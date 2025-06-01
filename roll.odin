package football
import "core:math/rand"
import "core:fmt"

d20 :: proc() -> int {
    return rand.int_max(20)+1
}

dn :: proc(n:int) -> int {
    return rand.int_max(n)+1
}

action_roll :: proc(action_scores:[Action]int) -> Action {
    die_size := 0
    for s in action_scores {
        die_size += s
    }
    roll := rand.int_max(die_size)
    fmt.println("die size:", die_size, "roll:", roll)
    acc := 0
    for score, action in action_scores {
        acc += score
        if roll <= acc {
            return action
        }
    }
    panic("")
}


