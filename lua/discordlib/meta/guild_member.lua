discord.guild_member_meta = discord.guild_member_meta or {}

discord.guild_member_meta.__index = discord.guild_member_meta

function discord.guild_member_meta:ParseGuildMemberObj(tbl)

	local self = setmetatable({}, discord.guild_member_meta)

	self.client = tbl.client
	self.user = discord.user_meta:ParseUserObj(tbl.user)
	self.nick =	tbl.nick
	self.joined_at = tbl.joined_at
	self.deaf = tbl.deaf
	self.mute = tbl.mute
	self.roles = {}
	self:__ParseRoles(tbl.roles)

	return self

end

function discord.guild_member_meta:IsInRole(id)
	for k, role in pairs(self.roles) do
		if role.id == id then
			return true
		end
	end
	return false
end

function discord.guild_member_meta:GetRoles()
	return self.roles
end

function discord.guild_member_meta:__ParseRoles(roles)
	self.roles = {}
	for k, v in pairs(roles) do
		local role = self.client:GetRoleById(v)
		if role then
			table.insert(self.roles, role)
		end
	end
end

