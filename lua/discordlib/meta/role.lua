discordlib.meta.role = discordlib.meta.role or {}

discordlib.meta.role.__index = discordlib.meta.role

function discordlib.meta.role:ParseRoleObj(tbl)

	local self = setmetatable({}, discordlib.meta.role)

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