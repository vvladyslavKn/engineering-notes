-- Double-entry ledger sketch.
-- The file exists to make the invariants explicit before application code:
--   1. every journal entry nets to zero per asset
--   2. no balance change without a posting
--   3. the same external event can never be posted twice
--   4. funds reserved for an open order stay on the balance sheet until released
--   5. amounts are integers in minor units

create table accounts (
    id          bigserial primary key,
    owner_id    bigint references users (id),          -- null for system accounts
    asset       text   not null,                       -- BTC, ETH, USDT, ...
    kind        text   not null check (kind in (
                    'user', 'fee', 'hot_wallet', 'cold_wallet', 'escrow', 'rounding'
                )),
    created_at  timestamptz not null default now(),
    unique (owner_id, asset, kind)
);

create table journal_entries (
    id           bigserial primary key,
    kind         text not null,                        -- deposit, withdrawal, trade, fee, reversal
    external_ref text,                                 -- tx hash + log index, trade id, withdrawal id
    created_at   timestamptz not null default now()
);

-- one posting run per external event, enforced by the database rather than the handler
create unique index journal_entries_external_ref_uniq
    on journal_entries (kind, external_ref)
    where external_ref is not null;

create table postings (
    id         bigserial primary key,
    entry_id   bigint not null references journal_entries (id),
    account_id bigint not null references accounts (id),
    asset      text   not null,
    amount     numeric(38, 0) not null check (amount <> 0),   -- signed, minor units
    created_at timestamptz not null default now()
);

create index postings_account_idx on postings (account_id, id);

-- the journal is the source of truth; this view is what the balance cache is built from
create view account_balances as
select account_id, asset, sum(amount) as balance
from postings
group by account_id, asset;

create table holds (
    id          bigserial primary key,
    account_id  bigint not null references accounts (id),
    asset       text   not null,
    amount      numeric(38, 0) not null check (amount > 0),
    reason      text   not null,                       -- open_order, pending_withdrawal
    ref         text   not null,                       -- order id, withdrawal id
    created_at  timestamptz not null default now(),
    released_at timestamptz
);

-- a retried reservation must not reserve twice
create unique index holds_ref_uniq on holds (reason, ref);

-- what a user can actually spend
create view account_available as
select b.account_id,
       b.asset,
       b.balance,
       coalesce(h.held, 0)          as held,
       b.balance - coalesce(h.held, 0) as available
from account_balances b
left join (
    select account_id, asset, sum(amount) as held
    from holds
    where released_at is null
    group by account_id, asset
) h on h.account_id = b.account_id and h.asset = b.asset;

-- the zero-sum rule is applied inside the transaction that writes the entry:
--   sum(postings.amount) = 0 per asset, checked before commit,
-- or as a deferred constraint trigger if the check must live in the database.
