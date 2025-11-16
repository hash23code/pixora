/**
 * Configuration de tous les providers AI disponibles
 *
 * Services supportés:
 * - Images: Stability AI, DALL-E, Midjourney, Leonardo AI
 * - Vidéos: Runway, Kling AI, Pika Labs, Luma Dream Machine, Veo
 * - Audio: ElevenLabs, Murf AI, Suno AI
 * - Outils: Background removal, Upscaling, Face swap
 */

export enum AIProvider {
  // ==================== IMAGE GENERATION ====================
  STABILITY_AI = 'stability-ai',
  DALL_E_3 = 'dall-e-3',
  MIDJOURNEY = 'midjourney',
  LEONARDO_AI = 'leonardo-ai',
  IDEOGRAM = 'ideogram',
  FLUX = 'flux',

  // ==================== VIDEO GENERATION ====================
  RUNWAY_GEN3 = 'runway-gen3',
  KLING_AI = 'kling-ai',
  PIKA_LABS = 'pika-labs',
  LUMA_DREAM_MACHINE = 'luma-dream-machine',
  GOOGLE_VEO = 'google-veo',
  SYNTHESIA = 'synthesia',
  HEYGEN = 'heygen',

  // ==================== AUDIO & MUSIC ====================
  ELEVEN_LABS = 'eleven-labs',
  MURF_AI = 'murf-ai',
  SUNO_AI = 'suno-ai',
  UDIO = 'udio',

  // ==================== IMAGE TOOLS ====================
  REPLICATE_UPSCALE = 'replicate-upscale',
  BACKGROUND_REMOVER = 'background-remover',
  FACE_SWAP = 'face-swap',
  STYLE_TRANSFER = 'style-transfer',

  // ==================== VIDEO TOOLS ====================
  VIDEO_UPSCALER = 'video-upscaler',
  VIDEO_INTERPOLATION = 'video-interpolation',

  // ==================== TEXT & COPY ====================
  ANTHROPIC_CLAUDE = 'anthropic-claude',
  GPT4 = 'gpt4',
}

export interface ProviderConfig {
  id: AIProvider;
  name: string;
  category: 'image' | 'video' | 'audio' | 'tool' | 'text';
  description: string;
  costPerRun: number; // in tokens
  maxDuration: number; // seconds
  outputFormats: string[];
  features: string[];
  replicate_model?: string; // For Replicate-hosted models
  api_endpoint?: string; // For direct API calls
}

export const AI_PROVIDERS: Record<AIProvider, ProviderConfig> = {
  // ==================== IMAGE GENERATION ====================
  [AIProvider.STABILITY_AI]: {
    id: AIProvider.STABILITY_AI,
    name: 'Stability AI (SDXL)',
    category: 'image',
    description: 'High-quality image generation with SDXL',
    costPerRun: 100,
    maxDuration: 30,
    outputFormats: ['png', 'jpeg'],
    features: ['text-to-image', 'style-control', 'aspect-ratios'],
    api_endpoint: 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
  },

  [AIProvider.DALL_E_3]: {
    id: AIProvider.DALL_E_3,
    name: 'DALL-E 3',
    category: 'image',
    description: 'OpenAI DALL-E 3 for creative images',
    costPerRun: 150,
    maxDuration: 20,
    outputFormats: ['png'],
    features: ['text-to-image', 'high-quality', 'coherent-details'],
    api_endpoint: 'https://api.openai.com/v1/images/generations',
  },

  [AIProvider.MIDJOURNEY]: {
    id: AIProvider.MIDJOURNEY,
    name: 'Midjourney v6',
    category: 'image',
    description: 'Artistic image generation via Midjourney API',
    costPerRun: 200,
    maxDuration: 60,
    outputFormats: ['png'],
    features: ['artistic-style', 'text-to-image', 'upscaling'],
    replicate_model: 'tstramer/midjourney-v6:latest', // Via Replicate proxy
  },

  [AIProvider.LEONARDO_AI]: {
    id: AIProvider.LEONARDO_AI,
    name: 'Leonardo AI',
    category: 'image',
    description: 'Production-ready AI art generation',
    costPerRun: 120,
    maxDuration: 25,
    outputFormats: ['png', 'jpeg'],
    features: ['text-to-image', 'models-library', 'consistent-characters'],
    api_endpoint: 'https://cloud.leonardo.ai/api/rest/v1/generations',
  },

  [AIProvider.IDEOGRAM]: {
    id: AIProvider.IDEOGRAM,
    name: 'Ideogram',
    category: 'image',
    description: 'Text rendering in images',
    costPerRun: 100,
    maxDuration: 15,
    outputFormats: ['png'],
    features: ['text-to-image', 'text-rendering', 'typography'],
    replicate_model: 'ideogram-ai/ideogram-v2:latest',
  },

  [AIProvider.FLUX]: {
    id: AIProvider.FLUX,
    name: 'Flux Pro',
    category: 'image',
    description: 'Black Forest Labs Flux - state-of-the-art image generation',
    costPerRun: 180,
    maxDuration: 20,
    outputFormats: ['png'],
    features: ['text-to-image', 'photorealistic', 'fast-generation'],
    replicate_model: 'black-forest-labs/flux-pro:latest',
  },

  // ==================== VIDEO GENERATION ====================
  [AIProvider.RUNWAY_GEN3]: {
    id: AIProvider.RUNWAY_GEN3,
    name: 'Runway Gen-3 Alpha',
    category: 'video',
    description: 'Text/image to video with Gen-3',
    costPerRun: 500,
    maxDuration: 180,
    outputFormats: ['mp4'],
    features: ['text-to-video', 'image-to-video', '10s-duration', 'cinematic'],
    api_endpoint: 'https://api.runwayml.com/v1/generate',
  },

  [AIProvider.KLING_AI]: {
    id: AIProvider.KLING_AI,
    name: 'Kling AI',
    category: 'video',
    description: 'Chinese video generation model by Kuaishou',
    costPerRun: 400,
    maxDuration: 120,
    outputFormats: ['mp4'],
    features: ['text-to-video', 'long-duration', 'realistic-motion'],
    replicate_model: 'kuaishou/kling-v1:latest',
  },

  [AIProvider.PIKA_LABS]: {
    id: AIProvider.PIKA_LABS,
    name: 'Pika Labs',
    category: 'video',
    description: 'Creative video generation',
    costPerRun: 350,
    maxDuration: 90,
    outputFormats: ['mp4'],
    features: ['text-to-video', 'image-animation', '3s-duration'],
    api_endpoint: 'https://api.pika.art/v1/generate',
  },

  [AIProvider.LUMA_DREAM_MACHINE]: {
    id: AIProvider.LUMA_DREAM_MACHINE,
    name: 'Luma Dream Machine',
    category: 'video',
    description: 'High-quality text-to-video generation',
    costPerRun: 450,
    maxDuration: 150,
    outputFormats: ['mp4'],
    features: ['text-to-video', '5s-duration', 'smooth-motion'],
    replicate_model: 'lumalabs/ray:latest',
  },

  [AIProvider.GOOGLE_VEO]: {
    id: AIProvider.GOOGLE_VEO,
    name: 'Google Veo',
    category: 'video',
    description: 'Google\'s video generation model',
    costPerRun: 600,
    maxDuration: 200,
    outputFormats: ['mp4'],
    features: ['text-to-video', 'high-resolution', '1-minute-duration'],
    api_endpoint: 'https://generativelanguage.googleapis.com/v1/models/veo:generate',
  },

  [AIProvider.SYNTHESIA]: {
    id: AIProvider.SYNTHESIA,
    name: 'Synthesia',
    category: 'video',
    description: 'AI avatar videos for presentations',
    costPerRun: 300,
    maxDuration: 60,
    outputFormats: ['mp4'],
    features: ['avatar-video', 'text-to-speech', 'multilingual'],
    api_endpoint: 'https://api.synthesia.io/v2/videos',
  },

  [AIProvider.HEYGEN]: {
    id: AIProvider.HEYGEN,
    name: 'HeyGen',
    category: 'video',
    description: 'AI talking head videos',
    costPerRun: 280,
    maxDuration: 45,
    outputFormats: ['mp4'],
    features: ['avatar-video', 'lip-sync', 'custom-avatars'],
    api_endpoint: 'https://api.heygen.com/v1/video.generate',
  },

  // ==================== AUDIO & MUSIC ====================
  [AIProvider.ELEVEN_LABS]: {
    id: AIProvider.ELEVEN_LABS,
    name: 'ElevenLabs',
    category: 'audio',
    description: 'Realistic text-to-speech and voice cloning',
    costPerRun: 50,
    maxDuration: 10,
    outputFormats: ['mp3', 'wav'],
    features: ['text-to-speech', 'voice-cloning', 'multilingual'],
    api_endpoint: 'https://api.elevenlabs.io/v1/text-to-speech',
  },

  [AIProvider.MURF_AI]: {
    id: AIProvider.MURF_AI,
    name: 'Murf AI',
    category: 'audio',
    description: 'Professional voiceover generation',
    costPerRun: 40,
    maxDuration: 8,
    outputFormats: ['mp3'],
    features: ['text-to-speech', 'voice-library', 'emotional-tones'],
    api_endpoint: 'https://api.murf.ai/v1/speech',
  },

  [AIProvider.SUNO_AI]: {
    id: AIProvider.SUNO_AI,
    name: 'Suno AI',
    category: 'audio',
    description: 'AI music generation from text prompts',
    costPerRun: 200,
    maxDuration: 120,
    outputFormats: ['mp3'],
    features: ['text-to-music', 'vocals', 'multiple-genres'],
    api_endpoint: 'https://api.suno.ai/v1/generate',
  },

  [AIProvider.UDIO]: {
    id: AIProvider.UDIO,
    name: 'Udio',
    category: 'audio',
    description: 'High-quality AI music generation',
    costPerRun: 220,
    maxDuration: 150,
    outputFormats: ['mp3', 'wav'],
    features: ['text-to-music', 'full-songs', 'custom-lyrics'],
    api_endpoint: 'https://api.udio.com/v1/create',
  },

  // ==================== IMAGE TOOLS ====================
  [AIProvider.REPLICATE_UPSCALE]: {
    id: AIProvider.REPLICATE_UPSCALE,
    name: 'Image Upscaler (ESRGAN)',
    category: 'tool',
    description: '4x image upscaling with AI',
    costPerRun: 30,
    maxDuration: 15,
    outputFormats: ['png'],
    features: ['upscaling', '4x-resolution', 'enhance-details'],
    replicate_model: 'nightmareai/real-esrgan:latest',
  },

  [AIProvider.BACKGROUND_REMOVER]: {
    id: AIProvider.BACKGROUND_REMOVER,
    name: 'Background Remover',
    category: 'tool',
    description: 'AI-powered background removal',
    costPerRun: 20,
    maxDuration: 5,
    outputFormats: ['png'],
    features: ['background-removal', 'transparent-bg', 'high-accuracy'],
    replicate_model: 'pollinations/modnet:latest',
  },

  [AIProvider.FACE_SWAP]: {
    id: AIProvider.FACE_SWAP,
    name: 'Face Swap',
    category: 'tool',
    description: 'Swap faces in images',
    costPerRun: 80,
    maxDuration: 20,
    outputFormats: ['png'],
    features: ['face-swapping', 'realistic-blend', 'multiple-faces'],
    replicate_model: 'lucataco/faceswap:latest',
  },

  [AIProvider.STYLE_TRANSFER]: {
    id: AIProvider.STYLE_TRANSFER,
    name: 'Style Transfer',
    category: 'tool',
    description: 'Apply artistic styles to images',
    costPerRun: 60,
    maxDuration: 15,
    outputFormats: ['png'],
    features: ['style-transfer', 'artistic-filters', 'multiple-styles'],
    replicate_model: 'riffusion/style-transfer:latest',
  },

  // ==================== VIDEO TOOLS ====================
  [AIProvider.VIDEO_UPSCALER]: {
    id: AIProvider.VIDEO_UPSCALER,
    name: 'Video Upscaler',
    category: 'tool',
    description: 'AI video upscaling to 4K',
    costPerRun: 500,
    maxDuration: 300,
    outputFormats: ['mp4'],
    features: ['video-upscaling', '4k-output', 'frame-interpolation'],
    replicate_model: 'pollinations/video-upscale:latest',
  },

  [AIProvider.VIDEO_INTERPOLATION]: {
    id: AIProvider.VIDEO_INTERPOLATION,
    name: 'Video Frame Interpolation',
    category: 'tool',
    description: 'Increase video FPS with AI',
    costPerRun: 300,
    maxDuration: 200,
    outputFormats: ['mp4'],
    features: ['frame-interpolation', '60fps-output', 'smooth-motion'],
    replicate_model: 'pollinations/frame-interpolation:latest',
  },

  // ==================== TEXT & COPY ====================
  [AIProvider.ANTHROPIC_CLAUDE]: {
    id: AIProvider.ANTHROPIC_CLAUDE,
    name: 'Claude 3.5 Sonnet',
    category: 'text',
    description: 'Advanced copywriting and ad scripts',
    costPerRun: 30,
    maxDuration: 5,
    outputFormats: ['text'],
    features: ['copywriting', 'ad-scripts', 'multilingual', 'brand-voice'],
    api_endpoint: 'https://api.anthropic.com/v1/messages',
  },

  [AIProvider.GPT4]: {
    id: AIProvider.GPT4,
    name: 'GPT-4 Turbo',
    category: 'text',
    description: 'OpenAI GPT-4 for copy generation',
    costPerRun: 40,
    maxDuration: 5,
    outputFormats: ['text'],
    features: ['copywriting', 'creative-writing', 'structured-output'],
    api_endpoint: 'https://api.openai.com/v1/chat/completions',
  },
};

/**
 * Get providers by category
 */
export function getProvidersByCategory(category: ProviderConfig['category']): ProviderConfig[] {
  return Object.values(AI_PROVIDERS).filter(p => p.category === category);
}

/**
 * Get recommended provider for a task
 */
export function getRecommendedProvider(task: string): AIProvider {
  const taskLower = task.toLowerCase();

  // Video keywords
  if (taskLower.includes('video') || taskLower.includes('animation') || taskLower.includes('motion')) {
    if (taskLower.includes('realistic')) return AIProvider.RUNWAY_GEN3;
    if (taskLower.includes('long')) return AIProvider.KLING_AI;
    return AIProvider.LUMA_DREAM_MACHINE;
  }

  // Audio keywords
  if (taskLower.includes('voice') || taskLower.includes('speech') || taskLower.includes('narration')) {
    return AIProvider.ELEVEN_LABS;
  }
  if (taskLower.includes('music') || taskLower.includes('song') || taskLower.includes('soundtrack')) {
    return AIProvider.SUNO_AI;
  }

  // Image tools
  if (taskLower.includes('upscale') || taskLower.includes('enhance')) {
    return AIProvider.REPLICATE_UPSCALE;
  }
  if (taskLower.includes('background') || taskLower.includes('remove bg')) {
    return AIProvider.BACKGROUND_REMOVER;
  }

  // Image generation (default)
  if (taskLower.includes('logo')) return AIProvider.FLUX;
  if (taskLower.includes('artistic') || taskLower.includes('painting')) return AIProvider.MIDJOURNEY;
  if (taskLower.includes('text') && taskLower.includes('image')) return AIProvider.IDEOGRAM;

  // Default to Flux for general image generation
  return AIProvider.FLUX;
}

/**
 * Calculate total cost for a multi-step campaign
 */
export function calculateCampaignCost(providers: AIProvider[]): number {
  return providers.reduce((total, provider) => {
    return total + AI_PROVIDERS[provider].costPerRun;
  }, 0);
}
