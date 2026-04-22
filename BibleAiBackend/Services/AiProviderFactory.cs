namespace BibleAiBackend.Services;

public class AiProviderFactory(IEnumerable<IAiProvider> providers)
{
    private readonly Dictionary<string, IAiProvider> _map =
        providers.ToDictionary(p => p.ProviderName, StringComparer.OrdinalIgnoreCase);

    public IAiProvider Get(string providerName)
    {
        if (_map.TryGetValue(providerName, out var provider))
            return provider;

        throw new ArgumentException($"AI provider '{providerName}' is not registered. Available: {string.Join(", ", _map.Keys)}");
    }

    public IEnumerable<string> AvailableProviders => _map.Keys;
}
