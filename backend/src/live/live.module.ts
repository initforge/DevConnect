import { Module } from '@nestjs/common';
import { LiveGateway } from './live.gateway';

import { LiveService } from './live.service';
import { DatabaseModule } from '../common/database/database.module';

@Module({
  imports: [DatabaseModule],
  providers: [LiveGateway, LiveService],
})
export class LiveModule {}
