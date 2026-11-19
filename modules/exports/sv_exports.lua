exports("CanUseScanner", function(source)
    return SX.Scan:CanUse(source)
end)

exports("GetVehicleOwner", function(plate)
    return SX.Scan:GetOwner(plate)
end)

exports("SetVehicleOwner", function(plate, name)
    SX.Scan:SetOwner(plate, name)
end)
