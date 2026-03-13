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

---@class ColumnConfig
---@field name string
---@field title string

---@type ColumnConfig[]
local COLUMN_CONFIG = {
	{name = 'Accelerate', title = 'Accelerate'},
	{name = 'Brake', title = 'Brake'},
	{name = 'Steering', title = 'Steering'},
	{name = 'Camera_Change', title = 'Camera Change'},
	{name = 'Show_Hide_Opponents', title = 'Show/Hide Opponents'},
	{name = 'Show_Hide_Interface', title = 'Show/Hide Interface'},
}

---@param config ColumnConfig
---@return {title: string, value: fun(data: table): string?}
local function makeColumn(config)
	return {
		title = config.title,
		value = function(data)
			local key = config.name:lower()
			if data.controller and data.controller:lower() == 'kbm' then
				return data[key] and '<kbd>' .. data[key] .. '</kbd>' or nil
			end
			return '[[File:' .. getImageName(data.controller, data[key]) .. '.svg|' .. config.name .. '|link=]]'
		end
	}
end

---@type {title: string, value: fun(data: table): string?}[]
local COLUMNS = Array.map(COLUMN_CONFIG, makeColumn)

---@param data table
---@return table<string, string?>
local function generateLpdbExtradata(data)
    local result = {}
    for _, config in ipairs(COLUMN_CONFIG) do
        result[config.name:lower()] = data[config.name:lower()]
    end
    return result
end

---@param args table
---@return string
local function renderHeader(args)
	local header = Page.exists(EXPLAINATION_LINK) and '[['.. EXPLAINATION_LINK ..']] ' or EXPLAINATION_LINK..' '

	if args.ref then
		if args.ref:lower() == 'player' then
			header = header .. '[[category:Player Submitted Hardware]] <sup><i><b><small><small><abbr title="The player has submitted their own hardware information to Liquipedia">Player Submitted</abbr></small></small></b></i></sup>'
		else
			header = header .. mw.getCurrentFrame():callParserFunction{ name = '#tag', args = { 'ref', args['ref'] } }
		end
	end
	return header .. ' <small>([['.. LIST_LINK ..'|list of]])</small>'
end

---@param args table
---@return string
local function renderFooter(args)
	if args.date then
		local year, month, day = (args.date):match('(%d+)-(%d+)-(%d+)')
		local dayAgo = math.floor((os.time() - os.time{year=year, month=month, day=day}) / 86400)
		return '<i>Last updated on '.. args.date ..' (' .. dayAgo ..' days ago).</i>'
	end
	return '<span class="cinnabar-text"><i>No date of last update specified!</i></span>'
end

---@param args table
---@return {title: string, value: fun(data: table): string?}[]
local function getVisibleColumns(args)
	return Array.filter(COLUMNS, function(column)
		return String.isNotEmpty(column.value(args))
	end)
end

---@param args table
---@param header string
---@param footer string
---@param visibleColumns {title: string, value: fun(data: table): string?}[]
---@return Widget
local function renderTable(args, header, footer, visibleColumns)
	return HtmlWidgets.Table{
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
						['font-size'] = '85%',
						padding = '2px',
					},
					children = footer
				}
			}}
		)
	}
end

---@return Widget?
function ControlsSettingsTableWidget:render()
	local args = self.props

	local header = renderHeader(args)
	local footer = renderFooter(args)
	local visibleColumns = getVisibleColumns(args)

	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = {renderTable(args, header, footer, visibleColumns)}
	}
end

---@return table<string, string?>
function ControlsSettingsTableWidget:getLpdbData()
	return generateLpdbExtradata(self.props)
end

return ControlsSettingsTableWidget
