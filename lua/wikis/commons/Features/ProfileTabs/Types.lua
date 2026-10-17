---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---Configuration for a profile type's tabs, read from the wiki's Module:Info.
---@class ProfileTabsConfig
---@field specialSubpages ProfileTabsSubpage[]?
---@field defaultSubpages ProfileTabsSubpage[]?
---@field runQueryTabs ProfileTabsQueryTab[]?

---@class ProfileTabsSubpage
---@field name string?
---@field link string?

---@class ProfileTabsQueryTab
---@field displayName string?
---@field mediawikiForm string?
---@field form string
---@field template string?
---@field queryArgs table?

---Per-type metadata that drives all player/team differences.
---@class ProfileTypeDefinition
---@field configKey string
---@field lpdbType string
---@field lpdbQuery string
---@field displayField string
---@field interpolationKey string

---@type table<string, ProfileTypeDefinition>
local PROFILE_TYPES = {
	player = {
		configKey = 'playerTabs',
		lpdbType = 'player',
		lpdbQuery = 'id',
		displayField = 'id',
		interpolationKey = 'player',
	},
	team = {
		configKey = 'teamTabs',
		lpdbType = 'team',
		lpdbQuery = 'name',
		displayField = 'name',
		interpolationKey = 'team',
	},
}

return PROFILE_TYPES
