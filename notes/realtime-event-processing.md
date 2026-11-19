# 01 — Chat sync from 3 s to under 1 s

## Context

Hive is a US project and work management platform. Web, iOS and Android clients on top of a Node.js backend, with chat, notifications and time tracking inside the same product. Team of 17 engineers, 7 QA.

## The problem

Three numbers described the experience: a message took about 3 s to appear on another device, server-side event processing took 1.8 s per burst, and time-tracking operations took 2.5 s.

Nothing was broken on its own. The write path did auth, validation, persistence and notification in one go, and the read path refetched the conversation on a timer. Every new message multiplied the work: full history payloads, repeated auth, and a client that could not tell which messages it had already seen, so it re-rendered everything it received.

## What changed

1. **Delivery became event-driven.** The server publishes an event per conversation and connected clients receive it. No polling of history, no timer that guesses how often a change can happen.
2. **Payloads became incremental.** A message event carries an id, a cursor, author, body and timestamp. One new message costs one row of work instead of paging through history.
3. **Server-side processing became batchable.** Validation and persistence for a burst of messages happen in one transaction, and fan-out happens after commit, so a slow recipient cannot hold a write open.
4. **Non-critical signals left the critical path.** Typing indicators and presence updates are coalesced and rate-limited, so they can never queue ahead of a message.
5. **Clients got a resume cursor.** After a reconnect a client asks for everything after the last seen id instead of reloading the conversation, which removed the reconnect storm that follows any deployment.

## Result

| Metric | Before | After |
|---|---|---|
| Chat sync delay across iOS, web and backend | 3 s | under 1 s |
| Server-side chat event processing | 1.8 s | 700 ms |
| Time-tracking operations | 2.5 s | 900 ms |

## Trade-offs

Ordering and reconnect logic move into the client. Fan-out after commit means a dropped subscriber can see an older state until it resumes from its cursor, so every consumer needs to be idempotent and able to re-sync. Rate-limited presence gives up exactness for cheapness, which is the right trade for a typing indicator and the wrong one for a message.

## What I would do differently

Instrument end-to-end lag from the moment a user hits send, not from the moment the server starts handling the request. We spent time optimising a number that was already acceptable while the number users felt was the client render. I would also write the ordering guarantees into the API contract on day one instead of discovering them during load testing.
