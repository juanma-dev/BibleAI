using BibleAiBackend.Models;

namespace BibleAiBackend.Services;

public class ChatOrchestrator(AiProviderFactory providerFactory, ILogger<ChatOrchestrator> logger)
{
    private static readonly int MaxHistoryMessages = 10;
    private static readonly int MaxUserMessageLength = 2000;

    public async Task<ChatResponse> ProcessAsync(ChatRequest request, CancellationToken ct = default)
    {
        // Input validation
        if (string.IsNullOrWhiteSpace(request.Message))
            throw new ArgumentException("Message cannot be empty");

        var userMessage = request.Message.Length > MaxUserMessageLength
            ? request.Message[..MaxUserMessageLength]
            : request.Message;

        var systemPrompt = BuildSystemPrompt(request);
        var usedRag = !string.IsNullOrWhiteSpace(request.VerseContext);

        // Limit history to prevent token overflow
        var history = request.History
            .TakeLast(MaxHistoryMessages)
            .Select(h => (h.Role, h.Content))
            .ToList();

        var provider = providerFactory.Get(request.Provider);

        logger.LogInformation("Processing chat with {Provider} | RAG: {UsedRag} | Lang: {Lang}",
            request.Provider, usedRag, request.Language);

        var aiResponse = await provider.CompleteAsync(
            systemPrompt,
            history,
            userMessage,
            request.ApiKey,
            ct);

        return new ChatResponse(aiResponse, request.Provider, usedRag);
    }

    private static string BuildSystemPrompt(ChatRequest request)
    {
        var isSpanish = request.Language == "es";
        var hasVerseContext = !string.IsNullOrWhiteSpace(request.VerseContext);
        var hasCurrentContext = !string.IsNullOrWhiteSpace(request.CurrentContext);

        var baseInstructions = isSpanish
            ? """
              Eres un asistente bíblico experto, erudito y pastoral. Tu rol es ayudar a los usuarios
              a comprender la Biblia con profundidad, precisión histórica y sensibilidad espiritual.

              REGLAS CRÍTICAS:
              1. SOLO cita versículos que estén explícitamente en el contexto proporcionado. NUNCA inventes ni parafrasees versículos.
              2. Si un versículo no está en el contexto, di claramente "Este versículo no está en mi contexto actual".
              3. Proporciona contexto histórico, cultural y lingüístico cuando sea relevante.
              4. Sé respetuoso con todas las tradiciones cristinas.
              5. Si la pregunta no es bíblica, redirige amablemente.
              6. Usa **negritas** para enfatizar puntos importantes.
              7. Responde en español.
              """
            : """
              You are an expert biblical assistant, scholar and pastor. Your role is to help users
              understand the Bible with depth, historical accuracy and spiritual sensitivity.

              CRITICAL RULES:
              1. ONLY quote verses explicitly present in the provided context. NEVER invent or paraphrase verses.
              2. If a verse is not in the context, clearly state "This verse is not in my current context".
              3. Provide historical, cultural and linguistic context when relevant.
              4. Be respectful of all Christian traditions.
              5. If the question is not biblical, kindly redirect.
              6. Use **bold** to emphasize important points.
              7. Respond in English.
              """;

        var contextSection = "";
        if (hasVerseContext)
            contextSection += $"\n\n--- VERSÍCULOS DE REFERENCIA (usa SOLO estos) ---\n{request.VerseContext}\n--- FIN DEL CONTEXTO ---";

        if (hasCurrentContext)
            contextSection += $"\n\nCONTEXTO DE LECTURA ACTUAL: {request.CurrentContext}";

        return baseInstructions + contextSection;
    }
}
