import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { PlaygroundService } from './playground.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller()
export class PlaygroundController {
  constructor(private readonly playgroundService: PlaygroundService) {}

  @UseGuards(JwtAuthGuard)
  @Post('playground/run')
  runCode(@Body() body: { code: string; language: string }) {
    return this.playgroundService.runCode(body.code, body.language);
  }

  @UseGuards(JwtAuthGuard)
  @Post('code/run')
  runCodeAlias(@Body() body: { code: string; language: string }) {
    return this.runCode(body);
  }
}
