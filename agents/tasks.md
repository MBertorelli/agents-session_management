# Tasks

Legend: `[ ]` todo · `[~]` in progress (max ONE at a time, except tasks fanned out to parallel subagents) · `[x]` done

Tags (see `AGENTS.md` → Task tagging): `diff:L|M|H` · `risk:L|M|H` · `exec:low|medium|high` (higher of diff/risk) · `deps:` · `coreqs:` · `files:` · `verify:`

Examples:

```
- [ ] T04 Add client retry unit tests · diff:L · risk:M · exec:medium · deps:T03 · coreqs:- · files:test/client.test.ts · verify:`npm test -- client`
- [ ] T05 Add date-parser tests · diff:L · risk:L · exec:low · deps:- · coreqs:- · files:test/date.test.ts · verify:`npm test -- date`
- [ ] T05-R Review T05 tests (Haiku-written → mandatory) · exec:medium · deps:T05 · verify:`npm test -- date`
```

## Tasks

- [ ] T00 Planning run: generate `agents/plan.md` from `agents/description.txt`, then replace this list with the full implementation task list, every task tagged as above.
