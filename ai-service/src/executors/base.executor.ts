import { AIProvider, AI_PROVIDERS, ProviderConfig } from './ai-providers.config';
import Replicate from 'replicate';
import Anthropic from '@anthropic-ai/sdk';
import fetch from 'node-fetch';

export interface ExecutionContext {
  userId: string;
  projectId: string;
  jobId: string;
  prompt: string;
  parameters: Record<string, any>;
}

export interface ExecutionResult {
  success: boolean;
  outputs: Array<{
    type: 'image' | 'video' | 'audio' | 'text';
    url?: string;
    data?: string;
    metadata?: Record<string, any>;
  }>;
  metadata?: Record<string, any>;
  error?: string;
}

export abstract class BaseExecutor {
  protected config: ProviderConfig;
  protected replicate: Replicate;
  protected anthropic: Anthropic;

  constructor(protected provider: AIProvider) {
    this.config = AI_PROVIDERS[provider];

    // Initialize Replicate client
    this.replicate = new Replicate({
      auth: process.env.REPLICATE_API_TOKEN!,
    });

    // Initialize Anthropic client
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY!,
    });
  }

  abstract execute(context: ExecutionContext): Promise<ExecutionResult>;

  /**
   * Upload result to Supabase Storage
   */
  protected async uploadToStorage(
    buffer: Buffer,
    filename: string,
    contentType: string,
    userId: string
  ): Promise<string> {
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );

    const path = `${userId}/${Date.now()}-${filename}`;

    const { data, error } = await supabase.storage
      .from('ai-outputs')
      .upload(path, buffer, {
        contentType,
        cacheControl: '3600',
      });

    if (error) throw error;

    const { data: publicUrl } = supabase.storage
      .from('ai-outputs')
      .getPublicUrl(path);

    return publicUrl.publicUrl;
  }

  /**
   * Download file from URL
   */
  protected async downloadFile(url: string): Promise<Buffer> {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Failed to download: ${response.statusText}`);
    return Buffer.from(await response.arrayBuffer());
  }

  /**
   * Call Replicate model
   */
  protected async callReplicate(
    model: string,
    input: Record<string, any>
  ): Promise<any> {
    try {
      const output = await this.replicate.run(model as any, { input });
      return output;
    } catch (error) {
      console.error('Replicate error:', error);
      throw new Error(`Replicate call failed: ${error.message}`);
    }
  }

  /**
   * Call external API
   */
  protected async callExternalAPI(
    endpoint: string,
    method: string = 'POST',
    body?: any,
    headers?: Record<string, string>
  ): Promise<any> {
    const response = await fetch(endpoint, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      throw new Error(`API call failed: ${response.statusText}`);
    }

    return await response.json();
  }

  /**
   * Get estimated cost
   */
  public getEstimatedCost(): number {
    return this.config.costPerRun;
  }

  /**
   * Get max duration
   */
  public getMaxDuration(): number {
    return this.config.maxDuration;
  }
}
