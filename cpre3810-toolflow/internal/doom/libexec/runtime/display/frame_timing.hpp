// SPDX-License-Identifier: GPL-2.0-only
#pragma once
#include <cstdint>
#include <stdexcept>

namespace display {
// Cycle counts are supplied by the CPU harness at guest frame submission.
// Presentation skips and terminal refreshes must never call submit().
class FrameTiming {
    uint64_t hz_, previous_=0, frames_=0;
public:
    explicit FrameTiming(uint64_t clock_hz):hz_(clock_hz) {
        if(!hz_) throw std::invalid_argument("Guest clock frequency must be positive");
    }
    struct Sample { uint64_t cycles_per_frame; double guest_fps; double average_guest_fps; };
    Sample submit(uint64_t cycles) {
        if(cycles<=previous_) throw std::invalid_argument("Guest frame cycles must increase");
        const uint64_t delta=cycles-previous_;
        previous_=cycles; ++frames_;
        return {delta,double(hz_)/double(delta),double(hz_)*double(frames_)/double(cycles)};
    }
    uint64_t guest_milliseconds(uint64_t cycles) const {
        // long double avoids overflow in cycles * 1000; long-running timer
        // register implementations may intentionally expose only the low 32 bits.
        return uint64_t((static_cast<long double>(cycles)*1000)/hz_);
    }
};
}
