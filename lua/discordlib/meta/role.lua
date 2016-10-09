discord.role_meta = discord.role_meta or {}

discord.role_meta.__index = discord.role_meta

function discord.role_meta:ParseRoleObj(tbl)

	local self = setmetatable({}, discord.role_meta)

	self.id = tbl.id
	self.name = tbl.name
	self.color = tbl.color
	self.hoist = tbl.hoist
	self.position = tbl.position
	self.permissions = tbl.permissions
	self.managed = tbl.managed
	self.mentionable = tbl.mentionable

	return self

end