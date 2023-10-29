module main

import math

fn test_triangle_area() {
	triangle_polygon_with_area_1 := Polygon{[
		Point{0.0, -1.0},
		Point{1.0, 0.0},
		Point{0.0, 1.0},
		Point{0.0, -1.0},
	]}

	assert geom_tools_area_polygon(triangle_polygon_with_area_1) == 1.0
}

fn test_parallelogram_area() {
	parallelogram_polygon_with_area_8 := Polygon{[
		Point{-2.0, -1.0},
		Point{2.0, -1.0},
		Point{3.0, 1.0},
		Point{-1.0, 1.0},
		Point{-2.0, -1.0},
	]}

	assert geom_tools_area_polygon(parallelogram_polygon_with_area_8) == 8.0
}

fn test_complex_figure_with_right_angles_area() {
	complex_figure_with_right_angles := Polygon{[
		Point{35.97872543334961, -34.659114837646484},
		Point{35.97872543334961, -37.01911163330078},
		Point{33.9708251953125, -37.01911163330078},
		Point{33.9708251953125, -37.219112396240234},
		Point{34.07872772216797, -37.219112396240234},
		Point{34.0787277221679, -38.4352912902832},
		Point{33.15372467041016, -38.4352912902832},
		Point{33.153724670410156, -37.219112396240234},
		Point{33.25210189819336, -37.219112396240234},
		Point{33.25210189819336, -37.01911163330078},
		Point{32.90689468383789, -37.01911163330078},
		Point{32.90689468383789, -37.219112396240234},
		Point{33.003726959228516, -37.219112396240234},
		Point{33.00372695922856, -38.4352912902832},
		Point{32.0787277221679, -38.4352912902832},
		Point{32.07872772216797, -37.219112396240234},
		Point{32.193763732910156, -37.219112396240234},
		Point{32.19376373291015, -37.01911163330078},
		Point{30.50872802734375, -37.01911163330078},
		Point{30.50872802734375, -34.659114837646484},
		Point{35.97872543334961, -34.659114837646484},
	]}

	assert geom_tools_area_polygon(complex_figure_with_right_angles) == 15.44548203003069 // 15.44548203003071 ?
}

fn test_point_inside_triangle() {
	triangle_polygon_with_area_0_5 := Polygon{[
		Point{0.0, 0.0},
		Point{1.0, 0.0},
		Point{0.0, 1.0},
		Point{0.0, 0.0},
	]}
	points := [
		Point{0.0, 0.0},
		Point{0.5, 0.0},
		Point{1.0, 0.0},
		Point{0.5, 0.5},
		Point{0.0, 1.0},
		Point{0.0, 0.5},
		Point{0.0, 0.0},
	]

	for point in points {
		assert geom_tools_is_point_in_polygon(&point, &triangle_polygon_with_area_0_5), '${point} should be inside triangle'
	}
}

fn test_point_outside_triangle() {
	triangle_polygon_with_area_0_5 := Polygon{[
		Point{0.0, 0.0},
		Point{1.0, 0.0},
		Point{0.0, 1.0},
		Point{0.0, 0.0},
	]}
	points := [
		Point{-1.0, -1.0},
		Point{0.5, -1.0},
		Point{1.5, -0.5},
		Point{1.0, 1.0},
		Point{-0.5, 1.5},
		Point{-0.5, 0.5},
	]

	for point in points {
		assert !geom_tools_is_point_in_polygon(&point, &triangle_polygon_with_area_0_5), '${point} should be outside triangle'
	}
}

fn test_point_inside_square() {
	square_polygon := Polygon{[
		Point{0.0, 0.0},
		Point{1.0, 0.0},
		Point{1.0, 1.0},
		Point{0.0, 1.0},
		Point{0.0, 0.0},
	]}
	points := [
		Point{0.0, 0.0},
		Point{0.5, 0.0},
		Point{1.0, 0.0},
		Point{1.0, 0.5},
		Point{1.0, 1.0},
		Point{0.5, 1.0},
		Point{0.0, 1.0},
		Point{0.0, 0.5},
		Point{0.5, 0.5},
	]

	for point in points {
		assert geom_tools_is_point_in_polygon(&point, &square_polygon), '${point} should be inside square'
	}
}

fn test_point_outside_square() {
	square_polygon := Polygon{[
		Point{0.0, 0.0},
		Point{1.0, 0.0},
		Point{1.0, 1.0},
		Point{0.0, 1.0},
		Point{0.0, 0.0},
	]}
	points := [
		Point{-0.5, -0.5},
		Point{0.5, -0.5},
		Point{1.5, -0.5},
		Point{1.5, 0.5},
		Point{1.5, 1.5},
		Point{0.5, 1.5},
		Point{-0.5, 1.5},
		Point{-0.5, 0.5},
	]

	for point in points {
		assert !geom_tools_is_point_in_polygon(&point, &square_polygon), '${point} should be outside square'
	}
}

fn test_polygon_intersection() {
	complex_figure_with_right_angles := Polygon{[
		Point{35.97872543334961, -34.659114837646484},
		Point{35.97872543334961, -37.01911163330078},
		Point{33.9708251953125, -37.01911163330078},
		Point{33.9708251953125, -37.219112396240234},
		Point{34.07872772216797, -37.219112396240234},
		Point{34.0787277221679, -38.4352912902832},
		Point{33.15372467041016, -38.4352912902832},
		Point{33.153724670410156, -37.219112396240234},
		Point{33.25210189819336, -37.219112396240234},
		Point{33.25210189819336, -37.01911163330078},
		Point{32.90689468383789, -37.01911163330078},
		Point{32.90689468383789, -37.219112396240234},
		Point{33.003726959228516, -37.219112396240234},
		Point{33.00372695922856, -38.4352912902832},
		Point{32.0787277221679, -38.4352912902832},
		Point{32.07872772216797, -37.219112396240234},
		Point{32.193763732910156, -37.219112396240234},
		Point{32.19376373291015, -37.01911163330078},
		Point{30.50872802734375, -37.01911163330078},
		Point{30.50872802734375, -34.659114837646484},
		Point{35.97872543334961, -34.659114837646484},
	]}
	points_outside := [
		Point{31.87872886657715, -38.24702072143555},
		Point{31.87872886657715, -37.34701919555664},
	]
	points_inside := [
		Point{32.07872772216797, -38.24702072143555},
		Point{32.07872772216797, -37.34701919555664},
	]

	for point_outside in points_outside {
		assert !geom_tools_is_point_in_polygon(&point_outside, &complex_figure_with_right_angles), '${point_outside} should be outside polygon'
	}

	for point_inside in points_inside {
		assert geom_tools_is_point_in_polygon(&point_inside, &complex_figure_with_right_angles), '${point_inside} should be inside polygon'
	}
}

fn test_on_segment() {
	point1 := Point{0.0, 0.0}
	point2 := Point{1.0, 0.0}
	point_to_check := Point{0.0, 0.0}

	assert on_segment(&point1, &point_to_check, &point2)
}

fn test_length_side() {
	point1 := Point{0.0, 0.0}
	point2 := Point{1.0, -1.0}

	assert geom_tools_length_side(&point1, &point2) == math.sqrt(2.0)
}
