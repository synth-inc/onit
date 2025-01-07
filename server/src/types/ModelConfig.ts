export type ModelProvider = 'openai' | 'anthropic';

export interface ModelCapabilities {
    vision?: boolean;
    function_calling?: boolean;
}

export interface ModelConfig {
    provider: ModelProvider;
    capabilities: ModelCapabilities;
}

export const MODEL_CONFIGS: Record<string, ModelConfig> = {
    // OpenAI Models
    'gpt-4': { provider: 'openai', capabilities: { function_calling: true } },
    'gpt-4-turbo-preview': { provider: 'openai', capabilities: { function_calling: true } },
    'gpt-4-vision-preview': { provider: 'openai', capabilities: { vision: true, function_calling: true } },
    'gpt-3.5-turbo': { provider: 'openai', capabilities: { function_calling: true } },
    'gpt-3.5-turbo-16k': { provider: 'openai', capabilities: { function_calling: true } },
    
    // Anthropic Models
    'claude-3-opus-20240229': { provider: 'anthropic', capabilities: { vision: true } },
    'claude-3-sonnet-20240229': { provider: 'anthropic', capabilities: { vision: true } },
    'claude-3-haiku-20240229': { provider: 'anthropic', capabilities: { vision: true } },
    'claude-2.1': { provider: 'anthropic', capabilities: {} },
    'claude-2.0': { provider: 'anthropic', capabilities: {} },
    'claude-instant-1.2': { provider: 'anthropic', capabilities: {} }
};