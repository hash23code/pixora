import { BaseExecutor, ExecutionContext, ExecutionResult } from './base.executor';
import { AIProvider, AI_PROVIDERS, getProvidersByCategory } from './ai-providers.config';
import { VideoGeneratorExecutor } from './video-generator.executor';
import { ImageGeneratorExecutor } from './image-generator.executor';
import { AudioGeneratorExecutor } from './audio-generator.executor';

/**
 * ADVERTISING AGENT - Crée des campagnes publicitaires complètes
 *
 * Fonctionnalités:
 * 1. Analyse le brief client (produit, audience, objectif)
 * 2. Génère un script publicitaire optimisé
 * 3. Crée les visuels (images + vidéo)
 * 4. Génère la voix-off professionnelle
 * 5. Assemble tout en publicité finale
 *
 * Formats supportés:
 * - Social media ads (Instagram, Facebook, TikTok)
 * - Display ads (bannières web)
 * - Video ads (YouTube, TV)
 * - Story ads (Instagram Stories, Snapchat)
 * - Carousel ads (multiple images)
 */

export interface AdBrief {
  // Produit/Service
  productName: string;
  productDescription: string;
  productCategory: string;
  uniqueSellingPoints: string[];

  // Audience
  targetAudience: {
    age?: string;
    gender?: string;
    interests?: string[];
    painPoints?: string[];
  };

  // Objectifs
  campaignGoal: 'awareness' | 'consideration' | 'conversion';
  callToAction: string;

  // Contraintes créatives
  brandGuidelines?: {
    colors?: string[];
    fonts?: string[];
    tone?: 'professional' | 'casual' | 'humorous' | 'inspirational';
    keywords?: string[];
  };

  // Format
  adFormat: 'social' | 'display' | 'video' | 'story' | 'carousel';
  duration?: number; // For video ads (seconds)
  dimensions?: string; // e.g., "1080x1920", "1200x628"
}

export interface AdCampaignResult {
  // Script & Copy
  script: {
    hook: string; // First 3 seconds
    body: string; // Main message
    cta: string; // Call to action
    hashtags?: string[];
  };

  // Visual Assets
  assets: Array<{
    type: 'image' | 'video' | 'audio';
    url: string;
    purpose: string; // e.g., "hero-image", "background-music", "voiceover"
    metadata: Record<string, any>;
  }>;

  // Performance Estimates
  estimates: {
    engagementRate: number; // Predicted %
    clickThroughRate: number; // Predicted %
    conversionPotential: 'low' | 'medium' | 'high';
  };

  // Variations (A/B testing)
  variations?: Array<{
    id: string;
    script: any;
    assets: any[];
    differentiator: string; // What's different
  }>;
}

export class AdvertisingAgentExecutor extends BaseExecutor {
  private videoExecutor: VideoGeneratorExecutor;
  private imageExecutor: ImageGeneratorExecutor;
  private audioExecutor: AudioGeneratorExecutor;

  constructor() {
    super(AIProvider.ANTHROPIC_CLAUDE);

    this.videoExecutor = new VideoGeneratorExecutor(AIProvider.RUNWAY_GEN3);
    this.imageExecutor = new ImageGeneratorExecutor(AIProvider.FLUX);
    this.audioExecutor = new AudioGeneratorExecutor(AIProvider.ELEVEN_LABS);
  }

  async execute(context: ExecutionContext): Promise<ExecutionResult> {
    try {
      const brief: AdBrief = context.parameters.brief;

      console.log(`[Ad Agent] Creating campaign for: ${brief.productName}`);

      // STEP 1: Generate ad script using Claude
      const script = await this.generateAdScript(brief);

      // STEP 2: Create visual assets based on format
      const visualAssets = await this.createVisualAssets(brief, script, context);

      // STEP 3: Generate voiceover (if video/audio format)
      const audioAssets = await this.createAudioAssets(brief, script, context);

      // STEP 4: Generate A/B test variations
      const variations = await this.generateVariations(brief, script, context);

      // STEP 5: Predict performance
      const estimates = await this.estimatePerformance(brief, script);

      const result: AdCampaignResult = {
        script,
        assets: [...visualAssets, ...audioAssets],
        estimates,
        variations,
      };

      return {
        success: true,
        outputs: [
          {
            type: 'text',
            data: JSON.stringify(result, null, 2),
            metadata: {
              brief,
              totalAssets: result.assets.length,
              variations: result.variations?.length || 0,
            },
          },
        ],
        metadata: {
          adFormat: brief.adFormat,
          estimatedPerformance: estimates.conversionPotential,
        },
      };
    } catch (error) {
      console.error('[Ad Agent] Error:', error);
      return {
        success: false,
        outputs: [],
        error: error.message,
      };
    }
  }

  /**
   * STEP 1: Generate optimized ad script using Claude
   */
  private async generateAdScript(brief: AdBrief): Promise<any> {
    const prompt = this.buildScriptPrompt(brief);

    const response = await this.anthropic.messages.create({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 2000,
      temperature: 0.7,
      system: `You are an expert advertising copywriter with 20 years of experience creating high-converting ad campaigns.
Your specialty is crafting scripts that:
- Hook attention in the first 3 seconds
- Address audience pain points
- Highlight unique selling propositions
- Drive action with compelling CTAs
- Match brand tone and voice

Always structure your response as JSON with: hook, body, cta, hashtags.`,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    const content = response.content[0];
    if (content.type === 'text') {
      // Extract JSON from response
      const jsonMatch = content.text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    }

    throw new Error('Failed to generate ad script');
  }

  /**
   * Build prompt for script generation
   */
  private buildScriptPrompt(brief: AdBrief): string {
    return `Create an advertising script for the following brief:

**Product:**
- Name: ${brief.productName}
- Description: ${brief.productDescription}
- Category: ${brief.productCategory}
- USPs: ${brief.uniqueSellingPoints.join(', ')}

**Target Audience:**
- Demographics: ${brief.targetAudience.age || 'All ages'}, ${brief.targetAudience.gender || 'All genders'}
- Interests: ${brief.targetAudience.interests?.join(', ') || 'General'}
- Pain Points: ${brief.targetAudience.painPoints?.join(', ') || 'None specified'}

**Campaign:**
- Goal: ${brief.campaignGoal}
- CTA: ${brief.callToAction}
- Format: ${brief.adFormat}
${brief.duration ? `- Duration: ${brief.duration} seconds` : ''}

**Brand Guidelines:**
- Tone: ${brief.brandGuidelines?.tone || 'professional'}
- Keywords: ${brief.brandGuidelines?.keywords?.join(', ') || 'None'}

Create a ${brief.adFormat} ad script with:
1. **Hook** (first 3 seconds) - Must grab attention immediately
2. **Body** (main message) - Address pain points, showcase USPs
3. **CTA** (call to action) - Clear, actionable, compelling
4. **Hashtags** (if social media) - 3-5 relevant hashtags

Format as JSON: { "hook": "...", "body": "...", "cta": "...", "hashtags": ["..."] }`;
  }

  /**
   * STEP 2: Create visual assets based on format
   */
  private async createVisualAssets(
    brief: AdBrief,
    script: any,
    context: ExecutionContext
  ): Promise<any[]> {
    const assets: any[] = [];

    switch (brief.adFormat) {
      case 'video':
      case 'story':
        // Generate video ad
        const videoPrompt = `Create a ${brief.duration || 15}-second video ad for ${brief.productName}.
Style: ${brief.brandGuidelines?.tone || 'professional'}.
Scene: ${script.hook} ${script.body}.
Colors: ${brief.brandGuidelines?.colors?.join(', ') || 'vibrant, modern'}.
Cinematic, high-quality, product-focused.`;

        const videoResult = await this.videoExecutor.execute({
          ...context,
          prompt: videoPrompt,
          parameters: {
            duration: brief.duration || 15,
            aspect_ratio: brief.adFormat === 'story' ? '9:16' : '16:9',
          },
        });

        if (videoResult.success) {
          assets.push(...videoResult.outputs.map(output => ({
            type: 'video',
            url: output.url,
            purpose: 'main-video',
            metadata: output.metadata,
          })));
        }
        break;

      case 'social':
      case 'display':
        // Generate static image ad
        const imagePrompt = `Create a ${brief.adFormat} ad image for ${brief.productName}.
Text overlay: "${script.hook}"
Style: ${brief.brandGuidelines?.tone || 'professional'}, modern, eye-catching
Colors: ${brief.brandGuidelines?.colors?.join(', ') || 'bold, vibrant'}
Product focus, high-quality, professional photography style.
${brief.dimensions || '1080x1080'} dimensions.`;

        const imageResult = await this.imageExecutor.execute({
          ...context,
          prompt: imagePrompt,
          parameters: {
            aspect_ratio: '1:1', // Social media standard
            style: 'photographic',
          },
        });

        if (imageResult.success) {
          assets.push(...imageResult.outputs.map(output => ({
            type: 'image',
            url: output.url,
            purpose: 'hero-image',
            metadata: output.metadata,
          })));
        }
        break;

      case 'carousel':
        // Generate multiple images for carousel
        const carouselPrompts = [
          `Slide 1: ${script.hook} - Eye-catching hero image of ${brief.productName}`,
          `Slide 2: Feature highlight - ${brief.uniqueSellingPoints[0]}`,
          `Slide 3: Benefit showcase - ${brief.uniqueSellingPoints[1] || 'User benefit'}`,
          `Slide 4: Call to action - ${script.cta}`,
        ];

        for (const [index, slidePrompt] of carouselPrompts.entries()) {
          const slideResult = await this.imageExecutor.execute({
            ...context,
            prompt: `${slidePrompt}. Style: ${brief.brandGuidelines?.tone}, professional, cohesive brand look.`,
            parameters: { aspect_ratio: '1:1' },
          });

          if (slideResult.success) {
            assets.push(...slideResult.outputs.map(output => ({
              type: 'image',
              url: output.url,
              purpose: `carousel-slide-${index + 1}`,
              metadata: output.metadata,
            })));
          }
        }
        break;
    }

    return assets;
  }

  /**
   * STEP 3: Generate voiceover audio
   */
  private async createAudioAssets(
    brief: AdBrief,
    script: any,
    context: ExecutionContext
  ): Promise<any[]> {
    const assets: any[] = [];

    // Only generate audio for video/story formats
    if (brief.adFormat === 'video' || brief.adFormat === 'story') {
      const voiceoverText = `${script.hook}. ${script.body}. ${script.cta}`;

      const audioResult = await this.audioExecutor.execute({
        ...context,
        prompt: voiceoverText,
        parameters: {
          voice: this.selectVoice(brief),
          style: brief.brandGuidelines?.tone || 'professional',
        },
      });

      if (audioResult.success) {
        assets.push(...audioResult.outputs.map(output => ({
          type: 'audio',
          url: output.url,
          purpose: 'voiceover',
          metadata: output.metadata,
        })));
      }
    }

    return assets;
  }

  /**
   * Select appropriate voice based on brief
   */
  private selectVoice(brief: AdBrief): string {
    const tone = brief.brandGuidelines?.tone || 'professional';
    const gender = brief.targetAudience?.gender;

    const voiceMap: Record<string, string> = {
      professional_male: 'Antoni', // ElevenLabs voice
      professional_female: 'Bella',
      casual_male: 'Adam',
      casual_female: 'Elli',
      humorous_male: 'Josh',
      humorous_female: 'Rachel',
      inspirational_male: 'Arnold',
      inspirational_female: 'Domi',
    };

    const key = `${tone}_${gender === 'female' ? 'female' : 'male'}`;
    return voiceMap[key] || 'Antoni';
  }

  /**
   * STEP 4: Generate A/B test variations
   */
  private async generateVariations(
    brief: AdBrief,
    originalScript: any,
    context: ExecutionContext
  ): Promise<any[]> {
    // Generate 2 variations with different hooks/CTAs
    const variations: any[] = [];

    const variationPrompts = [
      'Create a variation with a more emotional hook',
      'Create a variation with a more urgent, scarcity-based CTA',
    ];

    for (const [index, varPrompt] of variationPrompts.entries()) {
      const varScript = await this.generateAdScript({
        ...brief,
        callToAction: `${varPrompt}: ${brief.callToAction}`,
      });

      variations.push({
        id: `var-${index + 1}`,
        script: varScript,
        assets: [], // Could generate different visuals too
        differentiator: varPrompt,
      });
    }

    return variations;
  }

  /**
   * STEP 5: Estimate performance using Claude
   */
  private async estimatePerformance(brief: AdBrief, script: any): Promise<any> {
    const prompt = `Analyze this ad campaign and predict its performance:

Product: ${brief.productName}
Target Audience: ${JSON.stringify(brief.targetAudience)}
Script: ${JSON.stringify(script)}
Format: ${brief.adFormat}

Provide performance estimates as JSON:
{
  "engagementRate": <number 0-100>,
  "clickThroughRate": <number 0-100>,
  "conversionPotential": "low" | "medium" | "high",
  "reasoning": "<brief explanation>"
}`;

    const response = await this.anthropic.messages.create({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 500,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    const content = response.content[0];
    if (content.type === 'text') {
      const jsonMatch = content.text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    }

    // Default estimates
    return {
      engagementRate: 3.5,
      clickThroughRate: 1.2,
      conversionPotential: 'medium',
    };
  }
}
