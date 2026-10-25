
def tick() -> void {
    if (!ARMED) { return; };
    FRAME += 1;
    NOW = clock_us();
    LAST_US = NOW;
    if (FRAME % 300 == 0 && term.tracer_attached()) { note(true); };
    if (BAD > 0) {
        WHEN -= 1;
        if (WHEN <= 0) { trap(); };
    };
}
