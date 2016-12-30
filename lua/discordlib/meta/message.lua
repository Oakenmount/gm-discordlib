discordlib.meta.message = discordlib.meta.message or {}

discordlib.meta.message.__index = discordlib.meta.message

function discordlib.meta.message:ParseMessageCreate(tbl)

	local self = setmetatable({}, discordlib.meta.message)

	self._client = tbl._client

	self.id = tbl.id
	self.type = tbl.type
	self.content = tbl.content
	self.channel_id = tbl.channel_id
	self.author = discordlib.meta.user:ParseUserObj(tbl.author)

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
		self._client:SendMessage(self.channel_id, msg, cb)

end


function discordlib.meta.message:ReplyEmbed(embed, cb)
		self._client:SendEmbed(self.channel_id, embed, cb)

end

function discordlib.meta.message:Edit(msg, cb)
	local payload = util.TableToJSON({["content"] = msg})
	self._client:RunAPIFunc("editMessage", function()
		self._client:APIRequest(discordlib.endpoints.channels.."/"..self.channel_id.."/messages/"..self.id, "PATCH", nil, payload, function(headers, body)
			self._client:SetRateLimitHead("editMessage", headers)

			if not cb then return end
			local tbl = util.JSONToTable(body)
			tbl._client = self._client
			cb(discordlib.meta.message:ParseMessageCreate(tbl))
		end)
	end)

end

function discordlib.meta.message:Pin(cb)
	self._client:RunAPIFunc("pinMessage", function()
		self._client:APIRequest(discordlib.endpoints.channels.."/"..self.channel_id.."/pins/"..self.id, "PUT", nil, nil, function(headers, body)
			self._client:SetRateLimitHead("pinMessage", headers)
			if not cb then return end
			cb(util.JSONToTable(body))
		end)
	end)
end

function discordlib.meta.message:Unpin(cb)
	self._client:RunAPIFunc("unpinMessage", function()
		self._client:APIRequest(discordlib.endpoints.channels.."/"..self.channel_id.."/pins/"..self.id, "DELETE", nil, nil, function(headers, body)
			self._client:SetRateLimitHead("unpinMessage", headers)
			if not cb then return end
			cb(util.JSONToTable(body))
		end)
	end)
end

function discordlib.meta.message:Delete()
	self._client:RunAPIFunc("deleteMessage", function()
		self._client:APIRequest("https://discordapp.com/api/channels/"..self.channel_id.."/messages/"..self.id, "DELETE", {}, nil, function(headers, body)
			self._client:SetRateLimitHead("deleteMessage", headers)
			
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