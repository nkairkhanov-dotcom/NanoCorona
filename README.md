# NanoCorona

AI-assisted architectural post-processing plugin for Autodesk 3ds Max + Corona Renderer.

## Project idea

NanoCorona connects Corona renders and technical passes to an AI image generation/editing provider while keeping architectural structure under explicit constraints.

Core pipeline:

`Corona → Beauty/Depth/Normals/Masks → Scene.json → Edit.json → AI → QA → Result`

## Documentation

- [Technical Specification](docs/TECHNICAL_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Development Plan](docs/DEVELOPMENT_PLAN.md)
- [Research Protocol](docs/RESEARCH_PROTOCOL.md)
- [Scene JSON Schema](schemas/scene.schema.json)
- [Edit JSON Schema](schemas/edit.schema.json)

## Development principle

Do not start with a complex UI. First prove the image pipeline and architectural preservation benchmark.

The repository is the source of truth for project decisions, specifications, schemas, research protocol and implementation history.

## Current status

Phase 0 — repository foundation.

Next implementation target: Corona render extraction (Beauty + Z-Depth + Normals + initial masks).
