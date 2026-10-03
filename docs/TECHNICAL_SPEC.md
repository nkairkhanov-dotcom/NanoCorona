# NanoCorona — техническое задание v2

## 1. Назначение

**NanoCorona** — плагин для Autodesk 3ds Max + Corona Renderer, предназначенный для управляемой AI-постобработки архитектурных изображений непосредственно из 3ds Max.

Главный принцип проекта:

> Corona отвечает за геометрию, камеру, физически согласованный исходный рендер и технические passes; AI отвечает за целевые визуальные изменения, не разрушая защищённую архитектуру.

Плагин не должен работать как простой «фильтр Beauty → AI». Он должен строить управляемое представление сцены, выделять защищённые и изменяемые области и формировать для модели набор визуальных инструкций.

## 2. Цели

1. Получать из текущей сцены 3ds Max:
   - Beauty;
   - Z-Depth;
   - Normals;
   - дополнительные ID/Mask passes;
   - при необходимости пользовательские маски.
2. Анализировать Beauty и технические passes и строить структурированное описание сцены.
3. Представлять сцену в виде машиночитаемого Scene.json.
4. Представлять требуемые изменения в виде Edit.json.
5. Генерировать маски и набор reference images для целевого редактирования.
6. Отправлять данные в AI image-generation/editing provider через C#/.NET.
7. Получать результат без блокировки интерфейса 3ds Max.
8. Выполнять автоматическую проверку результата относительно исходного изображения.
9. При обнаружении существенного изменения защищённой архитектуры иметь возможность выполнить correction pass.
10. Сохранять каждое исследовательское испытание воспроизводимо.

## 3. Не входит в первую версию

Не блокировать MVP следующими функциями:

- сложная система лицензирования;
- онлайн-магазин/активация;
- автоматическая публикация релизов;
- полноценный менеджер материалов 3ds Max;
- автоматическая генерация идеальных масок для любого типа сцены;
- попытка управлять Nano Banana Pro через «магический JSON», если конкретная модель не принимает structured output как управляющий формат.

Эти возможности проектируются с учётом будущего расширения, но не являются условием первого работающего прототипа.

## 4. Поддерживаемая среда

> **Актуальный статус релиза:** этот документ задаёт архитектурные принципы v2, но текущая реализация и installer поддерживают только **3ds Max 2026 + Corona 15 + .NET 8**. Актуальная матрица находится в `docs/COMPATIBILITY.md`; более ранние версии Max не являются целью этой ветки.

### 4.1 3ds Max

Целевой минимум: **3ds Max 2015+**, но до релиза должна быть сформирована фактическая compatibility matrix по версиям Max и доступным .NET runtime.

### 4.2 Renderer

Основной renderer: **Corona Renderer for 3ds Max**.

В MVP требуется поддержка Corona render elements, необходимых для:

- Beauty;
- Z-Depth;
- Normals;
- masking/ID-представления.

Названия и API render elements должны определяться по установленной версии Corona, а не жёстко предполагаться одинаковыми для всех версий.

### 4.3 Технологии

- MAXScript — интеграция с 3ds Max, UI, render setup, получение/экспорт изображений.
- C#/.NET — сеть, JSON, асинхронные операции, хранение секретов, provider adapters.
- HTTPS.
- JSON.
- Без внешнего Python runtime.

## 5. Ключевая архитектурная идея

Пайплайн:

~~~text
3ds Max Scene
→ Corona Render
→ Beauty + Depth + Normals + IDs/Masks
→ Scene Intelligence
→ Scene.json
→ Edit.json
→ Masks + Prompt + References
→ AI Image Editing
→ Result
→ Vision QA
→ optional Correction Pass
→ Preview / Save
~~~

Важно: Scene.json и Edit.json — это **внутренний промежуточный control layer**, а не обещание того, что Nano Banana Pro будет интерпретировать произвольный JSON как команды.

Если выбранный image model не поддерживает structured outputs, JSON генерируется отдельным analysis/vision этапом или внутри плагина, после чего преобразуется в prompt, masks и reference inputs.

## 6. Роли компонентов

### 6.1 MAXScript

Отвечает за:

- запуск/контроль Corona render;
- настройку и поиск render elements;
- получение текущего Beauty/VFB;
- экспорт render passes;
- работу с 3ds Max UI;
- запуск C# методов;
- отображение прогресса;
- preview результата;
- пользовательские lock/edit маски;
- чтение/запись локальных настроек.

MAXScript не должен выполнять сетевые запросы к AI API.

### 6.2 NanoNetwork.dll

C# библиотека отвечает за:

- HTTPS;
- сериализацию JSON;
- provider adapter;
- upload/reference images;
- async request;
- retry/backoff;
- cancellation;
- timeout;
- скачивание результата;
- безопасное хранение API credentials;
- диагностическое логирование без секретов.

C# слой не должен напрямую модифицировать сцену через Max API из фонового потока.

### 6.3 Scene Intelligence Engine

Логический слой, который:

1. получает Beauty и passes;
2. определяет объекты/регионы;
3. строит Scene.json;
4. определяет protected regions;
5. формирует masks;
6. переводит пользовательскую команду в Edit.json;
7. превращает Edit.json в provider-specific generation request.

## 7. Модель сцены

Каждая сцена должна иметь минимум следующие категории:

### Camera

- projection;
- image size;
- aspect ratio;
- camera framing;
- perspective/protected composition.

### Objects

Для каждого существенного объекта:

- id;
- semantic label;
- region/mask;
- approximate depth;
- protected;
- editable;
- notes.

### Regions

Примеры:

- architecture;
- sky;
- vegetation;
- road;
- cars;
- people;
- background buildings;
- glass;
- facade;
- interior lights.

### Constraints

Примеры:

- preserve silhouette;
- preserve camera;
- preserve perspective;
- preserve facade proportions;
- preserve openings;
- preserve window positions;
- preserve structural elements.

## 8. Locked vs Editable

В MVP необходимо различать две логические категории.

### Protected / Locked

По умолчанию для архитектурной сцены:

- главный корпус здания;
- геометрический силуэт;
- фасадная сетка;
- окна/двери;
- арки;
- колонны;
- крупные конструктивные элементы;
- camera framing;
- perspective.

### Editable

Типовые области:

- sky;
- clouds;
- weather;
- season;
- vegetation appearance;
- road/wetness;
- background;
- cars;
- people;
- lighting atmosphere;
- material appearance;
- reflections;
- color grading.

Пользователь должен иметь возможность перевести регион из одной категории в другую.

## 9. Scene.json

Scene.json описывает **что находится в изображении**, а не то, каким оно должно стать.

Пример:

~~~json
{
  "schemaVersion": "1.0",
  "scene": {
    "type": "architectural_exterior",
    "camera": {
      "projection": "perspective",
      "compositionLocked": true
    }
  },
  "regions": [
    {
      "id": "architecture_main",
      "label": "main building",
      "protected": true,
      "mask": "masks/architecture_main.png"
    },
    {
      "id": "sky",
      "label": "sky",
      "protected": false,
      "mask": "masks/sky.png"
    }
  ],
  "constraints": [
    "preserve architectural geometry",
    "preserve camera perspective",
    "preserve facade proportions"
  ]
}
~~~

## 10. Edit.json

Edit.json описывает **что пользователь хочет изменить**.

Пример:

~~~json
{
  "schemaVersion": "1.0",
  "operations": [
    {
      "action": "replace",
      "target": "sky",
      "instruction": "overcast rainy autumn sky",
      "strength": 0.8
    },
    {
      "action": "modify",
      "target": "road",
      "instruction": "wet asphalt with realistic reflections",
      "strength": 0.7
    },
    {
      "action": "modify",
      "target": "architecture_main",
      "instruction": "white steel, white mesh and glass",
      "strength": 0.35,
      "protected": true
    }
  ]
}
~~~

Операция над protected region не должна автоматически означать изменение геометрии. Для материалов/appearance разрешается редактирование только если operation явно разрешает appearance-only change.

## 11. Маски

Маски — один из главных механизмов точного редактирования.

Минимально:

- architecture_mask;
- environment_mask.

Расширенный набор:

- sky_mask;
- vegetation_mask;
- road_mask;
- car_mask;
- people_mask;
- background_mask;
- glass_mask;
- facade_mask.

Правило:

**белое = область действия маски, чёрное = область вне действия**, если конкретный provider adapter не требует обратной полярности.

Для каждого provider должна существовать явная нормализация формата маски.

## 12. Corona passes

### Обязательные для research prototype

- Beauty;
- Z-Depth;
- Normals.

### Желательные

- Material ID;
- Instance/Object ID;
- пользовательский architecture mask;
- environment mask;
- другие доступные masking passes.

Не следует предполагать, что любой pass автоматически является «ControlNet». Для AI provider passes рассматриваются как reference/control images до тех пор, пока документация конкретного API не подтверждает специальную семантику.

## 13. Provider abstraction

Не привязывать ядро проекта к одному endpoint.

Интерфейс должен позволять:

- AnalyzeImage;
- GenerateImage;
- EditImage;
- GenerateStructuredScene;
- ValidateResult.

Первый provider — Google Gemini/Nano Banana family или совместимый API endpoint, выбранный владельцем проекта.

Конкретные model IDs, request schema, image limits, resolution limits и authentication flow должны храниться в provider adapter/configuration и проверяться по актуальной документации перед реализацией.

## 14. AI request

На generation stage отправляется набор:

1. исходный Beauty;
2. выбранные reference/control images;
3. masks;
4. сгенерированные инструкции;
5. параметры generation;
6. provider-specific options.

Концептуально:

~~~text
Beauty
+ Depth
+ Normals
+ Masks
+ Scene constraints
+ Edit instructions
→ Provider
→ Result
~~~

Не отправлять все passes всегда. Состав request должен зависеть от операции.

Например:

- Replace Sky → Beauty + sky mask + edit instruction;
- Change Materials → Beauty + architecture mask + optional normals;
- Environment/Weather → Beauty + depth + environment masks;
- Architecture-sensitive edit → Beauty + depth + normals + architecture mask.

## 15. AI Strength

Параметр strength нормализуется в диапазон 0.0–1.0.

Важно: не обещать одинаковое физическое значение strength между разными provider/model. Внутри NanoCorona это **логический коэффициент интенсивности операции**, который provider adapter преобразует в доступные ему параметры/instructions.

## 16. Vision QA

После генерации выполняется проверка результата.

QA должен сравнивать:

- silhouette;
- composition;
- major architectural regions;
- facade layout;
- window/opening positions;
- camera framing;
- unintended additions/removals.

Результат:

~~~json
{
  "passed": true,
  "violations": [],
  "confidence": 0.91
}
~~~

При нарушении:

Result → QA → correction instruction → second generation/edit pass

В MVP QA может быть только report-only режимом. Автоматический correction pass — следующий этап.

## 17. Research Mode

Каждое исследование должно сохраняться в отдельную папку:

~~~text
Research/
  Test_0001/
    input/
      beauty.png
      depth.png
      normals.png
    masks/
      architecture.png
      environment.png
    scene.json
    edit.json
    prompt.txt
    request.json
    response.json
    result.png
    qa.json
    metadata.json
~~~

Секреты и API keys в Research folders не сохранять.

Это необходимо для сравнения моделей, prompts, passes и параметров.

## 18. UI MVP

Минимальный UI:

### Source

- Current Corona Beauty;
- Render / Refresh;
- Preview passes.

### Control

- Architecture Locked;
- Environment Editable;
- Show masks;
- Auto Analyze.

### Edit

Готовые операции:

- Change Sky;
- Change Weather;
- Change Season;
- Change Materials;
- Add/Change Background;
- Improve Glass;
- Add Cars;
- Add People;
- Custom Instruction.

### Generation

- AI Strength;
- Resolution;
- Generate;
- Cancel;
- progress/status.

### Result

- Preview;
- Save;
- Send to VFB;
- Re-edit.

## 19. API key

API key не хранить в открытом виде в config.ini.

Предпочтительно:

- Windows DPAPI / защищённое локальное хранилище;
- в config хранить только metadata/identifier.

В логах:

- не выводить API key;
- не выводить Authorization header;
- не сохранять полные request payloads, содержащие секреты.

## 20. Async и thread safety

Сетевой запрос должен выполняться асинхронно.

Во время generation:

- UI остаётся отзывчивым;
- Generate блокируется;
- Cancel доступен, если provider transport поддерживает отмену;
- ошибки отображаются в UI.

Любые операции с 3ds Max API/UI должны выполняться в допустимом для 3ds Max потоке/механизме. Background thread используется для network/file I/O, а не для произвольного доступа к сцене.

## 21. Error handling

Минимальные категории:

- API key missing/invalid;
- provider unavailable;
- timeout;
- rate limit;
- invalid image;
- unsupported resolution;
- invalid request;
- generation failed;
- download failed;
- corrupted result;
- missing Corona pass;
- unsupported Max/Corona version.

Пользователю показывается понятное сообщение. В debug log сохраняется техническая причина без секретов.

## 22. Файловая структура проекта

~~~text
NanoCorona/
├── README.md
├── LICENSE
├── docs/
│   ├── TECHNICAL_SPEC.md
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT_PLAN.md
│   └── RESEARCH_PROTOCOL.md
├── schemas/
│   ├── scene.schema.json
│   └── edit.schema.json
├── src/
│   ├── MaxScript/
│   └── NanoNetwork/
├── installer/
├── config/
└── research/
~~~

Папки src, installer и production config могут быть пустыми до начала соответствующего этапа.

## 23. MVP definition

MVP считается достигнутым, когда:

1. из 3ds Max автоматически получают Beauty + ZDepth + Normals;
2. создаётся architecture mask;
3. создаётся Scene.json;
4. пользователь задаёт edit operation;
5. создаётся Edit.json;
6. request отправляется через C# async transport;
7. результат возвращается в 3ds Max;
8. исходная архитектурная композиция сохраняется в приемлемом для benchmark качестве;
9. исследовательский тест сохраняется полностью воспроизводимо;
10. ошибки не приводят к зависанию UI.

## 24. Первый benchmark

Эталонная сцена — архитектурный exterior из текущего проектного примера.

Зафиксировать:

- один camera;
- один Corona render;
- Beauty;
- ZDepth;
- Normals;
- architecture mask.

Проверить минимум пять режимов:

A. Beauty only  
B. Beauty + Depth  
C. Beauty + Normals  
D. Beauty + Depth + Normals  
E. Beauty + Depth + Normals + Architecture Mask

Для каждого теста сохранять одинаковый исходник, prompt/edit JSON и результат.

Критерии анализа:

- сохранение геометрии;
- сохранение камеры;
- сохранение фасадной сетки;
- качество изменения материалов;
- качество environment/weather;
- AI artifacts;
- необходимость correction pass.

## 25. Этапы разработки

### Phase 0 — Repository foundation
- документация;
- schemas;
- research protocol;
- issue backlog.

### Phase 1 — Corona extraction
- Beauty;
- ZDepth;
- Normals;
- masks;
- export.

### Phase 2 — Provider transport
- C# project;
- HTTP;
- authentication;
- image encoding;
- async;
- result download.

### Phase 3 — First generation
- Beauty → provider → result.

### Phase 4 — Controlled generation
- Depth;
- Normals;
- Architecture mask;
- Scene/Edit JSON.

### Phase 5 — UI
- operation presets;
- masks;
- progress;
- preview.

### Phase 6 — QA
- architecture validation;
- report;
- correction loop.

### Phase 7 — Packaging
- installer;
- encrypted MaxScript where appropriate;
- configuration;
- versioning;
- release package.

## 26. Критически важные ограничения

1. Не считать JSON сам по себе механизмом управления генерацией.
2. Не считать ZDepth/Normals специальными control channels без подтверждения provider API.
3. Не блокировать UI сетевым запросом.
4. Не вызывать Max API из произвольного background thread.
5. Не хранить API key plaintext.
6. Не привязывать core domain model к конкретному AI endpoint.
7. Не строить сложный UI до проверки качества generation pipeline.
8. Не оценивать результат только по субъективному впечатлению — каждый тест должен иметь сохранённые входы, инструкции и output.

## 27. Главный принцип проекта

NanoCorona должен решать не задачу:

> «Отправить Corona render в нейросеть».

А задачу:

> **«Дать AI возможность изменять визуальные свойства архитектурного изображения, сохраняя заданные человеком структурные ограничения сцены».**

Именно passes + masks + Scene.json + Edit.json + QA являются основой этой архитектуры.
