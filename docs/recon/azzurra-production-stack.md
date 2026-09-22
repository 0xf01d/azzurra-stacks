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

## 4. CAPABILITY MATRIX SKELETON
| Capability | azzurra-production | solanum-it | atheme-it | Gap notes |
|---|---|---|---|---|
| S2S protocol | TS + CAPAB tokens | TS6 (SID/UID) | n/a | TODO verify our forks |
| Halfops (+h) | native, non-disableable | yes | yes | TODO |
| Cloaking | umode +x | +x-style | n/a | TODO |
| Registered nick umode | +r | +r | n/a | TODO |
| Reg-only channel (+R) | yes | +R | n/a | TODO |
| No-color (+c) | yes | +c | n/a | TODO |
| No-CTCP (+C) | yes | +C | n/a | TODO |
| Oper-only (+O) | yes | +O | n/a | TODO |
| SSL-only (+S) | yes | TLS modes | n/a | TODO |
| Moderated-for-unreg (+M) | yes | +M | n/a | TODO |
| Hide banlist (+B) | yes | +b world | n/a | TODO |
| Registered-join restrict (+j/+z) | two flavors | +z extban differs | n/a | TODO |
| Ban exceptions (+e) | no | yes | n/a | TODO |
| INVEX (+I) | no | yes | n/a | TODO |
| Extbans | none (EBMODE token only) | $-extbans | n/a | TODO |
| WATCH/MONITOR | WATCH | MONITOR | n/a | TODO |
| SILENCE | yes (10) | yes | n/a | TODO |
| DCCALLOW | yes | no | n/a | TODO |
| SHUN | yes | yes | n/a | TODO |
| IRCv3 CAP | no | yes | n/a | TODO |
| SeenServ | built-in | n/a | 3rd-party modules | TODO |
| StatServ | built-in | n/a | stats module | TODO |
| RootServ hierarchy | yes | n/a | OperServ equivalent | TODO |
| Nick enforcement | RELEASE + enforcer (300s) | n/a | RELEASE/ENFORCER | TODO |
| Email-verified reg | yes (EMAIL:1) | n/a | configurable | TODO |
| WEBIRC/HAProxy ingress | both | webirc | n/a | TODO |

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
