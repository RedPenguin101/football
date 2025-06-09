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

lane :: proc(zone:int) -> int {
    return (zone+2) / 3
}

neighbour_zone :: proc(team, dir, zone: int) -> int {
    if team == BLUE {
        switch dir {
        case FORWARD:  return blue_forward_zone[zone]
        case BACKWARD: return blue_backward_zone[zone]
        case LEFT:     return blue_left_zone[zone]
        case RIGHT:    return blue_right_zone[zone]
        }
    } else if team == RED {
        switch dir {
        case FORWARD:  return blue_backward_zone[zone]
        case BACKWARD: return blue_forward_zone[zone]
        case LEFT:     return blue_right_zone[zone]
        case RIGHT:    return blue_left_zone[zone]
        }
    }
    panic("neighbour zone called for bad team")
}

target_zone :: proc(team, zone: int, action:ActionType) -> int {
    dir:int
    switch action {
    case .S: return 10 if team == BLUE else 0
    case .Z: return zone
    case .F: dir = FORWARD
    case .D: dir = FORWARD
    case .B: dir = BACKWARD
    case .L: dir = LEFT
    case .R: dir = RIGHT
    }
    return neighbour_zone(team,dir,zone)
}

natural_zone :: proc(team:int, pos:Position) -> int {
    if team == BLUE {
        switch pos {
        case .G:  return 0
        case .BL: return 1
        case .BC: return 2
        case .BR: return 3
        case .ML: return 4
        case .MC: return 5
        case .MR: return 6
        case .FC: return 8
        }
    } else {
        switch pos {
        case .G:  return 10
        case .BL: return 9
        case .BC: return 8
        case .BR: return 7
        case .ML: return 6
        case .MC: return 5
        case .MR: return 4
        case .FC: return 2
        }
    }
    panic("unreachable")
}
