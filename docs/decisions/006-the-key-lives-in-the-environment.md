# ADR-006: The key lives in the environment; dev reads the main checkout's `.env`

## Status
Accepted

## Date
2026-10-29

## Context
The OpenRouter key is a secret that costs money when it leaks. Worktrees
should not each need their own copy.

## Decision
`OPENROUTER_API_KEY` is the only secret. In development `config/runtime.exs`
loads the git-ignored `.env` of the main checkout (`Tldr.Config.shared_root/0`),
so every worktree uses the same key; real environment variables win. In
production a missing key stops the boot with a message that names it. Tests
use a fake key and stub every outside call with `Req.Test`.

## Alternatives Considered

### A `.env` per worktree
- Rejected: copies of a secret spread over the disk, and a fresh worktree
  fails until somebody copies it

### A secret manager
- Rejected: one key for one small app

## Consequences
- The development key is the one Klaus put into `.env`. A production key is
  separate and set on the host.
- `.env` must stay in `.gitignore`.
