# NanoCorona

AI-assisted architectural post-processing plugin for Autodesk 3ds Max + Corona Renderer.

## Project idea

NanoCorona connects Corona renders and technical passes to an AI image generation/editing provider while keeping architectural structure under explicit constraints.

Core pipeline:

    Corona → Beauty/Depth/Normals/Masks → Scene.json → Edit.json → AI → QA → Result

## Documentation

- [Installation](docs/INSTALL.md)
- [User Guide](docs/USER_GUIDE.md)
- [Compatibility Matrix](docs/COMPATIBILITY.md)

- [Technical Specification](docs/TECHNICAL_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Development Plan](docs/DEVELOPMENT_PLAN.md)
- [Research Protocol](docs/RESEARCH_PROTOCOL.md)
- [UI Specification](docs/UI_SPEC.md)
- [Corona VFB Panel Prototype](docs/PROTOTYPE_VFB_PANEL.md)
- [Render Extraction](docs/RENDER_EXTRACTION.md)
- [Network Transport](docs/NETWORK_TRANSPORT.md)
- [Phase 3 Max Bridge](docs/PHASE3_MAX_BRIDGE.md)
- [Scene JSON Schema](schemas/scene.schema.json)
- [Edit JSON Schema](schemas/edit.schema.json)

## Phase 6 product UI

The UI is organized as a Corona-VFB-first dockable panel with model selection, API-key settings entry point, source/result/A-B controls, generation progress, Vision QA and correction workflow. Direct undocumented Corona VFB embedding is not a production dependency.

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

The Generate button now has a C# transport target behind the structured input package. NanoNetwork.dll builds a provider request from Scene.json + Beauty + Depth + Normals + Architecture Mask and sends it asynchronously through the Gemini adapter.

## Development principle

Keep the UI contract stable while the image pipeline is implemented behind it. Do not rely on undocumented Corona VFB widget internals for the production path.

The repository is the source of truth for project decisions, specifications, schemas, research protocol and implementation history.

## Current status

UI prototype milestone — Corona VFB + dockable NanoCorona panel.

Data milestone — Beauty + Z-Depth + Normals + Architecture Mask + Scene.json.

Phase 6 productization is implemented on the product branch: UI polish, installation script, user guide, compatibility matrix and CI artifact packaging. Live 3ds Max/Corona acceptance testing remains an explicit release gate.
