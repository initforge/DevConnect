import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
} from "@nestjs/websockets";
import { Server, Socket } from "socket.io";

import { LiveService } from "./live.service";

@WebSocketGateway({ namespace: "live", cors: true })
export class LiveGateway {
  @WebSocketServer()
  server: Server;

  constructor(private readonly liveService: LiveService) {}

  @SubscribeMessage("create_room")
  async handleCreateRoom(
    @MessageBody() data: any,
    @ConnectedSocket() client: Socket,
  ) {
    const room = await this.liveService.createRoom(
      data.userId || client.handshake.auth?.userId || client.id,
      data.title || "Collaborative Coding",
      data.language || "javascript",
    );
    client.join(room.id);
    client.emit("room_created", {
      roomId: room.id,
      code: room.code,
      revision: room.revision,
    });
  }

  @SubscribeMessage("join_room")
  async handleJoinRoom(
    @MessageBody() roomId: string,
    @ConnectedSocket() client: Socket,
  ) {
    try {
      const room = await this.liveService.getRoom(roomId);
      client.join(roomId);
      client.emit("room_joined", {
        roomId,
        code: room.code,
        language: room.language,
        revision: room.revision,
      });
    } catch (e) {
      client.emit("error", { message: "Room not found" });
    }
  }

  @SubscribeMessage("code_change")
  async handleCodeChange(
    @MessageBody() data: any,
    @ConnectedSocket() client: Socket,
  ) {
    // Persist code change periodically or on every change (depending on traffic)
    // For demo, we persist on every change.
    const revision = Number.isFinite(Number(data.revision))
      ? Number(data.revision)
      : 0;
    await this.liveService.updateCode(data.roomId, data.code, revision);
    client.to(data.roomId).emit("code_updated", {
      code: data.code,
      delta: data.delta || null,
      baseRevision: data.baseRevision || Math.max(0, revision - 1),
      revision,
      userId: data.userId || client.id,
      cursor: data.cursor || null,
    });
  }

  @SubscribeMessage("cursor_update")
  async handleCursorUpdate(
    @MessageBody() data: any,
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.roomId).emit("cursor_updated", {
      userId: data.userId || client.id,
      name: data.name || "Guest",
      offset: data.offset || 0,
      color: data.color || "#5B53F6",
    });
  }
}
