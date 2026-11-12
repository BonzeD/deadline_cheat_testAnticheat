-- Per-action bind modes. Hold is momentary; Toggle changes on each press.
return function(input, actions, getters, modes)
local held={}
local function setEnabled(name, desired)
    local getter,action=getters[name],actions[name]
    if not getter or not action then return false end
    if getter()~=desired then action() end
    return getter()==desired
end
local function release(name)
    if not held[name] then return end
    held[name]=nil
    setEnabled(name,false)
end
local function releaseAll()
    local names={};for name in pairs(held) do names[#names+1]=name end
    for _,name in ipairs(names) do release(name) end
end
local function press(name, key)
    if not actions[name] or not getters[name] then return end
    if modes[name]=="Hold" then
        if held[name] then return end
        if setEnabled(name,true) then held[name]={key=key,started=os.clock()} end
    else actions[name]() end
end
local function inputEnded(key)
    local names={}
    for name,record in pairs(held) do if record.key==key then names[#names+1]=name end end
    for _,name in ipairs(names) do release(name) end
end
local function step()
    local names={}
    for name,record in pairs(held) do
        if os.clock()-record.started>0.15 then
            local key=record.key
            local mouse=key==Enum.UserInputType.MouseButton1 or key==Enum.UserInputType.MouseButton2 or key==Enum.UserInputType.MouseButton3
            local ok,down
            if mouse and type(input.IsMouseButtonPressed)=="function" then
                ok,down=pcall(function() return input:IsMouseButtonPressed(key) end)
            elseif not mouse and type(input.IsKeyDown)=="function" then
                ok,down=pcall(function() return input:IsKeyDown(key) end)
            end
            if ok and down==false then names[#names+1]=name end
        end
    end
    for _,name in ipairs(names) do release(name) end
end
local function setMode(name,mode)
    assert(actions[name] and getters[name] and (mode=="Toggle" or mode=="Hold"),"Invalid binding mode")
    release(name); modes[name]=mode
    -- Selecting Hold makes its feature inactive until the key is held.
    if mode=="Hold" then setEnabled(name,false) end
end
return {press=press,inputEnded=inputEnded,step=step,releaseAll=releaseAll,setMode=setMode}
end
