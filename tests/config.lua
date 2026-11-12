-- Lua 5.4 mocks for profile validation and filesystem flow, not Roblox JSON.
local function enums(names)
 local t={};for _,n in ipairs(names) do t[n]={Name=n} end;return t
end
Enum={KeyCode=enums({'RightShift','Escape','Unknown','Q','K'}),UserInputType=enums({'MouseButton1','MouseButton2','MouseButton3'})}
local stored, encoded, decoded={}, nil, nil
local http={}
function http:JSONEncode(v) encoded=v; return 'json' end
function http:JSONDecode(v) assert(v=='json'); return decoded end
game={GetService=function(_,name) assert(name=='HttpService');return http end}
function writefile(p,v) stored[p]=v end
function readfile(p) assert(stored[p], 'missing');return stored[p] end
function listfiles(p) return {p..'/config_default.json',p..'\\config_custom-1.json',p..'/config_../bad.json'} end
local s={ESP=true,ESPFrameRate=60,AimMode='Hold',SilentAim=false,TriggerEnabled=false,AutoJumpEnabled=false,BypassRemoteFlag='',BypassAllowedPlaceIds={}}
local config=assert(loadfile('src/config/init.lua'))()({settings=s},'DeadlineTest')
config.number('ESPFrameRate',15,120); config.choice('AimMode',{'Hold','Toggle'})
local keys={'Trigger','ESP'};local binds={Trigger=Enum.KeyCode.Q,ESP=nil}
config.save('default',binds,keys)
assert(stored['DeadlineTest/config_default.json']=='json' and encoded.settings.ESP and not encoded.settings.SilentAim and not encoded.settings.BypassRemoteFlag)
assert(encoded.binds.Trigger.name=='Q' and encoded.binds.ESP==false)
decoded=encoded;s.ESP=false;s.ESPFrameRate=30;s.AimMode='Toggle';binds.Trigger=Enum.KeyCode.K;binds.ESP=Enum.UserInputType.MouseButton3
config.load('default',binds,keys)
assert(s.ESP==true and s.ESPFrameRate==60 and s.AimMode=='Hold' and binds.Trigger==Enum.KeyCode.Q and binds.ESP==nil)
local names=config.list();assert(#names==2 and names[1]=='custom-1' and names[2]=='default')
assert(not pcall(config.save,'../escape',binds,keys))
local snapshot=s.ESPFrameRate; decoded.settings.ESPFrameRate=9999
assert(not pcall(config.load,'default',binds,keys) and s.ESPFrameRate==snapshot)
decoded.settings.ESPFrameRate=60; decoded.binds.ESP={kind='key',name='Q'}
assert(not pcall(config.load,'default',binds,keys) and binds.ESP==nil)
decoded.binds.ESP={kind='key',name='RightShift'};assert(not pcall(config.load,'default',binds,keys))
decoded.binds.ESP=false;decoded.settings.BypassAllowedPlaceIds={123};assert(not pcall(config.load,'default',binds,keys))
print('Config mocks: safe paths, validated atomic load, bindings, list PASS')
