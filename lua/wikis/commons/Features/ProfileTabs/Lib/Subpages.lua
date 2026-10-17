---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Lib/Subpages
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local ProfileTabsApiConfig = Lua.import('Module:Features/ProfileTabs/Api/Config')

local ProfileTabsSubpages = {}

---Returns the configured subpage page names, so `isSubpage` matches real pages rather than labels.
---@param profileType string
---@return string[]
function ProfileTabsSubpages.getSubpages(profileType)
	local names = {}
	for _, subpage in ipairs(ProfileTabsSubpages.getSubpageConfigs(profileType)) do
		table.insert(names, subpage.link)
	end
	return names
end

---Returns `{name, link, default}` subpage configs: defaults first/always shown, specials after/only if page exists.
---@param profileType string
---@return {name: string, link: string, default: boolean}[]
function ProfileTabsSubpages.getSubpageConfigs(profileType)
	local config = ProfileTabsApiConfig.config(profileType)
	local configs = {}
	local function normalizeSubpage(item, default)
		if type(item) == 'string' then
			return {name = item, link = item, default = default}
		end
		return {
			name = item.name or item.link,
			link = item.link or item.name,
			default = default,
		}
	end
	-- Default subpages are always shown and come first
	for _, item in ipairs(config.defaultSubpages or {}) do
		table.insert(configs, normalizeSubpage(item, true))
	end
	-- Special subpages are only shown when the page exists, after the default ones
	for _, item in ipairs(config.specialSubpages or {}) do
		table.insert(configs, normalizeSubpage(item, false))
	end
	return configs
end

---Checks whether the given page name is one of the configured profile subpages.
---@param profileType string
---@param subpageName string
---@return boolean
function ProfileTabsSubpages.isSubpage(profileType, subpageName)
	return Table.includes(ProfileTabsSubpages.getSubpages(profileType), subpageName)
end

return ProfileTabsSubpages
