/*
Discord Library for Garry's Mod by Datamats
Check the README.md and LICENSE file for more infomation.
*/

discord = discord or {}

discord.__index = discord

discord.currid = discord.currid or 1

discord.endpoints = {}
discord.endpoints.base = "https://discordapp.com/api"
discord.endpoints.gateway = "wss://gateway.discord.gg/"
discord.endpoints.users = discord.endpoints.base.."/users"
discord.endpoints.guilds = discord.endpoints.base.."/guilds"
discord.endpoints.channels = discord.endpoints.base.."/channels"

local rateLimiter = {}

include('libs/websocket.lua')
include('libs/http.lua')

include('meta/user.lua')
include('meta/message.lua')
include('meta/channel.lua')
include('meta/role.lua')
include('meta/guild.lua')
include('meta/guild_member.lua')



function discord:CreateClient()

	local self = setmetatable({}, discord)

	-- Generate new id used for heartbeat timer etc probably a more elegant way to do this
	discord.currid = discord.currid +1
	self.cid = discord.currid

	self.autoreconnect = true -- Let's make this the default

	self.events = {}
	-- Let's cache basic guilds and roles data and update them on websocket event maybe a better way to do this? ¯\_(ツ)_/¯
	self.guilds = {}

	rateLimiter[self.cid] = {}

	self.ws = self.WS.Client(discord.endpoints.gateway, 443)

	self.ws:on("open", function()
			self:Auth()
			self:StartHeartbeat()
	end)
		
	self.ws:on("message", function(msg)
		self:HandleMessage(msg)
	end)
		
	self.ws:on("close", function()
		self:fireEvent("disconnected")
	end)

	return self
end

--Will add the token ad start the connection to the gateway
function discord:Login(token)
	self.token = token
	self.ws:Connect()
end

--If the websocket connection is still active
function discord:IsConnected()
	return self.ws and self.ws:IsActive()
end

--Disconnect the current session
function discord:Disconnect()
	if self:IsConnected() then
		timer.Destroy("discordHeartbeat"..self.cid)
		self.ws:Close()
	end
	return true
end

--Basic auth message for websocket
function discord:Auth()
	local payload = {
		["op"] = 2,
		["d"] = {
			["token"] = self.token,
		    ["properties"] = {
		        ["$os"] = jit.os,
		        ["$browser"] = "gm-discordlib",
		        ["$device"] = "gm-discordlib",
		        ["$referrer"] = "",
		        ["$referring_domain"] = ""
		    },
		    ["compress"] = false,
		    ["large_threshold"] = 100
	    }
	}
	self.ws:Send(util.TableToJSON(payload))
end

-- Emit the heartbeant event
function discord:Heartbeat()
		local payload = {
			["op"] = 1,
			["d"] = os.time()
		}
		self.ws:Send(util.TableToJSON(payload))
end

-- Make it emit the heartbeat websocket event every 20sec to not get disconnected
function discord:StartHeartbeat()
	if not self.ws:IsActive() then
		return false
	end
	timer.Create( "discordHeartbeat"..self.cid, 20, 0, function() 
		if not self:IsConnected() then
				timer.Destroy("discordHeartbeat"..self.cid)
		else
			self:Heartbeat()
		end
	end)
end

function discord:HandleMessage(msg)
	local tbl = util.JSONToTable(msg)

	tbl.d = tbl.d or {}
	tbl.d.client = self

	if tbl.t == "READY" then
		self.bot = discord.user_meta:ParseUserObj(tbl.d.user)
		self.id = tbl.d.user.id
		self.username = tbl.d.user.username
		self.session_id = tbl.d.session_id
		self:fireEvent("ready")

	elseif tbl.t == "MESSAGE_CREATE" then
		self:fireEvent("message", discord.message_meta:ParseMessageCreate(tbl.d), self)

	elseif tbl.t == "GUILD_CREATE" then
		local guild = discord.guild_meta:ParseGuildCreate(tbl.d)
		self.guilds[guild.id] = guild

	elseif tbl.t == "GUILD_MEMBER_ADD" then
		local guild = self:GetGuildByGuildID(tbl.d.guild_id)
		local guild_member = discord.guild_member_meta:ParseGuildMemberObj(tbl.d)
		guild.members[guild_member.user.id] = guild_member

	elseif tbl.t == "GUILD_MEMBER_REMOVE" then
		local guild = self:GetGuildByGuildID(tbl.d.guild_id)
		local userid = tbl.d.user.id
		guild.members[userid] = nil

	elseif tbl.t == "GUILD_MEMBER_ADD" then
		local guild = self:GetGuildByGuildID(tbl.d.guild_id)
		local member = discord.guild_member_meta:ParseGuildMemberObj(tbl.d)
		table.insert(guild.members, member)

	elseif tbl.t == "GUILD_MEMBER_UPDATE" then
		local guild = self:GetGuildByGuildID(tbl.d.guild_id)
		local userid = tbl.d.user.id
		guild.members[userid].user = discord.user_meta:ParseUserObj(tbl.d.user)

		guild.members[userid].roles = {}
		for k, v in pairs(tbl.d.roles) do
			local role = self:GetRoleById(v)
			table.insert(guild.members[userid].roles, role)
		end
	end
end

function discord:GetChannelByChannelID(id)
	for k, guild in pairs(self.guilds) do
		for k, channel in pairs(guild.channels) do
			if channel.id == id then
				return channel
			end
		end
	end
	return false
end

function discord:GetGuildByChannelID(id)
	for k, guild in pairs(self.guilds) do
		for k, channel in pairs(guild.channels) do
			if channel.id == id then
				return guild
			end
		end
	end
	return false
end

function discord:GetGuildByGuildID(id)
	for k, guild in pairs(self.guilds) do
		if guild.id == id then
			return guild
		end
	end
	return false
end


function discord:GetRoleById(id)
	for k, guild in pairs(self.guilds) do
		for k, role in pairs(guild.roles) do
			if role.id == id then
				return role
			end
		end
	end
	return false
end

function discord:GetUserById(id, cb)
	for k, guild in pairs(self.guilds) do
		for k, role in pairs(guild.roles) do
			if role.id == id then
				return role
			end
		end
	end
	return false
end

function discord:APIRequest(url, method, posttbl, patchdata, callback)
	local headtbl = {["Authorization"]="Bot "..self.token, ["Content-Type"]="application/json"}
	
	self.HTTPRequest(url, method, headtbl, posttbl, patchdata, callback)
end

function discord:SendMessage(channelid, msg, cb)
	local postTbl = {["content"] = msg}
	self:RunAPIFunc("sendMessage", function()
		self:APIRequest(discord.endpoints.channels.."/"..channelid.."/messages", "POST", postTbl, nil, function(headers, body)
			self:SetRateLimitHead("sendMessage", headers)
			
			if not cb then return end
			local tbl = util.JSONToTable(body)
			tbl.client = self
			cb(discord.message_meta:ParseMessageCreate(tbl, bot))
		end)
	end)
end

end

function discord:on(eventName,func)
	self.events[eventName] = func
end

function discord:fireEvent(eventName,...)
	local event = self.events[eventName] or false
	if not event then return end
	event(...)
end

--The ratelimiter, it may need a rewrite in the future

local lastRateLimit = 0

function discord:RunAPIFunc(name, func)
	rateLimiter[self.cid] = rateLimiter[self.cid] or {}
	rateLimiter[self.cid][name] = rateLimiter[self.cid][name] or {}
	rateLimiter[self.cid][name].funcs = rateLimiter[self.cid][name].funcs or {}

	table.insert(rateLimiter[self.cid][name].funcs, func)
end

function discord:SetRateLimitHead(name, headers)
	self:SetRateLimit(name, tonumber(headers["x-ratelimit-remaining"]) or 5, tonumber(headers["x-ratelimit-reset"]) or 5)
end

function discord:SetRateLimit(name, remaining, resetTime)
	rateLimiter[self.cid] = rateLimiter[self.cid] or {}
	rateLimiter[self.cid][name] = rateLimiter[self.cid][name] or {}
	rateLimiter[self.cid][name].Remaining = remaining
	rateLimiter[self.cid][name].resetTime = resetTime


hook.Add("Think", "discordRatelimiter", function()

	if SysTime() - lastRateLimit > 0.1 then
		for k, clientRates in pairs(rateLimiter) do
			for k, apiType in pairs(clientRates) do

				apiType.funcs = apiType.funcs or {}

				if table.Count(apiType.funcs) > 0 then
					if (apiType.Remaining or 1) > 0 or CurTime() > (apiType.resetTime or 0) then
						local func = table.remove(apiType.funcs, 1)
						func()

					end

				end

			end

		end
		lastRateLimit = SysTime()
	end
end)