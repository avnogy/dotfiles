local awful = require("awful")
local naughty = require("naughty")

local M = {}

local LLM_BIN = "/home/avner/.local/bin/llm"
local MODEL = "qwen2.5-coder-7b-instruct"

function M.prompt()
	local prompt_screen = awful.screen.focused()
	if not prompt_screen or not prompt_screen.mypromptbox or not prompt_screen.mypromptbox.widget then
		naughty.notify({
			title = "LLM prompt error",
			text = "No prompt box is available on the focused screen.",
			urgency = "critical",
			timeout = 0,
		})
		return
	end

	naughty.notify({ title = "LLM prompt", text = "Enter prompt in the top bar.", urgency = "low", timeout = 1.5 })

	awful.prompt.run({
		prompt = "LLM: ",
		textbox = prompt_screen.mypromptbox.widget,
		exe_callback = function(input)
			local prompt = input and input:match("^%s*(.-)%s*$") or ""
			if prompt == "" then
				return
			end

			naughty.notify({ title = "LLM prompt", text = "Processing...", urgency = "low", timeout = 1.5 })

			awful.spawn.easy_async(
				{ LLM_BIN, "-m", MODEL, prompt },
				function(stdout, stderr, reason, exit_code)
					local output = stdout and stdout:match("^%s*(.-)%s*$") or ""
					local err = stderr and stderr:match("^%s*(.-)%s*$") or ""

					if reason ~= "exit" or exit_code ~= 0 then
						naughty.notify({
							title = "LLM prompt error",
							text = err ~= "" and err or "Command failed.",
							urgency = "critical",
							timeout = 0,
						})
						return
					end

					if output == "" then
						naughty.notify({
							title = "LLM prompt error",
							text = err ~= "" and err or "The model returned no output.",
							urgency = "critical",
							timeout = 0,
						})
						return
					end

					naughty.notify({ title = "LLM response", text = output, timeout = 0 })
				end
			)
		end,
	})
end

return M
