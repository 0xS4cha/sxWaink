SX.Animation = {}
SX.Modules:Register("Animation", 15)

local UNARMED = joaat('WEAPON_UNARMED')
local LOAD_TIMEOUT = 3000

local active = false
local prop = nil
local current = nil
local previousWeapon = nil

local function load(request, isLoaded, asset)
    request(asset)
    local timeout = GetGameTimer() + LOAD_TIMEOUT
    while not isLoaded(asset) do
        if GetGameTimer() > timeout then return false end
        Wait(0)
    end
    return true
end

local function removeProp()
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, false)
        DeleteEntity(prop)
    end
    prop = nil
end

local function attachProp(ped)
    if prop and DoesEntityExist(prop) and IsEntityAttachedToEntity(prop, ped) then return end
    removeProp()

    local settings = Config.Animation
    local model = joaat(settings.prop)
    if not load(RequestModel, HasModelLoaded, model) then return end

    local coords = GetEntityCoords(ped)
    prop = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, false, false)
    SetEntityCollision(prop, false, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, settings.bone),
        settings.offset.x, settings.offset.y, settings.offset.z,
        settings.rotation.x, settings.rotation.y, settings.rotation.z,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

local function stopAnim(ped)
    if current then
        StopAnimTask(ped, current.dict, current.name, 2.0)
        RemoveAnimDict(current.dict)
        current = nil
    end
end

local function canAnimate(ped)
    return not IsEntityDead(ped) and not IsPedRagdoll(ped) and not IsPedSwimming(ped)
        and not IsPedClimbing(ped) and not IsPedGettingIntoAVehicle(ped)
end

local function playAnim(ped)
    local anim = IsPedInAnyVehicle(ped, false) and Config.Animation.inVehicle or Config.Animation.onFoot
    if current and current ~= anim then stopAnim(ped) end
    if IsEntityPlayingAnim(ped, anim.dict, anim.name, 3) then return end
    if not load(RequestAnimDict, HasAnimDictLoaded, anim.dict) then return end

    TaskPlayAnim(ped, anim.dict, anim.name, 3.0, 3.0, -1, 49, 0, false, false, false)
    current = anim
end

local function loop()
    while active do
        local ped = PlayerPedId()

        if canAnimate(ped) then
            if GetSelectedPedWeapon(ped) ~= UNARMED then
                SetCurrentPedWeapon(ped, UNARMED, true)
            end
            playAnim(ped)
            attachProp(ped)
        else
            stopAnim(ped)
            removeProp()
        end

        Wait(250)
    end

    local ped = PlayerPedId()
    stopAnim(ped)
    removeProp()

    if previousWeapon and previousWeapon ~= UNARMED and HasPedGotWeapon(ped, previousWeapon, false) then
        SetCurrentPedWeapon(ped, previousWeapon, true)
    end
    previousWeapon = nil
end

function SX.Animation:Start()
    if active or not Config.Animation.enabled then return end
    active = true
    previousWeapon = GetSelectedPedWeapon(PlayerPedId())
    CreateThread(loop)
end

function SX.Animation:Stop()
    active = false
end

function SX.Animation:IsPlaying()
    return active
end

function SX.Animation:Initialize()
    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        stopAnim(PlayerPedId())
        removeProp()
    end)
end
