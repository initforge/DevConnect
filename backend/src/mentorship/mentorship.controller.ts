import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from "@nestjs/common";
import { MentorshipService } from "./mentorship.service";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";

@Controller("mentorship")
@UseGuards(JwtAuthGuard)
export class MentorshipController {
  constructor(private readonly mentorshipService: MentorshipService) {}

  @Get("mentors")
  getMentors(
    @Query("expertise") expertise: string,
    @Query("page") page: string,
  ) {
    return this.mentorshipService.findMentors({
      expertise,
      page: parseInt(page) || 1,
    });
  }

  @Post("connect")
  connect(@Request() req, @Body() data: any) {
    return this.mentorshipService.connect(
      req.user.userId,
      data.mentorId,
      data.note,
    );
  }

  // Alias for Flutter compatibility if needed
  @Post("mentor-match")
  mentorMatch(@Request() req, @Body() data: any) {
    // This could call AI service, but for now simple connect or redirect
    return this.mentorshipService.connect(
      req.user.userId,
      data.mentorId,
      data.note,
    );
  }

  @Get("requests")
  getRequests(@Request() req, @Query("role") role?: "mentor" | "mentee") {
    return this.mentorshipService.getRequests(req.user.userId, role);
  }

  @Patch("requests/:id")
  updateStatus(@Param("id") id: string, @Body("status") status: string) {
    return this.mentorshipService.updateStatus(id, status);
  }

  @Delete("requests/:id")
  cancel(@Param("id") id: string) {
    return this.mentorshipService.cancel(id);
  }

  @Post("requests/:id/sessions")
  scheduleSession(@Request() req, @Param("id") id: string, @Body() data: any) {
    return this.mentorshipService.scheduleSession(
      req.user.userId,
      id,
      data.scheduledAt,
      data.notes,
    );
  }

  @Get("sessions")
  getSessions(@Request() req) {
    return this.mentorshipService.getSessions(req.user.userId);
  }

  @Post("journals")
  addJournal(@Request() req, @Body() data: any) {
    return this.mentorshipService.addJournal(req.user.userId, data);
  }

  @Get("journals")
  getJournals(@Request() req) {
    return this.mentorshipService.getJournals(req.user.userId);
  }

  @Patch("journals/:id/feedback")
  addJournalFeedback(
    @Request() req,
    @Param("id") id: string,
    @Body("feedback") feedback: string,
  ) {
    return this.mentorshipService.addJournalFeedback(
      req.user.userId,
      id,
      feedback,
    );
  }

  @Get("weekly-summary")
  weeklySummary(@Request() req) {
    return this.mentorshipService.weeklySummary(req.user.userId);
  }
}
