discordlib.user_meta = discordlib.user_meta or {}

discordlib.user_meta.__index = discordlib.user_meta

function discordlib.user_meta:ParseUserObj(tbl)

	local self = setmetatable({}, discordlib.user_meta)

	self.status = "online"
	self.username = tbl.username
	self.id = tbl.id
	self.discriminator = tbl.discriminator
	self.avatar = tbl.avatar
	self.bot = tbl.bot or false
	self.verified = tbl.verified or false -- Let's just do this incase

	return self

end

function discordlib.user_meta:Mention()
	return "<@"..self.id..">"
end