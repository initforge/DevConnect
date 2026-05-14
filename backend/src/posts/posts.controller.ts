import { Controller, Get, Post, Body, Param, Query, UseGuards, Request, Patch, Delete } from '@nestjs/common';
import { PostsService } from './posts.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('posts')
@UseGuards(JwtAuthGuard)
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  findAll(@Request() req, @Query() query: any) {
    return this.postsService.findAll(req?.user?.userId, query);
  }

  @Get('recommendations')
  getRecommendations(@Request() req, @Query('limit') limit?: string) {
    return this.postsService.getRecommendations(req.user.userId, limit ? parseInt(limit) : 10);
  }

  @Get('search')
  search(@Query('q') q: string) {
    return this.postsService.search(q);
  }

  @Get(':id')
  findOne(@Request() req, @Param('id') id: string) {
    return this.postsService.findOne(req.user.userId, id);
  }

  @Post()
  create(@Request() req, @Body() body: any) {
    return this.postsService.create(req.user.userId, body);
  }

  @Post(':id/like')
  like(@Request() req, @Param('id') id: string) {
    return this.postsService.like(req.user.userId, id);
  }

  @Post(':id/bookmark')
  bookmark(@Request() req, @Param('id') id: string) {
    return this.postsService.bookmark(req.user.userId, id);
  }

  @Get(':id/comments')
  getComments(@Param('id') id: string) {
    return this.postsService.getComments(id);
  }

  @Post(':id/comments')
  addComment(@Request() req, @Param('id') id: string, @Body() body: any) {
    return this.postsService.addComment(req.user.userId, id, body);
  }

  @Patch(':id/comments/:commentId/best-answer')
  markBestAnswer(@Request() req, @Param('id') id: string, @Param('commentId') commentId: string) {
    return this.postsService.markBestAnswer(req.user.userId, id, commentId);
  }

  @Patch(':id')
  update(@Request() req, @Param('id') id: string, @Body() body: any) {
    return this.postsService.update(req.user.userId, id, body);
  }

  @Delete(':id')
  remove(@Request() req, @Param('id') id: string) {
    return this.postsService.remove(req.user.userId, id);
  }
}
