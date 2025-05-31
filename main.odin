package football

import "core:fmt"

Position :: enum {
    GK,
    CB, FBL, FBR,
    MC, ML, MR,
    S
}

Zone :: enum {
    TopGoalBox,
    TopLeft, TopCenter, TopRight,
    MiddleLeft, MiddleCenter, MiddleRight,
    BottomLeft, BottomCenter, BottomRight,
    BottomGoalBox,
}

blue_starting_zones := [Position]Zone {
        .GK = .BottomGoalBox,
        .CB = .BottomCenter,
        .FBL = .BottomLeft,
        .FBR = .BottomRight,
        .MC = .MiddleCenter,
        .ML = .MiddleLeft,
        .MR = .MiddleRight,
        .S = .MiddleCenter,
}

red_starting_zones := [Position]Zone {
        .GK = .TopGoalBox,
        .CB = .TopCenter,
        .FBL = .TopRight,
        .FBR = .TopLeft,
        .MC = .MiddleCenter,
        .ML = .MiddleRight,
        .MR = .MiddleLeft,
        .S = .MiddleCenter,
}

Player :: struct {
    name : string,
    position : Position,
    current_zone : Zone,
}

Team :: enum { Red, Blue }

MatchState :: struct {
    red_players : [11]Player,
    blue_players : [11]Player,
    team_with_ball : Team,
    player_with_ball : int,
    in_transition : bool,
    minute : int,
}

make_team :: proc(team:Team) -> [11]Player {
    players : [11]Player
    starting_zones := blue_starting_zones if team == .Blue else red_starting_zones
    players[0] = Player{"0",.GK, starting_zones[.GK]}
    players[1] = Player{"1",.CB, starting_zones[.CB]}
    players[2] = Player{"2",.CB, starting_zones[.CB]}
    players[3] = Player{"3",.FBL, starting_zones[.FBL]}
    players[4] = Player{"4",.FBR, starting_zones[.FBR]}
    players[5] = Player{"5",.MC, starting_zones[.MC]}
    players[6] = Player{"6",.MC, starting_zones[.MC]}
    players[7] = Player{"7",.ML, starting_zones[.ML]}
    players[8] = Player{"8",.MR, starting_zones[.MR]}
    players[9] = Player{"9",.S, starting_zones[.S]}
    players[10] = Player{"10",.S, starting_zones[.S]}
    return players
}

make_match :: proc(starting_team:Team) -> MatchState {
    return MatchState {
        red_players = make_team(.Red),
        blue_players = make_team(.Blue),
        team_with_ball = starting_team,
        player_with_ball = 10,
        in_transition = false,
        minute = 0,
    }
}

main :: proc() {
    make_match(.Blue)
    fmt.println("Hello world")
}
