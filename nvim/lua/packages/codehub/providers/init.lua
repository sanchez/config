local OpenAIProvider = require("packages.codehub.providers.openai")
local AnthropicProvider = require("packages.codehub.providers.anthropic")

return {
    openai = OpenAIProvider,
    anthropic = AnthropicProvider,
}
