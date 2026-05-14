import { Injectable, BadRequestException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../common/database/prisma.service';
import { Mapper } from '../common/utils/mapper';
import { SocialService } from '../social/social.service';

@Injectable()
export class ProjectsService {
  constructor(
    private prisma: PrismaService,
    private socialService: SocialService,
  ) {}

  async findAll(query: any) {
    const { status, q, limit = 20, cursor } = query;
    const projects = await this.prisma.project.findMany({
      where: {
        status: status || undefined,
        OR: q ? [
          { title: { contains: q, mode: 'insensitive' } },
          { description: { contains: q, mode: 'insensitive' } },
          { techStack: { contains: q, mode: 'insensitive' } },
        ] : undefined,
      },
      include: { owner: true, members: { include: { user: true } } },
      take: parseInt(limit),
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: 'desc' },
    });
    return projects.map(p => Mapper.project(p));
  }

  async findOne(id: string) {
    const project = await this.prisma.project.findUnique({
      where: { id },
      include: { owner: true, members: { include: { user: true } } },
    });
    if (!project) throw new NotFoundException('Project not found');
    return Mapper.project(project);
  }

  async create(ownerId: string, data: any) {
    if (data.techStack && Array.isArray(data.techStack)) {
      data.techStack = data.techStack.join('|');
    }
    const project = await this.prisma.project.create({
      data: {
        ...data,
        id: `proj${Date.now()}`,
        ownerId,
      },
      include: { owner: true },
    });
    return Mapper.project(project);
  }

  async update(userId: string, id: string, data: any) {
    const project = await this.prisma.project.findUnique({ where: { id } });
    if (!project) throw new NotFoundException();
    if (project.ownerId !== userId) throw new UnauthorizedException();

    if (data.techStack && Array.isArray(data.techStack)) {
      data.techStack = data.techStack.join('|');
    }

    const updated = await this.prisma.project.update({
      where: { id },
      data,
      include: { owner: true },
    });
    return Mapper.project(updated);
  }

  async delete(userId: string, id: string) {
    const project = await this.prisma.project.findUnique({ where: { id } });
    if (!project) throw new NotFoundException();
    if (project.ownerId !== userId) throw new UnauthorizedException();

    return this.prisma.project.delete({ where: { id } });
  }

  async join(userId: string, projectId: string, message: string) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId }, include: { owner: true } });
    if (!project) throw new NotFoundException('Project not found');

    const existing = await this.prisma.projectMember.findFirst({
      where: { projectId, userId },
    });
    if (existing) {
      throw new BadRequestException('You have already joined or requested to join this project');
    }

    const result = await this.prisma.projectMember.create({
      data: {
        id: `pm${Date.now()}`,
        projectId,
        userId,
        message,
        status: 'PENDING',
      },
    });

    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    // Send notification to project owner
    await this.socialService.createNotification({
      type: 'PROJECT',
      title: 'New Project Request',
      body: `${user.displayName} wants to join your project: ${project.title}`,
      fromUserId: userId,
      targetUserId: project.ownerId,
    });

    return { joined: true, ...result };
  }

  async leave(userId: string, projectId: string) {
    return this.prisma.projectMember.delete({
      where: { projectId_userId: { projectId, userId } },
    });
  }

  async getMembers(projectId: string) {
    const members = await this.prisma.projectMember.findMany({
      where: { projectId },
      include: { user: true },
    });
    return members.map(m => ({
      ...m,
      user: Mapper.user(m.user),
    }));
  }

  async updateMemberStatus(ownerId: string, projectId: string, userId: string, status: string) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!project) throw new NotFoundException('Project not found');
    if (project.ownerId !== ownerId) throw new UnauthorizedException('Only owner can manage members');

    return this.prisma.$transaction(async (tx) => {
      const member = await tx.projectMember.update({
        where: { projectId_userId: { projectId, userId } },
        data: { status },
      });

      if (status === 'ACCEPTED') {
        await tx.project.update({
          where: { id: projectId },
          data: { memberCount: { increment: 1 } },
        });
      }

      // Notify the user about the status update
      const statusText = status === 'ACCEPTED' ? 'accepted into' : 'declined from';
      await this.socialService.createNotification({
        type: 'PROJECT',
        title: 'Project Update',
        body: `You have been ${statusText} the project: ${project.title}`,
        fromUserId: ownerId,
        targetUserId: userId,
      });

      return member;
    });
  }
}
