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
local Template = Lua.import('Module:Template')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local SETTINGS_LINK = 'Control settings'

---@class ControlsSettingsTableWidget: Widget
---@field args {[string]: string?}
---@field columnConfig ColumnConfig[]
---@field frame table
local ControlsSettingsTableWidget = Class.new(Widget,
	function(self, columnConfig, args, frame)
		self.columnConfig = columnConfig
		self.args = args
		self.frame = frame or mw.getCurrentFrame()
	end
)

---@return Widget?
function ControlsSettingsTableWidget:render()
	local header = self:renderHeader(self.args)
	local footer = self:renderFooter(self.args)
	local visibleColumns = self:getVisibleColumns(self.args)

	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = {self:renderTable(self.args, header, footer, visibleColumns)}
	}
end

---@param args table
---@return string
function ControlsSettingsTableWidget:renderHeader(args)
	local frame = self.frame
	local header = Page.exists(SETTINGS_LINK) and '[['.. SETTINGS_LINK ..']] ' or SETTINGS_LINK..' '
	if args.ref == 'insidesource' then
		header = header .. frame:callParserFunction{ name = '#tag', args = { 'ref', Template.safeExpand(frame, 'inside source') } }
	elseif args.ref then
		header = header .. frame:callParserFunction{ name = '#tag', args = { 'ref', args['ref'] } }
	end
	return header .. " <small>([[List of player control settings|list of]])</small>'''"
end

---@param args table
---@return string
function ControlsSettingsTableWidget:renderFooter(args)
	if args.date then
		local year, month, day = (args.date):match('(%d+)-(%d+)-(%d+)')
		local dayAgo = math.floor((os.time() - os.time{year=year, month=month, day=day}) / 86400)
		return '<i>Last updated on '.. args.date ..' (' .. dayAgo ..' days ago).</i>'
	end
	return '<span class="cinnabar-text"><i>No date of last update specified!</i></span>'
end

---@param args table
---@return {title: string, value: fun(data: table): string?}[]
function ControlsSettingsTableWidget:getVisibleColumns(args)
	local columns = Array.map(self.columnConfig, function(config)
		return self:makeColumn(config)
	end)
	return Array.filter(columns, function(column)
		return String.isNotEmpty(column.value(args))
	end)
end

---@param config ColumnConfig
---@return {title: string, value: fun(data: table): string?}
function ControlsSettingsTableWidget:makeColumn(config)
	return {
		title = config.title,
		value = function(data)
			local key = config.key:lower()
			if data.controller and data.controller:lower() == 'kbm' then
				return data[key] and '<kbd>' .. data[key] .. '</kbd>' or nil
			end
			return '[[File:' .. self:getImageName(data.controller, data[key]) .. '.svg|' .. config.key .. '|link=]]'
		end
	}
end

---@param device string?
---@param key string?
---@return string?
function ControlsSettingsTableWidget:getImageName(device, key)
	return Template.safeExpand(self.frame, 'Button translation', {(device or ''):lower(), (key or ''):lower()})
end

---@param args table
---@param header string
---@param footer string
---@param visibleColumns {title: string, value: fun(data: table): string?}[]
---@return Widget
function ControlsSettingsTableWidget:renderTable(args, header, footer, visibleColumns)
	return HtmlWidgets.Table{
		classes = {'wikitable', 'controls-responsive-table'},
		css = {['table-layout'] = 'auto'},
		children = WidgetUtil.collect(
			HtmlWidgets.Tr{children = {
				HtmlWidgets.Th{
					attributes = {colspan = #self.columnConfig},
					children = header
					}
			}},
			HtmlWidgets.Tr{children = Array.map(visibleColumns, function(column)
				return HtmlWidgets.Th{children = column.title}
			end)},
			HtmlWidgets.Tr{children = Array.map(visibleColumns, function(column)
				return HtmlWidgets.Td{
					attributes = {['data-label'] = column.title},
					children = column.value(args)
					}
			end)},
			HtmlWidgets.Tr{children = {
				HtmlWidgets.Th{
					attributes = {colspan = #self.columnConfig},
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

return ControlsSettingsTableWidget
