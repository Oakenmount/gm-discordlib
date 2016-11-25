discordlib.role_meta = discordlib.role_meta or {}

discordlib.role_meta.__index = discordlib.role_meta

function discordlib.role_meta:ParseRoleObj(tbl)

	local self = setmetatable({}, discordlib.role_meta)

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