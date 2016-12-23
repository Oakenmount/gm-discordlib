discordlib.meta.channel = discordlib.meta.channel or {}

discordlib.meta.channel.__index = discordlib.meta.channel

function discordlib.meta.channel:ParseChannelObj(tbl)

	local self = setmetatable({}, discordlib.meta.channel)

	self._client = tbl.client

	self.id = tbl.id
	self.name = tbl.name
	self.guild_id = tbl.guild_id
	self.type = tbl.type
	self.position = tbl.position
	self.is_private = tbl.position
	self.permission_overwrites = tbl.permission_overwrites
	self.topic = tbl.topic
	self.last_message_id = tbl.last_message_id

	return self

end

function discordlib.meta.channel:GetGuild()
	return self._client:GetGuildByChannelID(self.id)
end

function discordlib.meta.channel:SendMessage(msg, cb)
		self._client:SendMessage(self.id, msg, cb)

end