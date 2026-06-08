--- Build agent: general-purpose coding assistant. Uses OpenAI-compatible endpoint with deepseek-v4-pro.
--- All tools enabled ("*"). No skill restrictions. Suitable for code generation, editing, debugging.
return {
    description = "Used for all things do",
    provider = "openai",
    model = "deepseek-v4-pro",
    tools = {
        allowed = { "*" },
    },
}
