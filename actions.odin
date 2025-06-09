package football

import "core:log"
import "core:fmt"

ActionType :: enum {B,Z,L,R,F,D,S}

Action :: struct {
    type : ActionType,
    zone :int,
}

passes := bit_set[ActionType]{.B,.L,.R,.F,.Z}

shot_likelihood :: proc(ms:MatchState) -> int {
    my_team := ms.ball.team
    current_zone := ms.ball.zone
    opp_team := other_team(my_team)
    target_zone := my_team == BLUE ? 10 : 0
    distance := distance_from_goal(my_team, current_zone)

    // base chance is a function of distance. A distance of 0 means the player with the ball
    // is in the opponents penalty area, a distance of 5 means they're in their own area.
    base_chance := 5 - distance

    // If the opposing goal keeper isn't in the goal zone it significantly increases the likelihood
    if ms.players[opp_team][0].current_zone != target_zone do base_chance += 3

    return base_chance
}

pass_likelihood :: proc(ms:MatchState, pass_type:ActionType) -> int {
    assert(pass_type in passes)

    my_team := ms.ball.team
    current_zone := ms.ball.zone
    opp_team := other_team(my_team)
    target := target_zone(my_team, current_zone, pass_type)
    if target == -1 do return 0

    target_players := card(players_in_zone(ms, my_team, target))
    if pass_type == .Z do target_players-=1

    // don't try and pass if there's noone to pass to
    if target_players == 0 do return 0

    base_chance:int

    switch pass_type {
    case .B: base_chance=2
    case .Z: base_chance=2
    case .L: base_chance=3
    case .R: base_chance=3
    case .F: base_chance=4
    case .D: panic("unreachable")
    case .S: panic("unreachable")
    }

    opp_players := card(players_in_zone(ms, opp_team, target))
    advantage := target_players - opp_players

    return base_chance+advantage
}

dribble_likelihood :: proc(ms:MatchState) -> int {
    my_team := ms.ball.team
    current_zone := ms.ball.zone
    opp_team := other_team(my_team)

    // goalkeepers don't dribble
    if ms.ball.player == 0 do return 0

    target := target_zone(my_team, current_zone, .D)
    if target == -1 do return 0

    my_players_in_zone := card(players_in_zone(ms, my_team, current_zone))
    opp_players_in_zone := card(players_in_zone(ms, opp_team, current_zone))
    my_players_in_target := card(players_in_zone(ms, my_team, target))
    opp_players_in_target := card(players_in_zone(ms, opp_team, target))

    // if there are no players in this or the target zone, big chance that
    // we choose this.
    if opp_players_in_zone + opp_players_in_target == 0 do return 10

    advantage := my_players_in_zone+my_players_in_target-opp_players_in_zone-opp_players_in_target

    return 3+advantage
}

decide_action :: proc(ms:MatchState) -> Action {
    my_team := ms.ball.team
    me := ms.ball.player
    current_zone := ms.ball.zone

    // Given each potential action, which zone will a successful execution of that
    // action end up in?
    t_zone,score:int

    for a in ActionType {
        t_zone := target_zone(my_team, current_zone, a)
        if me == 0 && a == .D do continue // goalkeepers don't dribble
        if a == .S do score = shot_likelihood(ms)
        else if a == .D do score = dribble_likelihood(ms)
        else if a in passes do score = pass_likelihood(ms, a)
        else do panic("unreachable")

        set_action_chance(Action{a,t_zone}, score)
    }

    chosen_action := action_roll()
    return chosen_action
}

ActionReport :: struct {
    start_team : int,
    start_player : int,
    start_zone : int,

    action : Action,
    success : bool,

    end_team : int,
    end_player : int,
    end_zone : int,
}

action_outcome_dribble :: proc(ms:MatchState, a:Action) -> ActionReport {
    ar : ActionReport
    ar.start_team = ms.ball.team
    ar.start_player = ms.ball.player
    ar.start_zone = ms.ball.zone

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
    my_in_target_zone  := players_in_zone(ms, my_team, a.zone)
    opp_in_target_zone := players_in_zone(ms, opp_team, a.zone)

    if card(opp_in_target_zone) == 0 || execution_score == 20 {
        ar.success = true
        ar.end_team = ar.start_team
        ar.end_zone = a.zone
        ar.end_player = ar.start_player
        return ar
    }

    ar.end_zone = a.zone

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

action_outcome_shot :: proc(ms:MatchState, a:Action) -> ActionReport {
    assert(a.zone == 0 || a.zone == 10)

    ar : ActionReport
    ar.start_team = ms.ball.team
    ar.start_player = ms.ball.player
    ar.start_zone = ms.ball.zone

    ar.action = a

    my_team := ms.ball.team
    opp_team := other_team(my_team)

    // whether success or failure the ball always ends up with the keeper because we don't
    // do kickoffs yet
    ar.end_team = opp_team
    ar.end_player = 0
    ar.end_zone = a.zone

    // shot success chance is affected by distance to the goal
    distance := distance_from_goal(my_team, ar.start_zone)

    // If the opponent has equal or more players than us in the zone we shoot
    // from, we are assumed to be under pressure and therefore at a disadvantage

    my_in_current_zone  := players_in_zone(ms, my_team, ar.start_zone)
    opp_in_current_zone := players_in_zone(ms, opp_team, ar.start_zone)
    pressure_modifier := card(opp_in_current_zone) - card(my_in_current_zone)
    pressure_modifier = max(pressure_modifier, 0)

    // There is also a modifier for players in the target zone - that is a chance for the
    // shot to be be blocked or stopped
    my_in_target_zone  := players_in_zone(ms, my_team, a.zone)
    opp_in_target_zone := players_in_zone(ms, opp_team, a.zone)
    congestion := card(opp_in_current_zone) - card(my_in_current_zone)

    roll := d20()
    win := 10 + distance + pressure_modifier + congestion
    ar.success = roll >= win

    return ar
}

action_outcome_pass :: proc(ms:MatchState, a:Action) -> ActionReport {
    ar : ActionReport
    ar.start_team = ms.ball.team
    ar.start_player = ms.ball.player
    ar.start_zone = ms.ball.zone

    ar.action = a

    my_team := ms.ball.team
    opp_team := other_team(my_team)
    my_in_current_zone  := players_in_zone(ms, my_team, ar.start_zone)
    opp_in_current_zone := players_in_zone(ms, opp_team, ar.start_zone)
    my_in_target_zone  := players_in_zone(ms, my_team, a.zone)
    opp_in_target_zone := players_in_zone(ms, opp_team, a.zone)

    // remove yourself as a target if the pass is within the zone.
    if a.type == .Z {
        my_in_target_zone = my_in_target_zone - PlayerSet{ar.start_player}
    }
    assert(card(my_in_target_zone) > 0)

    if card(opp_in_current_zone + opp_in_target_zone) == 0 {
        ar.success = true
        ar.end_team = ar.start_team
        ar.end_player = random_player_from_set(my_in_target_zone)
        ar.end_zone = a.zone
        return ar
    }

    pressure_modifier := card(opp_in_current_zone) - card(my_in_current_zone) - 1
    t_zone_advantage  := card(my_in_target_zone) - card(opp_in_target_zone)

    win := 10 + pressure_modifier - t_zone_advantage
    roll := d20()

    if roll >= win {
        ar.success = true
        ar.end_zone = a.zone
        ar.end_team = ar.start_team
        ar.end_player = random_player_from_set(my_in_target_zone)
    } else {
        ar.success = false
        ar.end_team = opp_team

        if card(opp_in_target_zone) > 0 {
            ar.end_zone = a.zone
            ar.end_player = random_player_from_set(opp_in_target_zone)
        } else  {
            ar.end_zone = ar.start_zone
            ar.end_player = random_player_from_set(opp_in_current_zone)
        }
    }

    return ar
}

action_outcome :: proc(ms:MatchState, a:Action) -> ActionReport {
    assert(a.zone >= 0)
    assert(a.zone <= 10)

    if a.type == .D do return action_outcome_dribble(ms,a)
    if a.type == .S do return action_outcome_shot(ms,a)
    else do return action_outcome_pass(ms,a)
}

tick_match_state :: proc(ms:^MatchState, ar:ActionReport) {
    ms.ball.team = ar.end_team
    ms.ball.player = ar.end_player
    ms.ball.zone = ar.end_zone

    if ar.action.type == .D do ms.players[ar.start_team][ar.start_player].current_zone = ar.end_zone

    if ar.action.type == .S {
        for &p in ms.players[BLUE] do p.current_zone = natural_zone(BLUE, p.position)
        for &p in ms.players[RED] do p.current_zone = natural_zone(RED, p.position)
    }

    if ar.action.type == .S && ar.success {
        if ar.start_team == BLUE do ms.blue_goals += 1
        else do ms.red_goals += 1
        append(&ms.goal_records, GoalRecord{ar.start_team, ar.start_player, ms.minute})
    }

    ms.minute += 1
}
