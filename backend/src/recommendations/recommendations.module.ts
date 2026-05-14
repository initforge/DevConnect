import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { RecommendationService } from './recommendations.service';
import { AIProcessor } from './ai.processor';

@Module({
  imports: [
    BullModule.registerQueue({
      name: 'ai_recalc',
    }),
  ],
  providers: [RecommendationService, AIProcessor],
  exports: [RecommendationService],
})
export class RecommendationModule {}
