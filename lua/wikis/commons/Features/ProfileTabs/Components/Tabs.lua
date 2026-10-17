---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Components/Tabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Builds the tab arguments for the Tabs widget from the profile's subpage and query configs.

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Page = Lua.import('Module:Page')
local StringUtils = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local QueryLink = Lua.import('Module:Widget/QueryLink')

local ProfileTabsApiConfig = Lua.import('Module:Features/ProfileTabs/Api/Config')
local ProfileTabsRunQueryTabs = Lua.import('Module:Features/ProfileTabs/Lib/RunQueryTabs')
local ProfileTabsSubpages = Lua.import('Module:Features/ProfileTabs/Lib/Subpages')
local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsTabs = {}

---Builds the tab configuration for profile tabs.
---@param profileType string
---@param profile string The page name of the player/team (without the page prefix)
---@param args table? Template arguments passed to the ProfileTabs template
---@return table A table with `nameN`/`linkN` entries compatible with Tabs.static
function ProfileTabsTabs.getTabArgs(profileType, profile, args)
	local settings = PROFILE_TYPES[profileType]

	local tabArgs = {
		name1 = 'Overview',
		link1 = profile,
	}

	local tabCounter = 1

	-- Subpages: `defaultSubpages` always shown first, `specialSubpages` only when the page exists.
	Array.forEach(ProfileTabsSubpages.getSubpageConfigs(profileType), function(subpage)
		if subpage.default or Page.exists(profile .. '/' .. subpage.link) then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = subpage.name
			tabArgs['link' .. tabCounter] = profile .. '/' .. subpage.link
		end
	end)

	-- Query tabs render via QueryLink (lighthouse + legacy MediaWiki RunQuery urls); `queryTabs=no` disables them all.
	if ProfileTabsRunQueryTabs.isRunQueryTabsEnabled(args) then
		Array.forEach(ProfileTabsApiConfig.config(profileType).runQueryTabs or {}, function(query)
			if query.mediawikiForm or query.form then
				tabCounter = tabCounter + 1
				local queryArgs = Table.map(query.queryArgs or {}, function(key, value)
					if type(value) == 'string' then
						return key, StringUtils.interpolate(value, {[settings.interpolationKey] = profile})
					end
					return key, value
				end)
				tabArgs['name' .. tabCounter] = QueryLink{
					mediawikiForm = query.mediawikiForm,
					form = query.form,
					template = query.template,
					display = query.displayName or 'Query',
					queryArgs = queryArgs,
				}
			end
		end)
	end

	return tabArgs
end

return ProfileTabsTabs