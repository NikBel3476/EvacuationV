module main

import math

/// Структура, расширяющая элемент DOOR_*
struct BimTransit {
mut:
	uuid           string   ///< UUID идентификатор элемента
	id             usize    ///< Внутренний номер элемента
	name           string   ///< Название элемента
	outputs        []string ///< Массив UUID элементов, которые являются соседними
	polygon        Polygon  ///< Полигон элемента
	size_z         f64      ///< Высота элемента
	z_level        f64      ///< Уровень, на котором находится элемент
	width          f64      ///< Ширина проема/двери
	nop_proceeding f64      ///< Количество людей, которые прошли через элемент
	sign           string   ///< Тип элемента
	is_visited     bool     ///< Признак посещения элемента
	is_blocked     bool     ///< Признак недоступности элемента для движения
}

/// Структура, расширяющая элемент типа ROOM и STAIR
struct BimZone {
mut:
	uuid         string   ///< UUID идентификатор элемента
	id           usize    ///< Внутренний номер элемента
	name         string   ///< Название элемента
	polygon      Polygon  ///< Полигон элемента
	outputs      []string ///< Массив UUID элементов, которые являются соседними
	size_z       f64      ///< Высота элемента
	z_level      f64      ///< Уровень, на котором находится элемент
	numofpeople  f64      ///< Количество людей в элементе
	potential    f64      ///< Время достижения безопасной зоны
	area         f64      ///< Площадь элемента
	hazard_level u8       ///< Уровень опасности, % (0, 10, 20, ..., 90, 100)
	sign         string   ///< Тип элемента
	is_visited   bool     ///< Признак посещения элемента
	is_blocked   bool     ///< Признак недоступности элемента для движения
	is_safe      bool     ///< Признак безопасности зоны, т.е. в эту зону возможна эвакуация
}

/// Структура, описывающая этаж
struct BimLevel {
mut:
	zones    []BimZone    ///< Массив зон, которые принадлежат этажу
	transits []BimTransit ///< Массив переходов, которые принадлежат этажу
	name     string       ///< Название этажа
	z_level  f64 ///< Высота этажа над нулевой отметкой
}

/// Структура, описывающая здание
struct Bim {
mut:
	levels   []BimLevel   ///< Массив уровней здания
	name     string       ///< Название здания
	zones    []BimZone    ///< Список зон объекта
	transits []BimTransit ///< Список переходов объекта
}

fn bim_tools_new(bim_json &BimJsonObject) Bim {
	mut bim_element_rs_id := usize(0)
	mut bim_element_d_id := usize(0)
	mut bim_zones := []BimZone{}
	mut bim_transits := []BimTransit{}
	mut levels := []BimLevel{}

	for json_level in bim_json.levels {
		mut level_zones := []BimZone{}
		mut level_transits := []BimTransit{}

		for json_element in json_level.elements {
			if json_element.sign in ['Room', 'Staircase'] {
				zone := BimZone{
					uuid: json_element.uuid
					id: bim_element_rs_id++
					name: json_element.name
					polygon: json_element.xy[0]
					outputs: json_element.outputs
					size_z: json_element.size_z
					z_level: json_level.z_level
					numofpeople: 0
					potential: math.max_f64
					area: geom_tools_area_polygon(json_element.xy[0])
					hazard_level: 0
					sign: json_element.sign
					is_visited: false
					is_blocked: false
					is_safe: false
				}
				level_zones << zone
				bim_zones << zone
			} else if json_element.sign in ['DoorWay', 'DoorWayInt', 'DoorWayOut'] {
				transit := BimTransit{
					uuid: json_element.uuid
					id: bim_element_d_id++
					name: json_element.name
					outputs: json_element.outputs
					polygon: json_element.xy[0]
					size_z: json_element.size_z
					z_level: json_level.z_level
					width: -1.0
					nop_proceeding: 0.0
					sign: json_element.sign
					is_visited: false
					is_blocked: false
				}
				level_transits << transit
				bim_transits << transit
			}
		}

		level := BimLevel{
			zones: level_zones
			transits: level_transits
			name: json_level.name
			z_level: json_level.z_level
		}
		levels << level
	}

	outside_zone := outside_init(bim_json)
	bim_zones << outside_zone

	bim_zones.sort(a.id < b.id)
	bim_transits.sort(a.id < b.id)

	calculate_transits_width(bim_zones, mut bim_transits)

	bim := Bim{
		name: bim_json.name
		levels: levels
		zones: bim_zones
		transits: bim_transits
	}

	return bim
}

fn outside_init(bim_json &BimJsonObject) BimZone {
	mut outputs := []string{}
	mut outside_id := usize(0)

	for json_level in bim_json.levels {
		for json_element in json_level.elements {
			if json_element.sign == 'DoorWayOut' {
				outputs << json_element.uuid
			} else if json_element.sign in ['Room', 'Staircase'] {
				outside_id++
			}
		}
	}

	outside_zone := BimZone{
		uuid: 'outside0-safe-zone-0000-000000000000'
		id: outside_id
		name: 'Outside'
		polygon: Polygon{
			points: []
		}
		outputs: outputs
		size_z: math.max_f64
		z_level: 0
		numofpeople: 0
		potential: 0
		area: math.max_f64
		hazard_level: 0
		sign: 'Outside'
		is_visited: false
		is_blocked: false
		is_safe: true
	}
	return outside_zone
}

// Вычисление ширины проема по данным из модели здания
fn calculate_transits_width(zones []BimZone, mut transits []BimTransit) {
	for i, mut transit in transits {
		related_zones := zones.filter(it.uuid in transit.outputs)

		if related_zones.len == 0 {
			panic('Не найден элемент, соединенный с переходом:\n${transit}')
		}

		if related_zones.all(it.sign == 'Staircase') { // => Межэтажный проем
			transits[i].width = math.sqrt((related_zones[0].area + related_zones[1].area) / 2)
			continue
		}

		mut edge1 := Line{Point{0, 0}, Point{0, 0}}
		mut edge2 := Line{Point{0, 0}, Point{0, 0}}
		mut numofpoints_edge1 := 2
		mut numofpoints_edge2 := 2
		for point in transit.polygon.points {
			if geom_tools_is_point_in_polygon(&point, related_zones[0].polygon) {
				match numofpoints_edge1 {
					2 { edge1.p1 = point }
					1 { edge1.p2 = point }
					else { continue }
				}
				numofpoints_edge1--
			} else {
				match numofpoints_edge2 {
					2 { edge2.p1 = point }
					1 { edge2.p2 = point }
					else { continue }
				}
				numofpoints_edge2--
			}
		}

		mut width := -1.0
		if numofpoints_edge1 > 0 || numofpoints_edge2 > 0 {
			panic('Невозможно вычислить ширину двери:\n${transit}')
		}

		if transit.sign in ['DoorWayInt', 'DoorWayOut'] {
			width1 := geom_tools_length_side(edge1.p1, edge1.p2)
			width2 := geom_tools_length_side(edge2.p1, edge2.p2)

			width = (width1 + width2) / 2.0
		} else if transit.sign == 'DoorWay' {
			width = width_door_way(related_zones[0].polygon, related_zones[1].polygon,
				edge1, edge2)
		}

		transits[i].width = width

		if transits[i].width < 0.0 {
			panic('Ширина проема не определена:\n${transit}')
		} else if transits[i].width < 0.5 {
			// TODO: add warning
		}
	}
}

fn width_door_way(zone1 &Polygon, zone2 &Polygon, edge1 &Line, edge2 &Line) f64 {
	/*
	* Возможные варианты стыковки помещений, которые соединены проемом
     * Код ниже определяет область их пересечения
       +----+  +----+     +----+
            |  |               | +----+
            |  |               | |
            |  |               | |
       +----+  +----+          | |
                               | +----+
       +----+             +----+
            |  +----+
            |  |          +----+ +----+
            |  |               | |
       +----+  |               | |
               +----+          | +----+
                          +----+
     *************************************************************************
     * 1. Определить грани помещения, которые пересекает короткая сторона проема
     * 2. Вычислить среднее проекций граней друг на друга
	*/

	l1p1 := edge1.p1
	l1p2 := edge2.p2
	length1 := geom_tools_length_side(l1p1, l1p2)

	// FIXME: the same points uses again
	l2p1 := edge1.p1
	l2p2 := edge2.p2
	length2 := geom_tools_length_side(l2p1, l2p2)

	// Короткая линия проема, которая пересекает оба помещения
	mut dline := Line{Point{0, 0}, Point{0, 0}}
	if length1 >= length2 {
		dline.p1 = l2p1
		dline.p2 = l2p2
	} else {
		dline.p1 = l1p1
		dline.p2 = l1p2
	}

	// Линии, которые находятся друг напротив друга и связаны проемом
	edge_element_a := intersected_edge(zone1, &dline)
	edge_element_b := intersected_edge(zone2, &dline)

	// Поиск точек, которые являются ближайшими к отрезку edgeElement
	// Расстояние между этими точками и является шириной проема
	pt1 := geom_tools_nearest_point(edge_element_a.p1, edge_element_b)
	pt2 := geom_tools_nearest_point(edge_element_a.p2, edge_element_b)
	d12 := geom_tools_length_side(pt1, pt2)

	pt3 := geom_tools_nearest_point(edge_element_b.p1, edge_element_a)
	pt4 := geom_tools_nearest_point(edge_element_b.p2, edge_element_a)
	d34 := geom_tools_length_side(pt3, pt4)

	return (d12 + d34) / 2
}

fn intersected_edge(polygon &Polygon, line_to_check &Line) Line {
	mut line := Line{Point{0, 0}, Point{0, 0}}

	mut num_of_intersect := 0
	for i := 1; i < polygon.points.len; i++ {
		point_element_a := polygon.points[i - 1]
		point_element_b := polygon.points[i]
		line_tmp := Line{point_element_a, point_element_b}
		is_intersect := geom_tools_is_intersect_line(line_to_check, &line_tmp)
		if is_intersect {
			line.p1 = point_element_a
			line.p2 = point_element_b
			num_of_intersect++
		}
	}

	// TODO: move this error handler on above level to provide more information
	if num_of_intersect != 1 {
		panic('Ошибка геометрии. Проверьте правильность ввода дверей и вирутальных проемов.\n')
	}

	return line
}

fn bim_tools_set_people_to_zone(mut zone BimZone, num_of_people f64) {
	zone.numofpeople = num_of_people
}

fn bim_tools_get_area_bim(bim &Bim) f64 {
	mut area := 0.0
	for level in bim.levels {
		for zone in level.zones {
			if zone.sign in ['Room', 'Staircase'] {
				area += zone.area
			}
		}
	}
	return area
}

fn bim_tools_get_numofpeople(bim &Bim) f64 {
	mut numofpeople := 0.0
	for zone in bim.zones {
		if zone.sign != 'Outside' {
			numofpeople += zone.numofpeople
		}
	}
	return numofpeople
}
