-- ============================================================
--  MYSTIC HUB | Block Spin | Paid
--  Cleaned & Deobfuscated by formatter
-- ============================================================
local SERVICE_ID = "22934"
local API_KEY = "19d0ed2a-7f57-41cf-9f63-f089d56f570a"
local WEBHOOK = "https://discord.com/api/webhooks/1504823602560634972/09wWwv1wOIRlSo_zeqUFxtAsxWLhJ70YPcHlEL4NThoM5ZKg-VVfzLm3S8P0LkYzKNQZ"

pcall(function()
    local HttpService = game:GetService("HttpService")
    local player = game:GetService("Players").LocalPlayer
    local UIS = game:GetService("UserInputService")
    local hwid = pcall(gethwid) and gethwid() or "Unknown"
    local executor = identifyexecutor and identifyexecutor() or "Unknown"
    local platform = UIS.TouchEnabled and not UIS.KeyboardEnabled and "Mobile" or "PC"

    local data = {
        embeds = {{
            title = "🔐 Script Executed",
            color = 0x7000FF,
            thumbnail = {
                url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            },
            fields = {
                { name = "User",     value = player.Name, inline = true },
                { name = "Executor", value = executor,    inline = true },
                { name = "Platform", value = platform,    inline = true },
                { name = "HWID",     value = hwid,        inline = false },
            },
            footer = { text = "Mercyhub | " .. os.date("%d/%m/%Y %H:%M:%S") }
        }}
    }

    request({
        Url = WEBHOOK,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(data)
    })
end)

-- ── Services ─────────────────────────────────────────────────
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local Debris              = game:GetService("Debris")
local Workspace           = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")

-- ── Remotes / Modules ────────────────────────────────────────
local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local Util          = require(ReplicatedStorage.Modules.Core.Util)
local BuyPromptUI   = require(ReplicatedStorage.Modules.Game.UI.BuyPromptUI)
local EmotesUI      = require(ReplicatedStorage.Modules.Game.Emotes.EmotesUI)
local EmotesList    = require(ReplicatedStorage.Modules.Game.Emotes.EmotesList)
local CoreUI        = require(ReplicatedStorage.Modules.Core.UI)
local CharModule    = require(ReplicatedStorage.Modules.Core.Char)
local Items         = ReplicatedStorage:WaitForChild("Items")
local MeleeItems    = Items:WaitForChild("melee")

-- ── Local Player / Character ──────────────────────────────────
local LocalPlayer  = Players.LocalPlayer
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid     = Character:WaitForChild("Humanoid")
local HRP          = Character:WaitForChild("HumanoidRootPart")
local Camera       = Workspace.CurrentCamera

-- ── Misc Setup ───────────────────────────────────────────────
local isMobile        = false
local DroppedItems    = Workspace:WaitForChild("DroppedItems")
local itemDrawings    = {}    -- DroppedItem ESP drawings
local espData         = {}    -- Player ESP data
local positionHistory = {}    -- Velocity prediction history
local WeaponRegistry  = {}    -- Registered weapon info
local PlayerBillboards = {}   -- Inventory billboard GUIs
local highlightTable  = {}    -- Player highlights
local excludedPlayers = {}    -- Whitelist table
local itemPickupTrack = {}    -- Last pickup time per item
local originalAttribs = {}    -- Saved melee attributes

-- ── State Variables ──────────────────────────────────────────
local silentAimEnabled    = false
local redLineLockEnabled  = false
local fovRadius           = 120
local targetPlayer        = nil
local aimTarget           = nil

local nameESPEnabled      = false
local distanceESPEnabled  = false
local healthESPEnabled    = false
local inventoryESPEnabled = false
local highlightEnabled    = false

local walkSpeedEnabled    = false
local speedMultiplier     = 0.05
local jumpPowerEnabled    = false

local infiniteStaminaEnabled = false
local antiLockEnabled     = false
local antiKillEnabled     = false  -- "enabled" global
local autoPickupEnabled   = false
local antiRagdollEnabled  = false
local autoRespawnEnabled  = false
local autoFinishEnabled   = false
local meleeAuraEnabled    = false
local autoAttackEnabled   = false
local skipCrateEnabled    = false

local snapUnderMapEnabled = false
local snapActive          = false
local snapY               = nil
local snapDepth           = 10
local snapClickCount      = 0
local underMapPos         = nil
local isFlickering        = false

function isInCameraView(camera, object)
    if object:IsA("BasePart") then
        local objectPosition = object.Position
        local screenPosition, isOnScreen = camera:WorldToViewportPoint(objectPosition)
        return isOnScreen
    end
    return false
end

function loadVisibleObjects(camera, objects)
    for _, object in pairs(objects) do
        if isInCameraView(camera, object) then
            object.Transparency = 0
        else
            object.Transparency = 1
        end
    end
end

local Objects = workspace:GetDescendants()

local function IsAlive(model)
    if not model then return false end
    local Humanoids = model:FindFirstChildOfClass('Humanoid')
    if not Humanoids then return false end
    local RootParts = model:FindFirstChild('HumanoidRootPart')
    if not RootParts then return false end
    return Humanoids.Health > 0
end

local noRecoilValue   = 0
local fireRateValue   = 1000
local accuracyValue   = 1
local gunModsEnabled  = false

local sendEventCounter = 0
local sendFuncCounter  = 0

local smoothTarget    = Vector3.new()
local smoothFactor    = 0.75
local tracerLines     = nil
local fovCircle       = nil
local redLine         = Drawing.new("Line")
redLine.Thickness     = 1
redLine.Color         = Color3.fromRGB(255, 50, 50)
redLine.Transparency  = 1
redLine.Visible       = false

-- ── Global env helper ────────────────────────────────────────
local getEnv = getgenv or function() return _G end

getEnv().Sky        = false
getEnv().SkyAmount  = 1500

-- ── Rarity Colors ────────────────────────────────────────────
local RarityColors = {
    Common    = Color3.fromRGB(255, 255, 255),
    Uncommon  = Color3.fromRGB(99,  255, 52),
    Rare      = Color3.fromRGB(51,  170, 255),
    Epic      = Color3.fromRGB(237, 44,  255),
    Legendary = Color3.fromRGB(255, 150, 0),
    Omega     = Color3.fromRGB(255, 20,  51),
}

-- ── Counter table (anti-kick) ─────────────────────────────────
local Counter
pcall(function()
    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "event") and rawget(v, "func") then
            Counter = v
            break
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  WindUI Window
-- ══════════════════════════════════════════════════════════════
local WindUI
pcall(function()
    WindUI = loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)

local Window
if WindUI then
    Window = WindUI:CreateWindow({
        Title      = "MERCY HUB  |  Block Spin🔫",
        Icon = "rbxassetid://133253457738939",
        Author     = "Block spin | Paid💵",
        Folder     = "mercyhub",
        Size       = UDim2.fromOffset(650, 400),
        Theme      = "Violet",
        Transparent = true,
        Resizable  = true,
        KeyCode    = Enum.KeyCode.G,
    })

    Window:Tag({
        Title  = "v5.6",
        Color  = Color3.fromHex("#30ff6a"),
        Radius = 12,
    })
else
    -- Fallback stub so the rest of the script doesn't error
    Window = {
        Tab = function()
            return {
                Section  = function() end,
                Toggle   = function() end,
                Slider   = function() end,
                Button   = function() end,
                Input    = function() return {} end,
                Divider  = function() end,
            }
        end,
    }
end

local ConfigManager = Window.ConfigManager
local Config        = ConfigManager:CreateConfig("CathubConfig")

-- ── Send Remote reference ─────────────────────────────────────
local SendRemote
pcall(function()
    SendRemote = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("Send", 5)
end)

-- ══════════════════════════════════════════════════════════════
--  Utility Functions
-- ══════════════════════════════════════════════════════════════

local function getPing()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return 0.2 end
    local stats = gui:FindFirstChild("NetworkStats")
    if not stats then return 0.2 end
    local label = stats:FindFirstChild("PingLabel")
    if not label then return 0.2 end
    local num = tonumber(tostring(label.Text):match("%d+"))
    if not num then return 0.2 end
    local ping = num / 1000
    return (ping < 0 or ping > 2) and 0.2 or ping
end

local function isPlayerExcluded(name)
    for _, entry in ipairs(excludedPlayers) do
        if entry ~= "" and string.find(string.lower(name), string.lower(entry)) then
            return true
        end
    end
    return false
end

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    return ok, result
end

local unpackTable = table.unpack or unpack

-- ── Remote caller (respects counter) ─────────────────────────
local function callRemote(remote, ...)
    if not remote then return end
    local args = { ... }

    if remote.ClassName == "RemoteEvent" then
        if Counter and type(Counter.event) == "number" then
            Counter.event = Counter.event + 1
            safeCall(function(...) remote:FireServer(Counter.event, ...) end, unpackTable(args))
        else
            sendEventCounter = sendEventCounter + 1
            safeCall(function(...) remote:FireServer(sendEventCounter, ...) end, unpackTable(args))
        end
    elseif remote.ClassName == "RemoteFunction" then
        if Counter and type(Counter.func) == "number" then
            Counter.func = Counter.func + 1
            safeCall(function(...) remote:InvokeServer(Counter.func, ...) end, unpackTable(args))
        else
            sendFuncCounter = sendFuncCounter + 1
            safeCall(function(...) remote:InvokeServer(sendFuncCounter, ...) end, unpackTable(args))
        end
    else
        safeCall(function(...)
            if remote.FireServer   then remote:FireServer(...)   end
            if remote.InvokeServer then remote:InvokeServer(...) end
        end, unpackTable(args))
    end
end

-- ── NetGet (uses RemoteFunction "Get") ───────────────────────
local function netGet(...)
    if not Counter or not Counter.func then return end
    local args = { ... }
    for i, v in ipairs(args) do
        if typeof(v) == "Instance" then
            if v:IsA("Model") and #v:GetChildren() == 0 then
                local dropped = Workspace:FindFirstChild("DroppedItems")
                if dropped then
                    local model = dropped:FindFirstChildWhichIsA("Model")
                    if model then args[i] = model else return end
                else return end
            end
        end
    end
    Counter.func = (Counter.func or 0) + 1
    local ok, result = pcall(function()
        local get = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Get")
        return get:InvokeServer(Counter.func, unpackTable(args))
    end)
    if not ok then warn("[NetGet Error]", result) end
    return result
end

-- ── Send helper ───────────────────────────────────────────────
local Send = {}
function Send.send(...)
    local args = { ... }
    Counter.event = Counter.event + 1
    pcall(function()
        Remotes.Send:FireServer(Counter.event, unpackTable(args))
    end)
end

-- ══════════════════════════════════════════════════════════════
--  Prediction / Aim Helpers
-- ══════════════════════════════════════════════════════════════

local HISTORY_SIZE    = 10   -- เพิ่ม history ให้ velocity แม่นขึ้นตอนซิกแซก
local VELOCITY_SCALE  = 1.25 -- ลดการดักล่วงหน้าลงนิดหน่อย
local MAX_JUMP_VEL    = 150
local SMOOTH_MULT     = 1

RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum  = player.Character:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                positionHistory[player] = positionHistory[player] or {}
                table.insert(positionHistory[player], { time = os.clock(), pos = root.Position })
                if #positionHistory[player] > HISTORY_SIZE then
                    table.remove(positionHistory[player], 1)
                end
            else
                positionHistory[player] = nil
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    positionHistory[player] = nil
end)

local function calculateVelocity(player)
    local history = positionHistory[player]
    if not history or #history < 2 then return Vector3.new() end
    -- ใช้ weighted average โดยให้น้ำหนักกับ frame ล่าสุดมากกว่า
    -- เพื่อให้ตามทันคนที่วิ่งซิกแซกเปลี่ยนทิศทางกะทันหัน
    local sum, totalWeight = Vector3.new(), 0
    for i = 2, #history do
        local dt = history[i].time - history[i - 1].time
        if dt > 0 then
            local vel    = (history[i].pos - history[i - 1].pos) / dt
            local weight = i  -- frame ล่าสุด index สูงกว่า = น้ำหนักมากกว่า
            sum         = sum + vel * weight
            totalWeight = totalWeight + weight
        end
    end
    if totalWeight == 0 then return Vector3.new() end
    local avg = sum / totalWeight
    if avg.Y > MAX_JUMP_VEL then
        return Vector3.new(avg.X * 1.15, math.clamp(avg.Y * 0.85, 0, 400), avg.Z * 1.15)
    end
    return avg
end

local function predictPosition(part, root)
    if not part then return Vector3.zero end

    local parentModel = part.Parent
    local player = parentModel and Players:GetPlayerFromCharacter(parentModel)
    local velocity = (player and calculateVelocity(player)) or Vector3.zero

    local ping = math.clamp(getPing(), 0.06, 0.20)

    -- speed แนวนอนเท่านั้น (แม่นกว่า magnitude รวม Y)
    local hSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

    -- multiplier ละเอียดขึ้น + ชดเชยการเปลี่ยนทิศ
    local multiplier
    if     hSpeed > 60 then multiplier = 1.50
    elseif hSpeed > 50 then multiplier = 1.42
    elseif hSpeed > 35 then multiplier = 1.32
    elseif hSpeed > 20 then multiplier = 1.22
    elseif hSpeed > 10 then multiplier = 1.15
    else                     multiplier = 1.05
    end

    -- ถ้า ping สูง ลด multiplier นิดหน่อยเพื่อไม่ over-predict
    if ping > 0.15 then
        multiplier = multiplier * 0.93
    end

    local horizontal = Vector3.new(velocity.X, 0, velocity.Z) * ping * multiplier

    -- vertical คมขึ้น: เพิ่ม coefficient จาก 0.22 → 0.30
    local vertical = Vector3.new(
        0,
        math.clamp(velocity.Y * ping * 0.30, -4, 4),
        0
    )

    -- jump boost ละเอียดขึ้น
    local jumpBoost = Vector3.new(
        0,
        velocity.Y > 20 and 0.50
        or velocity.Y > 15 and 0.35
        or 0,
        0
    )

    local headOffset = Vector3.zero
    if part.Name == "Head" then
        headOffset = Vector3.new(
            0,
            hSpeed > 30 and 0.14
            or hSpeed > 22 and 0.10
            or 0.05,
            0
        )
    end

    return part.Position
        + horizontal
        + vertical
        + jumpBoost
        + headOffset
end

local function isBehindWall(origin, target)
    if not origin or not target then return false end
    local dir = target - origin
    if dir.Magnitude < 1 then return false end
    local params = RaycastParams.new()
    local result = Workspace:Raycast(origin, dir, params)
    if not result then return false end
    local inst = result.Instance
    local myChar    = LocalPlayer.Character
    local aimChar   = aimTarget and aimTarget.Character
    return inst and not (
        (myChar and inst:IsDescendantOf(myChar)) or
        (aimChar and inst:IsDescendantOf(aimChar))
    )
end

-- ── Closest target within FOV ────────────────────────────────
local function getClosestTarget()
    local best, bestDist = nil, fovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local hum  = player.Character:FindFirstChild("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if head and hum and hum.Health > 0 and root then
                local pos, visible = Camera:WorldToViewportPoint(head.Position)
                if visible then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenPos - center).Magnitude
                    if dist <= fovRadius and not isPlayerExcluded(player.Name) then
                        if dist < bestDist then
                            bestDist = dist
                            best = player
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════════════
--  FOV Circle
-- ══════════════════════════════════════════════════════════════
if not isMobile then
    local FovSegments = 16
    local FovLines = {}
    for i = 1, FovSegments do
        local Line = Drawing.new("Line")
        Line.Visible = false
        Line.Thickness = 1.5
        Line.Color = Color3.fromHSV(i / FovSegments, 1, 1)
        FovLines[i] = Line
    end
    fovCircle = {
        Visible = false,
        _lines = FovLines,
        _segments = FovSegments
    }
else
    local fovGui = Instance.new("ScreenGui")
    fovGui.Name   = "MobileFOV"
    fovGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    fovCircle = Instance.new("Frame")
    fovCircle.Size          = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
    fovCircle.AnchorPoint   = Vector2.new(0.5, 0.5)
    fovCircle.Position      = UDim2.fromScale(0.5, 0.5)
    fovCircle.BackgroundTransparency = 1
    local corner  = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovCircle
    local stroke  = Instance.new("UIStroke")
    stroke.Color       = Color3.fromRGB(255, 255, 255)
    stroke.Thickness   = 2
    stroke.Transparency = 0.2
    stroke.Parent = fovCircle
    fovCircle.Parent = fovGui
end

-- ══════════════════════════════════════════════════════════════
--  Silent Aim Hook (FireServer)
-- ══════════════════════════════════════════════════════════════
local originalFireServer
if SendRemote and SendRemote.FireServer then
    pcall(function()
        originalFireServer = hookfunction(SendRemote.FireServer, function(self, ...)
            if self ~= SendRemote then
                return originalFireServer(self, ...)
            end
            local args = { ... }
            if silentAimEnabled and args[2] == "shoot_gun" and aimTarget then
                local head = aimTarget.Character and aimTarget.Character:FindFirstChild("Head")
                local root = aimTarget.Character and aimTarget.Character:FindFirstChild("HumanoidRootPart")
                local hum  = aimTarget.Character and aimTarget.Character:FindFirstChild("Humanoid")
                if head and root and hum then
                    local aimPos     = predictPosition(head, root)
                    local myHead     = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                    local originPos  = myHead and myHead.Position or nil

                    -- Shotgun handling
                    local function isShotgun()
                        if not Character then return false end
                        for _, tool in ipairs(Character:GetChildren()) do
                            if tool:IsA("Tool") then
                                local ammo = tool:GetAttribute("AmmoType")
                                if ammo == "shotgun" or ammo == "shootgun" then return true end
                            end
                        end
                        return false
                    end

                    if isShotgun() then
                        args[4] = CFrame.new(originPos, aimPos)
                        local pellets = {}
                        for i = 1, 6 do
                            local spread = Vector3.new(
                                math.random(-2, 2) * 0.03,
                                math.random(-2, 2) * 0.03,
                                math.random(-2, 2) * 0.03
                            )
                            table.insert(pellets, { [1] = {
                                Instance = head,
                                Normal   = Vector3.new(0, 1, 0),
                                Position = aimPos + spread,
                            }})
                        end
                        args[5] = pellets
                    else
                        local wallBlocked = isBehindWall(originPos, aimPos)
                        args[4] = wallBlocked
                            and CFrame.new(math.huge, math.huge, math.huge)
                            or  CFrame.new(originPos, aimPos)
                        args[5] = { [1] = { [1] = {
                            Instance = head,
                            Normal   = Vector3.new(0, 1, 0),
                            Position = aimPos,
                        }}}
                    end

                    -- Hit indicator beam
                    pcall(function()
                        local beam = Instance.new("Part")
                        beam.Anchored    = true
                        beam.CanCollide  = false
                        beam.Size        = Vector3.new(0.08, 0.08, (aimPos - LocalPlayer.Character.Head.Position).Magnitude)
                        beam.CFrame      = CFrame.new(LocalPlayer.Character.Head.Position, aimPos)
                                         * CFrame.new(0, 0, -beam.Size.Z / 2)
                        beam.Material    = Enum.Material.Neon
                        beam.Transparency = 0.35
                        beam.Color       = Color3.fromRGB(255, 0, 0)
                        beam.Parent      = Workspace
                        Debris:AddItem(beam, 4)
                        -- Color feedback on hit
                        if hum then
                            local prevHp = hum.Health
                            spawn(function()
                                wait(0.1)
                                if hum and hum.Health < prevHp then
                                    beam.Color = Color3.fromRGB(0, 255, 0)
                                    -- Hit flash on target
                                    for _, part in ipairs(aimTarget.Character:GetDescendants()) do
                                        if part:IsA("BasePart") then
                                            local flash = Instance.new("Part")
                                            flash.Size        = part.Size + Vector3.new(0.05, 0.05, 0.05)
                                            flash.CFrame      = part.CFrame
                                            flash.Anchored    = true
                                            flash.CanCollide  = false
                                            flash.Material    = Enum.Material.Neon
                                            flash.Color       = Color3.fromRGB(255, 0, 0)
                                            flash.Transparency = 0.5
                                            flash.Parent      = Workspace
                                            TweenService:Create(flash, TweenInfo.new(1.5, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
                                            Debris:AddItem(flash, 2)
                                        end
                                    end
                                end
                            end)
                        end
                    end)
                end
            end
            return originalFireServer(self, unpack(args))
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  RenderStepped — Aim / FOV / Tracer
-- ══════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    pcall(function()
        if redLineLockEnabled then
            aimTarget = getClosestTarget()
        end
        aimTarget = (silentAimEnabled or redLineLockEnabled) and getClosestTarget() or nil

        local closestPlayer = getClosestTarget()

        -- FOV circle
        if fovCircle then
            if isMobile then
                fovCircle.Visible = silentAimEnabled
                fovCircle.Position = UDim2.fromScale(0.5, 0.5)
                fovCircle.Size     = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
            else
                local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local t = tick()
                for i = 1, fovCircle._segments do
                    local angle1 = math.rad((i - 1) * (360 / fovCircle._segments))
                    local angle2 = math.rad(i * (360 / fovCircle._segments))
                    fovCircle._lines[i].From = Center + Vector2.new(math.cos(angle1) * fovRadius, math.sin(angle1) * fovRadius)
                    fovCircle._lines[i].To   = Center + Vector2.new(math.cos(angle2) * fovRadius, math.sin(angle2) * fovRadius)
                    -- Rainbow: hue shifts over time and around the circle
                    fovCircle._lines[i].Color = Color3.fromHSV(((i / fovCircle._segments) + t * 0.5) % 1, 1, 1)
                    fovCircle._lines[i].Visible = silentAimEnabled
                end
            end
				end

        -- Tracer / Red Line
        if closestPlayer and closestPlayer.Character then
            local char = closestPlayer.Character
            local hum  = char:FindFirstChild("Humanoid")
            local aimPart = (SelectedAimPart == "HumanoidRootPart")
                and char:FindFirstChild("HumanoidRootPart")
                or  char:FindFirstChild("Head")

            if hum and hum.Health > 0 and aimPart then
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                smoothTarget = smoothTarget:Lerp(aimPart.Position, SMOOTH_MULT)
                local screenPos, visible = Camera:WorldToViewportPoint(smoothTarget)

                if visible then
                    redLine.Visible = true
                    redLine.From    = center
                    redLine.To      = Vector2.new(screenPos.X, screenPos.Y)
                    redLine.Color   = Color3.fromRGB(255, 50, 50)
                    redLine.Thickness = 1.3

                    -- Diamond crosshair
                    if not tracerLines then
                        tracerLines = {}
                        for i = 1, 4 do
                            tracerLines[i]           = Drawing.new("Line")
                            tracerLines[i].Color     = Color3.fromRGB(255, 255, 255)
                            tracerLines[i].Thickness = 1.2
                            tracerLines[i].Visible   = true
                        end
                    end
                    local top    = Camera:WorldToViewportPoint(aimPart.Position + Vector3.new(0,  0.5, 0))
                    local bottom = Camera:WorldToViewportPoint(aimPart.Position - Vector3.new(0,  0.5, 0))
                    local cx, cy = screenPos.X, screenPos.Y
                    local halfH  = math.clamp((Vector2.new(top.X, top.Y) - Vector2.new(bottom.X, bottom.Y)).Magnitude / 2, 8, 25)
                    local halfW  = halfH

                    tracerLines[1].From, tracerLines[1].To = Vector2.new(cx, cy - halfH), Vector2.new(cx + halfW, cy)
                    tracerLines[2].From, tracerLines[2].To = Vector2.new(cx + halfW, cy), Vector2.new(cx, cy + halfH)
                    tracerLines[3].From, tracerLines[3].To = Vector2.new(cx, cy + halfH), Vector2.new(cx - halfW, cy)
                    tracerLines[4].From, tracerLines[4].To = Vector2.new(cx - halfW, cy), Vector2.new(cx, cy - halfH)
                    for i = 1, 4 do tracerLines[i].Visible = true end
                else
                    redLine.Visible = false
                    if tracerLines then for i = 1, 4 do tracerLines[i].Visible = false end end
                end
            else
                redLine.Visible = false
                if tracerLines then for i = 1, 4 do tracerLines[i].Visible = false end end
                smoothTarget = Vector3.new()
            end
        else
            redLine.Visible = false
            if tracerLines then for i = 1, 4 do tracerLines[i].Visible = false end end
            smoothTarget = Vector3.new()
        end

        -- under-map lock
        if snapActive and snapY and HRP then
            local pos = HRP.Position
            if math.abs(pos.Y - snapY) > 0.1 then
                HRP.CFrame = CFrame.new(pos.X, snapY, pos.Z)
            end
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
--  Character / Anti-Lock / Anti-Kill
-- ══════════════════════════════════════════════════════════════
local jumpConn
local function setupCharacter(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    HRP       = char:WaitForChild("HumanoidRootPart")
    if jumpConn then pcall(function() jumpConn:Disconnect() end) end
    jumpConn = RunService.RenderStepped:Connect(function()
        if walkSpeedEnabled and Humanoid and HRP then
            if Humanoid.MoveDirection.Magnitude > 0 then
                HRP.CFrame = HRP.CFrame + (Humanoid.MoveDirection.Unit * speedMultiplier)
            end
        end
    end)
end

local function isDowned()
    local hum = CharModule.get_hum()
    if not hum or hum.Health <= 0 then return false end
    return hum:GetAttribute("HasBeenDowned") or hum:GetAttribute("IsDead")
end

local function getHRP()
    local char = CharModule.current_char.get()
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart")
end

local function teleportUnderground()
    local root = getHRP()
    if not root then return end
    underMapPos = root.CFrame + Vector3.new(0, -40, 0)
    root.CFrame = underMapPos
end

local function flickerAndMove()
    if isFlickering then return end
    isFlickering = true
    task.spawn(function()
        while isFlickering and antiKillEnabled and isDowned() do
            local hum = CharModule.get_hum()
            if hum and hum.Health <= 0 then break end
            local root = getHRP()
            if root and underMapPos then
                local angle = math.random() * math.pi * 2
                local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 10
                root.CFrame = CFrame.new(underMapPos.Position + offset)
                task.wait(0.05)
                root.CFrame = underMapPos
            end
            task.wait(0.1)
        end
        isFlickering = false
    end)
end

RunService.Heartbeat:Connect(function()
    if not antiKillEnabled then return end
    if isDowned() then
        local root = getHRP()
        if root and not underMapPos then
            teleportUnderground()
        end
        flickerAndMove()
    else
        if underMapPos then
            local root = getHRP()
            if root then root.CFrame = underMapPos + Vector3.new(0, 40, 0) end
        end
        underMapPos = nil
        isFlickering = false
    end
end)

-- Anti-Lock (sky velocity)
RunService.Heartbeat:Connect(function()
    if getEnv().Sky and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root    = LocalPlayer.Character.HumanoidRootPart
        local prevVel = root.Velocity
        local angle   = math.rad(tick() * 1500 % 360)
        local amount  = getEnv().SkyAmount
        root.Velocity = Vector3.new(math.cos(angle) * amount, math.random(280, 480), math.sin(angle) * amount)
        RunService.RenderStepped:Wait()
        root.Velocity = prevVel
    end
end)

-- ══════════════════════════════════════════════════════════════
--  Auto Pickup
-- ══════════════════════════════════════════════════════════════
local function checkAndPickup()
    if not autoPickupEnabled then return end
    local dropped = Workspace:FindFirstChild("DroppedItems")
    if not dropped then return end
    local now  = tick()
    local toPickup = {}
    for _, model in ipairs(dropped:GetChildren()) do
        if model:IsA("Model") then
            local part = model:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (HRP.Position - part.Position).Magnitude
                if dist <= 20 and (now - (itemPickupTrack[model] or 0)) >= 0 then
                    table.insert(toPickup, model)
                    itemPickupTrack[model] = now
                end
            end
        end
    end
    for _, model in ipairs(toPickup) do
        spawn(function() netGet("pickup_dropped_item", model) end)
    end
end

RunService.Heartbeat:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        HRP = Character:WaitForChild("HumanoidRootPart")
    end
    pcall(checkAndPickup)
end)

-- ══════════════════════════════════════════════════════════════
--  Auto Attack (Melee)
-- ══════════════════════════════════════════════════════════════
local function getPlayersInRange(range)
    local result = {}
    local myChar = LocalPlayer.Character
    if not myChar or not myChar.PrimaryPart then return result end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character.PrimaryPart then
            local ok, dist = pcall(function()
                return (player.Character.PrimaryPart.Position - myChar.PrimaryPart.Position).Magnitude
            end)
            if ok and dist and dist <= 20 then
                table.insert(result, player)
            end
        end
    end
    return result
end

local function getActiveTool()
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if pcall(function() return v:IsA("Tool") end) and v:IsA("Tool") then
                return v
            end
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, v in ipairs(backpack:GetChildren()) do
            if pcall(function() return v:IsA("Tool") end) and v:IsA("Tool") then
                return v
            end
        end
    end
    return nil
end

local function isMeleeToolCheck(tool)
    if not tool then return false end
    if tool.Name == "Fists" then return true end
    local meleeFolder    = ReplicatedStorage:WaitForChild("Items"):WaitForChild("melee")
    local throwableFolder = ReplicatedStorage:WaitForChild("Items"):WaitForChild("throwable")
    return meleeFolder:FindFirstChild(tool.Name) and not throwableFolder:FindFirstChild(tool.Name)
end

local function attackNearby()
    if not SendRemote then return end
    local myChar = LocalPlayer.Character
    if not myChar or not myChar.PrimaryPart then return end
    local tool = getActiveTool()
    if not tool or not isMeleeToolCheck(tool) then return end
    local ok, parent = pcall(function() return tool.Parent end)
    if not ok or parent ~= LocalPlayer.Character then return end
    local nearby = getPlayersInRange(20)
    if #nearby == 0 then return end
    local ok2, myPos = pcall(function() return myChar.PrimaryPart.Position end)
    if not ok2 or not myPos then return end
    local targets, positions = {}, {}
    for _, player in pairs(nearby) do
        if player and player.Character and player.Character.PrimaryPart then
            local head = player.Character:FindFirstChild("Head")
            local root = player.Character.PrimaryPart
            if head and root then
                local aimPos = predictPosition(head, root)
                table.insert(targets, player)
                table.insert(positions, aimPos)
            end
        end
    end
    if #targets == 0 then return end
    local lookAt = CFrame.lookAt(myPos, positions[1])
    pcall(function()
        callRemote(SendRemote, unpackTable({ "melee_attack", tool, targets, lookAt, 0.75 }))
    end)
end

local autoAttackRunning = false
local function startAutoAttack()
    if autoAttackRunning then return end
    autoAttackRunning = true
    task.spawn(function()
        while autoAttackRunning do
            task.wait(0.4)
            if autoAttackEnabled and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                pcall(attackNearby)
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  Snap Under Map
-- ══════════════════════════════════════════════════════════════
local function performTeleport()
    if not HRP then return end
    local pos = HRP.Position
    local dest = Vector3.new(pos.X, pos.Y - snapDepth, pos.Z)
    HRP.CFrame = CFrame.new(dest)
    snapY = dest.Y
    local sound = Instance.new("Sound")
    sound.SoundId     = "rbxassetid://95298029662868"
    sound.Volume      = 1
    sound.PlayOnRemove = true
    sound.Parent      = HRP
    sound:Destroy()
end

local function toggleSnap()
    if not snapUnderMapEnabled then return end
    snapActive = not snapActive
    if snapActive then
        performTeleport()
    else
        snapY = nil
    end
end

local snapConn
local function lockYPosition()
    if snapConn then pcall(function() snapConn:Disconnect() end) end
    snapConn = RunService.Heartbeat:Connect(function()
        if snapActive and snapY and HRP then
            local pos = HRP.Position
				if math.abs(pos.Y - snapY) > 0.1 then
                HRP.CFrame = CFrame.new(pos.X, snapY, pos.Z)
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  Finish Prompt (Auto Finish)
-- ══════════════════════════════════════════════════════════════
local function setFinishPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 1
        prompt.MaxActivationDistance = 20
    end
end

local function tryHoldPrompt(prompt, duration)
    if not prompt or prompt:GetAttribute("__AutoFinishBusy") then return end
    prompt:SetAttribute("__AutoFinishBusy", true)
    pcall(function() if prompt.InputHoldBegin then prompt:InputHoldBegin() end end)
    pcall(function() if prompt.HoldBegin      then prompt:HoldBegin()      end end)
    pcall(function() if prompt.Trigger        then prompt:Trigger()        end end)
    task.wait(duration)
    pcall(function() if prompt.InputHoldEnd then prompt:InputHoldEnd() end end)
    pcall(function() if prompt.HoldEnd      then prompt:HoldEnd()      end end)
    prompt:SetAttribute("__AutoFinishBusy", nil)
end

local function findFinishPrompts()
    local result = {}
    for _, child in pairs(Workspace:GetChildren()) do
        local player = Players:GetPlayerFromCharacter(child)
        if player and not isPlayerExcluded(player.Name) then
            local root = child:FindFirstChild("HumanoidRootPart")
            if root then
                local prompt = root:FindFirstChild("FinishPrompt")
                if prompt then
                    setFinishPrompt(prompt)
                    table.insert(result, prompt)
                end
            end
        end
    end
    return result
end

local function applyToAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local prompt = root:FindFirstChild("FinishPrompt")
                if prompt then setFinishPrompt(prompt) end
            end
        end
    end
end

local function setupFastFinishForPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        char.DescendantAdded:Connect(function(inst)
            if autoFinishEnabled and inst.Name == "FinishPrompt"
                and inst:IsA("ProximityPrompt")
                and inst.Parent and inst.Parent.Name == "HumanoidRootPart" then
                setFinishPrompt(inst)
            end
        end)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root and autoFinishEnabled then
            local prompt = root:FindFirstChild("FinishPrompt")
            if prompt then setFinishPrompt(prompt) end
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do setupFastFinishForPlayer(player) end
Players.PlayerAdded:Connect(setupFastFinishForPlayer)

task.spawn(function()
    while true do
        task.wait(0.4)
        if autoFinishEnabled then
            for _, prompt in ipairs(findFinishPrompts()) do
                task.spawn(function() tryHoldPrompt(prompt, 1) end)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  Skip Crate
-- ══════════════════════════════════════════════════════════════
local CrateController = require(ReplicatedStorage.Modules.Game.CrateSystem.Crate)
task.spawn(function()
    while true do
        if skipCrateEnabled then
            for _, crate in pairs(CrateController.class.objects) do
                crate.states.open.set(true)
                CrateController.skipping.set(true)
            end
        end
        task.wait(0.05)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  Player ESP
-- ══════════════════════════════════════════════════════════════
local ESP = {}
local function createESP(player)
    if player == LocalPlayer then return end
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency    = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Parent  = game.CoreGui

    local name = Drawing.new("Text")
    name.Size    = 12
    name.Center  = true
    name.Outline = true
    name.Color   = Color3.new(1, 1, 1)
    name.Visible = false
    name.Font    = 3

    local info = Drawing.new("Text")
    info.Size    = 11
    info.Center  = true
    info.Outline = true
    info.Color   = Color3.new(1, 1, 1)
    info.Visible = false
    info.Font    = 3

    local hpBar = Drawing.new("Square")
    hpBar.Filled = true
    hpBar.Transparency = 0.9
    hpBar.Visible = false

    local hpBg = Drawing.new("Square")
    hpBg.Filled = false
    hpBg.Thickness = 1
    hpBg.Color = Color3.fromRGB(0, 0, 0)
    hpBg.Transparency = 0.9
    hpBg.Visible = false

    ESP[player] = {Highlight = highlight, Name = name, Info = info, HpBar = hpBar, HpBg = hpBg}
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    local data = ESP[player]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Name      then data.Name:Remove()      end
        if data.Info      then data.Info:Remove()      end
        if data.HpBar     then data.HpBar:Remove()     end
        if data.HpBg      then data.HpBg:Remove()      end
        ESP[player] = nil
    end
end)

local function getESPColor(player)
    if aimTarget == player then
        return Color3.fromRGB(255, 0, 0)
    elseif player:GetAttribute("InSplashScreen") then
        return Color3.fromRGB(0, 200, 255)
    elseif player:GetAttribute("IsInSafeZone") then
        return Color3.fromRGB(0, 255, 0)
    end
    return Color3.new(1, 1, 1)
end

RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        if player.Character then
            local hum  = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and head and root and hum.Health > 0 then

                -- Highlight
                if highlightEnabled then
                    data.Highlight.Enabled = true
                    data.Highlight.Adornee = player.Character
                    local hpPercent = hum.Health / hum.MaxHealth
                    data.Highlight.FillColor = Color3.fromRGB(255 * (1 - hpPercent), 255 * hpPercent, 0)
                else
                    data.Highlight.Enabled = false
                end

                local posHead, visHead = Camera:WorldToViewportPoint(head.Position)
                local posFoot, visFoot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                -- Name
                if nameESPEnabled and visHead then
                    data.Name.Visible  = true
                    data.Name.Text     = player.Name
                    data.Name.Position = Vector2.new(posHead.X, posHead.Y - 20)
					data.Name.Color = getESPColor(player)
                else
                    data.Name.Visible = false
                end

                -- Distance
                if distanceESPEnabled and visFoot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                    local pct = math.floor(hum.Health / math.max(hum.MaxHealth, 1) * 100)
                    data.Info.Visible  = true
                    data.Info.Text     = pct .. "% | " .. dist .. "M"
                    data.Info.Position = Vector2.new(posFoot.X, posFoot.Y + 10)
                    data.Info.Color    = getESPColor(player)
                else
                    data.Info.Visible = false
					end
            else
                data.Highlight.Enabled = false
                data.Name.Visible      = false
                data.Info.Visible      = false
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  Inventory Viewer (Billboard)
-- ══════════════════════════════════════════════════════════════
local function registerItems(folder)
    for _, tool in ipairs(folder:GetChildren()) do
        if tool:IsA("Tool") then
            local handle    = tool:FindFirstChild("Handle")
            local displayName = tool:GetAttribute("DisplayName") or tool.Name
            local itemId    = tool:GetAttribute("ItemId") or tool:GetAttribute("Id") or tool.Name
            local rarity    = tool:GetAttribute("RarityName") or "Common"
            local imageId   = tool:GetAttribute("ImageId") or "rbxassetid://7072725737"
            local key
            if handle then
                local mesh = handle:FindFirstChildOfClass("SpecialMesh")
                if mesh and mesh.MeshId ~= "" then
                    key = mesh.MeshId .. (mesh.TextureId or "") .. "_RARITY_" .. rarity
                elseif handle:IsA("MeshPart") and handle.MeshId ~= "" then
                    key = handle.MeshId .. (handle.TextureID or "") .. "_RARITY_" .. rarity
                end
            end
            if not key and itemId and itemId ~= "" and itemId ~= tool.Name then
                key = "ITEMID_" .. itemId .. "_RARITY_" .. rarity
            end
            if not key then
                key = "NAME_" .. displayName .. "_" .. tool.Name .. "_RARITY_" .. rarity
            end
            WeaponRegistry[key] = { Name = displayName, Rarity = rarity, ImageId = imageId, ToolName = tool.Name }
        end
    end
end

local function getItemKey(tool)
    local handle = tool:FindFirstChild("Handle")
    local displayName = tool:GetAttribute("DisplayName") or tool.Name
    local itemId = tool:GetAttribute("ItemId") or tool:GetAttribute("Id") or tool.Name
    local rarity = tool:GetAttribute("RarityName") or "Common"
    if handle then
        local mesh = handle:FindFirstChildOfClass("SpecialMesh")
        if mesh and mesh.MeshId ~= "" then return mesh.MeshId .. (mesh.TextureId or "") .. "_RARITY_" .. rarity end
        if handle:IsA("MeshPart") and handle.MeshId ~= "" then return handle.MeshId .. (handle.TextureID or "") .. "_RARITY_" .. rarity end
    end
    if itemId and itemId ~= "" and itemId ~= tool.Name then return "ITEMID_" .. itemId .. "_RARITY_" .. rarity end
    return "NAME_" .. displayName .. "_" .. tool.Name .. "_RARITY_" .. rarity
end

local function getWeaponInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return WeaponRegistry[getItemKey(tool)]
end

-- ── Inventory ESP (Drawing) ───────────────────────────────────
local InventoryDrawings = {}

local function getPlayerTools(player)
    local tools = {}
    local char = player.Character
    for _, bagName in ipairs({"Backpack", "StarterGear", "StarterPack"}) do
        local bag = player:FindFirstChild(bagName)
        if bag then
            for _, t in ipairs(bag:GetChildren()) do
                if t:IsA("Tool") and t.Name ~= "Fists" then table.insert(tools, t) end
            end
        end
    end
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name ~= "Fists" then table.insert(tools, t) end
        end
    end
    return tools
end

local function clearInventoryDrawings(player)
    local data = InventoryDrawings[player]
    if data then
        for _, d in ipairs(data.drawings) do
            pcall(function() d:Remove() end)
        end
        InventoryDrawings[player] = nil
    end
end

local function createBillboardForPlayer(player) end

local function setInventoryESPEnabled(enabled)
    inventoryESPEnabled = enabled
    if not enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            clearInventoryDrawings(player)
        end
        PlayerBillboards = {}
    end
end

RunService.RenderStepped:Connect(function()
    if not inventoryESPEnabled then
        for player in pairs(InventoryDrawings) do
            clearInventoryDrawings(player)
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == Players.LocalPlayer then continue end
        local char = player.Character
        if not char then clearInventoryDrawings(player) continue end
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not head or not root then clearInventoryDrawings(player) continue end

        local tools = getPlayerTools(player)
        local infos = {}
        for _, tool in ipairs(tools) do
            local info = getWeaponInfo(tool)
            if info then table.insert(infos, info) end
        end

        if not InventoryDrawings[player] then
            InventoryDrawings[player] = { drawings = {} }
        end
        local data = InventoryDrawings[player]

        while #data.drawings < #infos do
            local d = Drawing.new("Text")
            d.Size    = 8
            d.Center  = true
            d.Outline = true
            d.Font    = 4
            d.Visible = false
            table.insert(data.drawings, d)
        end

        local posHead, visHead = Camera:WorldToViewportPoint(head.Position)
        local posFoot, visFoot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        local baseY = posFoot.Y + 28

        for idx, info in ipairs(infos) do
            local d = data.drawings[idx]
            if visFoot then
                d.Text     = "[" .. info.Name .. "]"
                d.Color    = RarityColors[info.Rarity] or Color3.new(1, 1, 1)
                d.Position = Vector2.new(posFoot.X, baseY + ((idx - 1) * 13))
                d.Visible  = true
            else
                d.Visible = false
            end
        end

        for idx = #infos + 1, #data.drawings do
            data.drawings[idx].Visible = false
        end
    end
end)

for _, folderName in ipairs({"gun", "melee", "throwable", "consumable", "farming", "misc", "rod", "fish"}) do
    local folder = Items:FindFirstChild(folderName)
    if folder then registerItems(folder) end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        clearInventoryDrawings(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    clearInventoryDrawings(player)
    if PlayerBillboards[player] then
        PlayerBillboards[player]:Destroy()
        PlayerBillboards[player] = nil
    end
end)

-- ══════════════════════════════════════════════════════════════
--  Dropped Items ESP
-- ══════════════════════════════════════════════════════════════
local ItemCamera
repeat task.wait() until Workspace.CurrentCamera
ItemCamera = Workspace.CurrentCamera

local function getRarityColor(model)
    if model.Name == "Money" then
        return Color3.fromRGB(0, 255, 0)
    end

    for _, folder in ipairs(Items:GetChildren()) do
        if folder:IsA("Folder") then
            local item = folder:FindFirstChild(model.Name)

            if item and item:GetAttribute("RarityName") then
                return RarityColors[item:GetAttribute("RarityName")] or Color3.fromRGB(255,255,255)
            end
        end
    end

    return Color3.fromRGB(255,255,255)
end

local function cleanupItemDrawings()
    for model, data in pairs(itemDrawings) do
        if not model or not model.Parent then
            pcall(function() data.name:Remove() end)
            pcall(function() data.amount:Remove() end)
            pcall(function() data.box:Remove() end)

            itemDrawings[model] = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    cleanupItemDrawings()

    if not DroppedItems then
        return
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        return
    end

    -- Hide all
    for _, data in pairs(itemDrawings) do
        data.name.Visible = false
        data.amount.Visible = false
        data.box.Visible = false
    end

    -- Collect & sort
    local visible = {}

    for _, model in ipairs(DroppedItems:GetChildren()) do
        if model:IsA("Model")
        and model:FindFirstChild("PickUpZone")
        and not model:GetAttribute("Locked") then

            local ok, zonePos = pcall(function()
                return model.PickUpZone.Position
            end)

            if ok and zonePos then
                table.insert(visible,{
                    item = model,
                    dist = (zonePos - myRoot.Position).Magnitude
                })
            end
        end
    end

    table.sort(visible,function(a,b)
        return a.dist < b.dist
    end)

    for i = 1, math.min(20,#visible) do
        local model = visible[i].item
        local data = itemDrawings[model]

        if not data then
            data = {
                name = Drawing.new("Text"),
                amount = Drawing.new("Text"),
                box = Drawing.new("Quad")
            }

            -- Name
            data.name.Outline = true
            data.name.OutlineColor = Color3.fromRGB(0,0,0)
            data.name.Center = true
            data.name.Size = 13
            data.name.Font = 2

            -- Amount
            data.amount.Outline = true
            data.amount.OutlineColor = Color3.fromRGB(0,0,0)
            data.amount.Center = true
            data.amount.Size = 11
            data.amount.Font = 2
            data.amount.Color = Color3.fromRGB(200,200,200)

            -- Box
            data.box.Thickness = 1
            data.box.Transparency = 0.9
            data.box.Filled = false

            itemDrawings[model] = data
        end

        local pos, vis = ItemCamera:WorldToViewportPoint(model.PickUpZone.Position)

        if vis then
            local color = getRarityColor(model)

            -- Name
            data.name.Color = color
            data.name.Position = Vector2.new(pos.X, pos.Y - 18)
            data.name.Text = model.Name
            data.name.Visible = true

            -- Amount
            local amt = model:GetAttribute("Amount") or 1

            data.amount.Position = Vector2.new(pos.X, pos.Y + 13)
            data.amount.Text = amt > 1 and "["..tostring(amt).."]" or ""
            data.amount.Visible = amt > 1

            -- Box
            local s = 9

            data.box.PointA = Vector2.new(pos.X - s, pos.Y - s)
            data.box.PointB = Vector2.new(pos.X + s, pos.Y - s)
            data.box.PointC = Vector2.new(pos.X + s, pos.Y + s)
            data.box.PointD = Vector2.new(pos.X - s, pos.Y + s)

            data.box.Color = color
            data.box.Visible = true
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        for _, data in pairs(itemDrawings) do
            pcall(function() data.name:Remove() end)
            pcall(function() data.amount:Remove() end)
            pcall(function() data.box:Remove() end)
        end

        itemDrawings = {}
    end
end)

-- ══════════════════════════════════════════════════════════════
--  Gun Modifier
-- ══════════════════════════════════════════════════════════════
local GunItems = Items:WaitForChild("gun")

getEnv().FireRateValue  = 1000
getEnv().AccuracyValue  = 1
getEnv().RecoilValue    = 0
getEnv().Durability     = 999999999
getEnv().AutoValue      = true
getEnv().GunModsAutoApply = false

local function isGunTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    return GunItems:FindFirstChild(tool.Name) ~= nil or tool.Name:match("Gun") or tool:FindFirstChild("Handle")
end

local function forceSetAttr(tool, attr, val)
    if tool and tool.SetAttribute then
        pcall(function() tool:SetAttribute(attr, val) end)
    end
end

local function FindFireRateAttribute(gun)
    if not gun then return "fire_rate" end
    if gun:GetAttribute("fire_rate") ~= nil then return "fire_rate" end
    for attrName in pairs(gun:GetAttributes()) do
        if type(attrName) == "string" and attrName:sub(-3) == "486" then
            return attrName
        end
    end
    return "fire_rate"
end

local function applyGodGun(tool)
    if not tool or not isGunTool(tool) then return end
    pcall(function()
        tool:SetAttribute(FindFireRateAttribute(tool), getEnv().FireRateValue)
        tool:SetAttribute("accuracy",   getEnv().AccuracyValue)
        tool:SetAttribute("Recoil",     getEnv().RecoilValue)
        tool:SetAttribute("Durability", getEnv().Durability)
        tool:SetAttribute("automatic",  getEnv().AutoValue)
    end)
    task.spawn(function()
        for _ = 1, 20 do
            local attrs = tool:GetAttributes()
            local keys = {}
            for k in pairs(attrs) do table.insert(keys, k) end
            table.sort(keys)
            if #keys >= 11 then
                local targetKey = keys[11]
                for _ = 1, 5 do forceSetAttr(tool, targetKey, true); task.wait(0.01) end
            end
            task.wait(0.1)
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not getEnv().GunModsAutoApply then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and isGunTool(tool) then pcall(applyGodGun, tool) end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    repeat
        task.wait(0.1)
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and isGunTool(tool) then task.spawn(applyGodGun, tool) end
        end
    until not getEnv().GunModsAutoApply
end)

LocalPlayer.Character.ChildAdded:Connect(function(child)
    if child:IsA("Tool") and getEnv().GunModsAutoApply then
        task.wait(0.2)
        applyGodGun(child)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  Melee Aura (Wide Fists)
-- ══════════════════════════════════════════════════════════════
local meleeNames = {}
for _, tool in ipairs(MeleeItems:GetChildren()) do table.insert(meleeNames, tool.Name) end

local function isMeleeByName(tool)
    if not tool:IsA("Tool") then return false end
    if tool.Name == "Fists" then return true end
    for _, name in ipairs(meleeNames) do
        if tool.Name == name then return true end
    end
    return false
end

local function modifyFists(tool, enable)
    if not tool then return end
    local attrs = tool:GetAttributes()
    local keys  = {}
    for k in pairs(attrs) do table.insert(keys, k) end
    table.sort(keys)
    if #keys >= 7 then
        local rangeKey = keys[6]
        local dmgKey   = keys[7]
        if enable then
            if originalAttribs[rangeKey] == nil then originalAttribs[rangeKey] = tool:GetAttribute(rangeKey) end
            if originalAttribs[dmgKey]   == nil then originalAttribs[dmgKey]   = tool:GetAttribute(dmgKey)   end
            tool:SetAttribute(rangeKey, 360)
            tool:SetAttribute(dmgKey,   20)
        else
            if originalAttribs[rangeKey] then tool:SetAttribute(rangeKey, originalAttribs[rangeKey]) end
            if originalAttribs[dmgKey]   then tool:SetAttribute(dmgKey,   originalAttribs[dmgKey])   end
        end
    end
end

local function checkAndModifyFists()
    local char    = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end
    for _, tool in ipairs(char:GetChildren()) do
        if isMeleeByName(tool) then modifyFists(tool, meleeAuraEnabled) end
    end
    for _, tool in ipairs(backpack:GetChildren()) do
        if isMeleeByName(tool) then modifyFists(tool, meleeAuraEnabled) end
    end
end

RunService.Heartbeat:Connect(function()
    if meleeAuraEnabled then checkAndModifyFists() end
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if meleeAuraEnabled then checkAndModifyFists() end
end)

-- ══════════════════════════════════════════════════════════════
--  High Jump (Hit Jump)
-- ══════════════════════════════════════════════════════════════
local jumpConn_HJ
local function setupHighJump(char)
    if not jumpPowerEnabled then return end
    local humanoid = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    humanoid.UseJumpPower = true
    humanoid.JumpPower = 60
    if jumpConn_HJ then pcall(function() jumpConn_HJ:Disconnect() end) end
    jumpConn_HJ = game:GetService("UserInputService").JumpRequest:Connect(function()
        if not jumpPowerEnabled then return end
        if hrp then
            local look = hrp.CFrame.LookVector
            hrp.Velocity = look * 80 + Vector3.new(0, 100, 0)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if jumpPowerEnabled then setupHighJump(char) end
end)

-- ══════════════════════════════════════════════════════════════
--  Hotbar lock / Sell Bypass / Emotes
-- ══════════════════════════════════════════════════════════════
local function lockTool(tool)
    if tool and tool:IsA("Tool") then
        pcall(function() tool:SetAttribute("Locked", true) end)
    end
end

local function setupBackpack(backpack)
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do lockTool(tool) end
    backpack.ChildAdded:Connect(lockTool)
end

local function initBackpack()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        setupBackpack(backpack)
    else
        LocalPlayer.ChildAdded:Connect(function(child)
            if child:IsA("Backpack") then setupBackpack(child) end
        end)
    end
end

initBackpack()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    initBackpack()
end)

task.wait(2)
print("Bypass hotbar inf")

-- Sell button bypass
local ok, sellBtn = pcall(function() return BuyPromptUI.get("SellPromptSellButton") end)
if ok and sellBtn then
    local holdStroke = sellBtn:FindFirstChild("HoldStroke", true)
    if holdStroke then
        holdStroke.Enabled = false
        local grad = holdStroke:FindFirstChildOfClass("UIGradient")
        if grad then grad.Enabled = false end
    end
    for _, v in pairs(sellBtn:GetDescendants()) do
        if v:IsA("NumberValue") then v.Value = 1 end
    end
end

task.wait(2)
print("Bypass")

-- Tween bypass (instant)
local origTween = Util.tween
Util.tween = function(obj, info, target)
    if obj and obj:IsA("NumberValue") and target and target.Value ~= nil then
        obj.Value = target.Value
        return { Cancel = function() end }
    end
    return origTween(obj, info, target)
end

-- Emote hooks
local function hookButton(btn)
    if not btn then return end
    if btn:FindFirstChild("UnlocksAtText") then btn.UnlocksAtText.Visible = false end
    if btn:FindFirstChild("EmoteName")     then btn.EmoteName.Visible = true      end
    CoreUI.on_click(btn, function()
        local hum = CharModule.get_hum()
        if not hum or hum.Health <= 0 then return end
        if EmotesUI.current_emote_playing.get() == btn then
            EmotesUI.current_emote_playing.set(nil)
        else
            EmotesUI.current_emote_playing.set(btn)
        end
        task.wait(0.12)
        EmotesUI.enabled.set(false)
    end)
    EmotesUI.current_emote_playing.hook(function(current)
        if btn:FindFirstChild("EmoteEquipped") then
            btn.EmoteEquipped.Visible = (current == btn)
        end
    end)
end

local function hookAllEmotes()
    for _, emote in pairs(EmotesList) do
        local btn = CoreUI.get("EmoteTemplate").Parent:FindFirstChild(emote.name)
        hookButton(btn)
    end
end

hookAllEmotes()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    hookAllEmotes()
end)

-- ══════════════════════════════════════════════════════════════
--  Character Spawn & Input Connections
-- ══════════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(setupCharacter)
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    snapY   = nil
    snapActive = false
    lockYPosition()
end)
lockYPosition()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    autoAttackRunning = false
    task.wait(0.1)
    startAutoAttack()
end)
startAutoAttack()

-- Re-setup humanoid jump connection on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
end)

-- CharacterAdded keep Character updated
LocalPlayer.CharacterAdded:Connect(function(char) Character = char end)

-- Key bindings
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G and WindUI and Window then
        if Window.Toggle then Window:Toggle()
        elseif Window.SetVisible then Window:SetVisible(not Window.Visible) end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Z and snapUnderMapEnabled then
        toggleSnap()
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if inventoryESPEnabled then
            wait(0.2)
            createBillboardForPlayer(player)
        end
        if espData[player] and espData[player].drawings then
            local nameDraw = espData[player].drawings[1]
            nameDraw.Color = isPlayerExcluded(player.Name)
                and Color3.fromRGB(0, 255, 0)
                or  Color3.fromRGB(255, 255, 255)
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
--  ██  UI TABS  ██
-- ══════════════════════════════════════════════════════════════

-- ── TAB: COMBAT ───────────────────────────────────────────────
local CombatTab = Window:Tab({ Title = "COMBAT:", Icon = "crosshair" })
CombatTab:Section({ Title = "GUN:" })

local SilentAimToggle = CombatTab:Toggle({
    Title   = "Silent Aim",
    Default = false,
    Callback = function(v)
        silentAimEnabled = v
        aimTarget = nil
    end,
})
Config:Register("SilentAim", SilentAimToggle)

local RedLineToggle = CombatTab:Toggle({
    Title   = "Red Line Lock",
    Default = false,
    Callback = function(v)
        redLineLockEnabled = v
        aimTarget = nil
    end,
})
Config:Register("SilentAimAttach", RedLineToggle)

local FOVSlider = CombatTab:Slider({
    Title = "FOV: ",
    Step  = 1,
    Value = { Min = 20, Max = 800, Default = fovRadius },
    Callback = function(v)
        fovRadius = tonumber(v) or 120
    end,
})
Config:Register("FOVRadius", FOVSlider)

local function getPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

local FriendDropdown = CombatTab:Dropdown({
    Title    = "Safe Friend",
    Desc     = "Select players to whitelist",
    Values   = getPlayerNames(),
    Default  = {},
    Multi    = true,
    Callback = function(v)
        excludedPlayers = {}
        if type(v) == "table" then
            for name, selected in pairs(v) do
                if type(name) == "string" and selected == true then
                    table.insert(excludedPlayers, name)
                end
            end
            if #excludedPlayers == 0 then
                for _, name in ipairs(v) do
                    if type(name) == "string" then
                        table.insert(excludedPlayers, name)
                    end
                end
            end
        end
        for _, player in pairs(Players:GetPlayers()) do
            if espData[player] and espData[player].drawings then
                espData[player].drawings[1].Color =
                    isPlayerExcluded(player.Name) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
            end
        end
    end,
})
Config:Register("FriendsList", FriendDropdown)

Players.PlayerAdded:Connect(function()
    pcall(function() FriendDropdown:Refresh(getPlayerNames(), true) end)
end)
Players.PlayerRemoving:Connect(function()
    pcall(function() FriendDropdown:Refresh(getPlayerNames(), true) end)
end)

pcall(function() CombatTab:Divider() end)

-- ── TAB: WEAPON ───────────────────────────────────────────────
local WeaponTab = Window:Tab({ Title = "WEAPON:", Icon = "layers" })
WeaponTab:Section({ Title = "MODS:" })

WeaponTab:Slider({
    Title = "Fire Rate",
    Step  = 10,
    Value = { Min = 100, Max = 3000, Default = 1000 },
    Callback = function(v) getEnv().FireRateValue = v end,
})

WeaponTab:Slider({
    Title = "Accuracy",
    Step  = 0.01,
    Value = { Min = 0, Max = 1, Default = 1 },
    Callback = function(v) getEnv().AccuracyValue = v end,
})

WeaponTab:Slider({
    Title = "Recoil",
    Step  = 0.1,
    Value = { Min = 0, Max = 10, Default = 0 },
    Callback = function(v) getEnv().RecoilValue = v end,
})

WeaponTab:Slider({
    Title = "Reload Time",
    Step  = 0.1,
    Value = { Min = 0.1, Max = 10, Default = 0.1 },
    Callback = function(v) getEnv().ReloadValue = v end,
})

WeaponTab:Toggle({
    Title = "Automatic",
    Icon  = "check",
    Type  = "Checkbox",
    Value = false,
    Callback = function(v)
        getEnv().automatic         = v
        getEnv().GunModsAutoApply  = v
        if v and WindUI then WindUI:Notify({ Title = "✅ Auto Modify", Duration = 2 }) end
    end,
})

WeaponTab:Section({ Title = "COMBAT" })

Config:Register("Fists Modifier", WeaponTab:Toggle({
    Title   = "Melee Aura",
    Desc    = "WideFists",
    Default = false,
    Callback = function(v)
        meleeAuraEnabled = v
        checkAndModifyFists()
    end,
}))

local AutoAttackToggle = WeaponTab:Toggle({
    Title   = "Auto Attack",
    Default = false,
    Callback = function(v) autoAttackEnabled = v end,
})
Config:Register("AutoAttack_Enabled", AutoAttackToggle)

-- ── TAB: ESP ──────────────────────────────────────────────────
local ESPTab = Window:Tab({ Title = "ESP:", Icon = "eye" })
ESPTab:Section({ Title = "Visual:" })

local InventoryESPToggle = ESPTab:Toggle({
    Title   = "Inventory Viewer",
    Default = false,
    Callback = function(v)
        inventoryESPEnabled = v
        if v then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    createBillboardForPlayer(player)
                end
            end
            inventoryConn = RunService.Heartbeat:Connect(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        createBillboardForPlayer(player)
                    end
                end
            end)
            if WindUI then WindUI:Notify({ Title = "✅ ESP Items Enabled", Duration = 3 }) end
        else
            if inventoryConn then inventoryConn:Disconnect(); inventoryConn = nil end
            for _, gui in pairs(PlayerBillboards) do gui:Destroy() end
            PlayerBillboards = {}
            if WindUI then WindUI:Notify({ Title = "❌ ESP Items Disabled", Duration = 3 }) end
        end
    end,
})
Config:Register("ItemsESP", InventoryESPToggle)

local NameESPToggle = ESPTab:Toggle({
    Title   = "Name",
    Default = false,
    Callback = function(v) nameESPEnabled = v end,
})
Config:Register("NameESP", NameESPToggle)

local HealthESPToggle = ESPTab:Toggle({
    Title   = "Health",
    Default = false,
    Callback = function(v) healthESPEnabled = v end,
})
Config:Register("HealthESP", HealthESPToggle)

local DistanceESPToggle = ESPTab:Toggle({
    Title   = "Distance",
    Default = false,
    Callback = function(v) distanceESPEnabled = v end,
})
Config:Register("DistanceESP", DistanceESPToggle)

local HighlightESPToggle = ESPTab:Toggle({
    Title   = "Highlight",
    Default = false,
    Callback = function(v)
        highlightEnabled = v
        for _, player in pairs(Players:GetPlayers()) do
            updateHighlight(player)
        end
    end,
})
Config:Register("HighlightESP", HighlightESPToggle)

-- ── TAB: CHARACTER ────────────────────────────────────────────
local CharTab = Window:Tab({ Title = "CHARACTER:", Icon = "user" })
CharTab:Section({ Title = "CHARACTER:" })

local DesyncToggle = CharTab:Toggle({
    Title   = "Desync",
    Default = false,
    Callback = function(v)
        local plsraknet = Raknet or raknet
        if plsraknet and plsraknet.desync then
            plsraknet.desync(v)
        end
    end,
})

local WalkSpeedToggle = CharTab:Toggle({
    Title   = "Walk Speed",
    Default = false,
    Callback = function(v) walkSpeedEnabled = v end,
})
Config:Register("WalkSpeed", WalkSpeedToggle)

local SpeedSlider = CharTab:Slider({
    Title = "Speed Multiplier",
    Step  = 0.5,
    Value = { Min = 1, Max = 5, Default = 2 },
    Callback = function(v) speedMultiplier = v * 0.05 end,
})
Config:Register("SpeedMultiplier", SpeedSlider)

local JumpToggle = CharTab:Toggle({
    Title   = "High Jump",
    Default = false,
    Callback = function(v)
        jumpPowerEnabled = v
        if v then
            if LocalPlayer.Character then setupHighJump(LocalPlayer.Character) end
        else
            if jumpConn_HJ then pcall(function() jumpConn_HJ:Disconnect() end); jumpConn_HJ = nil end
        end
    end,
})
Config:Register("JumpPower", JumpToggle)

local AutoSprintToggle = CharTab:Toggle({
    Title   = "Infinite Stamina",
    Default = false,
    Callback = function(v)
        infiniteStaminaEnabled = v
        if v then
            local ok, SprintModule = pcall(function() return require(ReplicatedStorage.Modules.Game.Sprint) end)
            if ok and SprintModule then
                local sprintBar = getupvalue(SprintModule.consume_stamina, 2).sprint_bar
                if sprintBar then
                    local origUpdate = sprintBar.update
                    sprintBar.update = function(...) return origUpdate(function() return 1 end) end
                    getEnv().OriginalSprintUpdate = origUpdate
                    getEnv().AutoSprintLoop = task.spawn(function()
                        while infiniteStaminaEnabled do
                            pcall(function()
                                Send.send("set_sprinting_1", true)
                                task.wait(0.5)
                                Send.send("set_sprinting_1", false)
                            end)
                            task.wait(0.1)
                        end
                        pcall(function() Send.send("set_sprinting_1", false) end)
                    end)
                    if WindUI then WindUI:Notify({ Title = "✅ INF STAMINA", Duration = 3 }) end
                else
                    infiniteStaminaEnabled = false
                    AutoSprintToggle:Set(false)
                end
            else
                infiniteStaminaEnabled = false
                AutoSprintToggle:Set(false)
            end
        else
            if getEnv().AutoSprintLoop then
                task.cancel(getEnv().AutoSprintLoop)
                getEnv().AutoSprintLoop = nil
            end
            pcall(function() Send.send("set_sprinting_1", false) end)
            local ok, SprintModule = pcall(function() return require(ReplicatedStorage.Modules.Game.Sprint) end)
            if ok and SprintModule then
                local sprintBar = getupvalue(SprintModule.consume_stamina, 2).sprint_bar
                if sprintBar and getEnv().OriginalSprintUpdate then
                    sprintBar.update = getEnv().OriginalSprintUpdate
                    getEnv().OriginalSprintUpdate = nil
                end
            end
            if WindUI then WindUI:Notify({ Title = "❌ Auto Sprint Disabled", Duration = 3 }) end
        end
    end,
})
Config:Register("AutoSprint", AutoSprintToggle)

local AntiLockToggle = CharTab:Toggle({
    Title   = "Anti Lock",
    Default = false,
    Callback = function(v)
        antiLockEnabled = v
        getEnv().Sky = v
        if v then getEnv().SkyAmount = 1500 end
    end,
})
Config:Register("AntiLock", AntiLockToggle)

local AntiKillToggle = CharTab:Toggle({
    Title   = "Anti Kill",
    Default = false,
    Callback = function(v)
        antiKillEnabled = v
        if WindUI then
            WindUI:Notify({ Title = v and " Anti Kill Enabled" or "❌ Anti Kill Disabled", Duration = 3 })
        end
    end,
})
Config:Register("AntiKill", AntiKillToggle)

pcall(function() if CharTab and typeof(CharTab.Divider) == "function" then CharTab:Divider() end end)
pcall(function() if CharTab and typeof(CharTab.Section) == "function" then CharTab:Section({ Title = "Att:" }) end end)

local PickupToggle = CharTab:Toggle({
    Title   = "Pickup items",
    Default = false,
    Callback = function(v) autoPickupEnabled = v end,
})
Config:Register("PickupItems", PickupToggle)

local AntiRagdollToggle = CharTab:Toggle({
    Title   = "Anti Ragdoll",
    Default = false,
    Callback = function(enabled)
        if not enabled then return end
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local pl = game:GetService("Players").LocalPlayer
            local function findCounter2()
                for _, v in ipairs(getgc and getgc(true) or {}) do
                    if typeof(v) == "table" and rawget(v, "event") and rawget(v, "func") then return v end
                end
            end
            local ctr = findCounter2()
            if not ctr then return end
            local function sendAction(action)
                ctr.event = (ctr.event or 0) + 1
                rs:WaitForChild("Remotes"):WaitForChild("Send"):FireServer(ctr.event, action)
            end
            task.spawn(function()
                while enabled do
                    sendAction("end_ragdoll_early")
                    task.wait(0.3)
                    if not enabled then break end
                    sendAction("clear_ragdoll")
                    task.wait(0.3)
                end
            end)
        end)
    end,
})
Config:Register("AntiRagdoll", AntiRagdollToggle)

local HideNameToggle = CharTab:Toggle({
    Title   = "Hide Name",
    Default = false,
    Callback = function(v)
        pcall(function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = char:WaitForChild("HumanoidRootPart")
            local billboard = root:FindFirstChild("CharacterBillboardGui")
            if billboard then
                local nameLabel = billboard:FindFirstChild("PlayerName")
                if nameLabel and nameLabel:IsA("TextLabel") then
                    nameLabel.Visible = not v
                end
            end
        end)
    end,
})
Config:Register("HideName", HideNameToggle)

local AutoRespawnToggle = CharTab:Toggle({
    Title   = "Auto Respawn",
    Default = false,
    Callback = function(enabled)
        if not enabled then return end
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local pl = game:GetService("Players").LocalPlayer
            local function findCounter2()
                for _, v in ipairs(getgc and getgc(true) or {}) do
                    if typeof(v) == "table" and rawget(v, "event") and rawget(v, "func") then return v end
                end
            end
            local ctr = findCounter2()
            if not ctr then return end
            local function sendAction(action)
                ctr.event = (ctr.event or 0) + 1
                rs:WaitForChild("Remotes"):WaitForChild("Send"):FireServer(ctr.event, action)
            end
            task.spawn(function()
                while enabled do
                    local char = pl.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health <= 0 then
                        task.wait(6)
                        if enabled then sendAction("death_screen_request_respawn") end
                    end
                    task.wait(0.5)
                end
            end)
        end)
    end,
})
Config:Register("AutoRespawn", AutoRespawnToggle)

CharTab:Divider()
CharTab:Section({ Title = "PC HOLD (Z)" })

local SnapToggle = CharTab:Toggle({
    Title   = "Snap Under Map",
    Default = false,
    Callback = function(v)
        snapUnderMapEnabled = v
        if v then
            snapY = HRP and HRP.Position.Y or nil
            snapActive = true
            performTeleport()
        else
            snapActive = false
            snapY = nil
        end
    end,
})
Config:Register("SnapUnderMap", SnapToggle)

local SnapSlider = CharTab:Slider({
    Title = "Snap:",
    Step  = 1,
    Value = { Min = 1, Max = 100, Default = 10 },
    Callback = function(v)
        snapDepth = v
        if snapActive and HRP and snapY then
            local newPos = Vector3.new(HRP.Position.X, snapY - snapDepth, HRP.Position.Z)
            HRP.CFrame   = CFrame.new(newPos)
            snapY        = newPos.Y
        end
    end,
})
Config:Register("SnapHeight", SnapSlider)

-- ── TAB: PLAYER ───────────────────────────────────────────────
local PlayerTab = Window:Tab({ Title = "PLAYER:", Icon = "person-standing" })
PlayerTab:Section({ Title = "PLAYER:" })

local AutoFinishToggle = PlayerTab:Toggle({
    Title   = "Auto Finish",
    Default = false,
    Callback = function(v)
        autoFinishEnabled = v
        if v then
            applyToAll()
            if WindUI then WindUI:Notify({ Title = "✅ Auto Finish Enabled", Description = "✅ Auto Enabled", Duration = 3 }) end
        else
            if WindUI then WindUI:Notify({ Title = "❌ Auto Disabled", Description = "❌ Auto Disabled", Duration = 3 }) end
        end
    end,
})
Config:Register("AutoFinnish", AutoFinishToggle)
PlayerTab:Divider()

-- ── TAB: BUY ──────────────────────────────────────────────────
local BuyTab = Window:Tab({ Title = "BUY:", Icon = "landmark" })
BuyTab:Section({ Title = "BUY:" })

-- ── Balance Display ───────────────────────────────────────────
local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild("PlayerGui")

local BankBalance =
    BuyTab:Button(
    {
        Title = "🏦 Bank Balance",
        Desc = "N/A"
    }
)
local HandBalance =
    BuyTab:Button(
    {
        Title = "💸 Hand Balance",
        Desc = "N/A"
    }
)

local function HandMoney()
    return tonumber(PlayerGui.TopRightHud.Holder.Frame.MoneyTextLabel.Text:match("%$(%d+)"))
end

local function ATMMoney()
    for _, v in ipairs(PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and string.find(v.Text, "Bank Balance") then
            return tonumber(v.Text:match("%$(%d+)"))
        end
    end
    return 0
end

task.spawn(
    function()
        while task.wait(0.2) do
            BankBalance:SetDesc('<b><font color="#FFFFFF">$' .. (ATMMoney() or 0) .. "</font></b>")
            HandBalance:SetDesc('<b><font color="#FFFFFF">$' .. (HandMoney() or 0) .. "</font></b>")
        end
    end
)

pcall(function()
    local SkipCrateToggle = BuyTab:Toggle({
        Title   = "Skip Crate Spin",
        Desc    = "ข้ามการหมุนกล่องอัตโนมัติ",
        Icon    = "check",
        Type    = "Checkbox",
        Default = false,
        Callback = function(v)
            skipCrateEnabled = v
        end,
    })
    Config:Register("SkipCrate",       SkipCrateToggle)
    Config:Register("SkipCrateBackup", SkipCrateToggle)
end)

local function getCrateOptions()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local tiles = map:FindFirstChild("Tiles")
    if not tiles then return nil end
    local gunShopTile = tiles:FindFirstChild("GunShopTile")
    if not gunShopTile then return nil end
    local patriotWeapons = gunShopTile:FindFirstChild("PatriotWeapons")
    if not patriotWeapons then return nil end
    local interior = patriotWeapons:FindFirstChild("Interior")
    if not interior then return nil end
    local crates = interior:FindFirstChild("Crates")
    if not crates then return nil end
    local ammoCrate = crates:FindFirstChild("Ammo Crate")
    if not ammoCrate then return nil end
    return ammoCrate:FindFirstChild("CrateOptions")
end

-- ฟังก์ชันเปิด crate ตามประเภทกระสุนที่เลือก
local function openCrateWithType(bulletType)
    local crateOptions = getCrateOptions()
    if not crateOptions then
        warn("❌ ไม่พบ CrateOptions (อาจอยู่นอกแผนที่หรือยังไม่โหลด)")
        if WindUI then WindUI:Notify({Title = "❌ ไม่พบ Ammo Crate", Duration = 2}) end
        return
    end
    
    local targetItem = crateOptions:FindFirstChild(bulletType)
    if not targetItem then
        warn("❌ ไม่พบประเภท " .. bulletType .. " ใน CrateOptions")
        if WindUI then WindUI:Notify({Title = "❌ ไม่มี " .. bulletType .. " ใน crate", Duration = 2}) end
        return
    end
    
    -- เรียก NetGet (ฟังก์ชันที่มีอยู่แล้วในสคริปต์หลัก)
    local result = netGet("open_crate", targetItem, "money")
    if result then
        print("✅ เปิด crate สำเร็จ ประเภท:", bulletType)
        if WindUI then WindUI:Notify({Title = "🔫 เปิด " .. bulletType .. " สำเร็จ", Duration = 2}) end
    else
        warn("❌ เปิด crate ล้มเหลว")
        if WindUI then WindUI:Notify({Title = "❌ เปิด crate ไม่สำเร็จ", Duration = 2}) end
    end
end

-- ตัวแปรเก็บประเภทที่เลือกจาก dropdown
local selectedBulletType = "Pistol"

-- Dropdown แบบเลือกเดี่ยว (ใช้ syntax WindUI)
local bulletDropdown = BuyTab:Dropdown({
    Title = "เลือกประเภทกระสุน",
    Values = {"Pistol", "Rifle", "Shotgun", "Random"},
    Value = "Pistol",          -- ค่าเริ่มต้น
    Multi = false,             -- เลือกได้แค่ค่าเดียว
    Callback = function(selected)
        selectedBulletType = selected
        if selected == "Random" then
            print("🎲 โหมดสุ่ม: จะสุ่ม Pistol / Rifle / Shotgun เมื่อกดเปิด")
        else
            print("🔫 เลือกประเภท: " .. selected)
        end
    end
})

BuyTab:Button({
    Title = "เปิด Ammo Crate",
    Desc = "ใช้ประเภทกระสุนที่เลือกจาก dropdown",
    Callback = function()
        local useType = selectedBulletType
        if useType == "Random" then
            local options = {"Pistol", "Rifle", "Shotgun"}
            useType = options[math.random(1, #options)]
           
            if WindUI then WindUI:Notify({Title = "สุ่มได้ " .. useType, Duration = 1}) end
        end
        openCrateWithType(useType)
    end
})

-- ── TAB: MISC ─────────────────────────────────────────────────
local MiscTab = Window:Tab({ Title = "MISC:", Icon = "warehouse" })
local placeId = game.PlaceId

MiscTab:Input({
    Title       = "Server Hop by ID",
    Value       = "",
    InputIcon   = "send",
    Type        = "Input",
    Placeholder = "id sever here!",
    Callback = function(v)
        if not v or v == "" then return end
        local ids = {}
        for id in string.gmatch(v, "[%w%-]+") do table.insert(ids, id) end
        for _, id in ipairs(ids) do
            print("กำลังวาร์ปไปเซิร์ฟ:", id)
            task.wait(0.5)
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, id, LocalPlayer)
            end)
        end
    end,
})

MiscTab:Button({
    Title = "Server Rejoin",
    Desc  = "Come back old sever",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(
            game.PlaceId, game.JobId, LocalPlayer
        )
    end,
})

MiscTab:Button({
    Title  = "Server Hop",
    Desc   = "Hop to a new server (sometime don't work)",
    Locked = false,
    Callback = function()
        local HttpService     = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local targetPlace     = 104715542330896

        local ok, data = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. targetPlace ..
                    "/servers/Public?sortOrder=Desc&limit=100"
                )
            )
        end)

        if not ok or not data or not data.data then
            warn("ไม่สามารถดึงข้อมูลเซิร์ฟเวอร์ได้เลยพี่")
            return
        end

        local available = {}
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(available, server)
            end
        end

        if #available == 0 then
            warn("ไม่มีเซิร์ฟเวอร์ว่างเลยพี่ขณะนี้")
            return
        end

        table.sort(available, function(a, b) return a.playing > b.playing end)

        game.StarterGui:SetCore("SendNotification", {
            Title    = "Server Hop",
            Text     = "กำลังย้ายไปเซิร์ฟเวอร์คนเยอะ...",
            Duration = 3,
        })

        TeleportService:TeleportToPlaceInstance(targetPlace, available[1].id, LocalPlayer)
    end,
})

MiscTab:Divider()

MiscTab:Button({
    Title    = "Claim All Quest",
    Callback = function()
        task.spawn(function()
            local ok, err = pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local pl = game:GetService("Players").LocalPlayer
                local function findCounter2()
                    for _, v in ipairs(getgc and getgc(true) or {}) do
                        if typeof(v) == "table" and rawget(v, "event") and rawget(v, "func") then return v end
                    end
                    return nil
                end
                local ctr = findCounter2()
                if not ctr then return end
                local remote = {}
                function remote.get(...)
                    local args = { ... }
                    ctr.func = (ctr.func or 0) + 1
                    local get = rs:WaitForChild("Remotes"):WaitForChild("Get")
                    return get:InvokeServer(ctr.func, table.unpack(args))
                end
                local questFrame = pl:WaitForChild("PlayerGui")
                    :WaitForChild("Quests")
                    :WaitForChild("QuestsHolder")
                    :WaitForChild("QuestsScrollingFrame")
                for _, child in ipairs(questFrame:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("ImageButton") then
                        remote.get("claim_quest", child.Name)
                        task.wait(0.2)
                    end
                end
            end)
            if ok then print("Claim All Quests Completed") else warn(err) end
        end)
    end,
})
Config:Register("ClaimAllQuest", MiscTab)

-- ── Config Management ─────────────────────────────────────────
MiscTab:Section({ Title = "Config Management" })

local SaveBtn = MiscTab:Button({
    Title    = "Save Config",
    Callback = function()
        if Config.Save then Config.Save(Config) end
    end,
})
Config:Register("SaveConfig", SaveBtn)

local DeleteBtn = MiscTab:Button({
    Title    = "Delete Config",
    Callback = function()
        if Config.Delete then Config.Delete(Config) end
    end,
})
Config:Register("DeleteConfig", DeleteBtn)

-- =========================
-- Boost FPS (ภาพกาก)
-- =========================

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local function Bootsfps()
	-- ลบท้องฟ้า + เอฟเฟกต์
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("Sky")
		or v:IsA("Atmosphere")
		or v:IsA("BloomEffect")
		or v:IsA("SunRaysEffect")
		or v:IsA("ColorCorrectionEffect")
		or v:IsA("DepthOfFieldEffect") then
			v:Destroy()
		end
	end

	-- ปิดเงา / แสง
	Lighting.GlobalShadows = false
	Lighting.Brightness = 0
	Lighting.FogEnd = 9e9
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0

	-- Terrain กาก
	if Terrain then
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterReflectance = 0
		Terrain.WaterTransparency = 1
	end

	-- ทำทั้งแมพเป็นสีเทา / plastic
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Material = Enum.Material.Plastic
			v.Reflectance = 0
			v.CastShadow = false
			v.Color = Color3.fromRGB(120,120,120)

		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1

		elseif v:IsA("ParticleEmitter")
		or v:IsA("Trail")
		or v:IsA("Beam") then
			v.Enabled = false
		end
	end
end

-- =========================
-- Button ใน Tab Misc
-- =========================

MiscTab:Button({
	Title = "Bootsfps",
	Icon = "zap",
	Callback = function()
		Bootsfps()
	end
})

-- =========================
-- RTX ON ULTRA (ภาพโคตรสวย)
-- =========================

local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local function RTX_ON()
	-- ล้างของเก่า
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("Atmosphere")
		or v:IsA("BloomEffect")
		or v:IsA("SunRaysEffect")
		or v:IsA("ColorCorrectionEffect")
		or v:IsA("DepthOfFieldEffect")
		or v:IsA("Sky") then
			v:Destroy()
		end
	end

	-- ===== Sky =====
	local Sky = Instance.new("Sky")
	Sky.SkyboxBk = "rbxassetid://159454299"
	Sky.SkyboxDn = "rbxassetid://159454296"
	Sky.SkyboxFt = "rbxassetid://159454293"
	Sky.SkyboxLf = "rbxassetid://159454286"
	Sky.SkyboxRt = "rbxassetid://159454300"
	Sky.SkyboxUp = "rbxassetid://159454288"
	Sky.SunAngularSize = 21
	Sky.Parent = Lighting

	-- ===== Lighting Core =====
	Lighting.Technology = Enum.Technology.Future
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 1
	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0.25
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ClockTime = 14

	-- ===== Atmosphere =====
	local Atmosphere = Instance.new("Atmosphere")
	Atmosphere.Density = 0.35
	Atmosphere.Offset = 0.25
	Atmosphere.Color = Color3.fromRGB(190, 210, 255)
	Atmosphere.Decay = Color3.fromRGB(120, 150, 200)
	Atmosphere.Glare = 0.35
	Atmosphere.Haze = 1.2
	Atmosphere.Parent = Lighting

	-- ===== Bloom =====
	local Bloom = Instance.new("BloomEffect")
	Bloom.Intensity = 1.2
	Bloom.Size = 56
	Bloom.Threshold = 0.85
	Bloom.Parent = Lighting

	-- ===== Sun Rays =====
	local SunRays = Instance.new("SunRaysEffect")
	SunRays.Intensity = 0.25
	SunRays.Spread = 0.85
	SunRays.Parent = Lighting

	-- ===== Color Correction =====
	local CC = Instance.new("ColorCorrectionEffect")
	CC.Brightness = 0.05
	CC.Contrast = 0.25
	CC.Saturation = 0.35
	CC.TintColor = Color3.fromRGB(255, 245, 235)
	CC.Parent = Lighting

	-- ===== Depth Of Field =====
	local DOF = Instance.new("DepthOfFieldEffect")
	DOF.FarIntensity = 0.25
	DOF.NearIntensity = 0.05
	DOF.FocusDistance = 60
	DOF.InFocusRadius = 40
	DOF.Parent = Lighting

	-- ===== Terrain น้ำใส =====
	if Terrain then
		Terrain.WaterWaveSize = 1
		Terrain.WaterWaveSpeed = 15
		Terrain.WaterReflectance = 1
		Terrain.WaterTransparency = 0.05
	end

	-- ===== วัสดุเงาสวย =====
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CastShadow = true
			if v.Material == Enum.Material.Plastic then
				v.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

-- =========================
-- Button (Tab Misc)
-- =========================

MiscTab:Button({
	Title = "RTX ON",
	Icon = "sparkles",
	Callback = function()
		RTX_ON()
	end
})

MiscTab:Button({
	Title = "Frustum Culling",
	Icon = "eye",
	Callback = function()
		Objects = workspace:GetDescendants()
		game:GetService("RunService").RenderStepped:Connect(function()
			loadVisibleObjects(Camera, Objects)
		end)
	end
})

if Config.Load then Config.Load(Config) end
