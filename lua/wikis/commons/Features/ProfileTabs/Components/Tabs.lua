---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Components/Tabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Builds the tab arguments for the Tabs widget from the hardcoded profile tab lists.

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local QueryLink = Lua.import('Module:Widget/QueryLink')

local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsTabs = {}

-- Results can be used even when the subpage doesn't exist if the player/team has
-- matches stored in lpdb. This helper checks whether the player/team has matches
-- in lpdb, so the Results tab (and Head to head / Statistics, which depend on it)
-- can be shown.
---@param profileType string
---@param profile string
---@return boolean
local function hasLpdbMatches(profileType, profile)
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

---Reads a boolean flag from the template args first (e.g. `{{PlayerTabs|h2h=true}}`),
---falling back to the wiki variable of the same name. Template args take precedence
---so pages can override the wiki default.
---@private
---@param args table? Template arguments passed to the PlayerTabs template
---@param name string
---@return boolean
local function readFlag(args, name)
	local argValue = args and args[name]
	if argValue ~= nil then
		return Logic.readBool(argValue)
	end
	return Logic.readBool(Variables.varDefault(name))
end

---Builds the tab configuration for profile tabs.
---Overview is always shown; all other tabs are special, i.e. only shown when the subpage exists.
---The Results tab is additionally shown when the player/team has matches stored in LPDB,
---even if the Results subpage does not exist (in which case it links to the subpage anyway).
---@param profileType string
---@param profile string The page name of the player/team (without the page prefix)
---@param args table? Template arguments passed to the PlayerTabs template
---@return table A table with `nameN`/`linkN` entries compatible with Tabs.static
function ProfileTabsTabs.getTabArgs(profileType, profile, args)
	local settings = PROFILE_TYPES[profileType]

	local tabArgs = {
		name1 = 'Overview',
		link1 = profile,
	}

	local tabCounter = 1

	Array.forEach(settings.tabs, function(tabName)
		local showTab = Page.exists(profile .. '/' .. tabName)
		if tabName == 'Results' and not showTab then
			showTab = hasLpdbMatches(profileType, profile)
		end

		-- Run query replacement tab, rendered via QueryLink (lighthouse + legacy MediaWiki RunQuery urls)
		-- Replaces the plain subpage tab in its slot. Only shown when the `replaceTabs` flag
		-- (template arg or wiki-variable) is true and available results data is present.
		-- The flag is checked first since it is usually not set, avoiding further checks.
		local runQueryTab = settings.replaceTabs and settings.replaceTabs[tabName]
		if runQueryTab
			and readFlag(args, 'replaceTabs')
			and (Page.exists(profile .. '/Results') or hasLpdbMatches(profileType, profile)) then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = QueryLink{
				mediawikiForm = runQueryTab.mediawikiForm,
				form = runQueryTab.form,
				template = runQueryTab.template,
				display = runQueryTab.display,
				queryArgs = {[runQueryTab.queryArg] = profile},
			}
			return
		end

		if showTab then
			tabCounter = tabCounter + 1
			local displayName = settings.tabDisplay and settings.tabDisplay[tabName] or tabName
			tabArgs['name' .. tabCounter] = displayName
			tabArgs['link' .. tabCounter] = profile .. '/' .. tabName
		end
	end)

	-- Head to head query tab, rendered via QueryLink (lighthouse + legacy MediaWiki RunQuery urls)
	-- Only shown when the `h2h` flag (template arg or wiki-variable) is true and available results
	-- data is present. The flag is checked first since it is usually not set, avoiding further checks.
	if readFlag(args, 'h2h')
		and (Page.exists(profile .. '/Results') or hasLpdbMatches(profileType, profile)) then
		tabCounter = tabCounter + 1
		tabArgs['name' .. tabCounter] = QueryLink{
			mediawikiForm = settings.headToHead.mediawikiForm,
			form = settings.headToHead.form,
			template = settings.headToHead.template,
			display = 'Head to head',
			queryArgs = {[settings.headToHead.queryArg] = profile},
		}
	end

	-- Statistics query tab, rendered via QueryLink (lighthouse + legacy MediaWiki RunQuery urls)
	-- Only shown when the `statistics` flag (template arg or wiki-variable) is true and available
	-- results data is present. The flag is checked first since it is usually not set, avoiding further checks.
	if settings.statistics
		and readFlag(args, 'statistics')
		and (Page.exists(profile .. '/Results') or hasLpdbMatches(profileType, profile)) then
		tabCounter = tabCounter + 1
		tabArgs['name' .. tabCounter] = QueryLink{
			mediawikiForm = settings.statistics.mediawikiForm,
			form = settings.statistics.form,
			template = settings.statistics.template,
			display = 'Statistics',
			queryArgs = {[settings.statistics.queryArg] = profile},
		}
	end

	return tabArgs
end

return ProfileTabsTabs