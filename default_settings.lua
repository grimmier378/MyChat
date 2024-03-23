return {
	['LoadTheme'] = 'Default',
	['Channels'] = {
		[2] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Shout',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['color'] = {
								[1] = 0.9526066184043884,
								[2] = 0.11286809295415878,
								[3] = 0.11286809295415878,
								[4] = 1,
							},
							['filterString'] = '',
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#shout#*#, \'#*#\'#*#',
				},
			},
		},
		[5] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Group',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.058107390999794,
								[2] = 0.9053785204887389,
								[3] = 0.9431279897689818,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#tells the group#*#',
				},
				[2] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.521327018737793,
								[2] = 0.4966195821762085,
								[3] = 0.4966195821762085,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#You tell your party, \'#*#',
				},
			},
		},
		[4] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'OOC',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['color'] = {
								[1] = 0.37943992018699646,
								[2] = 0.7014217972755432,
								[3] = 0.0664854571223259,
								[4] = 1,
							},
							['filterString'] = '',
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#say#*# out of character, \'#*#',
				},
			},
		},
		[9] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Auction',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['color'] = {
								[1] = 0.22158418595790863,
								[2] = 0.7552742958068848,
								[3] = 0.08604388684034348,
								[4] = 1,
							},
							['filterString'] = '',
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#auction#*#, \'#*#',
				},
			},
		},
		[8] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Exp AA pts',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
							['filterString'] = '',
						},
						[1] = {
							['filterString'] = 'experience!',
							['color'] = {
								[1] = 1,
								[2] = 0.9620252847671509,
								[3] = 0,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'an ability point',
							['color'] = {
								[1] = 1,
								[2] = 0.5569620132446289,
								[3] = 0,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#You have gained#*#',
				},
			},
		},
		[3] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Say',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
							['filterString'] = '',
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.7088607549667358,
								[2] = 0.7088607549667358,
								[3] = 0.7088607549667358,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#say#*#, \'#*#\'#*#',
				},
			},
		},
		[7] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Raid',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['color'] = {
								[1] = 0.8015201687812805,
								[2] = 0.3612847328186035,
								[3] = 0.9409282803535461,
								[4] = 1,
							},
							['filterString'] = '',
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.1615125834941864,
								[2] = 0.6240723133087158,
								[3] = 0.6835442781448364,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#tell#*# #*# raid, \'#*#',
				},
			},
		},
		[1] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Tells',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.5837929844856261,
								[2] = 0.3298972845077514,
								[3] = 0.9198312163352965,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#tells you,#*#',
				},
				[2] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.5924170613288878,
								[2] = 0.5868017077445984,
								[3] = 0.5868017077445984,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#You told #1#,#*#',
				},
			},
		},
		[6] = {
			['Scale'] = 1.5,
			['enabled'] = true,
			['Name'] = 'Guild',
			['Events'] = {
				[1] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.29469239711761475,
								[2] = 0.971563994884491,
								[3] = 0.32677161693573,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#tells the guild#*#',
				},
				[2] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.6398104429244994,
								[2] = 0.6185845136642455,
								[3] = 0.6185845136642455,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#You say to your guild, \'#*#',
				},
			},
		},
	},
}