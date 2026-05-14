import {
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as admin from "firebase-admin";

@Injectable()
export class PushService implements OnModuleInit {
  private readonly logger = new Logger("PushService");

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    if (admin.apps.length) return;

    const serviceAccountPath = this.configService.get<string>(
      "FIREBASE_SERVICE_ACCOUNT_PATH",
    );
    const serviceAccountJson = this.configService.get<string>(
      "FIREBASE_SERVICE_ACCOUNT_JSON",
    );
    const projectId = this.configService.get<string>("FIREBASE_PROJECT_ID");
    const clientEmail = this.configService.get<string>("FIREBASE_CLIENT_EMAIL");
    const privateKey = this.configService.get<string>("FIREBASE_PRIVATE_KEY");

    try {
      if (serviceAccountPath) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
        this.logger.log("Firebase FCM initialized from service account path");
        return;
      }

      if (serviceAccountJson) {
        admin.initializeApp({
          credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
        });
        this.logger.log("Firebase FCM initialized from service account JSON");
        return;
      }

      if (projectId && clientEmail && privateKey) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey: privateKey.replace(/\\n/g, "\n"),
          }),
        });
        this.logger.log("Firebase FCM initialized from env credentials");
        return;
      }

      this.logger.warn("Firebase FCM not configured; push delivery disabled");
    } catch (error) {
      this.logger.error("Firebase FCM initialization failed", error);
    }
  }

  get configured() {
    return admin.apps.length > 0;
  }

  async sendPushNotification(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ) {
    if (!admin.apps.length) {
      throw new ServiceUnavailableException("Firebase FCM is not configured");
    }

    try {
      await admin.messaging().send({
        notification: { title, body },
        token,
        data: data || {},
      });
      this.logger.log(`FCM sent to ${token}: ${title}`);
    } catch (error) {
      this.logger.error("FCM send error:", error);
    }
  }
}
