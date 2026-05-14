import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../common/database/prisma.service';
import { NotificationsGateway } from './notifications.gateway';
import { PushService } from '../common/push/push.service';
import { Mapper } from '../common/utils/mapper';

@Injectable()
export class SocialService {
  constructor(
    private prisma: PrismaService,
    private notificationsGateway: NotificationsGateway,
    private pushService: PushService,
    @InjectQueue('notifications') private notificationQueue: Queue,
  ) {}

  async getNotifications(userId: string) {
    const notifications = await this.prisma.notification.findMany({
      where: { targetUserId: userId },
      orderBy: { createdAt: 'desc' },
      include: { fromUser: true },
    });
    return notifications.map(n => Mapper.notification(n));
  }

  async markAsRead(id: string) {
    const notification = await this.prisma.notification.update({
      where: { id },
      data: { isRead: 1 },
      include: { fromUser: true },
    });
    return Mapper.notification(notification);
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { targetUserId: userId, isRead: 0 },
      data: { isRead: 1 },
    });
  }

  async getUnreadCount(userId: string) {
    return this.prisma.notification.count({
      where: { targetUserId: userId, isRead: 0 },
    });
  }

  async createNotification(data: any) {
    // Merge logic: If a notification of same type and target exists within 5 mins, increment mergedCount
    const fiveMinsAgo = new Date(Date.now() - 5 * 60 * 1000);
    const existing = await this.prisma.notification.findFirst({
      where: {
        type: data.type,
        targetUserId: data.targetUserId,
        createdAt: { gte: fiveMinsAgo },
      },
    });

    if (existing) {
      const newCount = existing.mergedCount + 1;
      let newBody = existing.body;
      
      // Update body based on merge
      if (existing.type === 'like') {
        newBody = `${data.title.split(' ')[0]} and ${newCount - 1} others liked your post`;
      } else if (existing.type === 'comment') {
        newBody = `${data.title.split(' ')[0]} and ${newCount - 1} others commented on your post`;
      }

      const notification = await this.prisma.notification.update({
        where: { id: existing.id },
        data: { 
          mergedCount: newCount,
          body: newBody,
          createdAt: new Date(), // Refresh the time
        },
        include: { fromUser: true },
      });
      
      const mapped = Mapper.notification(notification);
      this.notificationsGateway.sendNotification(data.targetUserId, mapped);
      return mapped;
    }


    const notification = await this.prisma.notification.create({
      data: {
        ...data,
        id: `n${Date.now()}`,
      },
      include: { fromUser: true },
    });

    const mapped = Mapper.notification(notification);

    // 3. Emit via WebSocket
    this.notificationsGateway.sendNotification(data.targetUserId, mapped);

    // 4. Trigger FCM Push
    this.triggerPush(data.targetUserId, mapped);

    return mapped;
  }

  private async triggerPush(userId: string, notification: any) {
    const title = 'DevConnect';
    let body = '';

    switch (notification.type) {
      case 'like':
        body = `${notification.fromUser?.displayName || 'Someone'} liked your post`;
        break;
      case 'comment':
        body = `${notification.fromUser?.displayName || 'Someone'} commented on your post`;
        break;
      case 'follow':
        body = `${notification.fromUser?.displayName || 'Someone'} followed you`;
        break;
      default:
        body = 'You have a new notification';
    }

    await this.notificationQueue.add('send_push', {
      userId,
      title,
      body,
      data: {
        notificationId: notification.id,
        type: notification.type,
      },
    });
  }
}
