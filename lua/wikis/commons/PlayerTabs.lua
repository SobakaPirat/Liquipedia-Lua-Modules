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
local Info = Lua.import('Module:Info', {loadData = true})
local Page = Lua.import('Module:Page')
local StringUtils = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')

local QueryLink = Lua.import('Module:Widget/QueryLink')

local PlayerTabs = {}

---Returns the playerTabs config section of the current wiki's Module:Info.
---@private
---@return {subpages: string[]?, alwaysSubpages: string[]?, runQueryTabs: table[]?}
function PlayerTabs._config()
	return (Info.config and Info.config.playerTabs) or {}
end

---Template entry point.
---@return Renderable?
function PlayerTabs.run()
	local pageName = mw.title.getCurrentTitle().prefixedText

	local subpageName = string.gsub(pageName, '.*/([^/]+)$', '%1')
	local player = string.gsub(pageName, '(.*)/[^/]-$', '%1')

	Page.setDisplayTitle{
		title = PlayerTabs._getDisplayTitle(player, subpageName),
	}

	return Tabs.static(PlayerTabs.getTabArgs(player))
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

---Returns the subpage list configured for the current wiki in Module:Info.
---@return string[]
---Returns the list of configured subpage names for the current wiki.
---Includes both conditional (`subpages`) and always-visible (`alwaysSubpages`) subpages.
---@return string[]
function PlayerTabs.getSubpages()
	local config = PlayerTabs._config()
	local names = {}
	for _, list in ipairs({config.subpages or {}, config.alwaysSubpages or {}}) do
		for _, name in ipairs(list) do
			table.insert(names, name)
		end
	end
	return names
end

---Returns the normalized subpage tab configurations.
---Each entry is `{name: string, always: boolean}`.
---Subpages from `subpages` are only shown when the page exists (`always = false`),
---subpages from `alwaysSubpages` are always shown (`always = true`).
---@return {name: string, always: boolean}[]
function PlayerTabs.getSubpageConfigs()
	local config = PlayerTabs._config()
	local configs = {}
	for _, name in ipairs(config.subpages or {}) do
		table.insert(configs, {name = name, always = false})
	end
	for _, name in ipairs(config.alwaysSubpages or {}) do
		table.insert(configs, {name = name, always = true})
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
---@return table A table with `nameN`/`linkN` entries compatible with Tabs.static
function PlayerTabs.getTabArgs(player)
	local tabArgs = {
		name1 = 'Overview',
		link1 = player,
	}

	local tabCounter = 1

	-- Subpages specific to the wiki.
	-- Subpages from `alwaysSubpages` are added unconditionally; subpages from
	-- `subpages` are only added when the page actually exists.
	Array.forEach(PlayerTabs.getSubpageConfigs(), function(subpage)
		if subpage.always or Page.exists(player .. '/' .. subpage.name) then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = subpage.name
			tabArgs['link' .. tabCounter] = player .. '/' .. subpage.name
		end
	end)

	-- Query tabs are rendered via the QueryLink widget (as e.g. warcraft/starcraft2 PlayerTabs do),
	-- which builds the lighthouse and legacy MediaWiki RunQuery urls and displays a proper link.
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

	return tabArgs
end

return PlayerTabs