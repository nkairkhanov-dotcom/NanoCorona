# NanoCorona

AI-assisted architectural post-processing plugin for Autodesk 3ds Max + Corona Renderer.

## Project idea

NanoCorona connects Corona renders and technical passes to an AI image generation/editing provider while keeping architectural structure under explicit constraints.

Core pipeline:

    Corona → Beauty/Depth/Normals/Masks → Scene.json → Edit.json → AI → QA → Result

## Documentation

- [Technical Specification](docs/TECHNICAL_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Development Plan](docs/DEVELOPMENT_PLAN.md)
- [Research Protocol](docs/RESEARCH_PROTOCOL.md)
- [UI Specification](docs/UI_SPEC.md)
- [Corona VFB Panel Prototype](docs/PROTOTYPE_VFB_PANEL.md)
- [Scene JSON Schema](schemas/scene.schema.json)
- [Edit JSON Schema](schemas/edit.schema.json)

## First UI prototype

The first Corona-VFB-first prototype is now in:

    src/MaxScript/NanoCorona_VFB_Prototype.ms

It opens the real Corona VFB, creates a dockable NanoCorona right panel, and provides working Prompt / Strength / Generate / Result controls. Generate currently performs a local VFB snapshot rather than an AI/network call; this isolates UI and framebuffer integration from the upcoming provider implementation.

## Development principle

Keep the UI contract stable while the image pipeline is implemented behind it. Do not rely on undocumented Corona VFB widget internals for the production path.

The repository is the source of truth for project decisions, specifications, schemas, research protocol and implementation history.

## Current status

Phase 0 — repository foundation.

UI prototype milestone — Corona VFB + dockable NanoCorona panel.

Next implementation target: Beauty + Z-Depth + Normals + initial architecture/environment masks.
