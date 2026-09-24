local _, NS = ...

-- core/State.lua — session-only runtime state. Nothing here is persisted to SavedVariables. The debug
-- flag (NS.State.debug) defaults off and resets on every /reload and fresh login
-- (Ka0s standard, debug-logging-§5).
NS.State = NS.State or { debug = false }
