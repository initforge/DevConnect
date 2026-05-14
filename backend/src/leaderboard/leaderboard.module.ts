import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { LeaderboardService } from './leaderboard.service';
import { LeaderboardController } from './leaderboard.controller';
import { LeaderboardProcessor } from './leaderboard.processor';

@Module({
  imports: [
    BullModule.registerQueue({
      name: 'leaderboard_recalc',
    }),
  ],
  controllers: [LeaderboardController],
  providers: [LeaderboardService, LeaderboardProcessor],
  exports: [LeaderboardService],
})
export class LeaderboardModule {}
