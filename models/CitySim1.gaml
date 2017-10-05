/**
 *  AMSMOVE
 *  Author: ligte002
 *  Description: 
 */


/**
 *  Description: simulation pedestrian movement Amsterdam
 *  Keuze via geschiktheid van weg
 */
 
model CitySim1
 
 
global {   
	file shape_file_roads  <- file("../includes/OSMnetwerk-centrum-small.shp") ;
	file shape_file_airbnb <- file("../includes/airbnbapril2017-centrum-small.shp") ;
	file shape_file_attractions <- file("../includes/attracties-centrum-small.shp") ;
	geometry shape <- envelope(shape_file_roads);
	graph the_graph; 
	map<road,float> weights_map; 	
	init {  
		write "model started"; 	
		create road from: shape_file_roads with:[Oid::int(read("osm_id"))]{
			//linked_road <- myself;
			//myself.linked_road <- self;
		} 
		create airbnb from:	shape_file_airbnb with:[Oid::int(read("id"))]{}
		create attraction from: shape_file_attractions with:[Oid::string(read("Trcid"))]{}
		weights_map <- road as_map (each:: (1 * each.shape.perimeter));
		the_graph <-  (as_edge_graph(road)) with_weights weights_map; 					
	}
	
}
 

species road skills: [skill_road] {
	int Oid;	
	init{
		//nothing to do
	}
	aspect base {
		draw shape color: rgb("black");		
	}
		
}
	
	
species attraction{
	string Oid;

	aspect base {
		draw geometry:circle(5) color: rgb("red");		
	}	

}	
	
species airbnb {
 		int Oid;
 		bool releasedWalker <- false;
 		point loc <- location;

	init{
		
		//nothing to do
	}
	
	reflex createWalker when: releasedWalker = false{		
		
			if flip(0.01){
				create walker number: 1{
					// bit difficult construction, have a look at difference between myself and self. 
					location <- myself.loc;
					startLocation <- location;
				}
				releasedWalker <- true;				
		}
		
	}
	
	aspect base {
		draw shape color: rgb("green");		
	}
 		
}

species walker skills: [advanced_driving]{
    //startlocation
    point startLocation;
    //Target point of the agent
    point targetLocation;
   
    //Probability of leaving 
    float leaving_proba <- 0.5; 
    
    //has Left Start Location
    bool hasLeftStartLocation <- false;
   
   //arrived at destination
   bool arrivedAtDestination <- false;
   
    //Speed of the agent (bit fast though)
    float speed <- 10.0 #km/#h;
    rgb color <- rnd_color(255);
    
    
    //Reflex to leave the building to another building
    reflex leave when: (targetLocation = nil) and (flip(leaving_proba)) {
        targetLocation <- any_location_in(one_of(attraction));
        hasLeftStartLocation <- true;
    }
   
    //Reflex to move to the target 
    reflex move when: hasLeftStartLocation = true {
        if (location = targetLocation) {
            targetLocation <- startLocation;
            arrivedAtDestination <- true;
            write name+": arrived at destination; going back";
        }
        if (location = startLocation) and arrivedAtDestination {     
           write name+": arrived back in hotel";
            do die;
        }              
        //below does not work, need to study why
        //current_path <- compute_path( graph: the_graph, target: targetLocation);
        //do drive;
        
        //this does the trick
        do goto target: targetLocation on: the_graph recompute_path: false move_weights: weights_map;
    
    }

	

	
	aspect base {
		draw geometry:circle(4) color: rgb(color);		
	}	
	
	
}	

experiment AMS_pedestrian_movement type: gui {
	output {
		
								
		display ams_display  { 
			
			species road aspect: base;
			species airbnb aspect: base;	
			species attraction aspect:base;		
			species walker aspect: base;	
		} 
	}

} 	 


	




