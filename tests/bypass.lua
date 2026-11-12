-- Lua 5.4 mocks only; does not prove executor or Roblox support.
local make = assert(loadfile('src/bypass/init.lua'))()
local hooks = {}
local clientCaller = false
checkcaller = function() return clientCaller end
newcclosure = function(f) return f end
local method = 'FireServer'
getnamecallmethod = function() return method end
hooks.__index = function(o,k) return o[k] end
hooks.__namecall = function(o,...) return 'forwarded', select('#',...), ... end
hookmetamethod = function(_,name,fn) local old=hooks[name]; hooks[name]=fn; return old end
local remote = {IsA=function(_,k) return k == 'RemoteEvent' end}
local store = {FindFirstChild=function(_,name) if name == 'Detector' then return remote end end}
game = {PlaceId=42,GetService=function(_,name) assert(name=='ReplicatedStorage'); return store end}
local hum={WalkSpeed=40}
local character={FindFirstChildOfClass=function(_,name) if name=='Humanoid' then return hum end end}
local ctx={env={},localPlayer={Character=character},settings={BypassAllowedPlaceIds={},BypassSpoofSpeed=16,BypassRemotePath={},BypassRemoteFlag=''}, setStatus=function(s) ctx_status=s end}
local b=make(ctx)
b.toggleSpeedSpoof(); assert(not b.isSpeedSpoof())
b.toggleSignal(); assert(not b.isSignal())
ctx.settings.BypassAllowedPlaceIds={42}; b.toggleSignal(); assert(not b.isSignal())
ctx.settings.BypassRemotePath={'Detector'};ctx.settings.BypassRemoteFlag='TestFlag'
b.toggleSpeedSpoof(); assert(b.isSpeedSpoof() and hooks.__index(hum,'WalkSpeed')==16)
assert(hooks.__index({WalkSpeed=8},'WalkSpeed')==8 and hooks.__index(hum,'Other')==nil)
clientCaller=true; assert(hooks.__index(hum,'WalkSpeed')==40);clientCaller=false
ctx.settings.BypassSpoofSpeed=22; b.updateSpoofValue();assert(hooks.__index(hum,'WalkSpeed')==22)
b.toggleSignal();assert(b.isSignal());assert(hooks.__namecall(remote,'TestFlag','x')==nil)
local a,n,arg1,arg2=hooks.__namecall(remote,'Other',nil); assert(a=='forwarded' and n==2 and arg1=='Other' and arg2==nil)
local other={}; assert(hooks.__namecall(other,'TestFlag')=='forwarded')
clientCaller=true;assert(hooks.__namecall(remote,'TestFlag')=='forwarded');clientCaller=false
method='Other';assert(hooks.__namecall(remote,'TestFlag')=='forwarded');method='FireServer'
b.respawn();assert(not b.isSpeedSpoof() and not b.isSignal() and hooks.__index(hum,'WalkSpeed')==40 and hooks.__namecall(remote,'TestFlag')=='forwarded')
local h1,h2=hooks.__index,hooks.__namecall
b.toggleSpeedSpoof();b.toggleSignal();assert(hooks.__index==h1 and hooks.__namecall==h2)
b.cleanup();local b2=make(ctx);b2.toggleSpeedSpoof();b2.toggleSignal();assert(hooks.__index==h1 and hooks.__namecall==h2);b2.cleanup()
game.PlaceId=7;b2.toggleSpeedSpoof();b2.toggleSignal();assert(not b2.isSpeedSpoof() and not b2.isSignal())
ctx.env={};game.PlaceId=42;hookmetamethod=nil;local b3=make(ctx);b3.toggleSpeedSpoof();b3.toggleSignal();assert(not b3.isSpeedSpoof() and not b3.isSignal())
print('Bypass mocks: allowlist, hooks, forwarding, disable, respawn and rerun PASS')
