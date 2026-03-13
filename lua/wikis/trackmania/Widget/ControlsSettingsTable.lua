---
-- @Liquipedia
-- page=Module:Widget/ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local EXPLAINATION_LINK = 'Control settings'
local LIST_LINK = 'List of player control settings'

---@class ControlsSettingsTableWidget: Widget
---@operator call(table): ControlsSettingsTableWidget
---@field props {
---	controller: string?,
---	ref: string?,
---	date: string?,
---	accelerate: string?,
---	brake: string?,
---	steering: string?,
---	camera_change: string?,
---	show_hide_opponents: string?,
---	show_hide_interface: string?,
---}
local ControlsSettingsTableWidget = Class.new(Widget)

---@param device string?
---@param key string?
---@return string?
local function getImageName(device, key)
	return Template.safeExpand(mw.getCurrentFrame(), 'Button translation', {(device or ''):lower(), (key or ''):lower()})
end

---@param displayName string
---@param argName string?
---@return {title: string, value: fun(data: table): string?}
local function basicColumn(displayName, argName)
	local name = argName or displayName
	return {
		title = displayName,
		value = function(data)
			if data.controller and data.controller:lower() == 'kbm' then
				return data[name:lower()] and '<kbd>'.. (data[name:lower()]) ..'</kbd>' or nil
			end
			return '[[File:'.. getImageName(data.controller, data[name:lower()]) ..'.svg|'.. name ..'|link=]]'
		end
	}
end

---@type {title: string, value: fun(data: table): string?}[]
local COLUMNS = {
	basicColumn('Accelerate'),
	basicColumn('Brake'),
	basicColumn('Steering'),
	basicColumn('Camera Change', 'camera_change'),
	basicColumn('Show/Hide Opponents', 'show_hide_opponents'),
	basicColumn('Show/Hide Interface', 'show_hide_interface'),
}

---@param name string
---@return fun(data: table): string, string?
local function basicStorage(name)
	return function(data)
		return name:lower(), data[name:lower()]
	end
end

---@type fun(data: table): (string, string?)[]
local LPDB_STORAGE = {
	basicStorage('Accelerate'),
	basicStorage('Brake'),
	basicStorage('Steering'),
	basicStorage('Camera_Change'),
	basicStorage('Show_Hide_Opponents'),
	basicStorage('Show_Hide_Interface'),
}

---@param data table
---@return table<string, string?>
local function generateLpdbExtradata(data)
	return Table.map(LPDB_STORAGE, function(field)
		local key, val = field(data)
		return key, val
	end)
end

---@return Widget?
function ControlsSettingsTableWidget:render()
	local args = self.props

	local header = Page.exists(EXPLAINATION_LINK) and '[['.. EXPLAINATION_LINK ..']] ' or EXPLAINATION_LINK..' '

	if args.ref then
		if args.ref:lower() == 'player' then
			header = header .. '[[category:Player Submitted Hardware]] <sup><i><b><small><small><abbr title="The player has submitted their own hardware information to Liquipedia">Player Submitted</abbr></small></small></b></i></sup>'
		else
			header = header .. mw.getCurrentFrame():callParserFunction{ name = '#tag', args = { 'ref', args['ref'] } }
		end
	end
	header = header .. ' <small>([['.. LIST_LINK ..'|list of]])</small>'

	local footer = ''
	if args.date then
		local year, month, day = (args.date):match('(%d+)-(%d+)-(%d+)')
		local dayAgo = math.floor((os.time() - os.time{year=year, month=month, day=day}) / 86400)
		footer = footer .. '<i>Last updated on '.. args.date ..' (' .. dayAgo ..' days ago).</i>'
	else
		footer = footer .. '<span class="cinnabar-text"><i>No date of last update specified!</i></span>'
	end

	local visibleColumns = Array.filter(COLUMNS, function(column)
		return String.isNotEmpty(column.value(args))
	end)

	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = {
			HtmlWidgets.Table{
				classes = {'wikitable', 'rl-responsive-table'},
				css = {
					textAlign = 'center',
					tableLayout = 'auto',
					width = '100%',
				},
				children = WidgetUtil.collect(
					HtmlWidgets.Tr{children = {
						HtmlWidgets.Th{
							attributes = {colspan = #COLUMNS},
							children = header
						}
					}},
					HtmlWidgets.Tr{children = Array.map(visibleColumns, function(column)
						return HtmlWidgets.Th{children = column.title}
					end)},
					HtmlWidgets.Tr{children = Array.map(visibleColumns, function(column)
						return HtmlWidgets.Td{children = column.value(args)}
					end)},
					HtmlWidgets.Tr{children = {
						HtmlWidgets.Th{
							attributes = {colspan = #COLUMNS},
							css = {
								fontSize = '85%',
								padding = '2px',
							},
							children = footer
						}
					}}
				)
			}
		}
	}
end

---@return table<string, string?>
function ControlsSettingsTableWidget:getLpdbData()
	return generateLpdbExtradata(self.props)
end

return ControlsSettingsTableWidget
