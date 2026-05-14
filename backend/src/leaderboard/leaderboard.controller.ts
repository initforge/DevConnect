import { Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { LeaderboardService } from './leaderboard.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('leaderboard')
export class LeaderboardController {
  constructor(private readonly leaderboardService: LeaderboardService) {}

  @Get()
  async getLeaderboard(@Query('limit') limit: string) {
    const limitNum = limit ? parseInt(limit, 10) : 50;
    return this.leaderboardService.getLeaderboard(limitNum);
  }

  @Get('scoring')
  getScoringWeights() {
    return this.leaderboardService.getScoringWeights();
  }

  @Post('recalculate')
  @UseGuards(JwtAuthGuard)
  async recalculate() {
    await this.leaderboardService.recalculateReputation();
    return { message: 'Reputation recalculated successfully' };
  }
}
