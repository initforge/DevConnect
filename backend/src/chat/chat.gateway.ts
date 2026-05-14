import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { WsJwtGuard } from './ws-jwt.guard';
import { ChatService } from './chat.service';
import { RedisService } from '../common/redis/redis.service';

@WebSocketGateway({ namespace: 'chat', cors: true })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(
    private redis: RedisService,
    private chatService: ChatService,
    private jwtService: JwtService,
  ) {}

  @WebSocketServer()
  server: Server;

  async handleConnection(client: Socket) {
    const userId = await this.resolveUserId(client);
    if (!userId) {
      client.disconnect(true);
      return;
    }

    client.data.userId = userId;
    await this.redis.set(`online:user:${userId}`, 'online', 60);
    this.server.emit('presence_change', { userId, status: 'online' });
  }

  async handleDisconnect(client: Socket) {
    const userId = client.data?.userId || (await this.resolveUserId(client));
    if (userId) {
      await this.redis.del(`online:user:${userId}`);
      this.server.emit('presence_change', { userId, status: 'offline' });
    }
  }

  private async resolveUserId(client: Socket): Promise<string | null> {
    const token = this.extractToken(client);
    if (!token) return null;

    try {
      const payload = await this.jwtService.verifyAsync<{ sub?: string }>(
        token,
      );
      return payload.sub || null;
    } catch {
      return null;
    }
  }

  private extractToken(client: Socket): string | null {
    const authToken = client.handshake.auth?.token;
    if (typeof authToken === 'string' && authToken.trim()) {
      return authToken;
    }

    const header = client.handshake.headers?.authorization;
    if (typeof header === 'string' && header.startsWith('Bearer ')) {
      return header.slice(7);
    }

    return null;
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('send_message')
  async handleMessage(@MessageBody() data: any, @ConnectedSocket() client: Socket): Promise<void> {
    const senderId = (client as any).user.userId;
    
    // Save to database first
    const savedMessage = await this.chatService.saveMessage({
      conversationId: data.conversationId,
      senderId: senderId,
      content: data.content,
      type: data.type || 'text',
      codeLanguage: data.codeLanguage,
      codeSource: data.codeSource,
    });
    
    // Broadcast the saved message to the conversation room
    this.server.to(data.conversationId).emit('new_message', savedMessage);
  }

  @SubscribeMessage('join_conversation')
  handleJoinRoom(@MessageBody() conversationId: string, @ConnectedSocket() client: Socket): void {
    client.join(conversationId);
  }

  @SubscribeMessage('typing')
  handleTyping(@MessageBody() data: any, @ConnectedSocket() client: Socket): void {
    client.to(data.conversationId).emit('user_typing', {
      userId: (client as any).user.userId,
      isTyping: data.isTyping,
    });
  }
}
