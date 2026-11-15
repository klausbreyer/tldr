# ADR-014: License tldr under AGPL version 3 only

## Status
Accepted.

## Date
2026-11-15

## Context
The repository had no project license. Klaus chose AGPL version 3 to release
tldr as open-source software. tldr runs as a web service, where users do not
receive a copy of the server code.

## Decision
License tldr under the GNU Affero General Public License, version 3 only
(`AGPL-3.0-only`). Keep the complete, unchanged license text in `LICENSE` and
state the grant in `README.md`. Third-party code and fonts retain their own
licenses.

## Alternatives Considered
- MIT or Apache-2.0: permit closed-source modifications, including hosted services.
- GPL-3.0: does not require a source offer for network use alone.
- AGPL-3.0-or-later: also permits future license versions. This grant covers version 3 only.

## Consequences
- Commercial use remains allowed under the license terms.
- Modified versions that users access over a network must offer those users the corresponding source code under AGPL.
- Distributed copies must meet the license requirements for notices and source code.
- A later license change cannot revoke rights already granted to compliant recipients.
