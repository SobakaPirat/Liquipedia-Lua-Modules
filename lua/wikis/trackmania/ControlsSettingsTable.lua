---
-- @Liquipedia
-- page=Module:ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ControlsSettingsTable = {}

local Arguments = require('Module:Arguments')
local Lua = require('Module:Lua')

local ControlsSettingsTableWidget = Lua.import('Module:Widget/ControlsSettingsTable')

function ControlsSettingsTable.create(frame)
	local args = Arguments.getArgs(frame)
	local widget = ControlsSettingsTableWidget(args)

	mw.ext.LiquipediaDB.lpdb_settings(mw.title.getCurrentTitle().text, {
		name = 'movement',
		reference = args.ref,
		lastupdated = args.date,
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(widget:getLpdbData()),
		type = (args.controller or ''):lower(),
	})

	return widget:tryMake()
end

return ControlsSettingsTable
