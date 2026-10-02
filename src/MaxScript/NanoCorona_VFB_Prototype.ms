/*
    NanoCorona — Corona VFB right-panel prototype

    UI milestone:
      Corona VFB + NanoCorona panel

    Data milestone:
      Beauty + Z-Depth + Normals + Architecture Mask + Scene.json

    Provider/network integration intentionally comes later.
*/

global NanoCoronaVfbPrototype

try (cui.UnRegisterDialogBar NanoCoronaVfbPrototype) catch()
try (destroyDialog NanoCoronaVfbPrototype) catch()

local prototypeDir = getFilenamePath (getSourceFileName())
try
(
    if NanoCoronaRenderExtraction == undefined do
        fileIn (prototypeDir + "NanoCorona_RenderExtraction.ms")
)
catch
(
    try (fileIn (prototypeDir + "NanoCorona_RenderExtraction.ms")) catch()
)

rollout NanoCoronaVfbPrototype "NanoCorona" width:340 height:760
(
    local lastResultBitmap = undefined
    local resultPath = ""
    local sceneJsonPath = ""
    local busy = false

    fn setStatus messageText =
    (
        statusLabel.text = messageText
    )

    fn openCoronaVfb =
    (
        try
        (
            CoronaRenderer.CoronaFp.showVfb true
            setStatus "Corona VFB: open"
        )
        catch
        (
            messageBox "Corona VFB could not be opened. Make sure Corona is the active renderer." title:"NanoCorona"
            setStatus "Corona VFB: unavailable"
        )
    )

    fn previewBeauty beautyPath =
    (
        if beautyPath == "" or not doesFileExist beautyPath then return false

        try
        (
            local bmp = openBitmap beautyPath
            if bmp != undefined then
            (
                if lastResultBitmap != undefined do
                (
                    try (free lastResultBitmap) catch()
                    lastResultBitmap = undefined
                )

                lastResultBitmap = copy bmp
                resultPreview.bitmap = lastResultBitmap
                resultPathLabel.text = beautyPath
                close bmp
                true
            )
            else false
        )
        catch(false)
    )

    fn setupPasses =
    (
        if NanoCoronaRenderExtraction == undefined then
        (
            messageBox "Render extraction module is not loaded." title:"NanoCorona"
            setStatus "Extraction module unavailable"
            return false
        )

        local r = NanoCoronaRenderExtraction.setupPasses()

        if r[1] then
        (
            setStatus r[3]
            messageBox (r[3] + "\n\nRender the frame again, then press Extract Passes.") title:"NanoCorona"
            true
        )
        else
        (
            messageBox r[3] title:"NanoCorona"
            setStatus r[3]
            false
        )
    )

    fn extractPasses =
    (
        if NanoCoronaRenderExtraction == undefined then
        (
            messageBox "Render extraction module is not loaded." title:"NanoCorona"
            return false
        )

        local r = NanoCoronaRenderExtraction.extractCurrentVfb()

        if r.success then
        (
            sceneJsonPath = r.sceneJsonPath
            resultPath = r.beautyPath
            sceneLabel.text = ("Scene.json: " + sceneJsonPath)
            packageLabel.text = "Beauty + Depth + Normals + Architecture Mask"
            previewBeauty r.beautyPath
            setStatus "Passes + Scene.json ready"
            true
        )
        else
        (
            messageBox r.message title:"NanoCorona"
            setStatus r.message
            false
        )
    )

    fn generatePrototype =
    (
        if busy then return()

        busy = true
        generateButton.enabled = false
        setupPassesButton.enabled = false
        extractPassesButton.enabled = false
        setStatus "Extracting Corona inputs..."
        progress.value = 15

        -- This is the first structured pipeline milestone.
        -- AI/network transport is deliberately not connected yet.
        local ok = extractPasses()

        if ok then
        (
            progress.value = 100
            setStatus ("Input package ready • Strength " + (strengthSpinner.value as string))
        )
        else
        (
            progress.value = 0
        )

        generateButton.enabled = true
        setupPassesButton.enabled = true
        extractPassesButton.enabled = true
        busy = false
    )

    fn showResult =
    (
        if resultPath != "" and doesFileExist resultPath then
        (
            try
            (
                local bmp = openBitmap resultPath
                if bmp != undefined do display bmp caption:"NanoCorona Result"
            )
            catch
            (
                messageBox "Could not open the result image." title:"NanoCorona"
            )
        )
        else
        (
            messageBox "Extract the current VFB first." title:"NanoCorona"
        )
    )

    group "NanoCorona" (
        label headerLabel "AI image editing for Corona VFB" align:#left
        label providerLabel "Provider: prototype / local extraction" align:#left
    )

    group "Source" (
        dropdownlist sourceDrop "Source:" items:#("Beauty (Corona VFB)", "Z-Depth", "Normals", "Mask") selection:1 width:300
        button openVfbButton "Open / Focus Corona VFB" width:300
        button setupPassesButton "Setup Depth / Normals / Architecture Mask" width:300
        button extractPassesButton "Extract Passes + Scene.json" width:300
    )

    group "Prompt" (
        edittext promptEdit "" text:"Photorealistic architectural visualization. Preserve building geometry, camera composition and facade layout. Improve materials, lighting, sky and environment." height:100 fieldWidth:300 multiLine:true labelOnTop:true
    )

    group "Controls" (
        spinner strengthSpinner "Strength:" range:[0.1,1.0,0.65] type:#float scale:0.05 fieldWidth:65 across:2
        dropdownlist resolutionDrop "Resolution:" items:#("1K", "2K", "4K") selection:2 width:90
        checkbox architectureLock "Architecture locked" checked:true across:2
        label strengthHint "0.1 = subtle   1.0 = strong" align:#left
    )

    group "Generate" (
        button generateButton "GENERATE AI" width:300 height:38
        progressbar progress "" value:0 width:300 height:8
        label statusLabel "Ready — render Beauty in Corona first." align:#left
    )

    group "Result" (
        imgTag resultPreview "" width:300 height:170 style:#bmp_stretch
        label resultPathLabel "No result yet." width:300 align:#left
        button showResultButton "Show Result" width:145 across:2
        button captureButton "Capture VFB" width:145
    )

    group "Scene package" (
        label sceneLabel "Scene.json: not generated" width:300 align:#left
        label packageLabel "Beauty / Depth / Normals / Mask" width:300 align:#left
    )

    group "Prototype notes" (
        label note1 "Generate now builds the structured Corona input package." align:#left
        label note2 "Next: Scene.json + Edit.json → NanoNetwork.dll → provider." align:#left
        label note3 "Select architectural objects before Setup Passes." align:#left
    )

    on openVfbButton pressed do openCoronaVfb()
    on setupPassesButton pressed do setupPasses()
    on extractPassesButton pressed do extractPasses()
    on generateButton pressed do generatePrototype()
    on captureButton pressed do
    (
        local ok = false
        try
        (
            local bmp = CoronaRenderer.CoronaFp.getVfbContent 0 true false
            if bmp != undefined then
            (
                local dir = (getDir #temp) + "\\NanoCorona\\Current"
                if not doesFileExist dir do makeDir dir
                local p = dir + "\\beauty.png"
                bmp.filename = p
                save bmp quiet:true
                close bmp
                resultPath = p
                previewBeauty p
                setStatus "Beauty captured"
                ok = true
            )
        )
        catch()

        if not ok do setStatus "No Beauty render"
    )
    on showResultButton pressed do showResult()

    on NanoCoronaVfbPrototype open do
    (
        openCoronaVfb()
    )
)

createDialog NanoCoronaVfbPrototype 340 760 style:#(#style_titlebar, #style_sysmenu, #style_resizing)
cui.RegisterDialogBar NanoCoronaVfbPrototype style:#(#cui_dock_right, #cui_floatable, #cui_handles)
cui.DockDialogBar NanoCoronaVfbPrototype #cui_dock_right

setStatus "Ready — select architecture, Setup Passes, then render."
