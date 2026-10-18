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

---@param item string|ProfileTabsSubpage
---@return ProfileTabsSubpageConfig
local function normalizeSubpage(item, default)
	if type(item) == 'string' then
		return {name = item, link = item, default = default}
	end
	-- Accepts `{name = 'X', link = 'Y', subpages = {...}}` (documented) as well as
	-- `{'X', subpages = {...}}` (positional alias) and missing link falls back to name.
	local name = item.name or item[1]
	local link = item.link or name
	return {
		name = name,
		link = link,
		default = default,
		subpages = item.subpages,
	}
end

---Returns the configured subpage page names, so `isSubpage` matches real pages rather than labels.
---Nested subpages are returned as `parent/child` page paths.
---@param profileType string
---@return string[]
function ProfileTabsSubpages.getSubpages(profileType)
	local names = {}
	for _, subpage in ipairs(ProfileTabsSubpages.getSubpageConfigs(profileType)) do
		if subpage.link then
			table.insert(names, subpage.link)
			for _, nested in ipairs(subpage.subpages or {}) do
				local nestedLink = normalizeSubpage(nested).link
				if nestedLink then
					table.insert(names, subpage.link .. '/' .. nestedLink)
				end
			end
		end
	end
	return names
end

---Returns `{name, link, default, subpages}` subpage configs: defaults first/always shown,
---specials after/only if page exists.
---@param profileType string
---@return ProfileTabsSubpageConfig[]
function ProfileTabsSubpages.getSubpageConfigs(profileType)
	local config = ProfileTabsApiConfig.config(profileType)
	local configs = {}
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

---Returns the configured nested subpage configs of a subpage, or an empty table.
---@param profileType string
---@param subpage string The subpage page name (without the profile prefix)
---@return ProfileTabsSubpageConfig[]
function ProfileTabsSubpages.getNestedSubpageConfigs(profileType, subpage)
	for _, config in ipairs(ProfileTabsSubpages.getSubpageConfigs(profileType)) do
		if config.link == subpage then
			local nested = {}
			for _, item in ipairs(config.subpages or {}) do
				table.insert(nested, normalizeSubpage(item))
			end
			return nested
		end
	end
	return {}
end

---Checks whether the given page name is one of the configured profile subpages.
---Accepts both top-level subpages (`Results`) and the subpage of a subpage (`Results/Pre-2020`).
---@param profileType string
---@param subpageName string
---@return boolean
function ProfileTabsSubpages.isSubpage(profileType, subpageName)
	return Table.includes(ProfileTabsSubpages.getSubpages(profileType), subpageName)
end

---Returns the configured subpage page name (possibly including nested subpages)
---that `pageName` belongs to, or nil. Longest match wins.
---@param profileType string
---@param pageName string
---@return string?
function ProfileTabsSubpages.getSubpageFromPageName(profileType, pageName)
	local longest
	for _, subpageName in ipairs(ProfileTabsSubpages.getSubpages(profileType)) do
		if pageName:sub(-#subpageName - 1) == '/' .. subpageName and
			(not longest or #subpageName > #longest) then
			longest = subpageName
		end
	end
	return longest
end

return ProfileTabsSubpages
