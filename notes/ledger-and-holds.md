# 04 — Ledger and holds

**Status:** draft. Design note, not a description of shipped work.

## Context

<!-- how balances are usually modelled and why that breaks -->

## The problem

<!-- concurrency, retries, partial failures, audit -->

## Design

<!-- append-only journal, postings, balances as projection, holds for open orders, idempotency keys -->

## Invariants

- every journal entry nets to zero per asset
- no balance change without a posting
- at-least-once delivery plus a unique key equals effectively-once

## Open questions

- settlement batching vs per-trade posting
- reconciliation cadence
