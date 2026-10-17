---
-- @Liquipedia
-- page=Module:ProfileTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Generic module for player and team profile tabs.
-- The module is parameterized by a `profileType` ('player' or 'team'),
-- which selects the matching section from Module:Info (`playerTabs`/`teamTabs`),
-- the lpdb type to look up the display name, and the interpolation key used
-- in run query template args.
--
-- It can be invoked directly from a template with `{{#invoke:ProfileTabs|run|target=team}}`;
-- `target` defaults to 'player'. The `run` function also accepts an explicit
-- profile type as its first argument.
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Arguments = Lua.import('Module:Arguments')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local StringUtils = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')
local Variables = Lua.import('Module:Variables')

local QueryLink = Lua.import('Module:Widget/QueryLink')

---Per-type metadata that drives all player/team differences.
---@type table<string, {configKey: string, lpdbType: string, lpdbQuery: string,
---	displayField: string, interpolationKey: string}>
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

local ProfileTabs = {}

---Returns the tabs config section of `profileType` from the wiki's Module:Info.
---@private
---@param profileType string
---@return {
---	specialSubpages: (string|{name: string?, link: string?}?[])?,
---	defaultSubpages: (string|{name: string?, link: string?}?[])?,
---	runQueryTabs: {displayName: string?, mediawikiForm: string?, form: string,
---		template: string?, queryArgs: table?}[]?,
---}
function ProfileTabs._config(profileType)
	local config = PROFILE_TYPES[profileType]
	return (Info.config and Info.config[config.configKey]) or {}
end

---Resolves the profile type from either an explicit argument or from the
---template's `target` parameter.
---
---Supports both calling conventions:
---  * `run(profileType, frame)` — explicit type
---  * `run(frame)` with `{{#invoke:ProfileTabs|run|target=team}}` — direct call
---When nothing resolves to a known type, falls back to `'player'` so plain
---player invocations keep working unchanged.
---@private
---@param first string|table Either the profile type or the frame.
---@param frame Frame?
---@return string profileType
---@return table|nil frame
function ProfileTabs._resolveProfileType(first, frame)
	-- Direct template invocation ({{#invoke:ProfileTabs|run|target=...}}): the
	-- first argument is the frame itself, so read `target` from its args.
	if type(first) ~= 'string' then
		local args = Arguments.getArgs(first)
		return PROFILE_TYPES[args.target] and args.target or 'player', first
	end

	return PROFILE_TYPES[first] and first or 'player', frame
end

---Template entry point.
---@param first string|table Either the profile type or the frame.
---@param frame Frame?
---@return Renderable?
function ProfileTabs.run(first, frame)
	local profileType, resolvedFrame = ProfileTabs._resolveProfileType(first, frame)
	frame = resolvedFrame or frame
	local args = Arguments.getArgs(frame)

	local pageName = mw.title.getCurrentTitle().prefixedText

	local subpageName = string.gsub(pageName, '.*/([^/]+)$', '%1')
	local profile = string.gsub(pageName, '(.*)/[^/]-$', '%1')

	local displayTitle = args.title or ProfileTabs._getDisplayTitle(profileType, profile, subpageName)

	Page.setDisplayTitle{
		title = displayTitle,
	}

	return Tabs.static(ProfileTabs.getTabArgs(profileType, profile, args))
end

---Builds the display title for profile pages, e.g. `Twizzler: Results` on subpages.
---@private
---@param profileType string
---@param profile string
---@param subpageName string
---@return string?
function ProfileTabs._getDisplayTitle(profileType, profile, subpageName)
	if profile == subpageName then
		return
	end

	local settings = PROFILE_TYPES[profileType]

	local data = mw.ext.LiquipediaDB.lpdb(settings.lpdbType, {
		conditions = '[[pagename::' .. profile:gsub(' ', '_') .. ']]',
		query = settings.lpdbQuery,
	})
	local title = (data[1] or {})[settings.displayField] or profile

	if ProfileTabs.isSubpage(profileType, subpageName) then
		title = title .. ': ' .. subpageName
	end

	return title
end


---Returns the list of configured subpage names for the current wiki.
---Returns the actual page names (`link`) so `isSubpage` matches real page names,
---not the display names.
---@param profileType string
---@return string[]
function ProfileTabs.getSubpages(profileType)
	local names = {}
	for _, subpage in ipairs(ProfileTabs.getSubpageConfigs(profileType)) do
		table.insert(names, subpage.link)
	end
	return names
end

---Returns the normalized subpage tab configurations.
---Each entry is `{name: string, link: string, default: boolean}`, where `name`
---is the tab label and `link` is the actual subpage page name.
---When an entry is a plain string, name and link are the same.
---Subpages from `defaultSubpages` are always shown and listed first
---(`default = true`), subpages from `specialSubpages` are shown only when the
---page exists (`default = false`), listed after the default ones.
---@param profileType string
---@return {name: string, link: string, default: boolean}[]
function ProfileTabs.getSubpageConfigs(profileType)
	local config = ProfileTabs._config(profileType)
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
function ProfileTabs.isSubpage(profileType, subpageName)
	return Table.includes(ProfileTabs.getSubpages(profileType), subpageName)
end


---Builds the tab configuration for profile tabs.
---@param profileType string
---@param profile string The page name of the player/team (without the page prefix)
---@param args table? Template arguments passed to the ProfileTabs template
---@return table A table with `nameN`/`linkN` entries compatible with Tabs.static
function ProfileTabs.getTabArgs(profileType, profile, args)
	local settings = PROFILE_TYPES[profileType]

	local tabArgs = {
		name1 = 'Overview',
		link1 = profile,
	}

	local tabCounter = 1

	-- Subpages specific to the wiki.
	-- `name` is the tab label, `link` the actual subpage page name.
	-- Subpages from `defaultSubpages` are added unconditionally and come
	-- first; subpages from `specialSubpages` are added only when the page
	-- actually exists. Order follows `getSubpageConfigs`.
	Array.forEach(ProfileTabs.getSubpageConfigs(profileType), function(subpage)
		if subpage.default or Page.exists(profile .. '/' .. subpage.link) then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = subpage.name
			tabArgs['link' .. tabCounter] = profile .. '/' .. subpage.link
		end
	end)

	-- Query tabs are rendered via the QueryLink widget, which builds the
	-- lighthouse and legacy MediaWiki RunQuery urls and displays a proper link.
	-- A single module-wide variable (see `_isRunQueryTabsEnabled`) can disable all of them,
	-- e.g. via `{{ProfileTabs|queryTabs=no}}`.
	if ProfileTabs._isRunQueryTabsEnabled(args) then
		Array.forEach(ProfileTabs._config(profileType).runQueryTabs or {}, function(query)
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

---Checks whether the run query tabs should be shown at all.
---The variable `queryTabs` controls visibility: when it evaluates to
---false (`0`, `no`, ...) all run query tabs are hidden. The value is read
---from the template arguments first, falling back to the page variable
---of the same name.
---@private
---@param args table? Template arguments passed to the ProfileTabs template
---@return boolean
function ProfileTabs._isRunQueryTabsEnabled(args)
	local varValue = Logic.nilIfEmpty(args and args['queryTabs'])
	if varValue == nil then
		varValue = Variables.varDefault('queryTabs')
	end
	return Logic.readBoolOrNil(varValue) ~= false
end

return ProfileTabs

