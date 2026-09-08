# 03 — Evidence (Ka0s Pretty Chat)

**Run date:** 2026-09-08 · **Standard:** v2.39.0 (2026-09-07) · **Repo:** `master` @ `8c06d55`

Every `file:line` below was re-read and the cited text quoted beside it in one pass after the
findings were drafted. Every count below was produced by the command printed with it, and each
command's **scope** — what it swept and what it did not — is stated. No number in this bundle was
re-typed from an earlier bundle or from memory.

---

## 0 — Resolving the standard

```
$ curl -fsSL https://raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master/standards/STANDARDS.md -o STANDARDS.md
$ head -1 STANDARDS.md
# Ka0s WoW Addon Standard (v2.39.0, 2026-09-07)
```

`AUDIT.md` (583 lines) and all **26** section files linked from the `## Sections` list were fetched
the same way, into a **clean** directory, so no file from an earlier session could be read by
mistake. The list was discovered from the index, not hard-coded:

```
$ grep -oE '\(standards/[a-z0-9-]+\.md\)' STANDARDS.md | tr -d '()' | sed 's|standards/||' | sort -u | wc -l
26
```

Sections fetched: `anti-patterns architecture audit-review-history automated-tests compat
debug-logging documentation events-frames-taint layout library-stack line-endings lint localization
naming-cheatsheet open-evolutions options-ui packaging performance preview-mode public-api
savedvariables slash-commands standalone-windows testing toc-file versioning-git`, plus
`standards/ADDONS.md`.

---

## 1 — Lint

**Scope:** the whole repo as `.luacheckrc` defines it — `exclude_files` is `Libs`, `libs`,
`GlobalStrings`, `docs/audits`, `docs/reviews`, `tests/_kit/`. **The test tree is in scope**, which
is what makes the `0/0` mean something.

```
$ luacheck .
...
Total: 0 warnings / 0 errors in 44 files
```

`lint`'s three checks, read before quoting the `0/0`:

- `.luacheckrc:20-27` — the `exclude_files` block. `.luacheckrc:26` is `    "tests/_kit/",` — the
  vendored kit alone, spelt with the trailing slash the template uses. Bare `tests/` is **not**
  excluded.
- **No top-level `ignore`.** `.luacheckrc:29` reads
  `-- NO TOP-LEVEL `ignore`, and none is coming back (lint-§1, `M4-11`).` The four surviving
  `ignore` entries are per-file stanzas (`.luacheckrc:142,151,160,169`), each `{ "212/self" }`.
- **The harness global is in the right stanza.** `.luacheckrc:99` is `files["tests/"] = {` and
  `:101` is `        "_G.PC_TEST",`. It is **not** in top-level `read_globals`.
- **Both perf entries correctly absent** under the ratified `performance-§12` exemption:
  `grep -n 'debugprofilestop\|PerfDB' .luacheckrc` returns nothing but the `globals` block header at
  `:51`, whose members are `PrettyChatDB`, `StaticPopupDialogs`, `UISpecialFrames`.

`GlobalStrings` is excluded beyond the template's list; `.luacheckrc:11` gives the reason —
`--   * GlobalStrings/ — machine-generated data + the ~1.6MB source dump.` — which is
`layout-§1`'s generated-data carve-out, not the test-tree exclusion `lint` forbids. Recorded, not
filed.

## 2 — Headless suite

**Scope:** `tests/run.lua`'s own suite list; `tests/_kit/` is the vendored harness, not a suite.

```
$ lua tests/run.lua
...
  PASS  eol: every tracked file carries the terminator .gitattributes declares for it
328 passed, 0 failed, 0 skipped, 328 total
```

The `line-endings-§7` gate is the last line of that run and it is **green**, so §7's "gate reports
green but the audit finds strays" case does not arise here — check 4 below independently returns 0.

## 3 — Vendored Ka0s-owned library drift

**Scope:** the whole `LibKa0s` ship folder and the whole vendored test kit — every module, not only
the six majors this addon wires. Diffed against the tag root `CLAUDE.md` names, **not** the sibling's
`HEAD`.

`CLAUDE.md:34` (re-read, quoted):

> `- **Library provenance — this line is the gate's input.** Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.27.0 (MIT).`

Sibling repo found at `../LibKa0s`; `git rev-parse -q --verify refs/tags/v1.27.0` →
`bf97b65dc4601d12dcbd1f53810aaa6796b7f580`. `v1.27.0` is also the newest tag
(`git tag --sort=-v:refname | head -1`), so the pin is current as well as honoured.

```
$ git -C ../LibKa0s archive v1.27.0 | tar -x -C $T
$ diff -r $T/LibKa0s  /…/PrettyChat/libs/LibKa0s
(no output)
$ diff -r $T/testkit  /…/PrettyChat/tests/_kit
(no output)
```

**Both empty.** No anti-pattern #45 (drift) and no #48 (partial vendoring). The harness is under
`tests/_kit/`, never `libs/`.

The three provenance greps:

```
$ grep -n 'Bundles \[LibKa0s\]' CLAUDE.md
34:- **Library provenance — this line is the gate's input.** Bundles [LibKa0s](…) v1.27.0 (MIT). …
$ grep -n 'Bundles \[LibKa0s\]' README.md
(no output)
$ grep -nE '^## (Libraries|Bundled libraries|Libraries and credits|Credits and libraries|Credits and bundled libraries)' README.md
(no output)
$ grep -n 'WoW_Addon_Standard' README.md
6:![Standard](https://img.shields.io/badge/Ka0s-WoW_Addon_Standard-yellow)
```

The badge is the **bare** `![Standard](…)` form, not wrapped in a link. The README's intro
(`README.md:11-13`) carries no library roll-call, and the file has no `## Credits` section at all
(`grep -n '^## ' README.md` returns eight headings, none of them Credits).

## 4 — Line endings

**Scope:** (a)–(d) read `.gitattributes` at the repo root. (e) sweeps **every tracked file** —
`git ls-files`, no path excluded — and skips only what git itself marks `binary`.

```
$ test -f .gitattributes && echo PRESENT
PRESENT
$ grep -n '^\* text=auto eol=\(crlf\|lf\)$' .gitattributes
26:* text=auto eol=crlf
$ grep -n '^\*\.sh text eol=lf$' .gitattributes
34:*.sh text eol=lf
$ grep -c ' binary$' .gitattributes
20
$ git ls-files -z | xargs -0 -I{} sh -c '
    set -- $(git check-attr text eol -- "{}" | sed "s/.*: //")
    [ "$1" = unset ] && exit
    cr=$(tr -dc "\r" < "{}" | wc -c); lf=$(tr -dc "\n" < "{}" | wc -c)
    case "$2" in crlf) [ "$lf" -gt 0 ] && [ "$cr" -ne "$lf" ] && echo "{}";;
                 lf)   [ "$cr" -gt 0 ] && echo "{}";; esac' 2>/dev/null | wc -l
0
```

**(e) returns 0.** The repo is client-bound (it has a `.toc` and a client-bound `libs/` payload), so
`eol=crlf` is the correct pin. 2026-09-07's `PC-66` reported **4**; that bundle is frozen and is not
edited, and the two figures are the same command over a tree that has since been renormalized and
re-checked-out, not two different commands.

**§5 body diff** — a diff, not a reading:

```
$ head -81 .gitattributes | tr -d '\r' > repo_ga.txt      # the file is exactly 81 lines
$ diff canonical_client_bound.txt repo_ga.txt && echo IDENTICAL
IDENTICAL
$ wc -l < .gitattributes
81
```

Byte-identical to `line-endings-§5`'s canonical **client-bound** body, and nothing follows it — so
there is no `§5 appendix` to evaluate and none is owed. **§7's owner** is present:
`tests/_kit/test_eol.lua` exists, is byte-identical to the kit at `v1.27.0` (check 3), and reports
green in check 2.

## 5 — Packaging

**Scope:** (a) the named list; (b) every root dot-entry that exists in the repo.

```
$ for e in .luacheckrc .pkgmeta .gitignore .gitattributes .claude .superpowers docs tests _dev; do
    grep -q "^  - $e\b" .pkgmeta || echo "NOT IGNORED — $e"; done
NOT IGNORED — .superpowers
$ for e in .[!.]*; do [ -e "$e" ] || continue; grep -q "^  - $e\b" .pkgmeta || echo "UNACCOUNTED — $e"; done
UNACCOUNTED — .git
```

**Nothing to file.** `.git` is the one entry the packager never sees. `.superpowers` prints from (a)
only because (a) is a fixed enumeration — the directory does not exist here, and `.pkgmeta:24` says
so on purpose: `# no .superpowers line, because no such directory exists at this root.` (b), the
check that cannot go stale, is clean. `.pkgmeta:25` reads `  - .claude     # untracked; listed under
packaging.md:28`, which closes 2026-09-07's `PC-63`; `.pkgmeta:15` reads `  - .pkgmeta    # packager
configuration: consumed before the zip is built, of no use inside it`.

## 6 — Complexity

**Scope:** the standard's invocation **verbatim** from the repo root — `libs/` and `tests/_kit/`
excluded, everything else in.

```
$ lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .
...
No thresholds exceeded (cyclomatic_complexity > 15 or length > 1000 …)
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
     53171       6.7     2.0       49.8      694            0      0.00    0.00
```

`lizard` is installed (`/home/tushar/.local/bin/lizard`, version 1.24.0 per the run manifest), so
this is measured, not skipped.

**Drift against the newest recorded bundle,** `docs/automated-tests/20260908-181425/`:

| | Recorded | Measured today | Δ |
|---|---|---|---|
| Total NLOC | 52,962 | 53,171 | +209 |
| Functions | 688 | 694 | +6 |
| Avg CCN | 2.0 | 2.0 | — |
| Functions over CCN 15 | 0 | 0 | — |
| Lint files | 43 | 44 | +1 |
| Test cases | 323 | 328 | +5 |

`docs/automated-tests/RESULTS.md:26` (re-read) is the row those recorded figures come from:

> `| [`20260908-181425`](20260908-181425/) | 1.4.0 | 0/0 | 43 | 323/0/323 | skip | 52962 | 688 | 6.6 | 2.0 | 13 | 0 | **green** |`

and `docs/automated-tests/RESULTS.md:63`:

> `Current as of [`20260908-181425`](20260908-181425/) — **this run's measurement, not its diff.** Max CCN **13** across 688`

**How stale the stamp dates it.** `docs/automated-tests/20260908-181425/manifest.json` records
`"sha": "4fecedab216c5440a5c359734a4620f399a0322b"` on branch
`feat/2026-09-07-audit-review-remediation`, and `"release": null`. `git log --oneline 4feceda..HEAD`
is two commits — `0d3edac` (*M4c-06*) and the merge `8c06d55`. **No file entered `layout-§1`'s
1000–1500 band and no function crossed a `lizard` threshold since that run**; the whole delta is
`M4c-06`. This is PC-76, and it is Info because the checkpoint is release and none has been cut.

**Artifact audit (`automated-tests`).** `tests/_kit/run-automated-tests.sh` is vendored and
executable; `docs/automated-tests/README.md` and `docs/automated-tests/RESULTS.md` both exist; there
is **no** retired `docs/complexity.md` (`ls docs/complexity.md` → No such file) and **no**
`docs/perf-runs/`.

**The watch list read as a decision record.** Two entries, both `Accepted`:

```
$ for c in $(git log --format=%h -- docs/automated-tests/RESULTS.md | head -8); do
    echo "$c: $(git show $c:docs/automated-tests/RESULTS.md | grep -c 'Accepted')"; done
cb1a80c: 2   7de1655: 2   14c1957: 2   b7b9180: 2   719be7c: 2
1de8453: 1   a2ba8f8: 1   53b2121: 1
```

Anti-pattern #53's shelf life is **three consecutive *release* runs**, and this repo has had
**none** — every bundle's `manifest.json` carries `"release": null` and every row reads version
`1.4.0`, so no entry's clock has started. The entries themselves:

- `docs/automated-tests/RESULTS.md:80` — `tests/test_panel.lua` at 1042, in the 1000–1500 band,
  **newly** in it at this run. `layout-§1` calls on-notice a compliant state.
- `docs/automated-tests/RESULTS.md:81` — `GlobalStrings/GlobalStrings.lua` at 23,842, which
  v2.39.0's generated-data carve-out now exempts **by rule**; the runner still prints the row because
  the table is a raw line-count census.

**Zero functions are warned on**, so the "dense defaulting versus tangled control flow" distinction
has nothing to apply to this run — `### Functions `lizard` warned on` at
`docs/automated-tests/RESULTS.md:74` reads `None.`

**Refactors since the last audit, read against `performance-§11`.** `git log --oneline 92c43f5..HEAD`
contains no watch-list-driven refactor: the two complexity-relevant commits are `M4c-06` (removing a
blanket lint ignore, which added no branches) and `M5-01` (a record regeneration). No anonymous
mega-helper, no per-call dispatch table, no `t.k = stored.k or D.k` introduced — the only `or`-default
in the tree is `modules/Override.lua:48`, which predates this cycle and is over a string.

## 7 — The recorded-deviation register, read first

**`docs/ARCHITECTURE.md:209`** is `## Documented deviations`. Nine active rows at `:228`–`:236`,
each re-read; a retired block at `:238`–`:264` holding two.

**Rule-change check (`audit-review-history` MUST 2).** One row cites a rule the standard permits
outright. `docs/ARCHITECTURE.md:230`, quoted:

> `| `toc-file-§1` | `## Title:` keeps its rainbow `\|cRRGGBB…\|r` escapes, `## Author:` keeps its stylized `aDd1kTeD2Ka0s` casing, and `## X-Wago-ID` is absent | … `toc-file-§1` asks for both distribution ids once an addon is published anywhere; …`

against `toc-file.md:30`, quoted:

> ``X-Wago-ID` and `X-WoWI-ID` are **optional** (**MAY**) — include each only when the addon is actually listed on that platform (Wago / WoW Interface respectively); an addon that doesn't publish there simply omits the line.`

That is PC-73. I checked whether v2.39.0 introduced the permission and it did not — the same sentence
is present at `03a9aa0` (v2.38.0) in the sibling standards repo — so the row has been recording a
non-deviation for longer than one cycle, and reporting it is `audit-review-history`'s job either way.

**Trigger check (`audit-review-history` MUST 3) — all nine evaluated against the tree.** The four
that needed a command:

```
$ grep -rn 'OnUpdate\|NewTicker\|C_Timer' --include='*.lua' core/ modules/ settings/ defaults/ locales/
settings/Panel.lua:530: -- A frame later, both are true. C_Timer.After(0, ...) is the client's own way
settings/Panel.lua:533: if C_Timer and C_Timer.After then
settings/Panel.lua:534:         C_Timer.After(0, function() fitTree(ctx) end)
$ grep -rn 'RegisterEvent' --include='*.lua' core/ modules/ settings/
modules/Override.lua:93:            combatWatcher:RegisterEvent(event)
```

`performance-§12`'s trigger — *"The first `OnUpdate` handler, repeating ticker, or event handler that
runs DURING combat"* — has **not** fired: one guarded one-shot next-frame hop on the options render
path, and one boundary-only event registration. `options-ui-§6`'s trigger needs a third `RenderGrid`
ratio; `libs/LibKa0s/OptionsWidgets.lua:59` is `local HALF = 0.5` and `O.RenderGrid` at `:1820` still
takes only that. `testing-§1`'s trigger needs an isolated-environment mode in the kit;
`tests/_kit/loader.lua:30` reads *"A suite that wants a fresh, isolated instance re-loads the ENTIRE
source tree"* — there is none. `localization-§1`'s trigger is a second locale file; `ls locales/`
returns `enUS.lua` alone.

**Evidence-id check (`audit-review-history` MUST 3, second half).** The register cites `PC-49`,
`PC-52`, `PC-61`, `PC-R-05`, `PC-R-06`, `M4-21` and issue `#10`. The repo gates this itself — the
suite case *"every deviation id the register cites is assigned by a bundle in docs/audits/"* passes
in check 2 — and issue #10 resolves live (see check 8).

## 8 — The issue store

**Scope:** all issues on this addon's own repo, open and closed, via the `gh` CLI subcommands. No
`gh api graphql` was used.

```
$ gh issue list --state all --limit 200 --json number,title,state,labels,url
```

14 issues. **Every one carries exactly one `state:` label and one `severity:` label**, and **no
title carries a `[status]` prefix** (anti-pattern #62) — checked by reading all 14 titles. There is
no `docs/pending/` and no `LEDGER.md` (`ls docs/pending` → No such file).

**The inverse check — a `state:will-not-do` with no register row.** Six closed `will-not-do` issues:

| # | Title | Register row? | Verdict |
|---|---|---|---|
| 14 | *Withdraw the ratified performance-§12 exemption: declined* | `performance-§12` (`:228`) | ratified |
| 13 | *LibKa0s-Pool-1.0: declined — AceGUI is already the pool* | none | **none owed** — `library-stack-§3`'s prune rule makes an unused major's absence compliant |
| 12 | *LibKa0s-Item-1.0: declined* | none | none owed, same rule |
| 11 | *LibKa0s-Widgets-1.0: declined* | none | none owed, same rule |
| 8 | *Expose per-character or per-realm profile scoping* | none | none owed — `options-ui-§3` makes the Profiles sub-page a **MAY** |
| 7 | *Add `## X-Wago-ID` to PrettyChat.toc* | `toc-file-§1` (`:230`) | row exists, but see PC-73 |

No missing-row finding is owed. The five open issues are all `state:triaged` feature/limitation
items, which is the working queue and not a deviation store.

## 9 — Documentation shape, measured

**Scope:** `find docs -name '*.md'` minus the frozen/generated directories, checked against the four
tables at `docs/ARCHITECTURE.md:169`, `:180`, `:192`, `:203`.

**Tier 1 — six of six present:**

```
$ for f in scope module-map schema settings-panel data-flow common-tasks; do
    test -f docs/$f.md && echo "OK  docs/$f.md" || echo "MISSING docs/$f.md"; done
OK  docs/scope.md      OK  docs/module-map.md   OK  docs/schema.md
OK  docs/settings-panel.md   OK  docs/data-flow.md   OK  docs/common-tasks.md
```

**Tier 2 — triggers measured against the code, not read off the doc:**

```
$ sed -n '/COMMANDS = {/,/^}/p' settings/Slash.lua | grep -cE '^\s*\{'
10                                    # slash-dispatch.md trigger (>= 8) FIRED; doc present
$ grep -rn 'SendMessage\|RegisterMessage' --include='*.lua' core/ settings/ modules/ defaults/ locales/
(no output)                           # message-bus.md trigger (> 10) NOT fired
$ ls core/Compat.lua
ls: cannot access 'core/Compat.lua': No such file or directory
$ grep -cE '^\s*function\s+[A-Za-z_][A-Za-z0-9_]*\.' core/Compat.lua
0                                     # compat-layer.md trigger (>= 3) NOT fired
```

Each unfired trigger carries a *Not applicable* row with the trigger stated
(`docs/ARCHITECTURE.md:184-190`), so *not applicable* is distinguishable from *not written*.
No row asserts *Not applicable* for a trigger that has fired.

**`## Documentation map` — both directions.** Every row points at a file that exists (checked one by
one), and every `.md` under `docs/` is registered **except** the two under `docs/revendor/`:

```
$ git ls-files 'docs/revendor/*'
docs/revendor/2026-08-25/01_DELTA.md
docs/revendor/2026-08-25/05_SUMMARY.md
```

`docs/ARCHITECTURE.md:167` (re-read) names the directory:

> `generated directories are named once each and never enumerated per run: `docs/audits/`, `docs/reviews/`, `docs/automated-tests/`, `docs/revendor/`, `docs/superpowers/`.`

`documentation-§3`'s out-of-scope list does not carry `docs/revendor/`. That is PC-71.
`docs/ARCHITECTURE.md` does not register itself, which is a **MAY** and is filed neither way.

**The fourth table exists and is correct.** `docs/ARCHITECTURE.md:192` is `### Verification and
record`, placed after Conditional and before Addon-specific, holding exactly the six rows the rule
names, and `perf-analysis/README.md` registers in `### Conditional` instead (`:190`). No note
justifying the extra table against the old three-table MUST survives. 2026-09-07's `PC-68` closes by
rule change.

**Non-canonical filenames:** none.

```
$ for f in data-model saved-variables pipeline capture-pipeline override-pipeline settings-system wow-quirks slash-commands debug-console file-index conventions complexity; do
    test -f docs/$f.md && echo "PRESENT docs/$f.md"; done
(no output)
$ ls -d docs/perf-runs
ls: cannot access 'docs/perf-runs': No such file or directory
```

**Hub shape:**

```
$ wc -l docs/ARCHITECTURE.md
359 docs/ARCHITECTURE.md
$ awk '/^## /{if(n)print n": "c; n=$0; c=0; next} {c++} END{if(n)print n": "c}' docs/ARCHITECTURE.md
## Overview: 25          ## Module Map: 42        ## Namespace publishing pattern: 26
## Invariants: 12        ## Settings Schema: 10   ## Message Bus: 7
## Slash Commands: 3     ## Event Subscriptions: 10   ## Taint Notes: 7
## Known Limitations: 7  ## Documentation map: 44 ## Documented deviations: 112
## External dependencies: 7  ## Testing: 3  ## Working environment: 6  ## Doc index: 18
```

359 lines, under the ~400 SHOULD. The one mandated section past ~60 lines is `## Documented
deviations` at **112**, which *is* the storage and has no canonical topic doc to spill to — the spill
rule names *Module Map → module-map.md*, *Settings Schema → schema.md*, *Slash Commands →
slash-dispatch.md*, *Message Bus → message-bus.md*, and all four are well under 60. Reported as
shape, not argued as arithmetic. The 18-line `## Doc index` at `:341` is the unmandated second
inventory PC-74 files.

**`## Doc index` drift, measured:** the map registers 20 documents; the index lists 12 of them plus
`../DEPENDENCIES.md`. Missing from the index: `test-cases.md` and `automated-tests/README.md` — two
of the six mandatory `### Verification and record` rows.

**`CLAUDE.md:36` staleness, measured:**

```
$ grep -n '^| `' docs/ARCHITECTURE.md | awk -F: '$1>=228 && $1<=236' | wc -l
9
$ sed -n '36p' CLAUDE.md | grep -o 'the re-check trigger for each of the [a-z]*'
the re-check trigger for each of the eleven
$ sed -n '36p' CLAUDE.md | grep -o 'most recent compliance audit is frozen under [^;]*;'
most recent compliance audit is frozen under [docs/audits/2026-08-05/](./docs/audits/2026-08-05/) (audited against Standard **v2.21.0**);
$ ls -d docs/audits/2026-09-07 docs/reviews/2026-09-07
docs/audits/2026-09-07   docs/reviews/2026-09-07
```

Nine rows against a claim of eleven, and a pointer at a bundle two runs old. That is PC-72.

## 10 — `localization-§5`, the published lists run whole

**Scope, stated precisely.** `git ls-files`, minus `libs/` (vendored, linted and swept in its own
repo), `tests/_kit/` (vendored kit), `GlobalStrings/` (generated data), `media/` (binaries),
`LICENSE`, `.claude/`, and the frozen or generated `docs/` material — `docs/audits/`,
`docs/reviews/`, `docs/revendor/`, `docs/superpowers/`, `docs/automated-tests/<run>/` and the
generated `docs/test-cases.md`. **Everything else is in**, including `.toc`, `.luacheckrc`,
`.pkgmeta`, root `README.md`/`CLAUDE.md`/`DEPENDENCIES.md`, all of `tests/` and all live `docs/`
pages. The `BRITISH` and `ALLOWED` lists were copied **whole** from `localization-§5` — no entry
added, none removed — and `ALLOWED` was removed as **whole words** first, exactly as the rule
specifies.

```
$ sh brit3.sh | wc -l
49
$ sh brit3.sh | sed 's/^\(\[[a-z]*\]\).*/\1/' | sort | uniq -c | sort -rn
     30 [colour]      9 [honour]      4 [behaviour]      2 [modelled]
      1 [neighbour]   1 [licence]     1 [labelled]       1 [acknowledgement]
$ sh brit3.sh | sed 's/^\[[a-z]*\] //; s/:.*//' | sort | uniq -c | sort -rn
     16 tests/test_locale.lua       7 tests/test_schema.lua      4 docs/smoke-tests.md
      3 docs/settings-panel.md      3 docs/common-tasks.md       2 tests/test_panel.lua
      2 tests/run.lua               1 tests/wow_mock.lua         1 tests/test_override.lua
      1 tests/test_libka0s.lua      1 tests/test_apply.lua       1 settings/Schema.lua
      1 settings/Panel.lua          1 modules/Override.lua       1 docs/schema.md
      1 docs/data-flow.md           1 docs/ARCHITECTURE.md       1 core/PrettyChat.lua
      1 .luacheckrc
```

**49 hits, 19 files.** The five in shipped source and config, re-read and quoted:

- `settings/Schema.lua:72` — `-- PrettyChat:IsVisible in modules/Override.lua, which honours all four modes).`
- `modules/Override.lua:41` — `-- canonical modes are honoured by what ApplyStrings writes to _G[GLOBALNAME].`
- `core/PrettyChat.lua:102` — `--- behaviour owed to the second, leaving the override in place until a /reload.`
- `settings/Panel.lua:465` — `    -- selection in the text COLOR alone. That was a column of coloured text, not a`
- `.luacheckrc:167` — `-- object answers like a FontString for every frame the suites make, not for one stored colour.`

All five are **comments**. **No player-visible string is affected**, which is the finding's grade:

```
$ grep -rinE '"[^"]*(colour|behaviour|honour|grey|licence)[^"]*"' --include='*.lua' core/ settings/ modules/ defaults/ locales/
(no output)
```

`locales/enUS.lua` is clean. **No `localization-§5` gate exists in this repo:**

```
$ grep -rn 'BRITISH\|localization-§5' tests/*.lua
(no output)
```

The only `ALLOWED` in `tests/` is `tests/test_doc_structure.lua:63`, an unrelated list of permitted
history headings. That is PC-75.

## 11 — Options panel content, from the schema

**(a) Pages and their tabs, read from the schema and the builders:**

| Page | Tabs, in `group` declaration order | Renderer |
|---|---|---|
| landing | — (exempt, `options-ui-§13`) | `H.BuildLandingPage` |
| `General` | `Master controls` | `settings/Panel.lua:125` — `H.RenderTabbedSchema(ctx, "General", { [H.MASTER_GROUP] = generalAfterGroup }, nil)` |
| `Categories` | Loot, Currency, Money, Reputation, Experience, Honor, Tradeskill, Misc | `settings/Panel.lua:618` — `H.TabStrip(ctx, {` |

No Profiles sub-page exists. `settings/Panel.lua:75` records the one-tab case explicitly:
`-- A ONE-GROUP PAGE STILL DRAWS ITS STRIP. RenderTabbedSchema has done that since`. No fallback to
an untabbed form and no early return that skips the strip: `buildCategoriesBody` heals a stale
pointer (`activeCategory`) rather than bailing.

**(b) Master controls, composed.** `settings/Schema.lua:79` is `local MASTER_SPEC = {`, with
`frameless = true` at `:83`. The frameless omission is proven, not assumed:

```
$ grep -rn 'SetMovable' --include='*.lua' . | grep -v '/libs/'
modules/Override.lua:71: -- no size, no anchor, no SetMovable — so the composed Master controls tab stays
settings/Schema.lua:65:  -- PrettyChat is FRAMELESS — `grep -rn SetMovable core/ modules/ settings/`
```

Two comments and no call. `General visibility` stays, correctly, and the `Test` verb is the
composer's `leadButton` (`settings/Schema.lua:116-120`) under the ratified `options-ui-§15` row.

**The `General visibility` migration question, answered.** `options-ui-§15` requires a bumped
`schemaVersion` and a runner step only where a *show only in combat* **boolean** shipped at that path:

```
$ git log --all --oneline -S'inCombat' -- defaults/Profile.lua settings/Schema.lua
(no output)
$ git log --oneline -S'visibility' -- defaults/Profile.lua
(no output)
```

No boolean ever shipped there, so no stored type changed and **no migration is owed**.
`core/Database.lua:14` is `Database.SCHEMA_VERSION = 1` with an empty `migrations` table at `:26`,
which is the correct state. Recorded compliant; not filed.

**(c)/(d) Color rows.** None exist, and the repo gates it —
`tests/test_schema.lua:176`: `test("no colour row exists, and none may appear without its
class-colour companion", function()`, asserting `t.eq(colours, 0, …)` at `:199`. `grep -rn
'disabledIf' settings/` returns nothing.

**(e)/(f) Reorder and media groups.**

```
$ grep -rn 'ScrollUp-Up\|ScrollDown-Up' --include='*.lua' settings/ | grep -v '/libs/'
(no output)
$ grep -rn 'LSM30_Font\|LSM30_Border\|LSM30_Statusbar' settings/
(no output)
```

**(h) The wrapped-strip geometry case.** `tests/_kit/mock_base.lua:132` (re-read) is
`  function f:GetHeight() return (self.__geomLive and self.__geomH) or 0 end` — the kit **can** now
answer a real height, so a falsifiable case is possible. Nothing in `tests/` asserts it:

```
$ grep -rn 'selection-invariant\|reserved band\|y offset' tests/*.lua
(no output)
```

That is PC-69, carried and deferred.

**(i) The secondary division** is `ctx.activeSubTab`, a table keyed per primary tab
(`settings/Panel.lua:376` — `    ctx.activeSubTab = ctx.activeSubTab or {}`; `:381` —
`    ctx.activeSubTab[category] = key`), never written to the profile, inside the scroll, with no
third level. That is the ratified `options-ui-§13` row at `docs/ARCHITECTURE.md:233`.

## 12 — Shared subsystems: the wiring, not the absence

The addon owns a **descriptor plus a degradation stub** per adopted major, and no implementation:

```
$ grep -rn 'LibStub("LibKa0s-' --include='*.lua' core/ settings/
core/EnvSetup.lua:59:      local Env = LibStub and LibStub("LibKa0s-Env-1.0", true)
core/MediaSetup.lua:42:    local Media = LibStub and LibStub("LibKa0s-Media-1.0", true)
core/CoreSetup.lua:41:     local lib = LibStub and LibStub("LibKa0s-Core-1.0", true)
core/DebugLogSetup.lua:39: local lib = LibStub and LibStub("LibKa0s-DebugLog-1.0", true)
settings/OptionsSetup.lua:17: local lib = LibStub and LibStub("LibKa0s-Options-1.0", true)
settings/Slash.lua:74:     local lib = LibStub and LibStub("LibKa0s-Slash-1.0", true)
```

There is no `modules/DebugLog.lua`, no widget-maker file, no dispatcher and no test framework of the
addon's own — which is evidence of **compliance**, not a missing feature.

**Stub coverage.** `core/CoreSetup.lua:94` (re-read) is
`    function NS.MakeCloseButton() return nil end`, inside the library-absent branch and **above** the
`return` at `:95`. That closes 2026-09-07's `PC-64`; the live wrapper is `core/CoreSetup.lua:123` —
`        return lib.MakeCloseButton(parent, onClick, addonName)` — three arguments out for two in,
which is the point. The whole surface is gated rather than eyeballed:
`tests/test_surface_parity.lua` loads a **live** arm and a **bare** arm from the same loader with
`skip = { "libs/LibKa0s/Core.lua" }` (`:37-38`) and compares `Kit.publicMembers`, so a member the
stub omits reddens the suite. The **Options** stub is load-completing rather than member-answering by
design, which is the one documented exception and is not flagged.

**The close-button grep, run as written:**

```
$ grep -rn 'MakeCloseButton(' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/'
core/CoreSetup.lua:94:    function NS.MakeCloseButton() return nil end
core/CoreSetup.lua:123:    return lib.MakeCloseButton(parent, onClick, addonName)
```

Two lines: the degraded twin and the one wrapper. No direct `lib.MakeCloseButton(…)`, no
`Core.MakeCloseButton(…)`, no `NS.DebugLog.MakeCloseButton(…)`. Anti-pattern #65 does not arise, and
no `standalone-windows` decline needs evaluating — this addon builds no window of its own.

**Media, both halves:**

```
$ find media -type d
media  media/logos  media/screenshots
$ ls libs/LibKa0s/media/
fonts  icons  textures
$ grep -rn 'SetAtlas' --include='*.lua' core/ settings/ modules/ defaults/ locales/
(no output)
```

No private `fonts/`, `icons/` or `textures/` shadowing the payload (anti-pattern #63 does not arise);
what remains is the logo and the screenshots, which is what legitimately remains. `core/MediaSetup.lua:99`
is `if Media then Media.RegisterLSM(addonName) end` — one call, fed the file's own first vararg
(`core/MediaSetup.lua:1`), loading at `PrettyChat.toc:36`, above `core\Constants.lua` at `:37`. The
console was told: `core/DebugLogSetup.lua:125` is `    addonName = addonName,`. The only
`Interface\` path in the tree is the addon's own logo (`settings/Panel.lua:34`), built from
`addonName` rather than hand-typed.

**No `core/LSMPatch.lua`** (`library-stack-§9`, anti-pattern #76, both new in v2.39.0):
`ls core/LSMPatch.lua` → No such file.

## 13 — `layout-§1`'s cap and its carve-out

```
$ head -1 GlobalStrings/GlobalStrings.lua
-- AUTOMATICALLY GENERATED -- Your benefactors send their regards.
$ grep -n 'GlobalStrings' PrettyChat.toc
(no output)
$ sed -n '39p' .pkgmeta
  - GlobalStrings
```

All three carve-out conditions hold — generated with a comment saying so, loaded by nothing, and
`.pkgmeta`-ignored — and `tests/test_defaults.lua:178-186` reads the chunks **as data**, which the
rule explicitly permits. The repo re-checks this itself at `tests/test_layout_cap.lua:348`:
`test("layoutcap: every row claiming layout-§1's generated-data carve-out still earns all three of its conditions", function()`.
No authored `.lua` is over 1500; the largest is `tests/test_panel.lua` at 1042, in the on-notice band
and recorded at `docs/automated-tests/RESULTS.md:80`.
