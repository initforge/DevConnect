import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../common/database/prisma.service';
import { RedisService } from '../common/redis/redis.service';
import { Mapper } from '../common/utils/mapper';

@Injectable()
export class RecommendationService implements OnModuleInit {
  private readonly logger = new Logger(RecommendationService.name);
  private readonly K = 20; // Latent factors
  private readonly ALPHA = 0.01; // Learning rate
  private readonly BETA = 0.02; // Regularization
  private readonly ITERATIONS = 20;

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    @InjectQueue('ai_recalc') private aiQueue: Queue,
  ) {}

  async onModuleInit() {
    await this.aiQueue.add(
      'recalculate_svd',
      {},
      {
        repeat: {
          pattern: '0 */6 * * *', // Every 6 hours
        },
        jobId: 'ai_recalc_6h',
      },
    );
  }

  async getRecommendedPosts(userId: string, limit: number = 20) {
    const userFactorsKey = `svd:u:${userId}`;
    const userFactors = await this.redis.get(userFactorsKey);

    if (!userFactors) {
      this.logger.log(`No SVD factors for user ${userId}, falling back to hybrid ranking`);
      return this.getHybridRecommendations(userId, limit);
    }

    const P_u = JSON.parse(userFactors) as number[];
    
    // Get candidate posts (e.g., top trending posts the user hasn't seen/interacted with)
    const candidates = await this.prisma.post.findMany({
      where: {
        authorId: { not: userId },
      },
      take: 200,
      orderBy: { trendingScore: 'desc' },
    });

    const scored = await Promise.all(candidates.map(async (post) => {
      const qKey = `svd:p:${post.id}`;
      const qRaw = await this.redis.get(qKey);
      if (!qRaw) return { ...post, score: post.trendingScore * 0.1 };

      const Q_v = JSON.parse(qRaw) as number[];
      // Prediction = Dot product of P_u and Q_v
      const prediction = P_u.reduce((sum, val, i) => sum + val * Q_v[i], 0);
      
      return { ...post, score: prediction + (post.trendingScore * 0.05) };
    }));

    return scored
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map(p => Mapper.post(p));
  }

  private async getHybridRecommendations(userId: string, limit: number) {
    const [likes, bookmarks] = await Promise.all([
      this.prisma.postLike.findMany({ where: { userId }, include: { post: true } }),
      this.prisma.postBookmark.findMany({ where: { userId }, include: { post: true } }),
    ]);

    const interactions = [...likes, ...bookmarks];
    if (interactions.length < 3) {
      return this.getFallbackRecommendations(userId, limit);
    }

    const interactedPostIds = interactions.map(i => i.post.id);

    const favTags = interactions.flatMap(i => i.post.tags.split('|').filter(Boolean));
    const tagWeights = favTags.reduce((acc, tag) => ({ ...acc, [tag]: (acc[tag] || 0) + 1 }), {});

    const posts = await this.prisma.post.findMany({
      where: { 
        AND: [
          { authorId: { not: userId } },
          { id: { notIn: interactedPostIds } }
        ]
      },
      include: { author: true },
      take: 100,
      orderBy: { trendingScore: 'desc' },
    });


    return posts
      .map(p => {
        const pTags = p.tags.split('|');
        const match = pTags.reduce((s, t) => s + (tagWeights[t] || 0), 0);
        return { ...p, rank: match * 2 + p.trendingScore };
      })
      .sort((a, b) => b.rank - a.rank)
      .slice(0, limit)
      .map(p => Mapper.post(p));
  }

  private async getFallbackRecommendations(userId: string, limit: number) {
    const posts = await this.prisma.post.findMany({
      where: { authorId: { not: userId } },
      orderBy: [{ trendingScore: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      include: { author: true },
    });
    return posts.map(p => Mapper.post(p));
  }

  async runSvdRecalculation() {
    this.logger.log('Starting AI SVD Matrix Factorization (SGD)...');
    
    // 1. Fetch all interactions to build the matrix
    const [likes, bookmarks, comments] = await Promise.all([
      this.prisma.postLike.findMany(),
      this.prisma.postBookmark.findMany(),
      this.prisma.comment.findMany(),
    ]);

    const users = await this.prisma.user.findMany({ select: { id: true } });
    const posts = await this.prisma.post.findMany({ select: { id: true } });

    const userMap = new Map(users.map((u, i) => [u.id, i]));
    const postMap = new Map(posts.map((p, i) => [p.id, i]));

    // Build R (Interaction Matrix) as a list of triplets [u, v, r]
    const R: [number, number, number][] = [];
    
    const addInteraction = (uId: string, pId: string, score: number) => {
      const uIdx = userMap.get(uId);
      const pIdx = postMap.get(pId);
      if (uIdx !== undefined && pIdx !== undefined) {
        R.push([uIdx, pIdx, score]);
      }
    };

    likes.forEach(l => addInteraction(l.userId, l.postId, 5));
    bookmarks.forEach(b => addInteraction(b.userId, b.postId, 8));
    comments.forEach(c => addInteraction(c.authorId, c.postId, 3));

    if (R.length === 0) {
      this.logger.warn('No interactions found for SVD. Skipping.');
      return;
    }

    // 2. Initialize P and Q with small random values
    const P = Array.from({ length: users.length }, () => 
      Array.from({ length: this.K }, () => Math.random() * 0.1)
    );
    const Q = Array.from({ length: posts.length }, () => 
      Array.from({ length: this.K }, () => Math.random() * 0.1)
    );

    // 3. Stochastic Gradient Descent
    for (let step = 0; step < this.ITERATIONS; step++) {
      let totalError = 0;
      for (const [u, v, r] of R) {
        const prediction = P[u].reduce((sum, val, i) => sum + val * Q[v][i], 0);
        const error = r - prediction;
        totalError += Math.pow(error, 2);

        for (let k = 0; k < this.K; k++) {
          const p_uk = P[u][k];
          const q_vk = Q[v][k];
          
          P[u][k] += this.ALPHA * (2 * error * q_vk - this.BETA * p_uk);
          Q[v][k] += this.ALPHA * (2 * error * p_uk - this.BETA * q_vk);
        }
      }
      if (step % 5 === 0) this.logger.debug(`SVD Step ${step}, Error: ${totalError.toFixed(2)}`);
    }

    // 4. Save factors to Redis
    const pipeline = this.redis.getClient().pipeline();
    users.forEach((user, i) => {
      pipeline.set(`svd:u:${user.id}`, JSON.stringify(P[i]), 'EX', 86400); // 24h
    });
    posts.forEach((post, i) => {
      pipeline.set(`svd:p:${post.id}`, JSON.stringify(Q[i]), 'EX', 86400); // 24h
    });
    await pipeline.exec();

    this.logger.log('SVD Factorization completed successfully.');
  }
}

