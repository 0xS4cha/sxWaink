SX.Widget = {}
SX.Modules:Register("Widget", 8)

local WIDGET_ID = 'sxwaink_vehicle'
local MS_TO_KMH = 3.6
local MS_TO_MPH = 2.236936

local visible = false

local function logo()
    return ('nui://%s/web/dist/logo.svg'):format(GetCurrentResourceName())
end

local function formatSpeed(metersPerSecond)
    if SX.UI:GetUnits() == 'imperial' then
        return ('%d %s'):format(math.floor(metersPerSecond * MS_TO_MPH + 0.5), GetPhrase('unit_speed_imperial'))
    end
    return ('%d %s'):format(math.floor(metersPerSecond * MS_TO_KMH + 0.5), GetPhrase('unit_speed_metric'))
end

local function levelTone(percent)
    return (percent or 0) <= 20 and 'danger' or nil
end

local function buildMenu(vehicle, key)
    local perf = vehicle.performance or {}
    local details = vehicle.details
    local fuel = details and details.fuel or 0
    local engine = details and details.engine or 0

    return {
        id = WIDGET_ID,
        page = 0,
        position = Config.Widget.position,
        offset = Config.Widget.offset,
        key = key,
        header = {
            subtitle = vehicle.brand,
            title = vehicle.model,
            image = logo(),
        },
        pages = {
            {
                id = 'info',
                title = GetPhrase('widget_page_info'),
                icon = 'user-round',
                rows = {
                    {
                        type = 'text',
                        label = GetPhrase('widget_owner'),
                        value = vehicle.owner or GetPhrase('vehicle_no_owner'),
                        icon = 'user-round',
                        tone = vehicle.owner and 'neutral' or 'danger',
                    },
                    {
                        type = 'text',
                        label = GetPhrase('widget_access'),
                        value = GetPhrase(vehicle.locked and 'vehicle_locked' or 'vehicle_unlocked'),
                        icon = vehicle.locked and 'key-round' or 'lock-open',
                        tone = vehicle.locked and 'danger' or 'safe',
                    },
                    { type = 'text', label = GetPhrase('widget_plate'), value = vehicle.plate },
                },
            },
            {
                id = 'perf',
                title = GetPhrase('widget_page_perf'),
                icon = 'gauge',
                rows = {
                    {
                        type = 'bar',
                        label = GetPhrase('widget_speed'),
                        value = perf.speed or 0,
                        display = perf.maxSpeed and formatSpeed(perf.maxSpeed) or nil,
                    },
                    { type = 'bar', label = GetPhrase('widget_acceleration'), value = perf.acceleration or 0 },
                    { type = 'bar', label = GetPhrase('widget_braking'), value = perf.braking or 0 },
                    { type = 'bar', label = GetPhrase('widget_traction'), value = perf.traction or 0 },
                },
            },
            {
                id = 'details',
                title = GetPhrase('widget_page_details'),
                icon = 'fuel',
                rows = {
                    { type = 'text', label = GetPhrase('widget_class'), value = details and details.class or '-', icon = 'car-front' },
                    { type = 'text', label = GetPhrase('widget_seats'), value = details and details.seats or '-', icon = 'armchair' },
                    { type = 'bar', label = GetPhrase('widget_fuel'), value = fuel, max = 100, display = ('%d%%'):format(fuel), tone = levelTone(fuel) },
                    { type = 'bar', label = GetPhrase('widget_engine'), value = engine, max = 100, display = ('%d%%'):format(engine), tone = levelTone(engine) },
                },
            },
        },
    }
end

local function available()
    if GetResourceState('sxHelpMenu') == 'started' then return true end
    Logger:warn('Widget', 'sxHelpMenu is not started, the vehicle widget is disabled')
    return false
end

function SX.Widget:Show(vehicle, key)
    if type(vehicle) ~= 'table' or not available() then return end
    visible = exports.sxHelpMenu:Show(buildMenu(vehicle, key)) ~= nil
end

function SX.Widget:Hide()
    if not visible then return end
    visible = false
    if GetResourceState('sxHelpMenu') == 'started' then
        exports.sxHelpMenu:Hide(WIDGET_ID)
    end
end

function SX.Widget:IsVisible()
    return visible
end

function SX.Widget:SetPage(page)
    if not visible then return end
    exports.sxHelpMenu:SetPage(WIDGET_ID, page)
end

function SX.Widget:Initialize()
    AddEventHandler('onResourceStop', function(resource)
        if resource == 'sxHelpMenu' then
            visible = false
        end
    end)
end
