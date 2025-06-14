package football

import "core:log"

ball_player_action :: proc(ms:MatchState) -> Action {
    /* the player with the ball decides what to do: pass, dribble,
       shoot, hold up play. The decision is based on the lane */

    my_team := ms.ball.team
    opp_team := other_team(my_team)
    current_zone := ms.ball.zone
    current_lane := lane(ms.ball.zone)
    if my_team == RED do current_lane = 4 - current_lane

    outfield_zones := [9]int{1,2,3,4,5,6,7,8,9}

    BL :: 0
    BC :: 1
    BR :: 2
    ML :: 3
    MC :: 4
    MR :: 5
    FL :: 6
    FC :: 7
    FR :: 8

    if my_team == RED {
        for &z in outfield_zones do z = 10 - z
    }

    advantages : [9]int

    for i in 0..<9 {
        advantages[i] = advantage_in_zone(ms, my_team, outfield_zones[i])
    }

    if current_lane == 0 {
        /* in the first lane, the priority is to pass the ball out
        into the first or middle lane. Dribbles, shots or holdups are
        very unlikely. Passes inside the zone are unlikely, especially
        if the zone is contested. Passes to the final third or
        opponent goal zone are not possibilities*/

        goal_zone := current_zone


        opps_in_goal_zone := card(players_in_zone(ms, opp_team, goal_zone))
        my_players_in_goal_zone := card(players_in_zone(ms, my_team, goal_zone))

        if opps_in_goal_zone > 0 || my_players_in_goal_zone < 2 {
            set_action_chance({.Pass, goal_zone}, 0)
        } else {
            set_action_chance({.Pass, goal_zone}, 5+my_players_in_goal_zone)
        }

        for i in 0..<6 {
            set_action_chance({.Pass, outfield_zones[i]}, 5+advantages[i])
        }
        print_action_change()
        return action_roll()
    } else if current_lane == 1 {

        /* In lane 1, the players pass the ball looking for advantages
           upfield if they are under pressure they might pass the ball
           back to the keeper. They might also run the ball forward -
           more likely if they are on the wing. */

    } else if current_lane == 2 {

        /* In lane 2, the primary instinct is to look for through
           balls into the center/box, or to put the ball out into the
           foward wide channels if there is an advantage there. If
           that option doesn't look attractive, they might dribble the
           ball forwards. If that doesn't look good they can recycle
           the ball back into lane 1 (though not zone 0) */

    } else if current_lane == 3 {

        /* In lane 3 more depends on which channel we are in. In all
           cases we want to maintain a high tempo and look for the
           incisive ball into the box - a cross if on the wings, a
           box-crash from the center. If in the centre channel there's
           also a chance for a shot. */

    } else {

        /* If you have the ball in the box you're probably taking a
           shot - though there's also a chance to pass to a player who
           is also in the box, or pass backwards to a set up another
           player for a shot or box-crash */

        set_action_chance({.Shot, current_zone}, 5)
        set_action_chance({.Pass, current_zone}, 2+advantage_in_zone(ms, my_team, current_zone))
        set_action_chance({.Pass, outfield_zones[FC]}, 1+advantages[FC])

        print_action_change()
        return action_roll()
    }
    panic("bad fallthrough")
}
