import { Module, Global } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { AIProcessor } from './processors/ai.processor';
import { NotificationProcessor } from './processors/notification.processor';
import { PostNotificationProcessor } from './processors/post-notification.processor';
import { RecommendationProcessor } from './processors/recommendation.processor';
import { PushModule } from '../common/push/push.module';
import { DatabaseModule } from '../common/database/database.module';

@Global()
@Module({
  imports: [
    BullModule.registerQueue(
      { name: 'ai' },
      { name: 'notifications' },
      { name: 'post_notifications' },
      { name: 'recommendations' },
    ),
    PushModule,
    DatabaseModule,
  ],
  providers: [
    AIProcessor,
    NotificationProcessor,
    PostNotificationProcessor,
    RecommendationProcessor,
  ],
  exports: [BullModule],
})
export class BackgroundTasksModule {}
