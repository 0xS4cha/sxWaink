SX.App = {}
SX.Modules:Register("App", 10)

local resourceName = GetCurrentResourceName()

local scannerActive = false
local widgetVisible = false
local history = {}
local historyKey = nil

local function clamp01(value)
    return Utils.Clamp(value, 0.0, 1.0)
end

local function sendToPhone(action, data)
    pcall(function()
        exports["lb-phone"]:SendCustomAppMessage(Config.App.identifier, { action = action, data = data })
    end)
end

local function saveHistory()
    if historyKey then
        SetResourceKvp(historyKey, json.encode(history))
    end
end

local function loadHistory(identifier)
    historyKey = identifier and ('history:%s'):format(identifier) or nil
    history = {}

    if historyKey then
        local ok, stored = pcall(json.decode, GetResourceKvpString(historyKey) or '[]')
        if ok and type(stored) == 'table' then
            for i = 1, math.min(#stored, Config.HistoryLimit) do
                history[i] = stored[i]
            end
        end
    end

    sendToPhone('setPhoneState', { history = history })
end

local function fetchProfile()
    local result = TriggerServerCallback('sxWaink:getProfile')
    return result and result.ok and result.data or nil
end

local function registerApp()
    local success, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = Config.App.identifier,
        name = Config.App.name,
        description = GetPhrase('app_description'),
        developer = Config.App.developer,
        defaultApp = Config.App.defaultApp,
        game = false,
        size = 59812,
        ui = resourceName .. "/web/dist/app.html",
        icon = "https://cfx-nui-" .. resourceName .. "/web/dist/icon.png",
        price = Config.App.price,
        landscape = false,
        keepOpen = false,
    })

    if not success then
        Logger:error('App', ('AddCustomApp failed: %s'):format(tostring(errorMessage)))
    end
end

function SX.App:SetCrosshair(active, state, progress)
    SX.UI:Send('setScanner', { active = active, state = state or 'idle', progress = progress or 0 })
end

function SX.App:ShowWidget(vehicle, key)
    widgetVisible = true
    SX.UI:Send('setWidget', { visible = true, vehicle = vehicle, key = key or Config.Keys.nextPage })
end

function SX.App:HideWidget()
    widgetVisible = false
    SX.UI:Send('setWidget', { visible = false })
end

function SX.App:IsWidgetVisible()
    return widgetVisible
end

function SX.App:SetWidgetPage(page)
    SX.UI:Send('widgetPage', { page = page })
end

function SX.App:GetVehicleStats(entity)
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

function SX.App:IsScannerActive()
    return scannerActive
end

function SX.App:SetScannerActive(active)
    scannerActive = active == true
    self:SetCrosshair(scannerActive, 'idle', 0)
    if scannerActive then
        SX.Scan:Start()
    else
        SX.Scan:Stop()
        self:HideWidget()
    end
    sendToPhone('setPhoneState', { scannerActive = scannerActive })
end

function SX.App:PushScan(vehicle)
    vehicle.scannedAt = vehicle.scannedAt or (GetCloudTimeAsInt() * 1000)
    table.insert(history, 1, vehicle)
    while #history > Config.HistoryLimit do
        table.remove(history)
    end
    saveHistory()
    sendToPhone('addScan', vehicle)
end

function SX.App:GetHistory()
    return history
end

function SX.App:ClearHistory()
    history = {}
    saveHistory()
    sendToPhone('setPhoneState', { history = history })
end

function SX.App:Initialize()
    registerApp()

    AddEventHandler('onResourceStart', function(resource)
        if resource == 'lb-phone' then
            registerApp()
        end
    end)

    RegisterCommand('waink_nextpage', function()
        if widgetVisible then
            SX.App:SetWidgetPage('next')
        end
    end, false)
    RegisterKeyMapping('waink_nextpage', GetPhrase('keymap_next_page'), 'keyboard', Config.Keys.nextPage)

    RegisterNUICallback('getState', function(_, cb)
        local localization = SX.UI:GetLocalization()
        cb({
            ok = true,
            data = {
                scannerActive = scannerActive,
                history = history,
                historyLimit = Config.HistoryLimit,
                locale = localization.locale,
                translations = localization.translations,
                units = localization.units,
            }
        })
    end)

    RegisterNUICallback('toggleScanner', function(data, cb)
        local active = data and data.active == true
        if not active then
            SX.App:SetScannerActive(false)
            cb({ ok = true, data = { active = false } })
            return
        end

        CreateThread(function()
            local profile = fetchProfile()
            if not profile then
                cb({ ok = false, error = 'timeout' })
                return
            end
            if not profile.allowed then
                cb({ ok = false, error = 'not_allowed' })
                return
            end

            SX.App:SetScannerActive(true)
            cb({ ok = true, data = { active = scannerActive } })
        end)
    end)

    RegisterNUICallback('clearHistory', function(_, cb)
        SX.App:ClearHistory()
        cb({ ok = true })
    end)

    RegisterNetEvent('esx:playerLoaded', function()
        SX.App:SetScannerActive(false)
        CreateThread(function()
            local profile = fetchProfile()
            loadHistory(profile and profile.identifier)
        end)
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        SX.App:SetScannerActive(false)
        loadHistory(nil)
    end)
end

function SX.App:InitializeAsync()
    local profile = fetchProfile()
    loadHistory(profile and profile.identifier)
end
