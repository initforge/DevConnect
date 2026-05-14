import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/database/prisma.service';
import { Mapper } from '../common/utils/mapper';

@Injectable()
export class JobsService {
  constructor(private prisma: PrismaService) {}

  async findAll(query: any) {
    const { q, limit = 20, cursor } = query;
    const jobs = await this.prisma.job.findMany({
      where: q ? {
        OR: [
          { title: { contains: q, mode: 'insensitive' } },
          { company: { contains: q, mode: 'insensitive' } },
          { techStack: { contains: q, mode: 'insensitive' } },
        ]
      } : {},
      take: parseInt(limit),
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: 'desc' },
    });
    return jobs.map(j => Mapper.job(j));
  }

  async findOne(id: string) {
    const job = await this.prisma.job.findUnique({
      where: { id },
    });
    if (!job) throw new NotFoundException('Job not found');
    return Mapper.job(job);
  }

  async create(userId: string, data: any) {
    const job = await this.prisma.job.create({
      data: {
        id: `job${Date.now()}`,
        company: data.company,
        title: data.title,
        location: data.location || '',
        remote: data.remote ? 1 : 0,
        salaryRange: data.salaryRange || '',
        techStack: Array.isArray(data.techStack) ? data.techStack.join('|') : (data.techStack || ''),
        experience: data.experience || '',
        matchPercent: 0,
      },
    });
    return Mapper.job(job);
  }

  async apply(userId: string, jobId: string, data: any) {
    const application = await this.prisma.jobApplication.create({
      data: {
        id: `app${Date.now()}`,
        jobId,
        userId,
        coverNote: data.coverNote || '',
        resumeUrl: data.resumeUrl,
      },
      include: { job: true, user: true },
    });
    return Mapper.jobApplication(application);
  }

  async getMyApplications(userId: string) {
    const applications = await this.prisma.jobApplication.findMany({
      where: { userId },
      include: { job: true, user: true },
      orderBy: { created_at: 'desc' },
    });
    return applications.map(a => Mapper.jobApplication(a));
  }
}
