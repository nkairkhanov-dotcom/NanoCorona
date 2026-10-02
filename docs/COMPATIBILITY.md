# NanoCorona — compatibility matrix

Статус означает уровень проверки проекта, а не официальную совместимость Chaos.

| Component | Version | Status | Notes |
|---|---|---|---|
| Windows | 10 x64 | Supported target | Corona currently lists Windows 10+ |
| Windows | 11 x64 | Supported target | Recommended platform |
| 3ds Max | 2025 | Primary target | Uses .NET Framework 4.8 host; NanoNetwork currently targets .NET Framework 4.6.2; runtime test required |
| 3ds Max | 2026 | Blocked / port required | Autodesk moved 3ds Max to .NET 8; NanoNetwork currently targets .NET Framework 4.6.2, so a dedicated .NET 8 bridge build is required before claiming support |
| 3ds Max | 2027 | Blocked / port required | Autodesk 2027 uses .NET Core 10; requires a dedicated modern bridge build and runtime validation |
| 3ds Max | 2024 and older | Experimental | Not part of Phase 6 release guarantee |
| Corona | Current supported 3ds Max release | Target | Corona VFB workflow expected; exact build must be recorded in release QA |
| Corona | Older releases | Experimental | No blanket compatibility claim |
| .NET | 4.6.2 target assembly | Implemented | NanoNetwork project target |
| Gemini | Nano Banana Pro / gemini-3-pro-image | Implemented | Default model |
| Gemini | Nano Banana 2 / gemini-3.1-flash-image | UI target | Must be verified against current API account/model availability |

## Runtime bridge note

Autodesk documents .NET Framework 4.8 for 3ds Max 2025, .NET Core 8 for 3ds Max 2026, and .NET Core 10 for 3ds Max 2027. The current NanoNetwork project targets .NET Framework 4.6.2. Therefore Phase 6 should not claim 2026/2027 support until the network bridge is multi-targeted or otherwise adapted and tested.

## Release gate

Before publishing a binary release, test at minimum:

1. 3ds Max 2025 + current supported Corona build.
2. 3ds Max 2026 + current supported Corona build.
3. 3ds Max 2027 + current supported Corona build.
4. Setup passes → fresh render → extraction.
5. Generate → result.
6. Source/Result/A-B.
7. Vision QA.
8. Correction Pass.
9. Cancel.
10. Restart 3ds Max and verify stored settings.

The project must not label a configuration "verified" until the runtime test has actually been performed.

## External baseline

Chaos currently lists Corona for 3ds Max as supporting 3ds Max 2018 or newer and Windows 10 or newer. Autodesk's current system-requirements index covers 3ds Max 2024–2027, while 3ds Max 2026 has additional .NET transition guidance. NanoCorona narrows its own release target until these versions are runtime-tested.
