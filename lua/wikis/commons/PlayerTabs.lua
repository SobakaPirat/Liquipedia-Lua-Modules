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
---@return {subpages: string[]?, runQueryTabs: {displayName: string?, form: string, template: string?, queryArgs: table?}[]?}
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
function PlayerTabs.getSubpages()
	return PlayerTabs._config().subpages or {}
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

	-- Subpages specific to the wiki
	Array.forEach(PlayerTabs.getSubpages(), function(item)
		if Page.exists(player .. '/' .. item) then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = item
			tabArgs['link' .. tabCounter] = player .. '/' .. item
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