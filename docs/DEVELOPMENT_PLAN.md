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

- [ ] Scene constraints extraction
- [ ] Result analysis
- [ ] Architecture violation report
- [ ] QA confidence
- [ ] Optional correction pass

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
