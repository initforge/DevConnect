import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as sharp from 'sharp';
import * as Minio from 'minio';

@Injectable()
export class MediaService implements OnModuleInit {
  private minioClient: Minio.Client;
  private bucketName: string;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    this.bucketName = this.configService.get<string>('MINIO_BUCKET') || 'devconnect';
    this.minioClient = new Minio.Client({
      endPoint: this.configService.get<string>('MINIO_ENDPOINT') || 'localhost',
      port: parseInt(this.configService.get<string>('MINIO_PORT')) || 9000,
      useSSL: this.configService.get<string>('MINIO_USE_SSL') === 'true',
      accessKey: this.configService.get<string>('MINIO_ACCESS_KEY') || 'minioadmin',
      secretKey: this.configService.get<string>('MINIO_SECRET_KEY') || 'minioadmin',
    });

    // Ensure bucket exists
    const exists = await this.minioClient.bucketExists(this.bucketName);
    if (!exists) {
      await this.minioClient.makeBucket(this.bucketName);
      // Set public policy for the bucket
      const policy = {
        Version: '2012-10-17',
        Statement: [
          {
            Action: ['s3:GetBucketLocation', 's3:ListBucket'],
            Effect: 'Allow',
            Principal: { AWS: ['*'] },
            Resource: [`arn:aws:s3:::${this.bucketName}`],
          },
          {
            Action: ['s3:GetObject'],
            Effect: 'Allow',
            Principal: { AWS: ['*'] },
            Resource: [`arn:aws:s3:::${this.bucketName}/*`],
          },
        ],
      };
      await this.minioClient.setBucketPolicy(this.bucketName, JSON.stringify(policy));
    }
  }

  async processImage(file: Express.Multer.File, userId: string) {
    if (!file || !file.buffer) {
      throw new Error('No file received or file buffer is empty');
    }
    console.log(`[Media] Upload: ${file.originalname} (${file.buffer.length} bytes, mime: ${file.mimetype}) by user ${userId}`);

    const filename = `${Date.now()}-${file.originalname}`;
    const objectName = `posts/${userId}/${filename}`;
    const thumbName = `posts/${userId}/thumb-${filename}`;

    // 1. Process Original (Max 1200px)
    const processedBuffer = await sharp(file.buffer)
      .resize({ width: 1200, withoutEnlargement: true })
      .toBuffer();

    // 2. Process Thumbnail (300px)
    const thumbBuffer = await sharp(file.buffer)
      .resize({ width: 300 })
      .toBuffer();

    // 3. Upload to MinIO
    await this.minioClient.putObject(this.bucketName, objectName, processedBuffer);
    await this.minioClient.putObject(this.bucketName, thumbName, thumbBuffer);

    const publicUrl = this.configService.get<string>('MINIO_PUBLIC_URL');
    const baseUrl = publicUrl
      ? `${publicUrl}/${this.bucketName}`
      : `http://localhost/storage/${this.bucketName}`;

    return {
      fullUrl: `${baseUrl}/${objectName}`,
      thumbnailUrl: `${baseUrl}/${thumbName}`,
    };
  }
}
