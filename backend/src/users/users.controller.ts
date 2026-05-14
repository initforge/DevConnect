import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Query,
  UseGuards,
  Request,
  Delete,
} from "@nestjs/common";
import { UsersService } from "./users.service";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";

@Controller("users")
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Get("search")
  search(@Query("q") q: string) {
    return this.usersService.search(q);
  }

  @Get("me")
  getProfile(@Request() req) {
    return this.usersService.findOne(req.user.userId);
  }

  @Get(":id/public-settings")
  getPublicSettings(@Param("id") id: string) {
    return this.usersService.getPublicSettings(id);
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.usersService.findOne(id);
  }

  @Get(":id/repos")
  getRepos(@Param("id") id: string) {
    return this.usersService.getGithubRepos(id);
  }

  @Get(":id/github-contributions")
  getContributions(@Param("id") id: string) {
    return this.usersService.getGithubContributions(id);
  }

  @Post(":id/github-sync")
  syncGithub(@Param("id") id: string) {
    return this.usersService.syncGithub(id);
  }

  @Patch("me")
  update(@Request() req, @Body() body: any) {
    return this.usersService.update(req.user.userId, body);
  }

  @Post(":id/follow")
  follow(@Request() req, @Param("id") followingId: string) {
    return this.usersService.follow(req.user.userId, followingId);
  }

  @Delete(":id/follow")
  unfollow(@Request() req, @Param("id") followingId: string) {
    return this.usersService.unfollow(req.user.userId, followingId);
  }

  @Get("me/settings")
  getSettings(@Request() req) {
    return this.usersService.getSettings(req.user.userId);
  }

  @Patch("me/settings")
  updateSettings(@Request() req, @Body() body: any) {
    return this.usersService.updateSettings(req.user.userId, body);
  }

  @Patch("me/fcm-token")
  updateFcmToken(@Request() req, @Body("token") token: string) {
    return this.usersService.updateFcmToken(req.user.userId, token);
  }
}
