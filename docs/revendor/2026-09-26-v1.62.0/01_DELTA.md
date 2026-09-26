# LibKa0s v1.61.0 -> v1.62.0: the delta (PrettyChat)

Copied from the local tag `v1.62.0` (commit `5dc9f5d`), never from a working tree.

## libs/LibKa0s (`diff -rq --strip-trailing-cr`, before the copy)

```
Files <tag>/LibKa0s/LibKa0s.xml and libs/LibKa0s/LibKa0s.xml differ
Files <tag>/LibKa0s/Options.lua and libs/LibKa0s/Options.lua differ
Only in <tag>/LibKa0s: OptionsCombat.lua
Only in <tag>/LibKa0s: OptionsIdList.lua
Only in <tag>/LibKa0s: OptionsIds.lua
Only in <tag>/LibKa0s: OptionsRegistry.lua
Files <tag>/LibKa0s/OptionsTabs.lua and libs/LibKa0s/OptionsTabs.lua differ
Files <tag>/LibKa0s/OptionsWidgets.lua and libs/LibKa0s/OptionsWidgets.lua differ
```

- `Options.lua`: minor 25 -> 26. The page registry and its combat park move out to `OptionsRegistry.lua`.
- `OptionsWidgets.lua`: minor 31 -> 32. The id surface moves out to `OptionsIds.lua` and `OptionsIdList.lua`
  (LibKa0s #32); the file calls both where the id members used to be defined.
- `OptionsTabs.lua`: minor 5 -> 6. The combat lock's page chrome moves out to `OptionsCombat.lua`.
- New files, each minor 1: `OptionsRegistry.lua`, `OptionsIds.lua`, `OptionsIdList.lua`, `OptionsCombat.lua`.
- `LibKa0s.xml`: loads the four new files, each after the file it was peeled from.
- The Options major key moves from `25.31.5.7.4.1` to `26.1.32.1.1.6.1.7.4.1`. No member, descriptor field or
  row field changes, and no `NEEDS_*` floor rises.

## tests/_kit

Kit revision 27 -> 31.

```
Files <tag>/testkit/README.md and tests/_kit/README.md differ
Files <tag>/testkit/framework.lua and tests/_kit/framework.lua differ
Only in <tag>/testkit: inventory.lua
Only in <tag>/testkit: prose_coverage.lua
Only in <tag>/testkit: prose_selftests.lua
Files <tag>/testkit/run-automated-tests.sh and tests/_kit/run-automated-tests.sh differ
Files <tag>/testkit/test_layout_cap.lua and tests/_kit/test_layout_cap.lua differ
Files <tag>/testkit/test_prose.lua and tests/_kit/test_prose.lua differ
```

- The suite inventory peels out of `framework.lua` into `inventory.lua` (revision 28), and `test_prose.lua`
  splits into `prose_coverage.lua` and `prose_selftests.lua` (revision 29).
- The battery runner prints `None.` under an empty complexity watch-list table (revision 30, ATS-20), and
  the band table leaves out `Kit.layoutCap.exempt`'s generated files (revision 31, ATS-21), which drops
  PrettyChat's `GlobalStrings/GlobalStrings.lua` from the band table.
