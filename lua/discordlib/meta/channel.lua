discord.channel_meta = discord.channel_meta or {}

discord.channel_meta.__index = discord.channel_meta

function discord.channel_meta:ParseChannelObj(tbl)

	local self = setmetatable({}, discord.channel_meta)

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

function discord.channel_meta:GetGuild()
	return self.bot:GetGuildByChannelID(self.id)
end