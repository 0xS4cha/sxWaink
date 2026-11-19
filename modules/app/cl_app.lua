SX.App = {}
SX.Modules:Register("App", 10)

local resourceName = GetCurrentResourceName()

local scannerActive = false
local widgetVisible = false
local history = {}

local function clamp01(value)
    return Utils.Clamp(value, 0.0, 1.0)
end

local function sendToPhone(action, data)
    exports["lb-phone"]:SendCustomAppMessage(Config.App.identifier, { action = action, data = data })
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
    if not scannerActive then
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
    sendToPhone('addScan', vehicle)
end

function SX.App:GetHistory()
    return history
end

function SX.App:ClearHistory()
    history = {}
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
        SX.App:SetScannerActive(data and data.active)
        cb({ ok = true, data = { active = scannerActive } })
    end)

    RegisterNUICallback('clearHistory', function(_, cb)
        history = {}
        cb({ ok = true })
    end)
end
