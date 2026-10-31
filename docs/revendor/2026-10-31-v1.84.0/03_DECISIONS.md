# LibKa0s v1.83.0 -> v1.84.0: decisions (PrettyChat)

Source: the workflow dispatch that launched this re-vendor, not the bundle. Its argument to
`/dev-copilot:wow-revendor-libka0s` read "multi-repo run, no interview; decline candidates in bundle,
no issues filed". Step 7 of Ka0sAddonsCommonTasks
`docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md` orders the re-vendor and says only "Close
no issue before merge"; it names no adoption for this addon and is silent on interviews and declines.
The bundle holds no owner ruling on these declines, and the skill's default is to file one as an issue, so
none of the five below is tracked outside this file. "The brief" in the table means that dispatch.

| Candidate | Decision | Why |
|---|---|---|
| `opts.beforeGroup`, `opts.afterSubgroup` | declined | Outside the brief; no page needs them |
| `note` row | declined | Outside the brief; no schema row wants it |
| `O.PositionBlock` | declined | Outside the brief; the addon is frameless. The stub carries it |
| `O.PageBanner{ acts }` | declined | Outside the brief; no page needs an act |
| `LibKa0s-Charts-1.0` | declined | Outside the brief; nothing here draws a chart |
