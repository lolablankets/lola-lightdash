# Lola Lightdash Changelog

Fork-specific changes on top of upstream [lightdash/lightdash](https://github.com/lightdash/lightdash).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

> **How to maintain:** Add an entry under `## Unreleased` when you commit a
> fork-specific change. When syncing upstream, update the "Based on" line.
> When deploying, rename `Unreleased` to a dated section and start a fresh one.

---

## [Unreleased]

_Based on upstream `0.2675.0`_

### Fixed

- Completed date filter boundaries (`IN_THE_PAST`, `IN_THE_NEXT`) now respect
  the timezone parameter via `.tz(timezone)` before computing period start —
  upstream still computes these in UTC.
  (`packages/common/src/compiler/filtersCompiler.ts`)

### Removed

- Local `.env` and `.env.development` files from git tracking. (`.gitignore`)

[unreleased]: https://github.com/lolablankets/lola-lightdash/compare/0.2675.0...HEAD
