# Corona VFB panel prototype

This prototype implements the first UI milestone for NanoCorona:

    Corona VFB render surface  |  NanoCorona right panel
                                 Source
                                 Prompt
                                 Strength
                                 Architecture locked
                                 GENERATE AI
                                 Result preview
                                 Show Result

## What is real

- The script calls the Corona MAXScript API to open the Corona VFB.
- The NanoCorona UI is a native MAXScript rollout registered as a 3ds Max dockable CUI dialog bar.
- The panel is intended to dock on the right side of the 3ds Max UI while Corona VFB remains the render surface.
- Prompt, Strength, Resolution, Architecture locked, Generate, and Result are interactive.
- Generate reads the current Corona Beauty framebuffer using CoronaRenderer.CoronaFp.getVfbContent 0 true false, saves a local prototype result, and displays it in the Result area.
- Show Result opens the saved prototype result as a 3ds Max image window.
- No browser, external upload, or network request is used.

Chaos documents Corona VFB 2.0 as the default VFB starting with Corona 12 and documents that the VFB can be docked in the 3ds Max UI. The Corona MAXScript reference exposes showVfb and getVfbContent, which makes this prototype possible without relying on undocumented VFB widget internals.

## What is intentionally mocked

The current Generate operation is **not AI generation**. It is a transport/UI proof:

    Corona Beauty → prototype result → Result preview

This is deliberate. It lets us validate the right-panel workflow before introducing API latency, credentials, provider errors, render-pass extraction, or background threading.

## Run

1. Open 3ds Max with Corona installed.
2. Set Corona as the active renderer.
3. Open the MAXScript Editor.
4. Evaluate:

    src/MaxScript/NanoCorona_VFB_Prototype.ms

5. Render a frame so the Corona VFB contains a Beauty image.
6. The script opens Corona VFB and docks NanoCorona to the right.
7. Enter a prompt, set Strength/Resolution, and press **GENERATE AI**.
8. The prototype result is stored under the 3ds Max temp directory in:

    NanoCorona\NanoCorona_Prototype_Result.png

## Important layout note

The production target is still **Corona-VFB-first**. This prototype uses the documented 3ds Max CUI docking mechanism for the NanoCorona panel rather than injecting custom widgets into Corona VFB's internal widget tree. That gives us a stable first implementation while we separately test whether direct embedding into the VFB can be supported across Corona versions.

## Next milestone

Replace the local snapshot inside generatePrototype() with:

    Beauty → Depth → Normals → Architecture Mask → Scene.json → Edit.json → NanoNetwork.dll → provider → Result

The UI contract should stay stable while the transport layer is replaced.
