# Phase 3 — MAXScript → NanoNetwork.dll → Gemini → Max preview

## Goal

Make the existing right-side NanoCorona panel perform a real end-to-end image generation without blocking the 3ds Max UI:

    Corona VFB
      ↓
    Beauty + Z-Depth + Normals + Architecture Mask + Scene.json
      ↓
    MAXScript
      ↓
    NanoNetworkBridge
      ↓
    async NanoNetworkClient
      ↓
    Gemini / Nano Banana Pro
      ↓
    result PNG
      ↓
    MAXScript polling
      ↓
    NanoCorona panel preview

## Threading model

MAXScript starts a job and immediately returns.

NanoNetworkBridge owns a background job and exposes a polling API:

- StartGeneration(...)
- GetJobState(...)
- GetJobProgress(...)
- GetJobResultPath(...)
- GetJobErrorCode(...)
- GetJobErrorMessage(...)
- CancelGeneration(...)

A MAXScript timer polls every 500 ms. UI updates happen only from the MAXScript timer event, not from the C# worker thread.

No 3ds Max API or rollout control is accessed from the network worker.

Autodesk documents MAXScript timer controls as a way for a rollout to react to asynchronous conditions without user interaction. citeturn2search0

## API key

The bridge first checks the Windows DPAPI credential store used by NanoNetwork.

If no key is configured, the prototype asks once for the Gemini key and stores it using CredentialStore.SaveGeminiApiKey.

The key is not written to the project repository.

## Result behavior

The generated image is written into the same temporary NanoCorona\\Current package directory as the input passes, using a timestamped filename.

The right panel loads that image into its existing result preview.

The original Corona VFB render is not overwritten. Direct replacement/injection of the native Corona VFB image remains a separate compatibility task.

## Current provider

The provider defaults to gemini-3-pro-image, which Google currently lists as the stable Nano Banana Pro model. Google documents image+text input and image output for this model. citeturn1search0turn1search10

The REST transport uses generateContent and x-goog-api-key. Google documents image output configuration with responseModalities / responseFormat, including 1K/2K/4K output and aspect ratios. citeturn0search0turn0search1

## Limitations

- Progress is phase-based, not provider-native percentage progress.
- The panel preview is the result surface; native Corona VFB replacement is not implemented.
- The current prototype uses a simple first-run API-key prompt; a polished settings UI belongs to productization.
- Technical passes are supplied as multimodal references. Their effectiveness as depth/normal control inputs must be benchmarked rather than assumed.
- No real API request has been executed from 3ds Max in this environment.

## Manual acceptance test

1. Open 3ds Max with Corona active.
2. Select the building/architecture objects.
3. Open NanoCorona.
4. Setup Depth / Normals / Architecture Mask.
5. Render the frame in Corona.
6. Extract Passes + Scene.json.
7. Press GENERATE AI.
8. If requested, enter the Gemini API key.
9. Observe Uploading → Generating → Saving.
10. Verify the result appears in the existing NanoCorona result preview.
11. Verify the original Corona VFB image is unchanged.
12. Press Show Result to open the generated image in 3ds Max's bitmap viewer.
13. Press CANCEL during generation and verify the UI returns to Ready without locking 3ds Max.
