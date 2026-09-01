::trimp_spot_info <- {

}

::trimp_forward_info <- {


    forward_z = forward_guide( Vector(75.794540, 845.174988, -0.621687), Vector(0.872303, -0.488965, -0.000000) )
    forward_y = forward_guide( Vector(-536.843262, 955.559937, 16.513712), Vector(0.050594, -0.998719, -0.000000) )
    forward_x = forward_guide( Vector(-454.441040, 187.023987, 28.541477), Vector(0.252139, -0.967691, -0.000000) )
	forward_0 = forward_guide( Vector(227.781189, -432.703644, -108.644012), Vector(0.999267, -0.038283, -0.000000) )

    forward_z = forward_guide( Vector(122.851486, 1266.746704, 72.935013), Vector(-0.976492, -0.215553, -0.000000) )
    forward_y = forward_guide( Vector(-774.432251, 677.489563, -75.048599), Vector(-0.413453, -0.910525, -0.000000) )
    forward_x = forward_guide( Vector(-770.636841, -271.813751, -32.913639), Vector(0.999276, 0.038058, -0.000000) )
	forward_extra_go_round = forward_guide( Vector(31.310425, 409.746704, 79.478226), Vector(-0.956544, -0.291589, -0.000000) )

    // go around to burn height
    forward_a = forward_guide( Vector(-75.619713, 1289.325317, 31.108759), Vector(-0.664670, 0.747137, -0.000000) )
    forward_b = forward_guide( Vector(-745.374268, 1240.115356, 165.614120), Vector(0.520490, -0.853868, -0.000000) )

    forward_c = forward_guide( Vector(-840.785950, 707.885254, 318.069153), Vector(0.999918, 0.012777, -0.000000) )
	forward_d = forward_guide( Vector(193.087952, 535, 160.562332), Vector(-0.758770, -0.651359, -0.000000) )

    forward_e = forward_guide( Vector(200.480026, 240, 203.753769), Vector(-0.978893, 0.204373, -0.000000) )
	forward_f = forward_guide( Vector(-980.323425, 78, 176.412567), Vector(0.221260, -0.975215, -0.000000))

	forward_g = forward_guide( Vector(-836.423828, -722.036194, 15.643457), Vector(0.980236, 0.197830, -0.000000) )
	forward_0 = forward_guide( Vector(227.781189, -432.703644, -108.644012), Vector(0.999267, -0.038283, -0.000000) )

    // from tank tunnel
    forward_a = forward_guide( Vector(-689.898071, 1366.531616, -291.677429), Vector(-0.837012, 0.547184, -0.000000) )
    forward_b = forward_guide( Vector(-850.330750, 225.754669, -88.551651), Vector(0.835788, -0.549052, -0.000000) )

    // pipe jump not cannon at spawnbot
    forward_a = forward_guide( Vector(-553.028992, 866.877258, 91.201195), Vector(0.997543, -0.070053, -0.000000) )
    forward_b = forward_guide( Vector(-737.950989, 299.983124, 171.243988), Vector(0.997965, -0.063761, -0.000000) )
    forward_0 = forward_guide( Vector(330.718658, -421.866028, -63.103188), Vector(0.997122, -0.075810, -0.000000) )

    forward_stairs_1 = forward_guide( Vector(1263.529175, -182.251541, 77.913597), Vector(0.741602, -0.670840, -0.000000) )
    forward_stairs_2 = forward_guide( Vector(1918.442627, -674.961609, 16.062702), Vector(0.076075, -0.997102, -0.000000) )
    forward_stairs_3 = forward_guide( Vector(1918.442627, -1009.961609, 16.062702), Vector(0.076075, -0.997102, -0.000000) )
    //forward_stairs_3 = forward_guide( Vector(1900, -1250, 367.200043), Vector(0.535754, -0.844374, -0.000000) )
    forward_stairs_4 = forward_guide( Vector(2951.445557, -1466.913208, 290.042053), Vector(0.911764, 0.410714, -0.000000) )


    //
	forward_0 = forward_guide( Vector(330.718658, -472.866028, -63.103188), Vector(0.997122, -0.075810, -0.000000) )
	forward_1 = forward_guide( Vector(1765.912476, -324.092468, 30.526009), Vector(0.900060, 0.435766, -0.000000) )
	forward_2 = forward_guide( Vector(2607.734619, 147.170135, 122.707298), Vector(0.948650, -0.316328, -0.000000) )
	forward_3 = forward_guide( Vector(3421.743164, -243.645081, 106.438614), Vector(-0.133536, -0.991044, -0.000000) )
	forward_4 = forward_guide( Vector(3730.107422, -1008.743896, 89.558723), Vector(-0.789941, -0.613183, -0.000000) )

	path_hill_with_cars	= []
	path_partial_hill_then_stairs = []
	path_hill_with_cars_backup	= []

	function parse()
	{
		path_hill_with_cars = [forward_a, forward_b, forward_0, forward_1, forward_2, forward_3, forward_4]
		path_partial_hill_then_stairs = [forward_a, forward_b, forward_0, forward_stairs_1, forward_stairs_2, forward_stairs_3, forward_stairs_4, forward_4]
		path_hill_with_cars_backup = [forward_a, forward_b, forward_c, forward_d, forward_e, forward_f, forward_g, forward_0, forward_1, forward_2, forward_3, forward_4]
	    //forward_0.max_height = -68
	    //forward_0.use_cannon = true

		//trimp_forward_info.cached_distances = {}

        //local total_nodes = path_hill_with_cars.len()
		//local total_distance = 0
	    //local distances = [0]
        //for ( local i = 0; i < total_nodes - 1; i++ )
        //{
        //    total_distance += (path[result_i] - path[result_i+1]).length()
        //    distances.append(total_distance)
        //}
        //cached_distances[path_hill_with_cars] <- distances
	}
}
trimp_forward_info.parse()

::showguide <- function( num )
{
	me().SetAbsOrigin( trimp_forward_info.path_partial_hill_then_stairs[num].where )
	me().SnapEyeAngles( VectorAngles(trimp_forward_info.path_partial_hill_then_stairs[num].dir) )
}

//bind q +jumpcharge;rcon script me().SnapEyeAngles(QAngle(0,-110,0));impulse 101
//rcon script prodemoknight.ListOfProDemoknight[0].interface_trimpAtTarget( me() , "tworocks ")
