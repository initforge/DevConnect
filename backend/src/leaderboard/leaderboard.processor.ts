import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { LeaderboardService } from './leaderboard.service';

@Processor('leaderboard_recalc')
export class LeaderboardProcessor extends WorkerHost {
  constructor(private readonly leaderboardService: LeaderboardService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    switch (job.name) {
      case 'recalculate':
        await this.leaderboardService.recalculateReputation();
        return { status: 'completed' };
      default:
        throw new Error(`Unknown job name: ${job.name}`);
    }
  }
}
