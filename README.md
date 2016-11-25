Garry's Mod Discord Library
============
**Note: This is highly experimental, use on own caution! This might not even work or it will break your stuff!**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Discord](https://discordapp.com/api/guilds/128871478019096576/embed.png)](https://discord.gg/vxCPtfK)

## Installation
**You need to have [gm_bromsock](https://github.com/Bromvlieg/gm_bromsock) installed for it to work!**

Download it either as a zip or clone it with git and then copy it to garrysmod/addons


## Example Usage
```lua

if bot and bot:IsConnected() then
    bot:Disconnect()
end

bot = discordlib:CreateClient()
bot:Login("<token>")

bot:on("ready", function()
	print("Successfully connected to discord!")
end)

bot:on("message", function(msg, self)
	if msg.author.id == self.id then return end
  
 	if string.find(msg.content, self.bot:Mention().." ping") then
		msg:Reply(msg.author:Mention()..", pong!")	
	end
end)
```
Then just @mention the bot with "ping" and it should reply with pong!
