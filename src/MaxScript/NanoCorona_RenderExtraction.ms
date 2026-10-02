/*
    NanoCorona — Corona render extraction + Scene.json

    Pipeline:
      Beauty (Corona VFB)
        + CGeometry_ZDepth
        + CGeometry_NormalsShading
        + CMasking_Mask (architecture selection)
        -> PNG passes
        -> Scene.json

    This file is intentionally MAXScript-only. It does not perform network I/O.
*/

global NanoCoronaRenderExtraction

struct NanoCoronaExtractionResult
(
    success = false,
    rootDir = "",
    beautyPath = "",
    depthPath = "",
    normalsPath = "",
    architectureMaskPath = "",
    sceneJsonPath = "",
    message = ""
)

struct NanoCoronaRenderExtraction
(
    fn isCoronaActive =
    (
        try
        (
            matchPattern (classOf renderers.current as string) pattern:"Corona*" ignoreCase:true
        )
        catch(false)
    )

    fn ensureDir dirPath =
    (
        if not doesFileExist dirPath do makeDir dirPath
        dirPath
    )

    fn jsonEscape value =
    (
        local s = value as string
        s = substituteString s "\\" "\\\\"
        s = substituteString s "\"" "\\\""
        s = substituteString s "\r" "\\r"
        s = substituteString s "\n" "\\n"
        s = substituteString s "\t" "\\t"
        s
    )

    fn jsonString value =
    (
        "\"" + (jsonEscape value) + "\""
    )

    fn jsonBool value =
    (
        if value then "true" else "false"
    )

    fn jsonNumber value =
    (
        formattedPrint value format:"%.6f"
    )

    fn getCamera =
    (
        local cam = undefined
        try (cam = getActiveCamera()) catch()
        if cam == undefined do
        (
            try (cam = viewport.getCamera()) catch()
        )
        cam
    )

    fn getElementManager =
    (
        maxOps.GetCurRenderElementMgr()
    )

    fn findElementByClass targetClass =
    (
        local mgr = getElementManager()
        for i = 0 to (mgr.NumRenderElements() - 1) do
        (
            local el = mgr.GetRenderElement i
            if (classOf el) == targetClass do return el
        )
        undefined
    )

    fn findElementIndexByClass targetClass =
    (
        local mgr = getElementManager()
        for i = 0 to (mgr.NumRenderElements() - 1) do
        (
            local el = mgr.GetRenderElement i
            if (classOf el) == targetClass do return i
        )
        undefined
    )

    fn addElementIfMissing elementClass elementName =
    (
        local existing = findElementByClass elementClass
        if existing != undefined then
        (
            try (existing.elementName = elementName) catch()
            existing
        )
        else
        (
            local mgr = getElementManager()
            local el = elementClass elementName:elementName
            if mgr.AddRenderElement el then el else undefined
        )
    )

    fn configureArchitectureMask =
    (
        local selectedNodes = for n in selection where (isValidNode n and not n.isHidden) collect n
        if selectedNodes.count == 0 then
        (
            return #(false, "Select the architectural/building objects first, then run Setup Passes.")
        )

        local mask = findElementByClass CMasking_Mask
        if mask == undefined then
        (
            mask = addElementIfMissing CMasking_Mask "NanoCorona_ArchitectureMask"
        )

        if mask == undefined then
        (
            return #(false, "Could not create CMasking_Mask.")
        )

        try
        (
            mask.elementName = "NanoCorona_ArchitectureMask"
            mask.mode = 0
            mask.nodesMonoOn = true
            mask.nodesMono = selectedNodes
        )
        catch
        (
            try
            (
                mask.nodesMonoOn = true
                mask.nodesMono = selectedNodes
            )
            catch
            (
                return #(false, "CMasking_Mask was created, but its object selection could not be configured.")
            )
        )

        #(true, ("Architecture mask configured from " + selectedNodes.count as string + " selected object(s)."))
    )

    fn setupPasses =
    (
        if not isCoronaActive() then
        (
            return #(false, #(), "Corona is not the active renderer.")
        )

        local depth = addElementIfMissing CGeometry_ZDepth "NanoCorona_ZDepth"
        local normals = addElementIfMissing CGeometry_NormalsShading "NanoCorona_NormalsShading"

        if depth == undefined or normals == undefined then
        (
            return #(false, #(), "Could not create one or more Corona geometry render elements.")
        )

        local maskResult = configureArchitectureMask()
        if not maskResult[1] then
        (
            return #(false, #(depth, normals), maskResult[2])
        )

        local mgr = getElementManager()
        mgr.SetElementsActive true

        #(true, #(depth, normals, findElementByClass CMasking_Mask), "Passes ready. Render the frame again so Corona generates Depth, Normals and Architecture Mask.")
    )

    fn saveBitmap bmp path =
    (
        if bmp == undefined then return false
        try
        (
            bmp.filename = path
            save bmp quiet:true
            true
        )
        catch(false)
    )

    fn getChannelBitmap channelIndex =
    (
        local bmp = undefined

        if channelIndex != undefined do
        (
            try (bmp = CoronaRenderer.CoronaFp.getVfbContent channelIndex false false) catch()
            if bmp == undefined do
            (
                try (bmp = CoronaRenderer.CoronaFp.getVfbContent channelIndex true false) catch()
            )
        )

        bmp
    )

    fn writeSceneJson rootDir beautyPath depthPath normalsPath maskPath =
    (
        local cam = getCamera()
        local camName = if cam != undefined then cam.name else ""
        local projection = "perspective"
        local cameraLocked = true

        if cam != undefined do
        (
            try
            (
                if cam.orthoProjection then projection = "orthographic"
            )
            catch()
        )

        local width = renderWidth
        local height = renderHeight
        local aspect = if height != 0 then (width as float / height) else 0.0

        local architectureObjects = #()
        local maskElement = findElementByClass CMasking_Mask

        if maskElement != undefined do
        (
            try
            (
                if maskElement.nodesMono != undefined do
                (
                    architectureObjects = for n in maskElement.nodesMono where isValidNode n collect n.name
                )
            )
            catch()
        )

        local sceneObjects = for n in geometry where (not n.isHidden and not n.isFrozen) collect n
        local objectJson = ""

        for i = 1 to sceneObjects.count do
        (
            local n = sceneObjects[i]
            local architectureLocked = (findItem architectureObjects n.name) > 0

            objectJson +=
            (
                "      {" +
                "\"name\":" + jsonString n.name + "," +
                "\"class\":" + jsonString ((classOf n) as string) + "," +
                "\"visible\":" + jsonBool (not n.isHidden) + "," +
                "\"architectureLocked\":" + jsonBool architectureLocked +
                "}"
            )
            if i < sceneObjects.count do objectJson += ","
            objectJson += "\n"
        )

        local cameraBlock =
        (
            "{" +
            "\"name\":" + jsonString camName + "," +
            "\"projection\":" + jsonString projection + "," +
            "\"compositionLocked\":" + jsonBool cameraLocked + "," +
            "\"width\":" + width as string + "," +
            "\"height\":" + height as string + "," +
            "\"aspectRatio\":" + jsonNumber aspect +
            "}"
        )

        local json =
        (
            "{\n" +
            "  \"schemaVersion\": \"1.1\",\n" +
            "  \"scene\": {\n" +
            "    \"type\": \"architectural_visualization\",\n" +
            "    \"camera\": " + cameraBlock + ",\n" +
            "    \"render\": {\n" +
            "      \"renderer\": " + jsonString ((classOf renderers.current) as string) + ",\n" +
            "      \"width\": " + width as string + ",\n" +
            "      \"height\": " + height as string + "\n" +
            "    },\n" +
            "    \"passes\": {\n" +
            "      \"beauty\": " + jsonString beautyPath + ",\n" +
            "      \"depth\": " + jsonString depthPath + ",\n" +
            "      \"normals\": " + jsonString normalsPath + ",\n" +
            "      \"architectureMask\": " + jsonString maskPath + "\n" +
            "    },\n" +
            "    \"architectureSelectionCount\": " + architectureObjects.count as string + ",\n" +
            "    \"objects\": [\n" +
            objectJson +
            "    ]\n" +
            "  },\n" +
            "  \"regions\": [\n" +
            "    {\n" +
            "      \"id\": \"architecture\",\n" +
            "      \"label\": \"Architecture\",\n" +
            "      \"protected\": true,\n" +
            "      \"mask\": " + jsonString maskPath + ",\n" +
            "      \"appearanceEditable\": true,\n" +
            "      \"geometryEditable\": false\n" +
            "    },\n" +
            "    {\n" +
            "      \"id\": \"environment\",\n" +
            "      \"label\": \"Environment\",\n" +
            "      \"protected\": false,\n" +
            "      \"appearanceEditable\": true,\n" +
            "      \"geometryEditable\": false\n" +
            "    }\n" +
            "  ],\n" +
            "  \"constraints\": [\n" +
            "    \"Preserve camera composition.\",\n" +
            "    \"Preserve architectural geometry and facade layout.\",\n" +
            "    \"Do not move or remove protected architecture objects.\",\n" +
            "    \"Prefer appearance/environment changes over geometry changes.\"\n" +
            "  ]\n" +
            "}\n"
        )

        local path = rootDir + "\\Scene.json"
        local f = createFile path
        if f == undefined then return undefined
        format "%" json to:f
        close f
        path
    )

    fn extractCurrentVfb =
    (
        local result = NanoCoronaExtractionResult()

        if not isCoronaActive() then
        (
            result.message = "Corona is not the active renderer."
            return result
        )

        local root = ensureDir ((getDir #temp) + "\\NanoCorona\\Current")
        result.rootDir = root

        local beauty = undefined
        try (beauty = CoronaRenderer.CoronaFp.getVfbContent 0 true false) catch()

        if beauty == undefined then
        (
            result.message = "No Beauty image is available in the Corona VFB. Render a frame first."
            return result
        )

        result.beautyPath = root + "\\beauty.png"
        if not saveBitmap beauty result.beautyPath then
        (
            try (close beauty) catch()
            result.message = "Could not save Beauty."
            return result
        )
        try (close beauty) catch()

        local depthIndex = findElementIndexByClass CGeometry_ZDepth
        local normalsIndex = findElementIndexByClass CGeometry_NormalsShading
        local maskIndex = findElementIndexByClass CMasking_Mask

        -- Corona VFB channel 0 is Beauty, 1 is Alpha, and extra render
        -- elements follow the render-element list with an offset of +2.
        local depthChannel = if depthIndex != undefined then depthIndex + 2 else undefined
        local normalsChannel = if normalsIndex != undefined then normalsIndex + 2 else undefined
        local maskChannel = if maskIndex != undefined then maskIndex + 2 else undefined

        local depthBmp = getChannelBitmap depthChannel
        local normalsBmp = getChannelBitmap normalsChannel
        local maskBmp = getChannelBitmap maskChannel

        if depthBmp == undefined or normalsBmp == undefined or maskBmp == undefined then
        (
            result.message = "Beauty was captured, but one or more technical passes are missing. Run Setup Passes, render again, then Extract Passes."
            try (if depthBmp != undefined do close depthBmp) catch()
            try (if normalsBmp != undefined do close normalsBmp) catch()
            try (if maskBmp != undefined do close maskBmp) catch()
            return result
        )

        result.depthPath = root + "\\depth.png"
        result.normalsPath = root + "\\normals.png"
        result.architectureMaskPath = root + "\\architecture_mask.png"

        local okDepth = saveBitmap depthBmp result.depthPath
        local okNormals = saveBitmap normalsBmp result.normalsPath
        local okMask = saveBitmap maskBmp result.architectureMaskPath

        try (close depthBmp) catch()
        try (close normalsBmp) catch()
        try (close maskBmp) catch()

        if not (okDepth and okNormals and okMask) then
        (
            result.message = "Could not save one or more technical passes."
            return result
        )

        result.sceneJsonPath = writeSceneJson root result.beautyPath result.depthPath result.normalsPath result.architectureMaskPath

        if result.sceneJsonPath == undefined then
        (
            result.message = "Passes were saved, but Scene.json could not be written."
            return result
        )

        result.success = true
        result.message = "Beauty + Depth + Normals + Architecture Mask + Scene.json ready."
        result
    )
)

NanoCoronaRenderExtraction = NanoCoronaRenderExtraction()
