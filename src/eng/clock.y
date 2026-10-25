
import term;

const HZ = 30;
const PERIOD = 33333;
let TICK = 0;
let NEXT_US = 0;
let LAG = 0;

def begin() -> void {
    NEXT_US = clock_us() + PERIOD;
    TICK = 0;
}

def wait() -> long {
    TICK += 1;
    let now = clock_us();
    if (now < NEXT_US) {
        term.sleep_us(NEXT_US - now);
        NEXT_US += PERIOD;
        return 1;
    };
    let behind = (now - NEXT_US) / PERIOD + 1;
    if (behind > 4) {
        NEXT_US = now + PERIOD;
        return 1;
    };
    NEXT_US += PERIOD * behind;
    LAG = behind;
    behind
}

export { begin, wait, TICK, HZ, LAG };
