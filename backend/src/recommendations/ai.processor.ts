import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { RecommendationService } from './recommendations.service';

@Processor('ai_recalc')
export class AIProcessor extends WorkerHost {
  constructor(private readonly recommendationService: RecommendationService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    switch (job.name) {
      case 'recalculate_svd':
        await this.recommendationService.runSvdRecalculation();
        return { status: 'completed' };
      default:
        throw new Error(`Unknown job name: ${job.name}`);
    }
  }
}
