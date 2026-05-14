import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/database/prisma.service';
import { Mapper } from '../common/utils/mapper';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async getConversations(userId: string) {
    const conversations = await this.prisma.conversation.findMany({
      where: { userId },
      include: { otherUser: true },
      orderBy: { updatedAt: 'desc' },
    });
    return conversations.map(c => Mapper.conversation(c));
  }

  async createOrGetConversation(userId: string, otherUserId: string) {
    // Check if conversation already exists
    const existing = await this.prisma.conversation.findFirst({
      where: { userId, otherUserId },
      include: { otherUser: true },
    });
    if (existing) return Mapper.conversation(existing);

    // Create new conversation
    const conversation = await this.prisma.conversation.create({
      data: {
        id: `conv${Date.now()}`,
        userId,
        otherUserId,
        lastMessage: '',
        unreadCount: 0,
      },
      include: { otherUser: true },
    });
    return Mapper.conversation(conversation);
  }

  async getConversationById(id: string, userId: string) {
    const conversation = await this.prisma.conversation.findFirst({
      where: { id, userId },
      include: { otherUser: true },
    });
    if (!conversation) throw new NotFoundException('Conversation not found');
    return Mapper.conversation(conversation);
  }

  async getMessages(conversationId: string) {
    const messages = await this.prisma.message.findMany({
      where: { conversationId },
      include: { sender: true },
      orderBy: { createdAt: 'asc' },
    });
    return messages.map(m => Mapper.message(m));
  }

  async markAsRead(conversationId: string, userId: string) {
    return this.prisma.$transaction([
      this.prisma.message.updateMany({
        where: { conversationId, senderId: { not: userId }, isRead: 0 },
        data: { isRead: 1 },
      }),
      this.prisma.conversation.update({
        where: { id: conversationId },
        data: { unreadCount: 0 },
      }),
    ]);
  }

  async saveMessage(data: any) {
    return this.prisma.$transaction(async (tx) => {
      const message = await tx.message.create({
        data: {
          ...data,
          id: `m${Date.now()}`,
        },
        include: { sender: true },
      });

      let lastMessagePreview = data.content;
      if (data.type === 'code') {
        lastMessagePreview = '[Code snippet]';
      } else if (data.type === 'image') {
        lastMessagePreview = '[Image]';
      }

      await tx.conversation.update({
        where: { id: data.conversationId },
        data: {
          lastMessage: lastMessagePreview,
          unreadCount: { increment: 1 },
          updatedAt: new Date(),
        },
      });

      return Mapper.message(message);
    });
  }

  async addReaction(conversationId: string, messageId: string, reaction: string) {
    const normalized = (reaction || '').trim();
    if (!normalized) throw new NotFoundException('Reaction not found');

    const message = await this.prisma.message.findFirst({
      where: { id: messageId, conversationId },
    });
    if (!message) throw new NotFoundException('Message not found');

    const reactions = new Set(
      (message.reactions || '').split('|').filter(Boolean),
    );
    if (reactions.has(normalized)) {
      reactions.delete(normalized);
    } else {
      reactions.add(normalized);
    }

    const updated = await this.prisma.message.update({
      where: { id: messageId },
      data: { reactions: [...reactions].join('|') },
      include: { sender: true },
    });
    return Mapper.message(updated);
  }

  async deleteConversation(conversationId: string, userId: string) {
    await this.prisma.conversation.deleteMany({
      where: { id: conversationId, userId },
    });
    return { success: true };
  }
}
