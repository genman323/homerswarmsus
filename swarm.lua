local keys = {
    ["swarm_344043245"] = true,
    ["swarm_45001484"] = true,
    ["swarm_0013941"] = true
}

if not script_key or not keys[script_key] then
    game.Players.LocalPlayer:Kick("no")
end

if fps then
    local n = tonumber(fps)
    if n and n > 0 then
        if setfpscap then setfpscap(n) end
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Chat = game:GetService("Chat")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local currentHomer = nil
local swarmConnection = nil
local cameraConnection = nil
local isActive = false

local angle = 0
local speed = 0
local lastTime = tick()

local function say(msg)
    if Chat and player.Character and player.Character:FindFirstChild("Head") then
        pcall(function()
            Chat:Chat(player.Character.Head, msg, Enum.ChatColor.Blue)
        end)
    end
end

local function findHomer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player 
           and p.Team 
           and p.Team.Name 
           and string.lower(p.Team.Name):find("homer")
           and p.Character 
           and p.Character:FindFirstChild("HumanoidRootPart")
           and p.Character:FindFirstChild("Humanoid")
           and p.Character.Humanoid.Health > 0 then
            return p
        end
    end
    return nil
end

local function stopSwarm()
    if swarmConnection then swarmConnection:Disconnect() swarmConnection = nil end
    if cameraConnection then cameraConnection:Disconnect() cameraConnection = nil end
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
        char.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    pcall(function()
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = char and char:FindFirstChild("Humanoid")
    end)
    
    if isActive then
        say("Stopped swarming")
    end
    
    isActive = false
    currentHomer = nil
end

local function forcePlatformStand()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = true
        char.Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
    end
end

local function startSwarm(homerPlayer)
    if isActive then return end
    
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    
    currentHomer = homerPlayer
    isActive = true
    
    camera.CameraType = Enum.CameraType.Scriptable
    forcePlatformStand()
    
    say("Swarming " .. homerPlayer.Name .. "!")
    
    task.spawn(function()
        local oldChar = myChar
        while isActive and player.Character == oldChar do
            forcePlatformStand()
            task.wait(0.12)
        end
    end)
    
    angle = math.random() * math.pi * 2
    speed = (math.random() < 0.5 and 1 or -1) * (20 + math.random() * 20)
    lastTime = tick()
    
    swarmConnection = RunService.Heartbeat:Connect(function()
        if not isActive then return end
        
        local homerChar = currentHomer and currentHomer.Character
        if not homerChar or not homerChar.Parent or not homerChar:FindFirstChild("HumanoidRootPart") then
            stopSwarm()
            return
        end
        
        local myCharNow = player.Character
        if not myCharNow or not myCharNow:FindFirstChild("HumanoidRootPart") then
            stopSwarm()
            return
        end
        
        local now = tick()
        local delta = now - lastTime
        lastTime = now
        
        angle = angle + speed * delta * 1.75
        
        if math.random() < delta * 12 then
            speed = (math.random() < 0.5 and 1 or -1) * (20 + math.random() * 22)
        end
        
        if math.random() < delta * 1.4 then
            angle = angle + (math.random() - 0.5) * math.pi * 4
        end
        
        local hrp = homerChar.HumanoidRootPart
        local myHrp = myCharNow.HumanoidRootPart
        
        local radius = 8 + math.sin(angle * 4) * 2.2
        local pitch = (math.sin(angle * 2.3) * 0.65 + math.sin(angle * 0.8) * 0.35) * (math.pi / 2)
        
        local horiz = radius * math.cos(pitch)
        local x = horiz * math.cos(angle)
        local y = radius * math.sin(pitch)
        local z = horiz * math.sin(angle)
        
        local targetPos = hrp.Position + Vector3.new(x, y, z)
        
        myHrp.CFrame = CFrame.lookAt(myHrp.Position, hrp.Position)
        myHrp.CFrame = CFrame.new(targetPos) * (myHrp.CFrame - myHrp.Position)
        
        myHrp.Velocity = Vector3.zero
    end)
    
    cameraConnection = RunService.RenderStepped:Connect(function()
        if not isActive then return end
        
        local homerChar = currentHomer and currentHomer.Character
        if not homerChar or not homerChar:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = homerChar.HumanoidRootPart
        local offset = hrp.CFrame.LookVector * -14 + Vector3.new(0, 5.5, 0)
        local camPos = hrp.Position + offset
        
        camera.CFrame = CFrame.lookAt(camPos, hrp.Position + Vector3.new(0, 3, 0))
    end)
end

task.spawn(function()
    while true do
        if not isActive then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local target = findHomer()
                if target then
                    task.wait(0.35 + math.random() * 0.3)
                    if not isActive and findHomer() == target then
                        startSwarm(target)
                    end
                elseif math.random() < 0.02 then
                    say("Waiting for Homer...")
                end
            end
        end
        task.wait(0.15)
    end
end)

player.CharacterAdded:Connect(function()
    stopSwarm()
end)

stopSwarm()
