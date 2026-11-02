#ifndef NIVLET_KEEP_AWAKE_H
#define NIVLET_KEEP_AWAKE_H
#include <stdbool.h>
#include <stdint.h>

typedef struct { uint32_t system; uint32_t display; } NivletKeepAwake;
typedef int (*NivletCreateAssertion)(bool display, uint32_t *identifier);
typedef int (*NivletReleaseAssertion)(uint32_t identifier);

static bool nivletReleaseAssertion(uint32_t *identifier, NivletReleaseAssertion release) {
    if (!*identifier) return true;
    if (release(*identifier) != 0) return false;
    *identifier = 0;
    return true;
}

static bool nivletApplyKeepAwake(NivletKeepAwake *state, bool awake, bool display,
                                NivletCreateAssertion create, NivletReleaseAssertion release) {
    display = awake && display;
    if (awake && !state->system) {
        uint32_t identifier = 0;
        if (create(false, &identifier) != 0 || !identifier) return false;
        state->system = identifier;
    }
    if (display && !state->display) {
        uint32_t identifier = 0;
        if (create(true, &identifier) != 0 || !identifier) return false;
        state->display = identifier;
    }
    if (!display && !nivletReleaseAssertion(&state->display, release)) return false;
    if (!awake && !nivletReleaseAssertion(&state->system, release)) return false;
    return true;
}

static bool nivletSetKeepAwake(NivletKeepAwake *state, bool awake, bool display,
                              NivletCreateAssertion create, NivletReleaseAssertion release,
                              bool *restored) {
    const bool oldAwake = state->system != 0, oldDisplay = state->display != 0;
    if (nivletApplyKeepAwake(state, awake, display, create, release)) {
        *restored = true;
        return true;
    }
    *restored = nivletApplyKeepAwake(state, oldAwake, oldDisplay, create, release);
    return false;
}

static bool nivletStopKeepAwake(NivletKeepAwake *state, NivletReleaseAssertion release) {
    const bool displayReleased = nivletReleaseAssertion(&state->display, release);
    const bool systemReleased = nivletReleaseAssertion(&state->system, release);
    return displayReleased && systemReleased;
}
#endif
