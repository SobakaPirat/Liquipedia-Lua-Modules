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
---@field key string
---@field title string
---@field keys? string[]
---@field value? fun(args: {[string]: string}): string?
---@type ColumnConfig[]
local COLUMN_CONFIG = {
	{key = 'Accelerate', title = 'Accelerate'},
	{key = 'Brake', title = 'Brake'},
	{key = 'Steering', title = 'Steering'},
	{key = 'Camera_Change', title = 'Camera Change'},
	{key = 'Show_Hide_Opponents', title = 'Show/Hide Opponents'},
	{key = 'Show_Hide_Interface', title = 'Show/Hide Interface'},
}

function CustomControlsSettingsTable.create(frame)
	return ControlsSettingsTable.create(COLUMN_CONFIG, frame)
end

return CustomControlsSettingsTable
