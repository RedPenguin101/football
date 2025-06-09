package football

import "core:strings"

comment :: proc(ms:MatchState, ar:ActionReport) -> string {
    b := strings.builder_make()

    switch ar.action.type {
    case .Pass: {
        if ar.start_zone == ar.action.zone {
            strings.write_string(&b, "ManUtd " if ar.start_team == BLUE else "Livpl ")
            strings.write_string(&b, "are passing it around")
            if !ar.success {
                strings.write_string(&b, " but ")
                strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
                strings.write_string(&b, " manages to take it away!")
            }
        } else {
            strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
            strings.write_string(&b, " passes the ball from zone ")
            strings.write_int(&b, ar.start_zone)
            strings.write_string(&b, " to zone ")
            strings.write_int(&b, ar.action.zone)
            if ar.success {
                strings.write_string(&b, " to ")
            }
            else {
                strings.write_string(&b, " but it's intercepted by ")
            }
            strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)

        }
    }
    case .Dribble: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " carries the ball forward from zone ")
        strings.write_int(&b, ar.start_zone)
        strings.write_string(&b, " to zone ")
        strings.write_int(&b, ar.action.zone)
        if !ar.success {
            strings.write_string(&b, " but is tackled by ")
            strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
        }
    }
    case .Shot: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " shoots from zone ")
        strings.write_int(&b, ar.start_zone)
        if ar.success {
            strings.write_string(&b, " GOOOOOAL!!!")
        } else {
            strings.write_string(&b, " But the keeper collects it")
        }
    }
    }

    return strings.to_string(b)
}
