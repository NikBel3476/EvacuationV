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
		println("The file name of the used bim `${bim_file_name.split("/").last()}`")

		mut bim_tools := bim_tools_new(bim_json)

		apply_scenario_bim_params(mut bim_tools, scenario_configuration)

		mut total_area := 0.0
		mut total_num_of_people := 0.0
		for zone in bim_tools.zones {
			if zone.sign != "Outside" {
				total_area += zone.area
				total_num_of_people += zone.numofpeople
			}
		}
		println("people ${total_num_of_people}")
		println("area ${total_area}")

		bim_graph := bim_graph_new(bim_tools)

		mut evac_cfg := EvacConfiguration {
			max_speed: scenario_configuration.modeling.speed_max
			max_density: scenario_configuration.modeling.density_max
			min_density: scenario_configuration.modeling.density_min
			modeling_step: scenario_configuration.modeling.step
			evac_time: 0.0
		}
		evac_cfg.modeling_step = evac_def_modeling_step(bim_tools, &evac_cfg)

		remainder := 0.0 // Количество человек, которое может остаться в зд. для остановки цикла
		mut counter := 0
		println("bim ${bim_tools}")
		for {
			println("step ${counter++}------------------------------------------------------")
			evac_moving_step(&bim_graph, mut bim_tools.zones, mut bim_tools.transits, &evac_cfg)
			evac_time_inc(mut &evac_cfg)

			mut num_of_people := 0.0
			for zone in bim_tools.zones {
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
	// FIXME: remove double iteration: bim.transits && bim.level.transits, bim.zones && bim.level.zones
	for mut transit in bim.transits {
		if scenario_configuration.transits.@type == "users" {
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

	for mut level in bim.levels {
		for mut transit in level.transits {
			if scenario_configuration.transits.@type == "users" {
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
	}

	for mut zone in bim.zones {
		if zone.sign == "Outside" {
			continue
		}

		if scenario_configuration.distribution.@type == "uniform" {
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

	for mut level in bim.levels {
		for mut zone in level.zones {
			if zone.sign == "Outside" {
				continue
			}

			if scenario_configuration.distribution.@type == "uniform" {
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
}
