# NanoCorona — план разработки

## Milestone 0 — Foundation

- [x] Репозиторий создан
- [x] Базовое ТЗ v2
- [x] Архитектура
- [x] Scene schema
- [x] Edit schema
- [x] Research protocol
- [x] Issue backlog

## Milestone 1 — Corona extraction

Цель: получить стабильный набор исходных данных из 3ds Max.

- [ ] Detect 3ds Max version
- [x] Detect Corona
- [x] Create/find Beauty
- [x] Create/find ZDepth
- [x] Create/find Normals
- [x] Export passes
- [x] Validate dimensions — базовые размеры берутся из renderWidth/renderHeight; pixel-level validation будет добавлена в benchmark
- [x] Generate test architecture mask
- [ ] Save reproducible research package

Definition of done:

Beauty + Depth + Normals + mask получаются из текущего Corona VFB после одного повторного render после настройки элементов и имеют общий render frame/размер.

## Milestone 2 — Network prototype

- [x] C# class library
- [x] Provider interface
- [x] API credential storage (Windows DPAPI CurrentUser)
- [x] HTTPS transport
- [x] Async generation
- [x] Timeout
- [x] Retry policy
- [x] Result download
- [x] Error normalization

Definition of done:

локальный тест может отправить изображение и получить результат без участия Max UI.

## Milestone 3 — First Max integration

- [x] MAXScript → C# bridge
- [x] Generate button
- [x] Progress
- [x] Cancel
- [x] Save result
- [x] Preview

Definition of done:

Beauty → AI → result выполняется из 3ds Max без ручного копирования файлов. The Phase 3 bridge uses MAXScript timer polling so worker threads never touch Max UI/API.

## Milestone 4 — Controlled editing

- [x] Scene.json
- [x] Edit.json
- [x] architecture mask
- [ ] environment mask
- [x] operation presets — Photorealism, Change Sky, Weather, Materials, Wet Road
- [x] provider request builder — Edit.json is validated and compiled into provider prompt
- [ ] A/B benchmark — pending reproducible 3ds Max/Corona runtime experiments

Обязательный benchmark:

A Beauty only  
B Beauty + Depth  
C Beauty + Normals  
D Beauty + Depth + Normals  
E Beauty + Depth + Normals + Architecture Mask

## Milestone 5 — QA

- [x] Scene constraints extraction — Scene.json + Edit.json are supplied to QA
- [x] Result analysis — async Vision QA compares source/result with architecture mask
- [x] Architecture violation report
- [x] QA confidence
- [x] Optional correction pass — generated only when QA identifies a violation

## Milestone 6 — Productization

- [ ] UI polish
- [ ] settings
- [ ] installer
- [ ] encrypted distribution where required
- [ ] compatibility matrix
- [ ] documentation
- [ ] release build


### Phase 4 implementation notes

The controlled-edit path now creates an Edit.json beside the extracted Scene.json before each generation. The MAXScript preset selector provides five presets: Photorealism, Change Sky, Weather, Materials, and Wet Road. Each preset produces one explicit operation plus global constraints. When Architecture locked is enabled, the plan records the architecture as protected and the C# provider request explicitly treats the architecture mask as authoritative. NanoNetworkClient validates Edit.json before sending the request and includes both the edit plan and Scene.json as provider-agnostic control context; the JSON is not assumed to be a native Gemini command language.

Still pending: automatic environment-mask generation and the A/B benchmark (Beauty → Beauty+Depth → +Normals → +Architecture Mask). These require real Corona renders and should not be marked complete without runtime measurements.


### Phase 5 implementation notes

Vision QA runs asynchronously through NanoNetwork.dll and Gemini. It compares the original Corona Beauty, AI result, architecture protection mask, Scene.json and Edit.json. The QA response is normalized into schemas/qa.schema.json with architecture, camera, composition and edit-satisfaction checks, severity, confidence and violations.

If the QA gate fails, the MaxScript panel exposes a Correction Pass. The correction request carries the QA violations and uses a lower edit strength (0.35) while re-supplying Beauty, Depth, Normals, Architecture Mask, Scene.json and Edit.json. The correction pass is refused when QA reports all protected invariants and the requested edit as satisfied.

Validation status: implementation is committed, but no live 3ds Max/Corona runtime test or Gemini QA accuracy benchmark was performed here. QA is an AI judgement layer, not a pixel-perfect proof; later benchmark work should measure false positives/negatives against manually reviewed renders.
