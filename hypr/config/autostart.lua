-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/

local programs = require("config.programs")

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
hl.on("hyprland.start", function ()
    -- hl.exec_cmd(programs.terminal)
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("qs")
end)
