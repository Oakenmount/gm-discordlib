--This is ugly
function discordlib.HTTPRequest(ctx, callback)
	local HTTPRequest = {}
	HTTPRequest.method = ctx.method
	HTTPRequest.url = ctx.url
	HTTPRequest.headers = {["Content-Type"] = "application/json"}
	if ctx.headers then
		table.Merge(HTTPRequest.headers, ctx.headers)
	end
	
	HTTPRequest.type = "application/json"

	if ctx.body then
		HTTPRequest.body = ctx.body
	elseif ctx.parameters then
		HTTPRequest.parameters = ctx.parameters
	end

	HTTPRequest.success = function(code, body, headers)
		callback(headers, body)
	end

	HTTPRequest.failed = function(reason)
	end

	HTTP(HTTPRequest)
end