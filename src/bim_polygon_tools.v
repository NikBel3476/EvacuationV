module main

import math

struct Point {
mut:
	x f64
	y f64
}

struct Line {
mut:
	p1 Point
	p2 Point
}

struct Polygon {
	// numofpoints usize
	points []Point
}

fn geom_tools_length_side(p1 &Point, p2 &Point) f64 {
	return math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2))
}

fn geom_tools_area_polygon(polygon &Polygon) f64 {
	// https://ru.wikipedia.org/wiki/Формула_площади_Гаусса
	n := polygon.points.len - 2 // last point is equal to first, so we don't count it
	mut sum := polygon.points[n].x * polygon.points[0].y - polygon.points[0].x * polygon.points[n].y
	for i := 0 ; i < n; i++ {
		sum += polygon.points[i].x * polygon.points[i + 1].y - polygon.points[i + 1].x * polygon.points[i].y
	}
	return 0.5 * math.abs(sum)
}

fn on_segment(a &Point, b &Point, c &Point) bool {
	return geom_tools_length_side(a, b) + geom_tools_length_side(b, c) == geom_tools_length_side(a, c)
}

fn geom_tools_is_point_in_polygon(point &Point, polygon &Polygon) bool {
	// https://web.archive.org/web/20161108113341/https://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
	mut c := false
	mut point1 := polygon.points.last()
	for point2 in polygon.points {
		if on_segment(&point1, point, &point2) {
			return true
		}
		if (point2.y > point.y) != (point1.y > point.y) &&
				point.x < (point1.x - point2.x) * (point.y - point2.y) /
					(point1.y - point2.y) + point2.x
		{
			c = !c
		}
		point1 = point2
	}
	return c
}

// signed area of a triangle
fn area(p1 &Point, p2 &Point, p3 &Point) f64 {
	return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
}

fn fswap(v1 &f64, v2 &f64)  {
	unsafe {
		tmp_v1 := *v1
		*v1 = *v2
		*v2 = tmp_v1
	}
}

// https://e-maxx.ru/algo/segments_intersection_checking
fn intersect_1(a f64, b f64, c f64, d f64) bool {
	if a > b {
		fswap(&a, &b)
	}
	if c > d {
		fswap(&c, &d)
	}
	return math.max(a, c) <= math.min(b, d)
}

fn geom_tools_is_intersect_line(l1 &Line, l2 &Line) bool {
	p1 := l1.p1
	p2 := l1.p2
	p3 := l2.p1
	p4 := l2.p2
	return intersect_1(p1.x, p2.x, p3.x, p4.x) &&
		intersect_1(p1.y, p2.y, p3.y, p4.y) &&
		area(p1, p2, p3) * area(p1, p2, p4) <= 0 &&
		area(p3, p4, p1) * area(p3, p4, p2) <= 0
}

// Определение точки на линии, расстояние до которой от заданной точки является минимальным из существующих
fn geom_tools_nearest_point(point_start &Point, line &Line) Point {
	point_a := Point {
		x: line.p1.x,
		y: line.p1.y
	}

	point_b := Point {
		x: line.p2.x,
		y: line.p2.y
	}

	if geom_tools_length_side(&point_a, &point_b) < 1E-9 {
		return line.p1
	}
	a := point_start.x - point_a.x
	b := point_start.y - point_a.y
	c := point_b.x - point_a.x
	d := point_b.y - point_a.y
	dot := a * c + b * d
	len_sq := c * c + d * d
	mut param := -1.0
	if len_sq != 0 {
		param = dot / len_sq
	}
	mut xx := 0.0
	mut yy := 0.0

	if param < 0 {
		xx = point_a.x
		yy = point_a.y
	}
	else if param > 1 {
		xx = point_b.x
		yy = point_b.y
	}
	else {
		xx = point_a.x + param * c
		yy = point_a.y + param * d
	}
	mut point_end := Point { 0, 0 }
	point_end.x = xx
	point_end.y = yy
	return point_end
}
