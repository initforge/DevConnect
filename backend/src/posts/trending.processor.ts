import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PostsService } from './posts.service';

@Processor('trending_recalc')
export class TrendingProcessor extends WorkerHost {
  constructor(private readonly postsService: PostsService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    switch (job.name) {
      case 'recalculate':
        await this.postsService.recalculateTrendingScores();
        return { status: 'completed' };
      default:
        throw new Error(`Unknown job name: ${job.name}`);
    }
  }
}
