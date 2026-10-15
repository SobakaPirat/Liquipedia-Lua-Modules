-- luacheck: ignore
--- Triple Comment to Enable our LLS Plugin
describe('PlayerTabs Module', function()
	local PlayerTabs = require('Module:PlayerTabs')
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
	-- (PlayerTabs holds a reference to the same table) and restores it afterwards.
	local function withPlayerTabsConfig(config, func)
		Info.config = Info.config or {}
		local origPlayerTabs = Info.config.playerTabs
		Info.config.playerTabs = config
		finally(function()
			Info.config.playerTabs = origPlayerTabs
		end)
		return func()
	end

	it('should always include the Overview tab', function()
		local result = PlayerTabs.getTabArgs('Twizzler')
		assert.is_not_nil(result.name1)
		assert.are.equal('Overview', result.name1)
		assert.are.equal('Twizzler', result.link1)
	end)

	it('should add a RunQuery tab rendered as a QueryLink widget', function()
		withPlayerTabsConfig({
			runQueryTabs = h2hConfig('Head to head query'),
		}, function()
			-- RunQuery tabs are always added, no Page.exists check:
			-- the query url is not a valid page title.
			local result = PlayerTabs.getTabArgs('Twizzler')
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
		withPlayerTabsConfig({
			runQueryTabs = h2hConfig('Head to head query'),
		}, function()
			local result = PlayerTabs.getTabArgs('Viswanathan Anand')
			local rendered = tostring(result.name2)
			assert.is_true(rendered:find(expectedMediawikiUrl('Viswanathan Anand'), nil, true) ~= nil)
		end)
	end)

	it('should fall back to a default name when displayName is missing', function()
		withPlayerTabsConfig({
			runQueryTabs = h2hConfig(nil),
		}, function()
			local result = PlayerTabs.getTabArgs('Twizzler')
			assert.is_true(tostring(result.name2):find('Query', nil, true) ~= nil)
		end)
	end)

	it('should add subpages from the config when they exist', function()
		withPlayerTabsConfig({
			subpages = {'Results', 'Played Matches'},
		}, function()
			mw.title.new = function(page)
				return {exists = page == 'Twizzler/Results'}
			end

			local result = PlayerTabs.getTabArgs('Twizzler')
			assert.are.equal('Overview', result.name1)
			assert.are.equal('Results', result.name2)
			assert.are.equal('Twizzler/Results', result.link2)
			assert.is_nil(result.name3)
		end)
	end)

	it('should add alwaysSubpages even when the page does not exist', function()
		withPlayerTabsConfig({
			subpages = {'Results'},
			alwaysSubpages = {'Coaching'},
		}, function()
			mw.title.new = function(page)
				return {exists = page == 'Twizzler/Results'}
			end

			local result = PlayerTabs.getTabArgs('Twizzler')
			assert.are.equal('Overview', result.name1)
			assert.are.equal('Results', result.name2)
			assert.are.equal('Twizzler/Results', result.link2)
			assert.are.equal('Coaching', result.name3)
			assert.are.equal('Twizzler/Coaching', result.link3)
			assert.is_nil(result.name4)
		end)
	end)

	it('getSubpages should include both subpages and alwaysSubpages', function()
		withPlayerTabsConfig({
			subpages = {'Results'},
			alwaysSubpages = {'Coaching'},
		}, function()
			assert.are.same({'Results', 'Coaching'}, PlayerTabs.getSubpages())
		end)
	end)

	it('getSubpageConfigs should map the two lists onto always flags', function()
		withPlayerTabsConfig({
			subpages = {'Results'},
			alwaysSubpages = {'Coaching'},
		}, function()
			assert.are.same({
				{name = 'Results', link = 'Results', always = false},
				{name = 'Coaching', link = 'Coaching', always = true},
			}, PlayerTabs.getSubpageConfigs())
		end)
	end)

	it('should allow a tab name that differs from the subpage link', function()
		withPlayerTabsConfig({
			subpages = {
				{name = 'Coaching Videos', link = 'Coaching'},
				'Results',
			},
			alwaysSubpages = {
				{name = 'Fan Content', link = 'FanContent'},
			},
		}, function()
			mw.title.new = function(page)
				return {exists = page == 'Twizzler/Coaching' or page == 'Twizzler/Results'}
			end

			local result = PlayerTabs.getTabArgs('Twizzler')
			assert.are.equal('Overview', result.name1)
			assert.are.equal('Coaching Videos', result.name2)
			assert.are.equal('Twizzler/Coaching', result.link2)
			assert.are.equal('Results', result.name3)
			assert.are.equal('Twizzler/Results', result.link3)
			assert.are.equal('Fan Content', result.name4)
			assert.are.equal('Twizzler/FanContent', result.link4)
			assert.is_nil(result.name5)
		end)
	end)

	it('isSubpage should match the subpage link, not the tab name', function()
		withPlayerTabsConfig({
			subpages = {{name = 'Coaching Videos', link = 'Coaching'}},
		}, function()
			assert.is_true(PlayerTabs.isSubpage('Coaching'))
			assert.is_false(PlayerTabs.isSubpage('Coaching Videos'))
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
		withPlayerTabsConfig(nil, function()
			local result = PlayerTabs.getTabArgs('TestPlayer')
			assert.are.equal('Overview', result.name1)
			assert.is_nil(result.name2)
		end)
	end)

	it('getSubpages should return the configured subpages or an empty table', function()
		withPlayerTabsConfig({subpages = {'Results', 'Coaching'}}, function()
			assert.are.same({'Results', 'Coaching'}, PlayerTabs.getSubpages())
		end)
		withPlayerTabsConfig(nil, function()
			assert.are.same({}, PlayerTabs.getSubpages())
		end)
	end)

	it('isSubpage should check against the configured subpages', function()
		withPlayerTabsConfig({subpages = {'Results', 'Coaching'}}, function()
			assert.is_true(PlayerTabs.isSubpage('Results'))
			assert.is_true(PlayerTabs.isSubpage('Coaching'))
			assert.is_false(PlayerTabs.isSubpage('Overview'))
		end)
		withPlayerTabsConfig(nil, function()
			assert.is_false(PlayerTabs.isSubpage('Results'))
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

			withPlayerTabsConfig({subpages = {'Results'}}, function()
				local result = PlayerTabs.run()
				assert.is_not_nil(result)
				local html = tostring(result)
				-- The subpage tab should link to the subpage
				assert.is_true(html:find('Twizzler/Results', nil, true) ~= nil)
			end)
		end)

		it('should render on the player main page without subpage tabs', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'Twizzler'}
			end)

			withPlayerTabsConfig({subpages = {'Results'}}, function()
				local result = PlayerTabs.run()
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

			withPlayerTabsConfig({
				runQueryTabs = h2hConfig('Head to head query'),
			}, function()
				local html = tostring(PlayerTabs.run())
				-- QueryLink renders the full url as a clickable link with the display name
				local expectedUrl = expectedMediawikiUrl('Twizzler')
				assert.is_true(html:find('[', nil, true) ~= nil)
				assert.is_true(html:find(expectedUrl, nil, true) ~= nil)
				assert.is_true(html:find('Head to head query', nil, true) ~= nil)
			end)
		end)
	end)
end)