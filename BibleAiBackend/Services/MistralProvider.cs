using System.Text;
using System.Text.Json;

namespace BibleAiBackend.Services;

public class MistralProvider(IHttpClientFactory httpFactory) : IAiProvider
{
    public string ProviderName => "mistral";

    public async Task<string> CompleteAsync(
        string systemPrompt,
        List<(string role, string content)> history,
        string userMessage,
        string apiKey,
        CancellationToken ct = default)
    {
        var client = httpFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);

        var messages = new List<object> { new { role = "system", content = systemPrompt } };
        foreach (var (role, content) in history)
            messages.Add(new { role, content });
        messages.Add(new { role = "user", content = userMessage });

        var payload = new
        {
            model = "mistral-small-latest",
            messages,
            max_tokens = 1024,
            temperature = 0.3
        };

        var json = JsonSerializer.Serialize(payload);
        var response = await client.PostAsync(
            "https://api.mistral.ai/v1/chat/completions",
            new StringContent(json, Encoding.UTF8, "application/json"),
            ct);

        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException($"Mistral error {response.StatusCode}");

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        return doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? "Sin respuesta";
    }
}
