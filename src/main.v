module main

import cli { Command }
import os
import json

fn main() {
	mut cmd := Command {
		name: 'EvacuationV'
		description: 'EvacuationV'
		version: '0.1.0'
	}
	mut config_cmd := Command {
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

	// println(scenario_configuration)

	for bim_file_name in scenario_configuration.bim {
		bim_json := bim_json_new(bim_file_name)

		mut bim_tools := bim_tools_new(bim_json)

		apply_scenario_bim_params(mut &bim_tools, scenario_configuration)

		bim_graph := bim_graph_new(bim_tools)

		mut evac_cfg := EvacConfiguration {
			max_speed: scenario_configuration.modeling.speed_max
			max_density: scenario_configuration.modeling.density_max
			min_density: scenario_configuration.modeling.density_min
			modeling_step: scenario_configuration.modeling.step
			evac_time: 0.0
		}
		evac_cfg.modeling_step = evac_def_modeling_step(bim_tools, evac_cfg)

		mut transits := &bim_tools.transits
		mut zones := &bim_tools.zones

		remainder := 0.0 // Количество человек, которое может остаться в зд. для остановки цикла
		for {
			evac_moving_step(&bim_graph, mut zones, mut transits, evac_cfg)
			evac_time_inc(mut &evac_cfg)

			mut num_of_people := 0.0
			for zone in zones {
				if zone.is_visited {
					num_of_people += zone.numofpeople
				}
			}

			if num_of_people <= remainder {
				break
			}
		}

		println("Длительность эвакуации: ${evac_get_time_s(evac_cfg)} с. (${evac_get_time_m(evac_cfg)} мин.)")
		println("Количество человек: в здании - ${bim_tools_get_numofpeople(bim_tools)} (в безопасной зоне - ${bim_tools.zones.last().numofpeople}) чел.")
		println("---------------------------------------")
	}
}

fn apply_scenario_bim_params(mut bim &Bim, scenario_configuration &BimCfgScenario) {
	for mut transit in bim.transits {
		if scenario_configuration.transits.@type == .users {
			if transit.sign == "DoorWayInt" {
				transit.width = scenario_configuration.transits.doorwayin
			} else if transit.sign == "DoorWayOut" {
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

	for mut zone in bim.zones {
		if zone.sign == "Outside" {
			continue
		}

		if scenario_configuration.distribution.@type == .uniform {
			bim_tools_set_people_to_zone(mut zone, zone.area * scenario_configuration.distribution.density);
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
