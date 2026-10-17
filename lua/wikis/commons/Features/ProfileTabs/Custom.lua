---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ProfileTabsController = Lua.import('Module:Features/ProfileTabs/Controller')

---Template entry point; forwards to the layer that orchestrates and renders the tabs.
---@param frame Frame
---@return Renderable?
return {
	run = ProfileTabsController.run,
}
