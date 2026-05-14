import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { PostsService } from './posts.service';
import { PostsController } from './posts.controller';
import { TrendingProcessor } from './trending.processor';
import { PostsProcessor } from './posts.processor';
import { SocialModule } from '../social/social.module';
import { RecommendationModule } from '../recommendations/recommendations.module';

@Module({
  imports: [
    BullModule.registerQueue({
      name: 'trending_recalc',
    }),
    BullModule.registerQueue({
      name: 'post_notifications',
    }),
    SocialModule,
    RecommendationModule,
  ],
  controllers: [PostsController],
  providers: [PostsService, TrendingProcessor, PostsProcessor],
  exports: [PostsService],
})
export class PostsModule {}
