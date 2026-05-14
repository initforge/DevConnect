import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Request } from '@nestjs/common';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('conversations')
  getConversations(@Request() req) {
    return this.chatService.getConversations(req.user.userId);
  }

  @Post('conversations')
  createOrGetConversation(@Request() req, @Body('otherUserId') otherUserId: string) {
    return this.chatService.createOrGetConversation(req.user.userId, otherUserId);
  }

  @Get('conversations/:id')
  getConversation(@Param('id') id: string, @Request() req) {
    return this.chatService.getConversationById(id, req.user.userId);
  }

  @Get('conversations/:id/messages')
  getMessages(@Param('id') id: string) {
    return this.chatService.getMessages(id);
  }

  @Patch('conversations/:id/read')
  markAsRead(@Param('id') id: string, @Request() req) {
    return this.chatService.markAsRead(id, req.user.userId);
  }

  @Post('conversations/:id/messages')
  sendMessage(@Param('id') id: string, @Request() req, @Body() body: any) {
    return this.chatService.saveMessage({
      conversationId: id,
      senderId: req.user.userId,
      ...body,
    });
  }

  @Post('conversations/:id/messages/:messageId/reactions')
  addReaction(
    @Param('id') id: string,
    @Param('messageId') messageId: string,
    @Body('reaction') reaction: string,
  ) {
    return this.chatService.addReaction(id, messageId, reaction);
  }

  @Delete('conversations/:id')
  deleteConversation(@Param('id') id: string, @Request() req) {
    return this.chatService.deleteConversation(id, req.user.userId);
  }
}
