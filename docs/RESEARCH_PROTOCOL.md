# NanoCorona — Research Protocol

## Purpose

Research must be reproducible. Every experiment compares one controlled variable at a time.

## Test package

Each test should contain:

~~~text
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

Never store API keys or Authorization headers.

## Baseline benchmark

Use the same source image and camera for all tests.

A — Beauty only  
B — Beauty + Depth  
C — Beauty + Normals  
D — Beauty + Depth + Normals  
E — Beauty + Depth + Normals + Architecture Mask

## Evaluation dimensions

Record observations separately:

- geometry preservation;
- camera/composition preservation;
- facade layout preservation;
- material transformation;
- environment transformation;
- weather/atmosphere;
- unwanted additions/removals;
- text/signage changes;
- AI artifacts;
- latency;
- request errors.

Do not change prompt, model, passes and resolution simultaneously when trying to identify causality.

## Naming

Use monotonically increasing test IDs: Test_0001, Test_0002, ...

