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
