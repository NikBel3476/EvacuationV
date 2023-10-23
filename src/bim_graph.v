module main

struct BimGraph {
mut:
	head []BimNode
	node_count usize
}

struct BimNode {
	dest usize
	eid usize
	next &BimNode
}

struct BimEdge {
	src usize
	dest usize
	id usize
}

fn bim_graph_new(bim &Bim) BimGraph {
	mut edges := []BimEdge{len: bim.transits.len}

	graph_create_edges(bim.transits, mut edges, bim.zones)

	graph := graph_create(edges, usize(bim.transits.len), usize(bim.zones.len))
	return graph
}

fn graph_create(edges []BimEdge, edge_count usize, node_count usize) BimGraph {
	mut src := 0
	mut dest := 0
	mut eid := 0

	unsafe {
		// add edges to the directed graph one by one
		mut nodes := []BimNode{len: int(node_count)}

		graph := BimGraph {
			node_count: node_count
			head: nodes
		}

		for edge in edges {
			// get the source and destination vertex
			src = int(edge.src)
			dest = int(edge.dest)
			eid = int(edge.id)

			// 1. allocate a new node of adjacency list from `src` to `dest`
			src_to_dest := BimNode {
				dest: usize(dest)
				eid: usize(eid)
				next: &graph.head[src] // point new node to the current head
			}

			// point head pointer to the new node
			graph.head[src] = src_to_dest

			// 2. allocate a new node of adjacency list from `dest` to `src`
			dest_to_src := BimNode {
				dest: usize(src)
				eid: usize(eid)
				next: &graph.head[dest] // point new node to the current head
			}

			// change head pointer to point to the new node
			graph.head[dest] = dest_to_src
		}

		return graph
	}
}

fn graph_create_edges(transits []BimTransit, mut edges []BimEdge, zones []BimZone)
{
	for i, transit in transits {
		mut ids := [usize(0), usize(zones.len)]!

		mut j := 0
		for k, zone in zones {
			if arraylist_equal_callback(zone, transit) && j != 2 {
				ids[j] = usize(k)
				j++
			}
		}

		edges[i] = BimEdge {
			id: usize(i)
			src: ids[0]
			dest: ids[1]
		}
	}
}

fn arraylist_equal_callback(zone &BimZone, transit &BimTransit) bool {
	for output in zone.outputs {
		if output == transit.uuid {
			return true
		}
	}
	return false
}
