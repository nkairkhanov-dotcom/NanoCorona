# NanoNetwork transport milestone

## Goal

Move the structured Corona input package into an asynchronous C# provider transport:

    Scene.json
      + Beauty
      + Z-Depth
      + Normals
      + Architecture Mask
      + Prompt
      ↓
    NanoNetwork.dll
      ↓
    Provider adapter
      ↓
    Gemini image model
      ↓
    Result image

## Assembly

Project:

    src/NanoNetwork/NanoNetwork.csproj

Output:

    NanoNetwork.dll

The project targets .NET Framework 4.6.2 as a conservative baseline for the older 3ds Max compatibility range. The exact supported 3ds Max/Corona matrix must still be tested before packaging.

## Public API

NanoNetworkClient.GenerateAsync(GenerationRequest, apiKey, CancellationToken) is the integration entry point.

The request contains paths to Scene.json, Beauty, Z-Depth, Normals, Architecture Mask, plus prompt, strength, resolution, model and an optional output path.

The result contains success/failure, result path, provider/model, normalized error code/message, HTTP status and request duration.

## Provider boundary

IImageProvider keeps the transport provider-agnostic.

Current implementation:

- GeminiProvider
- Gemini REST generateContent
- API key in x-goog-api-key
- image inputs as inline base64 parts
- image-only response modality
- 1K / 2K / 4K request mapping
- image extraction from inline response data

The implementation is REST-based and does not depend on the Google SDK.

## Input semantics

The first image is Beauty. The following images are:

1. Z-Depth
2. Normals
3. Architecture Mask

The generated control prompt explicitly tells the model that technical passes are spatial/control references and must not become visible textures.

Scene.json is provider-agnostic context. It is not treated as a literal command language.

## Reliability

- asynchronous HTTP
- cancellation token
- per-request timeout
- bounded retries for transient HTTP failures and timeout/network failures
- Retry-After support
- normalized provider errors
- result written only after a valid image response

## Credentials

CredentialStore uses Windows DPAPI with CurrentUser scope.

Default path:

    %LOCALAPPDATA%\NanoCorona\credentials.bin

The API key is never included in diagnostics JSON.

## Important security rule

Do not commit API keys, authorization headers, generated request JSON containing base64 image data, generated results or credential files.

## Current limitations

- Aspect ratio is derived from Scene.json and mapped to the provider's supported ratio set; pixel-level output preservation still needs benchmark coverage.
- There is no MAXScript → C# async bridge yet.
- There is no Edit.json builder yet.
- No live 3ds Max runtime test has been performed in this environment.
- Technical-pass semantics must be benchmarked against the selected Gemini model; sending all four images is an experiment, not a claim that the model will numerically consume depth/normals.
