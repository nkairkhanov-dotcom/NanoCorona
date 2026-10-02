# Render extraction milestone

## Goal

Turn the current Corona VFB render into the first structured NanoCorona input package:

    Beauty
      ↓
    Z-Depth
      +
    Normals
      +
    Architecture Mask
      ↓
    Scene.json

## Implementation

src/MaxScript/NanoCorona_RenderExtraction.ms provides:

- Corona renderer validation.
- Creation/reuse of:
  - CGeometry_ZDepth
  - CGeometry_NormalsShading
  - CMasking_Mask
- Architecture mask configuration from the user's current object selection.
- Extraction of Beauty from Corona VFB channel 0.
- Extraction of technical render elements from Corona VFB channels.
- PNG export to a temporary NanoCorona working directory.
- Scene.json generation with camera, render dimensions, pass paths, object inventory, protected architecture region, and constraints.

Corona's current documentation describes CGeometry_ZDepth and CGeometry_NormalsShading as geometry render elements and CMasking_Mask as a custom object/material/GBuffer mask. Corona's MAXScript API exposes getVfbContent and setDisplayedChannel; 3ds Max exposes the RenderElementMgr used here to add and inspect render elements.

## Architecture mask policy

NanoCorona does not guess which objects are architecture in this milestone.

The user selects the building/architectural objects in 3ds Max and presses Setup Passes. The script assigns those objects to CMasking_Mask and marks the corresponding Scene.json region as protected.

This is intentionally conservative. Automatic semantic classification will be added later after the first image benchmark.

## Working directory

The prototype writes:

    <3ds Max temp>\NanoCorona\Current\
        beauty.png
        depth.png
        normals.png
        architecture_mask.png
        Scene.json

No API keys or network data are written.

## Important

After adding the render elements, the scene must be rendered again. The current VFB cannot contain a newly-added pass until Corona has rendered that pass.

## Next step

The provider layer should consume this package and translate Scene.json + Edit.json + images into the provider-specific request. Scene.json remains provider-agnostic.
