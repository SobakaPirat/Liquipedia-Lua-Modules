-- luacheck: ignore
--- Triple Comment to Enable our LLS Plugin
describe('ProfileTabs Module', function()
	local Controller = require('Module:Features/ProfileTabs/Controller')
	local ProfileTabsTabs = require('Module:Features/ProfileTabs/Components/Tabs')
	local PROFILE_TYPES = require('Module:Features/ProfileTabs/Types')
	local Page = require('Module:Page')
	local mockLpdb = require('Module:Mock/Lpdb')

	local ProfileTabs = Controller
	ProfileTabs.getTabArgs = ProfileTabsTabs.getTabArgs
	ProfileTabs.getSubpageName = Controller._getSubpageName

	-- Builds the expected mediawiki run query url the same way Widget/QueryLink does
	local function expectedMediawikiUrl(mediawikiForm, template, queryArg, profile)
		return tostring(mw.uri.fullUrl(
			'Special:RunQuery/' .. mediawikiForm,
			{[template .. '[' .. queryArg .. ']'] = profile}
		)):gsub(' ', '%%20')
	end

	local function expectedPlayerH2HUrl(profile)
		return expectedMediawikiUrl('Match history', 'Head_to_head_query', 'player', profile)
	end

	local function expectedTeamH2HUrl(profile)
		return expectedMediawikiUrl('Head2head', 'Headtohead', 'team', profile)
	end

	local function expectedPlayerStatsUrl(profile)
		return expectedMediawikiUrl('PlayerStats', 'Player statistics', 'player', profile)
	end

	local function expectedPlayerResultsUrl(profile)
		return expectedMediawikiUrl('Player Results', 'Player results', 'player', profile)
	end

	local function expectedPlayerMatchesUrl(profile)
		return expectedMediawikiUrl('Player Matches', 'Player Matches', 'player', profile)
	end

	local function expectedTeamResultsUrl(profile)
		return expectedMediawikiUrl('Team Results', 'Team results', 'team', profile)
	end

	local function expectedTeamMatchesUrl(profile)
		return expectedMediawikiUrl('Team Matches', 'Team matches', 'team', profile)
	end

	local function expectedTeamPlayerResultsUrl(profile)
		return expectedMediawikiUrl('Team Player Results', 'Team player results', 'team', profile)
	end

	local origTitleNew
	local titleStub
	before_each(function()
		origTitleNew = mw.title.new
	end)
	after_each(function()
		mw.title.new = origTitleNew
		if titleStub then
			titleStub:revert()
			titleStub = nil
		end
	end)

	-- Mocks Page.exists to only accept the given pages
	local function withExistingPages(existingPages, func)
		local existing = {}
		for _, page in ipairs(existingPages) do
			existing[page] = true
		end
		mw.title.new = function(page)
			return {exists = existing[page] == true}
		end
		return func()
	end

	-- Defines the `h2h` wiki-variable so the Head to head tab is shown
	local function withH2HVariable(func)
		mw.ext.VariablesLua.vardefine('h2h', 'true')
		return func()
	end

	-- Defines the `statistics` wiki-variable so the Statistics tab is shown
	local function withStatisticsVariable(func)
		mw.ext.VariablesLua.vardefine('statistics', 'true')
		return func()
	end

	-- Defines the `replaceTabs` wiki-variable so the run query replacement tabs are shown
	local function withQueryTabsVariable(func)
		mw.ext.VariablesLua.vardefine('replaceTabs', 'true')
		return func()
	end

	describe('getTabArgs', function()
		before_each(function()
			mockLpdb.setUp()
		end)

		after_each(function()
			mockLpdb.tearDown()
		end)

		it('should always include the Overview tab', function()
			withExistingPages({}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler')
				assert.are.equal('Overview', result.name1)
				assert.are.equal('Twizzler', result.link1)
				assert.is_nil(result.name2)
			end)
		end)

		it('should only include special tabs whose subpage exists', function()
			withExistingPages({'Twizzler/Results', 'Twizzler/Awards'}, function()
				-- Results alone is not enough; the `h2h` variable must also be set
				local result = ProfileTabs.getTabArgs('player', 'Twizzler')
				assert.are.equal('Results', result.name2)
				assert.are.equal('Twizzler/Results', result.link2)
				assert.are.equal('Awards', result.name3)
				assert.are.equal('Twizzler/Awards', result.link3)
				assert.is_nil(result.name4)
			end)
		end)

		it('should preserve the hardcoded tab order for players', function()
			local allTabs = {}
			for _, tabName in ipairs(PROFILE_TYPES.player.tabs) do
				table.insert(allTabs, 'Twizzler/' .. tabName)
			end
			withExistingPages(allTabs, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler')
				for index, tabName in ipairs(PROFILE_TYPES.player.tabs) do
					local expectedName = PROFILE_TYPES.player.tabDisplay and PROFILE_TYPES.player.tabDisplay[tabName]
						or tabName
					assert.are.equal(expectedName, result['name' .. (index + 1)])
					assert.are.equal('Twizzler/' .. tabName, result['link' .. (index + 1)])
				end
			end)
		end)

		it('should display Talent for the Broadcasts tab while linking to Broadcasts', function()
			withExistingPages({'Twizzler/Broadcasts'}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler')
				assert.are.equal('Talent', result.name2)
				assert.are.equal('Twizzler/Broadcasts', result.link2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should use the team tab list', function()
			withExistingPages({'twizzler-fans/Teamkills', 'twizzler-fans/Results'}, function()
				local result = ProfileTabs.getTabArgs('team', 'twizzler-fans')
				assert.are.equal('Results', result.name2)
				assert.are.equal('Teamkills', result.name3)
				-- Results exists, but h2h is not set, so no Head to head tab
				assert.is_nil(result.name4)
			end)
		end)

		it('should add a Head to head QueryLink when Results exists and h2h is set', function()
			withExistingPages({'Twizzler/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler')
					assert.are.equal('table', type(result.name3))
					-- The QueryLink widget provides the link itself, no separate link arg
					assert.is_nil(result.link3)
					assert.is_nil(result.name4)

					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerH2HUrl('Twizzler'), nil, true) ~= nil)
					assert.is_true(rendered:find('Head to head', nil, true) ~= nil)
				end)
			end)
		end)

		it('should use the team query arg for teams', function()
			withExistingPages({'twizzler-fans/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabs.getTabArgs('team', 'twizzler-fans')
					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedTeamH2HUrl('twizzler-fans'), nil, true) ~= nil)
				end)
			end)
		end)

		it('should not add the Head to head tab without Results', function()
			withExistingPages({'Twizzler/Awards'}, function()
				withH2HVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler')
					assert.are.equal('Awards', result.name2)
					assert.is_nil(result.name3)
				end)
			end)
		end)

		it('should not add the Head to head tab when the h2h variable is not set', function()
			withExistingPages({'Twizzler/Results'}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler')
				assert.are.equal('Results', result.name2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should encode player names with spaces in Head to head links', function()
			withExistingPages({'Viswanathan Anand/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Viswanathan Anand')
					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerH2HUrl('Viswanathan Anand'), nil, true) ~= nil)
				end)
			end)
		end)

		it('should add a Statistics QueryLink when Results exists and statistics is set', function()
			withExistingPages({'Twizzler/Results'}, function()
				withStatisticsVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler')
					assert.are.equal('table', type(result.name3))
					-- The QueryLink widget provides the link itself, no separate link arg
					assert.is_nil(result.link3)
					assert.is_nil(result.name4)

					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerStatsUrl('Twizzler'), nil, true) ~= nil)
					assert.is_true(rendered:find('Statistics', nil, true) ~= nil)
				end)
			end)
		end)

		it('should not add the Statistics tab when the statistics variable is not set', function()
			withExistingPages({'Twizzler/Results'}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler')
				assert.are.equal('Results', result.name2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should not add the Statistics tab without Results', function()
			withExistingPages({'Twizzler/Awards'}, function()
				withStatisticsVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler')
					assert.are.equal('Awards', result.name2)
					assert.is_nil(result.name3)
				end)
			end)
		end)

		it('should add both the Head to head and Statistics tabs when both variables are set', function()
			withExistingPages({'Twizzler/Results'}, function()
				withH2HVariable(function()
					withStatisticsVariable(function()
						local result = ProfileTabs.getTabArgs('player', 'Twizzler')
						assert.are.equal('table', type(result.name3))
						assert.are.equal('table', type(result.name4))
						assert.is_nil(result.name5)

						local h2h = tostring(result.name3)
						assert.is_true(h2h:find('Head to head', nil, true) ~= nil)
						local stats = tostring(result.name4)
						assert.is_true(stats:find(expectedPlayerStatsUrl('Twizzler'), nil, true) ~= nil)
					end)
				end)
			end)
		end)

		it('should add the Head to head tab when h2h is passed as a template arg', function()
			withExistingPages({'Twizzler/Results'}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler', {h2h = 'true'})
				assert.are.equal('table', type(result.name3))

				local rendered = tostring(result.name3)
				assert.is_true(rendered:find(expectedPlayerH2HUrl('Twizzler'), nil, true) ~= nil)
				assert.is_true(rendered:find('Head to head', nil, true) ~= nil)
			end)
		end)

		it('should add the Statistics tab when statistics is passed as a template arg', function()
			withExistingPages({'Twizzler/Results'}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler', {statistics = 'true'})
				assert.are.equal('table', type(result.name3))

				local rendered = tostring(result.name3)
				assert.is_true(rendered:find(expectedPlayerStatsUrl('Twizzler'), nil, true) ~= nil)
				assert.is_true(rendered:find('Statistics', nil, true) ~= nil)
			end)
		end)

		it('should replace the Results tab when replaceTabs is passed as a template arg', function()
			withExistingPages({'Twizzler/Results'}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler', {replaceTabs = 'true'})
				assert.are.equal('table', type(result.name2))
				assert.is_nil(result.link2)

				local rendered = tostring(result.name2)
				assert.is_true(rendered:find(expectedPlayerResultsUrl('Twizzler'), nil, true) ~= nil)
				assert.is_true(rendered:find('Results', nil, true) ~= nil)
			end)
		end)

		it('should let a template arg override a wiki variable false', function()
			withExistingPages({'Twizzler/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler', {h2h = 'no'})
					assert.are.equal('Results', result.name2)
					assert.is_nil(result.name3)
				end)
			end)
		end)

		it('should add the Results tab when the Results subpage is missing but the player has lpdb matches', function()
			withExistingPages({}, function()
				local result = ProfileTabs.getTabArgs('player', 'Rambo')
				assert.are.equal('Results', result.name2)
				assert.are.equal('Rambo/Results', result.link2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should add the Results tab when the Results subpage is missing but the team has lpdb matches', function()
			withExistingPages({}, function()
				local result = ProfileTabs.getTabArgs('team', 'rambo-fans')
				assert.are.equal('Results', result.name2)
				assert.are.equal('rambo-fans/Results', result.link2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should add the Head to head tab based on lpdb matches when the Results subpage is missing', function()
			withExistingPages({}, function()
				withH2HVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Rambo')
					assert.are.equal('Results', result.name2)
					assert.are.equal('table', type(result.name3))

					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerH2HUrl('Rambo'), nil, true) ~= nil)
					assert.is_true(rendered:find('Head to head', nil, true) ~= nil)
				end)
			end)
		end)

		it('should replace the Results tab with a Player Results QueryLink when replaceTabs is set', function()
			withExistingPages({'Twizzler/Results'}, function()
				withQueryTabsVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler')
					-- Results slot is taken over by the run query tab: name2 is the QueryLink,
					-- there is no separate link2 argument
					assert.are.equal('table', type(result.name2))
					assert.is_nil(result.link2)

					local rendered = tostring(result.name2)
					assert.is_true(rendered:find(expectedPlayerResultsUrl('Twizzler'), nil, true) ~= nil)
					assert.is_true(rendered:find('Results', nil, true) ~= nil)
				end)
			end)
		end)

		it('should replace the Played Matches tab with a Player Matches QueryLink when replaceTabs is set', function()
			withExistingPages({'Twizzler/Results'}, function()
				withQueryTabsVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler')
					-- Like headToHead/statistics, the run query tab only depends on the Results
					-- data, so it is shown even when the 'Played Matches' subpage does not exist.
					assert.are.equal('table', type(result.name3))
					assert.is_nil(result.link3)

					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerMatchesUrl('Twizzler'), nil, true) ~= nil)
					assert.is_true(rendered:find('Matches', nil, true) ~= nil)
				end)
			end)
		end)

		it('should not replace tabs when the replaceTabs variable is not set', function()
			withExistingPages({'Twizzler/Results'}, function()
				local result = ProfileTabs.getTabArgs('player', 'Twizzler')
				assert.are.equal('Results', result.name2)
				assert.are.equal('Twizzler/Results', result.link2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should not replace tabs without results data', function()
			withExistingPages({'Twizzler/Awards'}, function()
				withQueryTabsVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Twizzler')
					assert.are.equal('Awards', result.name2)
					assert.is_nil(result.name3)
				end)
			end)
		end)

		it('should replace team tabs with run query tabs when replaceTabs is set', function()
			withExistingPages({'rambo-fans/Results'}, function()
				withQueryTabsVariable(function()
					local result = ProfileTabs.getTabArgs('team', 'rambo-fans')
					-- Results, Played Matches and Player Results take over the first three slots
					assert.are.equal('table', type(result.name2))
					assert.are.equal('table', type(result.name3))
					assert.are.equal('table', type(result.name4))
					assert.is_nil(result.name5)

					assert.is_true(tostring(result.name2):find(expectedTeamResultsUrl('rambo-fans'), nil, true) ~= nil)
					assert.is_true(tostring(result.name3):find(expectedTeamMatchesUrl('rambo-fans'), nil, true) ~= nil)
					assert.is_true(tostring(result.name4):find(expectedTeamPlayerResultsUrl('rambo-fans'), nil, true) ~= nil)
				end)
			end)
		end)

		it('should replace tabs based on lpdb matches even when the Results subpage is missing', function()
			withExistingPages({}, function()
				withQueryTabsVariable(function()
					local result = ProfileTabs.getTabArgs('player', 'Rambo')
					-- 'Rambo' has lpdb matches, so the run query tabs take over despite no subpages
					assert.are.equal('table', type(result.name2))
					assert.are.equal('table', type(result.name3))

					assert.is_true(tostring(result.name2):find(expectedPlayerResultsUrl('Rambo'), nil, true) ~= nil)
					assert.is_true(tostring(result.name3):find(expectedPlayerMatchesUrl('Rambo'), nil, true) ~= nil)
				end)
			end)
		end)
	end)

	describe('_getSubpageName', function()
		it('should return the subpage tab name', function()
			assert.are.equal('Results', ProfileTabs.getSubpageName('player', 'Twizzler/Results'))
			assert.are.equal('Played Matches', ProfileTabs.getSubpageName('player', 'Twizzler/Played Matches'))
		end)

		it('should return nil on the profile main page', function()
			assert.is_nil(ProfileTabs.getSubpageName('player', 'Twizzler'))
		end)

		it('should return nil for unknown subpages', function()
			assert.is_nil(ProfileTabs.getSubpageName('player', 'Twizzler/Bogus'))
		end)
	end)

	describe('run', function()
		it('should render the tabs on a subpage', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler/Results'}
			end)
			withExistingPages({'Twizzler/Results', 'Twizzler/Awards'}, function()
				local result = ProfileTabs.run({})
				assert.is_not_nil(result)
				local html = tostring(result)
				assert.is_true(html:find('Twizzler/Results', nil, true) ~= nil)
				assert.is_true(html:find('Twizzler/Awards', nil, true) ~= nil)
			end)
		end)

		it('should override the page display title without changing the player name', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler/Results'}
			end)
			withExistingPages({'Twizzler/Results'}, function()
				local result = ProfileTabs.run({displayTitle = 'Custom Title'})
				assert.is_not_nil(result)
				local html = tostring(result)
				assert.is_true(html:find('Twizzler/Results', nil, true) ~= nil)
			end)
		end)

		it('should use a custom displayTitle string as the page title', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler/Results'}
			end)
			withExistingPages({'Twizzler/Results'}, function()
				local setTitleProps
				stub(Page, 'setDisplayTitle', function(props)
					setTitleProps = props
				end)
				local result = ProfileTabs.run({displayTitle = 'Custom Title'})
				assert.is_not_nil(result)
				assert.are.equal('Custom Title', setTitleProps.title)
			end)
		end)

		it('should not set the auto display title when displayTitle is false', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler/Results'}
			end)
			withExistingPages({'Twizzler/Results'}, function()
				local setTitleProps
				stub(Page, 'setDisplayTitle', function(props)
					setTitleProps = props
				end)
				local result = ProfileTabs.run({displayTitle = 'false'})
				assert.is_not_nil(result)
				-- No automatic "Twizzler: Results" title is set
				assert.is_nil(setTitleProps.title)
			end)
		end)

		it('should render on the main page without subpage tabs', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler'}
			end)
			withExistingPages({}, function()
				local result = ProfileTabs.run({})
				assert.is_not_nil(result)
				local html = tostring(result)
				assert.is_true(html:find('Twizzler', nil, true) ~= nil)
			end)
		end)

		it('should render the Head to head tab as a clickable query link', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler/Results'}
			end)
			withExistingPages({'Twizzler/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabs.run({})
					local html = tostring(result)
					assert.is_true(html:find(expectedPlayerH2HUrl('Twizzler'), nil, true) ~= nil)
					assert.is_true(html:find('Head to head', nil, true) ~= nil)
				end)
			end)
		end)

		it('_getDisplayTitle should return proper display titles', function()
			mockLpdb.setUp()
			assert.is_nil(ProfileTabs._getDisplayTitle('player', 'Twizzler', nil))
			assert.is_not_nil(ProfileTabs._getDisplayTitle('player', 'Twizzler', 'Results'))
			local title = ProfileTabs._getDisplayTitle('player', 'Twizzler', 'Results')
			assert.is_true(title:find('Results', nil, true) ~= nil)
		end)

		describe('target parameter', function()
			it('should resolve player from an explicit profileType', function()
				local profileType, frame = ProfileTabs._resolveProfileType('player', {title = 'X'})
				assert.are.equal('player', profileType)
				assert.are.same({title = 'X'}, frame)
			end)

			it('should resolve team from the template target arg', function()
				local profileType, frame = ProfileTabs._resolveProfileType({target = 'team'})
				assert.are.equal('team', profileType)
				assert.are.same({target = 'team'}, frame)
			end)

			it('should fall back to player when target is unknown', function()
				local profileType = ProfileTabs._resolveProfileType({target = 'bogus'})
				assert.are.equal('player', profileType)
			end)

			it('should fall back to player when target is missing', function()
				local profileType = ProfileTabs._resolveProfileType({})
				assert.are.equal('player', profileType)
			end)

			it('should use the team tabs when running with target=team', function()
				mockLpdb.setUp()
				titleStub = stub(mw.title, 'getCurrentTitle', function()
					return {prefixedText = 'twizzler-fans'}
				end)
				withExistingPages({'twizzler-fans/Player Results', 'twizzler-fans/Coaching'}, function()
					local result = ProfileTabs.run({target = 'team'})
					assert.is_not_nil(result)
					local html = tostring(result)
					-- 'Player Results' is part of the team tab list, 'Coaching' only of the player one
					assert.is_true(html:find('twizzler-fans/Player Results', nil, true) ~= nil)
					assert.is_nil(html:find('twizzler-fans/Coaching', nil, true))
				end)
			end)
		end)
	end)
end)
