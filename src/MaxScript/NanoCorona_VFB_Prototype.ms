/*
    NanoCorona — Corona VFB right-panel prototype

    UI milestone:
      Corona VFB + NanoCorona panel

    Data milestone:
      Beauty + Z-Depth + Normals + Architecture Mask + Scene.json

    Provider/network integration: NanoNetwork.dll async bridge.
*/

global NanoCoronaVfbPrototype
global NanoCoronaPrototypeDir

try (cui.UnRegisterDialogBar NanoCoronaVfbPrototype) catch()
try (destroyDialog NanoCoronaVfbPrototype) catch()

NanoCoronaPrototypeDir = getFilenamePath (getSourceFileName())
try
(
    if NanoCoronaRenderExtraction == undefined do
        fileIn (NanoCoronaPrototypeDir + "NanoCorona_RenderExtraction.ms")
)
catch
(
    try (fileIn (NanoCoronaPrototypeDir + "NanoCorona_RenderExtraction.ms")) catch()
)

rollout NanoCoronaVfbPrototype "NanoCorona" width:340 height:760
(
    local lastResultBitmap = undefined
    local resultPath = ""
    local sceneJsonPath = ""
    local editJsonPath = ""
    local busy = false
    local networkBridge = undefined
    local networkDllPath = ""
    local currentJobId = ""
    local qaJobId = ""
    local networkReady = false
    local compareMode = "Result"
    local selectedModel = "gemini-3-pro-image"
    local apiKeyConfigured = false

    fn setStatus messageText =
    (
        try
        (
            NanoCoronaVfbPrototype.statusLabel.text = messageText
        )
        catch
        (
            try (NanoCoronaVfbPrototype.statusLabel.text = messageText) catch()
        )
    )

    fn findNetworkDll =
    (
        local candidates = #()
        append candidates (NanoCoronaPrototypeDir + "..\\NanoNetwork\\bin\\Release\\NanoNetwork.dll")
        append candidates (NanoCoronaPrototypeDir + "..\\NanoNetwork\\bin\\Debug\\NanoNetwork.dll")
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

        local dll = NanoCoronaVfbPrototype.findNetworkDll()

        if dll == undefined then
        (
            networkDllPath = ""
            NanoCoronaVfbPrototype.setStatus "NanoNetwork.dll not found"
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
            NanoCoronaVfbPrototype.setStatus "Could not load NanoNetwork.dll"
            false
        )
    )

    fn promptForApiKey promptText =
    (
        local form = undefined
        local label = undefined
        local textBox = undefined
        local okButton = undefined
        local cancelButton = undefined
        local result = undefined
        local forms = undefined

        try
        (
            forms = dotNetClass "System.Windows.Forms.Application"
            dotNet.loadAssembly "System.Windows.Forms"
            dotNet.loadAssembly "System.Drawing"

            form = dotNetObject "System.Windows.Forms.Form"
            form.Text = "NanoCorona — Gemini API Key"
            form.Width = 520
            form.Height = 155
            form.FormBorderStyle = (dotNetClass "System.Windows.Forms.FormBorderStyle").FixedDialog
            form.StartPosition = (dotNetClass "System.Windows.Forms.FormStartPosition").CenterScreen
            form.MinimizeBox = false
            form.MaximizeBox = false
            form.TopMost = true

            label = dotNetObject "System.Windows.Forms.Label"
            label.Text = promptText
            label.Left = 12
            label.Top = 12
            label.Width = 480
            label.Height = 24
            form.Controls.Add label

            textBox = dotNetObject "System.Windows.Forms.TextBox"
            textBox.Left = 12
            textBox.Top = 38
            textBox.Width = 480
            textBox.UseSystemPasswordChar = true
            form.Controls.Add textBox

            okButton = dotNetObject "System.Windows.Forms.Button"
            okButton.Text = "Save"
            okButton.Left = 322
            okButton.Top = 72
            okButton.Width = 80
            okButton.DialogResult = (dotNetClass "System.Windows.Forms.DialogResult").OK
            form.Controls.Add okButton

            cancelButton = dotNetObject "System.Windows.Forms.Button"
            cancelButton.Text = "Cancel"
            cancelButton.Left = 412
            cancelButton.Top = 72
            cancelButton.Width = 80
            cancelButton.DialogResult = (dotNetClass "System.Windows.Forms.DialogResult").Cancel
            form.Controls.Add cancelButton

            form.AcceptButton = okButton
            form.CancelButton = cancelButton

            if form.ShowDialog() == (dotNetClass "System.Windows.Forms.DialogResult").OK then
                result = textBox.Text
            else
                result = undefined

            try (form.Dispose()) catch()
            result
        )
        catch
        (
            try (if form != undefined do form.Dispose()) catch()
            undefined
        )
    )

    fn openSettings =
    (
        local key = undefined
        if not NanoCoronaVfbPrototype.loadNetworkBridge() then return false
        key = NanoCoronaVfbPrototype.promptForApiKey "Enter Gemini API key (stored encrypted for this Windows user):"
        if key != undefined and key != "" then
        (
            try
            (
                networkBridge.SaveGeminiApiKey key
                NanoCoronaVfbPrototype.apiStatusLabel.text = "API key: configured"
                NanoCoronaVfbPrototype.setStatus "Settings saved"
                true
            ) catch (false)
        )
        else false
    )

    fn ensureApiKey =
    (
        local key = undefined
        if not NanoCoronaVfbPrototype.loadNetworkBridge() then return false

        try
        (
            if networkBridge.HasGeminiApiKey() then return true
        )
        catch()

        key = NanoCoronaVfbPrototype.promptForApiKey "Enter your Gemini API key:"
        if key == undefined or key == "" then
        (
            NanoCoronaVfbPrototype.setStatus "Gemini API key is required"
            return false
        )

        try
        (
            networkBridge.SaveGeminiApiKey key
            NanoCoronaVfbPrototype.setStatus "Gemini API key saved"
            true
        )
        catch
        (
            NanoCoronaVfbPrototype.setStatus "Could not save Gemini API key"
            false
        )
    )

    fn jsonEscape value =
    (
        local s = value as string
        s = substituteString s "\\" "\\\\"
        s = substituteString s "\"" "\\\""
        s = substituteString s "\r" ""
        s = substituteString s "\n" "\\n"
        s
    )

    fn getPresetName =
    (
        if NanoCoronaVfbPrototype.editPresetDrop.selection == 2 then "Change Sky"
        else if NanoCoronaVfbPrototype.editPresetDrop.selection == 3 then "Weather"
        else if NanoCoronaVfbPrototype.editPresetDrop.selection == 4 then "Materials"
        else if NanoCoronaVfbPrototype.editPresetDrop.selection == 5 then "Wet Road"
        else "Photorealism"
    )

    fn getPresetInstruction =
    (
        local p = NanoCoronaVfbPrototype.getPresetName()
        if p == "Change Sky" then "Replace the sky and distant atmospheric background only; preserve the building silhouette, facade and camera composition."
        else if p == "Weather" then "Modify weather and atmosphere: clouds, haze, sunlight and ambient conditions. Keep architecture unchanged."
        else if p == "Materials" then "Improve architectural material appearance, physically plausible roughness, reflections and texture response. Do not alter material boundaries or geometry."
        else if p == "Wet Road" then "Make the visible road and pavement wet with realistic reflections, puddles and subtle darkening; preserve all architecture and camera composition."
        else "Improve photorealism, lighting, material response and natural environmental integration without changing architectural geometry."
    )

    fn buildEditJson packageDir =
    (
        local p = NanoCoronaVfbPrototype.getPresetName()
        local strength = NanoCoronaVfbPrototype.strengthSpinner.value
        local protectedArchitecture = NanoCoronaVfbPrototype.architectureLock.checked
        local constraints = #(
            "Preserve camera composition and framing.",
            "Preserve architectural geometry, facade layout and window placement.",
            "Do not add, remove or relocate structural building elements.",
            "Keep the edit appearance-focused unless an operation explicitly targets an editable environment region."
        )
        if protectedArchitecture do append constraints "Architecture is protected by architecture_mask.png and must remain unchanged."

        local opAction = if p == "Change Sky" then "replace" else "modify"
        local target = if p == "Change Sky" then "sky" else if p == "Weather" then "environment" else if p == "Materials" then "architectural materials" else if p == "Wet Road" then "road and pavement" else "overall appearance"
        local mask = if p == "Change Sky" then "environment" else if p == "Wet Road" then "road" else "auto"
        local op = "{\"action\":\"" + opAction + "\",\"target\":\"" + (NanoCoronaVfbPrototype.jsonEscape target) + "\",\"instruction\":\"" + (NanoCoronaVfbPrototype.jsonEscape (NanoCoronaVfbPrototype.getPresetInstruction())) + "\",\"strength\":" + (strength as string) + ",\"protected\":" + (protectedArchitecture as string) + ",\"appearanceOnly\":true,\"mask\":\"" + mask + "\"}"
        local constraintJson = ""
        for i = 1 to constraints.count do
        (
            if i > 1 do constraintJson += ","
            constraintJson += "\"" + (NanoCoronaVfbPrototype.jsonEscape constraints[i]) + "\""
        )

        local json = "{\"schemaVersion\":\"1.1\",\"preset\":\"" + (NanoCoronaVfbPrototype.jsonEscape p) + "\",\"source\":\"NanoCorona MAXScript preset\",\"operations\":[" + op + "],\"globalConstraints\":[" + constraintJson + "]}"
        local path = packageDir + "\\Edit.json"
        local f = createFile path
        format "%" json to:f
        close f
        editJsonPath = path
        path
    )

    fn getResolutionValue =
    (
        if NanoCoronaVfbPrototype.resolutionDrop.selection == 3 then "4K"
        else if NanoCoronaVfbPrototype.resolutionDrop.selection == 1 then "1K"
        else "2K"
    )

    fn startNetworkGeneration =
    (
        local outputDir = ""
        local stamp = ""
        local outputPath = ""
        if not NanoCoronaVfbPrototype.loadNetworkBridge() then
        (
            messageBox "NanoNetwork.dll was not found. Build/copy NanoNetwork.dll before using Generate AI." title:"NanoCorona"
            return false
        )

        if not NanoCoronaVfbPrototype.ensureApiKey() then return false

        if sceneJsonPath == "" or not doesFileExist sceneJsonPath then
        (
            NanoCoronaVfbPrototype.setStatus "Scene.json is missing"
            return false
        )

        outputDir = getFilenamePath sceneJsonPath
        stamp = (localTime as string)
        stamp = substituteString stamp ":" "_"
        stamp = substituteString stamp "/" "_"
        stamp = substituteString stamp " " "_"
        outputPath = outputDir + "\\nanocorona_result_" + stamp + ".png"
        NanoCoronaVfbPrototype.buildEditJson outputDir

        try
        (
            currentJobId = networkBridge.StartGeneration sceneJsonPath resultPath (outputDir + "\\depth.png") (outputDir + "\\normals.png") (outputDir + "\\architecture_mask.png") editJsonPath NanoCoronaVfbPrototype.promptEdit.text NanoCoronaVfbPrototype.strengthSpinner.value (NanoCoronaVfbPrototype.getResolutionValue()) selectedModel outputPath ""

            NanoCoronaVfbPrototype.setStatus "Gemini generation started..."
            NanoCoronaVfbPrototype.progress.value = 50
            NanoCoronaVfbPrototype.jobTimer.active = true
            true
        )
        catch
        (
            currentJobId = ""
            NanoCoronaVfbPrototype.setStatus "Could not start Gemini generation"
            messageBox "Could not start the AI request. Check NanoNetwork.dll and the Gemini API key." title:"NanoCorona"
            false
        )
    )

    fn startVisionQa =
    (
        if networkBridge == undefined and not NanoCoronaVfbPrototype.loadNetworkBridge() then
        (
            NanoCoronaVfbPrototype.setStatus "NanoNetwork.dll is not loaded"
            return false
        )
        if resultPath == "" or editJsonPath == "" or sceneJsonPath == "" then
        (
            NanoCoronaVfbPrototype.setStatus "QA inputs are missing"
            return false
        )
        try
        (
            qaJobId = networkBridge.StartVisionQa sceneJsonPath (getFilenamePath sceneJsonPath + "beauty.png") resultPath (getFilenamePath sceneJsonPath + "architecture_mask.png") editJsonPath NanoCoronaVfbPrototype.promptEdit.text
            NanoCoronaVfbPrototype.setStatus "Vision QA analyzing result..."
            NanoCoronaVfbPrototype.progress.value = 20
            NanoCoronaVfbPrototype.jobTimer.active = true
            true
        )
        catch
        (
            NanoCoronaVfbPrototype.setStatus "Could not start Vision QA"
            false
        )
    )

    fn startCorrection =
    (
        local outputDir = ""
        local stamp = ""
        local outputPath = ""
        if qaJobId == "" then return false
        outputDir = getFilenamePath sceneJsonPath
        stamp = substituteString ((localTime as string)) ":" "_"
        stamp = substituteString stamp "/" "_"
        stamp = substituteString stamp " " "_"
        outputPath = outputDir + "\\nanocorona_correction_" + stamp + ".png"
        try
        (
            currentJobId = networkBridge.StartCorrectionGeneration qaJobId sceneJsonPath resultPath (outputDir + "\\depth.png") (outputDir + "\\normals.png") (outputDir + "\\architecture_mask.png") editJsonPath (NanoCoronaVfbPrototype.getResolutionValue()) "gemini-3-pro-image" outputPath
            NanoCoronaVfbPrototype.setStatus "Correction pass started..."
            NanoCoronaVfbPrototype.progress.value = 20
            NanoCoronaVfbPrototype.jobTimer.active = true
            true
        )
        catch
        (
            NanoCoronaVfbPrototype.setStatus "Correction pass unavailable"
            false
        )
    )

    fn pollNetworkJob =
    (
        local qaState = ""
        local qp = 0
        local state = ""
        local p = 0
        local code = ""
        local message = ""
        local qaPassed = false
        local qaSummary = ""
        if currentJobId == "" and qaJobId == "" or networkBridge == undefined then
        (
            NanoCoronaVfbPrototype.jobTimer.active = false
            return()
        )

        try
        (
            if qaJobId != "" and currentJobId == "" then
            (
                qaState = networkBridge.GetJobState qaJobId
                qp = networkBridge.GetJobProgress qaJobId
                NanoCoronaVfbPrototype.progress.value = qp
                if qaState == "Analyzing" then NanoCoronaVfbPrototype.setStatus "Vision QA: checking architecture..."
                else if qaState == "Succeeded" then
                (
                    NanoCoronaVfbPrototype.jobTimer.active = false
                    qaPassed = networkBridge.GetJobQaPassed qaJobId
                    qaSummary = networkBridge.GetJobQaSummary qaJobId
                    if qaPassed then
                        NanoCoronaVfbPrototype.setStatus "QA passed • architecture preserved"
                    else
                    (
                        NanoCoronaVfbPrototype.setStatus "QA found violations — correction available"
                        messageBox (qaSummary + "\n\nUse Correction Pass to repair the result.") title:"NanoCorona Vision QA"
                        NanoCoronaVfbPrototype.correctionButton.enabled = true
                    )
                    qaJobId = ""
                    return()
                )
                else if qaState == "Failed" then
                (
                    NanoCoronaVfbPrototype.jobTimer.active = false
                    NanoCoronaVfbPrototype.setStatus "Vision QA failed"
                    qaJobId = ""
                    return()
                )
                return()
            )

            state = networkBridge.GetJobState currentJobId
            p = networkBridge.GetJobProgress currentJobId
            NanoCoronaVfbPrototype.progress.value = p

            if state == "Queued" or state == "Preparing" then
                NanoCoronaVfbPrototype.setStatus "Preparing AI request..."
            else if state == "Uploading" then
                NanoCoronaVfbPrototype.setStatus "Uploading Corona passes..."
            else if state == "Generating" then
                NanoCoronaVfbPrototype.setStatus "Gemini is generating..."
            else if state == "Saving" then
                NanoCoronaVfbPrototype.setStatus "Saving result..."
            else if state == "Canceling" then
                NanoCoronaVfbPrototype.setStatus "Canceling..."
            else if state == "Succeeded" then
            (
                NanoCoronaVfbPrototype.jobTimer.active = false
                resultPath = networkBridge.GetJobResultPath currentJobId
                if resultPath != "" and doesFileExist resultPath then
                (
                    NanoCoronaVfbPrototype.previewBeauty resultPath
                    NanoCoronaVfbPrototype.setStatus ("AI result ready • " + ((networkBridge.GetJobDurationMs currentJobId) as string) + " ms")
                    NanoCoronaVfbPrototype.qaButton.enabled = true
                )
                else
                (
                    NanoCoronaVfbPrototype.setStatus "Generation succeeded but result file is missing"
                )
                NanoCoronaVfbPrototype.generateButton.enabled = true
                NanoCoronaVfbPrototype.setupPassesButton.enabled = true
                NanoCoronaVfbPrototype.extractPassesButton.enabled = true
                NanoCoronaVfbPrototype.cancelButton.enabled = false
                busy = false
                NanoCoronaVfbPrototype.qaButton.enabled = true
                currentJobId = ""
            )
            else if state == "Failed" then
            (
                NanoCoronaVfbPrototype.jobTimer.active = false
                code = networkBridge.GetJobErrorCode currentJobId
                message = networkBridge.GetJobErrorMessage currentJobId
                NanoCoronaVfbPrototype.setStatus ("AI failed: " + code)
                messageBox (message + "\n\nError: " + code) title:"NanoCorona"
                NanoCoronaVfbPrototype.generateButton.enabled = true
                NanoCoronaVfbPrototype.setupPassesButton.enabled = true
                NanoCoronaVfbPrototype.extractPassesButton.enabled = true
                NanoCoronaVfbPrototype.cancelButton.enabled = false
                busy = false
                currentJobId = ""
            )
            else if state == "Canceled" then
            (
                NanoCoronaVfbPrototype.jobTimer.active = false
                NanoCoronaVfbPrototype.progress.value = 0
                NanoCoronaVfbPrototype.setStatus "AI generation canceled"
                NanoCoronaVfbPrototype.generateButton.enabled = true
                NanoCoronaVfbPrototype.setupPassesButton.enabled = true
                NanoCoronaVfbPrototype.extractPassesButton.enabled = true
                NanoCoronaVfbPrototype.cancelButton.enabled = false
                busy = false
                currentJobId = ""
            )
        )
        catch
        (
            NanoCoronaVfbPrototype.jobTimer.active = false
            NanoCoronaVfbPrototype.setStatus "Could not poll AI job"
            NanoCoronaVfbPrototype.generateButton.enabled = true
            NanoCoronaVfbPrototype.setupPassesButton.enabled = true
            NanoCoronaVfbPrototype.extractPassesButton.enabled = true
            NanoCoronaVfbPrototype.cancelButton.enabled = false
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
                NanoCoronaVfbPrototype.setStatus "Canceling AI generation..."
            )
            catch()
        )
    )

    fn openCoronaVfb =
    (
        try
        (
            CoronaRenderer.CoronaFp.showVfb true
            NanoCoronaVfbPrototype.setStatus "Corona VFB: open"
        )
        catch
        (
            messageBox "Corona VFB could not be opened. Make sure Corona is the active renderer." title:"NanoCorona"
            NanoCoronaVfbPrototype.setStatus "Corona VFB: unavailable"
        )
    )

    fn previewBeauty beautyPath =
    (
        local bmp = undefined
        if beautyPath == "" or not doesFileExist beautyPath then return false

        try
        (
            bmp = openBitmap beautyPath
            if bmp != undefined then
            (
                if lastResultBitmap != undefined do
                (
                    try (free lastResultBitmap) catch()
                    lastResultBitmap = undefined
                )

                lastResultBitmap = copy bmp
                NanoCoronaVfbPrototype.resultPreview.bitmap = lastResultBitmap
                NanoCoronaVfbPrototype.resultPathLabel.text = beautyPath
                close bmp
                true
            )
            else false
        )
        catch(false)
    )

    fn setupPasses =
    (
        local r = undefined
        if NanoCoronaRenderExtraction == undefined then
        (
            messageBox "Render extraction module is not loaded." title:"NanoCorona"
            NanoCoronaVfbPrototype.setStatus "Extraction module unavailable"
            return false
        )

        r = NanoCoronaRenderExtraction.setupPasses()

        if r[1] then
        (
            NanoCoronaVfbPrototype.setStatus r[3]
            messageBox (r[3] + "\n\nRender the frame again, then press Extract Passes.") title:"NanoCorona"
            true
        )
        else
        (
            messageBox r[3] title:"NanoCorona"
            NanoCoronaVfbPrototype.setStatus r[3]
            false
        )
    )

    fn extractPasses =
    (
        local r = undefined
        if NanoCoronaRenderExtraction == undefined then
        (
            messageBox "Render extraction module is not loaded." title:"NanoCorona"
            return false
        )

        r = NanoCoronaRenderExtraction.extractCurrentVfb()

        if r.success then
        (
            sceneJsonPath = r.sceneJsonPath
            resultPath = r.beautyPath
            NanoCoronaVfbPrototype.sceneLabel.text = ("Scene.json: " + sceneJsonPath)
            NanoCoronaVfbPrototype.editLabel.text = "Edit.json: will be created on Generate"
            NanoCoronaVfbPrototype.packageLabel.text = "Beauty + Depth + Normals + Architecture Mask"
            NanoCoronaVfbPrototype.previewBeauty r.beautyPath
            NanoCoronaVfbPrototype.setStatus "Passes + Scene.json ready"
            true
        )
        else
        (
            messageBox r.message title:"NanoCorona"
            NanoCoronaVfbPrototype.setStatus r.message
            false
        )
    )

    fn generatePrototype =
    (
        local ok = false
        if busy then return()

        busy = true
        NanoCoronaVfbPrototype.generateButton.enabled = false
        NanoCoronaVfbPrototype.setupPassesButton.enabled = false
        NanoCoronaVfbPrototype.extractPassesButton.enabled = false
        NanoCoronaVfbPrototype.setStatus "Extracting Corona inputs..."
        NanoCoronaVfbPrototype.progress.value = 15

        ok = NanoCoronaVfbPrototype.extractPasses()

        if ok then
        (
            NanoCoronaVfbPrototype.progress.value = 20
            if not NanoCoronaVfbPrototype.startNetworkGeneration() then
            (
                NanoCoronaVfbPrototype.generateButton.enabled = true
                NanoCoronaVfbPrototype.setupPassesButton.enabled = true
                NanoCoronaVfbPrototype.extractPassesButton.enabled = true
                NanoCoronaVfbPrototype.cancelButton.enabled = false
                busy = false
            )
        )
        else
        (
            NanoCoronaVfbPrototype.progress.value = 0
            NanoCoronaVfbPrototype.generateButton.enabled = true
            NanoCoronaVfbPrototype.setupPassesButton.enabled = true
            NanoCoronaVfbPrototype.extractPassesButton.enabled = true
            NanoCoronaVfbPrototype.cancelButton.enabled = false
            busy = false
        )
    )

    fn showSource =
    (
        local p = ""
        if sceneJsonPath != "" then
        (
            p = (getFilenamePath sceneJsonPath) + "\\beauty.png"
            if doesFileExist p then
            (
                compareMode = "Source"
                NanoCoronaVfbPrototype.previewBeauty p
                NanoCoronaVfbPrototype.setStatus "Showing Corona source"
                return true
            )
        )
        messageBox "Corona source Beauty is not available. Extract passes first." title:"NanoCorona"
        false
    )

    fn toggleAB =
    (
        if resultPath == "" or not doesFileExist resultPath then return false
        if compareMode == "Result" then NanoCoronaVfbPrototype.showSource() else
        (
            compareMode = "Result"
            NanoCoronaVfbPrototype.previewBeauty resultPath
            NanoCoronaVfbPrototype.setStatus "Showing AI result"
        )
        true
    )

    fn showResult =
    (
        local bmp = undefined
        if resultPath != "" and doesFileExist resultPath then
        (
            try
            (
                bmp = openBitmap resultPath
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
        label headerLabel "NanoCorona • AI image editing for Corona" align:#left
        label providerLabel "Gemini • Nano Banana Pro" align:#left
        label apiStatusLabel "API key: checking..." align:#left
        button settingsButton "Settings" width:145 across:2
        button openVfbButton "Open / Focus Corona VFB" width:145
    )

    group "Source" (
        dropdownlist sourceDrop "Source:" items:#("Beauty (Corona VFB)", "Z-Depth", "Normals", "Mask") selection:1 width:300
        button setupPassesButton "Setup Depth / Normals / Architecture Mask" width:300
        button extractPassesButton "Extract Passes + Scene.json" width:300
    )

    group "Edit" (
        dropdownlist editPresetDrop "Preset:" items:#("Photorealism", "Change Sky", "Weather", "Materials", "Wet Road") selection:1 width:300
        label presetHint "Preset creates a controlled Edit.json operation." align:#left
    )

    group "Prompt" (
        edittext promptEdit "" text:"Photorealistic architectural visualization. Preserve building geometry, camera composition and facade layout. Improve materials, lighting, sky and environment." height:100 fieldWidth:300 multiLine:true labelOnTop:true
    )

    group "Controls" (
        spinner strengthSpinner "Strength:" range:[0.1,1.0,0.65] type:#float scale:0.05 fieldWidth:65 across:2
        dropdownlist resolutionDrop "Resolution:" items:#("1K", "2K", "4K") selection:2 width:90
        dropdownlist modelDrop "Model:" items:#("Nano Banana 2", "Nano Banana Pro") selection:2 width:140
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
        button showSourceButton "SOURCE" width:95
        button showResultButton "RESULT" width:95
        button abButton "A / B" width:95
        button qaButton "VISION QA" width:145 enabled:false
        button correctionButton "CORRECTION PASS" width:145 enabled:false
        button captureButton "Capture VFB" width:145
    )

    group "Scene package" (
        label sceneLabel "Scene.json: not generated" width:300 align:#left
        label editLabel "Edit.json: not generated" width:300 align:#left
        label packageLabel "Beauty / Depth / Normals / Mask" width:300 align:#left
    )

    group "Prototype notes" (
        label note1 "Generate: Corona passes → NanoNetwork.dll → Gemini → Max preview." align:#left
        label note2 "AI result is shown in this panel; Corona VFB source remains unchanged." align:#left
        label note3 "Select architectural objects before Setup Passes." align:#left
        label note4 "Preset + Prompt are compiled into Edit.json before Gemini." align:#left
    )

    on openVfbButton pressed do NanoCoronaVfbPrototype.openCoronaVfb()
    on settingsButton pressed do NanoCoronaVfbPrototype.openSettings()
    on modelDrop selected i do selectedModel = if i == 1 then "gemini-3.1-flash-image" else "gemini-3-pro-image"
    on setupPassesButton pressed do NanoCoronaVfbPrototype.setupPasses()
    on extractPassesButton pressed do NanoCoronaVfbPrototype.extractPasses()
    on generateButton pressed do NanoCoronaVfbPrototype.generatePrototype()
    on editPresetDrop selected i do
    (
        local p = NanoCoronaVfbPrototype.getPresetName()
        if p == "Photorealism" then NanoCoronaVfbPrototype.promptEdit.text = "Improve photorealism, lighting and material response while preserving architecture and camera composition."
        else if p == "Change Sky" then NanoCoronaVfbPrototype.promptEdit.text = "Change the sky and atmosphere while preserving the building, camera and facade exactly."
        else if p == "Weather" then NanoCoronaVfbPrototype.promptEdit.text = "Change weather and atmosphere with realistic clouds, haze and sunlight; preserve architecture."
        else if p == "Materials" then NanoCoronaVfbPrototype.promptEdit.text = "Improve architectural materials, reflections, roughness and texture realism without changing geometry."
        else if p == "Wet Road" then NanoCoronaVfbPrototype.promptEdit.text = "Make the road and pavement wet with realistic reflections and puddles; preserve the building."
    )
    on cancelButton pressed do NanoCoronaVfbPrototype.cancelNetworkGeneration()
    on jobTimer tick do NanoCoronaVfbPrototype.pollNetworkJob()
    on captureButton pressed do
    (
        local ok = false
        local bmp = undefined
        local dir = ""
        local p = ""

        try
        (
            bmp = CoronaRenderer.CoronaFp.getVfbContent 0 true false
            if bmp != undefined then
            (
                dir = (getDir #temp) + "\\NanoCorona\\Current"
                if not doesFileExist dir do makeDir dir
                p = dir + "\\beauty.png"
                bmp.filename = p
                save bmp quiet:true
                close bmp
                resultPath = p
                NanoCoronaVfbPrototype.previewBeauty p
                NanoCoronaVfbPrototype.setStatus "Beauty captured"
                ok = true
            )
        )
        catch()

        if not ok do NanoCoronaVfbPrototype.setStatus "No Beauty render"
    )
    on showSourceButton pressed do NanoCoronaVfbPrototype.showSource()
    on showResultButton pressed do (compareMode = "Result"; NanoCoronaVfbPrototype.showResult())
    on abButton pressed do NanoCoronaVfbPrototype.toggleAB()
    on qaButton pressed do NanoCoronaVfbPrototype.startVisionQa()
    on correctionButton pressed do
    (
        if NanoCoronaVfbPrototype.startCorrection() then NanoCoronaVfbPrototype.correctionButton.enabled = false
    )

    on NanoCoronaVfbPrototype open do
    (
        try (NanoCoronaVfbPrototype.statusLabel.text = "Ready — select architecture, Setup Passes, then render.") catch()
        NanoCoronaVfbPrototype.openCoronaVfb()
        if NanoCoronaVfbPrototype.loadNetworkBridge() then
        (
            if networkBridge.HasGeminiApiKey() then
                NanoCoronaVfbPrototype.setStatus "Ready — Gemini API key configured."
            else
                NanoCoronaVfbPrototype.setStatus "Ready — Gemini API key required on first Generate."
        )
    )

    on NanoCoronaVfbPrototype close do
    (
        try (NanoCoronaVfbPrototype.jobTimer.active = false) catch()
        if currentJobId != "" and networkBridge != undefined do
        (
            try (networkBridge.CancelGeneration currentJobId) catch()
        )
    )
)

createDialog NanoCoronaVfbPrototype 340 760 style:#(#style_titlebar, #style_sysmenu, #style_resizing)
cui.RegisterDialogBar NanoCoronaVfbPrototype style:#(#cui_dock_right, #cui_floatable, #cui_handles)
cui.DockDialogBar NanoCoronaVfbPrototype #cui_dock_right
