---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Show = require('Module:Infobox/Show')
local Namespace = require('Module:Namespace')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomShow = Class.new()

local _show
local _args

local CustomInjector = Class.new(Injector)

function CustomShow.run(frame)
	local customShow = Show(frame)
	_show = customShow
	_args = customShow.args
	customShow.createWidgetInjector = CustomShow.createWidgetInjector
	return customShow:createInfobox(frame)
end

function CustomShow:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'No. of episodes',
		content = {_args['num_episodes']}
	})
	table.insert(widgets, Cell{
		name = 'Original Release',
		content = {CustomShow:_getReleasePeriod(_args.sdate, _args.edate)}
	})

	if Namespace.isMain() and _args.edate == nil then
		_show.infobox:categories('Active Shows')
	end

	return widgets
end

function CustomShow:_getReleasePeriod(sdate, edate)
	if not sdate then return nil end
	return sdate .. ' - ' .. (edate or '<b>Present</b>')
end

return CustomShow
