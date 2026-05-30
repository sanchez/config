--- Provider registry. Maps provider names to their factory functions.
--- Call provider.new(hostname, api_key, model_id) -> agent loop closure.
local OpenAIProvider = require("packages.codehub.providers.openai")
local AnthropicProvider = require("packages.codehub.providers.anthropic")
local FakeProvider = require("packages.codehub.providers.fake")

return {
    openai = OpenAIProvider,
    anthropic = AnthropicProvider,
    fake = FakeProvider,
}
