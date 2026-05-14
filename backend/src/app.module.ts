import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { DatabaseModule } from './common/database/database.module';
import { RedisModule } from './common/redis/redis.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PostsModule } from './posts/posts.module';
import { SocialModule } from './social/social.module';
import { MediaModule } from './media/media.module';
import { ChatModule } from './chat/chat.module';
import { LiveModule } from './live/live.module';
import { AIModule } from './ai/ai.module';
import { PlaygroundModule } from './playground/playground.module';
import { PushModule } from './common/push/push.module';
import { RecommendationModule } from './recommendations/recommendations.module';
import { JobsModule } from './jobs/jobs.module';
import { ProjectsModule } from './projects/projects.module';
import { MentorshipModule } from './mentorship/mentorship.module';
import { LeaderboardModule } from './leaderboard/leaderboard.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { BackgroundTasksModule } from './background-tasks/background-tasks.module';

import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    BullModule.forRoot({
      connection: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
      },
    }),
    DatabaseModule,
    RedisModule,
    AuthModule,
    UsersModule,
    PostsModule,
    SocialModule,
    MediaModule,
    ChatModule,
    LiveModule,
    AIModule,
    PlaygroundModule,
    PushModule,
    RecommendationModule,
    JobsModule,
    ProjectsModule,
    MentorshipModule,
    LeaderboardModule,
    AnalyticsModule,
    BackgroundTasksModule,
  ],
  controllers: [HealthController],
  providers: [],
})

export class AppModule {}
