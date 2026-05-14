import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { InteractionsController } from './interactions.controller';
import { DatabaseModule } from '../common/database/database.module';
import { RedisModule } from '../common/redis/redis.module';

@Module({
  imports: [DatabaseModule, RedisModule],
  controllers: [UsersController, InteractionsController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
