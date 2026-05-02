local naughty = require("naughty")

do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then
			return
		end
		in_error = true

		naughty.notify({
			title = "Oops, an error happened!",
			text = tostring(err),
			urgency = "critical",
			timeout = 0,
		})
		in_error = false
	end)
end
