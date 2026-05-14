import { Controller, Post, Get, Body, UseGuards, Request } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('interactions')
@UseGuards(JwtAuthGuard)
export class InteractionsController {
  constructor(private readonly usersService: UsersService) {}

  @Post('track')
  track(@Request() req, @Body() data: { postId: string; type: string }) {
    return this.usersService.trackInteraction(req.user.userId, data.postId, data.type);
  }

  @Get()
  get(@Request() req) {
    return this.usersService.getInteractions(req.user.userId);
  }
}
