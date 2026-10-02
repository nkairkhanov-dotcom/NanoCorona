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

- [ ] MAXScript → C# bridge
- [ ] Generate button
- [ ] Progress
- [ ] Cancel
- [ ] Save result
- [ ] Preview

Definition of done:

Beauty → AI → result выполняется из 3ds Max без ручного копирования файлов.

## Milestone 4 — Controlled editing

- [x] Scene.json
- [ ] Edit.json
- [x] architecture mask
- [ ] environment mask
- [ ] operation presets
- [ ] provider request builder
- [ ] A/B benchmark

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
