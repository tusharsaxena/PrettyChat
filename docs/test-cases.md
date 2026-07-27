# Test Cases

_Generated — do not hand-edit. Regenerate with `lua tests/run.lua --list > docs/test-cases.md`._

### test_compat.lua (8)

- Compat.GetAddOnMetadata is published on the namespace
- reads through the C_AddOns namespace on a modern client
- prefers C_AddOns over the legacy global when both exist
- falls back to the legacy _G global on an older client
- falls back when C_AddOns exists without the getter
- returns nil (never errors) when neither surface exists
- passes the addon name and key straight through
- ns.version is seeded from the TOC through the shim

### test_constants.lua (8)

- every colour escape is a well-formed |cRRGGBB code
- the slash-commands-§5 mandated palette is exact
- the brand colours are distinct from the mandated palette
- the [PC] chat tag is cyan-wrapped and trailing-spaced
- layout constants are positive numbers
- the header block leaves room between title and divider
- the button-pair width stays under half so the pair shares one row
- FONT_MONO points inside the addon's own media folder

### test_util.lua (7)

- SafeToString renders scalars and nil verbatim
- SafeToString substitutes <secret> for a value table.concat rejects
- IsConcatSafe probes concatenability via table.concat, not ..
- IsConcatSafe never raises on the value it is probing
- trim strips surrounding whitespace and is nil-safe
- trim keeps interior whitespace intact
- note and cmd wrap text in the documented slash colours

### test_locale.lua (7)

- ns.L is published as a table
- an unknown key falls back to itself verbatim
- every seeded manifest entry is an identity mapping
- the scan found the L call sites it is meant to guard
- every localized call site is in the enUS manifest
- the manifest carries no entry that nothing references
- every slash-command description is localized

### test_defaults.lua (14)

- the defaults table is non-empty and carries real entries
- every defaults category appears in CATEGORY_ORDER
- every ordered category except the virtual General has backing data
- CATEGORY_ORDER lists General first and has no duplicates
- every category declares a boolean enabled flag and a strings table
- every key is a Blizzard-style UPPERCASE global name
- every entry carries a non-empty label and default
- labels are unique within their category
- every default format string renders with sample arguments
- no default carries a raw newline or tab
- cross-registered globals are identified with their real categories
- the schema builds exactly the rows the defaults imply
- every string registration has both of its schema rows
- each format row's schema default is the defaults-table default

### test_schema.lua (21)

- resolves known setting paths and returns nil for unknown ones
- resolves categories case-insensitively and by prefix
- master toggle round-trips through the single write path
- Set on a format pushes the override to _G via ApplyStrings
- re-setting a format to its default auto-clears the stored override
- Set on an unknown path is a no-op returning false
- load-time schema path validation resolved every path
- the four row kinds are built with their documented shape
- exactly one addon-wide row exists, under the virtual General category
- RowsByCategory returns only that category, in registration order
- a cross-registered global carries one format row per category
- an exact category name beats any prefix interpretation
- an ambiguous prefix resolves to nothing rather than guessing
- a non-string or empty category name resolves to nothing
- FormatValue renders nil, bools, strings and numbers
- Set returns true and coerces bool rows to real booleans
- row.set closures are pure DB writes with no side effects
- NotifyPanelChange calls only the affected category's refresher
- a General or unscoped change refreshes every registered page
- a refresher that errors cannot break the write path
- an unregistered category is a silent no-op, not an error

### test_render.lua (12)

- renders basic %s + %d and collapses %% escapes
- positional %n$s formats degrade gracefully under stock Lua
- empty or nil format returns nil
- malformed conversion surfaces as nil + error string
- each conversion class gets a correctly typed sample argument
- upper-case conversions are typed from their lower-case form
- flags, width and precision are parsed, not mistaken for arguments
- multiple conversions are filled in order
- a format with no conversions renders as itself
- %% is not mistaken for a conversion next to a real one
- a non-string format is rejected like an empty one
- a real Blizzard-style default renders without error

### test_apply.lua (10)

- override is applied by default when all three layers are on
- master toggle off restores original, back on reapplies
- category toggle off restores original, back on reapplies
- per-string toggle off restores original, back on reapplies
- the cascade is a conjunction — every layer must be on to apply
- a disabled category leaves other categories applied
- a string with no snapshot is left alone rather than blanked
- repeated applies are idempotent across the whole surface
- ResetString clears both the custom format and the per-string disable
- cross-registered global resolves to the last CATEGORY_ORDER registrant, stably

### test_override.lua (17)

- GetStringValue falls back to the defaults table until overridden
- IsAddonEnabled treats an absent flag as default-true
- IsCategoryEnabled falls back to the category's shipped default
- IsStringEnabled is true unless the string is explicitly disabled
- EnsureCategoryDB creates the sub-table once and reuses it
- ApplyStrings returns applied/restored counts that sum to the surface
- a disabled category shifts its own strings from applied to restored
- ResetCategory drops the whole category table
- ResetCategory('General') clears only the master flag
- ResetAll clears the master flag and every category at once
- Test prints a header, a per-category block, and a counted footer
- Test previews the Blizzard original from the OnEnable snapshot
- a formatstring filter narrows the report to one string
- a filter that matches nothing says so instead of printing an empty report
- Test warns when the addon is disabled but still previews
- an unrenderable override is reported as an error line, not a crash
- every Test line routes through the [PC] printer

### test_database.lua (10)

- ns.Database and the db.global namespace exist
- a fresh DB is stamped at the current schema version
- re-running migrations is idempotent
- RunMigrations tolerates a db without a .global namespace
- an older DB is upgraded to the current version
- the schema version is a positive integer the defaults start below
- a DB with no recorded version is treated as version 0
- RunMigrations tolerates nil and a db without .global
- the runner stamps the current version even with no steps to run
- migrating emits no debug noise when nothing ran

### test_lifecycle.lua (12)

- the addon object and the bootstrap namespace are one table
- OnInitialize provisions both AceDB namespaces
- OnInitialize registers /pc and its /prettychat alias
- OnEnable snapshots a Blizzard original for every registered global
- OnEnable applies the overrides so live chat is rewritten at load
- ns.Print prepends the cyan [PC] tag to every line
- ns.Print neutralises a value the concat probe rejects
- OpenConfig refuses during combat without touching the Settings API
- OpenConfig opens the registered category out of combat
- the auto-expand fallback notice is printed once per session
- OpenConfig reports a category Blizzard refused to open
- OpenConfig is a silent no-op when the Settings API is unavailable

### test_debuglog.lua (25)

- FONT_MONO points at the vendored JetBrainsMono TTF
- pure line formatters render plain and coloured lines
- /pc debug on|off drives the session flag through the SetEnabled seam
- colour-coded chat ack: ON green, OFF red, via [PC]
- enable emits the [Init] session summary after the bracket
- bare /pc debug toggles the window without changing the flag
- header toggle click flips state through the same seam
- ns.Debug is a no-op when off and appends one line when on
- Schema.Set emits one [Set] line with no separate [Apply] echo
- the console line and the copy buffer describe the same event
- the plain buffer never carries colour escapes of its own
- ns.Debug neutralises a protected value inside its format args
- ns.Debug passes a bare message through without formatting it
- ns.Debug keeps argument types so numeric conversions still work
- the buffer is capped and drops its oldest lines first
- Clear empties both the buffer and the console view
- the line counter reports buffered lines against the cap
- the Copy window is filled with the plain-text buffer
- both console windows register for Esc-to-close
- Show, Hide and Toggle drive the window's visibility
- IsShown is false before the console has ever been built
- the header label tracks the session flag in the §5 state colours
- SessionSummary self-identifies the build, schema and profile
- disabling logging still writes its closing bracket line
- ResetAll emits one [Reset] summary carrying apply counts

### test_slash.lua (39)

- Schema.FormatValue formats bools and doubles pipes in strings
- ns.Print emits the cyan [PC] tag (reclaimed after the AceConsole embed)
- a bare /pc prints the help index
- /pc help lists every command with its description
- an unknown verb says so and then prints the help index
- the verb is lower-cased but the argument keeps its case
- extra whitespace around the verb is tolerated
- /pc version prints the tagged version line
- /pc config routes to the combat-gated panel opener
- /pc get echoes the gold-key/white-value FormatKV line
- /pc get with no path prints usage
- /pc get on an unknown path reports it as not found
- /pc get doubles the pipes in a format string so escapes read as text
- /pc set accepts every documented truthy bool spelling
- /pc set accepts every documented falsy bool spelling
- /pc set rejects an unparseable bool without touching the value
- /pc set stores a format string and echoes the stored value
- /pc set echoes the value the DB actually kept, not the input
- /pc set with no path, and with no value, both print usage
- /pc set on an unknown path reports it as not found
- /pc list prints the green header and azure category groups
- /pc list emits every schema row exactly once
- /pc list category lists the category names alphabetically
- /pc list formatstring lists every Category.GLOBALNAME pair
- /pc list <Category> narrows to that category's rows
- /pc list resolves a category case-insensitively and by prefix
- /pc list on an unknown category lists the valid ones
- /pc reset <Category> resets it and confirms
- /pc reset with no argument prints usage and the valid categories
- /pc reset on an unknown category changes nothing
- /pc resetall clears every override and confirms
- /pc test routes every line through the [PC] printer
- /pc test and /pc test all preview the whole surface
- /pc test category resolves the name and narrows the report
- /pc test formatstring upper-cases the name before matching
- /pc test surfaces usage for each malformed filter
- /pc test rejects unknown filter values by name
- /pc debug rejects an argument that is neither on, off, nor a toggle
- every slash line carries the cyan [PC] tag

### test_panel.lua (30)

- registration builds the parent category and one sub-page per category
- the addon records the category handle OpenConfig needs
- sub-page frames start hidden and unbuilt
- registration is a no-op on a client without the canvas Settings API
- the General page builds its controls on first show
- a second show does not rebuild the page
- the master checkbox is seeded from the schema, not assumed true
- toggling the master checkbox writes through the single Schema path
- the Debug console checkbox drives the window, never the logging flag
- the checkbox re-syncs when the console is opened another way
- the Test button prints the preview report
- Reset all asks for confirmation instead of resetting immediately
- the Defaults button is deferred to first show, not built at registration
- the General page has no Defaults button
- the Defaults button resets its own category only
- a category page builds a toggle plus one block per string
- string blocks are built in sorted global-name order
- each block is the documented three-row 40/60 editor
- the read-only Original row degrades when the reference dump is absent
- the per-string checkbox writes the string's enable path
- the New edit box unescapes || to | before storing
- the Preview box renders the live format with sample arguments
- the Preview box surfaces an unrenderable format instead of blanking
- the per-string Reset button restores both dimensions
- disabling the category greys the per-string controls
- a master-toggle change refreshes every built page, not just its own
- a slash-command write re-syncs the open panel
- a cross-registered string warns about the shared Blizzard global
- the parent page lists every slash command from the same source
- the parent page shows the TOC tagline

## Totals

| Suite | Cases |
|-------|------:|
| test_compat.lua | 8 |
| test_constants.lua | 8 |
| test_util.lua | 7 |
| test_locale.lua | 7 |
| test_defaults.lua | 14 |
| test_schema.lua | 21 |
| test_render.lua | 12 |
| test_apply.lua | 10 |
| test_override.lua | 17 |
| test_database.lua | 10 |
| test_lifecycle.lua | 12 |
| test_debuglog.lua | 25 |
| test_slash.lua | 39 |
| test_panel.lua | 30 |
| **Total** | **220** |
