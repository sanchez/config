local OpenAIProvider = require("packages.codehub.providers.openai")
local AnthropicProvider = require("packages.codehub.providers.anthropic")
local FakeProvider = require("packages.codehub.providers.fake")

return {
    openai = OpenAIProvider,
    anthropic = AnthropicProvider,
    fake = FakeProvider,
}
