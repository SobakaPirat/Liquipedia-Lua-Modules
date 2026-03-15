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

function CustomControlsSettingsTable.create(frame)
	return ControlsSettingsTable.create(COLUMN_CONFIG, frame)
end

return CustomControlsSettingsTable
