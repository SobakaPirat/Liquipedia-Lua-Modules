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
local LPDB_CONFIG = {
	'Accelerate', 'Brake', 'Steering', 'Steering_left', 'Steering_right',
	'Camera_Change', 'Camera1', 'Camera2', 'Camera3',
	'Show_Hide_Opponents', 'Show_Hide_Interface', 'Look_Behind',
	'Give_Up', 'Respawn', 'Ac1', 'Ac2', 'Ac3', 'Ac4', 'Ac5',
}

---@type ColumnConfig[]
local BASE_COLUMN_CONFIG = {
	{key = 'Accelerate', title = 'Accelerate'},
	{key = 'Brake', title = 'Brake'},
	{key = 'Camera_Change', title = 'Camera Change'},
	{keys = {{key = 'Camera1'}, ' / ', {key = 'Camera2'}, ' / ', {key = 'Camera3'}}, title = 'Camera (1/2/3)'},
	{key = 'Give_Up', title = 'Give Up'},
	{key = 'Respawn', title = 'Respawn'},
	{keys = {{key = 'Ac1'}, ' / ',
			{key = 'Ac2'}, ' / ',
			{key = 'Ac3'}, ' / ',
			{key = 'Ac4'}, ' / ',
			{key = 'Ac5'}},
			title = 'Action Slot (1/2/3/4/5)'},
	{key = 'Show_Hide_Opponents', title = 'Show/Hide Opponents'},
	{key = 'Show_Hide_Interface', title = 'Show/Hide Interface'},
	{key = 'Look_Behind', title = 'Look Behind'},
}

---@param args {[string]: string?}
---@return ColumnConfig[]
local function makeColumnConfig(args)
	local COLUMN_CONFIG = {}
	for _, col in ipairs(BASE_COLUMN_CONFIG) do
		table.insert(COLUMN_CONFIG, col)
	end

	if args.steering then
		table.insert(COLUMN_CONFIG, 1, {key = 'Steering', title = 'Steering'})
	else
		table.insert(COLUMN_CONFIG, 1, {
			keys = {{key = 'Steering_left'}, ' / ', {key = 'Steering_right'}},
			title = 'Steering (left/right)'
		})
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
