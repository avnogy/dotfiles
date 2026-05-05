local awful = require("awful")
local gfs = require("gears.filesystem")
local naughty = require("naughty")
local consts = require("consts")
local M = {}

local MODEL = "coder"
local response_file = gfs.get_cache_dir() .. "llm-response.md"

local function trim(text)
	return text and text:match("^%s*(.-)%s*$") or ""
end

local function notify_error(message)
	naughty.notify({
		title = "LLM prompt error",
		text = message,
		urgency = "critical",
		timeout = 0,
	})
end

function M.prompt()
	local prompt_screen = awful.screen.focused()
	if not prompt_screen or not prompt_screen.mypromptbox or not prompt_screen.mypromptbox.widget then
		notify_error("No prompt box is available on the focused screen.")
		return
	end

	naughty.notify({ title = "LLM prompt", text = "Enter prompt in the top bar.", urgency = "low", timeout = 1.5 })

	awful.prompt.run({
		prompt = "LLM: ",
		textbox = prompt_screen.mypromptbox.widget,
		exe_callback = function(input)
			local prompt = trim(input)
			if prompt == "" then
				return
			end

			naughty.notify({ title = "LLM prompt", text = "Processing...", urgency = "low", timeout = 1.5 })

			awful.spawn.easy_async(
				{ "llm", "-m", MODEL, prompt },
				function(stdout, stderr, reason, exit_code)
					local output = trim(stdout)
					local err = trim(stderr)

					if reason ~= "exit" or exit_code ~= 0 then
						notify_error(err ~= "" and err or "`llm` command failed.")
						return
					end

					if output == "" then
						notify_error(err ~= "" and err or "The model returned no output.")
						return
					end

					gfs.make_directories(gfs.get_cache_dir())
					local file = io.open(response_file, "w")
					if file then
						file:write(prompt .. "\n___\n" .. output)
						file:close()
						awful.spawn({ consts.terminal, "-e", "glow", "-p", response_file })
						return
					end

					notify_error("Failed to write response file.")
				end
			)
		end,
	})
end

return M
