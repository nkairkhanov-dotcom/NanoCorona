# Corona VFB panel prototype

## Purpose

The NanoCorona panel is a dockable 3ds Max rollout designed to sit beside the Corona VFB. It uses the documented CUI docking mechanism and Corona MAXScript API; it does not inject controls into undocumented Corona VFB widgets.

## Implemented workflow

1. Select the architectural objects to protect.
2. Run **Setup Depth / Normals / Architecture Mask** and render the frame again in Corona.
3. Run **Extract Passes + Scene.json**.
4. Select a preset, adjust the prompt, strength, model and resolution, then choose **Generate AI**.
5. MAXScript starts an asynchronous `NanoNetworkBridge` job and polls it every 500 ms.
6. The returned image is previewed in the panel without overwriting Corona's source VFB image.
7. Run **Vision QA** and, if it reports a violation, optionally run **Correction Pass**.

The panel can preview the extracted Beauty, Z-Depth, Normals and architecture mask via the Source selector. SOURCE, RESULT and A/B show the original Beauty and the separate AI result.

## Threading and result behavior

MAXScript owns all scene and UI calls. The .NET bridge owns HTTP and file work in background tasks. The rollout timer is the only place that updates controls after a request begins.

Input files, `Scene.json`, `Edit.json` and timestamped results are placed in `%TEMP%\NanoCorona\Current`. The source Beauty is retained separately from the result so that Vision QA and correction always use the original Corona render as their primary reference.

## Limits

- Generation and QA progress are phase-based.
- The panel result preview is the supported result surface; direct insertion into Corona VFB history is not implemented.
- Render-element channel behavior, Gemini generation quality and QA accuracy require live 3ds Max/Corona benchmark testing.
