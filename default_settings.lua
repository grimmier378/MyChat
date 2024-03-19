
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
		[1] = {
			['Name'] = 'Tells',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You told #1#,#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#tells you,#*#',
				},
			},
		},
		[2] = {
			['Name'] = 'Shout',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You shout, \'#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#shouts,#*#',
				},
			},
		},
		[3] = {
			['Name'] = 'Say',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You say, \'#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#says,#*#',
				},
			},
		},
		[4] = {
			['Name'] = 'OOC',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You say out of character,#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#say#*# out of character,#*#',
				},
			},
		},
		[5] = {
			['Name'] = 'Group',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You tell your party, \'#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#tells the group#*#',
                },
            },
        },
        [6] = {
			['Name'] = 'Guild',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You say to your guild, \'#*#',
                },
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#tells the guild#*#',
				},
			},
		},
		[7] = {
			['Name'] = 'Raid',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#You tell your raid,#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#tells the raid#*#',
				},
			},
		},
		[8] = {
			['Name'] = 'Exp AA pts',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#gained an ability point#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You have gained#*#experience!#*#',
				},
			},
		},
		[9] = {
			['Name'] = 'Auction',
			['Scale'] = 1.5,
			['enabled'] = true,
			['Events'] = {
				[2] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#You auction,#*#',
				},
				[1] = {
					['Filters'] = {
                        [0] = {
                            ['filterString'] = '',
                            ['color']={[1]=1,[2]=1,[3]=1,[4]=1,},
                        },
                    },
                    ['eventString'] = '#*#auctions,#*#',
				},
			},
		},
	},
}
