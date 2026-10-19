---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Api/Matches
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- LPDB checks for profile match data.

local Lua = require('Module:Lua')

local Condition = Lua.import('Module:Condition')
local Table = Lua.import('Module:Table')

local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsApiMatches = {}

---Checks whether the player/team has matches stored in lpdb.
---@param profileType string
---@param profile string
---@return boolean
function ProfileTabsApiMatches.has(profileType, profile)
	local settings = PROFILE_TYPES[profileType]
	local field = settings.lpdbType == 'team' and 'opponent' or 'player'

	local conditions = Condition.Tree(Condition.BooleanOperator.all):add(
		Condition.Node(field, Condition.Comparator.eq, profile)
	):toString()

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		limit = 1,
	})

	return Table.isNotEmpty(matches)
end

return ProfileTabsApiMatches