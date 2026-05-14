import { Injectable, HttpException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { RedisService } from "../common/redis/redis.service";
import { InjectQueue } from "@nestjs/bullmq";
import { Queue } from "bullmq";
import { createHash } from "crypto";

@Injectable()
export class AIService {
  private static readonly RATE_LIMIT = 20;
  private static readonly COOLDOWN_SECONDS = 30;

  constructor(
    private configService: ConfigService,
    private redisService: RedisService,
    @InjectQueue("ai") private aiQueue: Queue,
  ) {}

  async getAiResponse(
    payload: any,
    type: string,
    options?: { userId?: string; level?: string; locale?: string },
  ) {
    const locale = options?.locale === "vi" ? "vi" : "en";

    if (options?.userId) {
      await this.checkRateLimit(options.userId);
    }

    const payloadHash = createHash("sha256").update(JSON.stringify(payload)).digest("hex");
    const cacheKey = `ai:${type}:${locale}:${options?.level || "default"}:${payloadHash}`;
    const cached = await this.redisService.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const job = await this.aiQueue.add(type, {
      payload,
      type,
      userId: options?.userId,
      level: options?.level,
      locale,
    });

    for (let i = 0; i < 15; i++) {
      const state = await job.getState();
      if (state === "completed") {
        const finished = await this.aiQueue.getJob(job.id!);
        const result = finished?.returnvalue;
        if (result) {
          await this.redisService.set(cacheKey, JSON.stringify(result), 3600);
          return result;
        }
      }
      if (state === "failed") {
        throw new HttpException(
          locale === "vi"
            ? "AI xử lý thất bại. Vui lòng thử lại."
            : "AI processing failed. Please try again.",
          503,
        );
      }
      await new Promise((r) => setTimeout(r, 1000));
    }

    throw new HttpException(
      locale === "vi"
        ? "AI xử lý quá thời gian. Vui lòng thử lại."
        : "AI processing timed out. Please try again.",
      504,
    );
  }

  private async checkRateLimit(userId: string) {
    const rateKey = `ai:limit:${userId}`;
    const redis = this.redisService.getClient();
    const count = await redis.incr(rateKey);

    if (count === 1) {
      await redis.expire(rateKey, AIService.COOLDOWN_SECONDS);
    }

    if (count > AIService.RATE_LIMIT) {
      const ttl = await redis.ttl(rateKey);
      throw new HttpException(
        { message: `Rate limit: ${AIService.RATE_LIMIT} requests per ${AIService.COOLDOWN_SECONDS}s. Try again in ${ttl > 0 ? ttl : AIService.COOLDOWN_SECONDS}s.`, retryAfter: ttl > 0 ? ttl : AIService.COOLDOWN_SECONDS },
        429,
      );
    }
  }
}
