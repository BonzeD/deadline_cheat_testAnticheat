-- Exercise HTTP bootstrap with local file-backed mocked responses; no network.
_G.DEADLINE_TEST_REMOTE = true
assert(loadfile('tests/integration.lua'))()
print('HTTP loader mocks: bootstrap, modules and local config folder PASS')
