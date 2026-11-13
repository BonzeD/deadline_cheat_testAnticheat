local objects={}; Instance={new=function() local o={}; function o:Destroy() self.destroyed=true end; objects[#objects+1]=o; return o end}
Vector2={new=function(x,y) return {x=x,y=y} end}; UDim2={fromOffset=function(x,y) return {x=x,y=y} end}; math.atan2=function(y,x) return math.atan(y,x) end
local make=assert(loadfile('src/esp/skeleton.lua'))(); local skeleton=make({})
local function part(x,y,z) return {Position={X=x,Y=y,Z=z},IsA=function(_,c)return c=='BasePart' end} end
local parts={Torso=part(0,0,1),['Left Arm']=part(10,10,1),['Right Arm']=part(-10,10,1)}
local char={FindFirstChild=function(_,name)return parts[name] end}; local camera={WorldToViewportPoint=function(_,p) return p,p.Z>0 end}
skeleton.scan(char);skeleton.render(camera,'red',2,0);assert(not objects[1].Visible and objects[2].Visible and objects[3].Visible)
skeleton.hide();assert(not objects[2].Visible);parts['Left Arm'].Position.Z=-1;skeleton.render(camera,'red',2,0);assert(not objects[2].Visible)
parts={Head=part(0,1,1),UpperTorso=part(0,0,1),LowerTorso=part(0,-1,1)};skeleton.scan(char);skeleton.render(camera,'red',2,0);assert(objects[1].Visible and objects[2].Visible and not objects[3].Visible)
skeleton.destroy();for _,line in ipairs(objects)do assert(line.destroyed)end
print('Skeleton mocks: missing parts, R6/R15, offscreen, cleanup PASS')
