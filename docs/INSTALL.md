# NanoCorona — установка

## Требования

- Windows 10/11 x64.
- Autodesk 3ds Max 2025/2026/2027 — целевые версии Phase 6; более старые версии не считаются runtime-tested.
- Corona Renderer for 3ds Max.
- Gemini API key с доступом к выбранной image-модели.
- Для сборки из исходников: Visual Studio Build Tools / MSBuild с поддержкой .NET Framework 4.6.2.

Chaos сейчас указывает 3ds Max 2018+ и Windows 10+ как общие требования Corona, но NanoCorona пока не заявляет runtime compatibility со всеми этими версиями. См. compatibility matrix.

## Быстрая установка из репозитория

1. Скачайте/клонируйте репозиторий.
2. Откройте PowerShell в корне NanoCorona.
3. Выполните:

    powershell -ExecutionPolicy Bypass -File .\installer\Install-NanoCorona.ps1

4. Скрипт пытается найти MSBuild и собрать `src/NanoNetwork/NanoNetwork.csproj` в Release.
5. Он устанавливает MAXScript и `NanoNetwork.dll` в пользовательские папки Startup/scripts всех обнаруженных установок 3ds Max.
6. Перезапустите 3ds Max.

Если MSBuild не найден, заранее положите готовый `NanoNetwork.dll` в:
`src/NanoNetwork/bin/Release/NanoNetwork.dll`

## Первый запуск

1. Запустите 3ds Max с активным Corona Renderer.
2. Откройте NanoCorona из панели/Customize UI, либо выполните установленный startup script.
3. Откройте Corona VFB.
4. Выберите архитектурные объекты, которые должны оставаться защищёнными.
5. Нажмите **Setup Depth / Normals / Architecture Mask**.
6. Сделайте обычный Corona render.
7. Нажмите **Extract Passes + Scene.json**.
8. В NanoCorona откройте **Settings** и сохраните Gemini API key.
9. Выберите preset/model/resolution, проверьте Prompt.
10. Нажмите **GENERATE AI**.

API key не записывается в репозиторий. NanoNetwork использует Windows DPAPI CurrentUser storage.

## Где лежат результаты

Рабочий пакет создаётся в:

`%TEMP%\NanoCorona\Current\`

В нём находятся Beauty, технические passes, Scene.json, Edit.json и AI results.

## Обновление

Запустите installer повторно после получения новой версии. Он заменяет NanoCorona files, но не трогает сохранённый API key.

## Удаление

Удалите NanoCorona из пользовательских `scripts\NanoCorona` и startup-папок соответствующих версий 3ds Max. API key можно удалить через существующий credential workflow/обнуление credential store; installer сам credentials не удаляет.
