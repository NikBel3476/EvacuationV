module main

import math

struct EvacConfiguration {
mut:
	max_speed f64
	min_density f64
	max_density f64
	modeling_step f64
	evac_time f64
}

fn evac_def_modeling_step(bim &Bim, evac_cfg &EvacConfiguration) f64 {
	area := bim_tools_get_area_bim(bim)

	average_size := area / bim.zones.len
	hxy := math.sqrt(average_size) // характерный размер области, м
	return if evac_cfg.modeling_step == 0.0 {
		hxy / evac_cfg.max_speed * 0.1
	} else {
		evac_cfg.modeling_step
	}
}

fn evac_moving_step(
	graph &BimGraph,
	mut zones []BimZone,
	mut transits []BimTransit,
	evac_cfg &EvacConfiguration
) {
	reset_zones(mut zones)
	reset_transits(mut transits)

	mut zones_to_process := []&BimZone{}

	unsafe {
		outside_id := graph.node_count - 1
		mut ptr := &graph.head[outside_id]
		mut receiving_zone := &zones[outside_id]

		for _ in 0..zones.len {
			for i := 0; i < receiving_zone.outputs.len && ptr != nil; i++ {
				mut transit := &transits[ptr.eid]

				if transit.is_visited || transit.is_blocked {
					ptr = ptr.next
					continue
				}

				mut giver_zone := &zones[ptr.dest]

				receiving_zone.potential = potential_element(
					receiving_zone,
					giver_zone,
					transit,
					evac_cfg.max_speed
				)
				moved_people := part_people_flow(
					receiving_zone,
					giver_zone,
					transit,
					evac_cfg.min_density,
					evac_cfg.max_density,
					evac_cfg.max_speed,
					evac_cfg.modeling_step
				)
				receiving_zone.numofpeople += moved_people
				giver_zone.numofpeople -= moved_people
				transit.nop_proceeding = moved_people

				giver_zone.is_visited = true
				transit.is_visited = true

				if giver_zone.outputs.len > 1 &&
					!giver_zone.is_blocked &&
					!zones_to_process.any(it.id == giver_zone.id)
				{
					zones_to_process << giver_zone
				}

				ptr = ptr.next
			}

			zones_to_process.sort(a.potential < b.potential)

			if zones_to_process.len > 0 {
				receiving_zone = zones_to_process[0]
				ptr = &graph.head[receiving_zone.id]
				zones_to_process.delete(0)
			}
		}
	}
}

fn reset_zones(mut zones []BimZone) {
	for mut zone in zones {
		zone.is_visited = false
		zone.potential = if zone.sign == "DoorWayOut" { 0 } else { math.max_f64 }
	}
}

fn reset_transits(mut transits []BimTransit) {
	for mut transit in transits {
		transit.is_visited = false
		transit.nop_proceeding = 0.0
	}
}

// Подсчет потенциала
// TODO Уточнить корректность подсчета потенциала
// TODO Потенциал должен считаться до эвакуации из помещения или после?
// TODO Когда возникает ситуация, что потенциал принимающего больше отдающего
fn potential_element(
	receiving_zone &BimZone,
	giver_zone &BimZone,
	transit &BimTransit,
	evac_speed_max f64
) f64 {
	p := math.sqrt(giver_zone.area) /
		speed_at_exit(receiving_zone, giver_zone, transit.width, evac_speed_max)
	if receiving_zone.potential >= math.max_f64 {
		return p
	}
	return receiving_zone.potential + p
}

fn speed_at_exit(
	receiving_zone &BimZone,
	giver_zone &BimZone,
	transit_width f64,
	evac_speed_max f64
) f64 {
	zone_speed := speed_in_element(receiving_zone, giver_zone, evac_speed_max)
	density_in_giver_element := giver_zone.numofpeople / giver_zone.area
	transition_speed := speed_trough_transit(transit_width, density_in_giver_element, evac_speed_max)
	exit_speed := math.min(zone_speed, transition_speed)
	return exit_speed
}

fn speed_in_element(receiving_zone &BimZone, giver_zone &BimZone, evac_speed_max f64) f64 {
	density_in_giver_zone := giver_zone.numofpeople / giver_zone.area
	// По умолчанию, используется скорость движения по горизонтальной поверхности
	mut v_zone := speed_in_room(density_in_giver_zone, evac_speed_max)

	dh := receiving_zone.z_level - giver_zone.z_level // Разница высот зон

	// Если принимающее помещение является лестницей и находится на другом уровне,
	// то скорость будет рассчитываться как по наклонной поверхности
	if math.abs(dh) > 1E-3 && receiving_zone.sign == "Staircase" {
		/* Иначе определяем направление движения по лестнице
       * -1 вниз, 1 вверх
       *         ______   aGiverItem
       *        /                         => direction = -1
       *       /
       * _____/           aReceivingItem
       *      \
       *       \                          => direction = 1
       *        \______   aGiverItem
       */
		direction := if dh > 0 { -1 } else { 1 }
		v_zone = evac_speed_on_stair(density_in_giver_zone, direction)
	}

	if v_zone < 0 {
		panic("Скорость в отдающей зоне меньше 0. ${giver_zone}")
	}

	return v_zone
}

fn speed_in_room(density_in_zone f64, v_max f64) f64 {
	v0 := v_max; // м/мин
	d0 := 0.51;
	a := 0.295;

	return if density_in_zone > d0 { velocity(v0, a, density_in_zone, d0) } else { v0 }
}

fn evac_speed_on_stair(density_in_zone f64, direction int) f64 {
	mut d0 := 0.0
	mut v0 := 0.0
	mut a := 0.0

	if direction > 0 {
		d0 = 0.67;
		v0 = 50.0;
		a = 0.305;
	} else if direction < 0 {
		d0 = 0.89;
		v0 = 80.0;
		a = 0.4;
	}

	return if density_in_zone > d0 { velocity(v0, a, density_in_zone, d0) } else { v0 }
}

/**
 * Функция скорости. Базовая зависимость, которая позволяет определить скорость людского
 * потока по его плотности
 * @brief _velocity
 * @param v0   начальная скорость потока
 * @param a    коэффициент вида пути
 * @param d    текущая плотность людского потока на участке, чел./м2
 * @param d0   допустимая плотность людского потока на участке, чел./м2
 * @return      скорость, м/мин.
 */
fn velocity(v0 f64,a f64,d f64,d0 f64) f64 {
	return v0 * (1.0 - a * math.log(d / d0))
}

fn speed_trough_transit(transit_width f64, density_in_zone f64, v_max f64) f64 {
	mut v0 := v_max;
	mut d0 := 0.65;
	mut a := 0.295;
	mut v0k := -1.0;

	if density_in_zone > d0 {
		m := if density_in_zone > 5 { 1.25 - 0.05 * density_in_zone } else { 1 }
		v0k = velocity(v0, a, density_in_zone, d0) * m

		if density_in_zone >= 9 && transit_width < 1.6
		{
			v0k = 10 * (2.5 + 3.75 * transit_width) / d0
		}
	} else {
		v0k = v0
	}

	if v0k < 0 {
		panic("Скорость движения через переход меньше 0")
	}

	return v0k
}

/**
 * @brief _part_people_flow
 * @param receiving_zone    принимающее помещение
 * @param giver_zone        отдающее помещение
 * @param transit             дверь между этими помещениями
 * @return  количество людей
 */
fn part_people_flow(
	receiving_zone &BimZone,
	giver_zone &BimZone,
	transit &BimTransit,
	evac_density_min f64,
	evac_density_max f64,
	evac_speed_max f64,
	evac_modeling_step f64
) f64 {
	area_giver_zone := giver_zone.area
	people_in_giver_zone := giver_zone.numofpeople
	density_in_giver_zone := people_in_giver_zone / area_giver_zone
	density_min_giver_zone := if evac_density_min > 0 { evac_density_min } else { 0.5 / area_giver_zone }

	// Ширина перехода между зонами зависит от количества человек,
	// которое осталось в помещении. Если там слишком мало людей,
	// то они переходя все сразу, чтоб не дробить их
	door_width := transit.width
	speedatexit := speed_at_exit(receiving_zone, giver_zone, door_width, evac_speed_max)

	// Кол. людей, которые могут покинуть помещение
	part_of_people_flow := if density_in_giver_zone > density_min_giver_zone {
		change_numofpeople(giver_zone, door_width, speedatexit, evac_modeling_step)
	} else {
		people_in_giver_zone
	}

	// Т.к. зона вне здания принята безразмерной,
	// в нее может войти максимально возможное количество человек
	// Все другие зоны могут принять ограниченное количество человек.
	// Т.о. нужно проверить может ли принимающая зона вместить еще людей.
	// capacity_reciving_zone - количество людей, которое еще может
	// вместиться до достижения максимальной плотности
	// => если может вместить больше, чем может выйти, то вмещает всех вышедших,
	// иначе вмещает только возможное количество.
	max_numofpeople := evac_density_max * receiving_zone.area
	capacity_receiving_zone := max_numofpeople - receiving_zone.numofpeople
	// Такая ситуация возникает при плотности в принимающем помещении более Dmax чел./м2
	// Фактически capacity_reciving_zone < 0 означает, что помещение не может принять людей
	if capacity_receiving_zone < 0 {
		return 0.0
	}
	return if capacity_receiving_zone > part_of_people_flow {
		part_of_people_flow
	} else {
		capacity_receiving_zone
	}
}

fn change_numofpeople(
	giver_zone &BimZone,
	transit_width f64,
	speed_at_exit f64,
	evac_modeling_step f64
) f64 {
	density_in_element := giver_zone.numofpeople / giver_zone.area
	// Величина людского потока, через проем шириной aWidthDoor, чел./мин
	p := density_in_element * speed_at_exit * transit_width
	// Зная скорость потока, можем вычислить конкретное количество человек,
	// которое может перейти в принимющую зону (путем умножения потока на шаг моделирования)
	return p * evac_modeling_step
}

fn evac_time_inc(mut evac_cfg &EvacConfiguration) {
	evac_cfg.evac_time += evac_cfg.modeling_step
}

fn evac_get_time_s(evac_cfg &EvacConfiguration) f64 {
	return evac_cfg.evac_time * 60
}

fn evac_get_time_m(evac_cfg &EvacConfiguration) f64 {
	return evac_cfg.evac_time
}
