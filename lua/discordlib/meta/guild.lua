discordlib.meta.guild = discordlib.meta.guild or {}

discordlib.meta.guild.__index = discordlib.meta.guild

function discordlib.meta.guild:ParseGuildCreate(tbl)

	local self = setmetatable({}, discordlib.meta.guild)

	self._client = tbl._client
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
		local role = discordlib.meta.role:ParseRoleObj(v)
		self.roles[role.id] = role
	end

	self._client.guilds[self.id] = self -- Just temp pass for the other functions to get the data about roles

	for k, v in pairs(tbl.members or {}) do

		v._client = self._client -- Pass it
		local member = discordlib.meta.guild_member:ParseGuildMemberObj(v)
		member.guild = self
		self.members[member.user.id] = member
	end


	for k, v in pairs(tbl.channels or {}) do
		local channel = discordlib.meta.channel:ParseChannelObj(v)
		self.channels[channel.id] = channel
	end

	-- Turn the roles into a metatable

	return self

end