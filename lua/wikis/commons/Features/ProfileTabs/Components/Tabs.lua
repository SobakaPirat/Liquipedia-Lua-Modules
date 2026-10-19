---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Components/Tabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Builds the tab arguments for the Tabs widget from the hardcoded profile tab lists.

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Variables = Lua.import('Module:Variables')

local QueryLink = Lua.import('Module:Widget/QueryLink')

local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsTabs = {}

---Builds the tab configuration for profile tabs.
---Overview is always shown; all other tabs are special, i.e. only shown when the subpage exists.
---The head to head query tab is added when the `h2h` wiki-variable is true and the Results subpage exists.
---@param profileType string
---@param profile string The page name of the player/team (without the page prefix)
---@return table A table with `nameN`/`linkN` entries compatible with Tabs.static
function ProfileTabsTabs.getTabArgs(profileType, profile)
	local settings = PROFILE_TYPES[profileType]

	local tabArgs = {
		name1 = 'Overview',
		link1 = profile,
	}

	local tabCounter = 1

	Array.forEach(settings.tabs, function(tabName)
		if Page.exists(profile .. '/' .. tabName) then
			tabCounter = tabCounter + 1
			local displayName = settings.tabDisplay and settings.tabDisplay[tabName] or tabName
			tabArgs['name' .. tabCounter] = displayName
			tabArgs['link' .. tabCounter] = profile .. '/' .. tabName
		end
	end)

	-- Head to head query tab, rendered via QueryLink (lighthouse + legacy MediaWiki RunQuery urls)
	-- Only shown when the `h2h` wiki-variable is true and the Results subpage exists.
	-- The variable is checked first since it is usually not set, avoiding the Page.exists check.
	if Logic.readBool(Variables.varDefault('h2h')) and Page.exists(profile .. '/Results') then
		tabCounter = tabCounter + 1
		tabArgs['name' .. tabCounter] = QueryLink{
			mediawikiForm = settings.headToHead.mediawikiForm,
			form = settings.headToHead.form,
			template = settings.headToHead.template,
			display = 'Head to head',
			queryArgs = {[settings.headToHead.queryArg] = profile},
		}
	end

	return tabArgs
end

return ProfileTabsTabs