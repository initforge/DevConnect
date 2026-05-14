import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import axios from "axios";

@Injectable()
export class PlaygroundService {
  private readonly logger = new Logger("PlaygroundService");

  private static readonly LANG_MAP: Record<string, string> = {
    typescript: "typescript",
    javascript: "typescript",
    python: "python",
    dart: "dart",
    go: "go",
    java: "java",
    c: "c",
    cpp: "c++",
    rust: "rust",
    ruby: "ruby",
  };

  constructor(private configService: ConfigService) {}

  async runCode(sourceCode: string, language: string) {
    const pistonUrl =
      this.configService.get<string>("PISTON_URL") || "http://piston:2000";
    const timeout = Number(
      this.configService.get<string>("PISTON_TIMEOUT_MS") || 15000,
    );
    const pistonLang =
      PlaygroundService.LANG_MAP[language.toLowerCase()] ||
      language.toLowerCase();

    try {
      const response = await axios.post(
        `${pistonUrl}/api/v2/execute`,
        {
          language: pistonLang,
          version: "*",
          files: [{ content: sourceCode }],
        },
        { timeout },
      );

      const { run, language: lang, version } = response.data;
      return {
        stdout: run?.stdout || "",
        stderr: run?.stderr || "",
        output: run?.output || "",
        exitCode: run?.code ?? 0,
        language: lang,
        version,
      };
    } catch (error) {
      this.logger.error("Piston execution failed", error?.message);
      throw new ServiceUnavailableException(
        "Code execution service unavailable",
      );
    }
  }
}
