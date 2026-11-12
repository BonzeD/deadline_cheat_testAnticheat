-- Local JSON profiles. No code execution; names never escape the project directory.
return function(ctx, root)
local settings = ctx.settings
local numeric, choices = {}, {}
local excluded = {SilentAim=true, TriggerEnabled=true, AutoJumpEnabled=true}
local function number(key, min, max) numeric[key] = {min,max} end
local function choice(key, options) choices[key] = options end
local function validName(name)
    return type(name)=="string" and #name>=1 and #name<=32 and name:match("^[A-Za-z0-9_%-]+$") ~= nil
end
local function path(name)
    assert(validName(name), "Use 1-32 letters, numbers, _ or - for the profile name")
    return root .. "/config_" .. name .. ".json"
end
local function allowedBool(key)
    return type(settings[key]) == "boolean" and not excluded[key]
end
local function validValue(key,value)
    if allowedBool(key) then return type(value)=="boolean" end
    if numeric[key] then
        return type(value)=="number" and value==value and value>=numeric[key][1] and value<=numeric[key][2]
    end
    if choices[key] then
        if type(value)~="string" then return false end
        for _, option in ipairs(choices[key]) do if option==value then return true end end
    end
    return false
end
local function encodeBind(value)
    if value==nil then return false end
    if value == Enum.UserInputType.MouseButton1 or value == Enum.UserInputType.MouseButton2 or value == Enum.UserInputType.MouseButton3 then
        return {kind="mouse", name=value.Name}
    end
    return {kind="key",name=value.Name}
end
local function decodeBind(value)
    if value==false then return nil, true end
    if type(value)~="table" or type(value.name)~="string" or #value.name>64 then return nil,false end
    if value.kind=="mouse" then
        if value.name~="MouseButton1" and value.name~="MouseButton2" and value.name~="MouseButton3" then return nil,false end
        return Enum.UserInputType[value.name], true
    end
    if value.kind=="key" and value.name~="RightShift" and value.name~="Escape" and value.name~="Unknown" then
        local ok, item=pcall(function() return Enum.KeyCode[value.name] end)
        if ok and item then return item,true end
    end
    return nil,false
end
local function save(name, binds, bindingKeys, modes)
    assert(type(writefile)=="function", "writefile unavailable")
    local output={version=1,settings={},binds={},bindModes={}}
    for key,value in pairs(settings) do if validValue(key,value) then output.settings[key]=value end end
    for _,key in ipairs(bindingKeys) do
        output.binds[key]=encodeBind(binds[key])
        if key~="Trigger" then output.bindModes[key]=(modes and modes[key]) or "Toggle" end
    end
    local json=game:GetService("HttpService"):JSONEncode(output)
    writefile(path(name),json)
end
local function load(name, binds, bindingKeys, modes)
    assert(type(readfile)=="function", "readfile unavailable")
    local data=readfile(path(name))
    assert(type(data)=="string" and #data<=65536, "Invalid profile size")
    local payload=game:GetService("HttpService"):JSONDecode(data)
    assert(type(payload)=="table" and payload.version==1 and type(payload.settings)=="table" and type(payload.binds)=="table", "Invalid profile format")
    -- Validate the complete profile before making any changes.
    local nextValues, nextBinds, nextModes, used = {}, {}, {}, {}
    assert(payload.bindModes==nil or type(payload.bindModes)=="table", "Invalid binding modes")
    for key,value in pairs(payload.settings) do
        assert(validValue(key,value), "Invalid setting: " .. tostring(key))
        nextValues[key]=value
    end
    for _,key in ipairs(bindingKeys) do
        local value=payload.binds[key]
        assert(value~=nil,"Missing binding: " .. key)
        local item,ok=decodeBind(value); assert(ok,"Invalid binding: " .. key)
        if item then assert(not used[item],"Duplicate binding: " .. key); used[item]=true end
        nextBinds[key]=item or false
        if key~="Trigger" then
            local mode=(payload.bindModes and payload.bindModes[key]) or "Toggle"
            assert(mode=="Toggle" or mode=="Hold", "Invalid binding mode: " .. key)
            nextModes[key]=mode
        end
    end
    for key,value in pairs(nextValues) do settings[key]=value end
    for _,key in ipairs(bindingKeys) do
        binds[key]=nextBinds[key] or nil
        if modes and key~="Trigger" then modes[key]=nextModes[key] end
    end
end
local function list()
    if type(listfiles)~="function" then return nil,"listfiles unavailable; enter a name manually" end
    local ok, files=pcall(listfiles,root)
    if not ok or type(files)~="table" then return nil,"Cannot list profiles; enter a name manually" end
    local names={}
    for _,full in ipairs(files) do
        local leaf=tostring(full):match("([^/\\]+)$") or ""
        local name=leaf:match("^config_([A-Za-z0-9_%-]+)%.json$")
        if validName(name) then names[#names+1]=name end
    end
    table.sort(names)
    return names
end
return {number=number, choice=choice, save=save, load=load, list=list}
end
