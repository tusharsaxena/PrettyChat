# Analysis — GlobalStrings re-validation, WoW Forever 1.60.1.70938 (2026-11-15)

Hand-written. The first run of `/dev-copilot:validate-seeds PrettyChat forever`
(Ka0sAddonsCommonTasks#1), against wago.tools product `wowf`, build `1.60.1.70938`, the live WoW
Forever build on 2026-11-15.

## What was checked

Forever has no copy of its own. `docs/ARCHITECTURE.md` ("Per-client features") records that one
format-string list serves both clients. That was measured on 2026-11-08 between
Ketho/BlizzardInterfaceResources' `forever` (1.60.1.70532) and `live` (12.1.5.70448) dumps. This run
re-measures it from the client's own DB2:

- **All 79 keys `defaults/Defaults.lua` depends on are FrameXML strings on the Forever build.**
  Each one's decoded text is identical to the Retail copy's, which is Retail 12.1.5.70783 after
  this session's Retail run. So the defaults' conversion sequences hold on Forever unchanged, and
  the measurement stands, now against Forever's own build and from its own product.
- **0 flags, so nothing to rule.**

The Forever table is not a reworded copy of Retail's overall. It has 25,945 FrameXML rows to Retail's
24,732, it says *Account Bank* where Retail says *Warband Bank*, and it carries vanilla-era strings
(training points, pet loyalty) that Retail dropped. None of those differences touches a key the
addon depends on. That is why the flavor checks the dependent keys only and builds no second copy.

## What was applied

Nothing is written for Forever. `apply` confirmed that nothing was unruled and reported that there
is no copy to regenerate. `docs/ARCHITECTURE.md`'s measurement now names this bundle.

## What a later run should re-check

- **The reopen trigger.** A dependent key `gone` or `reworded` on Forever is the trigger
  `docs/ARCHITECTURE.md` names for a second list or a client branch. Rule it under
  `docs/validate-seeds.md`'s Forever nuances before anything else.
- **Run Retail first.** The reference is the Retail copy. A Forever run in a session that also runs
  Retail should follow the Retail apply, so the two compare like for like.
