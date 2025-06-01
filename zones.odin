package football

ZONES :: 11

zone_names :: [ZONES]string {
    "Blue Goal Box",
    "Blue Defence Left",
    "Blue Defence Center",
    "Blue Defence Right",
    "Midfield Left",
    "Midfield Center",
    "Midfield Right",
    "Red Defence Left",
    "Red Defence Center",
    "Red Defence Right",
    "Red Goal Box",
}

blue_forward_zone := [11]int{
  //0,1,2,3,4,5,6, 7, 8, 9,10
    2,4,5,6,7,8,9,-1,10,-1,-1
}

blue_backward_zone := [11]int{
  // 0, 1,2, 3,4,5,6,7,8,9,10
    -1,-1,0,-1,1,2,3,4,5,6,8
}

blue_left_zone := [11]int{
  // 0, 1,2,3, 4,5,6, 7,8,9,10
     1,-1,1,2,-1,4,5,-1,7,8,7
}

blue_right_zone := [11]int{
  // 0,1,2, 3,5,5, 6,7,8, 9,10
     3,2,3,-1,1,6,-1,8,9,-1, 9
}

FORWARD  :: 0
BACKWARD :: 1
LEFT     :: 2
RIGHT    :: 3

neighbour_zone :: proc(side, dir, zone: int) -> int {
    if side == BLUE {
        switch dir {
        case FORWARD:  return blue_forward_zone[zone]
        case BACKWARD: return blue_backward_zone[zone]
        case LEFT:     return blue_left_zone[zone]
        case RIGHT:    return blue_right_zone[zone]
        }
    } else if side == RED {
        switch dir {
        case FORWARD:  return blue_backward_zone[zone]
        case BACKWARD: return blue_forward_zone[zone]
        case LEFT:     return blue_right_zone[zone]
        case RIGHT:    return blue_left_zone[zone]
        }
    }
    panic("neighbour zone called for bad side")
}

neighbour_zones :: proc(side, zone: int) -> [4]int {
    return [4]int{
        neighbour_zone(side, FORWARD, zone),
        neighbour_zone(side, BACKWARD, zone),
        neighbour_zone(side, LEFT, zone),
        neighbour_zone(side, RIGHT, zone),
    }
}
