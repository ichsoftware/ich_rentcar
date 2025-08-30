local QBCore = exports['qb-core']:GetCoreObject()

local rentalLocation = vector3(-1031.51, -2734.18, 20.17)
local returnCoords = vector3(-1034.53, -2729.72, 20.08)
local menuOpen = false
local rentedVehicleNetId = nil

function hintToDisplay(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Marker çizme
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        -- Kiralama noktası
        if #(coords - rentalLocation) < 12.0 then
            DrawMarker(36, rentalLocation.x, rentalLocation.y, rentalLocation.z, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.8, 35, 105, 230, 105, false, true, 2, true)
        end

        -- Teslim noktası
        if #(coords - returnCoords) < 12.0 then
            DrawMarker(2, returnCoords.x, returnCoords.y, returnCoords.z + 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 150, 0, 100, false, true, 2, nil, nil, false)
        end
    end
end)

-- Menü açma kontrolü
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        -- Kiralama menüsü
        if not menuOpen and #(coords - rentalLocation) <= 0.5 then
            hintToDisplay('Araç kiralamak için ~INPUT_CONTEXT~ tuşuna bas') -- E tuşu
            if IsControlJustPressed(0, 38) then
                openRentNuiMenu()
            end
        end

        -- Teslim etme kontrolü
        if #(coords - returnCoords) <= 1.5 then
            hintToDisplay("Kiralanan aracı teslim etmek için ~INPUT_CONTEXT~ bas") -- E
            if IsControlJustPressed(0, 38) then
                local veh = GetVehiclePedIsIn(ped, false)

                if veh and veh ~= 0 then
                    local currentNetId = NetworkGetNetworkIdFromEntity(veh)
                    if rentedVehicleNetId ~= nil and currentNetId == rentedVehicleNetId then
                        TriggerServerEvent("ich_arackirala:returnVehicle")
                        rentedVehicleNetId = nil
                    else
                        TriggerEvent('QBCore:Notify', "Bu senin kiraladığın araç değil!", "error")
                    end
                else
                    TriggerEvent('QBCore:Notify', "Aracın içinde olmalısın!", "error")
                end
            end
        end
    end
end)

-- NUI aç/kapat
function openRentNuiMenu()
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({action = "openMenu"})
end

function closeRentNuiMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = "closeMenu"})
end

-- NUI callback'leri
RegisterNUICallback('rentCar', function(data, cb)
    TriggerServerEvent('ich_arackirala:rentCar')
    closeRentNuiMenu()
    cb('ok')
end)

RegisterNUICallback('rentBike', function(data, cb)
    TriggerServerEvent('ich_arackirala:rentBike')
    closeRentNuiMenu()
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    closeRentNuiMenu()
    cb('ok')
end)

-- Araç spawnla
RegisterNetEvent('ich_arackirala:spawnVehicle', function(model, price, plate)
    local spawnCoords = vector4(-1030.16, -2732.49, 20.07, 240.0)
    local heading = 240.0

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end

    local veh = CreateVehicle(GetHashKey(model), spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    if not veh then return end

    SetVehicleNumberPlateText(veh, plate)

    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    SetVehicleEngineOn(veh, true, true)

    local plate = GetVehicleNumberPlateText(veh)
    rentedVehicleNetId = NetworkGetNetworkIdFromEntity(veh)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TriggerServerEvent("ich_arackirala:giveCarKey", plate)

    TriggerEvent('QBCore:Notify', "Araç kiralandı. Anahtar verildi: " .. plate, "success")
end)


-- Araç silme
RegisterNetEvent("ich_arackirala:deleteVehicle", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh and veh ~= 0 then
        TaskLeaveVehicle(ped, veh, 0)
        Wait(1500)
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
end)