---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Lib/RunQueryTabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local ProfileTabsRunQueryTabs = {}

---Checks whether run query tabs show: template arg `queryTabs` overrides page variable; `0`/`no` hides all.
---@param args table? Template arguments passed to the ProfileTabs template
---@return boolean
function ProfileTabsRunQueryTabs.isRunQueryTabsEnabled(args)
	local varValue = Logic.nilIfEmpty(args and args['queryTabs'])
	if varValue == nil then
		varValue = Variables.varDefault('queryTabs')
	end
	return Logic.readBoolOrNil(varValue) ~= false
end

return ProfileTabsRunQueryTabs