package football

import "core:log"
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

passes := bit_set[Action]{.B,.L,.R,.F}

target_zones :: proc(team, zone:int) -> [Action]int {
    return {
            .Z = zone,
            .F = neighbour_zone(team, FORWARD, zone),
            .D = neighbour_zone(team, FORWARD, zone),
            .B = neighbour_zone(team, BACKWARD, zone),
            .L = neighbour_zone(team, LEFT, zone),
            .R = neighbour_zone(team, RIGHT, zone),
            .S = 0 if team == RED else 10
    }
}

ActionScore :: [Action]int

action_scores :: proc(team, zone: int) -> ActionScore {
    if team == BLUE {
        switch zone {
        case 0:
            return ActionScore{.Z=0, .L=3, .R=3,
                               .F=3, .B=0, .D=1, .S=0}
        case 1:
            return ActionScore{.Z=1, .L=0, .R=3,
                               .F=5, .B=2, .D=4, .S=1}
        case 2:
            return ActionScore{.Z=2, .L=3, .R=3,
                               .F=5, .B=1, .D=4, .S=1}
        case 3:
            return ActionScore{.Z=1, .L=3, .R=0,
                               .F=5, .B=2, .D=4, .S=1}
        case 4:
            return ActionScore{.Z=1, .L=0, .R=3,
                               .F=3, .B=1, .D=4, .S=1}
        case 5:
            return ActionScore{.Z=3, .L=3, .R=3,
                               .F=4, .B=2, .D=5, .S=2}
        case 6:
            return ActionScore{.Z=1, .L=3, .R=0,
                               .F=3, .B=1, .D=4, .S=1}
        case 7:
            return ActionScore{.Z=2, .L=0, .R=4,
                               .F=0, .B=1, .D=0, .S=1}
        case 8:
            return ActionScore{.Z=1, .L=1, .R=1,
                               .F=3, .B=1, .D=4, .S=3}
        case 9:
            return ActionScore{.Z=2, .L=4, .R=0,
                               .F=0, .B=1, .D=0, .S=1}
        case 10:
            return ActionScore{.Z=0, .L=0, .R=0,
                               .F=0, .B=1, .D=0, .S=5}
        }
    } else {
        switch zone {
        case 10:
            return ActionScore{.Z=0, .L=3, .R=3,
                               .F=3, .B=0, .D=1, .S=0}
        case 9:
            return ActionScore{.Z=1, .L=0, .R=3,
                               .F=5, .B=2, .D=4, .S=1}
        case 8:
            return ActionScore{.Z=2, .L=3, .R=3,
                               .F=5, .B=1, .D=4, .S=1}
        case 7:
            return ActionScore{.Z=1, .L=3, .R=0,
                               .F=5, .B=2, .D=4, .S=1}
        case 6:
            return ActionScore{.Z=1, .L=0, .R=3,
                               .F=3, .B=1, .D=4, .S=1}
        case 5:
            return ActionScore{.Z=3, .L=3, .R=3,
                               .F=4, .B=2, .D=5, .S=2}
        case 4:
            return ActionScore{.Z=1, .L=3, .R=0,
                               .F=3, .B=1, .D=4, .S=1}
        case 3:
            return ActionScore{.Z=2, .L=0, .R=4,
                               .F=0, .B=1, .D=0, .S=1}
        case 2:
            return ActionScore{.Z=1, .L=1, .R=1,
                               .F=3, .B=1, .D=3, .S=4}
        }
    }
    log.panicf("DEBUG: Unrecognized team/zone combo, %d, %d", team, zone)
}

decide_action :: proc(ms:MatchState) -> (action:Action, t_zone:int) {
    team := ms.ball.team
    zone := ms.ball.zone
    as := action_scores(team, zone)
    tz := target_zones(team, zone)
    zone_scores := zone_advantage_all(ms, team)
    for ac in Action {
        t_zone := tz[ac]
        if t_zone < 0 {
            as[action] = 0
        } else
        {
            blues, reds := player_counts_in_zone(ms, t_zone)
            my_teammates := ms.ball.team == BLUE ? blues : reds
            opp_teammates := ms.ball.team == BLUE ? reds : blues

            if (my_teammates == 0 && ac in passes) {
                // if it's a pass, and there are no teammates there,
                // don't pass it!
                as[ac] = 0
            } else {
                player_advantage := my_teammates - opp_teammates
                if ms.ball.team == RED do player_advantage *= -1
                as[ac] += player_advantage
            }
        }
    }
    chosen := action_roll(as)
    return chosen, tz[chosen]
}

ActionReport :: struct {
    success : bool,
    team : int,
    player : int,
    from_zone : int,
    action : Action,
    to_zone : int,

    execution_score : int,

    outcome_dice_size : int,
    outcome_win_score : int,
    outcome_roll : int,

    new_team : int,
    new_player : int
}

action_outcome :: proc(ms:MatchState, a:Action, zone:int) -> ActionReport {
    ar : ActionReport
    ar.action = a
    ar.team = ms.ball.team
    ar.player = ms.ball.player
    ar.from_zone = ms.ball.zone
    ar.to_zone = zone

    // An execution score is obtained by rolling a d20.
    // 1 and 20 are critical successes and failures respectively.

    execution_score := d20()
    ar.execution_score = execution_score
    if execution_score == 1 do ar.success = false
    if execution_score == 20 do ar.success = true
    else {
        // Otherwise we have to actually calculate the outcomes.

        // The outcome is affected by your relative strength in the
        // target zone. A decent execution will improve your chances
        // of completing the action by multiplying the 'weighting' of
        // your own team's presence in the zone.

        miskick := execution_score <= 4

        blues, reds := player_counts_in_zone(ms, zone)

        if !miskick {
            if ar.team == BLUE {
                blues *= 2
            } else {
                reds *= 2
            }
        }

        if blues+reds == 0 {
            if a != .D {
                log.error("target zone has no people in it, but trying to pass into it!")
            }
            // if we're dribbling into an empty area, just win
            // TODO: dribbing should also factor in the presence in the CURRENT
            // zone when calculating
            ar.success = true
        } else {
            roll := dn(blues+reds)
            win_score := 1 + (ar.team == BLUE ? reds : blues)
            ar.outcome_dice_size = blues + reds
            ar.outcome_win_score = win_score
            ar.outcome_roll = roll
            ar.success = roll >= win_score
        }
    }


    if ar.success {
        ar.new_team = ar.team
        log.debugf("getting random player from team %d zone %d", ar.team, ar.to_zone)
        ar.new_player = ar.action == .D ? ar.player : random_player_from_zone(ms, ar.team, ar.to_zone)
    }
    else {
        ar.new_team = other_team(ar.team)
        log.debugf("getting random player from team %d zone %d", ar.team, ar.to_zone)
        ar.new_player = random_player_from_zone(ms, ar.new_team, ar.to_zone)
    }

    return ar
}

tick_match_state :: proc(ms:^MatchState, ar:ActionReport) {
    ms.ball.team = ar.new_team
    ms.ball.player = ar.new_player
    ms.ball.zone = ar.to_zone

    if ar.action == .D do ms.players[ar.team][ar.player].current_zone = ar.to_zone

    ms.minute += 1
}
