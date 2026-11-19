# 01 — Real-time event processing

**Status:** draft. Numbers below come from production work; each one gets confirmed before this note is published.

## Context

<!-- system, team size, scale, what the product did -->

## The problem

<!-- what was slow or unreliable, and how it showed up for users -->

## What changed

<!-- transport, fan-out, payload, backpressure, reconnect -->

## Result

| Metric | Before | After |
|---|---|---|
| Chat sync delay across iOS, web and backend | 3 s | under 1 s |
| Server-side chat event processing | 1.8 s | 700 ms |
| Time-tracking operations | 2.5 s | 900 ms |

## Trade-offs

<!-- what we gave up: consistency window, infra complexity, client work -->

## What I would do differently

<!-- -->
