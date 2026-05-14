import { Processor, WorkerHost } from "@nestjs/bullmq";
import { Job } from "bullmq";
import { Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import axios from "axios";

@Processor("ai")
export class AIProcessor extends WorkerHost {
  private readonly logger = new Logger(AIProcessor.name);

  constructor(private configService: ConfigService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const { payload, type, userId, locale } = job.data;
    this.logger.log(
      `Processing AI job ${job.id} type=${type} user=${userId}`,
    );

    const timeout = Number(
      this.configService.get<string>("AI_TIMEOUT_MS") || 30000,
    );

    // 1. Try OpenRouter API
    const openRouterKey = this.configService.get<string>("OPENROUTER_API_KEY");
    if (openRouterKey) {
      return this.callOpenRouter(openRouterKey, type, payload, locale, timeout);
    }

    // 2. Try external AI worker
    const workerUrl = this.configService.get<string>("AI_WORKER_URL");
    const workerSecret = this.configService.get<string>("AI_WORKER_SECRET");
    if (workerUrl && !workerUrl.includes("your-")) {
      return this.callExternalWorker(workerUrl, workerSecret, type, payload, locale, timeout);
    }

    this.logger.warn(
      `No AI provider configured (OPENROUTER_API_KEY or AI_WORKER_URL). Returning error.`,
    );
    throw new Error(
      locale === "vi"
        ? "Chưa cấu hình AI provider. Vui lòng thiết lập OPENROUTER_API_KEY."
        : "No AI provider configured. Please set OPENROUTER_API_KEY.",
    );
  }

  private async callExternalWorker(
    workerUrl: string,
    workerSecret: string | undefined,
    type: string,
    payload: any,
    locale: string,
    timeout: number,
  ) {
    const routeMap: Record<string, string> = {
      code_review: "code-review",
      code_explanation: "explain",
    };
    const route = routeMap[type];
    if (!route) throw new Error(`Unknown AI job type: ${type}`);

    const body = { ...payload, locale };
    try {
      const response = await axios.post(`${workerUrl}/v1/${route}`, body, {
        headers: {
          "Content-Type": "application/json",
          ...(workerSecret ? { "x-devconnect-ai-key": workerSecret } : {}),
        },
        timeout,
      });
      return response.data;
    } catch (error) {
      this.logger.error(
        `AI Worker call failed: ${error?.response?.status || error?.message}`,
      );
      throw new Error(`AI Worker call failed: ${error?.message}`);
    }
  }

  private async callOpenRouter(
    apiKey: string,
    type: string,
    payload: any,
    locale: string,
    timeout: number,
  ) {
    const vi = locale === "vi";
    const langInstruction = vi
      ? "Trả lời hoàn toàn bằng tiếng Việt."
      : "Respond entirely in English.";

    let prompt: string;

    if (type === "code_review") {
      prompt = `You are a senior code reviewer. Analyze the following ${payload.language || "code"} snippet and return a JSON object with this exact structure:
{
  "score": <number 1-10>,
  "summary": "<brief overall assessment>",
  "issues": [
    {
      "type": "<quality|best_practice|performance|security>",
      "severity": "<high|medium|low>",
      "line": <line number>,
      "message": "<what is the problem>",
      "fix": "<how to fix it>"
    }
  ]
}

Rules:
- Score reflects overall quality (10 = perfect, 1 = terrible)
- Be specific: reference actual variable names, functions, and patterns from the code
- Each issue must reference the actual line number from the code
- If code is excellent, return fewer issues with score 9-10
- ${langInstruction}

Code:
\`\`\`
${payload.code}
\`\`\`

Return ONLY valid JSON, no markdown fences, no explanation outside the JSON.`;
    } else if (type === "code_explanation") {
      const level = payload.level || "intermediate";
      prompt = `You are a coding tutor. Explain the following ${payload.language || "code"} snippet for a ${level}-level developer. Return a JSON object with this exact structure:
{
  "level": "${level}",
  "explanation": "<clear explanation of what the code does, step by step>",
  "concepts": ["<concept1>", "<concept2>", ...],
  "complexity": "<time/space complexity description>",
  "alternatives": ["<alternative approach 1>", "<alternative approach 2>"]
}

Rules:
- Explanation must be specific to THIS code, referencing actual variables, functions, and logic
- Concepts should list programming concepts used in the code
- Alternatives should suggest genuinely different approaches
- ${langInstruction}

Code:
\`\`\`
${payload.code}
\`\`\`

Return ONLY valid JSON, no markdown fences, no explanation outside the JSON.`;
    } else {
      throw new Error(`Unknown AI job type: ${type}`);
    }

    try {
      const response = await axios.post(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          model: "google/gemini-2.0-flash-001",
          messages: [
            {
              role: "user",
              content: prompt,
            },
          ],
          temperature: 0.3,
          max_tokens: 2048,
        },
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${apiKey}`,
            "HTTP-Referer": "https://devconnect.app",
            "X-OpenRouter-Title": "DevConnect",
          },
          timeout,
        },
      );

      const text = response.data?.choices?.[0]?.message?.content || "";

      // Parse JSON from response (strip markdown fences if present)
      const jsonStr = text.replace(/```json\s*/g, "").replace(/```\s*/g, "").trim();
      const parsed = JSON.parse(jsonStr);

      this.logger.log(`OpenRouter response parsed successfully for type=${type}`);
      return parsed;
    } catch (error) {
      this.logger.error(
        `OpenRouter API call failed: ${error?.response?.status || error?.message}`,
      );
      if (error?.response?.data) {
        this.logger.error(
          `OpenRouter error detail: ${JSON.stringify(error.response.data)}`,
        );
      }
      throw new Error(`OpenRouter API call failed: ${error?.message}`);
    }
  }
}
