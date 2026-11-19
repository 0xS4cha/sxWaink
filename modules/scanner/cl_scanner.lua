SX.Scanner = {}
SX.Modules:Register("Scanner", 10)

local scannerActive = false
local widgetVisible = false
local toggling = false
local history = {}
local historyKey = nil

local function clamp01(value)
    return Utils.Clamp(value, 0.0, 1.0)
end

local function saveHistory()
    if historyKey then
        SetResourceKvp(historyKey, json.encode(history))
    end
end

local function loadHistory(identifier)
    historyKey = identifier and ('history:%s'):format(identifier) or nil
    history = {}

    if not historyKey then return end

    local ok, stored = pcall(json.decode, GetResourceKvpString(historyKey) or '[]')
    if ok and type(stored) == 'table' then
        for i = 1, math.min(#stored, Config.HistoryLimit) do
            history[i] = stored[i]
        end
    end
end

local function fetchProfile()
    local result = TriggerServerCallback('sxWaink:getProfile')
    return result and result.ok and result.data or nil
end

function SX.Scanner:SetCrosshair(active, state, progress)
    SX.UI:Send('setScanner', { active = active, state = state or 'idle', progress = progress or 0 })
end

function SX.Scanner:ShowWidget(vehicle, key)
    widgetVisible = true
    SX.UI:Send('setWidget', { visible = true, vehicle = vehicle, key = key or Config.Keys.nextPage })
end

function SX.Scanner:HideWidget()
    widgetVisible = false
    SX.UI:Send('setWidget', { visible = false })
end

function SX.Scanner:IsWidgetVisible()
    return widgetVisible
end

function SX.Scanner:SetWidgetPage(page)
    SX.UI:Send('widgetPage', { page = page })
end

function SX.Scanner:GetVehicleStats(entity)
    local model = GetEntityModel(entity)
    local maxSpeed = GetVehicleModelEstimatedMaxSpeed(model)

    local performance = {
        speed = clamp01(maxSpeed / 60.0),
        acceleration = clamp01(GetVehicleModelAcceleration(model) / 0.5),
        braking = clamp01(GetVehicleModelMaxBraking(model) / 1.6),
        traction = clamp01(GetVehicleModelMaxTraction(model) / 3.5),
        maxSpeed = maxSpeed,
    }

    local tank = GetVehicleHandlingFloat(entity, 'CHandlingData', 'fPetrolTankVolume')
    local fuel = GetVehicleFuelLevel(entity)
    local fuelPercent = tank > 0 and (fuel / tank * 100.0) or fuel

    local details = {
        class = GetLabelText(('VEH_CLASS_%d'):format(GetVehicleClass(entity))),
        seats = GetVehicleModelNumberOfSeats(model),
        fuel = math.floor(Utils.Clamp(fuelPercent, 0, 100) + 0.5),
        engine = math.floor(Utils.Clamp(GetVehicleEngineHealth(entity), 0, 1000) / 10 + 0.5),
    }

    return performance, details
end

function SX.Scanner:IsActive()
    return scannerActive
end

function SX.Scanner:SetActive(active)
    scannerActive = active == true
    self:SetCrosshair(scannerActive, 'idle', 0)
    if scannerActive then
        SX.Scan:Start()
        SX.Animation:Start()
    else
        SX.Scan:Stop()
        SX.Animation:Stop()
        self:HideWidget()
    end
end

function SX.Scanner:Toggle()
    if scannerActive then
        self:SetActive(false)
        Bridge.Notify(GetPhrase('notify_scanner_off'), 'info')
        return
    end

    if toggling then return end
    toggling = true

    CreateThread(function()
        local profile = fetchProfile()
        toggling = false

        if not profile then
            Bridge.Notify(GetPhrase('error_timeout'), 'error')
            return
        end
        if not profile.allowed then
            Bridge.Notify(GetPhrase('error_not_allowed'), 'error')
            return
        end

        SX.Scanner:SetActive(true)
        Bridge.Notify(GetPhrase('notify_scanner_on'), 'success')
    end)
end

function SX.Scanner:PushScan(vehicle)
    vehicle.scannedAt = vehicle.scannedAt or (GetCloudTimeAsInt() * 1000)
    table.insert(history, 1, vehicle)
    while #history > Config.HistoryLimit do
        table.remove(history)
    end
    saveHistory()
end

function SX.Scanner:GetHistory()
    return history
end

function SX.Scanner:ClearHistory()
    history = {}
    saveHistory()
end

function SX.Scanner:Initialize()
    RegisterCommand('waink', function()
        SX.Scanner:Toggle()
    end, false)
    RegisterKeyMapping('waink', GetPhrase('keymap_toggle'), 'keyboard', Config.Keys.toggle)

    RegisterCommand('waink_nextpage', function()
        if widgetVisible then
            SX.Scanner:SetWidgetPage('next')
        end
    end, false)
    RegisterKeyMapping('waink_nextpage', GetPhrase('keymap_next_page'), 'keyboard', Config.Keys.nextPage)

    RegisterNetEvent('esx:playerLoaded', function()
        SX.Scanner:SetActive(false)
        CreateThread(function()
            local profile = fetchProfile()
            loadHistory(profile and profile.identifier)
        end)
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        SX.Scanner:SetActive(false)
        loadHistory(nil)
    end)
end

function SX.Scanner:InitializeAsync()
    local profile = fetchProfile()
    loadHistory(profile and profile.identifier)
end
