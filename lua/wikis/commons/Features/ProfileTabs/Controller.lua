---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Orchestration: resolves the profile type, derives the display title and renders the tabs.

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Page = Lua.import('Module:Page')
local Tabs = Lua.import('Module:Tabs')

local ProfileTabsApiDisplayTitle = Lua.import('Module:Features/ProfileTabs/Api/DisplayTitle')
local ProfileTabsComponentsTabs = Lua.import('Module:Features/ProfileTabs/Components/Tabs')
local ProfileTabsSubpages = Lua.import('Module:Features/ProfileTabs/Lib/Subpages')
local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsController = {}

---Resolves the profile type from an explicit arg or `target`, falling back to `player` for direct invocations.
---@private
---@param first string|table Either the profile type or the frame.
---@param frame Frame?
---@return string profileType
---@return table|nil frame
function ProfileTabsController._resolveProfileType(first, frame)
	-- Direct invocation: the first argument is the frame itself, so read `target` from its args.
	if type(first) ~= 'string' then
		local args = Arguments.getArgs(first)
		return PROFILE_TYPES[args.target] and args.target or 'player', first
	end

	return PROFILE_TYPES[first] and first or 'player', frame
end

---Builds the display title for profile pages, e.g. `Twizzler: Results` on subpages.
---@private
---@param profileType string
---@param profile string
---@param subpageName string
---@return string?
function ProfileTabsController._getDisplayTitle(profileType, profile, subpageName)
	if profile == subpageName then
		return
	end

	local title = ProfileTabsApiDisplayTitle.get(profileType, profile) or profile

	if ProfileTabsSubpages.isSubpage(profileType, subpageName) then
		title = title .. ': ' .. subpageName
	end

	return title
end

---Template entry point.
---@param first string|table Either the profile type or the frame.
---@param frame Frame?
---@return Renderable?
function ProfileTabsController.run(first, frame)
	local profileType, resolvedFrame = ProfileTabsController._resolveProfileType(first, frame)
	frame = resolvedFrame or frame
	local args = Arguments.getArgs(frame)

	local pageName = mw.title.getCurrentTitle().prefixedText

	local subpageName = string.gsub(pageName, '.*/([^/]+)$', '%1')
	local profile = string.gsub(pageName, '(.*)/[^/]-$', '%1')

	local displayTitle = args.title or ProfileTabsController._getDisplayTitle(profileType, profile, subpageName)

	Page.setDisplayTitle{
		title = displayTitle,
	}

	return Tabs.static(ProfileTabsComponentsTabs.getTabArgs(profileType, profile, args))
end

return ProfileTabsController

