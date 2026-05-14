import { Injectable, NotFoundException, UnauthorizedException, OnModuleInit } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../common/database/prisma.service';
import { RedisService } from '../common/redis/redis.service';
import { RecommendationService } from '../recommendations/recommendations.service';
import { Mapper } from '../common/utils/mapper';
import { filterXSS } from 'xss';

@Injectable()
export class PostsService implements OnModuleInit {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private recommendationService: RecommendationService,
    @InjectQueue('trending_recalc') private trendingQueue: Queue,
    @InjectQueue('post_notifications') private postNotificationsQueue: Queue,
  ) {}

  async getRecommendations(userId: string, limit: number) {
    return this.recommendationService.getRecommendedPosts(userId, limit);
  }

  async onModuleInit() {
    await this.trendingQueue.add(
      'recalculate',
      {},
      {
        repeat: {
          pattern: '*/15 * * * *', // Every 15 minutes
        },
        jobId: 'trending_recalc_15m',
      },
    );
  }

  async recalculateTrendingScores() {
    const posts = await this.prisma.post.findMany({
      select: { id: true, viewCount: true, likeCount: true, commentCount: true, bookmarkCount: true }
    });

    for (const post of posts) {
      // Score = views*0.1 + likes*2 + comments*3 + bookmarks*4
      const score = 
        post.viewCount * 0.1 + 
        post.likeCount * 2 + 
        post.commentCount * 3 + 
        post.bookmarkCount * 4;

      await this.prisma.post.update({
        where: { id: post.id },
        data: { trendingScore: score }
      });
    }
  }

  async findAll(userId: string | undefined, query: any) {
    const { type, authorId, limit = 20, cursor } = query;
    const cacheKey = `posts:feed:${type || 'all'}:${authorId || 'all'}:${userId || 'anon'}:${limit}:${cursor || 'none'}`;
    
    const cachedData = await this.redis.get(cacheKey);
    if (cachedData) return JSON.parse(cachedData);

    const takeLimit = parseInt(limit);
    let posts = [];

    if (type === 'foryou' && userId) {
      // SVD Recommendations for 'For You' tab
      posts = await this.recommendationService.getRecommendedPosts(userId, takeLimit);
      // Already mapped by recommendation service
      await this.redis.set(cacheKey, JSON.stringify(posts), 300);
      return posts;
    } else if (type === 'following' && userId) {
      posts = await this.prisma.post.findMany({
        where: {
          author: {
            followers: {
              some: { followerId: userId }
            }
          }
        },
        take: takeLimit,
        skip: cursor ? 1 : 0,
        cursor: cursor ? { id: cursor } : undefined,
        orderBy: { createdAt: 'desc' },
        include: { author: true },
      });
    } else {
      const isTrending = type === 'trending';
      posts = await this.prisma.post.findMany({
        where: {
          type: (isTrending || type === 'foryou' || type === 'following') ? undefined : (type || undefined),
          authorId: authorId || undefined,
        },
        take: takeLimit,
        skip: cursor ? 1 : 0,
        cursor: cursor ? { id: cursor } : undefined,
        orderBy: isTrending ? { trendingScore: 'desc' } : { createdAt: 'desc' },
        include: { 
          author: true,
          likes: userId ? { where: { userId }, take: 1 } : false,
          bookmarks: userId ? { where: { userId }, take: 1 } : false,
        },
      });
    }

    const mapped = posts.map(p => {
      const post = Mapper.post(p);
      return {
        ...post,
        isLikedByMe: p.likes?.length > 0,
        isBookmarkedByMe: p.bookmarks?.length > 0,
      };
    });
    await this.redis.set(cacheKey, JSON.stringify(mapped), 300); // 5 min TTL
    return mapped;
  }

  async findOne(userId: string | undefined, id: string) {
    const cacheKey = `posts:item:${id}:${userId || 'anon'}`;
    const cachedData = await this.redis.get(cacheKey);
    if (cachedData) return JSON.parse(cachedData);

    const post = await this.prisma.post.findUnique({
      where: { id },
      include: { 
        author: true,
        likes: userId ? { where: { userId }, take: 1 } : false,
        bookmarks: userId ? { where: { userId }, take: 1 } : false,
      },
    });

    if (!post) return null;
    const mapped = Mapper.post(post);
    const final = {
      ...mapped,
      isLikedByMe: post.likes?.length > 0,
      isBookmarkedByMe: post.bookmarks?.length > 0,
    };
    await this.redis.set(cacheKey, JSON.stringify(final), 600);
    return final;
  }

  async create(userId: string, data: any) {
    // 1. Extract mentions and hashtags
    const mentions = (data.content.match(/@(\w+)/g) || []).map((m: string) => m.substring(1));
    const hashtags = (data.content.match(/#(\w+)/g) || []).map((h: string) => h.substring(1));
    
    // 2. Create post
    const post = await this.prisma.post.create({
      data: {
        id: `p${Date.now()}`,
        authorId: userId,
        title: data.title,
        content: filterXSS(data.content),
        type: data.type || 'article',
        tags: hashtags.join('|'),
        imageUrl: data.imageUrl,
      },
      include: { author: true },
    });

    // 3. Queue notifications
    if (mentions.length > 0) {
      await this.postNotificationsQueue.add('mention', { 
        postId: post.id, 
        authorId: userId, 
        mentions 
      });
    }

    await this.postNotificationsQueue.add('follower_notify', { 
      postId: post.id, 
      authorId: userId 
    });

    await this.invalidatePostCaches(post.id);
    return Mapper.post(post);
  }

  async like(userId: string, postId: string) {
    const existing = await this.prisma.postLike.findUnique({
      where: { postId_userId: { postId, userId } },
    });

    if (existing) {
      await this.prisma.$transaction([
        this.prisma.postLike.delete({ where: { id: existing.id } }),
        this.prisma.post.update({
          where: { id: postId },
          data: { 
            likeCount: { decrement: 1 },
            trendingScore: { decrement: 5 }
          },
        }),
      ]);
      const post = await this.prisma.post.findUnique({
        where: { id: postId },
        select: { likeCount: true, trendingScore: true },
      });
      await this.invalidatePostCaches(postId);
      return {
        liked: false,
        likeCount: post?.likeCount ?? 0,
        trendingScore: post?.trendingScore ?? 0,
      };
    } else {
      await this.prisma.$transaction([
        this.prisma.postLike.create({ data: { postId, userId } }),
        this.prisma.post.update({
          where: { id: postId },
          data: { 
            likeCount: { increment: 1 },
            trendingScore: { increment: 5 }
          },
        }),
      ]);
      const post = await this.prisma.post.findUnique({
        where: { id: postId },
        select: { likeCount: true, trendingScore: true },
      });
      await this.invalidatePostCaches(postId);
      return {
        liked: true,
        likeCount: post?.likeCount ?? 0,
        trendingScore: post?.trendingScore ?? 0,
      };
    }
  }

  async bookmark(userId: string, postId: string) {
    const existing = await this.prisma.postBookmark.findUnique({
      where: { postId_userId: { postId, userId } },
    });

    if (existing) {
      await this.prisma.$transaction([
        this.prisma.postBookmark.delete({ where: { id: existing.id } }),
        this.prisma.post.update({
          where: { id: postId },
          data: { 
            bookmarkCount: { decrement: 1 },
            trendingScore: { decrement: 10 }
          },
        }),
      ]);
      const post = await this.prisma.post.findUnique({
        where: { id: postId },
        select: { bookmarkCount: true, trendingScore: true },
      });
      await this.invalidatePostCaches(postId);
      return {
        bookmarked: false,
        bookmarkCount: post?.bookmarkCount ?? 0,
        trendingScore: post?.trendingScore ?? 0,
      };
    } else {
      await this.prisma.$transaction([
        this.prisma.postBookmark.create({ data: { postId, userId } }),
        this.prisma.post.update({
          where: { id: postId },
          data: { 
            bookmarkCount: { increment: 1 },
            trendingScore: { increment: 10 }
          },
        }),
      ]);
      const post = await this.prisma.post.findUnique({
        where: { id: postId },
        select: { bookmarkCount: true, trendingScore: true },
      });
      await this.invalidatePostCaches(postId);
      return {
        bookmarked: true,
        bookmarkCount: post?.bookmarkCount ?? 0,
        trendingScore: post?.trendingScore ?? 0,
      };
    }
  }

  async addComment(authorId: string, postId: string, data: any) {
    const parentId = data.parentId || null;
    let depth = 0;

    if (parentId) {
      const parent = await this.prisma.comment.findUnique({
        where: { id: parentId },
        select: { depth: true, postId: true },
      });
      if (!parent || parent.postId !== postId) throw new NotFoundException('Parent comment not found');
      depth = Math.min(parent.depth + 1, 4);
    }

    const comment = await this.prisma.$transaction(async (tx) => {
      const created = await tx.comment.create({
        data: {
          parentId,
          content: filterXSS(data.content),
          depth,
          authorId,
          postId,
          id: `c${Date.now()}`,
        },
        include: { author: true }
      });

      if (parentId) {
        await tx.comment.update({
          where: { id: parentId },
          data: { replyCount: { increment: 1 } },
        });
      }

      await tx.post.update({
        where: { id: postId },
        data: { 
          commentCount: { increment: 1 },
          trendingScore: { increment: 15 }
        }
      });

      return created;
    });
    await this.invalidatePostCaches(postId);
    return Mapper.comment(comment);
  }

  async getComments(postId: string) {
    const comments = await this.prisma.comment.findMany({
      where: { postId },
      include: { author: true },
      orderBy: { createdAt: 'asc' },
    });
    return comments.map(c => Mapper.comment(c));
  }

  async markBestAnswer(userId: string, postId: string, commentId: string) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== userId) throw new UnauthorizedException();

    await this.prisma.$transaction([
      this.prisma.comment.updateMany({
        where: { postId },
        data: { isBest: 0 },
      }),
      this.prisma.comment.update({
        where: { id: commentId },
        data: { isBest: 1 },
      }),
    ]);
    const comment = await this.prisma.comment.findUnique({
      where: { id: commentId },
      include: { author: true },
    });
    await this.invalidatePostCaches(postId);
    return Mapper.comment(comment);
  }

  async search(q: string) {
    // Raw SQL for Full-Text Search with keyword highlighting using ts_headline
    const posts: any[] = await this.prisma.$queryRaw`
      SELECT id, 
             ts_headline('english', title, plainto_tsquery('english', ${q}), 'StartSel=<b>, StopSel=</b>') as "highlightedTitle",
             ts_headline('english', content, plainto_tsquery('english', ${q}), 'StartSel=<b>, StopSel=</b>, MaxFragments=2, MaxWords=35, MinWords=15') as "highlightedContent",
             title, content, type, author_id as "authorId", 
             view_count as "viewCount", like_count as "likeCount", 
             comment_count as "commentCount", tags, created_at as "createdAt",
             trending_score as "trendingScore"
      FROM posts 
      WHERE search_vector @@ plainto_tsquery('english', ${q})
      ORDER BY ts_rank(search_vector, plainto_tsquery('english', ${q})) DESC, trending_score DESC
      LIMIT 20
    `;
    return posts.map(p => ({
      ...Mapper.post(p),
      highlightedTitle: p.highlightedTitle,
      highlightedContent: p.highlightedContent,
    }));
  }

  async update(userId: string, postId: string, data: any) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== userId) throw new UnauthorizedException('Not your post');

    const updated = await this.prisma.post.update({
      where: { id: postId },
      data: {
        ...(data.title && { title: data.title }),
        ...(data.content && { content: filterXSS(data.content) }),
        ...(data.tags && { tags: Array.isArray(data.tags) ? data.tags.join('|') : data.tags }),
      },
      include: { author: true },
    });
    await this.invalidatePostCaches(postId);
    return Mapper.post(updated);
  }

  async remove(userId: string, postId: string) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== userId) throw new UnauthorizedException('Not your post');

    await this.prisma.post.delete({ where: { id: postId } });
    await this.invalidatePostCaches(postId);
    return { deleted: true };
  }

  private async invalidatePostCaches(postId: string) {
    await Promise.all([
      this.redis.delByPattern(`posts:item:${postId}:*`),
      this.redis.delByPattern('posts:feed:*'),
    ]);
  }

}
