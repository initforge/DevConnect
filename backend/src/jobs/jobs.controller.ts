import { Controller, Get, Post, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { JobsService } from './jobs.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Get()
  findAll(@Query() query: any) {
    return this.jobsService.findAll(query);
  }

  @Get('search')
  search(@Query('q') q: string) {
    return this.jobsService.findAll({ q });
  }

  @UseGuards(JwtAuthGuard)
  @Get('my-applications')
  getMyApplications(@Request() req) {
    return this.jobsService.getMyApplications(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Request() req, @Body() data: any) {
    return this.jobsService.create(req.user.userId, data);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.jobsService.findOne(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/apply')
  apply(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.jobsService.apply(req.user.userId, id, data);
  }
}
