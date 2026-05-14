import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyAnalytics(@Request() req) {
    return this.analyticsService.getSystemAnalytics(req.user.userId);
  }
}
