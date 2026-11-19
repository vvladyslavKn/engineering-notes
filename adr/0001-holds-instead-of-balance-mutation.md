# 0001 — Holds instead of mutating balances

## Context

Users place orders and request withdrawals while other operations are in flight against the same balance. Debiting the balance at request time is the obvious implementation and the source of most of the bugs: a failed settlement leaves funds in limbo, a cancelled order needs a compensating credit, and two concurrent requests can both pass a balance check.

## Options

1. **Debit on request, credit back on failure or cancel.** Simple to read, but every failure path has to remember to give the money back, and any missed path is a silent loss for the user.
2. **Leave the balance untouched, reserve funds as a separate hold.** The balance only changes on settlement. `available = balance - open holds`.
3. **Single mutable `available` column** updated by every operation. Cheapest to write, impossible to audit.

## Decision

Option 2. Holds are rows with an amount, a reason and a reference to the thing reserving the funds (order id, withdrawal id), with a unique key on that reference so a retried request cannot reserve twice. Release is a state change on the hold, not a posting.

## Consequences

- Balance checks read `available`, which is a query over holds — acceptable because holds per account are small and the number is cached.
- Cancelling an order is cheap and cannot fail halfway: nothing was moved.
- Reconciliation is simpler: a real balance change only happens on settlement, so the set of events that touch money is small and enumerable.
- The cost is conceptual: two numbers (`balance`, `available`) instead of one, and every consumer has to know which one it needs.
