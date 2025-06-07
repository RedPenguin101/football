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

passes := bit_set[Action]{.B,.L,.R,.F,.Z}

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

decide_action :: proc(ms:MatchState) -> (action:Action, t_zone:int) {
    my_team := ms.ball.team
    me := ms.ball.player
    current_zone := ms.ball.zone

    // Given each potential action, which zone will a successful execution of that
    // action end up in?
    target_zones := target_zones(my_team, current_zone)

    // for each zone, what is the relative advantage my team has in the zone?
    action_scores : [Action]int

    for a in Action {
        target_zone := target_zones[a]
        if target_zone == -1 do continue
        target_players := card(players_in_zone(ms, my_team, target_zone))
        if a == .Z do target_players -= 1
        if a == .D && me == 0 {
            // goalkeepers don't dribble
            action_scores[a] = 0
        } else if a in passes && target_players == 0 {
            action_scores[a] = 0
        } else {
            opp_players_in_zone := card(players_in_zone(ms, other_team(my_team), target_zone))
            action_scores[a] = target_players - opp_players_in_zone + 4
        }
    }

    chosen_action := action_roll(action_scores)
    return chosen_action, target_zones[chosen_action]
}

ActionReport :: struct {
    start_team : int,
    start_player : int,
    start_zone : int,

    action : Action,
    target_zone : int,
    success : bool,

    end_team : int,
    end_player : int,
    end_zone : int,
}

action_outcome_dribble :: proc(ms:MatchState, a:Action, zone:int) -> ActionReport {
    ar : ActionReport
    ar.start_team = ms.ball.team
    ar.start_player = ms.ball.player
    ar.start_zone = ms.ball.zone

    ar.target_zone = zone
    ar.action = a

    execution_score := d20()

    my_team := ms.ball.team
    opp_team := other_team(my_team)

    my_in_current_zone  := players_in_zone(ms, my_team, ar.start_zone)
    opp_in_current_zone := players_in_zone(ms, opp_team, ar.start_zone)

    // The player first needs to get out of the current zone
    // if there are no opp players in the current zone the player gets out of the zone.
    // if the player rolls a crit on the play, they get out of the zone regardless of opp players.
    if card(opp_in_current_zone) > 0 && execution_score < 20 {
        advantage := card(my_in_current_zone) - card(opp_in_current_zone)
        roll := d20()
        win  := 10 - 3*advantage
        if roll <= win {
            ar.success = false
            ar.end_team = opp_team
            ar.end_zone = ar.start_zone
            ar.end_player = random_player_from_set(opp_in_current_zone)
            return ar
        }
    }

    // repeat the process for the target zone
    my_in_target_zone  := players_in_zone(ms, my_team, zone)
    opp_in_target_zone := players_in_zone(ms, opp_team, zone)

    if card(opp_in_target_zone) == 0 || execution_score == 20 {
        ar.success = true
        ar.end_team = ar.start_team
        ar.end_zone = zone
        ar.end_player = ar.start_player
        return ar
    }

    ar.end_zone = zone

    advantage := card(my_in_target_zone) + 1 - card(opp_in_target_zone)
    roll := d20()
    win := 10 - 3*advantage
    if roll <= win {
        ar.success = false
        ar.end_team = opp_team
        ar.end_player = random_player_from_set(opp_in_target_zone)
    } else {
        ar.success = true
        ar.end_team = ar.start_team
        ar.end_player = ar.start_player
    }

    return ar
}

action_outcome_shot :: proc(ms:MatchState, a:Action, zone:int) -> ActionReport {
    assert(zone == 0 || zone == 10)

    ar : ActionReport
    ar.start_team = ms.ball.team
    ar.start_player = ms.ball.player
    ar.start_zone = ms.ball.zone

    ar.target_zone = zone
    ar.action = a

    my_team := ms.ball.team
    opp_team := other_team(my_team)

    // whether success or failure the ball always ends up with the keeper because we don't
    // do kickoffs yet
    ar.end_team = opp_team
    ar.end_player = 0
    ar.end_zone = zone

    // shot success chance is affected by distance to the goal
    distance:int

    if my_team == BLUE {
        if ar.start_zone == 10 do distance = 0
        else if ar.start_zone == 8 do distance = 1
        else if ar.start_zone > 6 do distance = 2
        else if ar.start_zone > 3 do distance = 3
        else do distance = 4
    } else {
        if ar.start_zone == 0 do distance = 0
        else if ar.start_zone == 2 do distance = 1
        else if ar.start_zone < 4 do distance = 2
        else if ar.start_zone < 7 do distance = 3
        else do distance = 4
    }

    // If the opponent has equal or more players than us in the zone we shoot
    // from, we are assumed to be under pressure and therefore at a disadvantage

    my_in_current_zone  := players_in_zone(ms, my_team, ar.start_zone)
    opp_in_current_zone := players_in_zone(ms, opp_team, ar.start_zone)
    pressure_modifier := card(opp_in_current_zone) - card(my_in_current_zone)
    pressure_modifier = max(pressure_modifier, 0)

    // There is also a modifier for players in the target zone - that is a chance for the
    // shot to be be blocked or stopped
    my_in_target_zone  := players_in_zone(ms, my_team, zone)
    opp_in_target_zone := players_in_zone(ms, opp_team, zone)
    congestion := card(opp_in_current_zone) - card(my_in_current_zone)

    roll := d20()
    win := 10 + distance + pressure_modifier + congestion
    ar.success = roll >= win

    return ar
}


action_outcome_pass :: proc(ms:MatchState, a:Action, zone:int) -> ActionReport {
    ar : ActionReport
    ar.start_team = ms.ball.team
    ar.start_player = ms.ball.player
    ar.start_zone = ms.ball.zone

    ar.target_zone = zone
    ar.action = a

    my_team := ms.ball.team
    opp_team := other_team(my_team)
    my_in_target_zone  := players_in_zone(ms, my_team, zone)
    opp_in_target_zone := players_in_zone(ms, opp_team, zone)

    // remove yourself as a target if the pass is within the zone.
    if a == .Z {
        my_in_target_zone = my_in_target_zone - PlayerSet{ar.start_player}
    }

    assert(card(my_in_target_zone) > 0)

    // TODO: Actually implement some checks here
    ar.success = true
    ar.end_team = ar.start_team
    ar.end_zone = zone
    ar.end_player = random_player_from_set(my_in_target_zone)

    return ar
}


action_outcome :: proc(ms:MatchState, a:Action, zone:int) -> ActionReport {
    assert(zone >= 0)
    assert(zone <= 10)

    if a == .D do return action_outcome_dribble(ms,a,zone)
    if a == .S do return action_outcome_shot(ms,a,zone)
    else do return action_outcome_pass(ms,a,zone)
}

tick_match_state :: proc(ms:^MatchState, ar:ActionReport) {
    ms.ball.team = ar.end_team
    ms.ball.player = ar.end_player
    ms.ball.zone = ar.end_zone

    if ar.action == .D do ms.players[ar.start_team][ar.start_player].current_zone = ar.end_zone

    if ar.action == .S && ar.success {
        if ar.start_team == BLUE do ms.blue_goals += 1
        else do ms.red_goals += 1
    }

    ms.minute += 1
}
