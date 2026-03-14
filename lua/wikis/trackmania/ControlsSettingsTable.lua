---
-- @Liquipedia
-- page=Module:ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
--local Info = require('Module:Info')

local ControlsSettingsTableWidget = Lua.import('Module:Widget/ControlsSettingsTable')

--local CONTROLS_SETTINGS_TABLE = Info.config.ControlsSettingsTable

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

local ControlsSettingsTable = Class.new(
	function(self, frame)
		self.frame = frame or mw.getCurrentFrame()
		self.args = Arguments.getArgs(frame)
		self.title = mw.title.getCurrentTitle().text
	end
)

function ControlsSettingsTable.create(frame)
	local instance = ControlsSettingsTable(frame)
	local args = instance.args
	local widget = ControlsSettingsTableWidget(args, COLUMN_CONFIG)
	instance:saveToLpdb(args, widget)

	return widget:tryMake()
end

---@param args table
---@return table<string, string?>
function ControlsSettingsTable:generateLpdbExtradata(args)
	local result = {}
	for _, config in ipairs(COLUMN_CONFIG) do
		result[config.name:lower()] = args[config.name:lower()]
	end
	return result
end

---@param args table
function ControlsSettingsTable:saveToLpdb(args)
	local lpdbData = self:generateLpdbExtradata(args)
	mw.ext.LiquipediaDB.lpdb_settings(self.title, {
		name = 'movement',
		reference = args.ref,
		lastupdated = args.date,
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData),
		type = (args.controller or ''):lower(),
	})
end

return ControlsSettingsTable
