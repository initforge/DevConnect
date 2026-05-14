import { Module } from '@nestjs/common';
import { SocialService } from './social.service';
import { SocialController } from './social.controller';
import { NotificationsGateway } from './notifications.gateway';
import { PushModule } from '../common/push/push.module';
import { BullModule } from '@nestjs/bullmq';

@Module({
  imports: [
    BullModule.registerQueue({ name: 'notifications' }),
    PushModule,
  ],
  controllers: [SocialController],
  providers: [SocialService, NotificationsGateway],
  exports: [SocialService, NotificationsGateway],
})
export class SocialModule {}
