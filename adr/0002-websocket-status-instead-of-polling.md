# 0002 — Push events over a socket instead of polling from the client

## Context

Clients needed to see changes made by other users — messages, notifications, status changes — while the page was open. The first implementation refetched on a timer, which made latency a function of the interval and load a function of the number of open clients.

## Options

1. **Polling on a fixed interval.** Trivial to build, works through any proxy, and debt grows linearly with users. Latency is at best one interval; at worst the interval overlaps a slow response.
2. **Long polling.** Lower average latency, same request volume, plus connection churn that shows up as noise in every load balancer metric.
3. **A persistent connection with server-pushed events.** Latency is a network hop, not an interval; a quiet client costs nothing.

## Decision

Option 3, with the payload kept incremental and the client tracking a cursor. Reconnect resumes from the last seen id rather than reloading state. Non-critical signals (typing, presence) are coalesced and rate-limited so they cannot delay a message.

## Consequences

- Latency dropped from about 3 s to under 1 s without touching the database.
- Server and client both need connection state machines: backoff, resume, duplicate suppression. This is the real cost of the decision and it belongs in the API contract, not in a client library.
- Horizontal scaling requires that a connection on one node can be reached by an event produced on another — a fan-out layer becomes part of the system.
- Polling is still the right answer for low-frequency administrative screens; the decision applies where latency is user-visible.
