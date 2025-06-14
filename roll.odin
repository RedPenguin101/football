package football
import "core:math/rand"
import "core:log"
import "core:fmt"

d20 :: proc() -> int {
    return rand.int_max(20)+1
}

dn :: proc(n:int) -> int {
    if n <= 0 {
        log.warnf("%d", n)
    }
    return rand.int_max(n)+1
}

ACTION_CHANCES : map[Action]int

print_action_change :: proc() {
    total := 0
    for a, s in ACTION_CHANCES {
        total += s
    }
    for a, s in ACTION_CHANCES {
        if (s > 0) do fmt.println(a.type, a.zone, ": ", s*100/total)
    }
}

set_action_chance :: proc(a:Action, score:int) {
    ACTION_CHANCES[a] = score
}

reset_action_chance :: proc() {
    for action in ActionType {
        for zone in 0..<ZONES {
            ACTION_CHANCES[Action{action, zone}] = 0
        }
    }
}

cleanup_action_chance :: proc() {
    delete(ACTION_CHANCES)
}

action_roll :: proc() -> Action {
    die_size := 0
    for action, value in ACTION_CHANCES {
        die_size += value
    }
    // NOTE: possible some -1 being passed here
    if die_size <= 0 {
        log.panic("no suitable action", ACTION_CHANCES)
    }
    if ODIN_DEBUG {
        for a,v in ACTION_CHANCES {
            if v > 0 do log.debug("  ", a, (100*v)/die_size, "%")
        }
    }
    roll := dn(die_size)
    acc := 0
    for action, score in ACTION_CHANCES {
        acc += score
        if roll <= acc {
            reset_action_chance()
            return action
        }
    }
    panic("")
}


