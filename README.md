# Engineering notes

Short write-ups of backend problems I have worked on, the trade-offs behind the solutions, and the schema sketches that came out of them.

## Notes

| # | Note | Topic |
|---|---|---|
| 01 | [Real-time event processing](notes/realtime-event-processing.md) | WebSocket delivery, fan-out, reconnect |
| 02 | [Postgres performance](notes/postgres-performance.md) | indexes, query shape, caching |
| 03 | [Multi-tenant isolation](notes/multi-tenant-isolation.md) | schema boundaries, access rules |
| 04 | [Ledger and holds](notes/ledger-and-holds.md) | double-entry, balances as projection |

## Decision records

Short ADRs for the calls that shaped these systems: [adr/](adr/README.md)

## Schema sketches

- [schema/ledger.sql](schema/ledger.sql) — double-entry journal with holds and idempotency keys (draft DDL, not production code)

---

LinkedIn: [vladyslavvknysh](https://www.linkedin.com/in/vladyslavvknysh/) · knyshvladyslav1@gmail.com
