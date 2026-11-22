SX.Phone = {}
SX.Modules:Register("Phone", 30)

local resourceName = GetCurrentResourceName()
local registered = {}

local function isStarted(resource)
    return GetResourceState(resource) == 'started'
end

local function useApp(close)
    close()
    SX.Scanner:Toggle()
end

local providers = {}

providers['lb-phone'] = {
    register = function()
        local ok, success, errorMessage = pcall(function()
            return exports['lb-phone']:AddCustomApp({
                identifier = Config.Phone.identifier,
                name = Config.Phone.name,
                description = GetPhrase('phone_app_description'),
                developer = Config.Phone.developer,
                defaultApp = Config.Phone.defaultApp,
                price = Config.Phone.price,
                icon = ('https://cfx-nui-%s/web/dist/icon.png'):format(resourceName),
                onUse = function()
                    useApp(function()
                        pcall(function() exports['lb-phone']:ToggleOpen(false) end)
                    end)
                end,
            })
        end)
        if not ok or not success then return false, ok and errorMessage or success end
        return true
    end,
    unregister = function()
        pcall(function() exports['lb-phone']:RemoveCustomApp(Config.Phone.identifier) end)
    end,
}

providers['sd-phone'] = {
    readyEvent = 'sd-phone:ready',
    register = function()
        local ok, success, errorMessage = pcall(function()
            return exports['sd-phone']:addCustomApp({
                identifier = Config.Phone.sdPhone.identifier,
                name = Config.Phone.name,
                description = GetPhrase('phone_app_description'),
                developer = Config.Phone.developer,
                defaultApp = Config.Phone.defaultApp,
                price = Config.Phone.price,
                ui = resourceName .. '/web/dist/phone.html',
                icon = ('https://cfx-nui-%s/web/dist/icon.png'):format(resourceName),
                onOpen = function()
                    useApp(function()
                        pcall(function() exports['sd-phone']:close() end)
                    end)
                end,
            })
        end)
        if not ok or not success then return false, ok and errorMessage or success end
        return true
    end,
    unregister = function()
        pcall(function() exports['sd-phone']:removeCustomApp(Config.Phone.sdPhone.identifier) end)
    end,
}

local function register(resource)
    local provider = providers[resource]
    if not Config.Phone.enabled or not provider or registered[resource] or not isStarted(resource) then return end

    registered[resource] = true
    Wait(500)

    local ok, err = provider.register()
    if not ok then
        registered[resource] = nil
        Logger:error('PHONE', ('%s app registration failed:'):format(resource), err)
    end
end

local function unregister(resource)
    local provider = providers[resource]
    if not registered[resource] then return end
    registered[resource] = nil
    if provider.unregister and isStarted(resource) then provider.unregister() end
end

function SX.Phone:IsRegistered()
    return next(registered) ~= nil
end

function SX.Phone:Initialize()
    for resource, provider in pairs(providers) do
        if provider.readyEvent then
            AddEventHandler(provider.readyEvent, function()
                registered[resource] = nil
                CreateThread(function() register(resource) end)
            end)
        end
    end

    AddEventHandler('onClientResourceStart', function(resource)
        if providers[resource] and not providers[resource].readyEvent then
            registered[resource] = nil
            CreateThread(function() register(resource) end)
        end
    end)

    AddEventHandler('onClientResourceStop', function(resource)
        if resource == resourceName then
            for name in pairs(providers) do unregister(name) end
        elseif providers[resource] then
            registered[resource] = nil
        end
    end)
end

function SX.Phone:InitializeAsync()
    for resource in pairs(providers) do
        register(resource)
    end
end
