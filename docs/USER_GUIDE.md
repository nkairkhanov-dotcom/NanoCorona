# NanoCorona — руководство пользователя

## Идея

NanoCorona использует Corona как физический исходник сцены, а AI — как управляемый image-editing слой.

Corona даёт:
- Beauty;
- Z-Depth;
- Normals;
- Architecture Mask;
- Scene.json.

NanoCorona добавляет:
- Edit.json;
- preset + prompt;
- AI generation;
- результат;
- Vision QA;
- Correction Pass.

## Обычный workflow

### 1. Подготовьте сцену

Откройте сцену в 3ds Max и убедитесь, что Corona выбран renderer. Откройте Corona VFB и получите нормальный Beauty render.

### 2. Защитите архитектуру

Перед Setup Passes выделите объекты здания/архитектуры. Это selection используется для architecture mask.

### 3. Настройте passes

Нажмите **Setup Depth / Normals / Architecture Mask**. После этого сделайте новый Corona render.

### 4. Извлеките пакет

Нажмите **Extract Passes + Scene.json**.

Пакет становится source-of-truth для конкретной генерации.

### 5. Выберите edit

Доступны presets:
- Photorealism;
- Change Sky;
- Weather;
- Materials;
- Wet Road.

Preset создаёт структурированный Edit.json. Prompt остаётся редактируемым.

### 6. Generate

Выберите:
- model;
- resolution;
- strength;
- Architecture locked.

Нажмите **GENERATE AI**.

Во время запроса UI остаётся отзывчивым. **CANCEL** отменяет сетевую задачу.

### 7. Сравнение

После генерации:
- **SOURCE** — Corona Beauty;
- **RESULT** — AI result;
- **A / B** — переключение между source и result.

Это сравнение относится к изображениям, а не к изменению исходной 3D-сцены.

### 8. Vision QA

Нажмите **VISION QA** после успешной генерации.

QA проверяет:
- сохранность архитектуры;
- камеру;
- композицию;
- удовлетворение Edit.json;
- severity/confidence;
- список нарушений.

QA — AI judgement layer, а не математическое доказательство pixel-perfect совпадения.

### 9. Correction Pass

Если QA обнаружил нарушения, нажмите **CORRECTION PASS**. Correction Pass повторно отправляет исходные технические данные и список нарушений с более низкой силой редактирования.

### 10. Сохранение

AI result сохраняется как отдельный PNG. Исходный Corona Beauty не заменяется.

## Рекомендации

Для архитектурных изменений сначала используйте низкую/среднюю Strength. Держите Architecture locked включённым, если геометрия и фасад не должны меняться.

Для неразрушающего workflow всегда сохраняйте исходный Corona render отдельно от AI result.

## Что NanoCorona не делает

- Не меняет 3D geometry.
- Не заменяет исходный Corona render.
- Не требует браузерного upload workflow.
- Не обещает, что AI всегда сохранит архитектуру идеально.
- Не использует undocumented Corona VFB widget internals как обязательную часть production path.
