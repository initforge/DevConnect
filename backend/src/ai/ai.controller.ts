import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
} from "@nestjs/common";
import { AIService } from "./ai.service";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";

@Controller("ai")
export class AIController {
  constructor(private readonly aiService: AIService) {}

  @UseGuards(JwtAuthGuard)
  @Post("review")
  reviewCode(
    @Request() req,
    @Body("code") code: string,
    @Body("language") language: string,
    @Body("locale") locale?: string,
  ) {
    return this.aiService.getAiResponse(
      { code, language: language || "text" },
      "code_review",
      { userId: req.user.userId, locale },
    );
  }

  @UseGuards(JwtAuthGuard)
  @Post("code-review")
  reviewCodeAlias(
    @Request() req,
    @Body("code") code: string,
    @Body("language") language: string,
    @Body("locale") locale?: string,
  ) {
    return this.reviewCode(req, code, language, locale);
  }

  @UseGuards(JwtAuthGuard)
  @Post("explain")
  explainCode(
    @Request() req,
    @Body("code") code: string,
    @Body("language") language: string,
    @Body("level") level: string,
    @Body("locale") locale?: string,
  ) {
    return this.aiService.getAiResponse(
      { code, language: language || "text", level: level || "intermediate" },
      "code_explanation",
      { userId: req.user.userId, level, locale },
    );
  }

  @UseGuards(JwtAuthGuard)
  @Post("mentor-match")
  matchMentor(@Request() req, @Body() body: any) {
    return this.aiService.getAiResponse(
      { user: body.user, mentors: body.mentors },
      "mentor_matching",
      { userId: req.user.userId, locale: body.locale },
    );
  }

  @UseGuards(JwtAuthGuard)
  @Post("mentorship-match")
  matchMentorAlias(@Request() req, @Body() body: any) {
    return this.matchMentor(req, body);
  }
}
