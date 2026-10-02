# NanoCorona — Corona VFB UI Specification

## Goal

NanoCorona should feel like a native Corona VFB workflow, not like a separate web application or external AI window.

The competitor reference establishes the target interaction pattern:
- render remains the main workspace;
- AI controls live in a narrow right-side panel;
- source/render channel is selectable;
- prompt is always visible;
- generation settings are compact;
- result can be displayed immediately;
- generated image can be treated as another visual layer/result.

NanoCorona should reproduce this workflow, while using its own visual language and deeper scene-control features.

## Target layout

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ Corona VFB toolbar                                                          │
├───────────────────────────────────────────────────────────────┬─────────────┤
│                                                               │ NanoCorona  │
│                                                               │             │
│                  RENDER / AI RESULT                           │ API         │
│                                                               │ Provider    │
│                                                               │ Model       │
│                                                               │             │
│                                                               │ SOURCE      │
│                                                               │ Beauty      │
│                                                               │ Depth       │
│                                                               │ Normals     │
│                                                               │ Masks       │
│                                                               │             │
│                                                               │ EDIT        │
│                                                               │ Sky         │
│                                                               │ Weather     │
│                                                               │ Materials   │
│                                                               │ Background  │
│                                                               │ Custom      │
│                                                               │             │
│                                                               │ PROMPT      │
│                                                               │ [........]  │
│                                                               │             │
│                                                               │ STRENGTH    │
│                                                               │ 0.1 ─── 1.0 │
│                                                               │             │
│                                                               │ RESOLUTION  │
│                                                               │ 1K  2K  4K  │
│                                                               │             │
│                                                               │ [GENERATE]  │
│                                                               │             │
│                                                               │ RESULT      │
│                                                               │ Save / VFB  │
└───────────────────────────────────────────────────────────────┴─────────────┘
```

## UI principles

### 1. Render first
The image must remain dominant. The NanoCorona panel should normally occupy a narrow right-side area.

### 2. No modal workflow
The user should not have to open a browser, export an image, upload it, wait in another application, download the result, and import it back.
Generation starts and ends inside the Corona rendering workflow.

### 3. Progressive disclosure
Default panel: Provider/model, Source, Edit preset, Prompt, Strength, Resolution, Generate.
Advanced sections: Passes, Masks, Scene JSON, Edit JSON, QA, Research mode, provider diagnostics.

## Main controls

### Provider
- Provider selector;
- Model selector;
- API key status;
- Settings.
API keys must never be displayed as plaintext.

### Source
Default: Current Corona VFB / Beauty.
Advanced: Beauty, ZDepth, Normals, Material ID, Instance/Object ID, custom mask.

### Protected regions
The panel must expose the core NanoCorona differentiator: Architecture LOCKED.
Optional: Camera LOCKED, Geometry LOCKED, Facade LOCKED, Windows LOCKED, Environment EDITABLE.
The user should be able to inspect and toggle masks visually.

### Edit presets
Recommended first presets: Photorealism, Change Sky, Change Weather, Change Season, Change Materials, Wet Road, Change Background, Add Cars, Add People, Improve Glass, Custom Edit.
A preset creates or updates an Edit.json operation rather than directly constructing an opaque prompt only.

### Prompt
Free-text prompt remains available.
The final provider prompt should be composed from: user instruction + Scene constraints + selected operation + protected-region rules + provider adapter.
The user should be able to see an optional generated-instruction preview in Advanced mode.

### Strength
Logical 0.0–1.0 control. Provider adapters translate it to model-specific behavior.

### Resolution
- 1K;
- 2K;
- 4K where supported by the selected model/provider.
The UI must reflect provider capability instead of assuming all models support all resolutions.

## Result area
Actions: Show Result, Compare Source / Result, A/B, Save, Send/keep in VFB history if supported, Re-edit, Run QA, Correct.
Where direct insertion into native Corona VFB history is not supported by a public API, NanoCorona should use its own result history and offer Save/Load rather than relying on unsupported internal VFB APIs.

## Technical integration strategy

### Preferred
Use a supported/dockable 3ds Max UI mechanism so NanoCorona appears as a docked panel adjacent to the Corona VFB/render area.
Corona officially supports a dockable VFB in 3ds Max.

### Target
Investigate whether a stable public integration point exists for placing a custom NanoCorona panel directly inside the Corona VFB window.

### Important constraint
Do not make the production plugin dependent on undocumented Qt/Corona internal widget hierarchy or fragile HWND re-parenting unless a compatibility-tested adapter exists.
A direct embedded panel may be implemented as an optional integration layer: NanoCoronaVfbHost, with a fallback: NanoCoronaDockPanel.
This keeps the core plugin independent from Corona VFB internals.

## UI technology
The project remains MAXScript for 3ds Max integration and scene operations, and C#/.NET for networking and core service logic.
The UI host must be selected based on actual compatibility with the target 3ds Max/Corona versions.
Do not introduce C++ solely to embed the panel unless research proves that C#/MAXScript cannot provide the required stable integration.

## Visual language
NanoCorona should visually fit Corona: dark neutral background, compact controls, low visual noise, thin separators, restrained accent color, readable typography, consistent spacing, HiDPI-safe layout.
Do not copy competitor branding, icons, names or exact visual assets.

## Layout states
### Normal
Render + narrow NanoCorona panel.
### Expanded
Panel can widen to expose passes, masks, Scene JSON, Edit JSON, QA.
### Generation
Generate disabled; progress indicator; Cancel; current phase; elapsed time.
### Result
Result preview; Source/Result comparison; QA state; Save/Re-edit.
### Error
Compact error block with user-readable message, Retry, Details, Copy diagnostic information.

## Minimum UI MVP
Build in this order: Source: Current Beauty; Prompt; Generate; Progress; Result preview; Strength; Resolution; Architecture Locked; Pass selection; Edit presets; QA.
This prevents UI work from blocking the core render → AI pipeline.

## Acceptance criteria
- render remains the dominant area;
- NanoCorona controls are available without leaving 3ds Max;
- no browser/external upload step is required;
- generation is asynchronous;
- the panel does not freeze during network requests;
- source/result can be compared;
- protected architecture state is visible;
- the same UI can work with different AI providers;
- the UI degrades gracefully if direct VFB embedding is unavailable.