---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Legacy version for smash, brawhalla and fighters as they are not on standardized prize pools yet
-- they do not have team events (and no teamCard usage) hence only overwrite the player function

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Lpdb = require('Module:Lpdb')
local MathUtils = require('Module:Math')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local CustomEarnings = Table.deepCopy(Lua.import('Module:Earnings/Base', {requireDevIfEnabled = true}))

---
-- Entry point for players and individuals
-- @player - the player/individual for whom the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @noRedirect - (optional) player redirects get not resolved before query
-- @playerPositionLimit - (optional) the number for how many params the query should look in LPDB
-- @perYear - (optional) query all earnings per year and return the values in a lua table
function CustomEarnings.calculateForPlayer(args)
	args = args or {}
	local player = args.player

	if String.isEmpty(player) then
		return 0
	end
	if not Logic.readBool(args.noRedirect) then
		player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
	else
		player = player:gsub('_', ' ')
	end

	-- since TeamCards on some wikis store players with underscores and some with spaces
	-- we need to check for both options
	local playerAsPageName = player:gsub(' ', '_')

	local playerPositionLimit = tonumber(args.playerPositionLimit) or CustomEarnings.defaultNumberOfStoredPlayersPerMatch
	if playerPositionLimit <= 0 then
		error('"playerPositionLimit" has to be >= 1')
	end

	local playerConditions = {
		'[[participant::' .. player .. ']]',
		'[[participant::' .. playerAsPageName .. ']]',
		'[[participantlink::' .. player .. ']]',
		'[[participantlink::' .. playerAsPageName .. ']]',
		'[[opponentname::' .. player .. ']]',
		'[[opponentname::' .. playerAsPageName .. ']]',
	}

	for playerIndex = 1, playerPositionLimit do
		table.insert(playerConditions, '[[opponentplayers_p' .. playerIndex .. '::' .. player .. ']]')
		table.insert(playerConditions, '[[opponentplayers_p' .. playerIndex .. '::' .. playerAsPageName .. ']]')
		table.insert(playerConditions, '[[players_p' .. playerIndex .. '::' .. player .. ']]')
		table.insert(playerConditions, '[[players_p' .. playerIndex .. '::' .. playerAsPageName .. ']]')
	end

	playerConditions = '(' .. table.concat(playerConditions, ' OR ') .. ')'

	return CustomEarnings.calculate(playerConditions, args.year, args.mode, args.perYear, nil, true)
end

---
-- Calculates earnings for this participant in a certain mode
-- @participantCondition - the condition to find the player/team
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
-- @perYear - (optional) query all earnings per year and return the values in a lua table
-- @aliases - players/teams to determine earnings for
function CustomEarnings.calculate(conditions, queryYear, mode, perYear, aliases, isPlayerQuery)
	conditions = CustomEarnings._buildConditions(conditions, queryYear, mode)

	local sums = {}
	local totalEarnings = 0
	local sumUp = function(placement)
		local value = CustomEarnings._determineValue(placement, aliases, isPlayerQuery)
		if perYear then
			local year = string.sub(placement.date, 1, 4)
			if not sums[year] then
				sums[year] = 0
			end
			sums[year] = sums[year] + value
		end

		totalEarnings = totalEarnings + value
	end

	local queryParameters = {
		conditions = conditions,
		query = 'individualprizemoney, prizemoney, opponentplayers, date, opponenttype, opponentname',
	}
	Lpdb.executeMassQuery('placement', queryParameters, sumUp)

	if not perYear then
		return MathUtils._round(totalEarnings)
	end

	local totalEarningsByYear = {}
	for year, earningsOfYear in pairs(sums) do
		totalEarningsByYear[tonumber(year)] = MathUtils._round(earningsOfYear)
	end

	return MathUtils._round(totalEarnings), totalEarningsByYear
end

function CustomEarnings._determineValue(placement)
	local indivPrize = tonumber(placement.individualprizemoney) or 0
	if indivPrize > 0 then
		return indivPrize
	end

	-- they currently set 1 lpdb_placement object per player with individualprizemoney in prizemoney field
	-- in many cases individualprizemoney field is unset
	return tonumber(placement.prizemoney) or 0
end

return Class.export(CustomEarnings)
