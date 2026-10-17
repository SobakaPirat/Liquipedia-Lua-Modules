---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2002,
	wikiName = 'warcraft',
	name = 'Warcraft',
	defaultGame = 'reforged',
	games = {
		reignofchaos = {
			abbreviation = 'RoC',
			name = 'Reign of Chaos',
			link = 'Reign of Chaos',
			logo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
		},
		frozenthrone = {
			abbreviation = 'TFT',
			name = 'The Frozen Throne',
			link = 'The Frozen Throne',
			logo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
		},
		reforged = {
			abbreviation = 'WC3R',
			name = 'Reforged',
			link = 'Reforged',
			logo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = true,
			allowManual = true,
		},
		match2 = {
			status = 2,
			matchWidthMobile = 110,
			matchWidth = 150,
		},
		infoboxPlayer = {
			automatedHistory = {
				storeFromWikiCode = true,
			},
		},
		standings = {
			alwaysShowStats = {
				swiss = {'matchdiff', 'gamediff'},
			},
		},
		defaultMaxPlayersPerPlacement = 20,
		participants = {
			soloAsFactionTable = true,
			sortPlayersInTable = true,
		},
		playerTabs = {
			specialSubpages = {
				'Events',
				'Broadcasts',
			},
			runQueryTabs = {
				{
					displayName = 'Results',
					mediawikiForm = 'Player Results',
					form = 'Player Results/LH',
					template = 'Player results',
					queryArgs = {
						player = '${player}',
						tier = '1,2,3',
						limit = '250',
					},
				},
				{
					displayName = 'Matches',
					mediawikiForm = 'Player Matches',
					form = 'Player Matches/LH',
					template = 'Player Matches',
					queryArgs = {
						player = '${player}',
						tier = '1,2,3',
						linkSubPage = 'false',
						limit = '250',
					},
				},
				{
					displayName = 'Statistics',
					mediawikiForm = 'PlayerStats',
					form = 'PlayerStats/LH',
					template = 'Player statistics',
					queryArgs = {player = '${player}'},
				},
			},
		},
		teamTabs = {
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
}
