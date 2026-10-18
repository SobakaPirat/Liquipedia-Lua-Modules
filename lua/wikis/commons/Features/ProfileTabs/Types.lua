---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---Head to head run query configuration, rendered when the Results subpage exists.
---@class ProfileTabsHeadToHead
---@field mediawikiForm string
---@field form string
---@field template string
---@field queryArg string The query argument name the profile is passed as

---Per-type metadata that drives all player/team differences.
---@class ProfileTypeDefinition
---@field lpdbType string
---@field lpdbQuery string
---@field displayField string
---@field tabs string[] Special subpage tabs, shown only when the page exists
---@field headToHead ProfileTabsHeadToHead

---@type table<string, ProfileTypeDefinition>
local PROFILE_TYPES = {
	player = {
		lpdbType = 'player',
		lpdbQuery = 'id',
		displayField = 'id',
		tabs = {
			'Results',
			'Played Matches',
			'Coaching',
			'Broadcasts',
			'Awards',
			'Statistics',
			'Managing',
			'Organized Events',
			'Maps Created',
			'Notable Wins',
			'VODs',
		},
		headToHead = {
			mediawikiForm = 'Match history',
			form = 'H2H',
			template = 'Head_to_head_query',
			queryArg = 'player',
		},
	},
	team = {
		lpdbType = 'team',
		lpdbQuery = 'name',
		displayField = 'name',
		tabs = {
			'Results',
			'Played Matches',
			'Player Results',
			'Awards',
			'Bootcamps',
			'History',
			'Tournaments',
			'Teamkills',
			'Player Matches',
			'Organized Events',
		},
		headToHead = {
			mediawikiForm = 'Match history',
			form = 'H2H',
			template = 'Head_to_head_query',
			queryArg = 'team',
		},
	},
}

return PROFILE_TYPES
