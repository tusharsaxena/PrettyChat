Delta: LibKa0s v1.70.0 -> v1.71.0

# LibKa0s v1.70.0 -> v1.71.0: the delta (PrettyChat)

Item RV-PC of the 2026-10-07 review and standards-audit remediation: a mechanical re-vendor with no
adoption interview and no GitHub issue filed (the plan's owner scope). Copied from the annotated tag
`v1.71.0` (LibKa0s commit `cb274a4`, tag object `3bf1b97`) by `git -C ../LibKa0s archive v1.71.0
LibKa0s testkit | tar -x` into a scratch directory, then `libs/LibKa0s/` and `tests/_kit/` replaced
whole. The tag is **local only** (on LibKa0s's `feat/2026-10-07-review-audit-remediation`); the
payload is taken from the tag, never the working tree.

## 3a. The base

```sh
grep -n 'Bundles' CLAUDE.md
# 42:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.70.0 (MIT).   (before the roll)
diff -rq --strip-trailing-cr <v1.70.0>/LibKa0s libs/LibKa0s && diff -rq --strip-trailing-cr <v1.70.0>/testkit tests/_kit && echo base-matches
# base-matches
```

The provenance line and the payload agree: the base is **v1.70.0** (`7a1aabf`). Its re-vendor and
v1.69.0's had no bundle; both are recorded in the span folder `2026-10-07-v1.69.0-v1.70.0/`.

```sh
git -C ../LibKa0s log --oneline v1.70.0..v1.71.0   # LK-01 .. LK-12 of the remediation, plus RA-00
git -C ../LibKa0s diff --stat v1.70.0 v1.71.0 -- LibKa0s testkit
# LibKa0s/Env.lua, OptionsIdList.lua, Slash.lua, SlashParse.lua, WidgetsAutocomplete.lua,
# WidgetsLineChart.lua; testkit/README.md, framework.lua, inventory.lua, secrets.lua (new)
```

## 3c. Per-file minors (the files that moved)

| File | Major | old | new |
|---|---|---|---|
| `Env.lua` | `LibKa0s-Env-1.0` | 1 | 2 |
| `OptionsIdList.lua` | `LibKa0s-Options-1.0` | 3 | 4 |
| `Slash.lua` | `LibKa0s-Slash-1.0` | 19 | 20 |
| `SlashParse.lua` | `LibKa0s-Slash-1.0` | 1 | 2 |
| `WidgetsLineChart.lua` | `LibKa0s-Widgets-1.0` | 2 | 3 |
| `WidgetsAutocomplete.lua` | `LibKa0s-Widgets-1.0` | 1 | 2 |
| every other file (28) | | as v1.70.0 | unchanged |

`LibKa0s.xml` is unchanged: no library file added or removed (fifteen majors, thirty-four files). No
`NEEDS_*` floor rises (the tag's `CHANGELOG.md`, v1.71.0 block).

## 3d. Both diffs, before the copy

`diff -rq --strip-trailing-cr <tag>/LibKa0s libs/LibKa0s` named exactly the six files above;
`diff -rq --strip-trailing-cr <tag>/testkit tests/_kit` named `README.md`, `framework.lua`,
`inventory.lua` and `Only in <tag>/testkit: secrets.lua`. Nothing was only in the addon, so the
copy deletes nothing.

## 3e. Consumption map

```sh
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '^./libs/' | grep -v '^./tests/'
```

Core (`core/CoreSetup.lua:41`), Env (`core/EnvSetup.lua:60`), Media (`core/MediaSetup.lua:42`),
Lifecycle (`core/LifecycleSetup.lua:67`), DebugLog (`core/DebugLogSetup.lua:69`,
`settings/Panel.lua:84`), Launcher (`core/LauncherSetup.lua:98`), Slash (`settings/Slash.lua:158`,
`settings/Schema.lua:911`), Schema (`settings/Schema.lua:802`), Options
(`settings/OptionsSetup.lua:17`). Unchanged from v1.70.0. Widgets, Item and Pool are not consumed by
host code.

## 3f. Kit revision

```sh
grep -n 'Kit.VERSION =' <tag>/testkit/framework.lua <v1.70.0>/testkit/framework.lua
# <tag>:20:Kit.VERSION = 38      <v1.70.0>:20:Kit.VERSION = 37
```

Kit revision **37 -> 38**. Both payloads come from the one tag in this commit, so the pairing rule
holds by construction. Revision 38 changes the `--list` Totals (LK-01): a declared skip leaves the
count rows for a `| Skipped | N |` row and **Total counts only the cases that run**. It also adds
`testkit/secrets.lua` (`Kit.secret`, LK-02), loaded by `framework.lua` and opt-in; `mock_base.lua`
is untouched and nothing installs `issecretvalue` by default.

## 3g. Contract delta

Moved majors (3c) intersected with consumed majors (3e): **Env**, **Options**, **Slash**.

- **Env minor 2** drops the dead bare-global `GetAddOnMetadata` rung: `Env.GetAddOnMetadata` answers
  `C_AddOns.GetAddOnMetadata` or `nil`. `core/EnvSetup.lua:72` calls it; every supported client has
  `C_AddOns`, so a live host sees no difference.
- **OptionsIdList minor 4** drops the dead bare-global `IsAddOnLoaded` rung of `O.IdList`'s help-art
  guard. PrettyChat draws no id list.
- **Slash key 20.2**: `SlashParse` minor 2's `ParseValue` refuses `nan`, `inf`, `-inf` and an
  overflowing literal on a number row with the existing `ERR_NUMBER` reason; `Slash.lua` 20 changes
  one comment. A `/pc set` of a non-finite number is now refused where it was stored. No PrettyChat
  test pinned the old acceptance.

Each is a bug fix under an unmoved signature, and none changes a contract this addon relies on.
Widgets moved (LK-03, LK-04) and is not consumed. `grep -rn '__Attach[A-Za-z]*' . --include='*.lua'
--exclude-dir=libs --exclude-dir=_kit` is empty.

**Blockers:** none.

## 3h. Tags vendored and never recorded

Before this item the AUDIT.md two-listing check printed `v1.69.0` and `v1.70.0`. With the span
folder written, it prints nothing.
