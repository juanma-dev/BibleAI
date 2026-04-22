using System.Text;
using System.Text.Json;

namespace BibleAiBackend.Services;

public class GeminiProvider(IHttpClientFactory httpFactory) : IAiProvider
{
    public string ProviderName => "gemini";

    public async Task<string> CompleteAsync(
        string systemPrompt,
        List<(string role, string content)> history,
        string userMessage,
        string apiKey,
        CancellationToken ct = default)
    {
        var client = httpFactory.CreateClient();
        var model = "gemini-2.0-flash";
        var url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

        var contents = new List<object>();

        foreach (var (role, content) in history)
        {
            contents.Add(new
            {
                role = role == "assistant" ? "model" : "user",
                parts = new[] { new { text = content } }
            });
        }

        contents.Add(new
        {
            role = "user",
            parts = new[] { new { text = userMessage } }
        });

        var payload = new
        {
            system_instruction = new { parts = new[] { new { text = systemPrompt } } },
            contents,
            generationConfig = new
            {
                temperature = 0.3,
                maxOutputTokens = 1024,
                topP = 0.8
            },
            safetySettings = new[]
            {
                new { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_ONLY_HIGH" },
                new { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_ONLY_HIGH" }
            }
        };

        var json = JsonSerializer.Serialize(payload);
        var response = await client.PostAsync(url, new StringContent(json, Encoding.UTF8, "application/json"), ct);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync(ct);
            throw new HttpRequestException($"Gemini API error {response.StatusCode}: {error}");
        }

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        return doc.RootElement
            .GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString() ?? "Sin respuesta";
    }
}
