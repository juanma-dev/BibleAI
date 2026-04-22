using System.Text;
using System.Text.Json;

namespace BibleAiBackend.Services;

/// <summary>
/// Ollama - runs local models (completely free, runs on device or local network)
/// </summary>
public class OllamaProvider(IHttpClientFactory httpFactory, IConfiguration config) : IAiProvider
{
    public string ProviderName => "ollama";

    public async Task<string> CompleteAsync(
        string systemPrompt,
        List<(string role, string content)> history,
        string userMessage,
        string apiKey,
        CancellationToken ct = default)
    {
        var client = httpFactory.CreateClient();
        var ollamaUrl = config["Ollama:BaseUrl"] ?? "http://localhost:11434";
        var model = config["Ollama:Model"] ?? "llama3.2";

        var messages = new List<object> { new { role = "system", content = systemPrompt } };
        foreach (var (role, content) in history)
            messages.Add(new { role, content });
        messages.Add(new { role = "user", content = userMessage });

        var payload = new
        {
            model,
            messages,
            stream = false,
            options = new { temperature = 0.3, num_predict = 1024 }
        };

        var json = JsonSerializer.Serialize(payload);
        var response = await client.PostAsync(
            $"{ollamaUrl}/api/chat",
            new StringContent(json, Encoding.UTF8, "application/json"),
            ct);

        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException($"Ollama error {response.StatusCode}. Is Ollama running?");

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        return doc.RootElement
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? "Sin respuesta";
    }
}
