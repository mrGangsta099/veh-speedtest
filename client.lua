-- Configuration
local Config = {
    speedUnit = 'km/h', -- Speed unit ('km/h', 'mph')
    sounds = true, -- Enable sounds
    milestones = true, -- Enable speed milestones
    hudPosition = {x = 0.085, y = 0.75},
    hudSize = {width = 0.14, height = 0.08}
}

local SpeedTest = {
    isActive = false,
    startTime = 0,
    targetSpeed = 0,
    milestones = {},
    currentTime = "00:00.000",
    vehicle = 0,
    player = 0,
    milestonesReached = {},
    saveChronos = {},
    lastSpeed = 0,
    updateThread = nil,
    controlThread = nil,
    updateHUDThread = nil
}

-- Utilities
local function formatTime(milliseconds)
    local minutes = math.floor(milliseconds / 60000)
    local seconds = math.floor(milliseconds % 60000 / 1000)
    local ms = milliseconds % 1000
    return string.format("%02d:%02d.%03d", minutes, seconds, ms)
end

local function showNotification(message, type)
    local colors = {
        success = { 46, 204, 113 },
        error = { 231, 76, 60 },
        info = { 52, 152, 219 },
        warning = { 241, 196, 15 }
    }

    TriggerEvent('chat:addMessage', {
        color = colors[type] or colors.info,
        multiline = true,
        args = {"🏁 SpeedTest", message}
    })
end

local function playSound(soundName)
    if Config.sounds then PlaySoundFrontend(-1, soundName, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1) end
end

-- Modern and compact user interface
local function drawModernHUD()
    if not SpeedTest.isActive then return end

    local pos = Config.hudPosition
    local size = Config.hudSize

    -- Main background, very subtle
    DrawRect(pos.x, pos.y, size.width, size.height, 0, 0, 0, 120)

    -- Thin progress bar at the bottom
    local progress = math.min(SpeedTest.lastSpeed / SpeedTest.targetSpeed, 1.0)
    local barColor = progress >= 1.0 and {46, 204, 113} or {52, 152, 219}
    local barHeight = 0.002
    DrawRect(pos.x, pos.y + size.height/2 - barHeight/2, size.width * progress, barHeight, barColor[1], barColor[2], barColor[3], 200)

    -- Main time (smaller and centered)
    SetTextFont(4)
    SetTextScale(0.0, 0.42)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(SpeedTest.currentTime)
    EndTextCommandDisplayText(pos.x, pos.y - 0.024)

    -- Speed and target (very small)
    SetTextFont(0)
    SetTextScale(0.0, 0.32)
    SetTextColour(160, 160, 160, 200)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(string.format("%d/%d %s", SpeedTest.lastSpeed, SpeedTest.targetSpeed, Config.speedUnit))
    EndTextCommandDisplayText(pos.x, pos.y + 0.008)
end

-- Add speed milestones
local function addMilestones(targetSpeed)
    local minSpeed = Config.speedUnit == 'km/h' and 100 or 62 -- Minimum speed for milestones (100 km/h or 62 mph)
    SpeedTest.milestones = {}
    if targetSpeed >= minSpeed then
        local step = 50 -- Every 50 kmh or mph
        for speed = step, targetSpeed, step do
            table.insert(SpeedTest.milestones, speed)
        end
    end
end

-- Speed milestone management
local function checkSpeedMilestones(currentSpeed)
    for _, speedMilestone in ipairs(SpeedTest.milestones) do
        if currentSpeed >= speedMilestone and not SpeedTest.milestonesReached[speedMilestone] then
            SpeedTest.milestonesReached[speedMilestone] = true
            showNotification(string.format("📈 %d %s reached (%s)", speedMilestone, Config.speedUnit, SpeedTest.currentTime), "info")
            print(string.format("[SpeedTest] Milestone reached: %d %s at %s", speedMilestone, Config.speedUnit, SpeedTest.currentTime))
            playSound("WAYPOINT_SET")
        end
    end
end

-- Save and check records
local function saveChrono(model, speed, timeString, timeMs, vehicleInfo)
    SpeedTest.saveChronos[model] = SpeedTest.saveChronos[model] or {}
    SpeedTest.saveChronos[model][speed] = SpeedTest.saveChronos[model][speed] or {}
    SpeedTest.saveChronos[model][speed].timeMs = timeMs
    SpeedTest.saveChronos[model][speed].timeString = timeString
    SpeedTest.saveChronos[model][speed].vehicleInfo = vehicleInfo
    playSound("INFO")
end

-- Start condition validation
local function validateStartConditions(speedLimit)
    local limit = tonumber(speedLimit)

    -- Input validation
    if not limit then
        showNotification("❌ Invalid speed", "error")
        print("[SpeedTest] Error: Invalid speed input")
        return false
    end

    -- Player check
    SpeedTest.player = PlayerPedId()
    if not SpeedTest.player or SpeedTest.player == 0 then
        showNotification("❌ Player error", "error")
        print("[SpeedTest] Error: Player not found")
        return false
    end

    -- Vehicle check
    SpeedTest.vehicle = GetVehiclePedIsIn(SpeedTest.player, false)
    if SpeedTest.vehicle == 0 then
        showNotification("❌ You must be in a vehicle", "error")
        print("[SpeedTest] Error: No vehicle found")
        return false
    end

    -- Check if a timer is already active
    if SpeedTest.isActive then
        showNotification("⚠️ A timer is already running", "warning")
        print("[SpeedTest] Warning: Timer already active")
        return false
    end

    return limit
end

-- Main update thread
local function startUpdateThread()
    if SpeedTest.updateThread then return end

    SpeedTest.updateThread = CreateThread(function()
        while SpeedTest.isActive do
            Wait(0)

            -- Check if the vehicle still exists
            if not DoesEntityExist(SpeedTest.vehicle) then
                showNotification("❌ Vehicle lost", "error")
                SpeedTest:stop()
                break
            end

            -- Calculate current speed
            local speedMultiplier = Config.speedUnit == 'km/h' and 3.6 or 2.23694 -- km/h or mph
            local currentSpeed = math.floor((GetEntitySpeed(SpeedTest.vehicle) * speedMultiplier) + 0.5)
            SpeedTest.lastSpeed = currentSpeed

            -- Calculate elapsed time
            local elapsedTime = GetGameTimer() - SpeedTest.startTime
            SpeedTest.currentTime = formatTime(elapsedTime)

            -- Check milestones
            if Config.milestones then checkSpeedMilestones(currentSpeed) end

            -- Check if target speed is reached
            if currentSpeed >= SpeedTest.targetSpeed then
                SpeedTest:onSpeedReached(currentSpeed, elapsedTime)
                break
            end
        end

        SpeedTest.updateThread = nil
    end)
end

-- Control thread
local function startControlThread()
    if SpeedTest.controlThread then return end

    local notControlPressed = true
    SpeedTest.controlThread = CreateThread(function()
        while SpeedTest.isActive and notControlPressed do
            Wait(0)

            -- Check if the button accelerate has been pressed
            if IsControlJustPressed(0, 71) then
                notControlPressed = true
                startUpdateThread()
            end
        end

        SpeedTest.controlThread = nil
    end)
end

-- Main methods
function SpeedTest:start(speedLimit)
    local validSpeed = validateStartConditions(speedLimit)
    if not validSpeed then return end

    -- Initialization
    self.isActive = true
    self.targetSpeed = validSpeed
    self.startTime = GetGameTimer()
    self.currentTime = "00:00.000"
    self.milestonesReached = {}
    self.lastSpeed = 0

    -- Add milestones
    if Config.milestones then addMilestones(self.targetSpeed) end

    -- Interface
    TriggerEvent("startHUDThread")

    -- Info messages
    showNotification(string.format("🚀 Timer started - Target: %d %s", validSpeed, Config.speedUnit), "info")
    playSound("RACE_COUNTDOWN_GENERAL")

    -- Start control thread
    startControlThread()

    print(string.format("[SpeedTest] Timer started - Target: %d %s", validSpeed, Config.speedUnit))
end

function SpeedTest:stop()
    if not self.isActive then
        showNotification("ℹ️ No timer running", "info")
        return
    end

    self.isActive = false
    showNotification("🛑 Timer stopped", "warning")
    playSound("WAYPOINT_CLEAR")

    print("[SpeedTest] Timer stopped manually")
end

function SpeedTest:onSpeedReached(finalSpeed, totalTime)
    self.isActive = false

    local model = GetEntityModel(self.vehicle)
    local vehName = GetDisplayNameFromVehicleModel(model)
    local manufacturer = GetMakeNameFromVehicleModel(model)
    local label = GetLabelText(vehName)
    label = label ~= "NULL" and label or vehName
    local vehInfo = string.format("%s %s", manufacturer, label)

    local timeString = formatTime(totalTime)
    saveChrono(model, self.targetSpeed, timeString, totalTime, vehInfo)

    -- Success message
    local successMsg = string.format("🚗 %s - ⏱️ Time: %s", vehInfo, timeString, finalSpeed)

    showNotification(successMsg, "success")

    print(string.format("[SpeedTest] Target reached - Vehicle: %s, Time: %s, Speed: %d %s", vehInfo, timeString, finalSpeed, Config.speedUnit))
end

function SpeedTest:getChronos()
    if next(self.saveChronos) == nil then
        showNotification("⏱️ No records", "info")
        return
    end

    showNotification("📊 Records:", "info")
    for _, speeds in pairs(self.saveChronos) do
        print(string.format("[SpeedTest] Records for model: %s", _))
        for speed, data in pairs(speeds) do
            showNotification(string.format("   %s - %d %s - %s", data.vehicleInfo, speed, Config.speedUnit, data.timeString), "info")
            print(string.format("[SpeedTest] Record - Vehicle: %s, Speed: %d %s, Time: %s", data.vehicleInfo, speed, Config.speedUnit, data.timeString))
        end
    end
end

-- Commands
RegisterCommand("startrun", function(raw, args, command)
    if args[1] == nil then
        showNotification(string.format("❌ You must enter a speed (/startrun <speed_in_%s>).", Config.speedUnit), "error")
        print("[SpeedTest] Error: No speed provided")
        return
    end
    SpeedTest:start(args[1])
end, false)

RegisterCommand("stoprun", function()
    SpeedTest:stop()
end, false)

RegisterCommand("showchrono", function()
    SpeedTest:getChronos()
end, false)

-- HUD display thread
AddEventHandler("startHUDThread", function()
    if SpeedTest.updateHUDThread then return end

    SpeedTest.updateHUDThread = CreateThread(function()
        while SpeedTest.isActive do
            Wait(0)
            drawModernHUD()
        end

        SpeedTest.updateHUDThread = nil
    end)
end)

-- Cleanup on disconnect
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SpeedTest:stop()
    end
end)

print("^2[SpeedTest]^7 Client loaded successfully!")
