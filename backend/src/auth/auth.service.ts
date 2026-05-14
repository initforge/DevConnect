import { Injectable, UnauthorizedException } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { PrismaService } from "../common/database/prisma.service";
import * as bcrypt from "bcrypt";
import * as crypto from "crypto";

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  private async isPasswordValid(user: any, pass: string) {
    if (!user) return false;

    // Demo fallback must match both login and change-password flows.
    if (
      pass === "password123" &&
      (user.id === "u1" || user.email === "minh@dev.com")
    ) {
      return true;
    }

    if (!user.passwordHash) return false;
    return bcrypt.compare(pass, user.passwordHash);
  }

  async validateGithubUser(githubUser: any) {
    let user = await this.prisma.user.findUnique({
      where: { email: githubUser.email },
    });

    const nextSettings = JSON.stringify({ githubConnected: true });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          id: `u${Date.now()}`,
          username: githubUser.username,
          displayName: githubUser.displayName,
          email: githubUser.email,
          avatarUrl: githubUser.avatarUrl,
          passwordHash: "",
          skills: "",
          settings: nextSettings,
        },
      });
    } else {
      const currentSettings = this.parseSettings(user.settings);
      const mergedSettings = JSON.stringify({
        ...currentSettings,
        githubConnected: true,
      });

      user = await this.prisma.user.update({
        where: { id: user.id },
        data: {
          avatarUrl: githubUser.avatarUrl || user.avatarUrl,
          settings: mergedSettings,
        },
      });
    }

    return user;
  }

  async validateUser(email: string, pass: string): Promise<any> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) return null;

    if (await this.isPasswordValid(user, pass)) {
      const { passwordHash, ...result } = user;
      return result;
    }
    return null;
  }

  async generateTokens(user: any) {
    const payload = { username: user.username, sub: user.id };
    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, { expiresIn: "7d" });

    // Save refresh token in DB
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: refreshToken, // Should hash in production
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return {
      access_token: accessToken,
      token: accessToken, // Added for Flutter compatibility
      refresh_token: refreshToken,
      user: user,
    };
  }

  async refresh(token: string) {
    try {
      const payload = this.jwtService.verify(token);
      const storedToken = await this.prisma.refreshToken.findFirst({
        where: {
          userId: payload.sub,
          tokenHash: token,
          expiresAt: { gt: new Date() },
        },
      });

      if (!storedToken) throw new Error("Invalid refresh token");

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });
      return this.generateTokens(user);
    } catch (e) {
      throw new Error("Refresh failed");
    }
  }

  async login(user: any) {
    const payload = { username: user.username, sub: user.id };
    const accessToken = this.jwtService.sign(payload);

    // Generate Refresh Token as a JWT with longer expiry
    const refreshTokenId = `rt_${Date.now()}_${crypto.randomInt(1000)}`;
    const refreshToken = this.jwtService.sign(
      { sub: user.id, jti: refreshTokenId },
      { expiresIn: "7d" },
    );

    // Save refresh token info to DB (hashed)
    const tokenHash = await bcrypt.hash(refreshToken, 10);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await this.prisma.refreshToken.create({
      data: {
        id: refreshTokenId,
        userId: user.id,
        tokenHash: tokenHash,
        expiresAt: expiresAt,
      },
    });

    return {
      access_token: accessToken,
      token: accessToken, // Added for Flutter compatibility
      refresh_token: refreshToken,
      user,
    };
  }

  async refreshTokens(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync(refreshToken);
      const { sub: userId, jti: tokenId } = payload;

      const tokenEntity = await this.prisma.refreshToken.findUnique({
        where: { id: tokenId },
      });

      if (!tokenEntity || tokenEntity.expiresAt < new Date()) {
        throw new UnauthorizedException("Refresh token expired or not found");
      }

      const isMatch = await bcrypt.compare(refreshToken, tokenEntity.tokenHash);
      if (!isMatch) {
        throw new UnauthorizedException("Invalid refresh token");
      }

      // Valid! Rotate: Delete old token and issue new ones
      await this.prisma.refreshToken.delete({ where: { id: tokenId } });

      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new UnauthorizedException("User not found");

      return this.login(user);
    } catch (e) {
      throw new UnauthorizedException("Invalid refresh token");
    }
  }

  async register(userData: any) {
    const hashedPassword = await bcrypt.hash(userData.password, 12);
    const user = await this.prisma.user.create({
      data: {
        id: userData.id || `u${Date.now()}`,
        username: userData.username,
        displayName: userData.displayName,
        email: userData.email,
        passwordHash: hashedPassword,
        skills: "",
      },
    });

    return this.generateTokens(user);
  }

  async logout(userId: string) {
    await this.prisma.refreshToken.deleteMany({
      where: { userId },
    });
    return { success: true };
  }

  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      return { success: true };
    }
    return { success: true };
  }

  async changePassword(userId: string, data: any) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.passwordHash) throw new UnauthorizedException();

    const isMatch = await this.isPasswordValid(user, data.currentPassword);
    if (!isMatch) throw new UnauthorizedException("Invalid current password");

    const hashedPassword = await bcrypt.hash(data.newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: hashedPassword },
    });

    return { success: true };
  }

  private parseSettings(raw?: string | null) {
    if (!raw) return {};
    try {
      const parsed = JSON.parse(raw);
      return parsed && typeof parsed === "object" ? parsed : {};
    } catch {
      return {};
    }
  }
}
