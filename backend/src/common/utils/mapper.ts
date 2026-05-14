export class Mapper {
  static user(user: any) {
    if (!user) return null;
    return {
      ...user,
      isOnline: user.isOnline === 1,
      isMentor: user.isMentor === 1,
      skills: user.skills ? user.skills.split('|').filter(Boolean) : [],
    };
  }

  static post(post: any) {
    if (!post) return null;
    return {
      ...post,
      tags: post.tags ? post.tags.split('|').filter(Boolean) : [],
      author: this.user(post.author),
    };
  }

  static comment(comment: any) {
    if (!comment) return null;
    return {
      ...comment,
      parentId: comment.parentId ?? null,
      isBest: comment.isBest === 1,
      author: this.user(comment.author),
    };
  }

  static project(project: any) {
    if (!project) return null;
    return {
      ...project,
      techStack: project.techStack ? project.techStack.split('|').filter(Boolean) : [],
      owner: this.user(project.owner),
    };
  }

  static job(job: any) {
    if (!job) return null;
    return {
      ...job,
      remote: job.remote === 1,
      techStack: job.techStack ? job.techStack.split('|').filter(Boolean) : [],
    };
  }

  static jobApplication(app: any) {
    if (!app) return null;
    const mapped = {
      ...app,
      user: this.user(app.user),
      job: this.job(app.job),
    };
    
    // Flatten job fields for Flutter model consistency if needed
    if (app.job) {
      mapped.company = app.job.company;
      mapped.jobTitle = app.job.title;
      mapped.location = app.job.location;
      mapped.remote = app.job.remote === 1;
      mapped.salaryRange = app.job.salaryRange;
      mapped.techStack = app.job.techStack ? app.job.techStack.split('|').filter(Boolean) : [];
      mapped.experience = app.job.experience;
    }
    
    return mapped;
  }

  static notification(notification: any) {
    if (!notification) return null;
    return {
      ...notification,
      isRead: notification.isRead === 1,
      fromUser: this.user(notification.fromUser),
    };
  }

  static message(message: any) {
    if (!message) return null;
    return {
      ...message,
      isRead: message.isRead === 1,
      reactions: message.reactions ? message.reactions.split('|').filter(Boolean) : [],
      sender: this.user(message.sender),
    };
  }

  static conversation(conversation: any) {
    if (!conversation) return null;
    return {
      ...conversation,
      otherUser: this.user(conversation.otherUser),
    };
  }
}
