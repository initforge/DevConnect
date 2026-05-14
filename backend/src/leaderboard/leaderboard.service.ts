import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../common/database/prisma.service';
import { RedisService } from '../common/redis/redis.service';
import { Mapper } from '../common/utils/mapper';

@Injectable()
export class LeaderboardService implements OnModuleInit {
  private static readonly PREV_RANKS_KEY = 'leaderboard:prev_ranks';

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    @InjectQueue('leaderboard_recalc') private leaderboardQueue: Queue,
  ) {}

  async onModuleInit() {
    await this.leaderboardQueue.add(
      'recalculate',
      {},
      {
        repeat: {
          pattern: '0 * * * *',
        },
        jobId: 'leaderboard_recalc_hourly',
      },
    );
  }

  async getLeaderboard(limit: number = 50) {
    const cacheKey = `leaderboard:top:${limit}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const users = await this.prisma.user.findMany({
      orderBy: { reputation: 'desc' },
      take: limit,
    });

    const prevRanksRaw = await this.redis.get(LeaderboardService.PREV_RANKS_KEY);
    const prevRanks: Record<string, number> = prevRanksRaw ? JSON.parse(prevRanksRaw) : {};

    const entries = users.map((user, index) => {
      const currentRank = index + 1;
      const previousRank = prevRanks[user.id] ?? currentRank;
      return {
        rank: currentRank,
        user: Mapper.user(user),
        points: user.reputation,
        rankChange: previousRank - currentRank,
      };
    });

    await this.redis.set(cacheKey, JSON.stringify(entries), 900);
    return entries;
  }

  getScoringWeights() {
    return {
      formula: 'likes×2 + bookmarks×3 + comment_upvotes×1 + best_answers×15 + followers×1 + projects×5',
      weights: [
        { metric: 'Like received', key: 'likes', weight: 2, description: 'Each like on your posts' },
        { metric: 'Bookmark received', key: 'bookmarks', weight: 3, description: 'Each bookmark on your posts' },
        { metric: 'Comment upvote', key: 'comment_upvotes', weight: 1, description: 'Each upvote on your comments' },
        { metric: 'Best answer', key: 'best_answers', weight: 15, description: 'Marked as best answer on a post' },
        { metric: 'Follower', key: 'followers', weight: 1, description: 'Each user following you' },
        { metric: 'Project membership', key: 'projects', weight: 5, description: 'Each accepted project membership' },
      ],
    };
  }

  /**
   * Recalculates reputation for all users based on the scoring formula.
   * Snapshots current ranks before recalculation to compute rankChange.
   */
  async recalculateReputation() {
    const currentTop = await this.prisma.user.findMany({
      orderBy: { reputation: 'desc' },
      take: 100,
      select: { id: true },
    });
    const snapshot: Record<string, number> = {};
    currentTop.forEach((u, i) => { snapshot[u.id] = i + 1; });
    await this.redis.set(LeaderboardService.PREV_RANKS_KEY, JSON.stringify(snapshot), 86400);

    const users = await this.prisma.user.findMany({ select: { id: true } });

    for (const user of users) {
      const [likes, bookmarks, comments, followers, projects] = await Promise.all([
        this.prisma.postLike.count({ where: { post: { authorId: user.id } } }),
        this.prisma.postBookmark.count({ where: { post: { authorId: user.id } } }),
        this.prisma.comment.aggregate({
          where: { authorId: user.id },
          _sum: { upvotes: true },
        }),
        this.prisma.userFollow.count({ where: { followingId: user.id } }),
        this.prisma.projectMember.count({ where: { userId: user.id, status: 'ACCEPTED' } }),
      ]);

      const bestAnswers = await this.prisma.comment.count({
        where: { authorId: user.id, isBest: 1 },
      });

      const upvotes = comments._sum.upvotes || 0;
      const score =
        likes * 2 +
        bookmarks * 3 +
        upvotes * 1 +
        bestAnswers * 15 +
        followers * 1 +
        projects * 5;

      await this.prisma.user.update({
        where: { id: user.id },
        data: { reputation: score },
      });
    }

    await this.redis.delByPattern('leaderboard:top:*');
  }
}
