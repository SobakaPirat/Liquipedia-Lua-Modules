-- luacheck: ignore
--- Triple Comment to Enable our LLS Plugin
describe('ProfileTabs Module', function()
	local ProfileTabs = require('Module:ProfileTabs')
	local Info = require('Module:Info')
	local StringUtils = require('Module:StringUtils')

	-- Config for the head to head run query tab (chess wiki style)
	local function h2hConfig(displayName)
		return {
			{
				displayName = displayName,
				mediawikiForm = 'Match history',
				form = 'H2H',
				template = 'Head_to_head_query',
				queryArgs = {player = '${player}'},
			},
		}
	end

	-- Builds the expected mediawiki run query url the same way Widget/QueryLink does
	local function expectedMediawikiUrl(player)
		return tostring(mw.uri.fullUrl(
			'Special:RunQuery/Match history',
			{['Head_to_head_query[player]'] = player}
		)):gsub(' ', '%%20')
	end

	local origTitleNew
	before_each(function()
		origTitleNew = mw.title.new
	end)
	after_each(function()
		mw.title.new = origTitleNew
	end)

	-- Injects playerTabs config into the loaded Info table
	-- (ProfileTabs holds a reference to the same table) and restores it afterwards.
	local function withProfileTabsConfig(config, func)
		Info.config = Info.config or {}
		local origProfileTabs = Info.config.playerTabs
		Info.config.playerTabs = config
		finally(function()
			Info.config.playerTabs = origProfileTabs
		end)
		return func()
	end

	it('should always include the Overview tab', function()
		local result = ProfileTabs.getTabArgs('player', 'Twizzler')
		assert.is_not_nil(result.name1)
		assert.are.equal('Overview', result.name1)
		assert.are.equal('Twizzler', result.link1)
	end)

	it('should add a RunQuery tab rendered as a QueryLink widget', function()
		withProfileTabsConfig({
			runQueryTabs = h2hConfig('Head to head query'),
		}, function()
			-- RunQuery tabs are always added, no Page.exists check:
			-- the query url is not a valid page title.
			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.is_not_nil(result.name2)
			assert.are.equal('table', type(result.name2))
			-- The QueryLink widget provides the link itself, no separate link arg
			assert.is_nil(result.link2)
			assert.is_nil(result.name3)

			local rendered = tostring(result.name2)
			assert.is_true(rendered:find(expectedMediawikiUrl('Twizzler'), nil, true) ~= nil)
			assert.is_true(rendered:find('Head to head query', nil, true) ~= nil)
		end)
	end)

	it('should encode player names with spaces in RunQuery links', function()
		withProfileTabsConfig({
			runQueryTabs = h2hConfig('Head to head query'),
		}, function()
			local result = ProfileTabs.getTabArgs('player', 'Viswanathan Anand')
			local rendered = tostring(result.name2)
			assert.is_true(rendered:find(expectedMediawikiUrl('Viswanathan Anand'), nil, true) ~= nil)
		end)
	end)

	it('should fall back to a default name when displayName is missing', function()
		withProfileTabsConfig({
			runQueryTabs = h2hConfig(nil),
		}, function()
			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.is_true(tostring(result.name2):find('Query', nil, true) ~= nil)
		end)
	end)

	it('should hide all RunQuery tabs when queryTabs is false', function()
		withProfileTabsConfig({
			runQueryTabs = {{
				displayName = 'Head to head query',
				mediawikiForm = 'Match history',
				form = 'H2H',
				template = 'Head_to_head_query',
				queryArgs = {player = '${player}'},
			}},
		}, function()
			mw.ext.VariablesLua.vardefine('queryTabs', 'false')
			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.is_nil(result.name2)
		end)
	end)

	it('should show all RunQuery tabs when queryTabs is truthy', function()
		withProfileTabsConfig({
			runQueryTabs = {{
				displayName = 'Head to head query',
				mediawikiForm = 'Match history',
				form = 'H2H',
			}},
		}, function()
			mw.ext.VariablesLua.vardefine('queryTabs', 'true')
			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.is_not_nil(result.name2)
		end)
	end)

	it('should show all RunQuery tabs when queryTabs is not set', function()
		withProfileTabsConfig({
			runQueryTabs = {{
				displayName = 'Head to head query',
				mediawikiForm = 'Match history',
				form = 'H2H',
			}},
		}, function()
			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.is_not_nil(result.name2)
		end)
	end)

	it('should show all RunQuery tabs (variable not configured in test config)', function()
		withProfileTabsConfig({
			runQueryTabs = {{
				displayName = 'Head to head query',
				mediawikiForm = 'Match history',
				form = 'H2H',
			}},
		}, function()
			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.is_not_nil(result.name2)
		end)
	end)

	it('should hide all RunQuery tabs from a false template arg via getTabArgs', function()
		withProfileTabsConfig({
			runQueryTabs = {{
				displayName = 'Head to head query',
				mediawikiForm = 'Match history',
				form = 'H2H',
			}},
		}, function()
			-- Template args take precedence over the page variable
			mw.ext.VariablesLua.vardefine('queryTabs', 'true')
			local result = ProfileTabs.getTabArgs('player', 'Twizzler', {queryTabs = 'no'})
			assert.is_nil(result.name2)
		end)
	end)

	it('should show all RunQuery tabs from a truthy template arg via getTabArgs', function()
		withProfileTabsConfig({
			runQueryTabs = {{
				displayName = 'Head to head query',
				mediawikiForm = 'Match history',
				form = 'H2H',
			}},
		}, function()
			local result = ProfileTabs.getTabArgs('player', 'Twizzler', {queryTabs = 'yes'})
			assert.is_not_nil(result.name2)
		end)
	end)


	it('should add subpages from the config when they exist', function()
		withProfileTabsConfig({
			specialSubpages = {'Results', 'Played Matches'},
		}, function()
			mw.title.new = function(page)
				return {exists = page == 'Twizzler/Results'}
			end

			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.are.equal('Overview', result.name1)
			assert.are.equal('Results', result.name2)
			assert.are.equal('Twizzler/Results', result.link2)
			assert.is_nil(result.name3)
		end)
	end)

	it('should add defaultSubpages even when the page does not exist, before specialSubpages', function()
		withProfileTabsConfig({
			specialSubpages = {'Results'},
			defaultSubpages = {'Coaching'},
		}, function()
			mw.title.new = function(page)
				return {exists = page == 'Twizzler/Results'}
			end

			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.are.equal('Overview', result.name1)
			-- Default subpages always show and come first
			assert.are.equal('Coaching', result.name2)
			assert.are.equal('Twizzler/Coaching', result.link2)
			-- Special subpages show after the default ones when the page exists
			assert.are.equal('Results', result.name3)
			assert.are.equal('Twizzler/Results', result.link3)
			assert.is_nil(result.name4)
		end)
	end)

	it('getSubpages should include both specialSubpages and defaultSubpages', function()
		withProfileTabsConfig({
			specialSubpages = {'Results'},
			defaultSubpages = {'Coaching'},
		}, function()
			assert.are.same({'Coaching', 'Results'}, ProfileTabs.getSubpages('player'))
		end)
	end)

	it('getSubpageConfigs should map the two lists onto default flags', function()
		withProfileTabsConfig({
			specialSubpages = {'Results'},
			defaultSubpages = {'Coaching'},
		}, function()
			assert.are.same({
				{name = 'Coaching', link = 'Coaching', default = true},
				{name = 'Results', link = 'Results', default = false},
			}, ProfileTabs.getSubpageConfigs('player'))
		end)
	end)

	it('should allow a tab name that differs from the subpage link', function()
		withProfileTabsConfig({
			specialSubpages = {
				{name = 'Coaching Videos', link = 'Coaching'},
				'Results',
			},
			defaultSubpages = {
				{name = 'Fan Content', link = 'FanContent'},
			},
		}, function()
			mw.title.new = function(page)
				return {exists = page == 'Twizzler/Coaching' or page == 'Twizzler/Results'}
			end

			local result = ProfileTabs.getTabArgs('player', 'Twizzler')
			assert.are.equal('Overview', result.name1)
			-- Default subpage listed first
			assert.are.equal('Fan Content', result.name2)
			assert.are.equal('Twizzler/FanContent', result.link2)
			-- Special subpages in configured order after the default one
			assert.are.equal('Coaching Videos', result.name3)
			assert.are.equal('Twizzler/Coaching', result.link3)
			assert.are.equal('Results', result.name4)
			assert.are.equal('Twizzler/Results', result.link4)
			assert.is_nil(result.name5)
		end)
	end)

	it('isSubpage should match the subpage link, not the tab name', function()
		withProfileTabsConfig({
			specialSubpages = {{name = 'Coaching Videos', link = 'Coaching'}},
		}, function()
			assert.is_true(ProfileTabs.isSubpage('player', 'Coaching'))
			assert.is_false(ProfileTabs.isSubpage('player', 'Coaching Videos'))
		end)
	end)

	it('should interpolate ${player} into query arg values', function()
		assert.are.equal(
			'Head_to_head_query[player]=Twizzler',
			StringUtils.interpolate('Head_to_head_query[player]=${player}', {player = 'Twizzler'})
		)
		-- Template without any placeholders is returned unchanged
		assert.are.equal('no placeholders', StringUtils.interpolate('no placeholders', {}))
		-- Missing keys keep their placeholder
		assert.are.equal('Hello foo, ${missing}', StringUtils.interpolate('Hello ${name}, ${missing}', {name = 'foo'}))
	end)

	it('should handle wiki without playerTabs config gracefully', function()
		withProfileTabsConfig(nil, function()
			local result = ProfileTabs.getTabArgs('player', 'TestPlayer')
			assert.are.equal('Overview', result.name1)
			assert.is_nil(result.name2)
		end)
	end)

	it('getSubpages should return the configured subpages or an empty table', function()
		withProfileTabsConfig({specialSubpages = {'Results', 'Coaching'}}, function()
			assert.are.same({'Results', 'Coaching'}, ProfileTabs.getSubpages('player'))
		end)
		withProfileTabsConfig(nil, function()
			assert.are.same({}, ProfileTabs.getSubpages('player'))
		end)
	end)

	it('isSubpage should check against the configured subpages', function()
		withProfileTabsConfig({specialSubpages = {'Results', 'Coaching'}}, function()
			assert.is_true(ProfileTabs.isSubpage('player', 'Results'))
			assert.is_true(ProfileTabs.isSubpage('player', 'Coaching'))
			assert.is_false(ProfileTabs.isSubpage('player', 'Overview'))
		end)
		withProfileTabsConfig(nil, function()
			assert.is_false(ProfileTabs.isSubpage('player', 'Results'))
		end)
	end)

	describe('run', function()
		local mockLpdb = require('Module:Mock/Lpdb')

		local titleStub
		after_each(function()
			if titleStub then
				titleStub:revert()
				titleStub = nil
			end
			mockLpdb.tearDown()
		end)

		it('should render the tabs on a player subpage', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler/Results'}
			end)
			mw.title.new = function(page)
				return {exists = page == 'Twizzler/Results'}
			end

			withProfileTabsConfig({specialSubpages = {'Results'}}, function()
				local result = ProfileTabs.run({})
				assert.is_not_nil(result)
				local html = tostring(result)
				-- The subpage tab should link to the subpage
				assert.is_true(html:find('Twizzler/Results', nil, true) ~= nil)
			end)
		end)

		it('should override the page display title without changing the player name', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler'}
			end)

			withProfileTabsConfig({}, function()
				local result = ProfileTabs.run({title = 'Custom page name'})
				assert.is_not_nil(result)
				local html = tostring(result)
				-- Tab links must still point at the real player page, not the custom title
				assert.is_true(html:find('Twizzler', nil, true) ~= nil)
				assert.is_false(html:find('Custom page name', nil, true) ~= nil)
			end)
		end)

		it('should render on the player main page without subpage tabs', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler'}
			end)

			withProfileTabsConfig({specialSubpages = {'Results'}}, function()
				local result = ProfileTabs.run({})
				assert.is_not_nil(result)
				local html = tostring(result)
				-- Only the overview tab should be rendered
				assert.is_true(html:find('tabs tabs1', nil, true) ~= nil)
			end)
		end)

		it('should render RunQuery tabs as clickable query links', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler'}
			end)

			withProfileTabsConfig({
				runQueryTabs = h2hConfig('Head to head query'),
			}, function()
				local html = tostring(ProfileTabs.run({}))
				-- QueryLink renders the full url as a clickable link with the display name
				local expectedUrl = expectedMediawikiUrl('Twizzler')
				assert.is_true(html:find('[', nil, true) ~= nil)
				assert.is_true(html:find(expectedUrl, nil, true) ~= nil)
				assert.is_true(html:find('Head to head query', nil, true) ~= nil)
			end)
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

			it('should use the team tabs config when running with target=team', function()
				mockLpdb.setUp()
				titleStub = stub(mw.title, 'getCurrentTitle', function()
					return {prefixedText = 'twizzler-fans/Matches'}
				end)
				mw.title.new = function(page)
					return {exists = page == 'twizzler-fans/Matches'}
				end

				Info.config = Info.config or {}
				local origTeamTabs = Info.config.teamTabs
				Info.config.teamTabs = {specialSubpages = {'Matches'}}
				finally(function()
					Info.config.teamTabs = origTeamTabs
				end)

				local result = ProfileTabs.run({target = 'team', title = 'Custom team title'})
				assert.is_not_nil(result)
				local html = tostring(result)
				assert.is_true(html:find('twizzler-fans/Matches', nil, true) ~= nil)
			end)
		end)
	end)
end)