local consts = {}

consts.terminal = "alacritty"
consts.editor = os.getenv("EDITOR") or "nano"
consts.editor_cmd = consts.terminal .. " -e " .. consts.editor

consts.modkey = "Mod4"
consts.altkey = "Mod1"

return consts
