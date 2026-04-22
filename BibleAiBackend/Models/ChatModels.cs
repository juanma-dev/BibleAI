namespace BibleAiBackend.Models;

public record ChatRequest(
    string Message,
    string VerseContext,
    string CurrentContext,
    string Provider,
    string ApiKey,
    string Language,
    List<HistoryMessage> History
);

public record HistoryMessage(string Role, string Content);

public record ChatResponse(string Response, string Provider, bool UsedRag);

public record ErrorResponse(string Error, string Detail);
