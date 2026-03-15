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

local ControlsSettingsTable = Class.new(
	function(self, frame, columnConfig)
		self.frame = frame or mw.getCurrentFrame()
		self.args = Arguments.getArgs(frame)
		self.columnConfig = columnConfig
		self.title = mw.title.getCurrentTitle().text
	end
)

function ControlsSettingsTable.create(frame, columnConfig)
	local instance = ControlsSettingsTable(frame, columnConfig)
	local args = instance.args
	local widget = ControlsSettingsTableWidget(args, columnConfig)
	instance:saveToLpdb(args, widget)

	return widget:tryMake()
end

---@param args table
---@return table<string, string?>
function ControlsSettingsTable:generateLpdbExtradata(args)
	local result = {}
	for _, config in ipairs(self.columnConfig) do
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
