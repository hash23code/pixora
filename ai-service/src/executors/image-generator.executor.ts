import { BaseExecutor, ExecutionContext, ExecutionResult } from './base.executor';
import { AIProvider, AI_PROVIDERS } from './ai-providers.config';

export class ImageGeneratorExecutor extends BaseExecutor {
  async execute(context: ExecutionContext): Promise<ExecutionResult> {
    const { prompt, parameters } = context;
    const config = AI_PROVIDERS[this.provider];

    try {
      let imageUrl: string;

      // Use Replicate if model is specified
      if (config.replicate_model) {
        const output: any = await this.callReplicate(config.replicate_model, {
          prompt,
          ...parameters,
        });

        // Replicate returns array of URLs or single URL
        imageUrl = Array.isArray(output) ? output[0] : output;
      }
      // Direct API calls for specific providers
      else {
        switch (this.provider) {
          case AIProvider.STABILITY_AI:
            imageUrl = await this.callStabilityAI(prompt, parameters);
            break;

          case AIProvider.DALL_E_3:
            imageUrl = await this.callDALLE(prompt, parameters);
            break;

          default:
            throw new Error(`Provider ${this.provider} not implemented`);
        }
      }

      // Download and upload to Supabase Storage
      const imageBuffer = await this.downloadFile(imageUrl);
      const storagePath = await this.uploadToStorage(
        imageBuffer,
        `${this.provider}-${Date.now()}.png`,
        'image/png',
        context.userId
      );

      return {
        success: true,
        outputs: [
          {
            type: 'image',
            url: storagePath,
            metadata: {
              provider: this.provider,
              prompt,
              parameters,
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

  private async callStabilityAI(prompt: string, params: any): Promise<string> {
    const response = await this.callExternalAPI(
      'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
      'POST',
      {
        text_prompts: [{ text: prompt }],
        cfg_scale: params.cfg_scale || 7,
        height: params.height || 1024,
        width: params.width || 1024,
        samples: 1,
        steps: params.steps || 30,
      },
      {
        Authorization: `Bearer ${process.env.STABILITY_API_KEY}`,
      }
    );

    return `data:image/png;base64,${response.artifacts[0].base64}`;
  }

  private async callDALLE(prompt: string, params: any): Promise<string> {
    const response = await this.callExternalAPI(
      'https://api.openai.com/v1/images/generations',
      'POST',
      {
        model: 'dall-e-3',
        prompt,
        n: 1,
        size: params.size || '1024x1024',
        quality: params.quality || 'hd',
      },
      {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      }
    );

    return response.data[0].url;
  }
}
