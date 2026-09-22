# old-stack CI

The **legacy Azzurra stack** as a runnable, verifiable pipeline: three linked
`azzurra/bahamut` ircd (1.4.34 perimeter, `-azzurra(4.8)`) plus one
`azzurra/services` (Epona/SirvNET-derived; NickServ/ChanServ/MemoServ/HelpServ/
OperServ/RootServ/StatServ/SeenServ), composed as **3 ircd + 1 services** —
hub + leaf-v4 + leaf-v6 + services on three bridge networks.

Vendored near-verbatim from [vjt/azzurra-testnet](https://github.com/vjt/azzurra-testnet)
(upstream topology is already exactly 3+1); the deep verification script is
new — the upstream smoke is deliberately shallow and defers these checks to CI.

## Layout

- `compose.yaml` — the topology; builds bahamut/services from source at
  **pinned upstream master commits** (`BAHAMUT_REF` / `SERVICES_REF` overridable).
- `compose.ghcr.yaml` — override swapping `build:` for the prebuilt GHCR
  images. **The packages are private**: anonymous pull is rejected, so this
  override needs `docker login ghcr.io` with package access. CI does not use
  it.
- `bahamut/`, `services/`, `certs/` — build contexts, config templates,
  role-aware entrypoints, throwaway cert generation.
- `scripts/verify.sh` — the assertions (see below).

The config templates carry the hard-won wiring notes in their comments (bare-IP
C/N host fields, per-leaf U: lines, autoconnect class connfreq, cloak key
sharing) — read them before changing anything.

## Run locally

```sh
cd old-stack
docker compose -f compose.yaml up -d --build --wait   # ~5 min source build
scripts/verify.sh
```

## What CI verifies (`.github/workflows/old-stack.yml`)

1. **ChanServ round-trip** — a PRIVMSG to ChanServ comes back as a NOTICE:
   client → hub → services link → pseudo-client → back. The data path lives.
2. **/map shows hub + leaf4 + leaf6** (as oper) — the three ircd are really
   linked, not a hub talking to itself.
3. **Cross-leaf whois** — a user on leaf-v4 is visible from a hub client:
   S2S carries users.
4. **NickServ REGISTER + IDENTIFY lands `+r`** (RPL_WHOISREGNICK 307) on a
   leaf user — services → SVSMODE → leaf U:line, the privileged path that
   silently breaks when a leaf misses its U: line.

Any failed assertion dumps `compose ps` + the last 160 log lines per server
before exiting non-zero.
