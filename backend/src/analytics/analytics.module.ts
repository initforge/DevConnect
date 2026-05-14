import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { AnalyticsService } from './analytics.service';
import { AnalyticsController } from './analytics.controller';

@Module({
  imports: [
    BullModule.registerQueue(
      { name: 'ai' },
      { name: 'notifications' },
      { name: 'post_notifications' },
      { name: 'recommendations' },
      { name: 'leaderboard_recalc' },
      { name: 'ai_recalc' },
    ),
  ],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
