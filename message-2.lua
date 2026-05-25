-- โค้ดเต็มหลังจากแก้ไขฟังก์ชัน Sf:Drive ให้หันหน้าไปตามทิศทางที่เคลื่อนที่จริง
-- (ส่วนอื่น ๆ ไม่เปลี่ยนแปลง ยกเว้นฟังก์ชัน Drive ใน table Sf)

if not game:IsLoaded() then
    repeat
        task.wait()
    until game:IsLoaded()
end

local RS = game:GetService("ReplicatedStorage")

-- ========================================
-- PART 1: Hook TransitionUI
-- ========================================
pcall(
    function()
        local TransitionModule = require(RS.Modules.Game.UI.TransitionUI)
        local old_transition = TransitionModule.transition
        TransitionModule.transition = function(p_in, p_wait, p_out, noLogo)
            task.wait(10)
            return old_transition(p_in, p_wait, p_out, noLogo)
        end
    end
)

-- ========================================
-- PART 2: Hook CharacterCreator
-- ========================================
pcall(
    function()
        local CharCreator = require(RS.Modules.Game.CharacterCreator.CharacterCreator)
        if CharCreator.start then
            local old_start = CharCreator.start
            CharCreator.start = function(...)
                while true do
                    task.wait(1)
                end
            end
        end
        if CharCreator.load_page then
            local old_load = CharCreator.load_page
            CharCreator.load_page = function(...)
                return old_load(...)
            end
        end
        if CharCreator.initiate then
            local old_initiate = CharCreator.initiate
            CharCreator.initiate = function(...)
                return old_initiate(...)
            end
        end
    end
)

-- ========================================
-- PART 3: Hook Character Spawn (สำรอง)
-- ========================================
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

game:GetService("ReplicatedStorage")

-- ========================================
-- วิธีที่ 3: Hook identifyexecutor ก่อนทุกอย่าง
-- ========================================
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

-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PathfindingService = game:GetService('PathfindingService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

-- Modules
local Net = require(ReplicatedStorage.Modules.Core.Net)
local SprintModule = require(ReplicatedStorage.Modules.Game.Sprint)

-- Player References
local Client = Players.LocalPlayer
local Character = Client.Character or Client.CharacterAdded:Wait()
local PlayerGui = Client.PlayerGui
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local UserId = Client.UserId

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
    AutoRepair = false,
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
local function c()
    return Config
end

-- 🔧 ATM Proximity Prompt Distance Modifier
local function ModifyATMPrompts()
    local modifiedCount = 0
    local ATMFolder = workspace:FindFirstChild("Map")
    
    if not ATMFolder then
        return
    end
    
    ATMFolder = ATMFolder:FindFirstChild("Props")
    if not ATMFolder then
        return
    end
    
    ATMFolder = ATMFolder:FindFirstChild("ATMs")
    if not ATMFolder then
        return
    end
    
    for _, descendant in pairs(ATMFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            descendant.MaxActivationDistance = 22
            modifiedCount = modifiedCount + 1
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
    local Holding = Items:FindFirstChild('ItemsHolder').ItemsScrollingFrame
    for _, v in pairs(Holding:GetChildren()) do
        if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
            local itemName = v:FindFirstChild("ItemName")
            if itemName and itemName.Text == w then
                Uid = v.Name
                amount = amount + 1
                IsHaving = true
                Using = v:FindFirstChild('ItemEquipped').Visible
                Drowning = v:FindFirstChild('DestroyedItemIcon').Visible
            elseif v:GetAttribute("ItemType") == "car" or v:GetAttribute("ItemType") == "bike" or v:GetAttribute("ItemType") == "bmx" then
                if v.Name == w then
                    Uid = v.Name
                    amount = amount + 1
                    IsHaving = true
                    Using = v:FindFirstChild('ItemEquipped').Visible
                    Drowning = v:FindFirstChild('DestroyedItemIcon').Visible
                end
            end
        end
    end
    return {amount, IsHaving, Uid, Using, Drowning}
end

function Sf:GetSkill(skillname)
    local OptionsSkill = PlayerGui:FindFirstChild('Skills')
    if not OptionsSkill then return 0 end
    local Holder = OptionsSkill:FindFirstChild('SkillsHolder').SkillsScrollingFrame
    for _, v in pairs(Holder:GetChildren()) do
        if v.Name == "SkillOptionTemplate" then
            if string.find(v:FindFirstChild('SkillTitle').Text, skillname) then
                return tonumber(v:FindFirstChild('SkillTitle').Text:match("%d+"))
            end
        end
    end
    return 0
end

function Sf:CheckingIsMinigame()
    return PlayerGui.SliderMinigame:FindFirstChildOfClass("Frame").Visible
end

function Sf:GetLevel()
    local PlayerGui = Client:WaitForChild("PlayerGui")
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

function Sf:CheckNotificationVisible()
    local notificationTemplate = PlayerGui.Notifications.Frame:FindFirstChild("NotificationTemplate")
    if notificationTemplate then
        return notificationTemplate.Visible
    end
    return false
end

function Sf:HandleDetection(vehicle)
    if not vehicle then return false end
    Humanoid.Sit = false
    task.wait(1.5)
    for _, prompt in pairs(vehicle.PrimaryPart:GetDescendants()) do
        if prompt:IsA('ProximityPrompt') then
            fireproximityprompt(prompt)
        end
    end
    local waitCount = 0
    while not Humanoid.Sit and waitCount < 10 do
        task.wait(0)
        waitCount = waitCount + 1
    end
    return Humanoid.Sit
end

function Sf:GetChipPrice(d)
    return ChipPrice[d] or nil
end

function Sf:ForceStop()
    if c()['Running'] then
        c()["StopWalking"] = true
        task.wait()
        if c()["StopWalking"] then
            task.wait()
            c()["StopWalking"] = false
        end
    end
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

function Sf:GetVehicleHealth(vehicleName)
    local ScrollingFrame = PlayerGui.Items.ItemsHolder.ItemsScrollingFrame
    for _, v in ipairs(ScrollingFrame:GetChildren()) do
        if v:GetAttribute('ItemType') == "car" or v:GetAttribute('ItemType') == "bike" then
            if v.ItemName.Text == vehicleName then
                local healthLabel = v:FindFirstChild("ItemHealth")
                if healthLabel and healthLabel.Text then
                    local current, max = healthLabel.Text:match("(%d+)/(%d+)")
                    return tonumber(current), tonumber(max), v.Name
                end
            end
        end
    end
    return nil, nil, nil
end

function Sf:RepairVehicle(uid)
    if not uid then return false end
    local repairCost = 1000
    if Sf:GetMoney() < repairCost then
        if Sf:ATMMoney() >= repairCost then
            Sf:Ac("transfer_funds", "bank", "hand", repairCost)
            task.wait(0.3)
        else
            return false
        end
    end
    Net.get("repair_vehicle", uid)
    task.wait(0.5)
    return true
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
    for _, atm in pairs(workspace.Map.Props.ATMs:GetChildren()) do
        if atm.Name == "ATM" and atm:IsA("Model") then
            table.insert(all, atm)
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

-- ✅ แก้ไขฟังก์ชัน Drive ให้หันหน้าไปตามทิศทางที่เคลื่อนที่จริง ไม่ใช่ waypoint ถัดไป
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
    
    for i = 1, #waypoints - 1 do
        local startPos = waypoints[i].Position + Vector3.new(0, 5, 0)
        local endPos = waypoints[i + 1].Position + Vector3.new(0, 5, 0)
        DrawPathLine(startPos, endPos)
    end
    
    for i, wp in pairs(waypoints) do
        if not model or not model.PrimaryPart then
            c()['Running'] = false
            ClearPathLines()
            return
        end
        
        local startPos = model:GetPivot().Position
        local heightOffset = 2
        if wp.Action == Enum.PathWaypointAction.Jump then
            heightOffset = 8
        end
        
        local goalPos = wp.Position + Vector3.new(0, heightOffset, 0)
        local dir = (goalPos - startPos).Unit
        local dist = (goalPos - startPos).Magnitude
        local movedDist = 0
        local speed = c().InstantVechineSpeed or 55
        local startTime = tick()
        local lastPos = startPos  -- เก็บตำแหน่งก่อนหน้าเพื่อคำนวณทิศทางเคลื่อนที่
        
        while movedDist < dist and shouldContinue(value) do
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
            
            if self:CheckingIsMinigame() or (t and t:GetAttribute(tostring(c().keys[3]))) or not shouldContinue(value) then
                c()['Running'] = false
                ClearPathLines()
                break
            end
            
            local dt = tick() - startTime
            movedDist = math.min(dt * speed, dist)
            local newPos = startPos + dir * movedDist
            
            -- 🔁 คำนวณทิศทางการเคลื่อนที่จริง (จากตำแหน่งก่อนหน้า)
            local currentPos = model:GetPivot().Position
            local moveDirection = (newPos - currentPos).Unit
            if moveDirection.Magnitude < 0.01 then
                moveDirection = dir
            end
            
            -- 🎯 คำนวณมุม Yaw และหมุนรถตามทิศทางเคลื่อนที่
            local yaw = math.atan2(moveDirection.X, moveDirection.Z)
            local oldYaw = model:GetPivot().Rotation.Y
            local smoothYaw = oldYaw + (yaw - oldYaw) * 0.3   -- ปรับความนุ่มนวล
            local newCFrame = CFrame.new(newPos) * CFrame.Angles(0, smoothYaw, 0)
            model:PivotTo(newCFrame)
            
            -- รีเซ็ตความเร็ว
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                    part.AssemblyLinearVelocity = moveDirection * speed * 0.3
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
            
            lastPos = newPos
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

function Sf:BurgePlace()
    local BurgePlaceBeacon = workspace:FindFirstChild("BurgePlaceBeacon")
    if Client:GetAttribute("Job") ~= "janitor" then
        if self:dist(BurgePlaceBeacon) > 10 then
            RootPart.CFrame = CFrame.new(BurgePlaceBeacon:GetPivot().Position)
        end
        Net.send("apply_for_job", BurgePlaceBeacon)
        local t = tick()
        repeat task.wait(0.5) until Client:GetAttribute("Job") == "janitor" or tick() - t > 10
        return
    end
    local Mop = Client.Backpack:FindFirstChild("Mop") or Character:FindFirstChild("Mop")
    if Mop and Mop.Parent ~= Character then Humanoid:EquipTool(Mop) end
    local Interior = workspace.Map.Tiles.BurgerPlaceTile.BurgerPlace.Interior
    local Puddles = Interior:FindFirstChild("Puddles")
    if not Puddles then return end
    local Puddle = nil
    local shortest = math.huge
    for _, v in pairs(Puddles:GetChildren()) do
        if v:IsA("BasePart") and v.Transparency < 1 then
            local d = self:dist(v)
            if d < shortest then shortest = d Puddle = v end
        end
    end
    if not Puddle then task.wait(1) return end
    repeat
        if Client.Backpack:FindFirstChild("Mop") then
            Humanoid:EquipTool(Client.Backpack:FindFirstChild("Mop"))
        end
        RootPart.CFrame = CFrame.new(Puddle.Position)
        Net.send("start_cleaning_puddle", Puddle)
        task.wait(0.5)
    until Puddle.Transparency >= 0.99 or not Puddle or Humanoid.Health <= 0
end

function Sf:Quick_11()
    local Quick11 = workspace.Map.Tiles.GasStationTile:FindFirstChild("Quick11").Interior
    local Quick11_ATM = Quick11:FindFirstChild("ATM")
    local Quick11Beacon = Quick11:FindFirstChild("Quick11Beacon")
    local Quick11_Door = Quick11.DoorSystem
    if Client:GetAttribute("Job") ~= "shelf_stocker" then
        if self:dist(Quick11_Door:GetPivot()) > 150 then
            RootPart.CFrame = CFrame.new(Quick11_Door:GetPivot().Position)
            return
        end
        Net.send("apply_for_job", Quick11Beacon)
        task.wait(2)
        return
    end
    local ModuleATM = require(ReplicatedStorage.Modules.Game.ATM.ATM)
    local function isATMError(atm)
        for _, v in pairs(ModuleATM.class.objects) do
            if v.instance == atm then return v.states.disabled:get() end
        end
        return nil
    end
    if Sf:GetMoney() >= 100 and not isATMError(Quick11_ATM) then
        RootPart.CFrame = CFrame.new(103, 255, 168)
        Net.get("transfer_funds", "hand", "bank", Sf:GetMoney())
        return
    end
    local ShelfStock = Quick11.ShelfStockingJob
    local L_Box = ShelfStock:FindFirstChild("GoldenBox")
    local TypeBox = tonumber(L_Box.BillboardGui.Frame.StockLeft.Text:match("(%d+)/")) > 0 and "GoldenBox" or "NormalBox"
    local BoxTool = Client.Backpack:FindFirstChild("BoxTool") or Character:FindFirstChild("BoxTool")
    local CanNoclip = Vector3.new(98.5302963256836, 257.29205322265625, 205.9313201904297)
    if not BoxTool then
        if TypeBox == "GoldenBox" then
            local GoldenBoxPart = ShelfStock:FindFirstChild(TypeBox)
            RootPart.CFrame = CFrame.new(CanNoclip)
            task.wait(.5)
            RootPart.CFrame = CFrame.new(CanNoclip - Vector3.yAxis * 20)
            task.wait(.5)
            RootPart.CFrame = CFrame.new(GoldenBoxPart.Position)
            for i = 1, 10 do
                if GoldenBoxPart:FindFirstChild("ProximityPrompt") then
                    fireproximityprompt(GoldenBoxPart.ProximityPrompt)
                end
            end
            RootPart.CFrame = CFrame.new(CanNoclip - Vector3.yAxis * 20)
            task.wait(.5)
            RootPart.CFrame = CFrame.new(CanNoclip)
            task.wait(.5)
            return
        end
        if self:dist(Quick11_Door:GetPivot()) > 20 then
            RootPart.CFrame = CFrame.new(Quick11_Door:GetPivot().Position)
            return
        end
        for i = 1, 8 do
            fireproximityprompt(ShelfStock:FindFirstChild(TypeBox).ProximityPrompt)
        end
        return
    end
    local StandAttachment
    local StartCash = Sf:GetMoney()
    for _, v in pairs(ShelfStock.Shelves:GetChildren()) do
        if v:FindFirstChild("Attachment") then StandAttachment = v.Position break end
    end
    if not StandAttachment then return end
    repeat
        if not BoxTool then break end
        if not Character:FindFirstChild("BoxTool") then Humanoid:EquipTool(BoxTool) end
        if (RootPart.Position - StandAttachment).Magnitude > 2 then
            RootPart.CFrame = CFrame.new(StandAttachment)
        end
        task.wait()
    until Sf:GetMoney() > StartCash or Humanoid.Health <= 0 or not BoxTool
end

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
                                        task.wait(0)
                                    end
                                    do
                                        Humanoid.Sit = false
                                        task.wait()
                                        local atmPos = closestATM.Area.Position
                                        RootPart.CFrame = CFrame.new(atmPos + Vector3.new(0, -3, 0))
                                        RootPart.Anchored = false
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
                                        RootPart.Anchored = false
                                        task.wait(0.2)
                                    end
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

-- ส่วน UI (WindUI)
local v206 = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))():CreateWindow({
    Icon = "https://cdn.discordapp.com/attachments/1379297032568569909/1436623861826457600/93_20251108144920-removebg-preview.png?ex=691047bb&is=690ef63b&hm=0eb04f3e5adc7857237b8f13ed6a4d86864f42aec99e055cc9289ce22a04aed2&",
    Title = "Zenith Hub",
    Icon = "rbxassetid://81469999547026",
    Author = "by #yugiC",
    Folder = "zenith",
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
        Title = "Zenith hub",
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

local Players = game:GetService('Players')
local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild('PlayerGui')

local BankBalance = FarmTab:Button({
    Title = '🏦 Bank Balance',
    Desc = 'N/A'
})
local HandBalance = FarmTab:Button({
    Title = '💸 Hand Balance',
    Desc = 'N/A'
})

local function HandMoney()
    return tonumber(PlayerGui.TopRightHud.Holder.Frame.MoneyTextLabel.Text:match('%$(%d+)'))
end

local function ATMMoney()
    for _, v in ipairs(PlayerGui:GetDescendants()) do
        if v:IsA('TextLabel') and string.find(v.Text, 'Bank Balance') then
            return tonumber(v.Text:match('%$(%d+)'))
        end
    end
    return 0
end

task.spawn(function()
    while task.wait(0.2) do
        BankBalance:SetDesc('<b><font color="#00FF00">$' .. (ATMMoney() or 0) .. '</font></b>')
        HandBalance:SetDesc('<b><font color="#00f2ff">$' .. (HandMoney() or 0) .. '</font></b>')
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
    Title = 'Extra Jobs:'
})

FarmTab:Toggle({
    Title = "Auto Janitor",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        Config.AutoJanitor = Value
    end,
})

FarmTab:Toggle({
    Title = "Auto Quick 11",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        Config.AutoQuick11 = Value
    end,
})

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

task.spawn(function()
    while task.wait(0.2) do
        local ok, err = pcall(function()
            if Config.AutoJanitor then
                Sf:BurgePlace()
            elseif Config.AutoQuick11 then
                Sf:Quick_11()
            end
        end)
        if not ok then warn("Extra Job Error:", err) end
    end
end)

local CharacterTab = Window:Tab({
    Title = 'Character',
    Icon = 'person-standing',
})

CharacterTab:Toggle({
    Title = 'Auto Mask',
    Desc = 'Equip Shiesty',
    Icon = 'check',
    Type = 'Checkbox',
    Callback = function(Value)
        if not Value then
            return
        end
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Player = game.Players.LocalPlayer
        local PlayerGui = Player:WaitForChild("PlayerGui")
        local Net = require(ReplicatedStorage.Modules.Core.Net)
        function GetAllInfos(itemName)
            local infos = {}
            local Items = PlayerGui.Items
            local Holding = Items:FindFirstChild('ItemsHolder').ItemsScrollingFrame
            for _, v in ipairs(Holding:GetChildren()) do
                if v.Name ~= 'Folder' and v.Name ~= 'UIGridLayout' and v.Name ~= "ItemTemplate" then
                    local itemNameLabel = v:FindFirstChild("ItemName")
                    if itemNameLabel and itemNameLabel.Text == itemName then
                        table.insert(infos, {
                            Uid = v.Name,
                            Using = v:FindFirstChild('ItemEquipped').Visible,
                            Drowning = v:FindFirstChild('DestroyedItemIcon').Visible
                        })
                    end
                end
            end
            return infos
        end
        function EquipAccessory(itemName)
            local infos = GetAllInfos(itemName)
            for _, info in ipairs(infos) do
                if not info.Using and not info.Drowning then
                    Net.get("toggle_equip_item", info.Uid)
                    repeat
                        task.wait()
                    until GetAllInfos(itemName)[1].Using
                end
            end
        end
        EquipAccessory("Shiesty")
    end
})

func['AntiDied'] = function()
    while task.wait(0) do 
        if not c().AntiDied then break end
        if not Humanoid or Humanoid.Health <= 0 then continue end
        if Humanoid:GetAttribute('HasBeenDowned') then 
            if not Humanoid:GetAttribute('IsDead') and Humanoid.Health > 0 then
                local deathscreen = PlayerGui:FindFirstChild("DeathScreen")
                if deathscreen then
                    deathscreen = deathscreen:FindFirstChild("DeathScreenHolder")
                    if deathscreen and not deathscreen.Visible then 
                        local Radius = (math.random(1, 100) <= 80) and math.random(-30, -1) or math.random(5, 55)
                        local Gan = math.random(-5, 5)
                        RootPart.Anchored = false 
                        RootPart.CanCollide = false
                        RootPart.CFrame = RootPart.CFrame * CFrame.new(Gan, Radius, Gan)
                        for _, v in pairs(Character:GetChildren()) do 
                            if v:IsA("BasePart") then 
                                v.CanCollide = false 
                                v.Anchored = false 
                                v.CFrame = v.CFrame * CFrame.new(Gan, Radius, Gan)
                            end
                        end
                        EverDown = true
                    end
                end
            else
                EverDown = false 
            end
        else 
            if EverDown and not Humanoid:GetAttribute('IsInCombat') then 
                EverDown = false
            end
        end
    end
end

CharacterTab:Toggle({
    Title = 'Anti Kill',
    Desc = 'Normal PLayer cant Finish',
    Icon = 'check',
    Type = 'Checkbox',
    Value = false,
    Callback = function(state)
        c().AntiDied = state
        if state then
            task.spawn(func['AntiDied'])
        end
    end
})

local EspTab = Window:Tab({
    Title = 'Esp',
    Icon = 'eye',
})

local ATMViewerEnabled = false

local function GetAllATMForViewer()
    local atms = {}
    local atmFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Props") and workspace.Map.Props:FindFirstChild("ATMs")
    if atmFolder then
        for _, atm in pairs(atmFolder:GetChildren()) do
            if atm.Name == "ATM" and atm:IsA("Model") then
                table.insert(atms, atm)
            end
        end
    end
    return atms
end

local function ClearHighlights()
    for _, atm in pairs(GetAllATMForViewer()) do
        local hl = atm:FindFirstChild("ATMViewerHighlight")
        if hl then hl:Destroy() end
        local billboard = atm:FindFirstChild("ATMStatusLabel")
        if billboard then billboard:Destroy() end
    end
end

local function IsATMAvailable(atm)
    local keys = {}
    for k in pairs(atm:GetAttributes()) do
        table.insert(keys, k)
    end
    table.sort(keys)
    if keys[3] and atm:GetAttribute(keys[3]) == false then
        return true
    end
    return false
end

task.spawn(function()
    while task.wait(0) do
        pcall(function()
            if ATMViewerEnabled then
                local AllATM = GetAllATMForViewer()
                for _, atm in pairs(AllATM) do
                    if atm:IsA("Model") then
                        local isAvailable = IsATMAvailable(atm)
                        local existing = atm:FindFirstChild("ATMViewerHighlight")
                        if not existing then
                            local hl = Instance.new("Highlight")
                            hl.Name = "ATMViewerHighlight"
                            hl.Adornee = atm
                            hl.FillColor = Color3.fromRGB(0, 0, 0)
                            hl.FillTransparency = 0.7
                            hl.OutlineTransparency = 0
                            hl.Parent = atm
                            existing = hl
                        end
                        local billboard = atm:FindFirstChild("ATMStatusLabel")
                        if not billboard then
                            billboard = Instance.new("BillboardGui")
                            billboard.Name = "ATMStatusLabel"
                            billboard.Adornee = atm.PrimaryPart or atm:FindFirstChildWhichIsA("BasePart")
                            billboard.Size = UDim2.new(0, 100, 0, 30)
                            billboard.StudsOffset = Vector3.new(0, 2, 0)
                            billboard.AlwaysOnTop = true
                            billboard.Parent = atm
                            local textLabel = Instance.new("TextLabel")
                            textLabel.Name = "StatusText"
                            textLabel.Size = UDim2.new(1, 0, 1, 0)
                            textLabel.BackgroundTransparency = 1
                            textLabel.TextScaled = true
                            textLabel.Font = Enum.Font.GothamBold
                            textLabel.TextStrokeTransparency = 0
                            textLabel.TextSize = 9
                            textLabel.Parent = billboard
                            local corner = Instance.new("UICorner")
                            corner.CornerRadius = UDim.new(0, 8)
                            corner.Parent = textLabel
                        end
                        local statusText = billboard:FindFirstChild("StatusText")
                        existing.FillColor = Color3.fromRGB(0, 0, 0)
                        existing.FillTransparency = 0.7
                        if isAvailable then
                            existing.OutlineColor = Color3.fromRGB(0, 255, 0)
                            existing.OutlineTransparency = 0
                            statusText.Text = "Available"
                            statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
                            statusText.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
                        else
                            existing.OutlineColor = Color3.fromRGB(255, 0, 0)
                            existing.OutlineTransparency = 0
                            statusText.Text = "Hacked"
                            statusText.TextColor3 = Color3.fromRGB(255, 0, 0)
                            statusText.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
                        end
                        existing.Enabled = true
                        billboard.Enabled = true
                    end
                end
            else
                ClearHighlights()
            end
        end)
    end
end)

EspTab:Section({
    Title = 'ATM Viewer:'
})

EspTab:Toggle({
    Title = "ATM Viewer",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        ATMViewerEnabled = Value
        if Value then
            print("ATM Viewer Enabled")
        else
            print("ATM Viewer Disabled")
            ClearHighlights()
        end
    end,
})

local ServerTab = Window:Tab({
    Title = 'Server',
    Icon = 'server',
})

ServerTab:Section({
    Title = 'Server Information:',
})

local function GetJobID()
    return game.JobId or "Unknown"
end

local ServerCodeLabel = ServerTab:Code({
    Title = 'Current Server',
    Code = ''.. GetJobID()
})

ServerTab:Divider()

ServerTab:Section({
    Title = 'Server Utilities:',
})

local ServerCode = ''

ServerTab:Input({
    Title = 'Enter Server Code',
    Placeholder = 'Paste server JobId here...',
    Callback = function(Value)
        ServerCode = Value
    end
})

ServerTab:Button({
    Title = 'Join by Code',
    Icon = 'log-in',
    Callback = function()
        if ServerCode == '' then
            warn('ใส่codeดิน้อง')
            return
        end
        local TeleportService = game:GetService('TeleportService')
        TeleportService:TeleportToPlaceInstance(game.PlaceId, ServerCode, game.Players.LocalPlayer)
    end
})

ServerTab:Button({
    Title = 'Rejoin Current Server',
    Icon = 'refresh-ccw',
    Callback = function()
        local TeleportService = game:GetService('TeleportService')
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end
})

ServerTab:Button({
    Title = 'Hop Server',
    Icon = 'shuffle',
    Callback = function()
        local HttpService = game:GetService('HttpService')
        local TeleportService = game:GetService('TeleportService')
        local servers = {}
        local req = game:HttpGet(string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
        local data = HttpService:JSONDecode(req)
        if data and data.data then
            for _, v in pairs(data.data) do
                if v.playing < v.maxPlayers then
                    table.insert(servers, v.id)
                end
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], game.Players.LocalPlayer)
        end
    end
})
