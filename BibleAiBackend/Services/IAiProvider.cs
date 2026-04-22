namespace BibleAiBackend.Services;

public interface IAiProvider
{
    string ProviderName { get; }
    Task<string> CompleteAsync(string systemPrompt, List<(string role, string content)> history, string userMessage, string apiKey, CancellationToken ct = default);
}
