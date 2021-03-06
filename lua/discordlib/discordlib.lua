--[[
Discord Library for Garry's Mod Lua by Datamats
Check the README.md and LICENSE file for more infomation.
]]

discordlib = discordlib or {meta = {}}

discordlib.__index = discordlib

discordlib.currid = discordlib.currid or 1

discordlib.endpoints = {}
discordlib.endpoints.base = "https://discordapp.com/api/v6"
discordlib.endpoints.gateway = "wss://gateway.discord.gg/?v=6"
discordlib.endpoints.users = discordlib.endpoints.base.."/users"
discordlib.endpoints.guilds = discordlib.endpoints.base.."/guilds"
discordlib.endpoints.channels = discordlib.endpoints.base.."/channels"

discordlib._rateLimiter = {}
local rateLimiter = discordlib._rateLimiter

include('libs/websocket.lua')
include('libs/http.lua')

include('meta/user.lua')
include('meta/message.lua')
include('meta/channel.lua')
include('meta/role.lua')
include('meta/guild.lua')
include('meta/guild_member.lua')


function discordlib:CreateClient()

	local self = setmetatable({}, discordlib)

	-- Generate new id used for heartbeat timer etc probably a more elegant way to do this
	discordlib.currid = discordlib.currid +1
	self.cid = discordlib.currid

	self.autoreconnect = true -- Let's make this the default
	self.authed = false
	self.last_seq = nil
	self.debug = false
	self.events = {}
	-- Let's cache basic guilds and roles data and update them on websocket event ,maybe a better way to do this? ¯\_(ツ)_/¯
	self.guilds = {}
	self.heartbeatInterval = 45
	rateLimiter[self.cid] = {}

	self:CreateWS()

	return self
end

function discordlib:CreateWS()
	self.ws = self.WS.Client(discordlib.endpoints.gateway, 443)

	self.ws:on("open", function()
			timer.Simple(0, function()
				self:Auth()
			end)
	end)
		
	self.ws:on("message", function(msg)
		self:HandlePayload(msg)
	end)
		
	self.ws:on("close", function()
		if self.debug then
			print("DLib: Websocket disconnected")
		end
		if self.autoreconnect and self.authed then
			self:CreateWS()
			self.ws:Connect()
		else
			self:fireEvent("disconnected")
		end
	end)

	self.ws:on("close_payload", function(code, payload)
		if code == 4004 then
			self.autoreconnect = false
			self:fireEvent("auth_failure")
			if self.debug then
				print("DLib - Authentication failure")
			end
		end
	end)
	function self:IsConnected()
		return self.ws and self.ws:IsActive()
	end
end

--Will add the token at the start for the connection to the gateway
function discordlib:Login(token)
	self.token = token
	self.ws:Connect()

	if self.debug then
		print("DLib - Connecting / Loginin")
	end
end

--Disconnect the current session
function discordlib:Disconnect()
	self.autoreconnect = false
	if self:IsConnected() then
		timer.Destroy("discordHeartbeat"..self.cid)
		self.ws:Close()
	end
	return true
end

--Basic auth message for websocket
function discordlib:Auth()
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
function discordlib:Heartbeat()
	if self.debug then
		print("DLib: Sending heartbeat with sequence: "..self.last_seq)
	end

	local payload = {
		["op"] = 1,
		["d"] = self.last_seq or nil
	}
	self.ws:Send(util.TableToJSON(payload))
end

-- Make it emit the heartbeat websocket event every 20sec to not get disconnected
function discordlib:StartHeartbeat(int)
	if not self.ws:IsActive() then
		return false
	end
	timer.Create( "discordHeartbeat"..self.cid, self.heartbeatInterval, 0, function() 
		if not self:IsConnected() then
			timer.Destroy("discordHeartbeat"..self.cid)
		else
			self:Heartbeat()
		end
	end)
end

function discordlib:HandlePayload(msg)
	local payload = util.JSONToTable(msg)
	
	payload.d = payload.d or {}
	payload.d._client = self

	if self.debug then
		print("DLib: Getting OP: "..payload.op)
	end

	local op = payload.op

	if op == 0 then
		self:HandleMessage(payload)
	elseif op == 1 then
		self:Heartbeat()
	elseif op == 7 then
		self.ws:Close()
	elseif op == 9 then
		Error("DLib: Invalid session id")
	elseif op == 10 then
		self.heartbeatInterval = payload.d["heartbeat_interval"]/1000
	end

end

function discordlib:HandleMessage(payload)
	self.last_seq = payload.s
	if payload.t == "READY" then
		self.authed = true
		self.bot = discordlib.meta.user:ParseUserObj(payload.d.user, self)
		self.id = payload.d.user.id
		self.username = payload.d.user.username
		self.session_id = payload.d.session_id
		self:StartHeartbeat()
		self:fireEvent("ready")

	elseif payload.t == "MESSAGE_CREATE" then
		self:fireEvent("message", self, discordlib.meta.message:ParseMessageCreate(payload.d))

	elseif payload.t == "GUILD_CREATE" then
		local guild = discordlib.meta.guild:ParseGuildCreate(payload.d)
		self.guilds[guild.id] = guild

	elseif payload.t == "GUILD_MEMBER_ADD" then
		local guild = self:GetGuildByGuildID(payload.d.guild_id)
		local guild_member = discordlib.meta.guild_member:ParseGuildMemberObj(payload.d)
		guild.members[guild_member.user.id] = guild_member

	elseif payload.t == "GUILD_MEMBER_REMOVE" then
		local guild = self:GetGuildByGuildID(payload.d.guild_id)
		if guild then
			guild.members[payload.d.user.id] = nil
		end
	elseif payload.t == "GUILD_MEMBER_ADD" then
		local guild = self:GetGuildByGuildID(payload.d.guild_id)
		local member = discordlib.meta.guild_member:ParseGuildMemberObj(payload.d)
		member.guild = guild
		table.insert(guild.members, member)

	elseif payload.t == "GUILD_MEMBER_UPDATE" then
		local guild = self:GetGuildByGuildID(payload.d.guild_id)
		local userid = payload.d.user.id
		guild.members[userid].user = discordlib.meta.user:ParseUserObj(payload.d.user)

		guild.members[userid].roles = {}
		for k, v in pairs(payload.d.roles) do
			local role = self:GetRoleById(v)
			if role then
				table.insert(guild.members[userid].roles, role)
			end
		end
	end
end


function discordlib:GetChannelByChannelID(id)
	for k, guild in pairs(self.guilds) do
		for k, channel in pairs(guild.channels) do
			if channel.id == id then
				return channel
			end
		end
	end
	return false
end

function discordlib:GetGuildByChannelID(id)
	for k, guild in pairs(self.guilds) do
		for k, channel in pairs(guild.channels) do
			if channel.id == id then
				return guild
			end
		end
	end
	return false
end

function discordlib:GetGuildByGuildID(id)
	for k, guild in pairs(self.guilds) do
		if guild.id == id then
			return guild
		end
	end
	return false
end


function discordlib:GetRoleById(id)
	for k, guild in pairs(self.guilds) do
		for k, role in pairs(guild.roles) do
			if role.id == id then
				return role
			end
		end
	end
	return false
end

function discordlib:APIRequest(msg, callback)
	msg["headers"] = {["Authorization"]="Bot "..self.token, ["Content-Type"]="application/json"}
	self.HTTPRequest(msg, callback)
end

function discordlib:CreateMessage(channelid, msg, cb)
	local res;
	if type(msg) == "string" then
		res = util.TableToJSON({["content"] = msg})
	elseif type(msg) == "table" then
		res = util.TableToJSON(msg)
	else
		return print("DLib: Attempting to send a message that is not a string or table!")
	end

	self:RunAPIFunc("CreateMessage", function()
		self:APIRequest({
			["method"] = "post",
			["url"] = discordlib.endpoints.channels.."/"..channelid.."/messages",
			["body"] = res
		}, function(headers, body)
			self:SetRateLimitHead("CreateMessage", headers)
			
			if not cb then return end
			local tbl = util.JSONToTable(body)
			tbl._client = self
			cb(discordlib.meta.message:ParseMessageCreate(tbl, bot))
		end)
	end)
end

function discordlib:on(eventName,func)
	self.events[eventName] = func
end

function discordlib:fireEvent(eventName,...)
	local event = self.events[eventName] or false
	if not event then return end
	event(...)
end

function discordlib:RunAPIFunc(name, func)
	rateLimiter[self.cid] = rateLimiter[self.cid] or {}
	rateLimiter[self.cid][name] = rateLimiter[self.cid][name] or {}
	rateLimiter[self.cid][name].funcs = rateLimiter[self.cid][name].funcs or {}

	table.insert(rateLimiter[self.cid][name].funcs, func)
end

function discordlib:SetRateLimitHead(name, headers)
	self:SetRateLimit(name, tonumber(headers["x-ratelimit-remaining"]) or 5, tonumber(headers["x-ratelimit-reset"]) or 5)
end

function discordlib:SetRateLimit(name, remaining, resetTime)
	rateLimiter[self.cid] = rateLimiter[self.cid] or {}
	rateLimiter[self.cid][name] = rateLimiter[self.cid][name] or {}
	rateLimiter[self.cid][name].Remaining = remaining
	rateLimiter[self.cid][name].resetTime = resetTime
end

--The current ratelimiter, not very effective tho.

local nextRateLimit = 0

hook.Add("Think", "discordRatelimiter", function()
	if SysTime() > nextRateLimit then
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
		nextRateLimit = SysTime() + .1
	end
end)