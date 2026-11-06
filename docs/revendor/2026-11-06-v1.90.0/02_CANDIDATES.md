# Candidates

Range `v1.89.0..v1.90.0` (`git -C ../LibKa0s log --oneline v1.89.0..v1.90.0`), read from the tag's `CHANGELOG.md` block v1.90.0 and the API documents of the majors that moved.

## A. Delivered on the re-vendor

- **Core minor 16, Widgets minor 24, WidgetsAutocomplete minor 8, SkinPaint minor 19, SkinPaintExtras minor 18** (`CHANGELOG.md`, v1.90.0, "One physical pixel (`SF1-L1`)"; `docs/api/Core/version-16-docs.md:23-25,83`; `docs/api/Widgets/version-24.5.12.6.8.5-docs.md`): every Widgets edge of 1 UI unit is one physical pixel at any UI scale. No member moves. Pretty Chat has no Widgets lookup of its own, so the change reaches only the library-drawn surfaces it shows, such as the debug console and its copy window.
- **OptionsAppearance minor 7** (`CHANGELOG.md`, v1.90.0, "A copy leaves a host's Scope alone (`SF1-L2`)"; `docs/api/Options/version-37.4.44.2.7.2.9.15.2.4.19.13.5.5.7.7.11.1.1.4-docs.md:20-26`): `lib.__copySkinTo` still writes a Scope to every owner that does not register `keepScope`, so for this addon an Apply to all behaves as before.

## B. Host change required

- **Skin 17 `RegisterOwner(owner, { keepScope = true })`** (`docs/api/Skin/version-17.1.27.8.19.18.17.4.9-docs.md:19-21`; `CHANGELOG.md` v1.90.0). Not applicable. Only a host whose Scope is a documented deviation owes it (the Options document, line 26). Pretty Chat registers at `core/SkinSetup.lua:512` and documents no Scope deviation. The SF1 ruling gives it to the Skin Tester alone (`SF1-ST`). If it were ever adopted, the change would be additive.

## C. Whole-module adoption

None new in this range: no new major ships (`LibKa0s.xml` lists no new file). IconBrowser stays settled, as recorded in `2026-11-06-v1.89.0/03_DECISIONS.md`.

No candidate falls outside the SF1 decisions.
