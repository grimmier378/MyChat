return {
	['Channels'] = {
		[0] = {
			['Name'] = 'Consider',
			['Events'] = {
				[2] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.18917053937911985,
								[2] = 0.8418604731559752,
								[3] = 0.06656573712825774,
								[4] = 1,
							},
						},
					},
					['enabled'] = true,
					['eventString'] = '#*#glares at you threateningly#*#',
				},
				[5] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#looks upon you warmly#*#',
				},
				[4] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#regards you as an ally#*#',
				},
				[9] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#judges you amiably#*#',
				},
				[8] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['enabled'] = true,
					['eventString'] = '#*#looks your way apprehensively#*#',
				},
				[3] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['enabled'] = true,
					['eventString'] = '#*#regards you indifferently#*#',
				},
				[7] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#kindly considers you#*#',
				},
				[1] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.03251487016677856,
								[2] = 0.37174510955810547,
								[3] = 0.7767441868782042,
								[4] = 1,
							},
						},
					},
					['enabled'] = true,
					['eventString'] = '#*#scowls at you, ready to attack#*#',
				},
				[6] = {
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.9627907276153563,
								[2] = 0.040302865207195275,
								[3] = 0.040302865207195275,
								[4] = 1,
							},
						},
					},
					['enabled'] = true,
					['eventString'] = '#*#glowers at you dubiously#*#',
				},
			},
			['Echo'] = '/dgt',
			['PopOut'] = false,
			['MainEnable'] = true,
			['enabled'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
		[1] = {
			['Name'] = 'Exp AA pts',
			['Events'] = {
				[2] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 0,
							},
							['enabled'] = true,
						},
						[1] = {
							['filterString'] = 'M3',
							['color'] = {
								[1] = 0.09478676319122312,
								[2] = 1,
								[3] = 0,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[2] = {
							['filterString'] = 'GP1',
							['color'] = {
								[1] = 0,
								[2] = 0.9620254039764401,
								[3] = 1,
								[4] = 1,
							},
							['enabled'] = true,
						},
					},
					['eventString'] = '#*# gained #*#',
				},
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[1] = {
							['filterString'] = 'experience',
							['color'] = {
								[1] = 1,
								[2] = 0.9620252847671509,
								[3] = 0,
								[4] = 1,
							},
							['enabled'] = true,
						},
					},
					['eventString'] = '#*#You have gained #*#',
				},
			},
			['Echo'] = '/say',
			['enabled'] = true,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
		[2] = {
			['Name'] = 'Tells',
			['Events'] = {
				[2] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.8702717423439026,
								[2] = 0.3707739114761352,
								[3] = 0.9873417615890503,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^([^%s]+) tells you, \'',
							['color'] = {
								[1] = 0.6367206573486327,
								[2] = 0.2963556349277496,
								[3] = 0.8565400838851929,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#tells you,#*#',
				},
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0,
								[2] = 0.5,
								[3] = 0.5,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#You told #1#,#*#',
				},
			},
			['Echo'] = '/tell',
			['enabled'] = true,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1.3830000162124634,
		},
		[5] = {
			['Name'] = 'Say',
			['Events'] = {
				[2] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^([^%s]+) says, \'',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*# says, \'#*#',
				},
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.5738396644592284,
								[2] = 0.5496270060539246,
								[3] = 0.5738396644592284,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.649789035320282,
								[2] = 0.649789035320282,
								[3] = 0.649789035320282,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#say, \'#*#',
				},
			},
			['Echo'] = '/say',
			['enabled'] = true,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
		[11] = {
			['Name'] = 'Auction',
			['Events'] = {
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.36671361327171326,
								[2] = 0,
								[3] = 0.35740441083908076,
								[4] = 0.8815165758132935,
							},
							['enabled'] = true,
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.5968594551086426,
								[2] = 0.6286919713020325,
								[3] = 0.6202301383018494,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[2] = {
							['filterString'] = 'auctions',
							['color'] = {
								[1] = 0.04936994984745978,
								[2] = 0.7440758347511292,
								[3] = 0,
								[4] = 1,
							},
							['enabled'] = true,
						},
					},
					['eventString'] = '#*#auction#*#, \'#*#\'#*#',
				},
			},
			['Echo'] = '/auc',
			['enabled'] = false,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 2,
		},
		[4] = {
			['Name'] = 'WHO',
			['Events'] = {
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = 'Warrior',
							['color'] = {
								[1] = 1,
								[2] = 0.4303797483444214,
								[3] = 0,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'Necromancer',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0.19905233383178708,
								[4] = 1,
							},
						},
						[14] = {
							['filterString'] = 'Beastlord',
							['color'] = {
								[1] = 0.6510629057884215,
								[2] = 0.6635071039199828,
								[3] = 0.13836166262626648,
								[4] = 1,
							},
						},
						[13] = {
							['filterString'] = 'Shaman',
							['color'] = {
								[1] = 1,
								[2] = 0.7088607549667357,
								[3] = 0,
								[4] = 1,
							},
						},
						[5] = {
							['filterString'] = 'Magician',
							['color'] = {
								[1] = 0.019945634528994557,
								[2] = 0.42043399810791016,
								[3] = 0.7014217972755431,
								[4] = 1,
							},
						},
						[12] = {
							['filterString'] = 'Rogue',
							['color'] = {
								[1] = 0.04132882505655289,
								[2] = 0.4360189437866211,
								[3] = 0,
								[4] = 1,
							},
						},
						[11] = {
							['filterString'] = 'Cleric',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[4] = {
							['filterString'] = 'Enchanter',
							['color'] = {
								[1] = 0.48067206144332886,
								[2] = 0.582525074481964,
								[3] = 0.9478672742843628,
								[4] = 1,
							},
						},
						[10] = {
							['filterString'] = 'Ranger',
							['color'] = {
								[1] = 0.476426899433136,
								[2] = 1,
								[3] = 0.40284359455108637,
								[4] = 1,
							},
						},
						[9] = {
							['filterString'] = 'Shadow Knight',
							['color'] = {
								[1] = 0.6492891311645508,
								[2] = 0.6492891311645508,
								[3] = 0.6492891311645508,
								[4] = 1,
							},
						},
						[8] = {
							['filterString'] = 'Paladin',
							['color'] = {
								[1] = 0.9113924503326415,
								[2] = 1,
								[3] = 0,
								[4] = 1,
							},
						},
						[3] = {
							['filterString'] = 'Wizard',
							['color'] = {
								[1] = 0.10126584768295287,
								[2] = 0.5335682630538939,
								[3] = 1,
								[4] = 1,
							},
						},
						[7] = {
							['filterString'] = 'Bard',
							['color'] = {
								[1] = 0.6303317546844481,
								[2] = 0.5786547660827637,
								[3] = 0.19417804479599,
								[4] = 1,
							},
						},
						[16] = {
							['filterString'] = 'Druid',
							['color'] = {
								[1] = 0.20853078365325928,
								[2] = 1,
								[3] = 0,
								[4] = 1,
							},
						},
						[15] = {
							['filterString'] = 'Monk',
							['color'] = {
								[1] = 0.9156118035316466,
								[2] = 0.8849496245384215,
								[3] = 0.6954014301300049,
								[4] = 1,
							},
						},
						[6] = {
							['filterString'] = 'Berserker',
							['color'] = {
								[1] = 0.8565400838851929,
								[2] = 0.3939361870288849,
								[3] = 0.3939361870288849,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#[#*#(#*#)]#*#',
				},
			},
			['Echo'] = '/who',
			['enabled'] = true,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1.1319999694824219,
		},
		[10] = {
			['Name'] = 'Crits',
			['Events'] = {
				[2] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0,
								[2] = 1,
								[3] = 0.9004738330841063,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#ASSASSINATE#*#',
				},
				[5] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.9351065754890442,
								[2] = 0.4303797483444214,
								[3] = 0,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = 'TK1',
							['color'] = {
								[1] = 0.12658238410949704,
								[2] = 1,
								[3] = 0,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'GP1',
							['color'] = {
								[1] = 0,
								[2] = 0.5534468889236449,
								[3] = 0.7298578023910521,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#Finishing Blow#*#',
				},
				[3] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0.3291139602661133,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#trikethrough#*#',
				},
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0,
								[2] = 1,
								[3] = 0.8354430198669434,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.02531647682189941,
								[2] = 1,
								[3] = 0,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'GP1',
							['color'] = {
								[1] = 0,
								[2] = 1,
								[3] = 0.7014217376708983,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#xceptional#*#',
				},
				[4] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = 'GP1',
							['color'] = {
								[1] = 1,
								[2] = 0.9099526405334473,
								[3] = 0,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'M1',
							['color'] = {
								[1] = 0.720379114151001,
								[2] = 0.41946119070053095,
								[3] = 0,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#critical hit#*#',
				},
				[6] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.6248364448547362,
								[2] = 0.2936142385005951,
								[3] = 0.815165877342224,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'GP1',
							['color'] = {
								[1] = 1,
								[2] = 0.48815166950225825,
								[3] = 0.9830194115638733,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#critical blast#*#',
				},
			},
			['Echo'] = '/dgae /lootutils',
			['enabled'] = true,
			['MainEnable'] = false,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
		[9] = {
			['Name'] = 'Raid',
			['Events'] = {
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.10673616081476212,
								[2] = 0.34685027599334717,
								[3] = 0.6824644804000849,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.5924170613288875,
								[2] = 0.5924170613288875,
								[3] = 0.5924170613288875,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[2] = {
							['filterString'] = 'tells the raid,',
							['color'] = {
								[1] = 0.12603041529655457,
								[2] = 0.41042256355285645,
								[3] = 0.8578199148178101,
								[4] = 1,
							},
							['enabled'] = true,
						},
					},
					['eventString'] = '#*#tell#*# raid, \'#*#\'#*#',
				},
			},
			['Echo'] = '/rsay',
			['enabled'] = false,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1.4529999494552608,
		},
		[8] = {
			['Name'] = 'OOC',
			['Events'] = {
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.2025316208600998,
								[2] = 0.800000011920929,
								[3] = 0,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.7819905281066895,
								[2] = 0.7819905281066895,
								[3] = 0.7819905281066895,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[2] = {
							['filterString'] = 'says out of character,',
							['color'] = {
								[1] = 0.10126590728759766,
								[2] = 1,
								[3] = 0,
								[4] = 0.8436018824577332,
							},
							['enabled'] = true,
						},
					},
					['eventString'] = '#*# out of character, \'#*#',
				},
			},
			['Echo'] = '/ooc',
			['enabled'] = true,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1.4600000381469727,
		},
		[3] = {
			['Name'] = 'Combat',
			['Events'] = {
				[2] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.80490106344223,
								[2] = 0.5924170613288877,
								[3] = 1,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'G1',
							['color'] = {
								[1] = 0.9282700419425962,
								[2] = 0.6266306042671204,
								[3] = 0.31725683808326716,
								[4] = 1,
							},
						},
						[5] = {
							['filterString'] = 'kicks you',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 1,
							},
						},
						[3] = {
							['filterString'] = 'G4',
							['color'] = {
								[1] = 0.19626484811306,
								[2] = 0.8776371479034424,
								[3] = 0.4550137221813202,
								[4] = 1,
							},
						},
						[7] = {
							['filterString'] = 'G5',
							['color'] = {
								[1] = 0.1416439712047577,
								[2] = 0.9873417615890503,
								[3] = 0.8481762409210204,
								[4] = 1,
							},
						},
						[4] = {
							['filterString'] = 'G2',
							['color'] = {
								[1] = 0.7212910056114197,
								[2] = 0.43643292784690857,
								[3] = 0.8691983222961426,
								[4] = 1,
							},
						},
						[6] = {
							['filterString'] = 'G3',
							['color'] = {
								[1] = 0.9746835231781006,
								[2] = 0.8278276920318604,
								[3] = 0.08225178718566895,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*# kick #*#',
				},
				[5] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.8578199148178101,
								[2] = 0.21547134220600123,
								[3] = 0.21547134220600123,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = 'backstabs you',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'GP1',
							['color'] = {
								[1] = 0.7328043580055237,
								[2] = 0.8691983222961426,
								[3] = 0.04034252092242241,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#backstabs #*#',
				},
				[3] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.37263315916061396,
								[2] = 0.668586730957031,
								[3] = 0.7488151788711548,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'G1',
							['color'] = {
								[1] = 0.9240506291389463,
								[2] = 0.6211171746253965,
								[3] = 0.19884634017944336,
								[4] = 1,
							},
						},
						[5] = {
							['filterString'] = 'slashes you',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 1,
							},
						},
						[3] = {
							['filterString'] = 'G4',
							['color'] = {
								[1] = 0.20377789437770844,
								[2] = 0.8185653686523438,
								[3] = 0.46836987137794495,
								[4] = 1,
							},
						},
						[7] = {
							['filterString'] = 'G5',
							['color'] = {
								[1] = 0.23952712118625635,
								[2] = 0.9156118035316465,
								[3] = 0.8899376392364502,
								[4] = 1,
							},
						},
						[4] = {
							['filterString'] = 'G2',
							['color'] = {
								[1] = 0.7114106416702268,
								[2] = 0.29375636577606196,
								[3] = 0.9282700419425962,
								[4] = 1,
							},
						},
						[6] = {
							['filterString'] = 'G3',
							['color'] = {
								[1] = 0.9620253443717957,
								[2] = 0.7847059965133667,
								[3] = 0.13801208138465879,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#slash#*#point#*# of damage#*#',
				},
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = 'G1',
							['color'] = {
								[1] = 0.8776371479034424,
								[2] = 0.6038413047790525,
								[3] = 0.22218659520149225,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'G2',
							['color'] = {
								[1] = 0.7760439515113831,
								[2] = 0.3065747916698456,
								[3] = 0.8860759735107422,
								[4] = 1,
							},
						},
						[5] = {
							['filterString'] = 'crushes you',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 1,
							},
						},
						[3] = {
							['filterString'] = 'G5',
							['color'] = {
								[1] = 0.2215456962585449,
								[2] = 0.7721518874168396,
								[3] = 0.7373032569885254,
								[4] = 1,
							},
						},
						[7] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.5520521402359009,
								[2] = 0.5272119045257566,
								[3] = 0.7725118398666382,
								[4] = 1,
							},
						},
						[4] = {
							['filterString'] = 'G3',
							['color'] = {
								[1] = 0.9240506291389463,
								[2] = 0.8307719826698301,
								[3] = 0.1052715703845024,
								[4] = 1,
							},
						},
						[6] = {
							['filterString'] = 'G4',
							['color'] = {
								[1] = 0.21150457859039307,
								[2] = 0.9113923907279966,
								[3] = 0.4772846698760986,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#crush#*#point#*# of damage#*#',
				},
				[4] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = 'G2',
							['color'] = {
								[1] = 0.7948693633079529,
								[2] = 0.29637700319290156,
								[3] = 0.9620853066444397,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'pierces you',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 1,
							},
						},
						[5] = {
							['filterString'] = 'G1',
							['color'] = {
								[1] = 0.7383966445922852,
								[2] = 0.3770267069339751,
								[3] = 0.15577988326549524,
								[4] = 1,
							},
						},
						[3] = {
							['filterString'] = 'G5',
							['color'] = {
								[1] = 0.37508234381675715,
								[2] = 0.8689647912979126,
								[3] = 0.9662446975708008,
								[4] = 1,
							},
						},
						[7] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.5162283182144164,
								[2] = 0.5191102623939512,
								[3] = 0.6682464480400083,
								[4] = 1,
							},
						},
						[4] = {
							['filterString'] = 'G3',
							['color'] = {
								[1] = 0.7877751588821409,
								[2] = 0.9336493015289307,
								[3] = 0.278767317533493,
								[4] = 1,
							},
						},
						[6] = {
							['filterString'] = 'G4',
							['color'] = {
								[1] = 0.26438069343566895,
								[2] = 0.949367105960846,
								[3] = 0.4724777042865752,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#pierce#*#point#*# of damage#*#',
				},
				[6] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.07594943046569823,
								[2] = 1,
								[3] = 0,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.36819285154342646,
								[2] = 0.7488151788711548,
								[3] = 0.23067767918109894,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'bashes you',
							['color'] = {
								[1] = 0.9810426235198975,
								[2] = 0.023247433826327324,
								[3] = 0.023247433826327324,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*# bash#*#',
				},
			},
			['Echo'] = '/gu',
			['enabled'] = true,
			['MainEnable'] = false,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
		[7] = {
			['Name'] = 'Shout',
			['Events'] = {
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 0.05485230684280395,
								[3] = 0.05485230684280395,
								[4] = 1,
							},
						},
						[1] = {
							['filterString'] = '^You',
							['color'] = {
								[1] = 0.7594936490058899,
								[2] = 0.7018105983734131,
								[3] = 0.707651913166046,
								[4] = 1,
							},
						},
						[2] = {
							['filterString'] = 'shouts',
							['color'] = {
								[1] = 1,
								[2] = 0,
								[3] = 0,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#shout#*#',
				},
			},
			['Echo'] = '/shout',
			['enabled'] = true,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
		[9000] = {
			['Name'] = 'Spam',
			['Events'] = {
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 1,
								[2] = 1,
								[3] = 1,
								[4] = 1,
							},
						},
					},
					['eventString'] = '#*#',
				},
			},
			['Echo'] = '/say',
			['enabled'] = false,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
		[6] = {
			['Name'] = 'Guild',
			['Events'] = {
				[1] = {
					['enabled'] = true,
					['Filters'] = {
						[0] = {
							['filterString'] = '',
							['color'] = {
								[1] = 0.3120104670524595,
								[2] = 0.8227847814559937,
								[3] = 0.13886664807796473,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[1] = {
							['filterString'] = 'You',
							['color'] = {
								[1] = 0.24867810308933253,
								[2] = 0.8185653686523438,
								[3] = 0.6670762896537781,
								[4] = 1,
							},
							['enabled'] = true,
						},
						[2] = {
							['filterString'] = 'tells the guild',
							['color'] = {
								[1] = 0.5014937520027161,
								[2] = 1,
								[3] = 0.2322275042533874,
								[4] = 1,
							},
							['enabled'] = true,
						},
					},
					['eventString'] = '#*# guild, \'#*#',
				},
			},
			['Echo'] = '/gu',
			['enabled'] = false,
			['MainEnable'] = true,
			['PopOut'] = false,
			['locked'] = false,
			['Scale'] = 1,
		},
	},
	['locked'] = false,
	['doLinks'] = false,
	['timeStamps'] = true,
	['LoadTheme'] = 'Default',
	['Scale'] = 1,
}