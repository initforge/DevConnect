import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../common/database/prisma.service";
import { Mapper } from "../common/utils/mapper";

@Injectable()
export class MentorshipService {
  constructor(private prisma: PrismaService) {}

  async findMentors(query: any) {
    const { expertise, page = 1, limit = 20 } = query;
    const mentors = await this.prisma.user.findMany({
      where: {
        isMentor: 1,
        skills: expertise
          ? { contains: expertise, mode: "insensitive" }
          : undefined,
      },
      take: limit,
      skip: (page - 1) * limit,
      orderBy: { reputation: "desc" },
    });
    return mentors.map((m) => Mapper.user(m));
  }

  async connect(menteeId: string, mentorId: string, note: string) {
    const request = await this.prisma.mentorshipRequest.create({
      data: {
        id: `mr${Date.now()}`,
        menteeId,
        mentorId,
        note,
        status: "pending",
      },
      include: { mentor: true, mentee: true },
    });
    return this.mapRequest(request);
  }

  async getRequests(userId: string, role?: "mentor" | "mentee") {
    const requests = await this.prisma.mentorshipRequest.findMany({
      where:
        role === "mentor"
          ? { mentorId: userId }
          : role === "mentee"
            ? { menteeId: userId }
            : { OR: [{ mentorId: userId }, { menteeId: userId }] },
      include: { mentor: true, mentee: true },
      orderBy: { createdAt: "desc" },
    });
    return requests.map((request) => this.mapRequest(request));
  }

  async updateStatus(id: string, status: string) {
    const request = await this.prisma.mentorshipRequest.update({
      where: { id },
      data: { status },
      include: { mentor: true, mentee: true },
    });
    return this.mapRequest(request);
  }

  async cancel(id: string) {
    return this.prisma.mentorshipRequest.delete({
      where: { id },
    });
  }

  async scheduleSession(
    userId: string,
    requestId: string,
    scheduledAt: string,
    notes?: string,
  ) {
    const date = new Date(scheduledAt);
    if (Number.isNaN(date.getTime())) {
      throw new BadRequestException("scheduledAt must be an ISO date");
    }

    await this.requireParticipant(userId, requestId);
    return this.prisma.mentorshipSession.create({
      data: {
        requestId,
        scheduledAt: date,
        notes: notes || null,
      },
    });
  }

  async getSessions(userId: string) {
    return this.prisma.mentorshipSession.findMany({
      where: {
        request: {
          OR: [{ mentorId: userId }, { menteeId: userId }],
        },
      },
      orderBy: { scheduledAt: "asc" },
    });
  }

  async addJournal(
    userId: string,
    data: { requestId?: string; text?: string },
  ) {
    const text = data.text?.trim();
    if (!text) throw new BadRequestException("Journal text is required");

    if (data.requestId) {
      await this.requireParticipant(userId, data.requestId);
    }

    return this.prisma.mentorshipJournal.create({
      data: {
        requestId: data.requestId || null,
        authorId: userId,
        text,
      },
    });
  }

  async getJournals(userId: string) {
    return this.prisma.mentorshipJournal.findMany({
      where: {
        OR: [
          { authorId: userId },
          {
            request: {
              OR: [{ mentorId: userId }, { menteeId: userId }],
            },
          },
        ],
      },
      orderBy: { createdAt: "desc" },
    });
  }

  async addJournalFeedback(
    userId: string,
    journalId: string,
    feedback: string,
  ) {
    const journal = await this.prisma.mentorshipJournal.findUnique({
      where: { id: journalId },
      include: { request: true },
    });
    if (!journal || !journal.request) {
      throw new NotFoundException("Journal not found");
    }
    if (journal.request.mentorId !== userId) {
      throw new ForbiddenException("Only the mentor can add feedback");
    }

    return this.prisma.mentorshipJournal.update({
      where: { id: journalId },
      data: { mentorFeedback: feedback.trim() || null },
    });
  }

  async weeklySummary(userId: string) {
    const since = new Date();
    since.setDate(since.getDate() - 7);

    const [acceptedCount, scheduledCount, journalCount] = await Promise.all([
      this.prisma.mentorshipRequest.count({
        where: {
          status: "accepted",
          OR: [{ mentorId: userId }, { menteeId: userId }],
        },
      }),
      this.prisma.mentorshipSession.count({
        where: {
          scheduledAt: { gte: since },
          request: { OR: [{ mentorId: userId }, { menteeId: userId }] },
        },
      }),
      this.prisma.mentorshipJournal.count({
        where: {
          createdAt: { gte: since },
          OR: [
            { authorId: userId },
            { request: { OR: [{ mentorId: userId }, { menteeId: userId }] } },
          ],
        },
      }),
    ]);

    const completed = Math.min(
      5,
      acceptedCount + scheduledCount + journalCount,
    );
    return {
      acceptedCount,
      scheduledCount,
      journalCount,
      completed,
      target: 5,
      text: `You completed ${completed}/5 mentorship goals this week: ${scheduledCount} scheduled, ${journalCount} journaled, ${acceptedCount} active.`,
    };
  }

  private async requireParticipant(userId: string, requestId: string) {
    const request = await this.prisma.mentorshipRequest.findFirst({
      where: {
        id: requestId,
        OR: [{ mentorId: userId }, { menteeId: userId }],
      },
    });
    if (!request) throw new NotFoundException("Mentorship request not found");
    return request;
  }

  private mapRequest(request: any) {
    return {
      ...request,
      menteeUsername: request.mentee?.username,
      menteeDisplayName: request.mentee?.displayName,
      mentorUsername: request.mentor?.username,
      mentorDisplayName: request.mentor?.displayName,
      mentor: request.mentor ? Mapper.user(request.mentor) : undefined,
      mentee: request.mentee ? Mapper.user(request.mentee) : undefined,
    };
  }
}
