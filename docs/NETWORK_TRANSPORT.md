# NanoNetwork transport

## Purpose

NanoNetwork moves a structured Corona package to an image-generation provider without blocking the 3ds Max UI:

    Scene.json + Edit.json + Beauty + Z-Depth + Normals + Architecture Mask + Prompt
        -> NanoNetwork.dll -> Gemini -> result image

## Runtime and public boundary

`src/NanoNetwork/NanoNetwork.csproj` targets **net8.0-windows** for the 3ds Max 2026 + Corona 15 release target. Its provider-independent boundary is `IImageProvider`; `GeminiProvider` is the current implementation.

`NanoNetworkClient.GenerateAsync` validates the package, builds a provider request and saves a returned image. `NanoNetworkBridge` exposes start, progress, cancellation, result and QA methods to MAXScript while keeping HTTP and file work on background tasks.

## Gemini adapter

- Calls Gemini `v1` `generateContent` with `x-goog-api-key` authentication.
- Sends the prompt and every image as inline base64 parts.
- Requests text and image generation modalities, normalizes 1K/2K/4K resolution, and maps the closest supported aspect ratio from `Scene.json`.
- Extracts the returned inline image data and normalizes provider failures.
- Applies a five-minute default timeout, bounded retry with exponential backoff, and `Retry-After` where present to generation and Vision QA requests.

The Beauty image is the primary visual source. Depth, normals and the architecture mask are reference/control images; they are not assumed to be native numerical control channels of a Gemini model.

## Credentials and safety

The Gemini API key is saved under `%LOCALAPPDATA%\NanoCorona\credentials.bin` using Windows DPAPI with `CurrentUser` scope. It is never emitted by the diagnostics API or stored in a project package.

Do not commit API keys, authorization headers, base64 request payloads, generated results, or credential files.

## Current limitations

- Progress is phase-based, rather than a provider-native percentage.
- Technical-pass effectiveness and output-preservation quality require the documented A/B benchmark.
- No live 3ds Max 2026 + Corona 15 + Gemini acceptance test has been recorded for this repository state.
