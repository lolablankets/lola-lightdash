# Lola Lightdash Changelog

Changes made in our fork on top of upstream [lightdash/lightdash](https://github.com/lightdash/lightdash).

## How to maintain this file

Add an entry **when you commit a fork-specific change**. Skip upstream merges —
just update the "Based on" line. Each entry needs: what changed, why, and which
files were touched. Keep it brief; link to PRs or plans for detail.

---

## Unreleased

_Based on upstream `0.2627.0`_

### Bug Fixes

- **Timezone-aware completed date filter boundaries** — `IN_THE_PAST` and
  `IN_THE_NEXT` completed filters now use `.tz(timezone)` before computing
  period boundaries, fixing incorrect UTC-only behavior upstream still has.
  (`packages/common/src/compiler/filtersCompiler.ts`)

### Chores

- **Removed local env files from git** — `.env`, `.env.development`, and
  `.pi/agent/` are now gitignored. (`ced403239`)
