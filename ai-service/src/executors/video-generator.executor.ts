import { BaseExecutor, ExecutionContext, ExecutionResult } from './base.executor';
import { AIProvider } from './ai-providers.config';

export class VideoGeneratorExecutor extends BaseExecutor {
  async execute(context: ExecutionContext): Promise<ExecutionResult> {
    const { prompt, parameters } = context;

    try {
      const videoUrl = await this.generateVideo(prompt, parameters);

      // Download and upload to Supabase
      const videoBuffer = await this.downloadFile(videoUrl);
      const storagePath = await this.uploadToStorage(
        videoBuffer,
        `${this.provider}-${Date.now()}.mp4`,
        'video/mp4',
        context.userId
      );

      return {
        success: true,
        outputs: [
          {
            type: 'video',
            url: storagePath,
            metadata: {
              provider: this.provider,
              prompt,
              duration: parameters.duration || 10,
            },
          },
        ],
      };
    } catch (error) {
      return {
        success: false,
        outputs: [],
        error: error.message,
      };
    }
  }

  private async generateVideo(prompt: string, params: any): Promise<string> {
    const config = this.config;

    // Replicate models
    if (config.replicate_model) {
      const output: any = await this.callReplicate(config.replicate_model, {
        prompt,
        duration: params.duration || 10,
        aspect_ratio: params.aspect_ratio || '16:9',
        ...params,
      });

      return Array.isArray(output) ? output[0] : output;
    }

    // Direct API calls
    switch (this.provider) {
      case AIProvider.RUNWAY_GEN3:
        return await this.callRunway(prompt, params);

      default:
        throw new Error(`Video provider ${this.provider} not implemented`);
    }
  }

  private async callRunway(prompt: string, params: any): Promise<string> {
    // Runway Gen-3 API call
    const response = await this.callExternalAPI(
      'https://api.runwayml.com/v1/generate',
      'POST',
      {
        prompt,
        duration: params.duration || 10,
        aspect_ratio: params.aspect_ratio || '16:9',
      },
      {
        Authorization: `Bearer ${process.env.RUNWAY_API_KEY}`,
      }
    );

    // Poll for completion
    let jobId = response.id;
    let videoUrl: string;

    while (true) {
      const status = await this.callExternalAPI(
        `https://api.runwayml.com/v1/generate/${jobId}`,
        'GET',
        undefined,
        {
          Authorization: `Bearer ${process.env.RUNWAY_API_KEY}`,
        }
      );

      if (status.status === 'completed') {
        videoUrl = status.output_url;
        break;
      } else if (status.status === 'failed') {
        throw new Error('Video generation failed');
      }

      await new Promise(resolve => setTimeout(resolve, 5000)); // Poll every 5s
    }

    return videoUrl;
  }
}
