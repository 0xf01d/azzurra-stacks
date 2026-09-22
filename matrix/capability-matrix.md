# Capability Report — Azzurra production vs solanum-it / atheme-it

**Status: FINAL.** Every cell is evidence-backed. Every former advisory is either
reframed as an options set (O1–O11, multi-path, no pick) or a stated constraint (C1–C2). This report
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
| Cloaking | umode +x (ircd-side) [E7] | ❌ no ircd-side cloak implementation (docs-only mentions) [E4] | ✅ HostServ vHost [E6] | ⚠️ **OPTIONS O4** — paths: HostServ vHost / ircd-side cloak module / hybrid; no pick |
| Registered nick umode +r | yes [E7] | ✅ set via services [E2: registered client] | n/a (sets +r) | none |
| Reg-only join (+R) | ✅ [E7] | ✅ | sets +R | none |
| No-color (+c) | ✅ [E7] | ✅ | n/a (ircd) | none |
| No-CTCP (+C) | ✅ [E7] | ✅ | n/a (ircd) | none |
| Oper-only (+O) | ✅ [E7] | ✅ | n/a (ircd) | none |
| SSL-only (+S umode/+S chmode) | ✅ umode+chmode [E7] | ⚠️ no dedicated TLS-only channel-mode flag in source [E4]; TLS enforcement is listener-level (ssl listen blocks) | n/a (ircd) | ⚠️ **OPTIONS O5** — paths: listener TLS policy / +S mode upstream / services-side gating; no pick |
| Moderated-for-unreg (+M) | ✅ [E7] | ✅ `MODE_REGONLY` registered-only semantics (`include/channel.h:178`, enforced `modules/m_invite.c:174`) [E4] | sets +M | none |
| No-nick-change (+d) | ✅ [E7] | ❌ no mode flag in source [E4] | n/a | ❌ **OPTIONS O9** — paths: accept gap / upstream port / services-side approximation; no pick |
| No-spam (+u) | ✅ [E7] | ❌ no mode flag in source [E4] | n/a | ❌ **OPTIONS O9** — paths: accept gap / upstream port / services-side approximation; no pick |
| Hide banlist (+B) | ✅ [E7] | ⚠️ +b view restricted to ops by default | n/a | ⚠️ **OPTIONS O10** — paths: accept differing semantics / upstream resyntax; no pick |
| Registered-join restrict (+j) | ✅ registered-join [E7] | ⚠️ +j = join throttle [E4] | n/a | ⚠️ **OPTIONS O10** — paths: accept differing semantics / upstream resyntax; no pick |
| Ban exceptions (+e) | ❌ [E7] | ✅ (28 source files) [E4] | n/a | ADDITIVE (forks ahead) |
| INVEX (+I) | ❌ [E7] | ✅ (19 source files) [E4] | n/a | ADDITIVE |
| Extbans ($-syntax) | ❌ (EBMODE token, +z only) [E7] | ✅ (22 source files) [E4] | n/a | ADDITIVE |
| WATCH/MONITOR | WATCH [E7] | ✅ MONITOR (28 source files) [E4] | n/a | ADDITIVE (modern) |
| SILENCE | ✅ [E7] | ✅ | n/a | none |
| DCCALLOW | ✅ (5 files) [E7] | ❌ absent in source [E4] | n/a | ❌ **OPTIONS O9** — paths: accept gap / upstream port / services-side approximation; no pick |
| SHUN | ✅ [E7] | ✅ | n/a | none |
| IRCv3 CAP framework | ❌ [E7] | ✅ message-tags (123 files), server-time, account-notify, extended-join [E4] | n/a | ADDITIVE |
| SeenServ | ✅ built-in [E7] | ❌ | ✅ contrib cs_seen in tree [E6] | ✅ **OPTIONS O7** — paths: contrib load / native service / accept gap; no pick |
| StatServ | ✅ built-in [E7] | ❌ | ✅ statserv native [E6] | ✅ parity achieved |
| RootServ hierarchy | ✅ (SRA list) [E7] | ❌ (opers + services root) | ✅ OperServ + services root [E6] | ⚠️ **OPTIONS O8** — paths: OperServ mapping / dedicated service / oper classes; no pick |
| Nick enforcement | RELEASE + enforcer (300s) [E7] | n/a | ✅ RELEASE/ENFORCER [E6] | none (services-side) |
| Email-verified registration | ✅ (EMAIL:1, sendmail) [E7] | n/a | ✅ configurable [E6] | ✅ **OPTIONS O6** — paths: config-only parity / keep defaults; no pick |
| Nick expiry | 40d [E7] | n/a | ✅ configurable [E6] | ✅ **OPTIONS O6** — paths: config-only parity / keep defaults; no pick |
| Channel expiry | 40d [E7] | n/a | ✅ configurable [E6] | ✅ **OPTIONS O6** — paths: config-only parity / keep defaults; no pick |
| MemoServ | ✅ (21d expiry) [E7] | n/a | ✅ MemoServ [E6] | none |
| SASL authentication | ❌ [E7] | n/a | ✅ saslserv [E6] | ADDITIVE |
| HostServ vHosts | ❌ (+x cloaks only) [E7] | n/a | ✅ hostserv [E6] | ADDITIVE; cloaking paths in O4 |
| BotServ | ❌ [E7] | n/a | ✅ botserv [E6] | ADDITIVE |
| GroupServ teams | ❌ [E7] | n/a | ✅ groupserv [E6] | ADDITIVE |
| ChanFix | ❌ [E7] | n/a | ✅ chanfix [E6] | ADDITIVE |
| GameServ/RPGServ | ❌ [E7] | n/a | ✅ gameserv/rpgserv [E6] | ADDITIVE (optional load) |
| ALIS channel search | ❌ [E7] | n/a | ✅ alis [E6] | ADDITIVE (optional load) |
| Access model | CFOUNDER/SOP/AOP/HOP/AVOICE tiers [E7] | n/a | ✅ XOP + ACL [E6] | none |
| WEBIRC | ✅ [E7] | ✅ (3 source files) [E4] | n/a | none |
| HAProxy ingress | ✅ [E7] | ❌ native PROXY protocol (no handshake handling in source [E4]); ✅ WEBIRC available [E4] | n/a | ⚠️ **OPTIONS O1** — paths: WEBIRC passthrough / native PROXY listener (**M-2**, milestone 0.1.0) / TLS-at-ircd; no pick |
| Flood/clone detection | services-side tiers + clone warn→kill [E7] | ircd throttle [E4] | ✅ services limits [E6] | ⚠️ **OPTIONS O11** — paths: two-layer as-is / azzurra-tier services module / ircd extensions; no pick |

## Options (O1–O11 — formerly Decisions D1–D11)

> The analyst lays out paths; the choice belongs to the operator. Numbering is
> 1:1 with the original D-numbers so existing references (orch's grill verdicts,
> milestone issues) stay traceable. Numbering note: D2/D3 were never issued in
> the original draft (drafting gap), so **O2/O3 are intentionally unused**.
> Per standing direction, every option evaluates **feature parity** (upstream
> implementation in solanum-it/atheme-it, with scope/cost estimate and the
> milestone 0.1.0 link where it applies) alongside the alternatives.

- **O1 — HAProxy ingress.**
  - P-a (current stack behavior): HAProxy TCP passthrough + WEBIRC from the
    edge. Mechanism: no ircd code; edge authenticates via WEBIRC. Tradeoffs:
    zero code; trusts the edge's WEBIRC assertion; TLS may end at HAProxy.
    Cost/risk: low.
  - P-b (**feature parity** — not applicable as code: azzurra pairs HAProxy
    with WEBIRC too; the parity gap here is native PROXY support in solanum-it,
    tracked as **M-2** (issue #7, milestone 0.1.0)): PROXY v2 listener flag in
    solanum-it. Scope: C module + CI probe (HAProxy-fronted smoke). Cost/risk:
    medium; removes the WEBIRC trust hop.
  - P-c: TLS termination at the ircd (HAProxy pure TCP, certs on the ircd).
    Tradeoffs: one less trust hop; cert management moves to the ircd prefix.
    Cost/risk: low-medium (ops).
- **O4 — Cloaking.**
  - P-a (current stack behavior): services-side HostServ vHost. Tradeoffs:
    per-account vHosts, no ircd code; +x-style automatic cloaking is absent.
    Cost/risk: low.
  - P-b (**feature parity**): implement an ircd-side cloak module in
    solanum-it (umode +x with hashed-host suffixes, Bahamut-style). Scope:
    medium C module + mode plumbing + smoke probe. Cost/risk: medium;
    parity implementation tracked as **M-3** (issue #9, milestone 0.1.0).
  - P-c: hybrid — automatic cloak at connect + HostServ override. Tradeoffs:
    closest to azzurra UX; two mechanisms to operate. Cost/risk: medium-high.
- **O5 — TLS-only enforcement.**
  - P-a (current stack behavior): listener-level policy (ssl listen blocks;
    azzurra-style +S not available). Tradeoffs: per-port, not per-channel.
    Cost/risk: low.
  - P-b (**feature parity**): +S channel mode (and/or TLS-only umode) in
    solanum-it. Scope: small mode module (TLS-check chmode), ISUPPORT update,
    smoke probe. Cost/risk: low-medium; parity
    implementation tracked as **M-4** (issue #10, milestone 0.1.0).
  - P-c: services-side gating (channel +R/+M combinations approximating
    SSL-only for registered users). Tradeoffs: approximate; unregistered TLS
    users still join. Cost/risk: low.
- **O6 — Services config parity (expiry + e-mail verification).**
  - P-a (**feature parity** — config-only): deployment config sets NICK/CHAN
    expiry to 40d and enables e-mail-confirmed registration. Scope: config
    values only. Cost/risk: low; no milestone (not upstream code).
  - P-b: keep atheme defaults (shorter expiry, no mail confirmation).
    Tradeoffs: diverges from azzurra behavior users expect. Cost/risk: none.
- **O7 — SeenServ.**
  - P-a (**feature parity** — module load): enable contrib cs_seen in the
    deployment config. Scope: one loadmodule line + channel registration
    defaults. Cost/risk: low; module maturity = contrib tier. No milestone
    (module already exists in the atheme-it tree).
  - P-b: native SeenServ-style service in atheme-it. Scope: high (new
    service module + storage). Cost/risk: high; milestone 0.1.0 if picked.
  - P-c: accept the gap (ALIS + channel logging cover the use case).
    Tradeoffs: user-visible feature loss vs azzurra. Cost/risk: none.
- **O8 — RootServ hierarchy.**
  - P-a (current stack behavior): OperServ + services-root privileges cover
    SRA functions. Tradeoffs: no dedicatedRootServ UX. Cost/risk: none.
  - P-b (**feature parity**): dedicated RootServ-equivalent service in
    atheme-it. Scope: high (new service + command set). Cost/risk: high;
    parity implementation tracked as **M-5** (issue #11, milestone 0.1.0).
  - P-c: fold SRA functions into oper classes + OperServ SA/RA command set.
    Tradeoffs: keeps one service; slightly different command UX. Cost/risk:
    low-medium.
- **O9 — Legacy channel modes (+d / +u) and DCCALLOW.**
  - P-a (current stack behavior): accept the gap (upstream solanum removed
    them deliberately). Tradeoffs: azzurra channels relying on them lose that
    enforcement. Cost/risk: none.
  - P-b (**feature parity**): implement +d / +u / DCCALLOW in solanum-it
    (per-feature). Scope: medium-high each (mode plumbing + enforcement +
    smoke probes). Cost/risk: medium-high; parity
    implementation tracked as **M-6** (issue #12, milestone 0.1.0).
  - P-c: services-side approximations (ChanServ mode-lock for +u-ish policy;
    DCCALLOW replaced by network policy docs). Tradeoffs: partial enforcement.
    Cost/risk: low-medium.
- **O10 — +B / +j semantics.**
  - P-a (current stack behavior): accept solanum semantics (+b view
    ops-restricted; +j join throttle). Tradeoffs: azzurra meanings absent.
    Cost/risk: none.
  - P-b (**feature parity**): resyntax +B/+j in solanum-it to azzurra
    meanings. Scope: medium; diverges from upstream solanum semantics and
    affects documentation/interop. Cost/risk: medium; parity implementation tracked as **M-7**
    (issue #13, milestone 0.1.0).
  - P-c: extban-based approximations ($-extbans registered/joined).
    Tradeoffs: close UX via existing ADDITIVE extban framework. Cost/risk:
    low.
- **O11 — Flood/clone detection.**
  - P-a (current stack behavior): two-layer enforcement (ircd throttles +
    services limits). Tradeoffs: azzurra's warn→globops→kill tiers and clone
    percentage guard absent. Cost/risk: none.
  - P-b (**feature parity**): implement azzurra's tiered flood (TLEV/FLEV)
    and clone-percentage guard in atheme-it. Scope: medium-high (new
    opercommands + thresholds). Cost/risk: medium-high; parity implementation tracked as **M-8**
    (issue #14, milestone 0.1.0).
  - P-c: ircd-side extensions (clone detection / flood alerts in solanum-it
    extensions). Scope: medium. Tradeoffs: splits enforcement across three
    layers. Cost/risk: medium.

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

Genuine upstream implementation gaps — not option sets, not modernizations —
tracked in the
[`0.1.0 — feature parity`](https://github.com/0xf01d/azzurra-stacks/milestone/1)
milestone, each with its upstream repository:

- **M-1 — halfops (+h) in solanum-it.** Azzurra channels rely on HOP tiering;
  solanum-it has no halfop support at all [E4, E5]. Upstream repo:
  `0xf01d/solanum-it`.
- **M-2 — native PROXY-protocol listener in solanum-it** (issue #7). Removes
  the WEBIRC dependency for HAProxy ingress [E4]. Upstream repo:
  `0xf01d/solanum-it`.
- **M-3 — ircd-side cloak module (+x) in solanum-it** (issue #9). O4 parity
  path. Upstream repo: `0xf01d/solanum-it`.
- **M-4 — TLS-only mode (+S) in solanum-it** (issue #10). O5 parity path.
  Upstream repo: `0xf01d/solanum-it`.
- **M-5 — RootServ-equivalent service in atheme-it** (issue #11). O8 parity
  path P-b. Upstream repo: `0xf01d/atheme-it`.
- **M-6 — legacy channel modes (+d/+u) and DCCALLOW in solanum-it** (issue
  #12). O9 parity path P-b. Upstream repo: `0xf01d/solanum-it`.
- **M-7 — azzurra semantics for +B/+j in solanum-it** (issue #13). O10 parity
  path P-b. Upstream repo: `0xf01d/solanum-it`.
- **M-8 — tiered flood + clone-percentage guard in atheme-it** (issue #14).
  O11 parity path P-b. Upstream repo: `0xf01d/atheme-it`.

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
- Options rework: D1-D11 reframed as multi-path options O1-O11 (no
  prescriptive picks; feature parity evaluated in every set) per the
  operator's direction.
