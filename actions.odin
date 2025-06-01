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

decide_action :: proc(ms:MatchState) -> Action {
    side := ms.ball.team
    zone := ms.ball.zone
    /* fmt.println("Deciding action for", ms.ball) */
    as := action_scores(side, zone)
    tz := target_zones(side, zone)
    zone_scores := zone_score(ms, side)
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
    action := action_roll(as)
    fmt.println("Chosen action:", action_names[action])
    return action
}
