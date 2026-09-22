# Capability Matrix — Azzurra production vs solanum-it / atheme-it

Baseline recon: `docs/recon/azzurra-production-stack.md`. Sources: azzurra/bahamut
headers+source (per recon), solanum upstream documentation (solanum 1.x line, which
solanum-it forks), atheme upstream docs (atheme-it forks atheme 7.x line).

Legend: ✅ native · ⚠️ partial/different mechanism · ❌ absent · ❓ pending verification
against the -it forks (filled as the CI stacks come online).

| Capability | azzurra-production | solanum-it | atheme-it | Parity gap / action |
|---|---|---|---|---|
| S2S protocol | TS3 + CAPAB tokens, no SID/UID | TS6 (SID/UID) | links as TS6/U-lined service | ❌ intentional: modern protocol; no backport |
| Halfops (+h) | native, non-disableable | ❓ (no halfop symbols in -it includes — verify +h at runtime; likely present under different naming) | ✅ | runtime-verify |
| Cloaking | umode +x (ircd-side) | ⚠️ via services/IP-less host (verify -it cloak module) | HostServ vHost | decide: umode cloak parity or HostServ-only |
| Registered nick umode +r | yes | ✅ (+r via services) | n/a (sets +r) | none |
| Reg-only join (+R) | ✅ | ✅ | sets +R | none |
| No-color (+c) | ✅ | ✅ | n/a (ircd) | none |
| No-CTCP (+C) | ✅ | ✅ | n/a (ircd) | none |
| Oper-only (+O) | ✅ | ✅ | n/a (ircd) | none |
| SSL-only (+S umode/+S chmode) | ✅ umode+chmode | ⚠️ TLS modes differ (verify -it) | n/a | map TLS-only enforcement |
| Moderated-for-unreg (+M) | ✅ | ⚠️ (verify -it: +M registered-only) | sets +M | verify |
| No-nick-change (+d) | ✅ | ❌ upstream solanum dropped +d | n/a | evaluate: rarely used |
| No-spam (+u) | ✅ | ❌ (verify -it) | n/a | evaluate |
| Hide banlist (+B) | ✅ | ⚠️ solanum: +b view restricted to ops by default | n/a | parity likely achieved differently |
| Registered-join restrict (+j) | ✅ | ⚠️ solanum +j = join throttle (different meaning) | n/a | semantics differ — document, don't port |
| Ban exceptions (+e) | ❌ | ✅ (verified: 28 source files) | n/a | ADDITIVE (forks ahead) |
| INVEX (+I) | ❌ | ✅ (verified: 19 source files) | n/a | ADDITIVE |
| Extbans ($-syntax) | ❌ (EBMODE token, +z only) | ✅ (verified: 22 source files) | n/a | ADDITIVE |
| WATCH/MONITOR | WATCH | ✅ MONITOR (verified: 28 source files) | n/a | ADDITIVE (modern) |
| SILENCE | ✅ (10) | ✅ | n/a | none |
| DCCALLOW | ✅ (5) | ❌ (verified absent in -it source) | n/a | evaluate: legacy feature |
| SHUN | ✅ | ✅ | n/a | none |
| IRCv3 CAP framework | ❌ | ✅ (verified: message-tags 123 files, server-time, account-notify, extended-join) | n/a | ADDITIVE |
| SeenServ | ✅ built-in | ❌ | ⚠️ module (cs_seen) | parity via atheme module |
| StatServ | ✅ built-in | ❌ | ⚠️ stats module | parity via atheme module |
| RootServ hierarchy | ✅ (SRA list) | ❌ (opers + services root) | OperServ/SRA equivalent | document mapping |
| Nick enforcement | RELEASE + enforcer (300s) | n/a | ✅ RELEASE/ENFORCER | none (services-side) |
| Email-verified registration | ✅ (EMAIL:1, sendmail) | n/a | ✅ configurable | none |
| Nick expiry | 40d | n/a | ✅ configurable (NICK expire) | match 40d in config |
| Channel expiry | 40d | n/a | ✅ configurable (CHAN expire) | match 40d in config |
| MemoServ | ✅ (21d expiry) | n/a | ✅ MemoServ | none |
| Access model | CFOUNDER/SOP/AOP/HOP/AVOICE xN tiers | n/a | ✅ XOP + ACL | none |
| WEBIRC | ✅ | ✅ (verified: 3 source files) | n/a | none |
| HAProxy ingress | ✅ | ❓ (no PROXY-protocol hits in -it source; verify at runtime) | n/a | verify at runtime |
| Flood/clone detection | services-side tiers + clone warn→kill | ircd throttle | ✅ services limits | split across layers |

## Parity work queue (additive only — zero solanum features removed)

1. ✅ CI: dual stacks green (this repo).
2. Verify -it cells marked ❓ against the running CI stacks; update this matrix.
3. atheme-it config: NICK/CHAN expiry to 40d, EMAIL-verified registration — config-only parity.
4. Cloak parity decision: umode +x equivalent vs HostServ vHost.
5. SeenServ/StatServ parity via atheme modules (module load, config).
6. DCCALLOW / +d / +u: legacy evaluation — port only if production usage justifies.
7. Document intentional modernizations (+e/+I/extbans/MONITOR/IRCv3) as superset features.
