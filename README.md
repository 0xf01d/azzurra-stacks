# azzurra-stacks

Dual-stack IRC integration lab: run the **Azzurra production lineage** and the
**next-generation forks** side by side in GitHub Actions, then close the
capability gap additively.

## Stacks

| Stack | IRCd (x3 linked) | Services (x1) | Pipeline |
|---|---|---|---|
| OLD (production lineage) | bahamut-lineage ircd (pinned by recon) | azzurra's services package (pinned by recon) | `.github/workflows/old-stack.yml` |
| NEW (next-gen forks) | [solanum-it](https://github.com/0xf01d/solanum-it) | [atheme-it](https://github.com/0xf01d/atheme-it) | `.github/workflows/new-stack.yml` |

Topology per stack: **3 ircd servers, fully linked + 1 services package**,
brought up and proven by an integration harness (CONNECT / NICK / USER / JOIN /
PRIVMSG across servers + services registration).

## Capability matrix

`matrix/capability-matrix.md` — production azzurra capabilities vs
solanum-it/atheme-it, driving **additive** parity work on our forks.
HARD CONSTRAINT: zero solanum features removed.

## Layout

- `old-stack/` — pins, patches, build glue for the production lineage
- `new-stack/` — build glue for solanum-it + atheme-it
- `matrix/` — capability matrix + gap list
- `docs/` — recon notes and decisions

## OLD-stack CI — handoff state (for work_0ndHP)

> Lane reassigned mid-flight (2026-09-22, fleet ruling) from OldStackCI **before
> any implementation landed**. This branch currently carries only this section
> + `matrix/capability-matrix.md`; the adopting lane continues here. Recon is
> complete — build on it, don't re-derive it.

### Resolved pins (resolve once at authoring time; hardcode with comments)
- azzurra/bahamut `master` @ `178ada510aa6f35c3bd772de55f079d8f4d44631`
- azzurra/services `master` @ `5b38d02573ae93c76eeec8f5065607b5767e9538`
- GHCR pulls: `unauthorized` **in this sandbox**, but work fine inside GitHub
  Actions (public images, anonymous) — CI pulls, local runs may need
  `docker login ghcr.io`. Resolve the image digests in a workflow step (or
  after a local login), then pin `image: ...@sha256:<digest>`.

### Design settled from recon (reference: vjt/azzurra-testnet @ f7cafda)
- Topology: hub + leaf2 + leaf3 (3 ircd, all IPv4 — `options.h_hub` has
  `#undef INET6`) + services, U-lined. Nets: svc-net 172.30.1.0/24 (hub +
  services), leaf2-net 172.30.2.0/24, leaf3-net 172.30.3.0/24; static IPs
  everywhere. Hub-side C/N host fields must be **bare peer IPs** — `*@<ip>` is
  rejected at s_conf.c:1648, a bare IP auto-prefixes `*@` at :1660 and matches
  by IP without rDNS (docker bridges have none). Leaf side links by hostname
  (IPv4-only nets → clean A record).
- Every ircd needs its own `U:` line for services (FLAGS_ULINE is per-conf;
  missing leaf U-line silently drops SVSMODE).
- `cert-init` one-shot (alpine + openssl): per-server self-signed PEMs +
  shared `ircd.cloak` key (must be identical network-wide).
- Autoconnect class `Y:60` with connfreq=2s — upstream 180s keeps leaves in
  split for the whole CI run.
- **Key gotcha:** the `ghcr.io/azzurra/bahamut` image bakes in
  entrypoint.sh + conf.{hub,leaf4,leaf6}.tmpl that hardcode the testnet
  topology (server names + SERVICES_IP/LEAF4_IP/LEAF6_IP env) — a pulled
  image cannot express a different topology as-is. Either (a) pull by digest
  and mount own `old-stack/bahamut/` entrypoint+templates (override
  `entrypoint:`; image ships gettext-base/whois/bash so envsubst+mkpasswd
  work), or (b) build locally from own Dockerfiles with BAHAMUT_REF/SERVICES_REF
  set to the pinned SHAs. The `ghcr.io/azzurra/services` image is fully
  env-driven (SERVICES_NAME/DESC/HUB/HUB_PORT/SERVICES_PASSWORD/SERVICES_MASTER,
  SVC_* default EMAIL=0) — usable from digest as-is.
- Other testnet requirements to carry over: `init: true` on the services
  container (setpgid EPERM when services is PID 1 with `-F`); build path must
  sed-delete `#define NO_CHANOPS_WHEN_SPLIT` from config.h + ship options.h_hub
  (else fresh-channel JOINs get no ops for 5 min) and `#undef THROTTLE_ENABLE`
  (CI reconnect storms trip it).

### TODO (in order)
1. `old-stack/`: compose.yaml (cert-init + hub/leaf2/leaf3/services + a
   `smoke` profile service attached to all three nets), compose.build.yaml
   (build fallback; `image: !reset null` + build args), bahamut/{Dockerfile,
   entrypoint.sh,conf.hub.tmpl,conf.leaf.tmpl,options.h}, services/{Dockerfile,
   entrypoint.sh,conf.tmpl}, certs/gen-cert.sh, scripts/smoke.py — adapt from
   the testnet with attribution headers.
2. Smoke (python3 stdlib, run **in-network** — from the host, bahamut's res.c
   stalls client registration on missing PTR): 001 on hub; oper up → LINKS
   shows all four servers; LUSERS ≥ 3 servers; PRIVMSG NickServ → NOTICE back;
   cross-leaf JOIN + PRIVMSG round-trip (leaf2 client receives leaf3 client's
   message) + cross-leaf WHOIS. Fail loudly, dump transcripts.
3. `.github/workflows/old-stack.yml`: push to feat/old-stack-ci + PR +
   workflow_dispatch; job `smoke` = checkout → compose pull (digest-pinned) →
   `up -d --wait` (bash /dev/tcp healthchecks) → compose run smoke → down -v,
   with always() log collection → upload-artifact on failure; job
   `build-from-source` = documented fallback (`if: github.event_name !=
   'pull_request'`), same smoke on locally built images, pins echoed to
   $GITHUB_STEP_SUMMARY.
4. Validate locally: `docker compose config` + build-path `up` + smoke. The
   pull path is blocked by sandbox GHCR auth — CI pulls fine (public images),
   so let CI run it first; local runs may need `docker login ghcr.io`.
   Sandbox has docker 29.8.0 + compose v5.5.1, working.
5. Branch + PR (base `main`, `AI-GENERATED` disclosure line 1) — done: this
   branch/PR is the handoff vehicle; the adopting lane pushes follow-up
   commits to `feat/old-stack-ci`. Push token:
   `/project/omp-irc/.gh-device/token` (as `x-access-token`), verified working.
