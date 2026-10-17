---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Api/Config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Reads the profile tabs config from the wiki's Module:Info.

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})

local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsApiConfig = {}

---Returns the tabs config section of `profileType` from the wiki's Module:Info.
---@param profileType string
---@return table
function ProfileTabsApiConfig.config(profileType)
	local config = PROFILE_TYPES[profileType]
	return (Info.config and Info.config[config.configKey]) or {}
end

return ProfileTabsApiConfig
