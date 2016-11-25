discordlib.message_meta = discordlib.message_meta or {}

discordlib.message_meta.__index = discordlib.message_meta

function discordlib.message_meta:ParseMessageCreate(tbl)

	local self = setmetatable({}, discordlib.message_meta)

	self.client = tbl.client

	self.id = tbl.id
	self.type = tbl.type
	self.content = tbl.content
	self.channel_id = tbl.channel_id
	self.author = discordlib.user_meta:ParseUserObj(tbl.author)

	self.tts = tbl.tts
	self.timestamp = tbl.timestamp
	self.pinned = tbl.pinned
	self.nonce = tbl.nonce
	self.mentions = tbl.mentions
	self.embeds = tbl.embeds
	self.edited_timestamp = tbl.edited_timestamp

	return self

end

function discordlib.message_meta:Reply(msg, cb)
		self.client:SendMessage(self.channel_id, msg, cb)

end

function discordlib.message_meta:Edit(msg, cb)
	local payload = util.TableToJSON({["content"] = msg})
	self.client:RunAPIFunc("editMessage", function()
		self.client:APIRequest(discordlib.endpoints.channels.."/"..self.channel_id.."/messages/"..self.id, "PATCH", nil, payload, function(headers, body)
			self.client:SetRateLimitHead("editMessage", headers)

			if not cb then return end
			local tbl = util.JSONToTable(body)
			tbl.client = self.client
			cb(discordlib.message_meta:ParseMessageCreate(tbl))
		end)
	end)

end

function discordlib.message_meta:Pin(cb)
	self.client:RunAPIFunc("pinMessage", function()
		self.client:APIRequest(discordlib.endpoints.channels.."/"..self.channel_id.."/pins/"..self.id, "PUT", nil, nil, function(headers, body)
			self.client:SetRateLimitHead("pinMessage", headers)
			if not cb then return end
			cb(util.JSONToTable(body))
		end)
	end)
end

function discordlib.message_meta:Unpin(cb)
	self.client:RunAPIFunc("unpinMessage", function()
		self.client:APIRequest(discordlib.endpoints.channels.."/"..self.channel_id.."/pins/"..self.id, "DELETE", nil, nil, function(headers, body)
			self.client:SetRateLimitHead("unpinMessage", headers)
			if not cb then return end
			cb(util.JSONToTable(body))
		end)
	end)
end

function discordlib.message_meta:Delete()
	self.client:RunAPIFunc("deleteMessage", function()
		self.client:APIRequest("https://discordapp.com/api/channels/"..self.channel_id.."/messages/"..self.id, "DELETE", {}, nil, function(headers, body)
			self.client:SetRateLimitHead("deleteMessage", headers)
			
			if not cb then return end
			local tbl = util.JSONToTable(body)
			tbl.client = self.client
			cb(discordlib.message_meta:ParseMessageCreate(tbl, self.client))
		end)
	end)

end


function discordlib.message_meta:GetChannel()
	return self.client:GetChannelByChannelID(self.channel_id)

end

function discordlib.message_meta:IsMentioned(id)
	if not id then id = self.client.id end

end

function discordlib.message_meta:GetGuildMember()
	local guild = self.client:GetGuildByChannelID(self.channel_id)
	if not guild then return false end

	return guild.members[self.author.id] or false

end

function discordlib.message_meta:GetGuild()
	return self.client:GetGuildByChannelID(self.channel_id)

end

function discordlib.message_meta:GetAuthor()
	return self.author
end