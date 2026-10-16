---
-- @Liquipedia
-- page=Module:PlayerTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Generic module for player profile tabs.
-- Reads the configuration from Module:Info of the respective wiki.
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

local PlayerTabs = {}

---Returns the playerTabs config section of the current wiki's Module:Info.
---@private
---@return {
---	subpages: (string|{name: string?, link: string?}?[])?,
---	alwaysSubpages: (string|{name: string?, link: string?}?[])?,
---	runQueryTabs: {displayName: string?, mediawikiForm: string?, form: string,
---		template: string?, queryArgs: table?}[]?,
---}
function PlayerTabs._config()
	return (Info.config and Info.config.playerTabs) or {}
end

---Template entry point.
---@param frame Frame
---@return Renderable?
function PlayerTabs.run(frame)
	local args = Arguments.getArgs(frame)

	local pageName = mw.title.getCurrentTitle().prefixedText

	local subpageName = string.gsub(pageName, '.*/([^/]+)$', '%1')
	local player = string.gsub(pageName, '(.*)/[^/]-$', '%1')

	local displayTitle = args.title or PlayerTabs._getDisplayTitle(player, subpageName)

	Page.setDisplayTitle{
		title = displayTitle,
	}

	return Tabs.static(PlayerTabs.getTabArgs(player, args))
end

---Builds the display title for player pages, e.g. `Twizzler: Results` on subpages.
---@private
---@param player string
---@param subpageName string
---@return string?
function PlayerTabs._getDisplayTitle(player, subpageName)
	if player == subpageName then
		return
	end

	local data = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. player:gsub(' ', '_') .. ']]',
		query = 'id',
	})
	local title = (data[1] or {}).id or player

	if PlayerTabs.isSubpage(subpageName) then
		title = title .. ': ' .. subpageName
	end

	return title
end

---Returns the list of configured subpage names for the current wiki.
---Returns the actual page names (`link`) so `isSubpage` matches real page names,
---not the display names.
---@return string[]
function PlayerTabs.getSubpages()
	local names = {}
	for _, subpage in ipairs(PlayerTabs.getSubpageConfigs()) do
		table.insert(names, subpage.link)
	end
	return names
end

---Returns the normalized subpage tab configurations.
---Each entry is `{name: string, link: string, always: boolean}`, where `name`
---is the tab label and `link` is the actual subpage page name.
---When an entry is a plain string, name and link are the same.
---Subpages from `subpages` are only shown when page exists (`always = false`),
---subpages from `alwaysSubpages` are always shown (`always = true`).
---@return {name: string, link: string, always: boolean}[]
function PlayerTabs.getSubpageConfigs()
	local config = PlayerTabs._config()
	local configs = {}
	local function normalizeSubpage(item, always)
		if type(item) == 'string' then
			return {name = item, link = item, always = always}
		end
		return {
			name = item.name or item.link,
			link = item.link or item.name,
			always = always,
		}
	end
	for _, item in ipairs(config.subpages or {}) do
		table.insert(configs, normalizeSubpage(item, false))
	end
	for _, item in ipairs(config.alwaysSubpages or {}) do
		table.insert(configs, normalizeSubpage(item, true))
	end
	return configs
end

---Checks whether the given page name is one of the configured player subpages.
---@param subpageName string
---@return boolean
function PlayerTabs.isSubpage(subpageName)
	return Table.includes(PlayerTabs.getSubpages(), subpageName)
end

---Builds the tab configuration for player profile tabs.
---@param player string The page name of the player (without the page prefix)
---@param args table? Template arguments passed to the PlayerTabs template
---@return table A table with `nameN`/`linkN` entries compatible with Tabs.static
function PlayerTabs.getTabArgs(player, args)
	local tabArgs = {
		name1 = 'Overview',
		link1 = player,
	}

	local tabCounter = 1

	-- Subpages specific to the wiki.
	-- `name` is the tab label, `link` the actual subpage page name.
	-- Subpages from `alwaysSubpages` are added unconditionally; subpages from
	-- `subpages` are only added when the page actually exists.
	Array.forEach(PlayerTabs.getSubpageConfigs(), function(subpage)
		if subpage.always or Page.exists(player .. '/' .. subpage.link) then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = subpage.name
			tabArgs['link' .. tabCounter] = player .. '/' .. subpage.link
		end
	end)

	-- Query tabs are rendered via the QueryLink widget (as e.g. warcraft/starcraft2 PlayerTabs do),
	-- which builds the lighthouse and legacy MediaWiki RunQuery urls and displays a proper link.
	-- A single module-wide variable (see `_isRunQueryTabsEnabled`) can disable all of them,
	-- e.g. via `{{PlayerTabs|hasH2H=no}}`.
	if PlayerTabs._isRunQueryTabsEnabled(args) then
		Array.forEach(PlayerTabs._config().runQueryTabs or {}, function(query)
			if query.mediawikiForm or query.form then
				tabCounter = tabCounter + 1
				local queryArgs = Table.map(query.queryArgs or {}, function(key, value)
					if type(value) == 'string' then
						return key, StringUtils.interpolate(value, {player = player})
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
---from the template arguments first (e.g. `{{PlayerTabs|queryTabs=no}}`),
---falling back to the page variable of the same name.
---@private
---@param args table? Template arguments passed to the PlayerTabs template
---@return boolean
function PlayerTabs._isRunQueryTabsEnabled(args)
	local varValue = Logic.nilIfEmpty(args and args['queryTabs'])
	if varValue == nil then
		varValue = Variables.varDefault('queryTabs')
	end
	return Logic.readBoolOrNil(varValue) ~= false
end

return PlayerTabs