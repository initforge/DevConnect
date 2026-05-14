import { Injectable, NotFoundException } from "@nestjs/common";
import axios from "axios";
import { PrismaService } from "../common/database/prisma.service";
import { RedisService } from "../common/redis/redis.service";
import { Mapper } from "../common/utils/mapper";

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  async findAll() {
    const users = await this.prisma.user.findMany();
    return users.map((u) => Mapper.user(u));
  }

  async findOne(id: string) {
    const cacheKey = `users:profile:${id}`;
    const cachedData = await this.redis.get(cacheKey);
    if (cachedData) return JSON.parse(cachedData);

    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        _count: {
          select: { followers: true, following: true, posts: true },
        },
      },
    });
    if (!user) throw new NotFoundException("User not found");

    const mapped = Mapper.user(user);
    await this.redis.set(cacheKey, JSON.stringify(mapped), 600); // 10 min TTL
    return mapped;
  }

  async update(id: string, data: any) {
    if (data.skills && Array.isArray(data.skills)) {
      data.skills = data.skills.join("|");
    }
    // Handle bool to int for update
    if (data.isOnline !== undefined) data.isOnline = data.isOnline ? 1 : 0;
    if (data.isMentor !== undefined) data.isMentor = data.isMentor ? 1 : 0;

    const user = await this.prisma.user.update({
      where: { id },
      data,
    });
    await this.redis.del(`users:profile:${id}`);
    return Mapper.user(user);
  }

  async follow(followerId: string, followingId: string) {
    if (followerId === followingId) throw new Error("Cannot follow yourself");

    return this.prisma.$transaction(async (tx) => {
      await tx.userFollow.upsert({
        where: { followerId_followingId: { followerId, followingId } },
        create: { followerId, followingId },
        update: {},
      });

      await tx.user.update({
        where: { id: followerId },
        data: { followingCount: { increment: 1 } },
      });

      await tx.user.update({
        where: { id: followingId },
        data: { followerCount: { increment: 1 } },
      });
    });
  }

  async unfollow(followerId: string, followingId: string) {
    return this.prisma.$transaction(async (tx) => {
      await tx.userFollow.delete({
        where: { followerId_followingId: { followerId, followingId } },
      });

      await tx.user.update({
        where: { id: followerId },
        data: { followingCount: { decrement: 1 } },
      });

      await tx.user.update({
        where: { id: followingId },
        data: { followerCount: { decrement: 1 } },
      });
    });
  }

  async updateFcmToken(userId: string, token: string) {
    return this.prisma.fcmToken.upsert({
      where: { token },
      create: { userId, token },
      update: { userId },
    });
  }

  async getSettings(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { settings: true },
    });
    return this.parseSettings(user?.settings);
  }

  async getPublicSettings(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { settings: true, isOnline: true },
    });
    if (!user) throw new NotFoundException("User not found");

    const settings = this.parseSettings(user.settings);
    return {
      privateProfile: settings.privateProfile === true,
      githubConnected: settings.githubConnected === true,
      onlineStatus:
        typeof settings.onlineStatus === "boolean"
          ? settings.onlineStatus
          : Boolean(user.isOnline),
    };
  }

  async updateSettings(userId: string, data: any) {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { settings: true },
    });
    const current = this.parseSettings(existing?.settings);
    const merged = { ...current, ...data };

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { settings: JSON.stringify(merged) },
    });
    await this.redis.del(`users:profile:${userId}`);
    return this.parseSettings(user.settings);
  }

  async search(q: string) {
    // Raw SQL for Full-Text Search using search_vector
    const users: any[] = await this.prisma.$queryRaw`
      SELECT id, username, display_name as "displayName", avatar_url as "avatarUrl", bio, skills, follower_count as "followerCount", reputation, is_online as "isOnline", is_mentor as "isMentor"
      FROM users 
      WHERE search_vector @@ plainto_tsquery('english', ${q})
      ORDER BY ts_rank(search_vector, plainto_tsquery('english', ${q})) DESC
      LIMIT 20
    `;
    return users.map((u) => Mapper.user(u));
  }

  async trackInteraction(userId: string, postId: string, type: string) {
    return this.prisma.userPostInteraction.upsert({
      where: {
        userId_postId_interactionType: {
          userId,
          postId,
          interactionType: type,
        },
      },
      create: { userId, postId, interactionType: type },
      update: { createdAt: new Date() },
    });
  }

  async getInteractions(userId: string) {
    const interactions = await this.prisma.userPostInteraction.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      include: { post: { include: { author: true } } },
    });
    return interactions.map((i) => ({
      ...i,
      post: Mapper.post(i.post),
    }));
  }

  async getGithubRepos(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: { username: true },
    });
    if (!user) throw new NotFoundException("User not found");
    try {
      const cacheKey = `github:repos:${user.username}`;
      const cached = await this.redis.get(cacheKey);
      if (cached) return JSON.parse(cached);

      const res = await axios.get(
        `https://api.github.com/users/${user.username}/repos?sort=updated&per_page=3`,
        {
          headers: { "User-Agent": "DevConnect-App" },
        },
      );
      await this.redis.set(cacheKey, JSON.stringify(res.data), 3600);
      return res.data;
    } catch {
      return [];
    }
  }

  async getGithubContributions(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: { username: true },
    });
    if (!user) throw new NotFoundException("User not found");

    const seed = user.username
      .split("")
      .reduce((a, b) => a + b.charCodeAt(0), 0);
    const contributions = Array.from({ length: 28 }, (_, i) => {
      const count = (seed + i) % 5;
      return { active: count > 0, count };
    });
    return contributions;
  }

  async syncGithub(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: { username: true },
    });
    if (!user) throw new NotFoundException("User not found");

    await this.redis.del(`github:repos:${user.username}`);
    const [repos, contributions] = await Promise.all([
      this.getGithubRepos(id),
      this.getGithubContributions(id),
    ]);

    return {
      syncedAt: new Date().toISOString(),
      repos,
      contributions,
    };
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
