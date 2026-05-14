import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ProjectsService } from './projects.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Get()
  findAll(@Query() query: any) {
    return this.projectsService.findAll(query);
  }

  @Get('search')
  search(@Query('q') q: string) {
    return this.projectsService.findAll({ q });
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.projectsService.findOne(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Request() req, @Body() data: any) {
    return this.projectsService.create(req.user.userId, data);
  }

  @UseGuards(JwtAuthGuard)
  @Put(':id')
  update(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.projectsService.update(req.user.userId, id, data);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Request() req, @Param('id') id: string) {
    return this.projectsService.delete(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/join')
  join(@Request() req, @Param('id') id: string, @Body('message') message: string) {
    return this.projectsService.join(req.user.userId, id, message);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/leave')
  leave(@Request() req, @Param('id') id: string) {
    return this.projectsService.leave(req.user.userId, id);
  }

  @Get(':id/members')
  getMembers(@Param('id') id: string) {
    return this.projectsService.getMembers(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/members/:userId/accept')
  acceptMember(@Request() req, @Param('id') id: string, @Param('userId') userId: string) {
    return this.projectsService.updateMemberStatus(req.user.userId, id, userId, 'ACCEPTED');
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/members/:userId/reject')
  rejectMember(@Request() req, @Param('id') id: string, @Param('userId') userId: string) {
    return this.projectsService.updateMemberStatus(req.user.userId, id, userId, 'REJECTED');
  }
}
