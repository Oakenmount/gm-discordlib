discordlib.channel_meta = discordlib.channel_meta or {}

discordlib.channel_meta.__index = discordlib.channel_meta

function discordlib.channel_meta:ParseChannelObj(tbl)

	local self = setmetatable({}, discordlib.channel_meta)

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

function discordlib.channel_meta:GetGuild()
	return self.bot:GetGuildByChannelID(self.id)
end