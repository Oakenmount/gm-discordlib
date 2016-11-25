discordlib.guild_meta = discordlib.guild_meta or {}

discordlib.guild_meta.__index = discordlib.guild_meta

function discordlib.guild_meta:ParseGuildCreate(tbl)

	local self = setmetatable({}, discordlib.guild_meta)

	self.client = tbl.client
	self.id = tbl.id
	self.name = tbl.name
	self.icon = tbl.icon
	self.splash = tbl.splash
	self.owner_id = tbl.owner_id
	self.region = tbl.region
	self.afk_channel_id = tbl.afk_channel_id
	self.afk_timeout = tbl.afk_timeout
	self.embed_enabled = tbl.embed_enabled
	self.embed_channel_id = tbl.embed_channel_id
	self.verification_level = tbl.verification_level
	self.default_message_notifications = tbl.default_message_notifications
	self.embed_channel_id = tbl.embed_channel_id
	self.emojis = tbl.emojis
	self.features = tbl.features
	self.member_count = tbl.member_count
	self.presences = tbl.presences
	self.unavailable = tbl.unavailable

	self.channels = {}
	self.roles = {}
	self.members = {}

	for k, v in pairs(tbl.roles) do
		local role = discordlib.role_meta:ParseRoleObj(v)
		self.roles[role.id] = role
	end

	self.client.guilds[self.id] = self -- Just temp pass for the other functions to get the data about roles

	for k, v in pairs(tbl.members or {}) do

		v.client = self.client -- Pass it
		local member = discordlib.guild_member_meta:ParseGuildMemberObj(v)
		self.members[member.user.id] = member
	end


	for k, v in pairs(tbl.channels or {}) do
		local channel = discordlib.channel_meta:ParseChannelObj(v)
		self.channels[channel.id] = channel
	end

	-- Turn the roles into a metatable

	return self

end