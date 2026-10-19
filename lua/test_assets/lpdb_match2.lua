-- luacheck: ignore
-- Mock lpdb_match2 data used by Module:Mock/Lpdb.
-- Each entry must be filterable by the `player`/`opponent` conditions used in tests.
-- Note: `Twizzler`/`twizzler-fans` intentionally have no matches here so existing
-- sync tests keep asserting the Results tab is absent without the subpage.
return {
	{
		['date'] = '2020-01-01 00:00:00',
		['game'] = 'siege',
		['mode'] = 'solo',
		['namespace'] = '0',
		['objectname'] = '1_2_3',
		['opponent'] = 'Soniqs',
		['opponentname'] = 'Soniqs',
		['opponenttemplate'] = 'soniqs',
		['opponenttype'] = 'team',
		['pageid'] = '1000',
		['pagename'] = 'Team Liquid',
		['player'] = 'Rambo',
		['playernames'] = 'Rambo',
		['result'] = '1',
		['status'] = 'done',
		['title'] = 'Example Cup',
		['tournament'] = 'Example Cup',
	},
	{
		['date'] = '2020-02-02 00:00:00',
		['game'] = 'siege',
		['mode'] = 'team',
		['namespace'] = '0',
		['objectname'] = '4_5_6',
		['opponent'] = 'rambo-fans',
		['opponentname'] = 'rambo-fans',
		['opponenttemplate'] = 'rambo fans',
		['opponenttype'] = 'team',
		['pageid'] = '1001',
		['pagename'] = 'Some Tournament',
		['player'] = 'Foo Bar',
		['playernames'] = 'Foo Bar',
		['result'] = '2',
		['status'] = 'done',
		['title'] = 'Another Cup',
		['tournament'] = 'Another Cup',
	},
}
