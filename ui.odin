package football

import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800
L_MARGIN :: 50
T_MARGIN :: 100
PITCH_WIDTH :: SCREEN_WIDTH-2*(L_MARGIN)
PITCH_HEIGHT :: SCREEN_HEIGHT-2*(T_MARGIN)
FPS :: 10

ZONE_RECTS := [?]rl.Rectangle{
    rl.Rectangle{ L_MARGIN+PITCH_WIDTH/3,  T_MARGIN+5*PITCH_HEIGHT/6, PITCH_WIDTH/3, PITCH_HEIGHT/6},

    rl.Rectangle{ L_MARGIN,                T_MARGIN+2*PITCH_HEIGHT/3, PITCH_WIDTH/4, PITCH_HEIGHT/3},
    rl.Rectangle{ L_MARGIN+PITCH_WIDTH/4,  T_MARGIN+2*PITCH_HEIGHT/3, PITCH_WIDTH/2, PITCH_HEIGHT/3},
    rl.Rectangle{ L_MARGIN+3*PITCH_WIDTH/4,T_MARGIN+2*PITCH_HEIGHT/3, PITCH_WIDTH/4, PITCH_HEIGHT/3},

    rl.Rectangle{ L_MARGIN,                T_MARGIN+PITCH_HEIGHT/3,   PITCH_WIDTH/4, PITCH_HEIGHT/3},
    rl.Rectangle{ L_MARGIN+PITCH_WIDTH/4,  T_MARGIN+PITCH_HEIGHT/3,   PITCH_WIDTH/2, PITCH_HEIGHT/3},
    rl.Rectangle{ L_MARGIN+3*PITCH_WIDTH/4,T_MARGIN+PITCH_HEIGHT/3,   PITCH_WIDTH/4, PITCH_HEIGHT/3},

    rl.Rectangle{ L_MARGIN,                T_MARGIN,                  PITCH_WIDTH/4, PITCH_HEIGHT/3},
    rl.Rectangle{ L_MARGIN+PITCH_WIDTH/4,  T_MARGIN,                  PITCH_WIDTH/2, PITCH_HEIGHT/3},
    rl.Rectangle{ L_MARGIN+3*PITCH_WIDTH/4,T_MARGIN,                  PITCH_WIDTH/4, PITCH_HEIGHT/3},

    rl.Rectangle{ L_MARGIN+PITCH_WIDTH/3,  T_MARGIN,                  PITCH_WIDTH/3, PITCH_HEIGHT/6},
}

alpha_blue :: rl.Color{0,0,255,50}
alpha_red :: rl.Color{255,0,0,50}

ui_init :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Amputation")
    rl.SetTargetFPS(FPS)
}

ui_close :: proc() {
    rl.CloseWindow()
}

ui_continue :: proc() -> bool {
    return !rl.WindowShouldClose()
}

draw :: proc(ms:MatchState) {
    rl.DrawText(rl.TextFormat("Minute: %d", int(ms.minute)), 10, 10, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%s", ms.commentary), 10, 30, 20, rl.WHITE)

    color := alpha_blue if ms.ball.team == BLUE else alpha_red

    rl.DrawRectangleRec(ZONE_RECTS[ms.ball.zone], color)
    if ms.ball.zone == 2 {
        rl.DrawRectangleRec(ZONE_RECTS[0], rl.DARKGREEN)
    } else if ms.ball.zone == 8 {
        rl.DrawRectangleRec(ZONE_RECTS[10], rl.DARKGREEN)
    }

    rl.DrawRectangleLines(L_MARGIN+PITCH_WIDTH/4,T_MARGIN,
                          PITCH_WIDTH/2, PITCH_HEIGHT,
                          rl.WHITE)
    rl.DrawRectangleLines(L_MARGIN,T_MARGIN+PITCH_HEIGHT/3,
                          PITCH_WIDTH, PITCH_HEIGHT/3,
                          rl.WHITE)

    rl.DrawRectangleLines(L_MARGIN+PITCH_WIDTH/3,
                          T_MARGIN,
                          PITCH_WIDTH/3,
                          PITCH_HEIGHT/6,
                          rl.WHITE)

    rl.DrawRectangleLines(L_MARGIN+PITCH_WIDTH/3,
                          T_MARGIN+5*PITCH_HEIGHT/6,
                          PITCH_WIDTH/3,
                          PITCH_HEIGHT/6,
                          rl.WHITE)

    rl.DrawRectangleLines(L_MARGIN,T_MARGIN,
                          PITCH_WIDTH, PITCH_HEIGHT,
                          rl.RAYWHITE)

    for zone in 0..<ZONES {
        blues := players_in_zone(ms, BLUE, zone)
        reds := players_in_zone(ms, RED, zone)
        zr := ZONE_RECTS[zone]
        b_i :i32= 0
        r_i :i32= 0
        y :i32= 25 if zone != 8 else 125
        for p in 0..<11 {
            if p in blues {
                rl.DrawCircle(i32(zr.x)+25+b_i, i32(zr.y)+y, 20, rl.BLUE)
                rl.DrawText(rl.TextFormat("%d", p+1), i32(zr.x)+25+b_i-7, i32(zr.y)+y-7, 20, rl.WHITE)
                b_i += 50
            }
            if p in reds {
                rl.DrawCircle(i32(zr.x+zr.width)-25-r_i, i32(zr.y)+y, 20, rl.RED)
                rl.DrawText(rl.TextFormat("%d", p+1), i32(zr.x+zr.width)-25-r_i-7, i32(zr.y)+y-7, 20, rl.WHITE)
                r_i += 50
            }
        }
    }
}

handle_input :: proc(ms:^MatchState) -> bool {
    kp := rl.GetKeyPressed()
    return kp == .T
}

ui_run :: proc(ms:^MatchState) -> bool {
    rl.BeginDrawing()
    rl.ClearBackground(rl.DARKGREEN)

    draw(ms^)
    tick := handle_input(ms)

    rl.EndDrawing()
    return tick
}
