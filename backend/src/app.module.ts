import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { HealthModule } from './modules/health/health.module';
// Import other modules as we build them
// import { AuthModule } from './modules/auth/auth.module';
// import { UsersModule } from './modules/users/users.module';
// import { ProjectsModule } from './modules/projects/projects.module';
// import { BoardsModule } from './modules/boards/boards.module';
// import { AssetsModule } from './modules/assets/assets.module';
// import { TokensModule } from './modules/tokens/tokens.module';
// import { BillingModule } from './modules/billing/billing.module';
// import { CollaboratorsModule } from './modules/collaborators/collaborators.module';
// import { AgentModule } from './modules/agent/agent.module';

@Module({
  imports: [
    // ==================== CONFIG ====================
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // ==================== DATABASE ====================
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.get<string>('DATABASE_URL'),
        ssl: configService.get<boolean>('DATABASE_SSL')
          ? { rejectUnauthorized: false }
          : false,
        autoLoadEntities: true,
        synchronize: false, // NEVER true in production - use migrations
        logging: configService.get<string>('NODE_ENV') === 'development',
        extra: {
          max: configService.get<number>('DATABASE_POOL_MAX', 10),
          min: configService.get<number>('DATABASE_POOL_MIN', 2),
        },
      }),
    }),

    // ==================== RATE LIMITING ====================
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        ttl: configService.get<number>('RATE_LIMIT_TTL', 60),
        limit: configService.get<number>('RATE_LIMIT_LIMIT', 100),
      }),
    }),

    // ==================== FEATURE MODULES ====================
    HealthModule,
    // AuthModule,
    // UsersModule,
    // ProjectsModule,
    // BoardsModule,
    // AssetsModule,
    // TokensModule,
    // BillingModule,
    // CollaboratorsModule,
    // AgentModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
