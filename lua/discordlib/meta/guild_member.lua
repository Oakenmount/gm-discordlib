discordlib.meta.guild_member = discordlib.meta.guild_member or {}

discordlib.meta.guild_member.__index = discordlib.meta.guild_member

function discordlib.meta.guild_member:ParseGuildMemberObj(tbl)

	local self = setmetatable({}, discordlib.meta.guild_member)

	self._client = tbl._client
	tbl.user_client = tbl.client
	self.user = discordlib.meta.user:ParseUserObj(tbl.user)
	self.nick =	tbl.nick
	self.joined_at = tbl.joined_at
	self.deaf = tbl.deaf
	self.mute = tbl.mute
	self.roles = {}
	self:__ParseRoles(tbl.roles)

	return self

end

function discordlib.meta.guild_member:IsInRole(id)
	for k, role in pairs(self.roles) do
		if role.id == id then
			return true
		end
	end
	return false
end

function discordlib.meta.guild_member:GetRoles()
	return self.roles
end

function discordlib.meta.guild_member:__ParseRoles(roles)
	self.roles = {}
	for k, v in pairs(roles) do
		local role = self._client:GetRoleById(v)
		if role then
			table.insert(self.roles, role)
		end
	end
end