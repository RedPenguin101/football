package football

import "core:log"
import "core:mem"
import "core:fmt"

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
    assert(zone >= 0)
    for player, i in ms.players[team] {
        if player.current_zone == zone {
            ps += {i}
        }
    }
    return ps
}

random_player_from_set :: proc(ps:PlayerSet) -> int {
    count := card(ps)
    if count == 0 {
        log.panic("tried to select player from empty set")
    }
    roll := dn(count)
    idx := 0
    for i in 0..<11 {
        if i in ps do idx += 1
        if idx == roll do return i
    }
    panic("Failed to pick random player")
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

GoalRecord :: struct {
    team:int,
    player:int,
    minute:f32,
}

MatchState :: struct {
    players: [2][11]Player,
    ball : Ball,
    minute : f32,
    red_goals: int,
    blue_goals: int,
    goal_records: [dynamic]GoalRecord,
}

distance_from_goal :: proc(team, zone: int) -> int {
    distance:int

    if team == BLUE {
        if zone == 10 do distance = 0
        else if zone == 8 do distance = 1
        else if zone > 6 do distance = 2
        else if zone > 3 do distance = 3
        else if zone > 0 do distance = 4
        else do distance = 5
    } else {
        if zone == 0 do distance = 0
        else if zone == 2 do distance = 1
        else if zone < 4 do distance = 2
        else if zone < 7 do distance = 3
        else if zone < 10 do distance = 4
        else do distance = 5
    }

    return distance
}

main :: proc() {
    context.logger = log.create_console_logger()
    context.logger.lowest_level = .Info
    defer log.destroy_console_logger(context.logger)
    when ODIN_DEBUG {
        context.logger.lowest_level = .Debug
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                for _, entry in track.allocation_map {
                    fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
                }
            }
            if len(track.bad_free_array) > 0 {
                for entry in track.bad_free_array {
                    fmt.eprintf("%v bad free at %v\n", entry.location, entry.memory)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

    PRINT_REPORTS :: true
    ms : MatchState
    ms.minute = 0
    ms.players[BLUE] = man_utd
    ms.players[RED] = liverpool
    ms.ball = Ball{2, BLUE, 3}

    for ms.minute < 90 {
        a, z := decide_action(ms)
        report := action_outcome(ms, a, z)
        if PRINT_REPORTS {
            cm := comment(ms, report)
            fmt.println(cm)
            delete(cm)
        }
        tick_match_state(&ms, report)
    }

    fmt.println("FULL TIME: Match Score: ManUtd", ms.blue_goals, "Liverpool", ms.red_goals)
    for gr in ms.goal_records {
        fmt.println(gr.minute, ":", ms.players[gr.team][gr.player].name)
    }

    delete(ms.goal_records)
}
