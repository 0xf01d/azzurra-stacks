# AzzurraNet Production Stack — Technical Recon

> Recon for the azzurra-stacks mission. Sources cited inline; [INFERENCE] marks uncertainty.
> Scope: technicalities only — no PII, no channel names, no user data.

## 1. IRCD
- **Flavor**: `azzurra/bahamut` — "Azzurra's fork of Bahamut 1.4.34 (legacy ircd)", self-described "Azzurra Bahamut 1.4.6a" (README), (c) 2001–2005 Azzurra IRC Network, original coding by vjt and INT24, based on DALnet Bahamut. https://github.com/azzurra/bahamut
- **Exact version** (`include/patchlevel.h`): MAJOR 1 / MINOR 4 / PATCH 34, `BRANCH "perimeter"`, optional suffixes `-inet6(1.0a)`, `-azzurra(4.8)` (Azzurra patchlevel), `-ssl(1.1)`, `-webirc(1.2)`. https://raw.githubusercontent.com/azzurra/bahamut/master/include/patchlevel.h
- **Lineage**: DALnet Bahamut → 1.4 branch (pre-2.x; Bahamut itself descended from DreamForge/df-hybrid via DALnet). Upstream modern Bahamut 2.2.x is a different line: https://github.com/DALnet/Bahamut, https://www.dal.net/?page=Bahamut

### User modes (include/struct.h)
Standard: +i invis, +o oper, +O locop, +w wallops, +s server notices, +r registered nick, +a services admin, +A server admin, +h helper. Oper notice splits: +c conn/exits, +k kills, +f flood, +y stats/links, +d debug, +g globops, +b chatops, +n routing, +m spambot, +e dccallow-ops, +K U:line kills. Azzurra additions: **+x host cloaking**, **+z services agent**, +S SSL user, +I hide idle, +R no non-registered msgs, +D/E dccallow, +F no msg-rate throttle.

### Channel modes (src/channel.c mode tables)
Base: +n +t +m +i +p +s +l (limit) +k (KEYLEN 23) +b (MAXBANS 100), **+h halfop** ("can't be disabled anymore"), +v/o. Azzurra/1.4 additions: **+r registered (services-only set)**, **+R reg-only join**, **+c no-color**, **+C no-CTCP**, **+O oper-only**, **+M moderated-for-unregistered**, **+d no-nick-change**, **+u no-spam**, **+S SSL-only**, **+j allow only registered users**, **+U allow restricted users**, **+z restrict join to registered nick / ban-view control**, **+B hide banlist** (CAP_EBMODE token = "extended ban modes (+z) and banlist hiding (+B)"). Limits: TOPICLEN 307, CHANNELLEN 32, NICKLEN 30. WATCH, SILENCE (10), DCCALLOW (5) present. IPv6, SSL, RC4-encrypted links, zipped links, SHUN, WEBIRC, HAProxy ingress, 6to4/Teredo detection in flags2.

### S2S CAPAB tokens (struct.h)
`TS3, NOQUIT, NSJOIN (smart sjoin), BURST, UNCONNECT, DKEY (DH key exchange), ZIP, NICKIP, TSMODE, EBMODE`; PASS ending in "TS" + SVINFO handshake (doc/README.TSora), SOB/EOB end-of-burst, SVSNICK.

### ISUPPORT / IRCv3
No IRCv3 CAP framework [INFERENCE: none seen in headers]; ISUPPORT list generated in s_serv.c [INFERENCE].

## 2. SERVICES
- **Package**: `azzurra/services` — "Azzurra IRC Services (legacy)", (c) 2001–2005, by Shaka and Gastaman; portions based on **Epona** (2000–2002; Anope/SirvNET lineage) and **SirvNET Services** (1998–2002). **Not** IRCServices-by-Andrew-Church, not Anope, not atheme. https://github.com/azzurra/services
- **Daemons** (services.conf.example NS/CS/MS/HS/OS/RS/ST/SS + inc/ headers): **NickServ, ChanServ, MemoServ, HelpServ, OperServ, RootServ, StatServ, SeenServ** + Global noticer; no BotServ, no HostServ (cloaks are ircd-side +x) [INFERENCE, grounded in inc/ file list].
- **Registration model**: nick+channel registration with email authorization (EMAIL:1, sendmail), REGDELAY, expiry (NICKEXP/CHANEXP 40d, MEMOEXP 21d), nick RELEASE/enforcement (RELEASE:300s enforcer), access tiers CFOUNDER/SOP/AOP/AVOICE/HOP, AKICK, MLOCK (valid modes tnimspcR), limits (CHAN_ACC_MAX 400, USERACC 40, AKICK 300), flood tiers TLEV/FLEV (warn→globops→kill), clone detection, AKILL w/ expiry + percentage-of-users guard, jupes, SXLINE, ignore list.
- **Hierarchy**: single Services Master (M: line) + SRA list via RootServ SRA add.
- **Linking**: C/N-line connect as **U-lined server** (`U:service:azzurra.chat`), D: description, A: network name — no SID/UID.

## 3. TOPOLOGY (link constraints)
- Wire protocol: `PASS <pw> :TS`, `SERVER`, `SVINFO <TS_CURRENT> <TS_MIN> <STANDALONE> :<UTC>`, then CAPAB token negotiation. **Pre-TS6**: no SID/UID; combined NICK line, SJOIN channel bursts, SVSMODE-style services modes.
- Extras: DH DKEY exchange, RC4 link encryption, gzipped links, NICKIP, TSMODE, SOB/EOB.
- Constraint: **only TS-protocol, non-TS6 services can link**. Generic Bahamut protocol modules exist upstream in atheme and Anope, but azzurra's -azzurra(4.8) tokens/umodes (EBMODE, +z/+S, SVSNICK flags) mean the network's own services are the reference link peer [INFERENCE for third-party module patch needs].

## 4. CAPABILITY COMPARISON (RESOLVED)

Filled from the definitive capability report: `matrix/capability-matrix.md`
(merged c8d86d2 — evidence refs E1-E7, options O1-O11 (formerly
D1-D11), constraints C1-C2;
issue #4). Options below — each row states whether a feature-parity path exists (with its milestone meta-issue) or the row is a moving-forward modernization; full per-cell evidence lives in the report.

| Capability | azzurra-production | solanum-it | atheme-it | Backward-compatibility option | Forward option |
|---|---|---|---|---|---|
| S2S protocol | TS + CAPAB tokens [E7] | TS6 (SID/UID), live link [E1] | U-lined TS6 service [E1] | TS3/CAPAB compatibility protocol module in solanum-it (upstream work, heavy) [E7] | TS6 SID/UID linking (current, live [E1]) |
| Halfops (+h) | native, non-disableable [E7] | absent: zero source symbols, live 005 `PREFIX=(ov)@+` [E4/E5] | present [E6] | implement +h upstream (**M-1**, milestone [0.1.0](https://github.com/0xf01d/azzurra-stacks/milestone/1)); cost: medium [E4/E5] | o/v-only modern semantics (current) [E5] |
| Cloaking | umode +x [E7] | no ircd-side cloak implementation [E4] | HostServ vHost [E6] | ircd-side cloak module (**M-3**, [#9](https://github.com/0xf01d/azzurra-stacks/issues/9)); cost: medium [E4] | HostServ vHost (current) [E6] |
| Registered nick umode (+r) | +r [E7] | set via services [E2] | sets +r | +r via services (unchanged) [E2] | same [E2] |
| Reg-only channel (+R) | yes [E7] | yes | sets +R | +R (unchanged) [E7] | same [E7] |
| No-color (+c) | yes [E7] | yes | n/a (ircd) | +c (unchanged) [E7] | same [E7] |
| No-CTCP (+C) | yes [E7] | yes | n/a (ircd) | +C (unchanged) [E7] | same [E7] |
| Oper-only (+O) | yes [E7] | yes | n/a (ircd) | +O (unchanged) [E7] | same [E7] |
| SSL-only (+S) | umode+chmode [E7] | listener-level TLS; no dedicated +S flag [E4] | n/a (ircd) | +S mode upstream (**M-4**, [#10](https://github.com/0xf01d/azzurra-stacks/issues/10)); cost: low-medium [E4] | listener-level TLS policy (current) [E4] |
| Moderated-for-unreg (+M) | yes [E7] | `MODE_REGONLY` registered-only [E4] | sets +M | +M registered-only (unchanged) [E4] | same [E4] |
| Hide banlist (+B) | yes [E7] | +b view restricted to ops [E4] | n/a (ircd) | azzurra banlist-hiding resyntax (**M-7**, [#13](https://github.com/0xf01d/azzurra-stacks/issues/13)); cost: medium [E4] | ops-restricted +b view (current) [E4] |
| Registered-join restrict (+j/+z) | two flavors [E7] | +j = join throttle [E4] | n/a (ircd) | registered-join semantics (**M-7**, #13); cost: medium [E4] | join throttle (current) [E4] |
| Ban exceptions (+e) | no [E7] | yes (28 source files) [E4] | n/a | n/a — azzurra had none [E7] | keep ADDITIVE +e [E4] |
| INVEX (+I) | no [E7] | yes (19 source files) [E4] | n/a | n/a — azzurra had none [E7] | keep ADDITIVE +I [E4] |
| Extbans | EBMODE token only [E7] | $-extbans (22 source files) [E4] | n/a | n/a — azzurra EBMODE only [E7] | keep ADDITIVE $-extbans [E4] |
| WATCH/MONITOR | WATCH [E7] | MONITOR (28 source files) [E4] | n/a | optional WATCH compat module (upstream work) [E7] | MONITOR (current, modern) [E4] |
| SILENCE | yes (10) [E7] | yes | n/a | SILENCE (unchanged) [E7] | same [E7] |
| DCCALLOW | yes (5 files) [E7] | absent [E4] | n/a | DCCALLOW (**M-6**, [#12](https://github.com/0xf01d/azzurra-stacks/issues/12)); cost: medium [E4/E7] | accept gap (current) [E4] |
| SHUN | yes [E7] | yes | n/a | SHUN (unchanged) [E7] | same [E7] |
| IRCv3 CAP | no [E7] | message-tags (123 files), server-time, account-notify, extended-join [E4] | n/a | n/a — azzurra pre-CAP [E7] | keep ADDITIVE IRCv3 CAP [E4] |
| SeenServ | built-in [E7] | n/a | contrib cs_seen in tree [E6] | contrib cs_seen load (config-only parity; module in tree [E6]) | native service (upstream) or accept gap |
| StatServ | built-in [E7] | n/a | statserv native [E6] | statserv native (parity) [E6] | continue native [E6] |
| RootServ hierarchy | SRA list [E7] | n/a | OperServ + services root [E6] | OperServ + services-root mapping (current) [E6] | dedicated RootServ service (**M-5**, [#11](https://github.com/0xf01d/azzurra-stacks/issues/11)); cost: high |
| Nick enforcement | RELEASE + enforcer (300s) [E7] | n/a | RELEASE/ENFORCER [E6] | RELEASE + ENFORCER (unchanged) [E6] | same [E6] |
| Email-verified reg | EMAIL:1 [E7] | n/a | configurable [E6] | EMAIL-confirmed registration in deployment config (config-only parity) [E6] | same config, or atheme defaults |
| Nick/Chan expiry 40d | NICKEXP/CHANEXP 40d [E7] | n/a | configurable [E6] | 40d in deployment config (config-only parity) [E7] | atheme defaults (drifts from azzurra) |
| MemoServ | yes, 21d expiry [E7] | n/a | MemoServ [E6] | MemoServ (unchanged, 21d expiry) [E6/E7] | same [E6] |
| SASL authentication | no [E7] | n/a | saslserv [E6] | n/a — azzurra pre-SASL [E7] | keep ADDITIVE saslserv [E6] |
| HostServ vHosts | +x cloaks only [E7] | n/a | hostserv [E6] | n/a — azzurra +x cloaks only [E7] | keep ADDITIVE hostserv; canonical cloaking path (see [O4](matrix/capability-matrix.md#o4)) [E6] |
| BotServ / GroupServ / ChanFix / GameServ / RPGServ / ALIS | no [E7] | n/a | all present [E6] | n/a — azzurra had none [E7] | keep ADDITIVE service set [E6] |
| Access model | CFOUNDER/SOP/AOP/HOP/AVOICE [E7] | n/a | XOP + ACL [E6] | XOP tiers cover the HOP tier (the +h half is M-1) [E6] | ACL granularity (current, finer than XOP) [E6] |
| WEBIRC/HAProxy ingress | both [E7] | WEBIRC yes (3 files); no PROXY listener [E4] | n/a | WEBIRC passthrough (current, azzurra-era shape) [E4] | native PROXY listener (**M-2**, [#7](https://github.com/0xf01d/azzurra-stacks/issues/7)); cost: medium |
| Flood/clone detection | tiers + clone warn-kill [E7] | ircd throttle [E4] | services limits [E6] | azzurra tiers + clone guard (**M-8**, [#14](https://github.com/0xf01d/azzurra-stacks/issues/14)); cost: medium-high [E7] | two-layer ircd+services enforcement (current) [E4/E6] |

Upstream implementation gaps tracked in milestone
[0.1.0 — feature parity](https://github.com/0xf01d/azzurra-stacks/milestone/1):
M-1 halfops (+h) in solanum-it; M-2 native PROXY-protocol listener in solanum-it.
Constraints: C1 testnet-only PEMs/cloak.key (rotation mandatory before real
infra); C2 verify.sh assumes ephemeral runners (teardown required on shared
runners).

## 5. REPRO NOTES (CI)
- **Buildability proven**: azzurra/bahamut and azzurra/services each ship `.github/workflows/build.yml` + `Dockerfile`; full stack dockerized at https://github.com/vjt/azzurra-testnet (hub + leaf-v4 + leaf-v6 + services via docker compose; /map + cross-leaf whois + services round-trip smoke script; GHCR images `ghcr.io/azzurra/bahamut`, `ghcr.io/azzurra/services`; one bahamut binary reused across roles via SERVER_ROLE; v4+v6 S2S; throwaway self-signed certs).
- Pins: azzurra/bahamut `master` (1.4.34, BRANCH=perimeter, -azzurra(4.8)) and azzurra/services `master`, pinned by commit SHA. Do NOT use upstream DALnet/Bahamut 2.2.x — different protocol era, incompatible.
- Testnet non-goals (upstream): HAProxy, webirc, stats, real-Azzurra links, HA topologies — keep out of CI scope.
- Third-party services: atheme/Anope bahamut modules exist upstream (Anope stable 2.0.20, https://www.anope.org/); expect patches for azzurra-specific tokens [INFERENCE].

### Sources
- https://github.com/azzurra/bahamut (README; include/patchlevel.h, include/struct.h, src/channel.c, doc/README.TSora)
- https://github.com/azzurra/services (README; doc/services.conf.example; inc/ layout)
- https://github.com/vjt/azzurra-testnet (README: topology, CI workflows, GHCR images)
- https://www.dal.net/?page=Bahamut (DreamForge→Bahamut lineage)
- https://github.com/DALnet/Bahamut (upstream 2.x, distinct line)
- https://www.anope.org/ (Anope 2.0.20)
