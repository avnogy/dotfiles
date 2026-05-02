local naughty = require("naughty")

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
		urgency = "critical",
		timeout = 0,
	})
end
