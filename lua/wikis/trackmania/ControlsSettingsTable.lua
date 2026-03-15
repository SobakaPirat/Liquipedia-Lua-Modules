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

local ControlsSettingsTable = Class.new()

function ControlsSettingsTable.create(columnConfig, frame)
	local args = Arguments.getArgs(frame)
	local widget = ControlsSettingsTableWidget(columnConfig, args)
	ControlsSettingsTable.saveToLpdb(columnConfig, args)
	return widget:tryMake()
end

function ControlsSettingsTable.saveToLpdb(columnConfig, args)
	local title = mw.title.getCurrentTitle().text
	local extradata = ControlsSettingsTable.generateLpdbExtradata(columnConfig, args)
	mw.ext.LiquipediaDB.lpdb_settings(title, {
		name = 'movement',
		reference = args.ref,
		lastupdated = args.date,
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
		type = (args.controller or ''):lower(),
	})
end

function ControlsSettingsTable.generateLpdbExtradata(columnConfig, args)
	local result = {}
	for _, config in ipairs(columnConfig) do
		result[config.name:lower()] = args[config.name:lower()]
	end
	return result
end

return ControlsSettingsTable
