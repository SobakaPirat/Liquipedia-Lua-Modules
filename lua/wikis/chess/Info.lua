---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1834,
	wikiName = 'chess',
	name = 'Chess',
	defaultGame = 'chess',
	games = {
		chess = {
			abbreviation = 'Chess',
			name = 'Chess',
			link = 'Chess',
			logo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
		},
		chess960 = {
			abbreviation = 'Chess960',
			name = 'Chess960',
			link = 'Chess960',
			logo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
		},
		bughouse = {
			abbreviation = 'Bughouse',
			name = 'Bughouse',
			link = 'Bughouse',
			logo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 2,
			matchWidth = 180,
		},
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'automatic',
			},
		},
		standings = {
			alwaysShowStats = {
				swiss = {'matchdiff', 'points'},
			},
		},
		playerTabs = {
			-- Default subpages shown unconditionally, listed first
			defaultSubpages = {
				{name = 'Talent', link = 'Broadcasts'},
			},
			-- Special subpages shown only when the page exists, listed after
			specialSubpages = {
				'Results',
				'Played Matches',
				'Coaching',
			},
			runQueryTabs = {
				{
					displayName = 'Head to head query',
					mediawikiForm = 'Match history',
					form = 'H2H',
					template = 'Head_to_head_query',
					queryArgs = {player = '${player}'},
				},
			},
		},
		teamTabs = {
			-- Default subpages shown unconditionally, listed first
			defaultSubpages = {
				'Results',
				'Played Matches',
			},
			-- Special subpages shown only when the page exists, listed after
			specialSubpages = {
				'Player Results',
				'History',
				'Awards',
			},
			runQueryTabs = {
				{
					displayName = 'Team matches query',
					mediawikiForm = 'Team match history',
					form = 'TMS',
					template = 'Team_matches_query',
					queryArgs = {team = '${team}'},
				},
			},
		},
	},
	defaultRoundPrecision = 0,
}
