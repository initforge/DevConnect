import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  Request,
  Res,
} from "@nestjs/common";
import { AuthService } from "./auth.service";
import { LocalAuthGuard } from "./local-auth.guard";
import { JwtAuthGuard } from "./jwt-auth.guard";
import { AuthGuard } from "@nestjs/passport";
import { Response } from "express";

@Controller("auth")
export class AuthController {
  constructor(private authService: AuthService) {}

  @UseGuards(LocalAuthGuard)
  @Post("login")
  async login(@Request() req) {
    return this.authService.generateTokens(req.user);
  }

  @Get("github")
  @UseGuards(AuthGuard("github"))
  async githubLogin() {
    // Redirects to GitHub
  }

  @Get("github/callback")
  @UseGuards(AuthGuard("github"))
  async githubCallback(@Request() req, @Res() res: Response) {
    const tokens = await this.authService.generateTokens(req.user);
    const frontendUrl = (
      process.env.FRONTEND_URL || "http://localhost:3000"
    ).replace(/\/$/, "");
    const redirectUrl =
      `${frontendUrl}/#/auth/callback` +
      `?token=${encodeURIComponent(tokens.token)}` +
      `&refresh_token=${encodeURIComponent(tokens.refresh_token)}`;
    return res.redirect(redirectUrl);
  }

  @Post("register")
  register(@Body() body: any) {
    return this.authService.register(body);
  }

  @Post("forgot-password")
  async forgotPassword(@Body("email") email: string) {
    return this.authService.forgotPassword(email);
  }

  @UseGuards(JwtAuthGuard)
  @Post("change-password")
  async changePassword(@Request() req, @Body() body: any) {
    return this.authService.changePassword(req.user.userId, body);
  }

  @Post("refresh")
  async refresh(@Body() body: any) {
    const token = body.refreshToken || body.refresh_token;
    return this.authService.refreshTokens(token);
  }
}
