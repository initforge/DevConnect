import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../common/database/prisma.service";

@Injectable()
export class LiveService {
  constructor(private prisma: PrismaService) {}

  async createRoom(
    hostId: string,
    title: string,
    language: string = "javascript",
  ) {
    const room = await this.prisma.liveCodeRoom.create({
      data: {
        id: `room-${Date.now()}`,
        hostId,
        title,
        language,
        code: this.getInitialCode(language),
      },
    });
    return room;
  }

  async getRoom(id: string) {
    const room = await this.prisma.liveCodeRoom.findUnique({
      where: { id },
    });
    if (!room) throw new NotFoundException("Room not found");
    const host = await this.prisma.user.findUnique({
      where: { id: room.hostId },
    });
    return {
      ...room,
      host,
    };
  }

  async updateCode(id: string, code: string, revision?: number) {
    return this.prisma.liveCodeRoom.update({
      where: { id },
      data: {
        code,
        revision: revision ?? undefined,
        updatedAt: new Date(),
      },
    });
  }

  async listActiveRooms() {
    const rooms = await this.prisma.liveCodeRoom.findMany({
      orderBy: { updatedAt: "desc" },
      take: 20,
    });
    const hosts = await this.prisma.user.findMany({
      where: { id: { in: rooms.map((room) => room.hostId) } },
    });
    const hostMap = new Map(hosts.map((host) => [host.id, host]));
    return rooms.map((room) => ({
      ...room,
      host: hostMap.get(room.hostId) ?? null,
    }));
  }

  private getInitialCode(language: string): string {
    switch (language.toLowerCase()) {
      case "javascript":
      case "typescript":
        return '// Happy coding!\nconsole.log("Hello DevConnect!");';
      case "python":
        return '# Happy coding!\nprint("Hello DevConnect!")';
      case "dart":
        return '// Happy coding!\nvoid main() {\n  print("Hello DevConnect!");\n}';
      default:
        return "// Start typing...";
    }
  }
}
