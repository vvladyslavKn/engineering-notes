# 02 — p95 from 850 ms to 320 ms on Postgres

## Context

EveryPig is a multi-tenant vertical SaaS platform: 100 farms and around 1,000 active users, built by a team of 18 engineers. I owned database schema, API design and caching for farm and tenant management and the operational dashboards.

## The problem

p95 API latency on the key modules was 850 ms and LCP on the Next.js pages was 4.2 s. Both numbers had the same root cause: the request path did far more work than the screen needed.

Concretely, a dashboard request loaded full entities through ORM relations to render four counters, list endpoints used offset pagination over tables sorted by a column with no matching index, and filter columns were indexed individually rather than together with the tenant column. The result was sequential scans over the whole tenant table and an N+1 pattern hidden behind a join that looked fine in code review.

## What changed

1. **Measured before touching anything.** `pg_stat_statements` plus per-endpoint query logging identified roughly ten statements responsible for most of the time. Everything else was noise.
2. **Indexes that match the queries.** Composite indexes on `(tenant_id, <sort column>)` covering the selected columns, and removal of redundant single-column indexes that only cost writes.
3. **Keyset pagination** instead of offset, so page 40 costs the same as page 1.
4. **Narrow selects** for list and dashboard views: aggregate in SQL, return the four numbers the UI draws instead of the entities behind them.
5. **Redis cache for platform configuration and expensive aggregates**, with invalidation on write rather than a TTL that hides bugs.
6. **Fewer client-side queries on first paint** — server components for the data the page needs at load, hydration for the rest.

## Result

| Metric | Before | After |
|---|---|---|
| p95 API latency on key modules | 850 ms | 320 ms |
| LCP on key Next.js pages | 4.2 s | 2.1 s |

## Trade-offs

Every index is a tax on writes, so the set has to be reviewed as schema, not as a hotfix. Caching configuration means invalidation becomes a correctness problem: a stale cache is invisible until someone changes a setting and nothing happens. Narrow selects couple the API response to a specific screen, which is fine when the endpoint is owned by that screen and painful when three clients share it.

## What I would do differently

Put a latency budget in the endpoint contract and treat a regression above it as a failed review, the same way a failing test is. And start with `pg_stat_statements` on day one — the instinct to guess which query is slow was wrong every single time.
