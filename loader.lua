-- Public HTTP bootstrap. Modules stay separate in the repository.
-- Executing the moving main branch trusts its current contents.
local base = "https://raw.githubusercontent.com/BonzeD/deadline_cheat_testAnticheat/main/"
local env = getgenv and getgenv() or _G
local root = env.DeadlineRoot or "DeadlineTest"
-- Profiles remain local; an executor without folder functions can still run,
-- but saving configs may require manually creating the workspace folder.
if type(root) == "string" and root ~= "" and type(isfolder) == "function" and type(makefolder) == "function" then
    pcall(function() if not isfolder(root) then makefolder(root) end end)
end
local ok, source = pcall(function() return game:HttpGet(base .. "main.lua") end)
if not ok or type(source) ~= "string" or source == "" then error("Cannot download main.lua: " .. tostring(source)) end
local chunk, err = loadstring(source, "@DeadlineTest/main.lua")
if not chunk then error("Cannot compile main.lua: " .. tostring(err)) end
return chunk(base)
