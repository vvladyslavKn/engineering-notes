# 04 — Ledger design: balances as a projection, holds instead of mutations

## Context

Most products keep money in a column: `users.balance`. It works until the day two requests touch it at once, a payment provider retries a webhook, or someone asks why the number changed. A ledger is the answer to that question — not a nicer schema, but a rule about how the number is allowed to exist.

## The problem

A mutable balance has three failure modes:

- **Lost updates.** Read, modify, write in two concurrent requests, and one of them disappears unless every path takes the same lock.
- **No audit.** The current value is known, the history is not. Reconciliation becomes a daily argument with the provider.
- **Retries create money.** A webhook delivered twice credits twice, and there is nothing in the schema that says it must not.

## Design

**Append-only journal.** Two tables: `journal_entries` (one row per transaction, with a kind and an external reference) and `postings` (signed amounts per account). Nothing is ever updated or deleted. A correction is a new entry that reverses the old one, which is what an accountant does and what an auditor expects.

**Balances are a projection.** A balance is `sum(postings.amount)` for an account, materialised into a cache or snapshot table for reads. If the cache and the journal disagree, the journal is right — the cache can be rebuilt from scratch. That single property is what makes recovery boring.

**Every entry nets to zero per asset.** Debits and credits are the same number with opposite signs. A deposit is not "increase the user's balance"; it is "move value from the hot wallet account to the user's account", and the sum is zero. This is the invariant that catches whole classes of bugs before a user does.

**Holds instead of mutations.** An open order or a pending withdrawal does not change the balance. It creates a hold, and `available = balance - open holds`. Funds never leave the account until the trade settles or the withdrawal is signed, and a cancelled order releases a hold instead of writing a compensating credit. Most concurrency bugs in exchange-like systems exist because funds were moved too early.

**Idempotency at the boundary.** The unique key is on the source event, not on the request: `(kind, external_ref)` for journal entries, where the reference is a chain transaction hash plus log index, a trade id, or a withdrawal id. Retries are then a database problem rather than an application problem — the second attempt inserts nothing and the handler returns the existing entry. At-least-once delivery plus a unique key is effectively once.

**Settlement in one transaction.** A trade posts all legs plus the fee entries inside a single serializable transaction, keyed by the trade id. Partial settlement is not a state the system can be in, and the reader never sees a half-posted trade.

## Invariants

1. Every journal entry nets to zero per asset.
2. No balance changes without a posting.
3. The same external event can never be posted twice.
4. Held funds remain on the balance sheet until released.
5. Amounts are integers in minor units — never floats, never a JavaScript number.

## Open questions

- Per-trade posting versus batched settlement: batching is cheaper on writes and makes per-user history less immediate.
- Reconciliation cadence against chain state: hourly is affordable, but confirmation policy per chain decides how much of that is noise.
- Whether holds belong in the same table as postings or stay separate; separate is cleaner to reason about, joined views are cheaper to read.
