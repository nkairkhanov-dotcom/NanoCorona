# NanoCorona — план разработки

## Milestone 0 — Foundation

- [x] Репозиторий создан
- [x] Базовое ТЗ v2
- [x] Архитектура
- [x] Scene schema
- [x] Edit schema
- [ ] Research protocol
- [ ] Issue backlog

## Milestone 1 — Corona extraction

Цель: получить стабильный набор исходных данных из 3ds Max.

- [ ] Detect 3ds Max version
- [ ] Detect Corona
- [ ] Create/find Beauty
- [ ] Create/find ZDepth
- [ ] Create/find Normals
- [ ] Export passes
- [ ] Validate dimensions
- [ ] Generate test architecture mask
- [ ] Save reproducible research package

Definition of done:

Beauty + Depth + Normals + mask получаются одной командой и имеют одинаковое разрешение/кадр.

## Milestone 2 — Network prototype

- [ ] C# class library
- [ ] Provider interface
- [ ] API credential storage
- [ ] HTTPS transport
- [ ] Async generation
- [ ] Timeout
- [ ] Retry policy
- [ ] Result download
- [ ] Error normalization

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

- [ ] Scene.json
- [ ] Edit.json
- [ ] architecture mask
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
