local keys = {
    ["swarm_344043245"] = true,
    ["swarm_45001484"] = true,
    ["swarm_0013941"] = true
}

if not script_key or not keys[script_key] then
    game.Players.LocalPlayer:Kick("no")
end

local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local ws = game:GetService("Workspace")

local lp = plrs.LocalPlayer
local cam = ws.CurrentCamera

local homer = nil
local swarmloop = nil
local camloop = nil
local running = false

local angle = 0
local spd = 0
local lastt = tick()

local function gethomer()
    for _, v in plrs:GetPlayers() do
        if v ~= lp and v.Team and v.Team.Name and string.lower(v.Team.Name):find("homer")
        and v.Character and v.Character:FindFirstChild("HumanoidRootPart") 
        and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end

local function stopshit()
    if swarmloop then swarmloop:Disconnect() swarmloop = nil end
    if camloop then camloop:Disconnect() camloop = nil end
    
    local char = lp.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
        char.Humanoid:ChangeState(8)
    end
    
    pcall(function()
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = char and char:FindFirstChild("Humanoid")
    end)
    
    running = false
    homer = nil
end

local function sticktothefloorlol()
    local char = lp.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = true
        char.Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
    end
end

local function dostuff(target)
    if running then return end
    
    local me = lp.Character
    if not me or not me:FindFirstChild("HumanoidRootPart") then return end
    
    homer = target
    running = true
    
    cam.CameraType = Enum.CameraType.Scriptable
    
    sticktothefloorlol()
    
    task.spawn(function()
        while running and lp.Character == me do
            sticktothefloorlol()
            task.wait(0.13)
        end
    end)
    
    angle = math.random()*6.28*2
    spd = (math.random()<0.5 and 1 or -1) * (20 + math.random()*20)
    lastt = tick()
    
    swarmloop = rs.Heartbeat:Connect(function()
        if not running then return end
        
        local hchar = homer and homer.Character
        if not hchar or not hchar.Parent or not hchar:FindFirstChild("HumanoidRootPart") then
            stopshit() return
        end
        
        local mechar = lp.Character
        if not mechar or not mechar:FindFirstChild("HumanoidRootPart") then
            stopshit() return
        end
        
        local now = tick()
        local dt = now - lastt
        lastt = now
        
        angle = angle + spd * dt * 1.75
        
        if math.random() < dt*12 then
            spd = (math.random()<0.5 and 1 or -1)*(20 + math.random()*22)
        end
        
        if math.random() < dt*1.4 then
            angle = angle + (math.random()-0.5)*math.pi*4
        end
        
        local root = hchar.HumanoidRootPart
        local myroot = mechar.HumanoidRootPart
        
        local rad = 8 + math.sin(angle*4)*2.2
        
        local pitch = (math.sin(angle*2.3)*0.65 + math.sin(angle*0.8)*0.35) * 1.57
        
        local rh = rad * math.cos(pitch)
        local x = rh * math.cos(angle)
        local y = rad * math.sin(pitch)
        local z = rh * math.sin(angle)
        
        local pos = root.Position + Vector3.new(x,y,z)
        
        myroot.CFrame = CFrame.lookAt(pos, root.Position)
        myroot.Velocity = Vector3.zero
        myroot.AngularVelocity = Vector3.zero
    end)
    
    camloop = rs.RenderStepped:Connect(function()
        if not running then return end
        
        local hchar = homer and homer.Character
        if not hchar or not hchar:FindFirstChild("HumanoidRootPart") then return end
        
        local root = hchar.HumanoidRootPart
        local off = root.CFrame.LookVector * -14 + Vector3.new(0,5.5,0)
        local cpos = root.Position + off
        
        cam.CFrame = CFrame.lookAt(cpos, root.Position + Vector3.new(0,3,0))
    end)
end

rs.Heartbeat:Connect(function()
    if running then return end
    
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
        return
    end
    
    local target = gethomer()
    if target then
        task.wait(0.35 + math.random()*0.3)
        dostuff(target)
    end
end)

lp.CharacterAdded:Connect(function()
    stopshit()
end)

stopshit()
