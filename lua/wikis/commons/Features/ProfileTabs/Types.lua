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

---Statistics run query configuration, rendered when the `statistics` wiki-variable is true
---and the Results subpage exists.
---@class ProfileTabsStatistics
---@field mediawikiForm string
---@field form string
---@field template string
---@field queryArg string The query argument name the profile is passed as

---Run query configuration for replacement tabs, rendered like headToHead/statistics
---but in the position of the replaced tab, so it takes over the tab's slot.
---@class ProfileTabsRunQuery
---@field display string
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
---@field tabDisplay table<string, string>? Optional display names for tabs, keyed by subpage name
---@field headToHead ProfileTabsHeadToHead
---@field statistics ProfileTabsStatistics?
---@field replaceTabs table<string, ProfileTabsRunQuery>? Keyed by the tab name they replace

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
		tabDisplay = {
			Broadcasts = 'Talent',
		},
		headToHead = {
			mediawikiForm = 'Match history',
			form = 'H2H',
			template = 'Head_to_head_query',
			queryArg = 'player',
		},
		statistics = {
			mediawikiForm = 'PlayerStats',
			form = 'PlayerStats/LH',
			template = 'Player statistics',
			queryArg = 'player',
		},
		replaceTabs = {
			['Results'] = {
				display = 'Results',
				mediawikiForm = 'Player Results',
				form = 'Player Results/LH',
				template = 'Player results',
				queryArg = 'player',
			},
			['Played Matches'] = {
				display = 'Matches',
				mediawikiForm = 'Player Matches',
				form = 'Player Matches/LH',
				template = 'Player Matches',
				queryArg = 'player',
			},
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
			mediawikiForm = 'Head2head',
			form = 'H2H',
			template = 'Headtohead',
			queryArg = 'team',
		},
		replaceTabs = {
			['Results'] = {
				display = 'Team Results',
				mediawikiForm = 'Team Results',
				form = 'Team Results/LH',
				template = 'Team results',
				queryArg = 'team',
			},
			['Played Matches'] = {
				display = 'Team Matches',
				mediawikiForm = 'Team Matches',
				form = 'Team Matches/LH',
				template = 'Team matches',
				queryArg = 'team',
			},
			['Player Results'] = {
				display = 'Player Results',
				mediawikiForm = 'Team Player Results',
				form = 'Team Player Results/LH',
				template = 'Team player results',
				queryArg = 'team',
			},
		},
	},
}

return PROFILE_TYPES
