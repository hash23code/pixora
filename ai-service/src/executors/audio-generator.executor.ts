import { BaseExecutor, ExecutionContext, ExecutionResult } from './base.executor';
import { AIProvider } from './ai-providers.config';

export class AudioGeneratorExecutor extends BaseExecutor {
  async execute(context: ExecutionContext): Promise<ExecutionResult> {
    const { prompt, parameters } = context;

    try {
      const audioUrl = await this.generateAudio(prompt, parameters);

      const audioBuffer = await this.downloadFile(audioUrl);
      const storagePath = await this.uploadToStorage(
        audioBuffer,
        `${this.provider}-${Date.now()}.mp3`,
        'audio/mpeg',
        context.userId
      );

      return {
        success: true,
        outputs: [
          {
            type: 'audio',
            url: storagePath,
            metadata: {
              provider: this.provider,
              text: prompt,
              voice: parameters.voice,
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

  private async generateAudio(text: string, params: any): Promise<string> {
    switch (this.provider) {
      case AIProvider.ELEVEN_LABS:
        return await this.callElevenLabs(text, params);

      case AIProvider.SUNO_AI:
        return await this.callSunoAI(text, params);

      default:
        throw new Error(`Audio provider ${this.provider} not implemented`);
    }
  }

  private async callElevenLabs(text: string, params: any): Promise<string> {
    const voiceId = this.getElevenLabsVoiceId(params.voice || 'Antoni');

    const response = await this.callExternalAPI(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      'POST',
      {
        text,
        model_id: 'eleven_multilingual_v2',
        voice_settings: {
          stability: params.stability || 0.5,
          similarity_boost: params.similarity_boost || 0.75,
        },
      },
      {
        'xi-api-key': process.env.ELEVEN_LABS_API_KEY!,
        Accept: 'audio/mpeg',
      }
    );

    // Response is audio buffer, convert to base64 data URL
    return `data:audio/mpeg;base64,${Buffer.from(response).toString('base64')}`;
  }

  private async callSunoAI(prompt: string, params: any): Promise<string> {
    const response = await this.callExternalAPI(
      'https://api.suno.ai/v1/generate',
      'POST',
      {
        prompt,
        make_instrumental: params.instrumental || false,
        duration: params.duration || 30,
      },
      {
        Authorization: `Bearer ${process.env.SUNO_API_KEY}`,
      }
    );

    return response.audio_url;
  }

  private getElevenLabsVoiceId(voiceName: string): string {
    const voiceMap: Record<string, string> = {
      Antoni: '21m00Tcm4TlvDq8ikWAM',
      Bella: 'EXAVITQu4vr4xnSDxMaL',
      Adam: 'pNInz6obpgDQGcFmaJgB',
      Elli: 'MF3mGyEYCl7XYWbV9V6O',
      Josh: 'TxGEqnHWrfWFTfGW9XjX',
      Rachel: '21m00Tcm4TlvDq8ikWAM',
      Arnold: 'VR6AewLTigWG4xSOukaG',
      Domi: 'AZnzlk1XvdvUeBnXmlld',
    };

    return voiceMap[voiceName] || voiceMap.Antoni;
  }
}
