-- Inicialización de QBCore
local QBCore = exports['qb-core']:GetCoreObject()

-------------------------------- 
-- Funciones del dinero
function getmoney(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then
        return 0
    end
    return xPlayer.PlayerData.money["cash"] or 0
end

function removemoney(source, count)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then
        return false
    end
    count = tonumber(count)
    if not count or count <= 0 then
        return false
    end
    return xPlayer.Functions.RemoveMoney('cash', count, "Pet Purchase")
end

-------------------------------- 
-- Funciones de datos del jugador
function getidentifier(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then
        return nil
    end
    return xPlayer.PlayerData.citizenid
end

-------------------------------- 
-- Funciones de base de datos
function ExecuteSql(query)
    local IsBusy = true
    local result = nil

    if Config.Mysql == "oxmysql" then
        if MySQL == nil then
            exports.oxmysql:execute(query, function(data)
                result = data
                IsBusy = false
            end)
        else
            MySQL.query(query, {}, function(data)
                result = data
                IsBusy = false
            end)
        end
    elseif Config.Mysql == "ghmattimysql" then
        exports.ghmattimysql:execute(query, {}, function(data)
            result = data
            IsBusy = false
        end)
    elseif Config.Mysql == "mysql-async" then
        MySQL.Async.fetchAll(query, {}, function(data)
            result = data
            IsBusy = false
        end)
    end

    while IsBusy do
        Citizen.Wait(0)
    end
    return result
end

function notify(source, text, type)
    TriggerClientEvent('QBCore:Notify', source, text, type or 'primary', 5000)
end

-------------------------------- 
-- Evento para verificar y usar items
QBCore.Functions.CreateCallback('dp-pets:useItem', function(source, cb, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return cb(false)
    end

    local itemData = Player.Functions.GetItemByName(item)
    if not itemData or itemData.amount <= 0 then
        cb(false)
        return
    end

    if Player.Functions.RemoveItem(item, 1) then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item], "remove")
        cb(true)
    else
        cb(false)
    end
end)

-------------------------------- 
-- Evento de compra de mascotas
RegisterNetEvent("buy:pet", function(petcode, price)
    local src = source
    if not petcode or not price then
        notify(src, "Selección de mascota no válida", 'error')
        return
    end

    local identifier = getidentifier(src)
    if not identifier then
        notify(src, "Jugador no encontrado", 'error')
        return
    end

    -- Verificar si el jugador ya tiene una mascota
    local result = ExecuteSql("SELECT * FROM `dp_petshop` WHERE `identifier` = '" .. identifier .. "'")
    if result and #result > 0 then
        notify(src, "¡Ya tienes una mascota!", 'error')
        return
    end

    local money = getmoney(src)
    price = tonumber(price)

    if money >= price then
        if removemoney(src, price) then
            ExecuteSql(
                "INSERT INTO `dp_petshop` (`identifier`, `pet_code`, `health`, `hunger`, `thirst`, `hygiene`, `affection`) " ..
                    "VALUES ('" .. identifier .. "','" .. petcode .. "', 100, 100, 100, 100, 100)")
            notify(src, "¡Has comprado tu nueva mascota con éxito!", 'success')
        else
            notify(src, "No se pudo procesar el pago", 'error')
        end
    else
        notify(src, "Hace falta dinero", 'error')
    end
end)

--------------------------------
-- Evento para actualizar las estadísticas
RegisterNetEvent("dp-pets:updateStats", function(stats)
    local src = source
    local identifier = getidentifier(src)

    if not identifier then
        return
    end

    ExecuteSql("UPDATE `dp_petshop` SET " .. "`health` = " .. (stats.health or 100) .. ", " .. "`hunger` = " ..
                   (stats.hunger or 100) .. ", " .. "`thirst` = " .. (stats.thirst or 100) .. ", " .. "`hygiene` = " ..
                   (stats.hygiene or 100) .. ", " .. "`affection` = " .. (stats.affection or 100) .. " " ..
                   "WHERE `identifier` = '" .. identifier .. "'")
end)

-------------------------------- 
-- Evento de eliminación de mascota
RegisterNetEvent("delete:pet", function()
    local src = source
    local identifier = getidentifier(src)

    if not identifier then
        notify(src, "Jugador no encontrado", 'error')
        return
    end

    local deleted = ExecuteSql("DELETE FROM `dp_petshop` WHERE `identifier` = '" .. identifier .. "'")
    if not deleted then
        notify(src, "No se pudo liberar a la mascota", 'error')
    end
end)

-------------------------------- 
-- Evento de control de mascotas
RegisterNetEvent("pet:control", function()
    local src = source
    local identifier = getidentifier(src)

    if not identifier then
        notify(src, "Jugador no encontrado", 'error')
        return
    end

    local result = ExecuteSql("SELECT * FROM `dp_petshop` WHERE `identifier` = '" .. identifier .. "'")
    if result and #result > 0 then
        TriggerClientEvent("pet:cl:control", src, true, {
            pet_code = result[1].pet_code,
            health = result[1].health,
            hunger = result[1].hunger,
            thirst = result[1].thirst,
            hygiene = result[1].hygiene,
            affection = result[1].affection
        })
    else
        notify(src, "No tienes mascota", 'error')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Limpieza si es necesario
    end
end)
