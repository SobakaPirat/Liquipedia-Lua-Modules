---
-- @Liquipedia
-- page=Module:ControlsSettingsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')

local ControlsSettingsTable = Lua.import('Module:ControlsSettingsTable')

local CustomControlsSettingsTable = Class.new(ControlsSettingsTable)

---@type string[]
local LPDB_CONFIG = {'Accelerate', 'Brake', 'Steering', 'Camera_Change', 'Show_Hide_Opponents', 'Show_Hide_Interface', 'Horn', 'Look_Behind', 'Give_Up', 'Respawn', 'Ac_1', 'Ac_2', 'Ac_3', 'Ac_4', 'Ac_5', 'Camera_1', 'Camera_2', 'Camera_3'}

---@param args {[string]: string?}
---@return ({key: string, title: string} | {keys: ({key: string} | string)[], title: string})[]
local function makeColumnConfig(args)
	local COLUMN_CONFIG = {
		{key = 'Accelerate', title = 'Accelerate'},
		{key = 'Brake', title = 'Brake'},
		{key = 'Camera_Change', title = 'Camera Change'},
		{key = 'Show_Hide_Opponents', title = 'Show/Hide Opponents'},
		{key = 'Show_Hide_Interface', title = 'Show/Hide Interface'},
		{key = 'Horn', title = 'Horn'},
		{key = 'Look_Behind', title = 'Look Behind'},
		{key = 'Give_Up', title = 'Give Up'},
		{key = 'Respawn', title = 'Respawn'},
		{key = 'Ac_1', title = 'Action Slot 1'},
		{key = 'Ac_2', title = 'Action Slot 2'},
		{key = 'Ac_3', title = 'Action Slot 3'},
		{key = 'Ac_4', title = 'Action Slot 4'},
		{key = 'Ac_5', title = 'Action Slot 5'},
		{key = 'Camera_1', title = 'Camera 1'},
		{key = 'Camera_2', title = 'Camera 2'},
		{key = 'Camera_3', title = 'Camera 3'},
	}

	if args.steering then
		table.insert(COLUMN_CONFIG, 3, {key = 'Steering', title = 'Steering'})
	else
		table.insert(COLUMN_CONFIG, 3, {keys = {{key = 'Steering_left'}, ' / ', {key = 'Steering_right'}}, title = 'Steering (left/right)'})
	end

	return COLUMN_CONFIG
end

---@param frame table
---@return Widget?
function CustomControlsSettingsTable.create(frame)
	local args = Arguments.getArgs(frame)
	local COLUMN_CONFIG = makeColumnConfig(args)
	return ControlsSettingsTable.create(LPDB_CONFIG, COLUMN_CONFIG, frame)
end

return CustomControlsSettingsTable
