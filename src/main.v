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

	println(scenario_configuration)

	for bim_file_name in scenario_configuration.bim {
		bim_json := bim_json_new(bim_file_name)

		bim_tools := bim_tools_new(bim_json)
	}
}
