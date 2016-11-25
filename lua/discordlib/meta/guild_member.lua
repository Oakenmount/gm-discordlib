discordlib.guild_member_meta = discordlib.guild_member_meta or {}

discordlib.guild_member_meta.__index = discordlib.guild_member_meta

function discordlib.guild_member_meta:ParseGuildMemberObj(tbl)

	local self = setmetatable({}, discordlib.guild_member_meta)

	self.client = tbl.client
	self.user = discordlib.user_meta:ParseUserObj(tbl.user)
	self.nick =	tbl.nick
	self.joined_at = tbl.joined_at
	self.deaf = tbl.deaf
	self.mute = tbl.mute
	self.roles = {}
	self:__ParseRoles(tbl.roles)

	return self

end

function discordlib.guild_member_meta:IsInRole(id)
	for k, role in pairs(self.roles) do
		if role.id == id then
			return true
		end
	end
	return false
end

function discordlib.guild_member_meta:GetRoles()
	return self.roles
end

function discordlib.guild_member_meta:__ParseRoles(roles)
	self.roles = {}
	for k, v in pairs(roles) do
		local role = self.client:GetRoleById(v)
		if role then
			table.insert(self.roles, role)
		end
	end
end

