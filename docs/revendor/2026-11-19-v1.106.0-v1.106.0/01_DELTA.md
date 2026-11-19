Delta: LibKa0s v1.106.0 -> v1.106.0 (span: v1.106.0)

Written 2026-11-19 by AF-RV-PC, beside `../2026-11-19-v1.107.0/`. A records-only back-fill: the one tag this addon vendored without a bundle. No code, library or kit file moved because of it.

## Listing

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)    # 2026-08-25
# the audit's walk over libs/LibKa0s and tests/_kit, plus the CLAUDE.md commits that roll the line
# -> vendored.txt; every docs/revendor/ bundle's tags -> recorded.txt
grep -vxF -f recorded.txt vendored.txt
```

Output:

```
v1.106.0
```

(The full script is revendor-libka0s Step 3h.)

v1.106.0 (library tag 7a2ff73, commit ee86fab) was vendored by `1bc919c` (Re-vendor LibKa0s v1.106.0 (Widgets minor 28: the HUD dock guards its measurements, RangeMaster#17)), base v1.105.0, a copy-only re-vendor outside any run bundle. Minors that moved: Widgets 27 -> 28; kit unchanged at 57.
