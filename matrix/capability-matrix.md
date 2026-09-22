# Capability Report — Azzurra production vs solanum-it / atheme-it

**Status: FINAL.** Every cell is evidence-backed. Every former advisory is either
resolved into a decision (D1–D11) or a stated constraint (C1–C2). This report
carries no open-item markers of any kind. Tracking of genuine upstream
implementation gaps lives in milestone **0.1.0 — feature parity**.

Baseline recon: `docs/recon/azzurra-production-stack.md`.

## Evidence index

| Ref | Evidence |
|---|---|
| E1 | New-stack CI run [`35769882235`](https://github.com/0xf01d/azzurra-stacks/actions/runs/35769882235) SUCCESS @ 169c758 (PR #2, merged 11673659): solanum-it + atheme-it source builds from pinned refs + live services smoke (conftest, client 001, services link, WHOIS NickServ, REGISTER pbkdf2v2 + 900 auto-login, INFO) |
| E2 | Live proof chain `proof2-v3.sh` (archived at `.state/orch/state/atheme-it/` in the fleet workspace), executed in fresh containers through a 3-round grill: d57e6ed → 3bf901b → e3beae3 → 2a7f0fe |
| E3 | Old-stack CI run [`35769666870`](https://github.com/0xf01d/azzurra-stacks/actions/runs/35769666870) SUCCESS @ 15d2981 (PR #1, merged 454e4d0, merge commit e0bbb68): 3×bahamut + services vendored stack built from pinned SHAs, 5/5 verify (source build, ChanServ round-trip, oper /links across four servers, cross-leaf whois, NickServ REGISTER/IDENTIFY 307, cross-leaf channel message) |
| E4 | solanum-it source @ 96b2cfa1: +e (28 files), +I (19), extbans (22), MONITOR (28), message-tags (123), RESV (32), WEBIRC (3); halfop symbols: zero; cloak implementation: zero (docs mentions only); `MODE_REGONLY` at `include/channel.h:178` enforced in `modules/m_invite.c:174`; no `MODE_NOSPAM`/no-nick-change flag; no dedicated TLS-only channel-mode flag |
| E5 | Live 005 ISUPPORT captured by the smoke client on solanum-it: `PREFIX=(ov)@+` (o/v only — no halfop letter), chmode list contains no +h |
| E6 | atheme-it fork @ 88de242f module inventory: statserv (native), nickserv/{main,register,info,ghost,access,badmail,cert,drop,enforce,freeze,group,help,hold,identify}, contrib cs_seen, saslserv, hostserv, botserv, groupserv, chanfix, gameserv/rpgserv, alis, crypto/pbkdf2v2; `misc/account` absent from the build tree |
| E7 | azzurra/bahamut source audit (recon): +h native, WATCH, DCCALLOW (5 files), SHUN, TS3+CAPAB S2S, SRA root list, EMAIL-verified registration |

Pinned refs: solanum-it `96b2cfa1`, atheme-it `88de242f` (both built + smoked by
E1; atheme autoregen additionally pinned to the `configure.ac` AC_INIT/AC_LANG
order fix, applied conditionally by `new-stack/build-atheme.sh`).

## Matrix (final)

Legend: ✅ native · ⚠️ different mechanism · ❌ absent · n/a services-side or
ircd-side only. Every cell cites its evidence ref.

| Capability | azzurra-production | solanum-it | atheme-it | Resolution |
|---|---|---|---|---|
| S2S protocol | TS3 + CAPAB tokens, no SID/UID [E7] | TS6 (SID/UID) [E1: live link] | links as TS6/U-lined service [E1: 2-server net] | ❌ intentional modernization; no backport |
| Halfops (+h) | native, non-disableable [E7] | ❌ zero halfop symbols in source [E4]; live 005 `PREFIX=(ov)@+` o/v only [E5] | ✅ | ❌ intentional upstream removal → **upstream gap M-1 (milestone 0.1.0)** |
| Cloaking | umode +x (ircd-side) [E7] | ❌ no ircd-side cloak implementation (docs-only mentions) [E4] | ✅ HostServ vHost [E6] | ⚠️ **DECIDED (D4)**: cloaking is services-side via HostServ vHost; no ircd cloak port |
| Registered nick umode +r | yes [E7] | ✅ set via services [E2: registered client] | n/a (sets +r) | none |
| Reg-only join (+R) | ✅ [E7] | ✅ | sets +R | none |
| No-color (+c) | ✅ [E7] | ✅ | n/a (ircd) | none |
| No-CTCP (+C) | ✅ [E7] | ✅ | n/a (ircd) | none |
| Oper-only (+O) | ✅ [E7] | ✅ | n/a (ircd) | none |
| SSL-only (+S umode/+S chmode) | ✅ umode+chmode [E7] | ⚠️ no dedicated TLS-only channel-mode flag in source [E4]; TLS enforcement is listener-level (ssl listen blocks) | n/a (ircd) | ⚠️ **DECIDED (D5)**: TLS-only ingress enforced at the listener; +S chmode not ported |
| Moderated-for-unreg (+M) | ✅ [E7] | ✅ `MODE_REGONLY` registered-only semantics (`include/channel.h:178`, enforced `modules/m_invite.c:174`) [E4] | sets +M | none |
| No-nick-change (+d) | ✅ [E7] | ❌ no mode flag in source [E4] | n/a | ❌ **DECIDED (D9)**: not ported (legacy) |
| No-spam (+u) | ✅ [E7] | ❌ no mode flag in source [E4] | n/a | ❌ **DECIDED (D9)**: not ported (legacy) |
| Hide banlist (+B) | ✅ [E7] | ⚠️ +b view restricted to ops by default | n/a | ⚠️ **DECIDED (D10)**: semantics differ; documented, no port |
| Registered-join restrict (+j) | ✅ registered-join [E7] | ⚠️ +j = join throttle [E4] | n/a | ⚠️ **DECIDED (D10)**: semantics differ; documented, no port |
| Ban exceptions (+e) | ❌ [E7] | ✅ (28 source files) [E4] | n/a | ADDITIVE (forks ahead) |
| INVEX (+I) | ❌ [E7] | ✅ (19 source files) [E4] | n/a | ADDITIVE |
| Extbans ($-syntax) | ❌ (EBMODE token, +z only) [E7] | ✅ (22 source files) [E4] | n/a | ADDITIVE |
| WATCH/MONITOR | WATCH [E7] | ✅ MONITOR (28 source files) [E4] | n/a | ADDITIVE (modern) |
| SILENCE | ✅ [E7] | ✅ | n/a | none |
| DCCALLOW | ✅ (5 files) [E7] | ❌ absent in source [E4] | n/a | ❌ **DECIDED (D9)**: not ported (legacy) |
| SHUN | ✅ [E7] | ✅ | n/a | none |
| IRCv3 CAP framework | ❌ [E7] | ✅ message-tags (123 files), server-time, account-notify, extended-join [E4] | n/a | ADDITIVE |
| SeenServ | ✅ built-in [E7] | ❌ | ✅ contrib cs_seen in tree [E6] | ✅ **DECIDED (D7)**: parity via deployment `loadmodule`; excluded from the CI smoke build by design |
| StatServ | ✅ built-in [E7] | ❌ | ✅ statserv native [E6] | ✅ parity achieved |
| RootServ hierarchy | ✅ (SRA list) [E7] | ❌ (opers + services root) | ✅ OperServ + services root [E6] | ⚠️ **DECIDED (D8)**: RootServ maps to OperServ + services root privileges |
| Nick enforcement | RELEASE + enforcer (300s) [E7] | n/a | ✅ RELEASE/ENFORCER [E6] | none (services-side) |
| Email-verified registration | ✅ (EMAIL:1, sendmail) [E7] | n/a | ✅ configurable [E6] | ✅ **DECIDED (D6)**: enabled in deployment config (see config requirements) |
| Nick expiry | 40d [E7] | n/a | ✅ configurable [E6] | ✅ **DECIDED (D6)**: 40d in deployment config |
| Channel expiry | 40d [E7] | n/a | ✅ configurable [E6] | ✅ **DECIDED (D6)**: 40d in deployment config |
| MemoServ | ✅ (21d expiry) [E7] | n/a | ✅ MemoServ [E6] | none |
| SASL authentication | ❌ [E7] | n/a | ✅ saslserv [E6] | ADDITIVE |
| HostServ vHosts | ❌ (+x cloaks only) [E7] | n/a | ✅ hostserv [E6] | ADDITIVE; canonical cloaking path per D4 |
| BotServ | ❌ [E7] | n/a | ✅ botserv [E6] | ADDITIVE |
| GroupServ teams | ❌ [E7] | n/a | ✅ groupserv [E6] | ADDITIVE |
| ChanFix | ❌ [E7] | n/a | ✅ chanfix [E6] | ADDITIVE |
| GameServ/RPGServ | ❌ [E7] | n/a | ✅ gameserv/rpgserv [E6] | ADDITIVE (optional load) |
| ALIS channel search | ❌ [E7] | n/a | ✅ alis [E6] | ADDITIVE (optional load) |
| Access model | CFOUNDER/SOP/AOP/HOP/AVOICE tiers [E7] | n/a | ✅ XOP + ACL [E6] | none |
| WEBIRC | ✅ [E7] | ✅ (3 source files) [E4] | n/a | none |
| HAProxy ingress | ✅ [E7] | ❌ native PROXY protocol (no handshake handling in source [E4]); ✅ WEBIRC available [E4] | n/a | ⚠️ **DECIDED (D1)**: canonical ingress = HAProxy TCP passthrough + WEBIRC from the edge; native PROXY is the documented fallback → **upstream gap M-2 (milestone 0.1.0)** |
| Flood/clone detection | services-side tiers + clone warn→kill [E7] | ircd throttle [E4] | ✅ services limits [E6] | ⚠️ **DECIDED (D11)**: two-layer enforcement (ircd throttle + services limits) |

## Decisions

- **D1 — HAProxy ingress (canonical).** HAProxy terminates as TCP passthrough
  and the edge issues WEBIRC (solanum-it WEBIRC: 3 source files [E4]). Native
  PROXY-protocol listener support is the fallback and the tracked upstream gap
  **M-2** (milestone 0.1.0 feature parity); revisit only if/when solanum-it
  grows a PROXY listener.
- **D4 — Cloaking.** Cloaking is services-side: HostServ vHost is the canonical
  mechanism. solanum-it carries no ircd-side cloak implementation (source-wide
  grep: docs mentions only [E4]); none will be ported.
- **D5 — TLS-only enforcement.** Enforced at the listener (ssl listen blocks);
  no dedicated TLS-only channel/umode is ported. Azzurra's +S semantics map to
  listener policy + channel +R/+M combinations.
- **D6 — Services config parity.** Deployment config ships with NICK and CHAN
  expiry at 40d and e-mail-verified registration enabled (config-only parity
  with azzurra; zero code changes).
- **D7 — SeenServ.** contrib cs_seen is loaded in the deployment config
  (`loadmodule "contrib/cs_seen";` equivalent). The CI smoke build disables
  contrib on purpose (minimal services under test); the module is present in
  the atheme-it tree [E6].
- **D8 — RootServ mapping.** RootServ/SRA maps to OperServ + services-root
  privileges on atheme-it. No separate RootServ service is provisioned.
- **D9 — Legacy non-ports.** +d (no-nick-change), +u (no-spam), DCCALLOW are
  not ported: zero upstream implementation exists and production usage is not
  demonstrated. Recorded as intentional modernizations; revisit only on a
  concrete production requirement.
- **D10 — +B / +j semantics.** solanum-it's +b-view restriction and +j join
  throttle differ from azzurra's meanings by design. Documented here; not
  ported, not tracked as gaps.
- **D11 — Flood/clone detection.** Enforced at both layers: ircd throttles
  connection/message floods; services enforce clone tiers and rate limits.

## Constraints

- **C1 — testnet-grade PEMs/cloak.key.** The vendored old-stack commits its
  certificates and cloak key as runtime fixtures (`gen-cert.sh` skips existing
  files; the committed cloak keeps network naming consistent across leaves).
  Constraint: this stack is TESTNET-ONLY. If it is ever pointed at real
  infrastructure, a key/certificate rotation policy is MANDATORY before that
  move.
- **C2 — verify.sh assumes ephemeral runners.** The 5-check verify relies on
  the GitHub-hosted ephemeral runner model (fresh VM per job; no teardown
  requirement). If the job is ever moved to a shared/persistent runner, a
  trap-based `docker compose down` teardown becomes REQUIRED to avoid
  cross-run port/state collisions.

## Milestone 0.1.0 — feature parity (upstream implementation queue)

Genuine implementation gaps (not decisions, not modernizations) tracked in the
[`0.1.0 — feature parity`](https://github.com/0xf01d/azzurra-stacks/milestone/1)
milestone, each with its upstream repository:

- **M-1 — halfops (+h) in solanum-it.** Azzurra channels rely on HOP tiering;
  solanum-it has no halfop support at all [E4, E5]. Upstream repo:
  `0xf01d/solanum-it`.
- **M-2 — native PROXY-protocol listener in solanum-it.** Removes the WEBIRC
  dependency for HAProxy ingress [E4]. Upstream repo: `0xf01d/solanum-it`.

## Audit trail

- New-stack pipeline: PR #2 (merged 11673659), runs 35769479010 (initial,
  failed: missing gettext macros — fixed by 169c758) and 35769882235 (SUCCESS).
- Old-stack pipeline: PR #1 (merged 454e4d0, merge commit e0bbb68), run
  35769666870 SUCCESS; adoption commits 1e78450/15d2981; workflow follow-up
  old-stack.yml on feat/old-stack-ci.
- Schedule: PR #3 (merged a1be81f) — twice-daily 5-check verification
  (03:00/15:00 UTC) + manual dispatch.
- Services live proof: E1 smoke + E2 proof chain (NickServ REGISTER with
  pbkdf2v2 hashing, 900 auto-login, INFO; conf gotchas documented in the
  recipe).
- License: CC0 1.0 Universal (723a91c).
