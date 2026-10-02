/*
    NanoCorona — Corona VFB right-panel prototype

    UI milestone:
      Corona VFB + NanoCorona panel

    Data milestone:
      Beauty + Z-Depth + Normals + Architecture Mask + Scene.json

    Provider/network integration: NanoNetwork.dll async bridge.
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
    local networkBridge = undefined
    local networkDllPath = ""
    local currentJobId = ""
    local networkReady = false

    fn setStatus messageText =
    (
        statusLabel.text = messageText
    )

    fn findNetworkDll =
    (
        local candidates = #()
        append candidates (prototypeDir + "..\\NanoNetwork\\bin\\Release\\NanoNetwork.dll")
        append candidates (prototypeDir + "..\\NanoNetwork\\bin\\Debug\\NanoNetwork.dll")
        append candidates ((getDir #userScripts) + "\\NanoCorona\\NanoNetwork.dll")
        append candidates ((getDir #plugcfg) + "\\NanoCorona\\NanoNetwork.dll")
        append candidates (getDir #temp + "\\NanoCorona\\NanoNetwork.dll")

        for p in candidates do
        (
            if doesFileExist p then return p
        )
        undefined
    )

    fn loadNetworkBridge =
    (
        if networkReady and networkBridge != undefined then return true

        local dll = findNetworkDll()

        if dll == undefined then
        (
            networkDllPath = ""
            setStatus "NanoNetwork.dll not found"
            return false
        )

        try
        (
            dotNet.loadAssembly dll
            networkBridge = dotNetObject "NanoCorona.Network.NanoNetworkBridge"
            networkDllPath = dll
            networkReady = true
            true
        )
        catch
        (
            networkBridge = undefined
            networkReady = false
            setStatus "Could not load NanoNetwork.dll"
            false
        )
    )

    fn ensureApiKey =
    (
        if not loadNetworkBridge() then return false

        try
        (
            if networkBridge.HasGeminiApiKey() then return true
        )
        catch()

        local key = getString caption:"Gemini API Key" prompt:"Enter your Gemini API key:"
        if key == undefined or key == "" then
        (
            setStatus "Gemini API key is required"
            return false
        )

        try
        (
            networkBridge.SaveGeminiApiKey key
            setStatus "Gemini API key saved"
            true
        )
        catch
        (
            setStatus "Could not save Gemini API key"
            false
        )
    )

    fn getResolutionValue =
    (
        if resolutionDrop.selection == 3 then "4K"
        else if resolutionDrop.selection == 1 then "1K"
        else "2K"
    )

    fn startNetworkGeneration =
    (
        if not loadNetworkBridge() then
        (
            messageBox "NanoNetwork.dll was not found. Build/copy NanoNetwork.dll before using Generate AI." title:"NanoCorona"
            return false
        )

        if not ensureApiKey() then return false

        if sceneJsonPath == "" or not doesFileExist sceneJsonPath then
        (
            setStatus "Scene.json is missing"
            return false
        )

        local outputDir = getFilenamePath sceneJsonPath
        local stamp = (localTime as string)
        stamp = substituteString stamp ":" "_"
        stamp = substituteString stamp "/" "_"
        stamp = substituteString stamp " " "_"
        local outputPath = outputDir + "\nanocorona_result_" + stamp + ".png"

        try
        (
            currentJobId = networkBridge.StartGeneration                 sceneJsonPath                 resultPath                 (outputDir + "\depth.png")                 (outputDir + "\normals.png")                 (outputDir + "\architecture_mask.png")                 promptEdit.text                 strengthSpinner.value                 (getResolutionValue())                 "gemini-3-pro-image"                 outputPath                 ""

            setStatus "Gemini generation started..."
            progress.value = 50
            jobTimer.active = true
            true
        )
        catch
        (
            currentJobId = ""
            setStatus "Could not start Gemini generation"
            messageBox "Could not start the AI request. Check NanoNetwork.dll and the Gemini API key." title:"NanoCorona"
            false
        )
    )

    fn pollNetworkJob =
    (
        if currentJobId == "" or networkBridge == undefined then
        (
            jobTimer.active = false
            return()
        )

        try
        (
            local state = networkBridge.GetJobState currentJobId
            local p = networkBridge.GetJobProgress currentJobId
            progress.value = p

            if state == "Queued" or state == "Preparing" then
                setStatus "Preparing AI request..."
            else if state == "Uploading" then
                setStatus "Uploading Corona passes..."
            else if state == "Generating" then
                setStatus "Gemini is generating..."
            else if state == "Saving" then
                setStatus "Saving result..."
            else if state == "Canceling" then
                setStatus "Canceling..."
            else if state == "Succeeded" then
            (
                jobTimer.active = false
                resultPath = networkBridge.GetJobResultPath currentJobId
                if resultPath != "" and doesFileExist resultPath then
                (
                    previewBeauty resultPath
                    setStatus ("AI result ready • " + ((networkBridge.GetJobDurationMs currentJobId) as string) + " ms")
                )
                else
                (
                    setStatus "Generation succeeded but result file is missing"
                )
                generateButton.enabled = true
                setupPassesButton.enabled = true
                extractPassesButton.enabled = true
                cancelButton.enabled = false
                busy = false
            )
            else if state == "Failed" then
            (
                jobTimer.active = false
                local code = networkBridge.GetJobErrorCode currentJobId
                local message = networkBridge.GetJobErrorMessage currentJobId
                setStatus ("AI failed: " + code)
                messageBox (message + "\n\nError: " + code) title:"NanoCorona"
                generateButton.enabled = true
                setupPassesButton.enabled = true
                extractPassesButton.enabled = true
                cancelButton.enabled = false
                busy = false
            )
            else if state == "Canceled" then
            (
                jobTimer.active = false
                progress.value = 0
                setStatus "AI generation canceled"
                generateButton.enabled = true
                setupPassesButton.enabled = true
                extractPassesButton.enabled = true
                cancelButton.enabled = false
                busy = false
            )
        )
        catch
        (
            jobTimer.active = false
            setStatus "Could not poll AI job"
            generateButton.enabled = true
            setupPassesButton.enabled = true
            extractPassesButton.enabled = true
            cancelButton.enabled = false
            busy = false
        )
    )

    fn cancelNetworkGeneration =
    (
        if currentJobId != "" and networkBridge != undefined then
        (
            try
            (
                networkBridge.CancelGeneration currentJobId
                setStatus "Canceling AI generation..."
            )
            catch()
        )
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

        local ok = extractPasses()

        if ok then
        (
            progress.value = 20
            if not startNetworkGeneration() then
            (
                generateButton.enabled = true
                setupPassesButton.enabled = true
                extractPassesButton.enabled = true
                cancelButton.enabled = false
                busy = false
            )
        )
        else
        (
            progress.value = 0
            generateButton.enabled = true
            setupPassesButton.enabled = true
            extractPassesButton.enabled = true
            cancelButton.enabled = false
            busy = false
        )
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
        label providerLabel "Provider: Gemini • Nano Banana Pro" align:#left
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
        button generateButton "GENERATE AI" width:300 height:38 across:2
        button cancelButton "CANCEL" width:145 enabled:false
        progressbar progress "" value:0 width:300 height:8
        label statusLabel "Ready — render Beauty in Corona first." align:#left
    )

    timer jobTimer "AI job timer" interval:500 active:false

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
        label note1 "Generate: Corona passes → NanoNetwork.dll → Gemini → Max preview." align:#left
        label note2 "AI result is shown in this panel; Corona VFB source remains unchanged." align:#left
        label note3 "Select architectural objects before Setup Passes." align:#left
    )

    on openVfbButton pressed do openCoronaVfb()
    on setupPassesButton pressed do setupPasses()
    on extractPassesButton pressed do extractPasses()
    on generateButton pressed do generatePrototype()
    on cancelButton pressed do cancelNetworkGeneration()
    on jobTimer tick do pollNetworkJob()
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
        if loadNetworkBridge() then
        (
            if networkBridge.HasGeminiApiKey() then
                setStatus "Ready — Gemini API key configured."
            else
                setStatus "Ready — Gemini API key required on first Generate."
        )
    )

    on NanoCoronaVfbPrototype close do
    (
        try (jobTimer.active = false) catch()
        if currentJobId != "" and networkBridge != undefined do
        (
            try (networkBridge.CancelGeneration currentJobId) catch()
        )
    )
)

createDialog NanoCoronaVfbPrototype 340 760 style:#(#style_titlebar, #style_sysmenu, #style_resizing)
cui.RegisterDialogBar NanoCoronaVfbPrototype style:#(#cui_dock_right, #cui_floatable, #cui_handles)
cui.DockDialogBar NanoCoronaVfbPrototype #cui_dock_right

setStatus "Ready — select architecture, Setup Passes, then render."
