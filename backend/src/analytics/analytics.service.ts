import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../common/database/prisma.service';
import { RedisService } from '../common/redis/redis.service';

@Injectable()
export class AnalyticsService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    @InjectQueue('ai') private aiQueue: Queue,
    @InjectQueue('notifications') private notifQueue: Queue,
    @InjectQueue('post_notifications') private postNotifQueue: Queue,
    @InjectQueue('recommendations') private recsQueue: Queue,
    @InjectQueue('leaderboard_recalc') private leaderboardQueue: Queue,
    @InjectQueue('ai_recalc') private aiRecalcQueue: Queue,
  ) {}

  async getSystemAnalytics(userId: string) {
    const [recommendation, redisMetrics, bullmq, userEngagement] =
      await Promise.all([
        this.getRecommendationMetrics(userId),
        this.getRedisMetrics(),
        this.getBullMQMetrics(),
        this.getUserEngagement(userId),
      ]);

    return { recommendation, redis: redisMetrics, bullmq, userEngagement };
  }

  private async getRecommendationMetrics(userId: string) {
    const client = this.redis.getClient();
    const hasSvdFactors = !!(await client.get(`svd:u:${userId}`));

    const [likes, bookmarks, comments] = await Promise.all([
      this.prisma.postLike.count({ where: { userId } }),
      this.prisma.postBookmark.count({ where: { userId } }),
      this.prisma.comment.count({ where: { authorId: userId } }),
    ]);

    const userFactorKeys = await client.keys('svd:u:*');
    const postFactorKeys = await client.keys('svd:p:*');

    const likedPosts = await this.prisma.postLike.findMany({
      where: { userId },
      include: { post: { select: { tags: true } } },
      take: 50,
      orderBy: { createdAt: 'desc' },
    });
    const tagCounts: Record<string, number> = {};
    for (const like of likedPosts) {
      for (const tag of like.post.tags.split('|').filter(Boolean)) {
        tagCounts[tag] = (tagCounts[tag] || 0) + 1;
      }
    }
    const topTags = Object.entries(tagCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([tag, count]) => ({ tag, count }));

    const totalInteractions = likes + bookmarks + comments;
    let method: string;
    if (hasSvdFactors) {
      method = 'SVD Matrix Factorization';
    } else if (totalInteractions >= 3) {
      method = 'Hybrid Tag Matching';
    } else {
      method = 'Trending Fallback';
    }

    return {
      method,
      svdActive: hasSvdFactors,
      svdFactors: { users: userFactorKeys.length, posts: postFactorKeys.length },
      interactions: { likes, bookmarks, comments, total: totalInteractions },
      topTags,
    };
  }

  private async getRedisMetrics() {
    const client = this.redis.getClient();
    const infoRaw = await client.info();

    const getVal = (key: string): string => {
      const m = infoRaw.match(new RegExp(`${key}:(.+)`));
      return m ? m[1].trim() : '0';
    };

    const hits = parseInt(getVal('keyspace_hits')) || 0;
    const misses = parseInt(getVal('keyspace_misses')) || 0;
    const totalOps = hits + misses;
    const hitRate = totalOps > 0 ? Math.round((hits / totalOps) * 100) : 0;
    const memoryBytes = parseInt(getVal('used_memory')) || 0;
    const connectedClients = parseInt(getVal('connected_clients')) || 0;
    const uptimeSeconds = parseInt(getVal('uptime_in_seconds')) || 0;

    const [feedKeys, lbKeys, svdKeys, rlKeys, aiReviewKeys, aiExplainKeys, aiMentorKeys] =
      await Promise.all([
        client.keys('feed:*'),
        client.keys('leaderboard:*'),
        client.keys('svd:*'),
        client.keys('ai:limit:*'),
        client.keys('ai:code_review:*'),
        client.keys('ai:code_explanation:*'),
        client.keys('ai:mentor_matching:*'),
      ]);

    const aiCacheCount = aiReviewKeys.length + aiExplainKeys.length + aiMentorKeys.length;

    return {
      hitRate,
      missRate: totalOps > 0 ? 100 - hitRate : 0,
      hits,
      misses,
      memoryUsedMB: Math.round((memoryBytes / 1024 / 1024) * 100) / 100,
      connectedClients,
      uptimeSeconds,
      cacheBreakdown: {
        feed: feedKeys.length,
        leaderboard: lbKeys.length,
        svd: svdKeys.length,
        rateLimit: rlKeys.length,
        aiCache: aiCacheCount,
        total: feedKeys.length + lbKeys.length + svdKeys.length + rlKeys.length + aiCacheCount,
      },
    };
  }

  private async getBullMQMetrics() {
    const queues = [
      { name: 'ai', queue: this.aiQueue },
      { name: 'leaderboard_recalc', queue: this.leaderboardQueue },
      { name: 'ai_recalc', queue: this.aiRecalcQueue },
      { name: 'notifications', queue: this.notifQueue },
      { name: 'post_notifications', queue: this.postNotifQueue },
      { name: 'recommendations', queue: this.recsQueue },
    ];

    const results = await Promise.all(
      queues.map(async ({ name, queue }) => {
        try {
          const counts = await queue.getJobCounts();
          return {
            name,
            waiting: counts.waiting || 0,
            active: counts.active || 0,
            completed: counts.completed || 0,
            failed: counts.failed || 0,
            delayed: counts.delayed || 0,
          };
        } catch {
          return { name, waiting: 0, active: 0, completed: 0, failed: 0, delayed: 0 };
        }
      }),
    );

    return {
      queues: results,
      totalCompleted: results.reduce((s, q) => s + q.completed, 0),
      totalFailed: results.reduce((s, q) => s + q.failed, 0),
    };
  }

  private async getUserEngagement(userId: string) {
    const [views, likes, comments, bookmarks, followers] = await Promise.all([
      this.prisma.userPostInteraction.count({
        where: { post: { authorId: userId }, interactionType: 'view' },
      }),
      this.prisma.postLike.count({ where: { post: { authorId: userId } } }),
      this.prisma.comment.count({ where: { post: { authorId: userId } } }),
      this.prisma.postBookmark.count({ where: { post: { authorId: userId } } }),
      this.prisma.userFollow.count({ where: { followingId: userId } }),
    ]);

    const topPosts = await this.prisma.post.findMany({
      where: { authorId: userId },
      orderBy: { viewCount: 'desc' },
      take: 5,
    });

    return {
      totalViews: views,
      totalLikes: likes,
      totalComments: comments,
      totalBookmarks: bookmarks,
      followers,
      topPosts: topPosts.map((p) => ({
        id: p.id,
        title: p.title,
        views: p.viewCount,
        likes: p.likeCount,
        comments: p.commentCount,
      })),
    };
  }
}
