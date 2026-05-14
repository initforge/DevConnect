import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job, Queue } from 'bullmq';
import { Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { PrismaService } from '../../common/database/prisma.service';

@Processor('post_notifications')
export class PostNotificationProcessor extends WorkerHost {
  private readonly logger = new Logger(PostNotificationProcessor.name);

  constructor(
    private prisma: PrismaService,
    @InjectQueue('notifications') private notificationsQueue: Queue,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const { postId, authorId, mentions } = job.data;
    
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      include: { author: true },
    });
    if (!post) return;

    if (job.name === 'mention' && mentions) {
      await this.handleMentions(post, mentions);
    } else if (job.name === 'follower_notify') {
      await this.handleFollowerNotify(post, authorId);
    }
  }

  private async handleMentions(post: any, usernames: string[]) {
    const users = await this.prisma.user.findMany({
      where: { username: { in: usernames } },
    });

    for (const user of users) {
      if (user.id === post.authorId) continue;
      await this.notificationsQueue.add('send', {
        userId: user.id,
        title: 'New Mention',
        body: `${post.author.displayName} mentioned you in a post: ${post.title}`,
        data: { type: 'post', id: post.id },
      });
    }
  }

  private async handleFollowerNotify(post: any, authorId: string) {
    const followers = await this.prisma.userFollow.findMany({
      where: { followingId: authorId },
    });

    for (const f of followers) {
      await this.notificationsQueue.add('send', {
        userId: f.followerId,
        title: 'New Post',
        body: `${post.author.displayName} published a new post: ${post.title}`,
        data: { type: 'post', id: post.id },
      });
    }
  }
}
