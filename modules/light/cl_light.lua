SX.Light = {}
SX.Modules:Register("Light", 14)

local STATE_KEY = 'wainkScanning'
local HAND_BONE = 28422
local REFRESH = 300

local scanning = false
local sources = {}

function SX.Light:SetScanning(active)
    active = active == true and Config.Light.enabled
    if active == scanning then return end
    scanning = active
    LocalPlayer.state:set(STATE_KEY, active, true)
end

local function refresh()
    local coords = GetEntityCoords(PlayerPedId())
    local found = {}

    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        local state = Player(GetPlayerServerId(player)).state
        if state[STATE_KEY] and DoesEntityExist(ped) and #(coords - GetEntityCoords(ped)) <= Config.Light.distance then
            found[#found + 1] = ped
        end
    end

    sources = found
end

local function draw()
    local settings = Config.Light
    local color = settings.color
    local pulse = 0.65 + 0.35 * math.abs(math.sin(GetGameTimer() / 1000.0 * settings.pulse * math.pi))

    for _, ped in ipairs(sources) do
        if DoesEntityExist(ped) then
            local hand = GetPedBoneCoords(ped, HAND_BONE, 0.0, 0.0, 0.0)
            local position = hand + GetEntityForwardVector(ped) * 0.15
            DrawLightWithRange(position.x, position.y, position.z, color.r, color.g, color.b, settings.range, settings.intensity * pulse)
        end
    end
end

function SX.Light:Initialize()
    if not Config.Light.enabled then return end

    CreateThread(function()
        local nextRefresh = 0
        while true do
            local now = GetGameTimer()
            if now >= nextRefresh then
                nextRefresh = now + REFRESH
                refresh()
            end

            if #sources > 0 then
                draw()
                Wait(0)
            else
                Wait(REFRESH)
            end
        end
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            LocalPlayer.state:set(STATE_KEY, false, true)
        end
    end)
end
