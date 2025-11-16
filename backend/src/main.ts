import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });

  const configService = app.get(ConfigService);

  // ==================== GLOBAL PREFIX ====================
  const apiPrefix = configService.get<string>('API_PREFIX', '/api');
  app.setGlobalPrefix(apiPrefix);

  // ==================== VERSIONING ====================
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // ==================== CORS ====================
  const corsOrigin = configService.get<string>('CORS_ORIGIN', 'http://localhost:3000');
  app.enableCors({
    origin: corsOrigin.split(','),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  });

  // ==================== SECURITY ====================
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'"],
          imgSrc: ["'self'", 'data:', 'https:'],
        },
      },
      crossOriginEmbedderPolicy: false,
    })
  );

  // ==================== VALIDATION ====================
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip non-whitelisted properties
      forbidNonWhitelisted: true, // Throw error if non-whitelisted properties
      transform: true, // Auto-transform payloads to DTO instances
      transformOptions: {
        enableImplicitConversion: true,
      },
    })
  );

  // ==================== SWAGGER / OpenAPI ====================
  if (configService.get<string>('NODE_ENV') !== 'production') {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Pixora API')
      .setDescription('API for Pixora - AI-Powered Marketing Asset Creation Platform')
      .setVersion('1.0')
      .addTag('auth', 'Authentication and authorization')
      .addTag('users', 'User management')
      .addTag('projects', 'Projects and workspaces')
      .addTag('boards', 'Whiteboard canvas state')
      .addTag('assets', 'Asset upload and management')
      .addTag('tokens', 'Token balance and transactions')
      .addTag('billing', 'Stripe payments and subscriptions')
      .addTag('collaborators', 'Project sharing and permissions')
      .addTag('agent', 'AI agent tool-router')
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup(`${apiPrefix}/docs`, app, document, {
      swaggerOptions: {
        persistAuthorization: true,
      },
    });

    console.log(`📚 Swagger docs available at http://localhost:${configService.get('PORT')}${apiPrefix}/docs`);
  }

  // ==================== START SERVER ====================
  const port = configService.get<number>('PORT', 4000);
  await app.listen(port);

  console.log(`🚀 Backend API running on http://localhost:${port}${apiPrefix}`);
  console.log(`🌍 Environment: ${configService.get('NODE_ENV')}`);
}

bootstrap().catch((error) => {
  console.error('❌ Error starting application:', error);
  process.exit(1);
});
