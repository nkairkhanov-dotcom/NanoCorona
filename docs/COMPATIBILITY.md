# NanoCorona — compatibility matrix

## Target release

**Primary target: Autodesk 3ds Max 2026 + Corona 15 for 3ds Max.**

This release uses a dedicated **.NET 8** NanoNetwork bridge. The previous .NET Framework 4.6.2 bridge is no longer the target for this configuration.

| Component | Version | Status | Notes |
|---|---|---|---|
| Windows | 10 x64 | Target | Required host platform for this release |
| Windows | 11 x64 | Target | Recommended |
| 3ds Max | 2026 | Primary target | NanoNetwork targets .NET 8; runtime acceptance required |
| Corona | 15 for 3ds Max | Primary target | Corona 15 VFB workflow |
| 3ds Max | 2025 | Not target | Use a separate legacy branch/build if needed |
| 3ds Max | 2027 | Not target | Separate .NET 10 bridge is outside this release |
| Corona | 15 + other Max versions | Not claimed | Only the 3ds Max 2026 + Corona 15 combination is the release target |
| Gemini | Nano Banana Pro / gemini-3-pro-image | Implemented | Default generation and QA model |
| Gemini | Nano Banana 2 / gemini-3.1-flash-image | Implemented in UI | Must be available to the user's Gemini API account |

## .NET 8 bridge

The NanoNetwork project now targets net8.0-windows and uses Newtonsoft.Json plus Windows DPAPI support through the .NET 8 package ecosystem. Network and file work run asynchronously; MAXScript polls job state from the 3ds Max main thread.

Autodesk provides MAXScript and Python as supported 3ds Max 2026 scripting environments, and its developer documentation is the compatibility baseline for this plugin. See the Autodesk 3ds Max 2026 developer documentation. citeturn0search2

## Corona 15

Corona 15 provides the Corona VFB workflow used by NanoCorona. Chaos also documents direct Veras access from the Corona VFB starting with Corona 15, confirming that AI-assisted workflows are part of the current Corona VFB environment. NanoCorona remains a separate Gemini-based panel and does not depend on undocumented Corona VFB internals. citeturn0search10

## Release acceptance

Before calling this build verified on a workstation, test:

1. 3ds Max 2026 starts with Corona 15.
2. NanoCorona startup script loads.
3. NanoNetwork.dll loads under the 3ds Max 2026 .NET environment.
4. Settings/API-key storage works.
5. Corona Beauty render works.
6. Setup passes → fresh render → extraction.
7. Generate → result.
8. SOURCE / RESULT / A-B.
9. Vision QA.
10. Correction Pass.
11. Cancel.
12. Restart 3ds Max and verify the panel and credentials.
13. 1K / 2K / 4K request paths.
14. Gemini error/retry handling.

No claim of runtime verification should be made until these tests have been executed on a real 3ds Max 2026 + Corona 15 workstation.

## Installation paths

Autodesk documents 3ds Max 2026 user data under the LocalAppData Autodesk 3dsMax 2026 - 64bit language tree, with user startup scripts in the corresponding user startup scripts location. NanoCorona's installer targets the 2026 user-data tree rather than the older APPDATA pattern. citeturn1search1turn1search2
