-- Draft DDL: double-entry ledger sketch.
-- Goal: make the accounting invariants explicit before writing application code.
-- Not production code.

-- TODO accounts: user and system accounts (fees, hot wallet, cold wallet, rounding)
-- TODO journal_entries: append-only, one row per transaction, never updated
-- TODO postings: signed amounts per account; every entry nets to zero per asset
-- TODO holds: reserved funds for open orders, released by compensating postings
-- TODO idempotency: unique key on (source, external_id) so retries cannot double-post
-- TODO constraints: no negative available balance, integer minor units only
