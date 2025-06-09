package football

import "core:strings"

comment :: proc(ms:MatchState, ar:ActionReport) -> string {
    b := strings.builder_make()

    switch ar.action.type {
    case .Z: {
        strings.write_string(&b, "ManUtd " if ar.start_team == BLUE else "Livpl ")
        strings.write_string(&b, "are passing it around")
        if !ar.success {
            strings.write_string(&b, " but ")
            strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
            strings.write_string(&b, " manages to take it away!")
        }
    }
    case .D: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " carries the ball forward")
        if !ar.success {
            strings.write_string(&b, " but is tackled by ")
            strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
        }
    }
    case .F: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " passes the ball forward")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
    }
    case .B: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " passes the ball backward")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
    }
    case .L: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " passes the ball to the left")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
    }
    case .R: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " passes the ball to the right")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.end_team][ar.end_player].name)
    }
    case .S: {
        strings.write_string(&b, ms.players[ar.start_team][ar.start_player].name)
        strings.write_string(&b, " Has a go at goal!")
        if ar.success {
            strings.write_string(&b, " GOOOOOAL!!!")
        } else {
            strings.write_string(&b, " But the keeper collects it")
        }
    }
    }

    return strings.to_string(b)
}
