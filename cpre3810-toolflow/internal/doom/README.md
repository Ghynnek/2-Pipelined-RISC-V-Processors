# Doom on your VHDL processor

Unzip this distribution, open a terminal in the extracted directory, and run:

```sh
./doom3810 /path/to/your/cpu
```

The argument can be the project root, its `TopLevel` folder, or the path to
`RISCV_Processor.vhd`. The launcher finds supporting VHDL files recursively.
For the standard layout, passing `TopLevel` also includes sibling component
and package folders. Directories named `test`, `tests`, `tb`, `testbench`,
`testbenches`, `build`, and `obj`, hidden directories, and files named `tb_*`,
`test_*`, or `*_tb.vhd` are excluded. Keep synthesis sources together in one
project; multiple processors/test-only files should be in separate folders.
Files named `mem.vhd` are intentionally replaced by the simulator's memory.

The first launch builds a native simulator for **your processor**, then starts
the first Doom level. Later launches reuse it until HDL contents change. Your
HDL files are read only. Every HDL input is copied to a private build snapshot;
GHDL reads only that copy. Memory/addressing changes are applied to the copied
top. Cache locations inside your processor directory are rejected. Generated
wrappers, compiled models, and logs live in
`~/.cache/doom-hdl/` (or `$XDG_CACHE_HOME/doom-hdl/`). Spaces in the project or
extracted distribution path are supported. Use a cache path without whitespace.

## Requirements

- x86-64 Linux using glibc 2.34 or newer (built on AlmaLinux 9).
- Python 3.9+, GNU Make, and a working GNU C++ compiler with C++17 support
  (GCC 11+ recommended), including its development libraries/headers.
- Runtime libraries: `libstdc++.so.6` with GLIBCXX_3.4.29 or newer,
  `libgcc_s.so.1`, `libatomic.so.1`, `libz.so.1`, and the usual glibc libraries.
- Optional SDL2 runtime (`libSDL2-2.0.so.0`) for a graphical window.

GHDL 6.0.0 and Verilator 5.052 are included. GNAT, a RISC-V compiler, SDL
headers, Perl, downloads, sudo, and installing Python packages are not needed
once the requirements above are present. The bundled tools are dynamically
linked; this is not an architecture-independent or fully static distribution.
It does not support Windows/macOS, ARM Linux, or musl-based Linux directly.

## Display and controls

SDL is the default. When SDL or a desktop display is unavailable, the launcher
falls back to a terminal renderer. Force terminal mode for SSH:

```sh
./doom3810 /path/to/your/cpu --terminal
```

SDL: arrows/WASD to move, Space/Ctrl to fire, E to use, Shift to run,
Enter/Esc for menus; close the window to stop. Terminal: arrows/WASD, Space,
E, Enter/Esc; Q or Ctrl-C to stop. Terminal key releases use a timeout.
Sound and saved games are not implemented.

Rendering and game logic execute on your HDL processor. The host supplies RAM,
WAD data, framebuffer display, and keyboard events. The on-screen **guest FPS**
normalizes cycles/frame to an assumed 50 MHz; **host FPS** is the actual playback
rate. Neither claims the HDL could physically clock at 50 MHz. Set another
normalization with `--guest-hz 25000000`.

```sh
# Reduce guest rendering work
./doom3810 /path/to/your/cpu --low-detail --view-size 6

# Compile without opening the game
./doom3810 /path/to/your/cpu --build-only

# Headless smoke test and screenshot
./doom3810 /path/to/your/cpu --display headless --frames 50 --ppm frame.ppm

# Override cache or force compilation
./doom3810 /path/to/your/cpu --cache-dir /tmp/my-doom-cache --rebuild

# Longer play (default is 10 billion cycles)
./doom3810 /path/to/your/cpu --max-cycles 100000000000
```

`--frames` counts framebuffer submissions, including startup/wipe frames.
`--view-size` accepts 3 through 11. Other options: `--jobs N`, `--wad FILE`,
`--elf FILE` (course bare-metal ELF), `--input FILE` (recorded key events),
`--log FILE`, and `--help`. Put the HDL directory before display/game options.

## Processor interface

The processor must implement the supplied course template's 32-bit interface,
required signals, and the memory component instances `IMem: mem` and `DMem: mem`.
The adapter exposes `s_IMemAddr`, `s_PC`, `s_Inst`, `s_DMemAddr`, `s_DMemData`,
`s_DMemBE`, `s_DMemWr`, `s_DMemOut`, `s_Halt`, `s_RegWr`, `s_RegWrAddr`, and
`s_RegWrData`. The `oALUOut` port is retained. Instances of `entity work.mem`
are also recognized. Required signals must represent committed architectural
operations; correct pipeline hazard handling is the student's responsibility.

The reset PC is 0x00400000. Instruction/data reads are combinational, stores
commit on rising edges, and byte enables select little-endian lanes. RAM is
64 MiB starting at 0x00400000; the WAD ROM starts at 0x10000000 and host devices
at 0x20000000. Full addresses are exposed instead of the small template memory
slices. Both memory instances are replaced only in a generated copy of the top;
all datapath/control logic comes from the submitted files.

Doom uses the course integer instructions with software multiply/divide,
without M, ECALL, EBREAK, or FENCE. WFI is HALT. The game is expected to run
continuously; an early halt usually indicates a processor bug. A template
skeleton without an implemented datapath cannot run the game. The adapter is
for template-compatible course designs, not arbitrary RISC-V top-level ports,
external IP libraries, or SystemVerilog processors.

## Troubleshooting

Compilation diagnostics are in the cache entry's `build.log`; the launcher
prints its location on failure. Runtime output and per-frame statistics are
in the printed `run.log`. To inspect an early halt, inspect the logged PC and
check instruction decoding, hazards, branches, byte stores, and signed loads.
If there is no desktop and no interactive TTY, use `--display headless`.
The simulation may be slow on complex processors; reducing the window size
alone does not reduce guest rendering work.

## Package contents

`doom3810` is the native launcher; `libexec/` contains the offline tools and
runtime source needed to compile each student's HDL. `assets/` contains the
precompiled course-ISA Doom ELF and the supplied `doom1.wad.zip`'s IWAD image.
`licenses/` contains notices; `sources/` contains upstream source archives and
our launcher/port sources. No precompiled sample processor, build trees, object
files, screenshots, compiler toolchain, or bootstrap compiler is distributed.
`MANIFEST.sha256` records package contents. See `licenses/NOTICE.txt` for the
separate engine, game-data, library, and tool notices.

## License

Our launcher, adapter, host platform, and packaging additions are licensed under
GNU GPL version 2 only (`GPL-2.0-only`); see `LICENSE.txt`. Corresponding sources
are included under `sources/`. Bundled third-party tools, libraries, the Doom
engine, and WAD data retain their respective licenses and notices. For the
Verilator runtime combined with our host code, its Artistic License 2.0 option
is selected. See `licenses/NOTICE.txt` for details.
