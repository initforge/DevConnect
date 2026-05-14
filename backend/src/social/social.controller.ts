import { Controller, Get, Post, Body, Patch, Param, UseGuards, Request } from '@nestjs/common';
import { SocialService } from './social.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller()
export class SocialController {
  constructor(private readonly socialService: SocialService) {}

  @UseGuards(JwtAuthGuard)
  @Get('social/notifications')
  getNotifications(@Request() req) {
    return this.socialService.getNotifications(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('notifications')
  getNotificationsAlias(@Request() req) {
    return this.socialService.getNotifications(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('notifications/count')
  getUnreadCount(@Request() req) {
    return this.socialService.getUnreadCount(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('notifications/read-all')
  markAllAsRead(@Request() req) {
    return this.socialService.markAllAsRead(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('social/notifications/:id/read')
  markAsRead(@Param('id') id: string) {
    return this.socialService.markAsRead(id);
  }
}
