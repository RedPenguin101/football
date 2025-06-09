package football
import "core:math/rand"
import "core:log"

d20 :: proc() -> int {
    return rand.int_max(20)+1
}

dn :: proc(n:int) -> int {
    if n <= 0 {
        log.warnf("%d", n)
    }
    return rand.int_max(n)+1
}

action_roll :: proc(action_scores:[ActionType]int) -> ActionType {
    die_size := 0
    for s in action_scores {
        die_size += s
    }
    // NOTE: possible some -1 being passed here
    if die_size <= 0 {
        log.panic("no suitable action", action_scores)
    }
    roll := dn(die_size)
    acc := 0
    for score, action in action_scores {
        acc += score
        if roll <= acc {
            return action
        }
    }
    panic("")
}


