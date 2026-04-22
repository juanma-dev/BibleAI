# La Santa Biblia Asistida por AI — Dev Guide

## Estructura del proyecto

```
LaSantaBibliaAsistidaPorAI/
├── santa_biblia/          ← Flutter app (APK)
│   ├── lib/
│   │   ├── core/          ← Temas, rutas, constantes
│   │   ├── data/          ← DB SQLite, modelos, repositorios
│   │   └── features/      ← Pantallas por feature
│   │       ├── home/      ← Selección idioma + versión
│   │       ├── books/     ← Lista de libros
│   │       ├── chapters/  ← Grid de capítulos
│   │       ├── reader/    ← Lector con swipe
│   │       ├── chat/      ← Panel de chat AI (colapsible)
│   │       └── settings/  ← Configuración
│   └── assets/
│       └── db/            ← (vacío, DB se crea en runtime)
└── BibleAiBackend/        ← C# .NET 8 API
    ├── Models/            ← DTOs
    └── Services/          ← IAiProvider + proveedores
```

## Fase 1: Correr la app (Primeros pasos)

### 1. Backend C# (necesitas esto para el chat)

```bash
cd BibleAiBackend
dotnet run
# Servidor en http://0.0.0.0:5000
```

### 2. App Flutter

```bash
cd santa_biblia
flutter run
```

En el emulador Android, el backend corre en `http://10.0.2.2:5000` (ya configurado por defecto).
En un dispositivo físico, ve a Configuración → ingresa la IP local de tu PC (ej: `http://192.168.1.x:5000`).

## Primera vez que se usa una versión bíblica

La primera vez que seleccionas una versión (ej: RV1909), la app descargará los datos de `bible-api.com` y los guardará en SQLite. Esto puede tardar unos minutos pero solo ocurre UNA vez. Luego todo funciona offline.

## Versiones disponibles (dominio público)

| ID       | Nombre              | Idioma  |
|----------|---------------------|---------|
| rv1909   | Reina-Valera 1909   | es      |
| rv1865   | Reina-Valera 1865   | es      |
| kjv      | King James Version  | en      |
| web      | World English Bible | en      |
| asv      | American Standard   | en      |

## Proveedores de IA configurados

| Provider  | Requiere API Key | Modelo           | Precio   |
|-----------|------------------|------------------|----------|
| gemini    | Sí               | gemini-2.0-flash | Pago     |
| openai    | Sí               | gpt-4o-mini      | Pago     |
| anthropic | Sí               | claude-haiku     | Pago     |
| mistral   | Sí               | mistral-small    | Pago     |
| groq      | Sí (free tier)   | gemma2-9b-it     | Gratis   |
| ollama    | No               | llama3.2 (local) | Gratis   |

### Obtener API keys gratuitas:
- **Groq**: https://console.groq.com (plan gratuito generoso)
- **Gemini**: https://aistudio.google.com (plan gratuito disponible)
- **Ollama**: https://ollama.ai (100% local, sin internet)

## Construir APK

```bash
cd santa_biblia
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

## Próximos pasos (Fase 2)

1. **Búsqueda por palabra** — Barra de búsqueda en la pantalla de libros
2. **Marcadores** — Guardar versículos favoritos en SQLite
3. **Vista comparativa bilingüe** — Leer mismo capítulo en ES/EN simultáneamente
4. **Planes de lectura** — Lectura bíblica en X días
5. **Notas personales** — Añadir anotaciones a versículos

## Arquitectura RAG (Anti-alucinación)

Cuando el usuario pregunta algo en el chat:
1. La app busca versículos relevantes en SQLite (FTS5)
2. Envía esos versículos al backend como contexto
3. El backend construye el prompt: "Responde SOLO basado en estos versículos: [...]"
4. La IA responde sin inventar, solo con texto bíblico verificado

## Tecnologías

- **Flutter 3.41** + Riverpod (estado) + GoRouter (navegación)
- **SQLite** (sqflite) con FTS5 para búsqueda de texto completo
- **C# .NET 8** Minimal API como backend seguro
- **Lora** + **Cinzel Decorative** (tipografía bíblica premium)
- **flutter_animate** para animaciones fluidas
