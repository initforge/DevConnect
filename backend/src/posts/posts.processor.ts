import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PostsService } from './posts.service';
import { SocialService } from '../social/social.service';
import { PrismaService } from '../common/database/prisma.service';

@Processor('post_notifications')
export class PostsProcessor extends WorkerHost {
  constructor(
    private readonly prisma: PrismaService,
    private readonly socialService: SocialService,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const { postId, authorId } = job.data;

    switch (job.name) {
      case 'mention':
        await this.handleMentions(postId, authorId, job.data.mentions);
        break;
      case 'follower_notify':
        await this.handleFollowerNotifications(postId, authorId);
        break;
    }
  }

  private async handleMentions(postId: string, authorId: string, mentions: string[]) {
    for (const username of mentions) {
      const user = await this.prisma.user.findUnique({ where: { username } });
      if (user && user.id !== authorId) {
        await this.socialService.createNotification({
          type: 'mention',
          title: 'You were mentioned',
          body: `Someone mentioned you in a post`,
          fromUserId: authorId,
          targetUserId: user.id,
        });
      }
    }
  }

  private async handleFollowerNotifications(postId: string, authorId: string) {
    const followers = await this.prisma.userFollow.findMany({
      where: { followingId: authorId },
    });

    const author = await this.prisma.user.findUnique({ where: { id: authorId } });

    for (const follow of followers) {
      await this.socialService.createNotification({
        type: 'post',
        title: 'New post',
        body: `${author?.displayName || 'Someone'} you follow posted something new`,
        fromUserId: authorId,
        targetUserId: follow.followerId,
      });
    }
  }
}
