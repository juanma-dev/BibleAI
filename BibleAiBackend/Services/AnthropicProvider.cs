using System.Text;
using System.Text.Json;

namespace BibleAiBackend.Services;

public class AnthropicProvider(IHttpClientFactory httpFactory) : IAiProvider
{
    public string ProviderName => "anthropic";

    public async Task<string> CompleteAsync(
        string systemPrompt,
        List<(string role, string content)> history,
        string userMessage,
        string apiKey,
        CancellationToken ct = default)
    {
        var client = httpFactory.CreateClient();
        client.DefaultRequestHeaders.Add("x-api-key", apiKey);
        client.DefaultRequestHeaders.Add("anthropic-version", "2023-06-01");

        var messages = new List<object>();
        foreach (var (role, content) in history)
            messages.Add(new { role, content });
        messages.Add(new { role = "user", content = userMessage });

        var payload = new
        {
            model = "claude-4.7-opus-20260416",
            max_tokens = 1024,
            system = systemPrompt,
            messages,
            temperature = 0.3
        };

        var json = JsonSerializer.Serialize(payload);
        var response = await client.PostAsync(
            "https://api.anthropic.com/v1/messages",
            new StringContent(json, Encoding.UTF8, "application/json"),
            ct);

        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException($"Anthropic error {response.StatusCode}");

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        return doc.RootElement
            .GetProperty("content")[0]
            .GetProperty("text")
            .GetString() ?? "Sin respuesta";
    }
}
