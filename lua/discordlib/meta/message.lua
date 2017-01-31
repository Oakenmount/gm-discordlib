discordlib.meta.message = discordlib.meta.message or {}

discordlib.meta.message.__index = discordlib.meta.message

function discordlib.meta.message:ParseMessageCreate(tbl)

	local self = setmetatable({}, discordlib.meta.message)

	self._client = tbl._client

	self.id = tbl.id
	self.type = tbl.type
	self.content = tbl.content
	self.channel_id = tbl.channel_id
	self.author = discordlib.meta.user:ParseUserObj(tbl.author, tbl._client)

	self.tts = tbl.tts
	self.timestamp = tbl.timestamp
	self.pinned = tbl.pinned
	self.nonce = tbl.nonce
	self.mentions = tbl.mentions
	self.embeds = tbl.embeds
	self.edited_timestamp = tbl.edited_timestamp

	return self

end

function discordlib.meta.message:Reply(msg, cb)
		self._client:CreateMessage(self.channel_id, msg, cb)

end

--[[
HTTP function dosnt support patch yet
function discordlib.meta.message:Edit(msg, cb)
	local payload = util.TableToJSON({["content"] = msg})
	self._client:RunAPIFunc("EditMessage", function()

		self._client:APIRequest({
			["method"] = "patch",
			["url"] = discordlib.endpoints.channels.."/"..self.channel_id.."/messages/"..self.id,
			["body"] = payload
		}, function(headers, body)
			self._client:SetRateLimitHead("EditMessage", headers)
			if not cb then return end
			local tbl = util.JSONToTable(body)
			tbl._client = self._client
			cb(discordlib.meta.message:ParseMessageCreate(tbl))
		end)
	end)

end
]]

function discordlib.meta.message:Pin(cb)
	self._client:RunAPIFunc("PinMessages", function()
		self._client:APIRequest({
			["method"] = "put",
			["url"] = discordlib.endpoints.channels.."/"..self.channel_id.."/pins/"..self.id
		}, function(headers, body)
			self._client:SetRateLimitHead("PinMessages", headers)
			if not cb then return end
			cb(util.JSONToTable(body))
		end)
	end)
end

function discordlib.meta.message:Unpin(cb)
	self._client:RunAPIFunc("UnpinMessages", function()
		self._client:APIRequest({
			["method"] = "delete",
			["url"] = discordlib.endpoints.channels.."/"..self.channel_id.."/pins/"..self.id
		}, function(headers, body)
			self._client:SetRateLimitHead("UnpinMessages", headers)
			if not cb then return end
			cb(util.JSONToTable(body))
		end)
	end)
end

function discordlib.meta.message:Delete()
	self._client:RunAPIFunc("DeleteMessages", function()
		self._client:APIRequest({
			["method"] = "delete",
			["url"] = "https://discordapp.com/api/channels/"..self.channel_id.."/messages/"..self.id
		}, function(headers, body)
			self._client:SetRateLimitHead("DeleteMessages", headers)
			if not cb then return end
			local tbl = util.JSONToTable(body)
			tbl._client = self._client
			cb(discordlib.meta.message:ParseMessageCreate(tbl, self._client))
		end)
	end)
end


function discordlib.meta.message:GetChannel()
	return self._client:GetChannelByChannelID(self.channel_id)

end

function discordlib.meta.message:IsMentioned(id)
	if not id then id = self._client.id end

end

function discordlib.meta.message:GetGuildMember()
	local guild = self._client:GetGuildByChannelID(self.channel_id)
	if not guild then return false end

	return guild.members[self.author.id] or false

end

function discordlib.meta.message:GetGuild()
	return self._client:GetGuildByChannelID(self.channel_id)

end

function discordlib.meta.message:GetAuthor()
	return self.author
end