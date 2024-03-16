return {
	['Colors'] = {
		['color_header'] = {
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 1,
		},
		['color_headHov'] = {
			[1] = 0.049999999999999996,
			[2] = 0.049999999999999996,
			[3] = 0.049999999999999996,
			[4] = 0.8999999999999999,
		},
		['color_headAct'] = {
			[1] = 0.049999999999999996,
			[2] = 0.049999999999999996,
			[3] = 0.049999999999999996,
			[4] = 0.8999999999999999,
		},
		['color_WinBg'] = {
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 1,
		},
	},
	['Channels'] = {
		[2] = {
			['Name'] = 'Tells',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#You told #1#,#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#tells you,#*#',
					['color'] = {
						[1] = 1,
						[2] = 0.5,
						[3] = 0.10000000149011612,
						[4] = 1,
					},
				},
			},
		},
		[5] = {
			['Name'] = 'Shout',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#You shout, \'#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#shouts,#*#',
					['color'] = {
						[1] = 1,
						[2] = 0,
						[3] = 0,
						[4] = 1,
					},
				},
			},
		},
		[4] = {
			['Name'] = 'Say',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#You say, \'#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#says,#*#',
					['color'] = {
						[1] = 1,
						[2] = 1,
						[3] = 1,
						[4] = 1,
					},
				},
			},
		},
		[9] = {
			['Name'] = 'OOC',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#You say out of character,#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#say#*# out of character,#*#',
					['color'] = {
						[1] = 0,
						[2] = 0.800000011920929,
						[3] = 0.30000001192092896,
						[4] = 1,
					},
				},
			},
		},
		[8] = {
			['Name'] = 'Group',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#You tell your party, \'#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#tells the group#*#',
					['color'] = {
						[1] = 0,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
			},
		},
		[3] = {
			['Name'] = 'Guild',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#You say to your guild, \'#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#tells the guild#*#',
					['color'] = {
						[1] = 0,
						[2] = 1,
						[3] = 0,
						[4] = 1,
					},
				},
			},
		},
		[7] = {
			['Name'] = 'Raid',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#You tell your raid,#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#tells the raid#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.6999999880790708,
						[3] = 1,
						[4] = 1,
					},
				},
			},
		},
		[1] = {
			['Name'] = 'Exp AA pts',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#gained an ability point#*#',
					['color'] = {
						[1] = 1,
						[2] = 0.5120974183082581,
						[3] = 0.14345991611480713,
						[4] = 0.800000011920929,
					},
				},
				[1] = {
					['eventString'] = '#*#You have gained#*#experience!#*#',
					['color'] = {
						[1] = 1,
						[2] = 1,
						[3] = 0,
						[4] = 1,
					},
				},
			},
		},
		[6] = {
			['Name'] = 'Auction',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['eventString'] = '#*#You auction,#*#',
					['color'] = {
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.5,
						[4] = 1,
					},
				},
				[1] = {
					['eventString'] = '#*#auctions,#*#',
					['color'] = {
						[1] = 0,
						[2] = 0.800000011920929,
						[3] = 0.30000001192092896,
						[4] = 1,
					},
				},
			},
		},
	},
}