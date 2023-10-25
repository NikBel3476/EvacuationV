[translated]
module main

enum DistributionType {
	from_bim
	uniform
}

enum TransitsWidthType {
	from_bim
	users
}

struct DistributionSpecial {
	uuid         []string
	density        f32
	_comment string
}

struct TransitionSpecial {
	uuid         []string
	width        f32
	_comment string
}

struct BimCfgDistribution {
	@type                 string
	density               f32
	special               []DistributionSpecial
}

struct BimCfgTransitionsWidth {
	@type                 string
	doorwayin             f32
	doorwayout            f32
	special               []TransitionSpecial
}

struct BimCfgModeling {
	step        f32
	speed_max   f32
	density_min f32
	density_max f32
}

struct BimCfgScenario {
	bim []string
	logger_configure string
	distribution     BimCfgDistribution
	transits         BimCfgTransitionsWidth
	modeling         BimCfgModeling
}
