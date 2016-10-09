/*
		Taken from the httprequest lua example of bromsock, slightly modified to allow more complex requests
		https://github.com/Bromvlieg/gm_bromsock/blob/master/Lua_examples/httprequest.lua
*/

function discord.HTTPRequest(url, method, headertbl, postdatatbl, patchdata, callback)
	local port = 80

	if (string.StartWith(url, "http://")) then
		url = string.Right(url, #url - 7)
	elseif (string.StartWith(url, "https://")) then
		url = string.Right(url, #url - 8)
		port = 443;
	end

	local host = ""
	local path = ""
	local postdata = ""
	local bigbooty = ""
	
	local headers = nil
	local chunkedmode = false
	local chunkedmodedata = false
	
	local pathindex = string.IndexOf("/", url)
	if (pathindex > -1) then
		host = string.sub(url, 1, pathindex - 1)
		path = string.sub(url, pathindex)
	else
		host = url
	end
	
	if (#path == 0) then path = "/" end
	
	if (postdatatbl) then
		for k, v in pairs(postdatatbl) do
			postdata = postdata .. k .. "=" .. v .. "&"
		end
		
		if (#postdata > 0) then
			postdata = string.Left(postdata, #postdata - 1)
		end
	end

	local pClient = BromSock();
	local pPacket = BromPacket();
	
	pClient:SetCallbackConnect( function( _, bConnected, szIP, iPort )
		if (not bConnected) then
			callback(nil, nil)
			return;
		end
		
		if (port == 443) then
			pClient:StartSSLClient()
		end
		
		pPacket:WriteLine(method .. " " .. path .. " HTTP/1.1");
		pPacket:WriteLine("Host: " .. host);

		for k, v in pairs(headertbl) do
			
			pPacket:WriteLine(k..": "..v)
		end

		if (method:lower() == "post") then
			pPacket:WriteLine("Content-Type: application/x-www-form-urlencoded");
			pPacket:WriteLine("Content-Length: " .. #postdata);
		elseif (method:lower() == "patch") then
			pPacket:WriteLine("Content-Type: application/json");
			pPacket:WriteLine("Content-Length: " .. #patchdata);
		else
			pPacket:WriteLine("Content-Type: application/x-www-form-urlencoded");
			pPacket:WriteLine("Content-Length: 0");
		end
		
		pPacket:WriteLine("");
		
		if (method:lower() == "post") then
			pPacket:WriteLine(postdata)
		elseif (method:lower() == "patch") then
			pPacket:WriteLine(patchdata)
		end

		pClient:SetMaxReceiveSize(1024 * 1024 * 100); -- some webpages like to embed images, so this can get quite big. Lets allow it to allocate up to 100MB
		pClient:Send( pPacket, true );
		pClient:ReceiveUntil( "\r\n\r\n" );
	end );
	
	pClient:SetCallbackReceive( function( _, incommingpacket )
		local szMessage = incommingpacket:ReadStringAll():Trim()
		incommingpacket = nil
		
		if (not headers) then
			local headers_tmp = string.Explode("\r\n", szMessage)
			headers = {}
			
			local statusrow = headers_tmp[1]
			table.remove(headers_tmp, 1)
			
			headers["status"] = statusrow:sub(10)
			for k, v in ipairs(headers_tmp) do
				local tmp = string.Explode(": ", v)
				headers[tmp[1]:lower()] = tmp[2]
			end
			
			if (headers["content-length"]) then
				pClient:Receive(tonumber(headers["content-length"]));
			elseif (headers["transfer-encoding"] and headers["transfer-encoding"] == "chunked") then
				chunkedmode = true
				pClient:ReceiveUntil( "\r\n" );
			else
				-- This is why we can't have nice things.
				pClient:Receive(99999);
			end
		elseif (chunkedmode) then
			if (chunkedmodedata) then
				bigbooty = bigbooty .. szMessage
				chunkedmodedata = false
				pClient:ReceiveUntil( "\r\n" );
			else
				local len = tonumber(szMessage, 16)
				if (len == 0) then
					callback(headers, bigbooty)
					pClient:Close()
					pClient = nil
					pPacket = nil
					return
				end
				
				chunkedmodedata = true
				pClient:Receive(len + 2) -- + 2 for \r\n, stilly chunked mode
			end
		else
			callback(headers, szMessage)
			pClient:Close()
			pClient = nil
			pPacket = nil
		end
	end)
	
	pClient:Connect(host, port);
end

function string.IndexOf(needle, haystack)
	for i = 1, #haystack do
		if (haystack[i] == needle) then
			return i
		end
	end
	
	return -1
end