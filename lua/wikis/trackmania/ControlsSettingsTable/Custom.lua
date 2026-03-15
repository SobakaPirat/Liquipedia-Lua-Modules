---
-- @Liquipedia
-- page=Module:ControlsSettingsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local ControlsSettingsTable = Lua.import('Module:ControlsSettingsTable')

local CustomControlsSettingsTable = Class.new(ControlsSettingsTable)

---@type string[]
local LPDB_CONFIG = {'Accelerate', 'Brake', 'Steering', 'Camera_Change', 'Show_Hide_Opponents', 'Show_Hide_Interface'}

---@class ColumnConfig
---@field key? string
---@field keys? ({key: string} | string)[]
---@field title string

---@type ColumnConfig[]
local COLUMN_CONFIG = {
	{key = 'Accelerate', title = 'Accelerate'},
	{key = 'Brake', title = 'Brake'},
	{keys = {{key = 'Steering_left'}, ' - ', {key = 'Steering_right'}}, title = 'Steering'},
	{key = 'Camera_Change', title = 'Camera Change'},
	{key = 'Show_Hide_Opponents', title = 'Show/Hide Opponents'},
	{key = 'Show_Hide_Interface', title = 'Show/Hide Interface'},
}

---@param frame table
---@return Widget?
function CustomControlsSettingsTable.create(frame)
	return ControlsSettingsTable.create(LPDB_CONFIG, COLUMN_CONFIG, frame)
end

return CustomControlsSettingsTable
