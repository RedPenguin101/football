package football

import "core:fmt"

ZONES :: 11
BLUE :: 0
RED :: 1

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

Position :: enum {
    G,
    BC, BL, BR,
    MC, ML, MR,
    FC,
}

Player :: struct {
    name : string,
    position : Position,
    current_zone : int,
}

PlayerSet :: bit_set[0..<11]

players_in_zone :: proc(ms:MatchState, side, zone:int) -> PlayerSet {
    ps : PlayerSet
    for player, i in ms.players[side] {
        if player.current_zone == zone {
            ps += {i}
        }
    }
    return ps
}

man_utd := [11]Player{
    Player{"Schmeichel", .G, 0},
    Player{"Irwin", .BL, 1},
    Player{"Johnsen", .BC, 2},
    Player{"Stam", .BC, 2},
    Player{"Neville", .BR, 3},
    Player{"Giggs", .ML, 4},
    Player{"Keane", .MC, 5},
    Player{"Scholes", .MC, 5},
    Player{"Beckham", .MR, 6},
    Player{"Cole", .FC, 8},
    Player{"Yorke", .FC, 8},
}

liverpool := [11]Player{
    Player{"James", .G, 10},
    Player{"Bjornebye", .BL, 9},
    Player{"Babb", .BC, 8},
    Player{"Carragher", .BC, 8},
    Player{"Jones", .BR, 7},
    Player{"McManaman", .MR, 6},
    Player{"Redknapp", .MC, 5},
    Player{"Ince", .MC, 5},
    Player{"Berger", .ML, 4},
    Player{"Fowler", .FC, 2},
    Player{"Owen", .FC, 2},
}

Team :: enum { Red, Blue }

Ball :: struct {
    zone : int,
    team : int,
    player : int,
}

MatchState :: struct {
    players: [2][11]Player,
    ball : Ball,
    minute : f32,
    red_goals: int,
    blue_goals: int,
}



print_match_state :: proc(ms:MatchState) {
    fmt.println("Match State: minute is", ms.minute, "ball is in zone", ms.ball.zone,
                "with player", ms.players[ms.ball.team][ms.ball.player].name)
    for z, i in zone_names {
        fmt.println(z)
        blues := players_in_zone(ms, BLUE, i)
        for i in 0..<11 {
            if i in blues do fmt.println(" BLUE:", ms.players[BLUE][i].name)
        }
        reds :=  players_in_zone(ms, RED, i)
        for i in 0..<11 {
            if i in reds do fmt.println(" RED:", ms.players[RED][i].name)
        }
    }
}

main :: proc() {
    ms : MatchState
    ms.players[BLUE] = man_utd
    ms.players[RED] = liverpool
    ms.ball = Ball{2, BLUE, 3}
    print_match_state(ms)
}
