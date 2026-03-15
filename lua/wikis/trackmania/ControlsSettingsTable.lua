---
-- @Liquipedia
-- page=Module:ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local ControlsSettingsTableWidget = Lua.import('Module:Widget/ControlsSettingsTable')

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
	local widget = ControlsSettingsTableWidget(instance.args, columnConfig)
	instance:saveToLpdb(instance.args)
	return widget:tryMake()
end

function ControlsSettingsTable:generateLpdbExtradata()
	local result = {}
	for _, config in ipairs(self.columnConfig) do
		result[config.name:lower()] = self.args[config.name:lower()]
	end
	return result
end

function ControlsSettingsTable:saveToLpdb(args)
	mw.ext.LiquipediaDB.lpdb_settings(self.title, {
		name = 'movement',
		reference = args.ref,
		lastupdated = args.date,
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(self:generateLpdbExtradata()),
		type = (args.controller or ''):lower(),
	})
end

return ControlsSettingsTable
