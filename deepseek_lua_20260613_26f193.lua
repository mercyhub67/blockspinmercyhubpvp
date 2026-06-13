if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

-- ========================================
-- BYPASS YENIX (นำมาจากไฟล์ข้อความ 4.txt)
-- ========================================
local NotificationLibrary

local Success, Err = pcall(function()
    NotificationLibrary = loadstring(game:HttpGet("https://pastefy.app/aM4rDwB5/raw"))()
end)

if not Success or not NotificationLibrary then
    print('Ssl\nError: ' .. tostring(Err))
end

NotificationLibrary:SendNotification("Success", "Script loading Version 1.11.2", 3)

task.spawn(function()
    local Succ, Err = pcall(function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/cf3b0bdf037787fe1c1ca46fa1ee9b59.lua"))()
    end)
    if not Succ then print(Err) end
end)

local StartTime = os.clock()
repeat task.wait() until (os.clock() - StartTime) > 60 or getgenv().Bypassed

if (os.clock() - StartTime) > 60 then
    return
end

local function c()
    return _G
end

local require = require or getfenv().require 
local hookfunction = hookfunction or getfenv().hookfunction

NotificationLibrary:SendNotification("Success", "Bypass anti cheat success", 3)

-- ========================================
-- ส่วน Hook หลักของ Bypass Yenix
-- ========================================
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local RS = game:GetService("ReplicatedStorage")

pcall(function()
    local TransitionModule = require(RS.Modules.Game.UI.TransitionUI)
    local old_transition = TransitionModule.transition
    TransitionModule.transition = function(p_in, p_wait, p_out, noLogo)
        task.wait(10)
        return old_transition(p_in, p_wait, p_out, noLogo)
    end
end)

pcall(function()
    local CharCreator = require(RS.Modules.Game.CharacterCreator.CharacterCreator)
    if CharCreator.start then
        local old_start = CharCreator.start
        CharCreator.start = function(...)
            while true do
                task.wait(1)
            end
        end
    end
end)

local VehiclesFolder = workspace:WaitForChild("Vehicles")
local protectedVehicles = {}

local function updateVehicleList()
    protectedVehicles = {}
    for _, model in ipairs(VehiclesFolder:GetDescendants()) do
        if model:IsA("VehicleSeat") and model.Name == "DriverSeat" then
            local vehicle = model:FindFirstAncestorOfClass("Model")
            if vehicle then
                protectedVehicles[vehicle] = true
            end
        end
    end
end

updateVehicleList()

local function isProtectedSeat(seat)
    local vehicle = seat:FindFirstAncestorOfClass("Model")
    return vehicle and protectedVehicles[vehicle] == true
end

local function removeSeatIfNotInProtectedVehicle(seat)
    if isProtectedSeat(seat) then
        return
    end
    seat:Destroy()
end

for _, seat in ipairs(workspace:GetDescendants()) do
    if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
        if not isProtectedSeat(seat) then
            removeSeatIfNotInProtectedVehicle(seat)
        end
    end
end

VehiclesFolder.DescendantAdded:Connect(function(obj)
    if obj:IsA("VehicleSeat") and obj.Name == "DriverSeat" then
        updateVehicleList()
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
        if not isProtectedSeat(obj) then
            removeSeatIfNotInProtectedVehicle(obj)
        end
    end
end)

if getgenv then
    getgenv().identifyexecutor = nil
end
if getfenv then
    local env = getfenv()
    env.identifyexecutor = nil
end

local v_u_1 = {}
local v2 = game.ReplicatedStorage:WaitForChild("Remotes")
local v_u_3 = {
    ["send"] = v2:WaitForChild("Send"),
    ["get"] = v2:WaitForChild("Get")
}
local v_u_4 = {
    ["event"] = 0,
    ["func"] = 0
}
local v_u_5 = {}
local v_u_6 = false
local v_u_7 = {}

function v_u_1.on_connect(p8)
    if v_u_6 then
        p8()
    else
        v_u_7[#v_u_7 + 1] = p8
    end
end

function v_u_1.hook(p_u_9, p_u_10)
    if not p_u_10 then
        error("Function nil for hook " .. p_u_9)
    end
    if v_u_6 then
        if v_u_5[p_u_9] then
            warn("Overwriting hook '" .. p_u_9 .. "'.")
        else
            v_u_5[p_u_9] = p_u_10
        end
    else
        v_u_1.on_connect(function()
            v_u_1.hook(p_u_9, p_u_10)
        end)
        return
    end
end

function v_u_1.is_connected(p11)
    return p11:GetAttribute("IsConnected") and true or false
end

local function v_u_19(p12, p13, p14, p15, ...)
    return p12(p13, p14, p15, ...)
end

task.wait(0.1)

local v_u_20 = v_u_3.send
local v_u_21 = v_u_3.send.FireServer

function v_u_1.send(p22, ...)
    v_u_4.event = v_u_4.event + 1
    v_u_21(v_u_20, v_u_4.event, p22, ...)
end

local v_u_23 = v_u_3.get
local v_u_24 = v_u_3.get.InvokeServer

function v_u_1.get(p25, ...)
    v_u_4.func = v_u_4.func + 1
    return v_u_24(v_u_23, v_u_4.func, p25, ...)
end

task.wait(0.1)

local function v_u_29()
    v_u_3.send.OnClientEvent:connect(function(p26, ...)
        if v_u_5[p26] then
            v_u_5[p26](...)
        else
            error("Invalid hook '" .. p26 .. "' fired!", 0)
        end
    end)
    
    function v_u_3.get.OnClientInvoke(p27, ...)
        if v_u_5[p27] then
            return v_u_5[p27](...)
        end
        error("Invalid hook '" .. p27 .. "' invoked!", 0)
    end
    
    if not pcall(function()
        for v28 = 1, #v_u_7 do
            v_u_7[v28]()
        end
    end) then
        pcall(function()
            print("On connect failed for client")
            v_u_1.send("issue", "On connect failed for client")
        end)
    end
end

function v_u_1.initiate() end

function v_u_1.loaded()
    function v_u_3.get.OnClientInvoke(p30)
        if p30 == "connect" then
            v_u_6 = true
            v_u_29()
            return true
        end
    end
    
    v_u_1.hook("ping", function()
        return true
    end)
end

print("bypassed")

-- ========================================
-- ส่วน Modules และ Services
-- ========================================
local PathfindingService = game:GetService('PathfindingService')
local Client = Players.LocalPlayer
local Character = Client.Character or Client.CharacterAdded:Wait()
local PlayerGui = Client.PlayerGui
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local UserId = Client.UserId

local Net = require(ReplicatedStorage.Modules.Core.Net)

Client.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild('Humanoid')
    RootPart = Character:WaitForChild('HumanoidRootPart')
end)

-- Chip Prices
local ChipPrice = {
    ["HackToolBasic"] = 10,
    ["HackToolPro"] = 150,
    ["HackToolUltimate"] = 350,
    ["HackToolQuantum"] = 550
}

local HackToolList = {
    [1] = "HackToolBasic",
    [12] = "HackToolPro",
    [50] = "HackToolUltimate",
    [90] = "HackToolQuantum",
}

-- AutoFarm Configuration
local Config = {
    AutoFarmATM = false,
    EnabledVechine = false,
    EnabledDespoit = false,
    AutoRepair = true,
    SelectSwiperType = "Smart Select",
    SwiperLimit = 3,
    VechineType = "car",
    InstantTeleportSpeed = 35,
    InstantVechineSpeed = 55,
    StopWalking = false,
    Running = false,
    keys = {},
    PathfindingModifierCreater = false,
    EnabledATMViewer = false,
    LastVehicleTeleport = 0,
    AntiDied = false
}

local EverDown = false
local function c() return Config end

-- ATM Proximity Prompt Distance Modifier
local function ModifyATMPrompts()
    local ATMFolder = workspace:FindFirstChild("Map")
    if not ATMFolder then return end
    ATMFolder = ATMFolder:FindFirstChild("Props")
    if not ATMFolder then return end
    ATMFolder = ATMFolder:FindFirstChild("ATMs")
    if not ATMFolder then return end
    
    for _, descendant in pairs(ATMFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            descendant.MaxActivationDistance = 22
        end
    end
end

ModifyATMPrompts()

workspace.Map.Props.ATMs.ChildAdded:Connect(function(child)
    if child.Name == "ATM" then
        task.wait(0.5)
        for _, descendant in pairs(child:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") then
                descendant.MaxActivationDistance = 22
            end
        end
    end
end)

-- Block remote: crashed_car
local SendRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Send")
local oldFireServer
oldFireServer = hookfunction(SendRemote.FireServer, function(self, ...)
    local args = {...}
    if args[2] == "crashed_car" then
        return nil
    end
    return oldFireServer(self, ...)
end)

local Sf = {}
local func = {}

-- Setup Pathfinding Modifiers
do
    if not c().PathfindingModifierCreater then
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "DoorSystem" or v.Name == "BasementDoor" then
                for _, x in ipairs(v:GetDescendants()) do
                    if x:IsA('BasePart') then
                        x.CanCollide = false
                        if not x:FindFirstChildOfClass("PathfindingModifier") then
                            local modifier = Instance.new("PathfindingModifier")
                            modifier.Label = "DoorArea"
                            modifier.PassThrough = true
                            modifier.Parent = x
                        end
                    end
                end
            end
            if v.Name == "VehicleBlockers" then
                v:Destroy()
            end
        end
        
        local nightclubShop = workspace:FindFirstChild("ShopZone_IllegalNightclub")
        if nightclubShop then
            local newCFrame = CFrame.new(1167.5, 255.1586151123047, -355.3337097167969) * CFrame.new(0, 0, 0)
            nightclubShop:PivotTo(newCFrame)
        end
        
        c().PathfindingModifierCreater = true
    end
end

-- Helper Functions
function Sf:dist(Objective)
    return (Objective.Position - RootPart.Position).Magnitude or 0
end

function Sf:GetInfo(w)
    local amount = 0
    local IsHaving = false
    local Uid = nil
    local Using = false
    local Drowning = false
    local Items = PlayerGui.Items
    if not Items then return {0, false, nil, false, false} end
    local Holding = Items:FindFirstChild('ItemsHolder')
    if not Holding then return {0, false, nil, false, false} end
    local ScrollingFrame = Holding:FindFirstChild('ItemsScrollingFrame')
    if not ScrollingFrame then return {0, false, nil, false, false} end
    
    for _, v in pairs(ScrollingFrame:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
            local itemName = v:FindFirstChild("ItemName")
            if itemName and itemName:IsA("TextLabel") and itemName.Text == w then
                Uid = v.Name
                amount = amount + 1
                IsHaving = true
                Using = v:FindFirstChild('ItemEquipped') and v.ItemEquipped.Visible or false
                Drowning = v:FindFirstChild('DestroyedItemIcon') and v.DestroyedItemIcon.Visible or false
            elseif v:GetAttribute("ItemType") == "car" or v:GetAttribute("ItemType") == "bike" or v:GetAttribute("ItemType") == "bmx" then
                if v.Name == w then
                    Uid = v.Name
                    amount = amount + 1
                    IsHaving = true
                    Using = v:FindFirstChild('ItemEquipped') and v.ItemEquipped.Visible or false
                    Drowning = v:FindFirstChild('DestroyedItemIcon') and v.DestroyedItemIcon.Visible or false
                end
            end
        end
    end
    return {amount, IsHaving, Uid, Using, Drowning}
end

function Sf:GetSkill(skillname)
    local OptionsSkill = PlayerGui:FindFirstChild('Skills')
    if not OptionsSkill then return 0 end
    local Holder = OptionsSkill:FindFirstChild('SkillsHolder')
    if not Holder then return 0 end
    local ScrollingFrame = Holder:FindFirstChild('SkillsScrollingFrame')
    if not ScrollingFrame then return 0 end
    for _, v in pairs(ScrollingFrame:GetChildren()) do
        if v.Name == "SkillOptionTemplate" then
            local title = v:FindFirstChild('SkillTitle')
            if title and title.Text and string.find(title.Text, skillname) then
                return tonumber(title.Text:match("%d+")) or 0
            end
        end
    end
    return 0
end

function Sf:CheckingIsMinigame()
    local slider = PlayerGui:FindFirstChild("SliderMinigame")
    if slider then
        local frame = slider:FindFirstChildOfClass("Frame")
        if frame then
            return frame.Visible
        end
    end
    return false
end

function Sf:GetLevel()
    local Skills = PlayerGui:FindFirstChild("Skills")
    if not Skills then return 1 end
    local PlayerCard = Skills:FindFirstChild("SkillsHolder")
    if not PlayerCard then return 1 end
    local ScrollingFrame = PlayerCard:FindFirstChild("SkillsScrollingFrame")
    if not ScrollingFrame then return 1 end
    local Card = ScrollingFrame:FindFirstChild("PlayerCard")
    if not Card then return 1 end
    local Viewport = Card:FindFirstChild("SkillPlayerViewport")
    if not Viewport then return 1 end
    local Frame = Viewport:FindFirstChild("Frame")
    if not Frame then return 1 end
    local LevelCard = Frame:FindFirstChild("ViewportSkillLevelCard")
    if not LevelCard then return 1 end
    local TextLabel = LevelCard:FindFirstChild("TextLabel")
    if not TextLabel then return 1 end
    local levelText = TextLabel.Text
    local level = tonumber(levelText:match("%d+"))
    return level or 1
end

function Sf:Detect()
    for _, v in ipairs(PlayerGui.Notifications.Frame:GetChildren()) do
        if v.Name == "Notification" and v.Text == "Teleport detected" then
            return true
        end
    end
    return nil
end

function Sf:GetMoney()
    return tonumber(PlayerGui.TopRightHud.Holder.Frame.MoneyTextLabel.Text:match("%$(%d+)"))
end

function Sf:ATMMoney()
    for _, v in ipairs(PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and string.find(v.Text, "Bank Balance") then
            return tonumber(v.Text:match("%$(%d+)"))
        end
    end
    return 0
end

function Sf:GetCarFromType(types)
    local ScrollingFrame = PlayerGui.Items.ItemsHolder.ItemsScrollingFrame
    if types == "Bike" then
        for _, v in ipairs(ScrollingFrame:GetChildren()) do
            if v:GetAttribute("ItemType") == "bike" then
                return v.ItemName.Text == "BMX" and "BMX" or v.ItemName.Text
            end
        end
    else
        for _, v in ipairs(ScrollingFrame:GetChildren()) do
            if v:GetAttribute('ItemType') == "car" then
                return v.ItemName.Text
            end
        end
    end
    return nil
end

function Sf:GetChipFromType(types)
    local chip
    if Sf:GetLevel() >= 10 then
        if tostring(types) == "Smart Select" then
            local SwipperSkill = Sf:GetSkill("Swiper")
            for i, v in pairs(HackToolList) do
                if SwipperSkill >= i then
                    chip = v
                end
            end
        else
            for _, v in pairs(HackToolList) do
                if tostring(v) == tostring(types) then
                    chip = v
                end
            end
        end
    else
        chip = "Level"
    end
    return chip or "HackToolBasic"
end

function Sf:Ac(...)
    return Net.send(...)
end

local function shouldContinue(value)
    if value == nil then
        return c().AutoFarmATM
    end
    return value
end

local function GetAllATM()
    local all = {}
    local atmFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Props") and workspace.Map.Props:FindFirstChild("ATMs")
    if atmFolder then
        for _, atm in pairs(atmFolder:GetChildren()) do
            if atm.Name == "ATM" and atm:IsA("Model") then
                table.insert(all, atm)
            end
        end
    end
    return all
end

local PathPartsFolder = workspace:FindFirstChild("PathLines") or Instance.new("Folder", workspace)
PathPartsFolder.Name = "PathLines"

function DrawPathLine(startPos, endPos)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(0, 255, 255)
    part.Transparency = 0.3
    local distance = (startPos - endPos).Magnitude
    part.Size = Vector3.new(0.3, 0.3, distance)
    part.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
    part.Parent = PathPartsFolder
    
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Color = Color3.fromRGB(0, 255, 255)
    light.Range = 5
    light.Parent = part
    
    return part
end

function ClearPathLines()
    for _, v in pairs(PathPartsFolder:GetChildren()) do
        v:Destroy()
    end
end

function Sf:Teleport(destination, value, t)
    c().StopWalking = false
    c()['Running'] = true
    ClearPathLines()
    
    local char = Client.Character or Client.CharacterAdded:Wait()
    local RootPart = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    local path = PathfindingService:CreatePath({
        AgentCanJump = true,
        AgentJumpHeight = 2.5,
        AgentHeight = 8,
        AgentRadius = 2.5,
        AgentMaxSlope = 90,
        Costs = {BlockedNode = 50, DoorArea = 1}
    })
    
    local success = pcall(function()
        path:ComputeAsync(RootPart.Position, destination)
    end)
    
    if not success then
        c()['Running'] = false
        ClearPathLines()
        return
    end
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for i = 1, #waypoints - 1 do
            local startPos = waypoints[i].Position + Vector3.new(0, 3, 0)
            local endPos = waypoints[i + 1].Position + Vector3.new(0, 3, 0)
            DrawPathLine(startPos, endPos)
        end
        
        for _, wp in pairs(waypoints) do
            local offsetY = (wp.Action == Enum.PathWaypointAction.Jump) and 10 or 4
            local targetPos = wp.Position + Vector3.new(0, offsetY, 0)
            local startPos = RootPart.Position
            local dir = (targetPos - startPos).Unit
            local dist = (targetPos - startPos).Magnitude
            local movedDist = 0
            local speed = c().InstantTeleportSpeed or 30
            local startTime = tick()
            
            while movedDist < dist and not c().StopWalking and shouldContinue(value) do
                task.wait()
                c()['Running'] = true
                
                if c().StopWalking or not shouldContinue(value) or Humanoid.Health <= 0 then
                    c()['Running'] = false
                    ClearPathLines()
                    break
                end
                
                if self:Detect() then
                    c()['Running'] = false
                    ClearPathLines()
                    return self:Teleport(destination, value, t)
                end
                
                if (t and t:GetAttribute(c().keys[3])) then
                    c()['Running'] = false
                    ClearPathLines()
                    break
                end
                
                if t and self:CheckingIsMinigame() then
                    c()['Running'] = false
                    ClearPathLines()
                    return self:Teleport(destination, value, t)
                end
                
                local elapsedTime = tick() - startTime
                movedDist = math.min(elapsedTime * speed, dist)
                local newPos = startPos + dir * movedDist
                
                if Humanoid.Sit then
                    Humanoid.Sit = false
                end
                
                RootPart:PivotTo(CFrame.new(newPos))
                Sf:Ac("set_sprinting_1", true)
            end
            
            c()['Running'] = false
            if not shouldContinue(value) then
                ClearPathLines()
                break
            end
        end
        
        ClearPathLines()
    end
    c()['Running'] = false
end

function Sf:Drive(model, destination, value, t)
    if not model or not model.PrimaryPart then
        c()['Running'] = false
        return
    end
    c()["StopWalking"] = false
    ClearPathLines()

    local path = PathfindingService:CreatePath({
        AgentRadius = c().VechineType == "car" and 6 or 3.5,
        AgentHeight = 8,
        AgentCanJump = true,
        AgentMaxSlope = 50,
        AgentCanClimb = false,
        WaypointSpacing = 8,
        Costs = {
            BlockedNode = 100,
            Cars = 1,
            Water = math.huge,
            DoorArea = 1
        }
    })

    local success = pcall(function()
        path:ComputeAsync(model.PrimaryPart.Position, destination)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        c()['Running'] = false
        ClearPathLines()
        return
    end

    local waypoints = path:GetWaypoints()
    if #waypoints < 2 then
        c()['Running'] = false
        ClearPathLines()
        return
    end

    for i = 1, #waypoints - 1 do
        local startPos = waypoints[i].Position + Vector3.new(0, 5, 0)
        local endPos = waypoints[i+1].Position + Vector3.new(0, 5, 0)
        DrawPathLine(startPos, endPos)
    end

    for i, wp in pairs(waypoints) do
        if not model or not model.PrimaryPart then
            c()['Running'] = false
            ClearPathLines()
            return
        end

        local heightOffset = (wp.Action == Enum.PathWaypointAction.Jump) and 8 or 2
        local goalPos = wp.Position + Vector3.new(0, heightOffset, 0)

        local distToGoal = (goalPos - model:GetPivot().Position).Magnitude
        local speed = c().InstantVechineSpeed or 55
        local startTime = tick()

        while distToGoal > 0.5 and shouldContinue(value) do
            task.wait()
            if not model or not model.PrimaryPart then
                c()['Running'] = false
                ClearPathLines()
                return
            end
            c()['Running'] = true

            if not shouldContinue(value) then
                c()['Running'] = false
                ClearPathLines()
                break
            end

            if self:Detect() then
                c()['Running'] = false
                ClearPathLines()
                return self:Drive(model, destination, value, t)
            end

            if not Humanoid.Sit then
                c()['Running'] = false
                ClearPathLines()
                return self:Drive(model, destination, value, t)
            end

            if self:CheckingIsMinigame() or (t and t:GetAttribute(tostring(c().keys[3]))) then
                c()['Running'] = false
                ClearPathLines()
                break
            end

            local now = tick()
            local dt = math.min(0.1, now - startTime)
            startTime = now

            local currentPos = model:GetPivot().Position
            local moveDelta = goalPos - currentPos
            local moveDirection = moveDelta.Unit
            local step = speed * dt

            local newPos
            if moveDelta.Magnitude <= step then
                newPos = goalPos
                distToGoal = 0
            else
                newPos = currentPos + moveDirection * step
                distToGoal = (goalPos - newPos).Magnitude
            end

            local horizontalDir = Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit
            local newCFrame
            if horizontalDir.Magnitude > 0.01 then
                newCFrame = CFrame.lookAt(newPos, newPos + horizontalDir, Vector3.new(0, 1, 0))
            else
                newCFrame = CFrame.new(newPos)
            end
            model:PivotTo(newCFrame)

            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end

        c()['Running'] = false
        if not shouldContinue(value) then
            ClearPathLines()
            break
        end
    end

    ClearPathLines()
    c()['Running'] = false
end

function Sf:ExitVehicle()
    if not Humanoid.Sit then return true end
    Humanoid.Sit = false
    task.wait(0.2)
    if Humanoid.Sit then
        for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
            if vehicle:GetAttribute('OwnerUserId') == UserId and vehicle.PrimaryPart then
                for _, prompt in pairs(vehicle.PrimaryPart:GetDescendants()) do
                    if prompt:IsA('ProximityPrompt') then
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
    local timeout = 0
    while Humanoid.Sit and timeout < 1.5 do
        task.wait(0.05)
        timeout = timeout + 0.05
    end
    return not Humanoid.Sit
end

function Sf:SnapToGround(object, offsetY)
    local primary = object.PrimaryPart or (object:IsA("BasePart") and object) or nil
    if not primary then return end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {object, Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local origin = primary.Position + Vector3.new(0, 2, 0)
    local ray = workspace:Raycast(origin, Vector3.new(0, -50, 0), rayParams)
    if ray then
        local groundY = ray.Position.Y + (offsetY or 2)
        local newPos = Vector3.new(primary.Position.X, groundY, primary.Position.Z)
        object:PivotTo(CFrame.new(newPos) * (object:GetPivot().Rotation))
    end
end

function Sf:FindClosestAvailableATM()
    local closestATM, shortestDist = nil, math.huge
    for _, atm in ipairs(workspace.Map.Props.ATMs:GetChildren()) do
        if atm.Name == "ATM" then
            local keys = {}
            for k in pairs(atm:GetAttributes()) do
                table.insert(keys, k)
            end
            table.sort(keys)
            if keys[3] and atm:GetAttribute(keys[3]) == false then
                local d = self:dist(atm.Area.CFrame)
                if d < shortestDist then
                    closestATM = atm
                    shortestDist = d
                end
            end
        end
    end
    return closestATM
end

local SafeHeight = {
    MinCharacter = 200,
    MinVehicle = 200,
    Emergency = 50,
    RespawnHeight = 260
}

task.spawn(function()
    while task.wait(0) do
        pcall(function()
            if not c().AutoFarmATM then return end
            for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
                if vehicle:GetAttribute('OwnerUserId') == UserId and vehicle.PrimaryPart then
                    local currentY = vehicle.PrimaryPart.Position.Y
                    
                    for _, part in pairs(vehicle:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if part.AssemblyLinearVelocity.Magnitude > 100 then
                                part.AssemblyLinearVelocity = part.AssemblyLinearVelocity.Unit * 100
                            end
                            local verticalVelocity = part.AssemblyLinearVelocity.Y
                            if verticalVelocity > 15 then
                                part.AssemblyLinearVelocity = Vector3.new(
                                    part.AssemblyLinearVelocity.X,
                                    -5,
                                    part.AssemblyLinearVelocity.Z
                                )
                            end
                            if math.abs(part.AssemblyAngularVelocity.X) > 5 or math.abs(part.AssemblyAngularVelocity.Z) > 5 then
                                part.AssemblyAngularVelocity = Vector3.new(0, part.AssemblyAngularVelocity.Y, 0)
                            end
                        end
                    end
                    
                    local downforce = 15
                    local maxHeightAboveGround = 8
                    local rayOrigin = vehicle.PrimaryPart.Position
                    local rayDirection = Vector3.new(0, -100, 0)
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {vehicle, Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                    if rayResult then
                        local distanceToGround = (rayOrigin - rayResult.Position).Magnitude
                        if distanceToGround > maxHeightAboveGround then
                            for _, part in pairs(vehicle:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.AssemblyLinearVelocity = Vector3.new(
                                        part.AssemblyLinearVelocity.X,
                                        -downforce,
                                        part.AssemblyLinearVelocity.Z
                                    )
                                end
                            end
                        end
                    end
                    
                    if currentY < SafeHeight.Emergency then
                        vehicle:PivotTo(RootPart.CFrame * CFrame.new(0, 10, 0))
                        for _, part in pairs(vehicle:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Velocity = Vector3.zero
                                part.RotVelocity = Vector3.zero
                                part.AssemblyLinearVelocity = Vector3.zero
                                part.AssemblyAngularVelocity = Vector3.zero
                                part.Anchored = true
                                task.wait(0)
                                part.Anchored = false
                            end
                        end
                    elseif currentY < SafeHeight.MinVehicle then
                        local targetPos = Vector3.new(
                            vehicle.PrimaryPart.Position.X,
                            SafeHeight.RespawnHeight,
                            vehicle.PrimaryPart.Position.Z
                        )
                        vehicle:PivotTo(CFrame.new(targetPos) * vehicle:GetPivot().Rotation)
                        for _, part in pairs(vehicle:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Velocity = Vector3.zero
                                part.RotVelocity = Vector3.zero
                                part.AssemblyLinearVelocity = Vector3.zero
                                part.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0) do
        pcall(function()
            if not Character or not RootPart then return end
            if not c().AutoFarmATM then return end
            local currentY = RootPart.Position.Y
            if currentY < SafeHeight.Emergency then
                RootPart.Anchored = true
                RootPart.CFrame = CFrame.new(
                    RootPart.Position.X,
                    SafeHeight.RespawnHeight,
                    RootPart.Position.Z
                )
                task.wait(0)
                RootPart.Anchored = false
            elseif currentY < SafeHeight.MinCharacter then
                RootPart.CFrame = CFrame.new(
                    RootPart.Position.X,
                    SafeHeight.RespawnHeight,
                    RootPart.Position.Z
                )
                if RootPart.AssemblyLinearVelocity.Y < -50 then
                    RootPart.AssemblyLinearVelocity = Vector3.new(
                        RootPart.AssemblyLinearVelocity.X,
                        0,
                        RootPart.AssemblyLinearVelocity.Z
                    )
                end
            end
        end)
    end
end)

func['AutoFarmATM'] = function()
    local playerLevel = Sf:GetLevel()
    if playerLevel < 10 then
        repeat task.wait(5) until false
        return
    end
    
    while task.wait(0) do
        if not c().AutoFarmATM then
            Sf:ForceStop()
            break
        end
        
        local vehicleName = Sf:GetCarFromType(c().VechineType)
        if not vehicleName then
            if not c().AutoFarmATM then break end
            task.wait(0)
            continue
        end
        
        local existingVehicle = nil
        for _, vehicle in ipairs(workspace.Vehicles:GetChildren()) do
            if vehicle:GetAttribute('OwnerUserId') == UserId then
                existingVehicle = vehicle
                break
            end
        end
        
        if not existingVehicle then
            local Checker = Sf:GetInfo(vehicleName)
            if Checker[2] and not Checker[4] and not Checker[5] then
                Net.get("toggle_equip_item", tostring(Checker[3]))
                task.wait(0.5)
            elseif Checker[5] then
                task.wait(3)
                if not c().AutoFarmATM then break end
                continue
            elseif not Checker[2] then
                task.wait(1)
                continue
            end
        end
        
        local foundVehicle = false
        for _, vehicle in ipairs(workspace.Vehicles:GetChildren()) do
            if not c().AutoFarmATM then
                foundVehicle = true
                break
            end
            
            if vehicle:GetAttribute('OwnerUserId') == UserId then
                if Sf:CheckingIsMinigame() then
                    task.wait(1)
                    continue
                end
                if Sf:Detect() then
                    task.wait(1)
                    continue
                end
                Sf:Ac("lock_vehicle", vehicle, true)
                foundVehicle = true
                
                if not Humanoid.Sit then
                    if not c().AutoFarmATM then break end
                    local currentTime = tick()
                    if currentTime - c().LastVehicleTeleport >= 0.5 then
                        local charLook = RootPart.CFrame.LookVector
                        local vehicleRotation = CFrame.new(RootPart.Position + Vector3.new(0, 7, 0)) * CFrame.Angles(0, math.atan2(charLook.X, charLook.Z), 0)
                        vehicle:PivotTo(vehicleRotation)
                        c().LastVehicleTeleport = currentTime
                        task.wait(0)
                    end
                    for _, prompt in pairs(vehicle.PrimaryPart:GetDescendants()) do
                        if prompt:IsA('ProximityPrompt') then
                            fireproximityprompt(prompt)
                            task.wait(0)
                        end
                    end
                end
                
                local waitCount = 0
                while not Humanoid.Sit and waitCount < 10 and c().AutoFarmATM do
                    task.wait(0)
                    waitCount = waitCount + 1
                end
                if not Humanoid.Sit then
                    task.wait(1)
                    continue
                end
                
                if not c().AutoFarmATM then break end
                
                if Humanoid.Sit then
                    if c().AutoRepair then
                        local currentHP, maxHP, vehicleUID = Sf:GetVehicleHealth(vehicleName)
                        if currentHP and maxHP then
                            local hpDifference = maxHP - currentHP
                            if hpDifference >= 1000 then
                                Humanoid.Sit = false
                                task.wait(0.3)
                                if Sf:RepairVehicle(vehicleUID) then
                                    task.wait(0.5)
                                    for _, prompt in pairs(vehicle.PrimaryPart:GetDescendants()) do
                                        if prompt:IsA('ProximityPrompt') then
                                            fireproximityprompt(prompt)
                                            task.wait(0.1)
                                        end
                                    end
                                    local waitCount2 = 0
                                    while not Humanoid.Sit and waitCount2 < 10 do
                                        task.wait(0.1)
                                        waitCount2 = waitCount2 + 1
                                    end
                                end
                            end
                        end
                    end
                    
                    if Humanoid.Sit then
                        local currentHackTool = Sf:GetChipFromType(c().SelectSwiperType)
                        local SwiperMoney = Sf:GetChipPrice(currentHackTool) * c().SwiperLimit
                        local hacktool = Sf:GetInfo(currentHackTool)
                        
                        if currentHackTool == "Level" then
                            task.wait(0.5)
                        elseif not hacktool[2] then
                            if not c().AutoFarmATM then break end
                            if Sf:GetMoney() < SwiperMoney then
                                if Sf:ATMMoney() >= SwiperMoney then
                                    local closestATM = Sf:FindClosestAvailableATM()
                                    if closestATM and c().AutoFarmATM then
                                        local dist = Sf:dist(closestATM.Area)
                                        if dist > 15 then
                                            Sf:Drive(vehicle, closestATM.Area.Position, c().AutoFarmATM, closestATM)
                                            if not c().AutoFarmATM then break end
                                            task.wait(0)
                                        else
                                            RootPart.Anchored = true
                                            task.wait(0)
                                            local currentMoney = Sf:GetMoney()
                                            local chipPrice = Sf:GetChipPrice(currentHackTool)
                                            local totalNeeded = chipPrice * c().SwiperLimit
                                            local currentAmount = Sf:GetInfo(currentHackTool)[1] or 0
                                            local needToBuy = math.max(0, c().SwiperLimit - currentAmount)
                                            local actualNeeded = chipPrice * needToBuy
                                            local moneyNeeded = math.max(0, actualNeeded - currentMoney)
                                            if moneyNeeded > 0 then
                                                local bankMoney = Sf:ATMMoney()
                                                if bankMoney >= moneyNeeded then
                                                    Sf:Ac("transfer_funds", "bank", "hand", moneyNeeded)
                                                    task.wait(0)
                                                end
                                            end
                                            RootPart.Anchored = false
                                            task.wait(0)
                                        end
                                    end
                                else
                                    task.wait(2)
                                end
                            else
                                if not c().AutoFarmATM then break end
                                local shopPos
                                local shopZone
                                if currentHackTool == "HackToolQuantum" then
                                    shopZone = workspace:FindFirstChild("ShopZone_IllegalNightclub")
                                    if shopZone then
                                        shopPos = shopZone:IsA("BasePart") and shopZone.Position or shopZone:GetPivot().Position
                                    else
                                        shopPos = Vector3.new(1168.73132, 256.449524, -347.701691)
                                    end
                                else
                                    shopZone = workspace:FindFirstChild("ShopZone_Illegal")
                                    if shopZone then
                                        shopPos = shopZone:IsA("BasePart") and shopZone.Position or shopZone:GetPivot().Position
                                    else
                                        local spinClub = workspace.Map.SpinClub.Exterior:GetChildren()[8]
                                        if spinClub then
                                            shopPos = spinClub:IsA("BasePart") and spinClub.Position or spinClub:GetPivot().Position
                                        else
                                            shopPos = Vector3.new(-212.181717, 255.525162, 387.744324)
                                        end
                                    end
                                end
                                if not shopZone then
                                    task.wait(1)
                                else
                                    local reachedShop = false
                                    while not reachedShop and c().AutoFarmATM do
                                        local dist = Sf:dist(CFrame.new(shopPos))
                                        if dist > 20 then
                                            Sf:Drive(vehicle, shopPos, c().AutoFarmATM)
                                            if not c().AutoFarmATM then break end
                                            task.wait(0)
                                            local newDist = Sf:dist(CFrame.new(shopPos))
                                            if newDist <= 20 then
                                                reachedShop = true
                                            end
                                        else
                                            reachedShop = true
                                        end
                                    end
                                    if reachedShop and c().AutoFarmATM then
                                        local maxRetries = 10
                                        local retryCount = 0
                                        while retryCount < maxRetries and c().AutoFarmATM do
                                            local currentAmount = Sf:GetInfo(currentHackTool)[1]
                                            local needToBuy = c().SwiperLimit - currentAmount
                                            if needToBuy <= 0 then
                                                break
                                            end
                                            if Sf:GetMoney() < Sf:GetChipPrice(currentHackTool) then
                                                break
                                            end
                                            for i = 1, needToBuy do
                                                if not c().AutoFarmATM then break end
                                                if Sf:GetMoney() >= Sf:GetChipPrice(currentHackTool) then
                                                    Net.get("purchase_consumable", shopZone, currentHackTool)
                                                    task.wait(0)
                                                else
                                                    break
                                                end
                                            end
                                            task.wait(0)
                                            local newAmount = Sf:GetInfo(currentHackTool)[1]
                                            if newAmount >= c().SwiperLimit then
                                                break
                                            end
                                            retryCount = retryCount + 1
                                        end
                                    end
                                end
                            end
                        elseif hacktool[1] > 0 then
                            if not c().AutoFarmATM then break end
                            local closestATM = Sf:FindClosestAvailableATM()
                            if closestATM and c().AutoFarmATM then
                                c().keys = {}
                                for k in pairs(closestATM:GetAttributes()) do
                                    table.insert(c().keys, k)
                                end
                                table.sort(c().keys)
                                if not closestATM:GetAttribute(c().keys[3]) then
                                    local dist = Sf:dist(closestATM.Area)
                                    if dist > 12 then
                                        Sf:Drive(vehicle, closestATM.Area.Position, c().AutoFarmATM, closestATM)
                                        if not c().AutoFarmATM then break end
                                        task.wait(0.5)
                                    end
                                    local exited = Sf:ExitVehicle()
                                    if not exited then
                                        task.wait(0.5)
                                        Sf:ExitVehicle()
                                    end
                                    task.wait(0.1)
                                    local atmPos = closestATM.Area.Position
                                    local groundCheck = workspace:Raycast(atmPos + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0))
                                    local standPos = Vector3.new(atmPos.X, (groundCheck and groundCheck.Position.Y or atmPos.Y) + 3, atmPos.Z)
                                    RootPart.CFrame = CFrame.new(standPos)
                                    RootPart.Anchored = false
                                    task.wait(0.1)
                                    if c().EnabledDespoit and Sf:GetMoney() > 0 then
                                        Net.get("transfer_funds", "hand", "bank", Sf:GetMoney())
                                        task.wait(0)
                                    end
                                    if not Sf:CheckingIsMinigame() and c().AutoFarmATM then
                                        Sf:Ac("request_begin_hacking_3", closestATM, currentHackTool)
                                        task.wait(1)
                                    end
                                    if c().AutoFarmATM then
                                        Sf:Ac("atm_win_3", closestATM)
                                        task.wait(1)
                                    end
                                    Sf:SnapToGround(vehicle, 2)
                                end
                            else
                                task.wait(1)
                            end
                        end
                    end
                    break
                end
            end
        end
        
        if not foundVehicle then
            task.wait(1)
        end
        
        if not c().AutoFarmATM then
            Sf:ForceStop()
            break
        end
    end
    
    Sf:ForceStop()
    ClearPathLines()
end

-- UI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "MERCY HUB (Yenix Bypass)",
    Author = "by #yugiC",
    Folder = "mercy",
    Size = UDim2.fromOffset(400, 400),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Red",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    OpenButton = {
        Title = "MERCY HUB",
        Icon = "rbxassetid://81469999547026",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false
    }
})

Window:Tag({
    Title = 'ATM Only',
    Color = Color3.fromHex('#30ff6a'),
    Radius = 13,
})

local FarmTab = Window:Tab({
    Title = 'Farm',
    Icon = 'car',
})

FarmTab:Section({
    Title = 'Information:'
})

local BankBalance = FarmTab:Button({
    Title = '🏦 Bank Balance',
    Desc = 'N/A'
})
local HandBalance = FarmTab:Button({
    Title = '💸 Hand Balance',
    Desc = 'N/A'
})

local function HandMoneyUI()
    return tonumber(PlayerGui.TopRightHud.Holder.Frame.MoneyTextLabel.Text:match('%$(%d+)'))
end

local function ATMMoneyUI()
    for _, v in ipairs(PlayerGui:GetDescendants()) do
        if v:IsA('TextLabel') and string.find(v.Text, 'Bank Balance') then
            return tonumber(v.Text:match('%$(%d+)'))
        end
    end
    return 0
end

task.spawn(function()
    while task.wait(0.2) do
        BankBalance:SetDesc('<b><font color="#00FF00">$' .. (ATMMoneyUI() or 0) .. '</font></b>')
        HandBalance:SetDesc('<b><font color="#00f2ff">$' .. (HandMoneyUI() or 0) .. '</font></b>')
    end
end)

local PlayerLevelLabel = FarmTab:Button({
    Title = 'Player Level',
    Desc = 'Loading...'
})

task.spawn(function()
    while task.wait(1) do
        local level = Sf:GetLevel()
        if level < 10 then
            PlayerLevelLabel:SetDesc('<b><font color="#FF4444">Lv. ' .. level .. ' (Need level 10+)</font></b>')
        else
            PlayerLevelLabel:SetDesc('<b><font color="#44FF44">Lv. ' .. level .. '</font></b>')
        end
    end
end)

FarmTab:Section({
    Title = 'Job:'
})

FarmTab:Toggle({
    Title = "AutoFarm",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        Config.AutoFarmATM = Value
        Config.EnabledVechine = Value  
        Config.EnabledDespoit = Value
        if Value then
            task.spawn(func["AutoFarmATM"])
        else
            Sf:ForceStop()
            ClearPathLines()
        end
    end,
})

FarmTab:Section({
    Title = "Setting:",
})

FarmTab:Dropdown({
    Title = "Swiper Type",
    Values = {
        "Smart Select",
        "HackToolBasic",
        "HackToolPro",
        "HackToolUltimate",
        "HackToolQuantum"
    },
    Value = "Smart Select",
    Callback = function(Value)
        Config.SelectSwiperType = Value
    end,
})

FarmTab:Dropdown({
    Title = "Vehicle Type",
    Values = {
        "Bike",
        "Car"
    },
    Value = "Bike",
    Callback = function(Value)
        Config.VechineType = Value
    end,
})

FarmTab:Slider({
    Title = "Swiper Limit",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = 3
    },
    Callback = function(Value)
        Config.SwiperLimit = Value
    end,
})

FarmTab:Slider({
    Title = "Vehicle Speed",
    Step = 1,
    Value = {
        Min = 10,
        Max = 350,
        Default = 60
    },
    Callback = function(Value)
        Config.InstantVechineSpeed = Value
    end,
})

task.spawn(func["AutoFarmATM"])