---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Api/DisplayTitle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Reads the display title for a profile from LPDB.

local Lua = require('Module:Lua')

local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsApiDisplayTitle = {}

---Returns the profile's display title from LPDB, or `nil` when the page does not exist.
---@param profileType string
---@param profile string The page name of the player/team (without the page prefix)
---@return string?
function ProfileTabsApiDisplayTitle.get(profileType, profile)
	local settings = PROFILE_TYPES[profileType]

	local data = mw.ext.LiquipediaDB.lpdb(settings.lpdbType, {
		conditions = '[[pagename::' .. profile:gsub(' ', '_') .. ']]',
		query = settings.lpdbQuery,
	})

	return (data[1] or {})[settings.displayField]
end

return ProfileTabsApiDisplayTitle