import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import { PrismaService } from '../../common/database/prisma.service';
import { RedisService } from '../../common/redis/redis.service';

@Processor('recommendations')
export class RecommendationProcessor extends WorkerHost {
  private readonly logger = new Logger(RecommendationProcessor.name);

  constructor(
    private prisma: PrismaService,
    private redisService: RedisService,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const { userId } = job.data;
    this.logger.log(`Calculating recommendations for user ${userId}`);

    // Simulation of SVD / Collaborative Filtering
    // 1. Get user interests from their skills and recent interactions
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { skills: true }
    });

    if (!user) return;

    const skills = user.skills.split('|');

    // 2. Find posts with matching tags that the user hasn't interacted with much
    const recommendedPosts = await this.prisma.post.findMany({
      where: {
        OR: skills.map(skill => ({ tags: { contains: skill, mode: 'insensitive' } })),
      },
      take: 10,
      orderBy: { likeCount: 'desc' },
    });

    // 3. Store in Redis for instant retrieval
    const cacheKey = `recommendations:${userId}`;
    await this.redisService.set(cacheKey, JSON.stringify(recommendedPosts.map(p => p.id)), 3600); // 1h cache

    this.logger.log(`Saved ${recommendedPosts.length} recommendations for user ${userId}`);
    
    return { count: recommendedPosts.length };
  }
}
