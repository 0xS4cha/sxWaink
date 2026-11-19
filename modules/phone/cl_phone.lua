SX.Phone = {}
SX.Modules:Register("Phone", 30)

local PHONE_RESOURCE = 'lb-phone'
local resourceName = GetCurrentResourceName()
local registered = false

local function isPhoneStarted()
    return GetResourceState(PHONE_RESOURCE) == 'started'
end

local function closePhone()
    pcall(function()
        exports[PHONE_RESOURCE]:ToggleOpen(false)
    end)
end

local function register()
    if not Config.Phone.enabled or not isPhoneStarted() then return end

    Wait(500)

    local ok, success, errorMessage = pcall(function()
        return exports[PHONE_RESOURCE]:AddCustomApp({
            identifier = Config.Phone.identifier,
            name = Config.Phone.name,
            description = GetPhrase('phone_app_description'),
            developer = Config.Phone.developer,
            defaultApp = Config.Phone.defaultApp,
            price = Config.Phone.price,
            icon = ('https://cfx-nui-%s/web/dist/icon.png'):format(resourceName),
            onUse = function()
                closePhone()
                SX.Scanner:Toggle()
            end,
        })
    end)

    if not ok or not success then
        Logger:error('PHONE', 'AddCustomApp failed:', ok and errorMessage or success)
        return
    end

    registered = true
end

local function unregister()
    if not registered or not isPhoneStarted() then return end
    registered = false

    pcall(function()
        exports[PHONE_RESOURCE]:RemoveCustomApp(Config.Phone.identifier)
    end)
end

function SX.Phone:IsRegistered()
    return registered
end

function SX.Phone:Initialize()
    AddEventHandler('onClientResourceStart', function(resource)
        if resource == PHONE_RESOURCE then
            registered = false
            CreateThread(register)
        end
    end)

    AddEventHandler('onClientResourceStop', function(resource)
        if resource == resourceName then
            unregister()
        elseif resource == PHONE_RESOURCE then
            registered = false
        end
    end)
end

function SX.Phone:InitializeAsync()
    register()
end
