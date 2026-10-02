# NanoCorona — Phase 5 Vision QA

## Pipeline

Corona Beauty + AI Result + Architecture Mask + Scene.json + Edit.json
→ Gemini Vision QA
→ normalized QA JSON
→ pass / violation
→ optional correction generation

## QA gate

The gate checks four invariants:

1. Architecture preserved — protected architecture remains unchanged according to the visual comparison and mask.
2. Camera preserved — framing/composition remains consistent.
3. Composition preserved — facade/window layout and major structural arrangement remain consistent.
4. Edit satisfied — the requested preset/edit is visibly addressed.

A result passes only when all four checks are true, the QA call succeeds, and severity is not high.

## Correction pass

A failed QA result can be sent through a correction pass. The correction prompt contains only the reported violations and explicitly instructs Gemini to preserve the original architecture/camera/composition and avoid introducing unrelated changes. The correction uses a lower strength than the original generation.

The correction is not automatic in the current UI: the user sees the QA result and chooses CORRECTION PASS.

## Important limitation

Vision QA is an AI-based visual judgement layer. architecturePreserved=true is not a mathematical pixel-diff guarantee. The next research step should establish a manually reviewed benchmark with known violations and measure QA precision/recall plus correction success.
