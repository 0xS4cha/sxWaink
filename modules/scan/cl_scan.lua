SX.Scan = {}
SX.Modules:Register("Scan", 20)

local BLOCKED_CONTROLS = { 21, 24, 37, 69, 70, 92, 114, 140, 141, 142, 257, 263, 264 }
local DISABLE_MELEE_FLAG = 122
local SCAN_CONTROLS = { 24, 69, 92 }
local SHAPE_TEST_FLAGS = 1 | 2 | 16
local PLATE_SIDES = {
    [0] = 'both', [1] = 'both', [2] = 'both', [3] = 'both', [4] = 'both', [5] = 'both', [6] = 'both',
    [7] = 'both', [8] = 'rear', [9] = 'both', [10] = 'both', [11] = 'both', [12] = 'both', [17] = 'both',
    [18] = 'both', [19] = 'both', [20] = 'both',
}

local running = false
local busy = false
local cooldownUntil = 0
local lockedEntity = nil
local widgetUntil = 0
local warnUntil = 0

local function rotationToDirection(rotation)
    local x = math.rad(rotation.x)
    local z = math.rad(rotation.z)
    local length = math.abs(math.cos(x))
    return vector3(-math.sin(z) * length, math.cos(z) * length, math.sin(x))
end

local function canScan(ped)
    return not IsEntityDead(ped) and not IsPauseMenuActive() and not IsNuiFocused()
end

local function getTarget(ped)
    local origin = GetGameplayCamCoord()
    local pedCoords = GetEntityCoords(ped)
    local reach = Config.Scan.distance + #(origin - pedCoords)
    local destination = origin + rotationToDirection(GetGameplayCamRot(2)) * reach

    local ignore = GetVehiclePedIsIn(ped, false)
    if ignore == 0 then ignore = ped end

    local handle = StartExpensiveSynchronousShapeTestLosProbe(origin.x, origin.y, origin.z, destination.x, destination.y, destination.z, SHAPE_TEST_FLAGS, ignore, 7)
    local _, hit, _, _, entity = GetShapeTestResult(handle)

    if hit ~= 1 or entity == 0 or GetEntityType(entity) ~= 2 then return nil end
    if #(pedCoords - GetEntityCoords(entity)) > Config.Scan.distance then return nil end

    return entity
end

local function relativeSpeed(ped, entity)
    local own = GetVehiclePedIsIn(ped, false)
    if own == 0 then own = ped end
    return #(GetEntityVelocity(entity) - GetEntityVelocity(own))
end

local function isPlateVisible(entity)
    local sides = PLATE_SIDES[GetVehicleClass(entity)]
    if not sides then return true end

    local toCamera = GetGameplayCamCoord() - GetEntityCoords(entity)
    local length = math.sqrt(toCamera.x * toCamera.x + toCamera.y * toCamera.y)
    if length < 0.01 then return true end

    local forward = GetEntityForwardVector(entity)
    local alignment = (forward.x * toCamera.x + forward.y * toCamera.y) / length
    local limit = math.cos(math.rad(Config.Scan.plateAngle))

    return alignment <= -limit or (sides == 'both' and alignment >= limit)
end

local function getBlockReason(ped, entity)
    if relativeSpeed(ped, entity) > Config.Scan.maxSpeed then
        return 'too_fast'
    end
    if not isPlateVisible(entity) then
        return 'plate_hidden'
    end
    return nil
end

local function getScanDuration(ped, entity)
    local settings = Config.Scan
    local distance = math.min(#(GetEntityCoords(ped) - GetEntityCoords(entity)) / settings.distance, 1.0)
    local speed = math.min(relativeSpeed(ped, entity) / settings.maxSpeed, 1.0)
    return settings.duration * (1.0 + settings.distanceFactor * distance) * (1.0 + settings.speedFactor * speed)
end

local function isScanJustPressed()
    for _, control in ipairs(SCAN_CONTROLS) do
        if IsDisabledControlJustPressed(0, control) then return true end
    end
    return false
end

local function isScanPressed()
    for _, control in ipairs(SCAN_CONTROLS) do
        if IsDisabledControlPressed(0, control) then return true end
    end
    return false
end

local function restrict(ped)
    for _, control in ipairs(BLOCKED_CONTROLS) do
        DisableControlAction(0, control, true)
    end
    DisablePlayerFiring(PlayerId(), true)
    SetPedConfigFlag(ped, DISABLE_MELEE_FLAG, true)
end

local function labelOrRaw(label)
    if not label or label == '' then return '' end
    local text = GetLabelText(label)
    if text == 'NULL' or text == '' then return label end
    return text
end

function SX.Scan:BuildVehicle(entity, owner, plate)
    local model = GetEntityModel(entity)
    local performance, details = SX.Scanner:GetVehicleStats(entity)

    return {
        brand = labelOrRaw(GetMakeNameFromVehicleModel(model)),
        model = labelOrRaw(GetDisplayNameFromVehicleModel(model)),
        plate = plate or Utils.Trim(GetVehicleNumberPlateText(entity)),
        owner = owner,
        locked = GetVehicleDoorLockStatus(entity) >= 2,
        performance = performance,
        details = details,
    }
end

local function complete(entity)
    busy = true
    SX.Feedback:Play('shutter')
    local netId = NetworkGetEntityIsNetworked(entity) and VehToNet(entity) or 0

    CreateThread(function()
        local result = TriggerServerCallback('sxWaink:scan', netId) or { ok = false, error = 'timeout' }
        cooldownUntil = GetGameTimer() + Config.Scan.cooldown
        busy = false

        if not result.ok then
            SX.Feedback:Play('fail')
            Bridge.Notify(GetPhrase('error_' .. tostring(result.error)), 'error')
            if result.error == 'not_allowed' then
                SX.Scanner:SetActive(false)
            end
            return
        end

        if not running or not DoesEntityExist(entity) then return end

        SX.Feedback:Play('success')
        local data = result.data or {}
        local vehicle = SX.Scan:BuildVehicle(entity, data.owner, data.plate)
        lockedEntity = entity
        widgetUntil = GetGameTimer() + Config.Scan.widgetDuration
        SX.Scanner:ShowWidget(vehicle)
        SX.Scanner:PushScan(vehicle)
    end)
end

local function decay(progress)
    return math.max(0.0, progress - GetFrameTime() * Config.Scan.decay)
end

local function loop()
    local target = nil
    local progress = 0.0
    local sentState, sentProgress = nil, -1

    while running do
        local ped = PlayerPedId()
        local now = GetGameTimer()
        local entity = canScan(ped) and getTarget(ped) or nil
        local state, shown = 'idle', 0.0

        restrict(ped)

        if busy then
            state, shown = 'scanning', 1.0
        elseif entity and entity == lockedEntity and SX.Scanner:IsWidgetVisible() then
            state, shown = 'locked', 1.0
        else
            if entity ~= target and progress <= 0.0 then
                target = entity
            end

            local blocked = entity and getBlockReason(ped, entity)

            if blocked then
                state = 'blocked'
                progress = decay(progress)
                if isScanJustPressed() and now >= warnUntil then
                    warnUntil = now + 2000
                    SX.Feedback:Play('blocked')
                    Bridge.Notify(GetPhrase('error_' .. blocked), 'error')
                end
            elseif entity and entity == target and now >= cooldownUntil and isScanPressed() then
                if isScanJustPressed() then
                    SX.Feedback:Play('start')
                end
                state = 'scanning'
                progress = math.min(1.0, progress + GetFrameTime() * 1000.0 / getScanDuration(ped, entity))
                if progress >= 1.0 then
                    progress = 0.0
                    complete(entity)
                end
            else
                state = entity and 'target' or 'idle'
                progress = decay(progress)
            end

            shown = busy and 1.0 or progress
        end

        local stepped = math.floor(shown * 20) / 20
        if state ~= sentState or stepped ~= sentProgress then
            sentState, sentProgress = state, stepped
            SX.Scanner:SetCrosshair(true, state, stepped)
        end

        if SX.Scanner:IsWidgetVisible() and (now > widgetUntil or not lockedEntity or not DoesEntityExist(lockedEntity)) then
            lockedEntity = nil
            SX.Scanner:HideWidget()
        end

        Wait(0)
    end
end

function SX.Scan:Start()
    if running then return end
    running = true
    CreateThread(loop)
end

function SX.Scan:Stop()
    if running then
        SetPedConfigFlag(PlayerPedId(), DISABLE_MELEE_FLAG, false)
    end
    running = false
    busy = false
    lockedEntity = nil
end

function SX.Scan:IsRunning()
    return running
end
