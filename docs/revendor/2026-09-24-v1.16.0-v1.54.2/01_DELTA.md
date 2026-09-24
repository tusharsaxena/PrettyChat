Delta: LibKa0s v1.16.0 -> v1.54.2 (span: v1.16.0 v1.18.0 v1.18.1 v1.19.0 v1.23.0 v1.24.0 v1.25.0 v1.26.0 v1.27.0 v1.28.0 v1.29.0 v1.35.0 v1.36.0 v1.36.1 v1.36.2 v1.37.0 v1.38.0 v1.39.0 v1.42.0 v1.43.0 v1.44.0 v1.45.0 v1.46.1 v1.47.0 v1.50.0 v1.51.0 v1.52.0 v1.53.0 v1.54.2)

# 01 — Delta: the consolidated span v1.16.0 to v1.54.2

Written 2026-09-24 as item PC-25 of the 2026-09-23 review and standards-audit remediation plan,
branch `feat/2026-09-23-review-audit-remediation`. It resolves finding PRETTYCHAT-A-01: LibKa0s
tags this addon vendored between 2026-08-25 and 2026-09-22 have no bundle naming them. This is a
back-fill record in the consolidated span shape `audit-review-history` defines, not a re-run of
the re-vendor procedure. Nothing was copied, and `libs/LibKa0s/` and `tests/_kit/` did not move.

## The true previous base

The tag vendored immediately before the span is **v1.15.0** (`f625c57`, 2026-08-25), recorded by
the bare-dated bundle `docs/revendor/2026-08-25/`. Line 1 names the span's first tag, v1.16.0,
because the span grammar fixes it that way: it is the span, not a base-and-new pair.

The span is not contiguous with the rest of the store. Six tags inside its range already have a
bundle and are left off line 1: v1.30.0 (`2026-09-12/`) and v1.31.0, v1.32.0, v1.33.0 and v1.34.0
(their own single-tag folders). v1.55.0 (`2026-09-23-v1.55.0/`, whose base is v1.54.2) and v1.56.0
(`2026-09-23-v1.56.0/`) follow the span. The library tags in the range this addon never vendored
(v1.17.0, v1.20.0, v1.21.0, v1.22.0, v1.40.0, v1.41.0, v1.46.0, v1.48.0, v1.48.1, v1.49.0,
v1.49.1, v1.54.0, v1.54.1) do not belong on the line either: the addon never carried them.

## The two listings

The `AUDIT.md` re-vendor check (WowAddonStandards v2.65.0), with the provenance-roll walk that
`/wow-addon:revendor-libka0s` Step 3h adds, run before this bundle existed:

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)   # 2026-08-25

tag_at() {
  git show "$1:CLAUDE.md" 2>/dev/null |
    grep -oE 'Bundles \[LibKa0s\]\([^)]*\) v[0-9]+\.[0-9]+\.[0-9]+' |
    grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1
}
{ git log --since="$horizon 00:00" --format=%H -- libs/LibKa0s tests/_kit
  git log --since="$horizon 00:00" --format=%H -- CLAUDE.md | while read -r c; do
    [ "$(tag_at "$c")" != "$(tag_at "$c^")" ] && echo "$c"
  done
} | while read -r c; do tag_at "$c"; done | sed '/^$/d' | sort -uV > vendored.txt

for b in docs/revendor/*/; do
  n=$(basename "$b" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | wc -l)
  if [ "$n" -ge 2 ]; then
    head -1 "$b/01_DELTA.md" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+'
  else
    t=$(basename "$b" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    [ -n "$t" ] || t=$(head -1 "$b/01_DELTA.md" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1)
    [ -n "$t" ] && echo "$t"
  fi
done | sort -uV > recorded.txt

grep -vxF -f recorded.txt vendored.txt
```

- Vendored (37): v1.15.0, v1.16.0, v1.18.0, v1.18.1, v1.19.0, v1.23.0, v1.24.0, v1.25.0, v1.26.0,
  v1.27.0, v1.28.0, v1.29.0, v1.30.0, v1.31.0, v1.32.0, v1.33.0, v1.34.0, v1.35.0, v1.36.0,
  v1.36.1, v1.36.2, v1.37.0, v1.38.0, v1.39.0, v1.42.0, v1.43.0, v1.44.0, v1.45.0, v1.46.1,
  v1.47.0, v1.50.0, v1.51.0, v1.52.0, v1.53.0, v1.54.2, v1.55.0, v1.56.0.
- Recorded before this bundle (8): v1.15.0, v1.30.0, v1.31.0, v1.32.0, v1.33.0, v1.34.0, v1.55.0,
  v1.56.0 (v1.31.0 was vendored twice, `8a2fdf9` and `44b2b38`, and has one bundle).
- Vendored minus recorded (29): the tags on line 1. The walk over the payload folders alone and
  the walk with the provenance rolls added give the same 29; no tag here arrived as a roll alone.

## The vendoring commits

Each tag is read off the `Bundles [LibKa0s](…) vX.Y.Z` provenance line in root `CLAUDE.md` at
that commit, from `git log --format='%h %ad %s' --date=short -- libs/LibKa0s tests/_kit`.

| Tag | Vendoring commit | Date | Subject |
|---|---|---|---|
| v1.16.0 | `e6daef5` | 2026-08-25 | Re-vendor LibKa0s v1.16.0 |
| v1.18.0 | `942f254` | 2026-08-26 | Adopt options-ui-§12: ResetAll is a profile reset, and wire the profile callbacks it needs |
| v1.18.1 | `e9ef943` | 2026-08-26 | Re-vendor LibKa0s v1.18.1: the landing logo stops pooling its texture |
| v1.19.0 | `6910b7d` | 2026-08-27 | Carry LibKa0s v1.19.0 |
| v1.23.0 | `050403e` | 2026-09-01 | Re-vendor LibKa0s v1.23.0: the tabbed page and the page banner |
| v1.24.0 | `8ee771a` | 2026-09-02 | feat(settings): a nested strip per rewritten string, and Test to the debug console |
| v1.25.0 | `7603ca3` | 2026-09-03 | feat(settings): a string LIST beside the editor, and Test beside the reset |
| v1.26.0 | `8adad23` | 2026-09-08 | M3-05: re-vendor LibKa0s v1.26.0 |
| v1.27.0 | `b302d0e` | 2026-09-08 | M4-01: adopt LibKa0s v1.27.0, and wire the gate that came with it |
| v1.28.0 | `6176f29` | 2026-09-09 | re-vendor LibKa0s v1.28.0 — the perf usage block renders correctly |
| v1.29.0 | `7880df2` | 2026-09-09 | re-vendor LibKa0s v1.29.0 — the JSON dump folds into the report step |
| v1.35.0 | `7ec65aa` | 2026-09-14 | Re-vendor LibKa0s v1.35.0 (Options 18.16.5.3, kit 20) |
| v1.36.0 | `1372234` | 2026-09-15 | Re-vendor LibKa0s v1.36.0 |
| v1.36.1 | `eb16212` | 2026-09-15 | Re-vendor LibKa0s v1.36.1: fix pooled CheckBox gold-fill leak |
| v1.36.2 | `804f164` | 2026-09-15 | Re-vendor LibKa0s v1.36.2: drop grid-cell yellow fill, ASCII-only strings |
| v1.37.0 | `3e7bd69` | 2026-09-16 | Re-vendor LibKa0s v1.37.0 |
| v1.38.0 | `78f5ec7` | 2026-09-16 | Re-vendor LibKa0s v1.38.0: a bare /pc opens the settings panel |
| v1.39.0 | `ed46f80` | 2026-09-16 | Re-vendor LibKa0s v1.39.0: the Launcher major and the minimap seam |
| v1.42.0 | `5232c3d` | 2026-09-17 | Disabling the addon stands it down, and a perf run takes the same latch |
| v1.43.0 | `511c10a` | 2026-09-17 | Re-vendor LibKa0s v1.43.0: kit revision 23 bounds every run and stops holding built instances |
| v1.44.0 | `f9b811a` | 2026-09-19 | Re-vendor LibKa0s v1.44.0 |
| v1.45.0 | `b1bd810` | 2026-09-19 | Re-vendor LibKa0s v1.45.0 |
| v1.46.1 | `5bbe28e` | 2026-09-19 | Re-vendor LibKa0s v1.46.1 |
| v1.47.0 | `94fbc7d` | 2026-09-20 | Re-vendor LibKa0s v1.47.0 |
| v1.50.0 | `0e3ec45` | 2026-09-21 | Re-vendor LibKa0s v1.50.0 |
| v1.51.0 | `cf1d93f` | 2026-09-22 | Re-vendor LibKa0s v1.51.0 |
| v1.52.0 | `2fe86c9` | 2026-09-22 | Re-vendor LibKa0s v1.52.0 |
| v1.53.0 | `5e6ff6c` | 2026-09-22 | Re-vendor LibKa0s v1.53.0 |
| v1.54.2 | `8421342` | 2026-09-22 | Adopt the kit's US-English gate, and delete the copy this repo was keeping |

`511c10a` carried v1.43.0 for kit revision 23 alone: the library payload is byte-identical to
v1.42.0 there. `8421342` carried v1.54.2 the same way, through `tests/_kit/` and `CLAUDE.md`:
kit revision 24 changed no library file, so `libs/LibKa0s/` is byte-identical to v1.53.0 there.

Each commit's own message is the record of what that re-vendor moved and adopted; this bundle
does not restate the per-file minors, which were never captured at the time. The earlier frozen
bundles are not edited: this folder adds the missing record beside them.
