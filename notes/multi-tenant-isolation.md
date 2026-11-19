# 03 — Multi-tenant isolation in a shared schema

## Context

EveryPig serves many farms on one platform: shared tables, shared deployment, per-tenant configuration and branding. Clients are businesses, and a cross-tenant read is a business-ending bug, not a cosmetic one.

## The problem

The dangerous version of multi-tenancy is the one where isolation is a convention. A query that forgets a tenant filter returns another client's rows, and nothing in the system says so — the API simply answers with data it should not have. Add per-tenant settings and role-based access on top, and the filter has to be applied in every handler written by an 18-person team.

## What changed

1. **`tenant_id` on every tenant-owned table**, and part of every unique constraint. A tenant-scoped uniqueness rule that lives only in application code is a race condition waiting for two requests.
2. **Data access through a scoped layer.** Handlers do not call models directly; they call repository functions that require a tenant context and fail closed when it is missing. The filter is in one place instead of in a hundred.
3. **Authorization at the boundary.** Membership and role are checked before the scope is applied, so an authenticated user cannot widen their own scope by changing an id in a URL.
4. **Per-tenant settings and branding in a separate table**, read through a cached config object, so a settings read is not a join on every request.
5. **Tests that assert the negative case.** A cross-tenant read must return 404, not 403 — a 403 confirms the row exists, which is a leak on its own.

## Result

Tenant isolation stopped depending on reviewer attention: the scoped layer turns a missing filter into a runtime error instead of a silent data leak, and the negative-path tests made the boundary explicit for every new endpoint.

## Trade-offs

Shared schema is cheap to operate and migrate, but enforcement lives in code, so the code has to be the enforcement point — which is a discipline the team pays for. Postgres row-level security moves enforcement into the database and is the stronger option, at the cost of every connection having to set its tenant context correctly and a more awkward debugging story.

## What I would do differently

Row-level security from the start on tables holding client data. Application-level scoping works when everyone follows it; the database never forgets.
