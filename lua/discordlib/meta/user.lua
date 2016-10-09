discord.user_meta = discord.user_meta or {}

discord.user_meta.__index = discord.user_meta

function discord.user_meta:ParseUserObj(tbl)

	local self = setmetatable({}, discord.user_meta)

	self.status = "online"
	self.username = tbl.username
	self.id = tbl.id
	self.discriminator = tbl.discriminator
	self.avatar = tbl.avatar
	self.bot = tbl.bot or false
	self.verified = tbl.verified or false -- Let's just do this incase

	return self

end

function discord.user_meta:Mention()
	return "<@"..self.id..">"
end