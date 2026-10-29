// SPDX-License-Identifier: GPL-2.0-only
#pragma once
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace display {
// Doom key codes; pixels are packed 0xAARRGGBB, alpha ignored by terminal.
struct KeyEvent { bool pressed; uint8_t key; };
class Backend {
public:
    virtual ~Backend() = default;
    virtual void present(const uint32_t* pixels, int width, int height) = 0;
    virtual std::vector<KeyEvent> poll() = 0;
    virtual bool closed() const = 0;
    virtual void status(const std::string&) {}
};
std::unique_ptr<Backend> create(const std::string& mode = "auto");
}
