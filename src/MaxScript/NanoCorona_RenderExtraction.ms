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
    ),

    fn ensureDir dirPath =
    (
        if not doesFileExist dirPath do makeDir dirPath
        dirPath
    ),

    fn jsonEscape value =
    (
        local s = value as string
        s = substituteString s "\\" "\\\\"
        s = substituteString s "\"" "\\\""
        s = substituteString s "\r" "\\r"
        s = substituteString s "\n" "\\n"
        s = substituteString s "\t" "\\t"
        s
    ),

    fn jsonString value =
    (
        "\"" + (jsonEscape value) + "\""
    ),

    fn jsonBool value =
    (
        if value then "true" else "false"
    ),

    fn jsonNumber value =
    (
        formattedPrint value format:"%.6f"
    ),

    fn getCamera =
    (
        local cam
        cam = undefined
        try (cam = getActiveCamera()) catch()
        if cam == undefined do
        (
            try (cam = viewport.getCamera()) catch()
        )
        cam
    ),

    fn getElementManager =
    (
        maxOps.GetCurRenderElementMgr()
    ),

    fn findElementByClass targetClass =
    (
        local mgr
        local el
        mgr = undefined
        el = undefined
        mgr = getElementManager()
        for i = 0 to (mgr.NumRenderElements() - 1) do
        (
            el = mgr.GetRenderElement i
            if (classOf el) == targetClass do return el
        )
        undefined
    ),

    fn findElementIndexByClass targetClass =
    (
        local mgr
        local el
        mgr = undefined
        el = undefined
        mgr = getElementManager()
        for i = 0 to (mgr.NumRenderElements() - 1) do
        (
            el = mgr.GetRenderElement i
            if (classOf el) == targetClass do return i
        )
        undefined
    ),

    fn addElementIfMissing elementClass elementName =
    (
        local existing = undefined
        local mgr
        local el
        mgr = undefined
        el = undefined
        existing = findElementByClass elementClass
        if existing != undefined then
        (
            try (existing.elementName = elementName) catch()
            existing
        )
        else
        (
            mgr = getElementManager()
            el = elementClass elementName:elementName
            if mgr.AddRenderElement el then el else undefined
        )
    ),

    fn findPropertyName target candidates =
    (
        local props = #()
        local prop = undefined
        local candidate = ""
        try (props = getPropNames target) catch (props = #())
        for candidate in candidates do
        (
            for prop in props do
            (
                if (toLower (prop as string)) == (toLower (candidate as string)) then return prop
            )
        )
        undefined
    ),

    fn setPropertyIfAvailable target candidates value =
    (
        local prop = undefined
        prop = findPropertyName target candidates
        if prop == undefined then false
        else
        (
            try
            (
                setProperty target prop value
                true
            )
            catch(false)
        )
    ),

    fn getPropertyIfAvailable target candidates defaultValue =
    (
        local prop = undefined
        prop = findPropertyName target candidates
        if prop == undefined then defaultValue
        else
        (
            try (getProperty target prop) catch(defaultValue)
        )
    ),

    fn calculateCameraDepthRange cam =
    (
        local minDepth = 1.0e9
        local maxDepth = 0.0
        local found = false
        local bb = undefined
        local n = undefined
        local corners = #()
        local p = undefined
        local depth = 0.0
        local span = 0.0
        local padding = 0.0

        if cam == undefined then return undefined

        for n in geometry where (not n.isHidden and not n.isFrozen) do
        (
            try
            (
                bb = nodeGetBoundingBox n cam.transform
                corners = #(
                    [bb[1].x, bb[1].y, bb[1].z],
                    [bb[1].x, bb[1].y, bb[2].z],
                    [bb[1].x, bb[2].y, bb[1].z],
                    [bb[1].x, bb[2].y, bb[2].z],
                    [bb[2].x, bb[1].y, bb[1].z],
                    [bb[2].x, bb[1].y, bb[2].z],
                    [bb[2].x, bb[2].y, bb[1].z],
                    [bb[2].x, bb[2].y, bb[2].z]
                )
                for p in corners do
                (
                    depth = -p.z
                    if depth > 0.0 then
                    (
                        minDepth = amin minDepth depth
                        maxDepth = amax maxDepth depth
                        found = true
                    )
                )
            )
            catch()
        )

        if not found then return undefined

        span = maxDepth - minDepth
        padding = amax (span * 0.05) 0.1
        minDepth = amax 0.01 (minDepth - padding)
        maxDepth = maxDepth + padding

        if maxDepth <= minDepth then
            maxDepth = minDepth + 1.0

        #(minDepth, maxDepth)
    ),

    fn configureZDepth depth cam =
    (
        local range = undefined
        local useCameraRange
        local minSet
        local maxSet
        local clipSet
        local message

        if depth == undefined then return #(false, undefined, "ZDepth element is undefined.")

        range = calculateCameraDepthRange cam
        if range == undefined then
            return #(false, undefined, "Could not calculate camera-space ZDepth range from visible geometry.")

        useCameraRange = setPropertyIfAvailable depth #("useCameraEnvironmentRange", "useCameraEnviroRange", "useEnviroRange", "useCameraRange", "useEnvironmentRange") false
        minSet = setPropertyIfAvailable depth #("minZ", "minDepth", "minZDepth") range[1]
        maxSet = setPropertyIfAvailable depth #("maxZ", "maxDepth", "maxZDepth") range[2]
        clipSet = setPropertyIfAvailable depth #("clipOutput", "clipOutputTo01", "clipOutputTo0_1") true

        message = "ZDepth range " + (formattedPrint range[1] format:"%.3f") + " - " + (formattedPrint range[2] format:"%.3f")
        if not minSet or not maxSet then
            message += " (Corona property names not exposed; range calculation saved for diagnostics only.)"

        #(minSet and maxSet, range, message)
    ),

    fn configureArchitectureMask =
    (
        local selectedNodes
        local mask
        selectedNodes = #()
        mask = undefined
        selectedNodes = for n in selection where (isValidNode n and not n.isHidden) collect n
        if selectedNodes.count == 0 then
        (
            return #(false, "Select the architectural/building objects first, then run Setup Passes.")
        )

        mask = findElementByClass CMasking_Mask
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
    ),

    fn setupPasses =
    (
        local depth
        local normals
        local maskResult
        local zDepthResult
        local cam
        local mgr
        depth = undefined
        normals = undefined
        maskResult = undefined
        zDepthResult = undefined
        cam = undefined
        mgr = undefined

        if not isCoronaActive() then
        (
            return #(false, #(), "Corona is not the active renderer.")
        )

        depth = addElementIfMissing CGeometry_ZDepth "NanoCorona_ZDepth"
        normals = addElementIfMissing CGeometry_NormalsShading "NanoCorona_NormalsShading"

        if depth == undefined or normals == undefined then
        (
            return #(false, #(), "Could not create one or more Corona geometry render elements.")
        )

        cam = getCamera()
        zDepthResult = configureZDepth depth cam
        if not zDepthResult[1] then
        (
            return #(false, #(depth, normals), zDepthResult[3])
        )

        maskResult = configureArchitectureMask()
        if not maskResult[1] then
        (
            return #(false, #(depth, normals), maskResult[2])
        )

        mgr = getElementManager()
        mgr.SetElementsActive true

        #(true, #(depth, normals, findElementByClass CMasking_Mask, zDepthResult[2]), "Passes ready. " + zDepthResult[3] + ". Render the frame again so Corona generates Depth, Normals and Architecture Mask.")
    ),

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
    ),

    fn getChannelBitmap channelIndex =
    (
        local bmp
        bmp = undefined

        if channelIndex != undefined do
        (
            try (bmp = CoronaRenderer.CoronaFp.getVfbContent channelIndex false false) catch()
            if bmp == undefined do
            (
                try (bmp = CoronaRenderer.CoronaFp.getVfbContent channelIndex true false) catch()
            )
        )

        bmp
    ),

    fn writeSceneJson rootDir beautyPath depthPath normalsPath maskPath =
    (
        local cam
        local camName
        local projection
        local cameraLocked
        local width
        local height
        local aspect
        local architectureObjects
        local maskElement
        local sceneObjects
        local objectJson
        local n
        local architectureLocked
        local zDepthRange
        local cameraBlock
        local json
        local path
        local f

        cam = getCamera()
        camName = if cam != undefined then cam.name else ""
        projection = "perspective"
        cameraLocked = true
        width = renderWidth
        height = renderHeight
        aspect = 0.0
        architectureObjects = #()
        maskElement = undefined
        sceneObjects = #()
        objectJson = ""
        n = undefined
        architectureLocked = false
        zDepthRange = calculateCameraDepthRange cam
        cameraBlock = ""
        json = ""
        path = ""
        f = undefined

        if cam != undefined do
        (
            try
            (
                if cam.orthoProjection then projection = "orthographic"
            )
            catch()
        )

        aspect = if height != 0 then (width as float / height) else 0.0
        maskElement = findElementByClass CMasking_Mask

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

        sceneObjects = for n in geometry where (not n.isHidden and not n.isFrozen) collect n

        for i = 1 to sceneObjects.count do
        (
            n = sceneObjects[i]
            architectureLocked = (findItem architectureObjects n.name) > 0

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

        cameraBlock =
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

        json =
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

        path = rootDir + "\\Scene.json"
        f = createFile path
        if f == undefined then return undefined
        format "%" json to:f
        close f
        path
    ),

    fn extractCurrentVfb =
    (
        local result
        local baseDir
        local root
        local beauty
        local depthIndex
        local normalsIndex
        local maskIndex
        local depthChannel
        local normalsChannel
        local maskChannel
        local depthBmp
        local normalsBmp
        local maskBmp
        local okDepth
        local okNormals
        local okMask
        local zDepthRange

        result = NanoCoronaExtractionResult()
        baseDir = ""
        root = ""
        beauty = undefined
        depthIndex = undefined
        normalsIndex = undefined
        maskIndex = undefined
        depthChannel = undefined
        normalsChannel = undefined
        maskChannel = undefined
        depthBmp = undefined
        normalsBmp = undefined
        maskBmp = undefined
        okDepth = false
        okNormals = false
        okMask = false
        zDepthRange = undefined

        if not isCoronaActive() then
        (
            result.message = "Corona is not the active renderer."
            return result
        )

        baseDir = (getDir #temp) + "\\NanoCorona"
        if not doesFileExist baseDir do makeDir baseDir
        root = ensureDir (baseDir + "\\Current")
        result.rootDir = root

        try (beauty = CoronaRenderer.CoronaFp.getVfbContent 0 true false) catch()

        if beauty == undefined do
        (
            try (beauty = getLastRenderedImage()) catch()
        )

        if beauty == undefined then
        (
            result.message = "No Corona Beauty render is available. Render a frame first and keep Corona as the active renderer."
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

        depthIndex = findElementIndexByClass CGeometry_ZDepth
        normalsIndex = findElementIndexByClass CGeometry_NormalsShading
        try
        (
            zDepthRange = calculateCameraDepthRange (getCamera())
        )
        catch
        (
            zDepthRange = undefined
        )
        maskIndex = findElementIndexByClass CMasking_Mask

        -- Corona VFB channel 0 is Beauty, 1 is Alpha, and extra render
        -- elements follow the render-element list with an offset of +2.
        depthChannel = if depthIndex != undefined then depthIndex + 2 else undefined
        normalsChannel = if normalsIndex != undefined then normalsIndex + 2 else undefined
        maskChannel = if maskIndex != undefined then maskIndex + 2 else undefined

        depthBmp = getChannelBitmap depthChannel
        normalsBmp = getChannelBitmap normalsChannel
        maskBmp = getChannelBitmap maskChannel

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

        okDepth = saveBitmap depthBmp result.depthPath
        okNormals = saveBitmap normalsBmp result.normalsPath
        okMask = saveBitmap maskBmp result.architectureMaskPath

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
