-- Double-entry ledger sketch.
-- The point of the file is to make the accounting invariants explicit before application code.

-- accounts: user and system accounts (fees, hot wallet, cold wallet, rounding)
-- journal_entries: append-only, one row per transaction, never updated
-- postings: signed amounts per account; every entry nets to zero per asset
-- holds: reserved funds for open orders, released by compensating postings
-- idempotency: unique key on (source, external_id) so retries cannot double-post
-- constraints: no negative available balance, integer minor units only
