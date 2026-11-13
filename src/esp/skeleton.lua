-- Approximate R6/R15 skeleton built from part centres, not joint attachments.
return function(parent)
    local edges = {
        {'Head','UpperTorso'}, {'UpperTorso','LowerTorso'},
        {'UpperTorso','LeftUpperArm'}, {'LeftUpperArm','LeftLowerArm'}, {'LeftLowerArm','LeftHand'},
        {'UpperTorso','RightUpperArm'}, {'RightUpperArm','RightLowerArm'}, {'RightLowerArm','RightHand'},
        {'LowerTorso','LeftUpperLeg'}, {'LeftUpperLeg','LeftLowerLeg'}, {'LeftLowerLeg','LeftFoot'},
        {'LowerTorso','RightUpperLeg'}, {'RightUpperLeg','RightLowerLeg'}, {'RightLowerLeg','RightFoot'},
    }
    local r6 = {{'Head','Torso'},{'Torso','Left Arm'},{'Torso','Right Arm'},{'Torso','Left Leg'},{'Torso','Right Leg'}}
    local lines, pairsOfParts = {}, {}
    local function hide() for _,line in ipairs(lines) do line.Visible=false end end
    local function scan(character)
        local selected=character:FindFirstChild('UpperTorso') and edges or r6
        pairsOfParts={}
        for i,pair in ipairs(selected) do
            local a,b=character:FindFirstChild(pair[1]),character:FindFirstChild(pair[2])
            if not lines[i] then
                    local line=Instance.new('Frame');line.Name='SkeletonLine';line.AnchorPoint=Vector2.new(0.5,0.5)
                    line.BorderSizePixel=0;line.Visible=false;line.Parent=parent;lines[i]=line
            end
            if a and b and a:IsA('BasePart') and b:IsA('BasePart') then pairsOfParts[i]={a,b} end
        end
        hide()
    end
    local function render(camera,color,thickness,transparency)
        for i,line in ipairs(lines) do
            local pair=pairsOfParts[i]
            if pair then
                local a, aOn=camera:WorldToViewportPoint(pair[1].Position)
                local b, bOn=camera:WorldToViewportPoint(pair[2].Position)
                line.Visible=aOn and bOn and a.Z>0 and b.Z>0
                if line.Visible then
                    local dx,dy=b.X-a.X,b.Y-a.Y
                    line.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
                    line.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),thickness)
                    line.Rotation=math.deg(math.atan2(dy,dx));line.BackgroundColor3=color;line.BackgroundTransparency=transparency
                end
            else line.Visible=false end
        end
    end
    return {scan=scan,render=render,hide=hide,destroy=function() for _,line in ipairs(lines) do line:Destroy() end end}
end
