module main

fn scenario_configuration() BimCfgScenario {
	return BimCfgScenario{
		bim: [
			'res/two_levels.json',
			'res/one_zone_one_exit.json',
			'res/three_zone_three_transit.json',
			'res/building_test.json',
			'res/example-one-exit.json',
			'res/example-two-exits.json',
			'res/udsu_block_1.json',
			'res/udsu_block_2.json',
			'res/udsu_block_3.json',
			'res/udsu_block_4.json',
			'res/udsu_block_5.json',
			'res/udsu_block_7.json',
		]
		distribution: BimCfgDistribution{
			@type: 'uniform'
			density: 1.0
			special: [
				DistributionSpecial{
					uuid: ['87c49613-44a7-4f3f-82e0-fb4a9ca2f46d']
					density: 1.0
					_comment: 'The uuid is Room_1 by three_zone_three_transit'
				},
			]
		}
		transits: BimCfgTransitionsWidth{
			@type: 'from_bim'
			doorwayin: 0.0
			doorwayout: 0.0
			special: [
				TransitionSpecial{
					uuid: ['dcbd8b6e-6dd0-4583-8aac-2492797f8032']
					width: 1.5
					_comment: 'The uuid is output by three_zone_three_transit'
				},
			]
		}
		modeling: BimCfgModeling{
			step: 0.01
			speed_max: 100.0
			density_min: 0.1
			density_max: 5.0
		}
	}
}

fn test_modeling() {
	cfg := scenario_configuration()
	results := [
		ModelingResult{
			evacuation_time_in_sec: 184.19999588280916
			evacuation_time_in_min: 3.0699999313801527
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 403.63159493204097
		},
		ModelingResult{
			evacuation_time_in_sec: 67.7999984845519
			evacuation_time_in_min: 1.1299999747425318
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 71.24836738425373
		},
		ModelingResult{
			evacuation_time_in_sec: 107.39999759942293
			evacuation_time_in_min: 1.7899999599903822
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 167.946623454526
		},
		ModelingResult{
			evacuation_time_in_sec: 102.59999770671129
			evacuation_time_in_min: 1.7099999617785215
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 333.80294939722967
		},
		ModelingResult{
			evacuation_time_in_sec: 40.799999088048935
			evacuation_time_in_min: 0.6799999848008156
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 83.73476930246652
		},
		ModelingResult{
			evacuation_time_in_sec: 25.199999436736107
			evacuation_time_in_min: 0.41999999061226845
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 83.73476930246649
		},
		ModelingResult{
			evacuation_time_in_sec: 1601.3999642059207
			evacuation_time_in_min: 26.68999940343201
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 7744.759455475453
		},
		ModelingResult{
			evacuation_time_in_sec: 658.7999852746725
			evacuation_time_in_min: 10.979999754577875
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 7336.1634225513935
		},
		ModelingResult{
			evacuation_time_in_sec: 395.3999911621213
			evacuation_time_in_min: 6.589999852702022
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 2512.1126045977494
		},
		ModelingResult{
			evacuation_time_in_sec: 1435.7999679073691
			evacuation_time_in_min: 23.92999946512282
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 8984.987407706734
		},
		ModelingResult{
			evacuation_time_in_sec: 505.19998870790005
			evacuation_time_in_min: 8.419999811798334
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 5230.64338349107
		},
		ModelingResult{
			evacuation_time_in_sec: 1560.5999651178718
			evacuation_time_in_min: 26.009999418631196
			number_of_people_in_building: 0.0
			number_of_evacuated_people: 7162.61893050353
		},
	]

	for i, bim_file_name in cfg.bim {
		assert run_modeling(&bim_file_name, &cfg) == results[i]
	}
}
