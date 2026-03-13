extends Node

const foo := 100
# Movement parameters
# 16 HU = 1 ft
# 1 ft = 0.3048 m
# x_m = x_hu / 16 * 0.3048 = x_hu * 0.01905
## Factor to convert Hammer units to meters
const HU_TO_M := 0.01905
