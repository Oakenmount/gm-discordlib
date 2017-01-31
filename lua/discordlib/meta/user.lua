discordlib.meta.user = discordlib.meta.user or {}

discordlib.meta.user.__index = discordlib.meta.user

function discordlib.meta.user:ParseUserObj(tbl, client)

	local self = setmetatable({}, discordlib.meta.user)

	self._client =  client or tbl._client

	self.status = "online"
	self.username = tbl.username
	self.id = tbl.id
	self.discriminator = tbl.discriminator
	self.avatar = tbl.avatar
	self.bot = tbl.bot or false
	self.verified = tbl.verified or false -- Let's just do this incase
	
	return self
end

function discordlib.meta.user:Mention()
	return "<@"..self.id..">"
end