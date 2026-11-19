SX.Scan = {}
SX.Modules:Register("Scan", 20)

local BLOCKED_CONTROLS = { 21, 24, 37, 69, 70, 92, 114, 140, 141, 142, 257, 263, 264 }
local DISABLE_MELEE_FLAG = 122
local SCAN_CONTROLS = { 24, 69, 92 }
local SHAPE_TEST_FLAGS = 1 | 2 | 16

local running = false
local busy = false
local cooldownUntil = 0
local lockedEntity = nil
local widgetUntil = 0

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
    local netId = NetworkGetEntityIsNetworked(entity) and VehToNet(entity) or 0

    CreateThread(function()
        local result = TriggerServerCallback('sxWaink:scan', netId) or { ok = false, error = 'timeout' }
        cooldownUntil = GetGameTimer() + Config.Scan.cooldown
        busy = false

        if not result.ok then
            Bridge.Notify(GetPhrase('error_' .. tostring(result.error)), 'error')
            if result.error == 'not_allowed' then
                SX.Scanner:SetActive(false)
            end
            return
        end

        if not running or not DoesEntityExist(entity) then return end

        local data = result.data or {}
        local vehicle = SX.Scan:BuildVehicle(entity, data.owner, data.plate)
        lockedEntity = entity
        widgetUntil = GetGameTimer() + Config.Scan.widgetDuration
        SX.Scanner:ShowWidget(vehicle)
        SX.Scanner:PushScan(vehicle)
    end)
end

local function loop()
    local target = nil
    local progress = 0.0
    local sentState, sentProgress = nil, -1

    while running do
        local ped = PlayerPedId()
        local now = GetGameTimer()
        local entity = canScan(ped) and getTarget(ped) or nil
        local state = 'idle'

        restrict(ped)

        if busy then
            state, progress = 'scanning', 1.0
        elseif entity then
            if entity ~= target then
                target = entity
                progress = 0.0
            end

            if entity == lockedEntity and SX.Scanner:IsWidgetVisible() then
                state, progress = 'locked', 1.0
            elseif now >= cooldownUntil and isScanPressed() then
                state = 'scanning'
                progress = math.min(1.0, progress + GetFrameTime() * 1000.0 / Config.Scan.duration)
                if progress >= 1.0 then
                    complete(entity)
                end
            else
                state, progress = 'target', 0.0
            end
        else
            target = nil
            progress = 0.0
        end

        local stepped = math.floor(progress * 20) / 20
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
