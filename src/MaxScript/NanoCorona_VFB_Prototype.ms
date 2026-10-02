/*
    NanoCorona — Corona VFB right-panel prototype
    Target: 3ds Max + Corona Renderer
    Prototype only: Generate currently snapshots the current Corona VFB Beauty
    into a local result file and shows it in the Result area. Provider/network
    integration comes next.

    Usage:
      1. Set Corona as the active renderer.
      2. Evaluate this file in MAXScript.
      3. Corona VFB opens and NanoCorona docks to the right.
      4. Enter a prompt, set Strength, press Generate.
*/

global NanoCoronaVfbPrototype

try (cui.UnRegisterDialogBar NanoCoronaVfbPrototype) catch()
try (destroyDialog NanoCoronaVfbPrototype) catch()

rollout NanoCoronaVfbPrototype "NanoCorona" width:340 height:680
(
    local lastResultBitmap = undefined
    local resultPath = ""
    local busy = false

    fn setStatus messageText =
    (
        statusLabel.text = messageText
    )

    fn ensureResultDirectory =
    (
        local dir = (getDir #temp) + "\\NanoCorona"
        if not doesFileExist dir do makeDir dir
        dir
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

    fn captureBeauty =
    (
        local sourceBmp = undefined

        try
        (
            sourceBmp = CoronaRenderer.CoronaFp.getVfbContent 0 true false
        )
        catch
        (
            sourceBmp = undefined
        )

        if sourceBmp == undefined then
        (
            messageBox "No Beauty image is available in the Corona VFB. Render a frame first." title:"NanoCorona"
            setStatus "No Beauty render"
            return false
        )

        local dir = ensureResultDirectory()
        resultPath = dir + "\\NanoCorona_Prototype_Result.png"

        try
        (
            sourceBmp.filename = resultPath
            save sourceBmp quiet:true

            if lastResultBitmap != undefined do
            (
                try (free lastResultBitmap) catch()
                lastResultBitmap = undefined
            )

            lastResultBitmap = copy sourceBmp
            resultPreview.bitmap = lastResultBitmap
            resultPathLabel.text = resultPath
            setStatus "Result ready (prototype snapshot)"
            close sourceBmp
            true
        )
        catch
        (
            try (close sourceBmp) catch()
            messageBox "Could not save the prototype result." title:"NanoCorona"
            setStatus "Result save failed"
            false
        )
    )

    fn generatePrototype =
    (
        if busy then return()

        busy = true
        generateButton.enabled = false
        setStatus "Generating..."
        progress.value = 15

        -- Prototype transport: no network call yet.
        -- The UI flow is kept identical to the future provider path.
        progress.value = 50

        local ok = captureBeauty()

        if ok then
        (
            progress.value = 100
            setStatus ("Result ready • Strength " + (strengthSpinner.value as string))
        )
        else
        (
            progress.value = 0
        )

        generateButton.enabled = true
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
            messageBox "Generate a result first." title:"NanoCorona"
        )
    )

    group "NanoCorona" (
        label headerLabel "AI image editing for Corona VFB" align:#left
        label providerLabel "Provider: Prototype / local VFB snapshot" align:#left
    )

    group "Source" (
        dropdownlist sourceDrop "Source:" items:#("Beauty (Corona VFB)", "Z-Depth", "Normals", "Mask") selection:1 width:300
        button openVfbButton "Open / Focus Corona VFB" width:300
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

    group "Prototype notes" (
        label note1 "Generate currently snapshots Corona Beauty." align:#left
        label note2 "Next: Beauty → Depth → Normals → Mask → Scene.json → API." align:#left
        label note3 "Network/API calls are intentionally not in this prototype." align:#left
    )

    on openVfbButton pressed do openCoronaVfb()
    on generateButton pressed do generatePrototype()
    on captureButton pressed do captureBeauty()
    on showResultButton pressed do showResult()

    on NanoCoronaVfbPrototype open do
    (
        openCoronaVfb()
    )
)

createDialog NanoCoronaVfbPrototype 340 680 style:#(#style_titlebar, #style_sysmenu, #style_resizing)
cui.RegisterDialogBar NanoCoronaVfbPrototype style:#(#cui_dock_right, #cui_floatable, #cui_handles)
cui.DockDialogBar NanoCoronaVfbPrototype #cui_dock_right

setStatus "Ready — Corona VFB opened. Render a Beauty frame, then Generate."
