module main

import cli { Command }
import os
import json
import time

fn main() {
	mut cmd := Command{
		name: 'EvacuationV'
		description: 'EvacuationV'
		version: '0.1.0'
	}
	mut config_cmd := Command{
		name: 'cfg'
		description: 'Configuration file'
		usage: '<file>'
		required_args: 1
		execute: app
	}
	cmd.add_command(config_cmd)
	cmd.setup()
	cmd.parse(os.args)
}

fn app(cmd Command) ! {
	cfg_file_name := cmd.args[0]
	full_path := os.abs_path(cfg_file_name)
	println('Using scenario configuration file: ${full_path}')
	scenario_configuration_json := os.read_file(full_path) or {
		panic('Cannot read file ${full_path}')
	}

	scenario_configuration := json.decode(BimCfgScenario, scenario_configuration_json) or {
		panic('Failed to decode BimCfgScenario. Error: ${err}')
	}

	sw := time.new_stopwatch()
	for bim_file_name in scenario_configuration.bim {
		modeling_result := run_modeling(&bim_file_name, &scenario_configuration)

		println('Длительность эвакуации: ${modeling_result.evacuation_time_in_sec:.2} с. (${modeling_result.evacuation_time_in_min:.2} мин.)')
		println('Количество человек: в здании - ${modeling_result.number_of_people_in_building:.2} (в безопасной зоне - ${modeling_result.number_of_evacuated_people:.2}) чел.')
		println('---------------------------------------')
	}
	println("Elapsed ${sw.elapsed().milliseconds()} ms")
}

fn apply_scenario_bim_params(mut bim Bim, scenario_configuration &BimCfgScenario) {
	// FIXME: remove double iteration: bim.transits && bim.level.transits, bim.zones && bim.level.zones
	for mut transit in bim.transits {
		if scenario_configuration.transits.@type == 'users' {
			if transit.sign == 'DoorWayInt' {
				transit.width = scenario_configuration.transits.doorwayin
			} else if transit.sign == 'DoorWayOut' {
				transit.width = scenario_configuration.transits.doorwayout
			}
		}

		// A special set up the transit width of item of bim
		for special in scenario_configuration.transits.special {
			for special_uuid in special.uuid {
				if special_uuid == transit.uuid {
					transit.width = special.width
				}
			}
		}
	}

	for mut level in bim.levels {
		for mut transit in level.transits {
			if scenario_configuration.transits.@type == 'users' {
				if transit.sign == 'DoorWayInt' {
					transit.width = scenario_configuration.transits.doorwayin
				} else if transit.sign == 'DoorWayOut' {
					transit.width = scenario_configuration.transits.doorwayout
				}
			}

			// A special set up the transit width of item of bim
			for special in scenario_configuration.transits.special {
				for special_uuid in special.uuid {
					if special_uuid == transit.uuid {
						transit.width = special.width
					}
				}
			}
		}
	}

	for mut zone in bim.zones {
		if zone.sign == 'Outside' {
			continue
		}

		if scenario_configuration.distribution.@type == 'uniform' {
			bim_tools_set_people_to_zone(mut zone, zone.area * scenario_configuration.distribution.density)
		}

		// A special set up the density of item of bim
		for special in scenario_configuration.distribution.special {
			for special_uuid in special.uuid {
				if special_uuid == zone.uuid {
					bim_tools_set_people_to_zone(mut zone, zone.area * special.density)
				}
			}
		}
	}

	for mut level in bim.levels {
		for mut zone in level.zones {
			if zone.sign == 'Outside' {
				continue
			}

			if scenario_configuration.distribution.@type == 'uniform' {
				bim_tools_set_people_to_zone(mut zone, zone.area * scenario_configuration.distribution.density)
			}

			// A special set up the density of item of bim
			for special in scenario_configuration.distribution.special {
				for special_uuid in special.uuid {
					if special_uuid == zone.uuid {
						bim_tools_set_people_to_zone(mut zone, zone.area * special.density)
					}
				}
			}
		}
	}
}
