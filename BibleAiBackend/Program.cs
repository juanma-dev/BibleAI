using System.Text.Json;
using BibleAiBackend.Models;
using BibleAiBackend.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Services ──────────────────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddLogging();

// Flutter client sends/expects snake_case JSON (verse_context, api_key, …),
// so align the Minimal API serializer with that convention.
builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
    o.SerializerOptions.DictionaryKeyPolicy = JsonNamingPolicy.SnakeCaseLower;
    o.SerializerOptions.PropertyNameCaseInsensitive = true;
});

// CORS - allow the Flutter app (Android emulator, physical device)
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

// Register all AI providers
builder.Services.AddSingleton<IAiProvider, GeminiProvider>();
builder.Services.AddSingleton<IAiProvider, OpenAiProvider>();
builder.Services.AddSingleton<IAiProvider, AnthropicProvider>();
builder.Services.AddSingleton<IAiProvider, MistralProvider>();
builder.Services.AddSingleton<IAiProvider, GroqProvider>();
builder.Services.AddSingleton<IAiProvider, OllamaProvider>();
builder.Services.AddSingleton<AiProviderFactory>();
builder.Services.AddScoped<ChatOrchestrator>();

// Rate limiting (simple in-memory, per-IP)
var requestCounts = new Dictionary<string, (int count, DateTime window)>();
var rateLimitLock = new object();

var app = builder.Build();

// ── Middleware ─────────────────────────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();

// ── Endpoints ──────────────────────────────────────────────────────────────────

// Health check
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
   .WithName("Health");

// Available providers
app.MapGet("/api/providers", (AiProviderFactory factory) =>
    Results.Ok(factory.AvailableProviders))
   .WithName("GetProviders");

// Main chat endpoint
app.MapPost("/api/chat", async (
    ChatRequest request,
    ChatOrchestrator orchestrator,
    HttpContext httpContext,
    CancellationToken ct) =>
{
    // Basic rate limiting: 30 requests/minute per IP
    var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    lock (rateLimitLock)
    {
        if (requestCounts.TryGetValue(ip, out var entry))
        {
            if (DateTime.UtcNow - entry.window < TimeSpan.FromMinutes(1))
            {
                if (entry.count >= 30)
                    return Results.StatusCode(429);
                requestCounts[ip] = (entry.count + 1, entry.window);
            }
            else
            {
                requestCounts[ip] = (1, DateTime.UtcNow);
            }
        }
        else
        {
            requestCounts[ip] = (1, DateTime.UtcNow);
        }
    }

    try
    {
        var response = await orchestrator.ProcessAsync(request, ct);
        return Results.Ok(response);
    }
    catch (ArgumentException ex)
    {
        return Results.BadRequest(new ErrorResponse("Bad Request", ex.Message));
    }
    catch (HttpRequestException ex)
    {
        return Results.Problem(
            detail: ex.Message,
            statusCode: 502,
            title: "AI Provider Error");
    }
    catch (Exception ex)
    {
        return Results.Problem(
            detail: ex.Message,
            statusCode: 500,
            title: "Internal Error");
    }
})
.WithName("Chat");

app.Run();
