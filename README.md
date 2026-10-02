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
- [Render Extraction](docs/RENDER_EXTRACTION.md)
- [Scene JSON Schema](schemas/scene.schema.json)
- [Edit JSON Schema](schemas/edit.schema.json)

## Current prototype

The Corona-VFB-first prototype is now connected to the first structured input pipeline.

Files:

    src/MaxScript/NanoCorona_VFB_Prototype.ms
    src/MaxScript/NanoCorona_RenderExtraction.ms

Workflow:

    Select architecture objects
          ↓
    Setup Passes
          ↓
    Corona render
          ↓
    Extract
          ↓
    Beauty + Z-Depth + Normals + Architecture Mask
          ↓
    Scene.json

The extraction module creates/reuses Corona render elements, reads the current Corona VFB, saves the passes under the 3ds Max temp directory, and generates a provider-agnostic Scene.json.

The Generate button currently stops at this structured input package. Gemini/Nano Banana transport comes next.

## Development principle

Keep the UI contract stable while the image pipeline is implemented behind it. Do not rely on undocumented Corona VFB widget internals for the production path.

The repository is the source of truth for project decisions, specifications, schemas, research protocol and implementation history.

## Current status

UI prototype milestone — Corona VFB + dockable NanoCorona panel.

Data milestone — Beauty + Z-Depth + Normals + Architecture Mask + Scene.json.

Next implementation target: Edit.json generation and C# provider transport.
