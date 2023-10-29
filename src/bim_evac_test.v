module main

fn test_speed_in_element() {
	receiving_zone := BimZone{
		id: 1
		name: 'Receiving zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}

	transmitting_zone := BimZone{
		id: 2
		name: 'Transmitting zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}
	max_speed := 100.0

	assert speed_in_element(&receiving_zone, &transmitting_zone, max_speed) == 80.13633567871892
}

fn test_speed_at_exit() {
	receiving_zone := BimZone{
		id: 1
		name: 'Receiving zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}

	transmitting_zone := BimZone{
		id: 2
		name: 'Transmitting zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}
	speed_max := 100.0
	transit_width := 1.0

	assert speed_at_exit(&receiving_zone, &transmitting_zone, transit_width, speed_max) == 80.13633567871892
}

fn test_change_num_of_people() {
	transmitting_zone := BimZone{
		id: 2
		name: 'Transmitting zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}
	transit_width := 1.0
	speedatexit := 50.0
	modeling_step := 0.01

	assert change_numofpeople(&transmitting_zone, transit_width, speedatexit, modeling_step) == 0.5
}

fn test_potential_element() {
	receiving_zone := BimZone{
		id: 1
		name: 'Receiving zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}

	transmitting_zone := BimZone{
		id: 2
		name: 'Transmitting zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}

	transit := BimTransit{
		uuid: '00000000-0000-0000-0000-000000000000'
		id: 1
		name: 'Transit'
		outputs: ['00000000-0000-0000-0000-000000000000']
		polygon: Polygon{[]}
		size_z: 2.0
		z_level: 1.0
		width: 1.0
		nop_proceeding: 0.0
		sign: 'DoorWay'
		is_visited: false
		is_blocked: false
	}
	speed_max := 100.0

	assert potential_element(&receiving_zone, &transmitting_zone, &transit, speed_max) == 1.039461221097587
}

fn test_part_people_flow() {
	receiving_zone := BimZone{
		id: 1
		name: 'Receiving zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}

	transmitting_zone := BimZone{
		id: 2
		name: 'Transmitting zone'
		uuid: '00000000-0000-0000-0000-000000000000'
		outputs: ['00000000-0000-0000-0000-000000000000']
		area: 10.0
		z_level: 1.0
		numofpeople: 10.0
		hazard_level: 0
		is_blocked: false
		is_visited: false
		is_safe: true
		sign: 'Room'
		size_z: 2.0
		polygon: Polygon{[]}
		potential: 1.0
	}

	transit := BimTransit{
		uuid: '00000000-0000-0000-0000-000000000000'
		id: 1
		name: 'Transit'
		outputs: ['00000000-0000-0000-0000-000000000000']
		polygon: Polygon{[]}
		size_z: 2.0
		z_level: 1.0
		width: 1.0
		nop_proceeding: 0.0
		sign: 'DoorWay'
		is_visited: false
		is_blocked: false
	}
	density_min := 0.1
	density_max := 5.0
	speed_max := 100.0
	modeling_step := 0.01

	assert part_people_flow(&receiving_zone, &transmitting_zone, &transit, density_min,
		density_max, speed_max, modeling_step) == 0.8013633567871893
}
