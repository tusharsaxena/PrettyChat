Delta: LibKa0s v1.64.0 -> v1.65.0 (span: v1.64.0 v1.65.0)

# The consolidated span v1.64.0 to v1.65.0 (PrettyChat)

Written 2026-10-01 beside `2026-10-01-v1.66.0/`, by item GI-PC-RV, because the re-vendor skill's 3h
listing named two tags this addon vendored with no bundle of their own. Records only.

```sh
horizon=$(ls -1 docs/revendor | sort | head -1 | cut -c1-10)   # 2026-08-25
# the 3h walk over libs/LibKa0s, tests/_kit and the CLAUDE.md commits that roll the line,
# then: grep -vxF -f recorded.txt vendored.txt
v1.64.0
v1.65.0
```

```sh
git log --format='%h %s' -- CLAUDE.md | head -2
7548ece DG-PC-01: re-vendor LibKa0s v1.65.0 (Slash 18, DebugLog 18.2.1 with DebugLogGates 1, Options 27, Launcher 5, Lifecycle 3; kit revision 34)
fa4f9fd DL-PC-01: re-vendor LibKa0s v1.64.0 (kit revision 33), resize smoke checks
git log --format='%h %s' -3 -- libs/LibKa0s
7548ece DG-PC-01: re-vendor LibKa0s v1.65.0 (...)
49edc8b DL-PC-03: re-vendor the final LibKa0s v1.64.0 (DebugLog 17, DebugLogDiagnostics 2, kit revision 34); diagnostics turns logging on
fa4f9fd DL-PC-01: re-vendor LibKa0s v1.64.0 (kit revision 33), resize smoke checks
```

Both re-vendors were carried by plans recorded in Ka0sAddonsCommonTasks
(`docs/2026-09-30-DEBUG_LOGS_AND_RESIZABLE_WINDOWS/` and `docs/2026-09-30-LIBKA0S_DEBUG_GAPS/`), whose own
records hold the deliberation; this folder only closes the store's gap.
