---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Orchestration: resolves the profile type, derives the display title and renders the tabs.

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Tabs = Lua.import('Module:Tabs')

local ProfileTabsApiDisplayTitle = Lua.import('Module:Features/ProfileTabs/Api/DisplayTitle')
local ProfileTabsComponentsTabs = Lua.import('Module:Features/ProfileTabs/Components/Tabs')
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

---Returns the subpage tab name `pageName` belongs to, or nil when on the profile main page.
---A page is on a subpage when its name ends in `/` + one of the profile type's tab names.
---@private
---@param profileType string
---@param pageName string
---@return string?
function ProfileTabsController._getSubpageName(profileType, pageName)
	for _, tabName in ipairs(PROFILE_TYPES[profileType].tabs) do
		if pageName:sub(-#tabName - 1) == '/' .. tabName then
			return tabName
		end
	end
end

---Builds the display title for profile pages, e.g. `Twizzler: Results` on subpages.
---Returns nil on profile main pages.
---@private
---@param profileType string
---@param profile string
---@param subpageName string?
---@return string?
function ProfileTabsController._getDisplayTitle(profileType, profile, subpageName)
	if not subpageName then
		return
	end

	local title = ProfileTabsApiDisplayTitle.get(profileType, profile) or profile
	return title .. ': ' .. subpageName
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

	local subpageName = ProfileTabsController._getSubpageName(profileType, pageName)
	local profile = subpageName and pageName:sub(1, -#subpageName - 2) or pageName

	-- Resolve the display title from the `displayTitle` arg:
	-- - nil -> auto-generate from the subpage (e.g. "Twizzler: Results"),
	-- - false -> restore the default page title (e.g. `{{...|displayTitle=false}}`),
	-- - any other string -> use it as the custom title directly.
	local displayTitle
	if args.displayTitle == nil then
		displayTitle = ProfileTabsController._getDisplayTitle(profileType, profile, subpageName)
	elseif Logic.readBoolOrNil(args.displayTitle) ~= false then
		displayTitle = args.displayTitle
	end

	Page.setDisplayTitle{
		title = displayTitle,
	}

	return Tabs.static(ProfileTabsComponentsTabs.getTabArgs(profileType, profile, args))
end

return ProfileTabsController
