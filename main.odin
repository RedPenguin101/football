package football

import "core:log"

BLUE :: 0
RED :: 1

other_team :: proc(team:int) -> int {
    if team == BLUE do return RED
    else do return BLUE
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

players_in_zone :: proc(ms:MatchState, team, zone:int) -> PlayerSet {
    ps : PlayerSet
    for player, i in ms.players[team] {
        if player.current_zone == zone {
            ps += {i}
        }
    }
    return ps
}

player_counts_in_zone :: proc(ms:MatchState, zone:int) -> (blue, red: int) {
    return card(players_in_zone(ms, BLUE, zone)), card(players_in_zone(ms, RED, zone))
}

random_player_from_zone :: proc(ms:MatchState, team, zone:int) -> int {
    candidates := players_in_zone(ms, team, zone)
    count := card(candidates)
    if count == 0 {
        log.errorf("call dn with 0")
    }
    roll := dn(count)
    nth := 0
    for i in 0..<11 {
        if i in candidates do nth += 1
        if nth == roll {
            return i
        }
    }
    panic("random player from zone fail")
}

zone_advantage :: proc(ms:MatchState, team, zone: int, team_weight:=1) -> int {
    blues := card(players_in_zone(ms, BLUE, zone))
    reds  := card(players_in_zone(ms, RED, zone))
    return team == BLUE ? (blues*team_weight)-reds : (reds*team_weight)-blues
}

zone_advantage_all :: proc(ms:MatchState, team:int, team_weight:=1) -> [ZONES]int {
    zs : [ZONES]int
    for i in 0..<ZONES {
        zs[i] = zone_advantage(ms, team, i, team_weight)
    }
    return zs
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

main :: proc() {
    context.logger = log.create_console_logger()
    context.logger.lowest_level = .Debug
    defer log.destroy_console_logger(context.logger)

    ms : MatchState
    ms.minute = 0
    ms.players[BLUE] = man_utd
    ms.players[RED] = liverpool
    ms.ball = Ball{2, BLUE, 3}

    for ms.minute < 90 {
        a, z := decide_action(ms)
        report := action_outcome(ms, a, z)
        log.info(comment(ms, report))
        tick_match_state(&ms, report)
    }
}
