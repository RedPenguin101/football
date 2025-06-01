package football

import "core:fmt"

Action :: enum {B,Z,L,R,F,D,S}

action_names := [Action]string {
        .B = "Pass backward",
        .Z = "Pass within Zone",
        .L = "Pass left",
        .R = "Pass right",
        .F = "Pass forward",
        .D = "Dribble forward",
        .S = "Shoot",
}

target_zones :: proc(side, zone:int) -> [Action]int {
    return {
            .Z = zone,
            .F = neighbour_zone(side, FORWARD, zone),
            .D = neighbour_zone(side, FORWARD, zone),
            .B = neighbour_zone(side, BACKWARD, zone),
            .L = neighbour_zone(side, LEFT, zone),
            .R = neighbour_zone(side, RIGHT, zone),
            .S = 0 if side == RED else 10
    }
}

ActionScore :: [Action]int

action_scores :: proc(side, zone: int) -> ActionScore {
    if side == BLUE {
        switch zone {
        case 2:
            return ActionScore{.Z=2, .L=3, .R=3,
                               .F=5, .B=1, .D=4, .S=1}
        }
    }
    panic("Unrecognized side/zone combo when determining action score")
}

decide_action :: proc(ms:MatchState) -> (action:Action, t_zone:int) {
    side := ms.ball.team
    zone := ms.ball.zone
    /* fmt.println("Deciding action for", ms.ball) */
    as := action_scores(side, zone)
    tz := target_zones(side, zone)
    zone_scores := zone_advantage_all(ms, side)
    for action in Action {
        t_zone := tz[action]
        if t_zone >= 0 {
            player_advantage := zone_scores[t_zone]
            as[action] += player_advantage
        } else {
            as[action] = 0
        }
    }
    /* fmt.println("Post modification action scores", as) */
    chosen := action_roll(as)
    fmt.println("Chosen action:", action_names[chosen], "zone", tz[chosen])
    return chosen, tz[chosen]
}

ActionReport :: struct {
    success : bool,
    side : int,
    player : int,
    from_zone : int,
    action : Action,
    to_zone : int,

    execution_score : int,

    outcome_dice_size : int,
    outcome_win_score : int,
    outcome_roll : int,
}

print_action_report :: proc(ms:MatchState, ar:ActionReport) {
    fmt.printfln("%s tried to %s", ms.players[ar.side][ar.player].name,
                 action_names[ar.action])
    fmt.println("  outcome", "Success" if ar.success else "Failed")
    fmt.println("  ex_score:", ar.execution_score)
    fmt.println("  outcome roll:", ar.outcome_roll, "on a", ar.outcome_dice_size, "die with", ar.outcome_win_score, "win score")
}

action_outcome :: proc(ms:MatchState, a:Action, zone:int) -> ActionReport {
    ar : ActionReport
    ar.action = a
    ar.side = ms.ball.team
    ar.player = ms.ball.player
    ar.from_zone = ms.ball.zone
    ar.to_zone = zone

    execution_score := d20()
    ar.execution_score = execution_score
    fmt.println("Execution score", execution_score)
    if execution_score == 1 {
        ar.success = false
        return ar
    }
    if execution_score == 20 {
        ar.success = true
        return ar
    }

    miskick := execution_score <= 4

    blues, reds := player_counts_in_zone(ms, zone)

    fmt.println("in target zone:", blues, "blues", reds, "reds")

    side := ms.ball.team

    if !miskick {
        if side == BLUE {
            blues *= 2
        } else {
            reds *= 2
        }
    }

    roll := dn(blues+reds)
    win_score := 1 + (side == BLUE ? reds : blues)
    fmt.println("Rolled", roll, "on", blues+reds, "sided dice.", "win score", win_score)

    ar.outcome_dice_size = blues + reds
    ar.outcome_win_score = win_score
    ar.outcome_roll = roll

    ar.success = roll >= win_score

    return ar
}
