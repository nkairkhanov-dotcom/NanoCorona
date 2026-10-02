# NanoCorona — архитектура

## High-level

~~~text
┌──────────────────────────────┐
│ Autodesk 3ds Max + Corona    │
│                              │
│ MAXScript UI / Render Setup  │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Render Extraction            │
│ Beauty / Depth / Normals     │
│ IDs / Masks                  │
└──────────────┬───────────────┘
               │ files
               ▼
┌──────────────────────────────┐
│ Scene Intelligence           │
│ Scene.json / masks           │
│ protected regions            │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Edit Planner                 │
│ Edit.json → provider request │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ NanoNetwork.dll              │
│ C# / .NET / async HTTPS      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ AI Provider Adapter          │
│ Nano Banana / Gemini / etc.  │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Result + Vision QA            │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ 3ds Max Preview / Save / VFB │
└──────────────────────────────┘
~~~

## Module boundaries

### MaxScript

Owns 3ds Max-specific state.

### NanoNetwork.dll

Owns network and provider-independent transport.

### Provider Adapter

Owns exact API contract of a provider/model.

### Scene Intelligence

Owns semantic scene representation and masks.

### QA

Owns post-generation validation.

## Dependency rule

~~~text
MAXScript → NanoNetwork interface
NanoNetwork → Provider Adapter
Provider Adapter → external API

Scene Intelligence → image files / JSON
QA → source + result + scene constraints
~~~

Provider-specific fields must not leak into Scene.json.

## Async rule

Network and file operations may be asynchronous. 3ds Max scene/UI operations must be marshalled to the appropriate Max context.

## Data flow

~~~text
source/
  beauty.png
  depth.png
  normals.png

analysis/
  scene.json

masks/
  architecture.png
  environment.png

edit.json

request/
  provider_request.json

result/
  result.png
  qa.json
~~~

## Future extension points

- multiple AI providers;
- local vision models;
- interactive mask painting;
- per-region strength;
- batch generation;
- prompt templates;
- automatic correction;
- generation history;
- A/B benchmark dashboard.
