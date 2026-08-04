# Automated test results

<!-- The newest run is prepended by tests/_kit/run-automated-tests.sh. -->
<!-- This file is OVERWRITTEN IN PLACE — the git history of this one path is the trend line. -->

One row per run. The frozen evidence for each is in the dated folder beside this file;
the analysis of a given run is its `ANALYSIS.md`.

| Run | Version | Lint w/e | Tests | Perf | CCN warn | Max CCN | Verdict |
|---|---|---|---|---|---|---|---|
| [`20260804-114913`](20260804-114913/) | 1.4.0 | 0/0 | 255/255 | skip | 2 | 23 | **green** |

## Complexity watch list

Current state as of [`20260804-114913`](20260804-114913/) — not that run's diff.
Every function `lizard` warned on and every file in `layout-§1`'s 1000–1500 on-notice band,
each with a one-line disposition.

| `PrettyChat:Test` | 23 | `modules/Override.lua` | **Peel next.** Partly relieved by review finding **F-007**, whose shared index deletes the inner collect-and-sort outright. |
| `build` | 18 | `tests/loader.lua` | **Accepted, and expected to disappear** — tracked as **PC-51**, deleted when `LIBKA0S-01` lands. |

**Files in the 1000–1500 band:** None.

**Over the 1500 cap:** `GlobalStrings/GlobalStrings.lua` (23,842) — the unshipped Blizzard source dump. Not loaded by any TOC and excluded by `.pkgmeta:21`; it is the build-time input the splitter reads. The 26 shipped chunks are all ~882 lines, deliberately under the on-notice band (PC-49, closed this session).
