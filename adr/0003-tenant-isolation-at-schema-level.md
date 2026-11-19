# 0003 — Tenant isolation in a shared schema

## Context

Many client businesses run on one deployment. Their data must not mix, their settings differ, and the team writing endpoints is larger than the number of people who will remember the rule.

## Options

1. **Shared tables with a `tenant_id` column**, filtered in application code.
2. **Shared database, schema per tenant.**
3. **Separate database or deployment per tenant.**
4. **Shared tables plus Postgres row-level security**, so the database applies the filter.

## Decision

Option 1 with the filter enforced by a scoped data-access layer, and `tenant_id` included in every unique constraint. Option 4 is the stronger version of the same idea and would be the choice for a system holding regulated or financial data.

Options 2 and 3 were rejected because migrations across a hundred schemas or deployments is a full-time job at this size, and the isolation gain does not pay for it.

## Consequences

- Isolation depends on code discipline, so the enforcement point has to be one layer that fails closed, and the negative path needs tests — a cross-tenant read must return 404, never 403.
- Per-tenant configuration and branding live in their own table, cached, so isolation does not cost a join on every request.
- Migration to row-level security later is possible but not free: it changes how connections are opened and how debugging works.
