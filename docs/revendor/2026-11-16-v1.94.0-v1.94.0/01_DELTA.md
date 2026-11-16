Delta: LibKa0s v1.94.0 -> v1.94.0 (span: v1.94.0)

Written 2026-11-16 by RV-PC, beside `../2026-11-16-v1.105.0/`. A records-only back-fill: the one tag this addon vendored without a bundle. No code, library or kit file moved because of it.

## Listing

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)    # 2026-08-25
# the audit's walk over libs/LibKa0s and tests/_kit, plus the CLAUDE.md commits that roll the line
# -> vendored.txt; every docs/revendor/ bundle's tags -> recorded.txt
grep -vxF -f recorded.txt vendored.txt
```

Output:

```
v1.94.0
```

(The full script is revendor-libka0s Step 3h.)

v1.94.0 (library tag 5e71662, commit 2d2be05) was vendored by `04d48ba` (W2-PC-01: Port to Retail + Forever: two-number TOC, LibKa0s v1.94.0, default skin per client), base v1.93.0, under the WoW Forever port, whose run kept no revendor bundle. Minors that moved: Compat 3 -> 4, Skin 17 -> 18; kit unchanged at 53.
