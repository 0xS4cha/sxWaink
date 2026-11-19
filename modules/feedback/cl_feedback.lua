SX.Feedback = {}
SX.Modules:Register("Feedback", 12)

local function playSound(sound)
    if not Config.Feedback.sounds or not sound then return end

    if sound.audible and Config.Feedback.audible then
        PlaySoundFromEntity(-1, sound.name, PlayerPedId(), sound.set, true, 0)
    else
        PlaySoundFrontend(-1, sound.name, sound.set, true)
    end
end

local function vibrate(vibration)
    if not Config.Feedback.vibration or not vibration then return end

    SetPadShake(0, vibration.duration, vibration.strength)
    SX.UI:Send('vibrate', { pulses = vibration.pulses })
end

function SX.Feedback:Play(event)
    local feedback = Config.Feedback.enabled and Config.Feedback.events[event]
    if not feedback then return end

    playSound(feedback.sound)
    vibrate(feedback.vibration)
end
