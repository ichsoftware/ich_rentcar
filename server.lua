local QBCore = exports['qb-core']:GetCoreObject()

-- Araç kiralama - Araba
RegisterNetEvent("ich_arackirala:rentCar", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local price = 500
    if not Player then return end

    local cash = Player.PlayerData.money["cash"]
    if cash < price then
        TriggerClientEvent('QBCore:Notify', src, "Yeterli nakit paran yok!", "error")
        return
    end

    Player.Functions.RemoveMoney('cash', price, "Araç kiralama (car)")

    local plate = "RENT" .. math.random(1000, 9999)
    Player.Functions.SetMetaData("rented_vehicle", { model = "drafter", price = price, plate = plate })

    -- Plakayı client'e gönder
    TriggerClientEvent('ich_arackirala:spawnVehicle', src, "drafter", price, plate)
end)


-- Araç kiralama - Motosiklet
RegisterNetEvent("ich_arackirala:rentBike", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local price = 200
    if not Player then return end

    local cash = Player.PlayerData.money["cash"]
    if cash < price then
        TriggerClientEvent('QBCore:Notify', src, "Yeterli nakit paran yok!", "error")
        return
    end

    Player.Functions.RemoveMoney('cash', price, "Araç kiralama (bike)")

    local plate = "RENT" .. math.random(1000, 9999)
    Player.Functions.SetMetaData("rented_vehicle", { model = "faggio", price = price, plate = plate })

    TriggerClientEvent('ich_arackirala:spawnVehicle', src, "faggio", price, plate)
end)


-- Araç teslim
RegisterNetEvent("ich_arackirala:returnVehicle", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local rented = Player.PlayerData.metadata["rented_vehicle"]
    if not rented or not rented.price then
        TriggerClientEvent('QBCore:Notify', src, "Kiralanmış bir aracın yok!", "error")
        return
    end

    local refund = math.floor(rented.price * 0.20)
    Player.Functions.AddMoney('cash', refund, "Araç iade iadesi")

    -- Anahtar silme
    local keys = Player.PlayerData.metadata["owned_keys"] or {}
    local newKeys = {}
    for _, plate in ipairs(keys) do
        if plate ~= rented.plate then
            table.insert(newKeys, plate)
        end
    end
    Player.Functions.SetMetaData("owned_keys", newKeys)

    Player.Functions.SetMetaData("rented_vehicle", nil)

    TriggerClientEvent("QBCore:Notify", src, "Araç teslim edildi! $" .. refund .. " nakit iade edildi.", "success")
    TriggerClientEvent("ich_arackirala:deleteVehicle", src)
end)


RegisterNetEvent("ich_arackirala:giveCarKey", function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Metadata kontrol et
    local keys = Player.PlayerData.metadata["owned_keys"] or {}

    -- Anahtarı ekle
    table.insert(keys, plate)
    Player.Functions.SetMetaData("owned_keys", keys)

    -- Gerekirse client'e anahtar listesi gönder
    TriggerClientEvent("QBCore:Notify", src, "Araç anahtarı eklendi: " .. plate, "success")
end)
