import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import {
  HealthCheck,
  HealthCheckService,
  TypeOrmHealthIndicator,
  MemoryHealthIndicator,
  DiskHealthIndicator,
} from '@nestjs/terminus';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private memory: MemoryHealthIndicator,
    private disk: DiskHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({
    status: 200,
    description: 'The service is healthy',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        info: { type: 'object' },
        error: { type: 'object' },
        details: { type: 'object' },
      },
    },
  })
  @ApiResponse({ status: 503, description: 'The service is unhealthy' })
  check() {
    return this.health.check([
      // Database health
      () => this.db.pingCheck('database', { timeout: 3000 }),

      // Memory heap should not exceed 150MB
      () =>
        this.memory.checkHeap('memory_heap', 150 * 1024 * 1024),

      // Memory RSS should not exceed 300MB
      () =>
        this.memory.checkRSS('memory_rss', 300 * 1024 * 1024),

      // Disk storage should not exceed 90% of available space
      () =>
        this.disk.checkStorage('storage', {
          path: '/',
          thresholdPercent: 0.9,
        }),
    ]);
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness check - is the service ready to accept traffic?' })
  @ApiResponse({ status: 200, description: 'Service is ready' })
  async ready() {
    return this.health.check([
      () => this.db.pingCheck('database', { timeout: 3000 }),
    ]);
  }

  @Get('live')
  @ApiOperation({ summary: 'Liveness check - is the service alive?' })
  @ApiResponse({ status: 200, description: 'Service is alive' })
  live() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }
}
