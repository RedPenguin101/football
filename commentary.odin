package football

import "core:strings"

comment :: proc(ms:MatchState, ar:ActionReport) -> string {
    b := strings.builder_make()

    switch ar.action {
    case .Z: {
        strings.write_string(&b, "Blue " if ar.team == BLUE else "Red ")
        strings.write_string(&b, "are passing it around")
        if !ar.success {
            strings.write_string(&b, " but ")
            strings.write_string(&b, ms.players[ar.new_team][ar.new_player].name)
            strings.write_string(&b, " manages to take it away!")
        }
    }
    case .D: {
        strings.write_string(&b, ms.players[ar.team][ar.player].name)
        strings.write_string(&b, " carries the ball forward")
        if !ar.success {
            strings.write_string(&b, " but is tackled by ")
            strings.write_string(&b, ms.players[ar.new_team][ar.new_player].name)
        }
    }
    case .F: {
        strings.write_string(&b, ms.players[ar.team][ar.player].name)
        strings.write_string(&b, " passes the ball forward")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.new_team][ar.new_player].name)
    }
    case .B: {
        strings.write_string(&b, ms.players[ar.team][ar.player].name)
        strings.write_string(&b, " passes the ball backward")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.new_team][ar.new_player].name)
    }
    case .L: {
        strings.write_string(&b, ms.players[ar.team][ar.player].name)
        strings.write_string(&b, " passes the ball to the left")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.new_team][ar.new_player].name)
    }
    case .R: {
        strings.write_string(&b, ms.players[ar.team][ar.player].name)
        strings.write_string(&b, " passes the ball to the right")
        if ar.success {
            strings.write_string(&b, " to ")
        }
        else {
            strings.write_string(&b, " but it's intercepted by ")
        }
        strings.write_string(&b, ms.players[ar.new_team][ar.new_player].name)
    }
    case .S: {
        strings.write_string(&b, ms.players[ar.team][ar.player].name)
        strings.write_string(&b, " Has a go at goal!")
    }
    }

    return strings.to_string(b)
}
