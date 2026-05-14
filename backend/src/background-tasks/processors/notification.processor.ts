import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import { PushService } from '../../common/push/push.service';
import { PrismaService } from '../../common/database/prisma.service';

@Processor('notifications')
export class NotificationProcessor extends WorkerHost {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(
    private pushService: PushService,
    private prisma: PrismaService,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const { userId, title, body, data } = job.data;
    this.logger.log(`Processing Notification for user ${userId}: ${title}`);

    // 1. Get user's FCM tokens
    const tokens = await this.prisma.fcmToken.findMany({
      where: { userId },
    });

    if (tokens.length === 0) {
      this.logger.warn(`No FCM tokens found for user ${userId}`);
      return { success: false, reason: 'no_tokens' };
    }

    // 2. Send push notifications
    const sendPromises = tokens.map(t => 
      this.pushService.sendPushNotification(t.token, title, body, data)
    );

    await Promise.all(sendPromises);

    return { success: true, count: tokens.length };
  }
}
