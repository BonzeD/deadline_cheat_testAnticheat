# Mock test environment

Run `python3 tests/run_all.py` from any directory. Requires Python 3 and a Lua 5.4 shared library named `liblua-5.4.so` discoverable by the OS. The scripts also work with a standard Lua 5.4 executable, e.g. `lua tests/integration.lua`, from the project root. Tests run independently with a timeout; they use simulated Roblox/executor APIs.

These mocks are not Roblox Studio, Codex, physics, a graphics renderer, networking or the game's actual character/team model. Passing them does not guarantee compatibility or performance in a real game.

## Manual test, in an authorized test place

1. Launch fresh; verify ESP, aim and other main features are off. Switch ESP on/off repeatedly, respawn and check other players leave/join.
2. In ESP STYLE, enable Skeleton; inspect R6 and R15, on/off-screen and missing parts. Test different team and distance filters.
3. Turn on Crosshair + Crosshair spin; change speed and shape, turn spin off. Dot alone cannot visibly rotate.
4. Change CONFIGS → Language to Ukrainian and back; save/load a profile and check bindings.
5. Test actual executor capabilities, game performance, camera and menu separately. Record the game, device, FPS, expected/actual behaviour and errors; do not infer that mock tests reproduce real rendering.
