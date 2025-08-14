-- Inicialización de QBCore
local QBCore = exports['qb-core']:GetCoreObject()

local pcode = nil
local petcode = nil
local precio = nil
local spawned_ped = nil
local bindimi = true
local cam = nil
local b = nil
local zoomLevel = 0.0 -- Variable para controlar el nivel de zoom
local petStats = {
    health = 100,
    hunger = 100,
    thirst = 100,
    hygiene = 100,
    affection = 100
}
local lastHygieneDecrease = 0
local lastAffectionDecrease = 0

local function MostrarTextoUI(id, texto, tecla, mantener)
    if Config.DPTextUI and exports['DP-TextUI'] then
        exports['DP-TextUI']:MostrarUI(id, texto, 'E', mantener or false)
    end
end

local function OcultarTextoUI(id)
    if Config.DPTextUI and exports['DP-TextUI'] then
        if id then
            exports['DP-TextUI']:OcultarUI(id)
        else
            exports['DP-TextUI']:OcultarUI()
        end
    end
end

-- Creación del NPC
Citizen.CreateThread(function()
    RequestModel(Config.npc)
    while not HasModelLoaded(Config.npc) do
        Citizen.Wait(1)
    end

    local npc = CreatePed(4, Config.npc, Config.npccoord.x, Config.npccoord.y, Config.npccoord.z - 1.0,
        Config.npccoordh, false, false)
    SetPedFleeAttributes(npc, 0, 0)
    SetPedDropsWeaponsWhenDead(npc, false)
    SetPedDiesWhenInjured(npc, false)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskStartScenarioInPlace(npc, Config.npcanim, 0, true)
end)

-- Interacción con la tienda de mascotas
Citizen.CreateThread(function()
    local textoMostrado = false -- Variable de control
    while true do
        local espera = 1500
        local coordsJugador = GetEntityCoords(PlayerPedId())
        local distancia = #(coordsJugador - Config.npccoord)

        if distancia < Config.sleepdistance then
            espera = 1
            if distancia < Config.textdistance then
                if not textoMostrado then -- Solo mostrar si no estaba mostrado
                    if Config.DPTextUI then
                        MostrarTextoUI('tienda_mascotas', Config.text, Config.controlkeys, false)
                    else
                        DibujarTexto3D(Config.npccoord.x, Config.npccoord.y, Config.npccoord.z + 0.0, Config.text)
                    end
                    textoMostrado = true
                end

                if distancia < Config.controldistance and IsControlJustReleased(0, Config.controlkeys) then
                    SendNUIMessage({
                        action = "openmenu"
                    })
                    SetNuiFocus(true, true)
                    if Config.DPTextUI then
                        OcultarTextoUI('tienda_mascotas')
                    end
                    textoMostrado = false -- Resetear para que se vuelva a mostrar al cerrar el menú
                end
            elseif textoMostrado then
                if Config.DPTextUI then
                    OcultarTextoUI('tienda_mascotas')
                end
                textoMostrado = false
            end
        elseif textoMostrado then
            if Config.DPTextUI then
                OcultarTextoUI('tienda_mascotas')
            end
            textoMostrado = false
        end
        Citizen.Wait(espera)
    end
end)

-- Callbacks de NUI
RegisterNUICallback("closenui", function()
    SetNuiFocus(false, false)
    if not Config.DPTextUI then
        return
    end

    -- Volver a mostrar el texto si el jugador sigue cerca
    local distancia = #(GetEntityCoords(PlayerPedId()) - Config.npccoord)
    if distancia < Config.textdistance then
        textoMostrado = false -- Permitir que se muestre de nuevo en el bucle principal
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        OcultarTextoUI()
        if spawned_ped then
            savePetStats()
        end
    end
end)

function DibujarTexto3D(x, y, z, texto)
    if Config.DPTextUI then
        return
    end

    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)

    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(texto)
    DrawText(_x, _y)
    local factor = (string.len(texto)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

RegisterNUICallback("spawnpet", function()
    if not pcode then
        notificar("No has seleccionado una mascota", 'error')
        return
    end
    spawnMascota(pcode)
end)

RegisterNUICallback("vehicle", function()
    entrarVehiculo()
end)

RegisterNUICallback("showpet", function(data)
    local id = tonumber(data.id)
    SetEntityVisible(PlayerPedId(), false)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 0)
    SetCamCoord(cam, Config.shop.cam)
    SetCamRot(cam, Config.shop.rot, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500)
    zoomLevel = 0.0 -- Reiniciar el zoom al abrir la vista de compra

    for k, v in pairs(Config.pets.dogs) do
        if id == k then
            SendNUIMessage({
                action = "updatepetname",
                name = v.name,
                price = v.price
            })

            RequestModel(v.pet_code)
            while not HasModelLoaded(v.pet_code) do
                Citizen.Wait(1)
            end

            if DoesEntityExist(b) then
                DeleteEntity(b)
            end

            b = CreatePed(4, v.pet_code, Config.shop.pedspawn.x, Config.shop.pedspawn.y, Config.shop.pedspawn.z,
                Config.shop.pedspawn_h, false, false)
            SetPedFleeAttributes(b, 0, 0)
            SetPedDropsWeaponsWhenDead(b, false)
            SetPedDiesWhenInjured(b, false)
            SetEntityInvincible(b, true)
            FreezeEntityPosition(b, true)
            SetBlockingOfNonTemporaryEvents(b, true)

            precio = v.price
            petcode = v.pet_code
        end
    end

    for k, v in pairs(Config.pets.others) do
        if id == k + 100 then -- IDs diferentes para otros animales
            SendNUIMessage({
                action = "updatepetname",
                name = v.name,
                price = v.price
            })

            RequestModel(v.pet_code)
            while not HasModelLoaded(v.pet_code) do
                Citizen.Wait(1)
            end

            if DoesEntityExist(b) then
                DeleteEntity(b)
            end

            b = CreatePed(4, v.pet_code, Config.shop.pedspawn.x, Config.shop.pedspawn.y, Config.shop.pedspawn.z,
                Config.shop.pedspawn_h, false, false)
            SetPedFleeAttributes(b, 0, 0)
            SetPedDropsWeaponsWhenDead(b, false)
            SetPedDiesWhenInjured(b, false)
            SetEntityInvincible(b, true)
            FreezeEntityPosition(b, true)
            SetBlockingOfNonTemporaryEvents(b, true)

            precio = v.price
            petcode = v.pet_code
        end
    end
end)

RegisterNUICallback("cam", function()
    if DoesCamExist(cam) then
        DestroyCam(cam, true)
        SetEntityVisible(PlayerPedId(), true)
        RenderScriptCams(false, true, 500)
        if DoesEntityExist(b) then
            DeleteEntity(b)
        end
        cam = nil
        zoomLevel = 0.0 -- Reiniciar el zoom al cerrar la cámara
    end
end)

RegisterNUICallback("rotatepet", function(data)
    if DoesEntityExist(b) then
        local currentHeading = GetEntityHeading(b)
        local newHeading = currentHeading + (data.direction * 5.0) -- Rota 5 grados
        SetEntityHeading(b, newHeading)
    end
end)

RegisterNUICallback("zoompet", function(data)
    if DoesCamExist(cam) then
        local camCoords = GetCamCoord(cam)
        local pedCoords = GetEntityCoords(b)
        local direction = data.direction
        local zoomStep = 0.2 -- Ajusta la velocidad del zoom

        -- Limitar el zoom para evitar que la cámara se aleje o se acerque demasiado
        local minZoom = -0.5
        local maxZoom = 0.5
        local newZoomLevel = zoomLevel + direction * zoomStep

        if newZoomLevel >= minZoom and newZoomLevel <= maxZoom then
            zoomLevel = newZoomLevel
            local newX = camCoords.x + (pedCoords.x - camCoords.x) * (direction * zoomStep)
            local newY = camCoords.y + (pedCoords.y - camCoords.y) * (direction * zoomStep)
            local newZ = camCoords.z + (pedCoords.z - camCoords.z) * (direction * zoomStep)
            SetCamCoord(cam, newX, newY, newZ)
        end
    end
end)

RegisterNUICallback("sit", function()
    if spawned_ped then
        sentar(spawned_ped)
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

RegisterNUICallback("sleep", function()
    if spawned_ped then
        acostar(spawned_ped)
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

-- Función para spawnear mascota
function spawnMascota(modelo)
    if spawned_ped and DoesEntityExist(spawned_ped) then
        DeleteEntity(spawned_ped)
        spawned_ped = nil
        notificar("Mascota guardada", 'primary')
        return
    end

    RequestModel(modelo)
    while not HasModelLoaded(modelo) do
        Citizen.Wait(1)
    end

    local coordsJugador = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 2.0, 0.0)
    spawned_ped = CreatePed(28, modelo, coordsJugador.x, coordsJugador.y, coordsJugador.z,
        GetEntityHeading(PlayerPedId()), true, true)

    SetBlockingOfNonTemporaryEvents(spawned_ped, true)
    SetPedFleeAttributes(spawned_ped, 0, 0)
    SetPedRelationshipGroupHash(spawned_ped, GetHashKey("k9"))

    local blip = AddBlipForEntity(spawned_ped)
    SetBlipAsFriendly(blip, true)
    SetBlipSprite(blip, 442)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("MI MASCOTA")
    EndTextCommandSetBlipName(blip)

    NetworkRegisterEntityAsNetworked(spawned_ped)
    while not NetworkGetEntityIsNetworked(spawned_ped) do
        NetworkRegisterEntityAsNetworked(spawned_ped)
        Citizen.Wait(1)
    end

    seguirJugador()
    notificar("¡Mascota creada!", 'success')
end

-- Función para que la mascota siga al jugador
function seguirJugador()
    if spawned_ped ~= nil then
        local tieneControl = false
        solicitarControlRed(function(cb)
            tieneControl = cb
        end)
        if tieneControl then
            TaskFollowToOffsetOfEntity(spawned_ped, PlayerPedId(), 0.5, 0.0, 0.0, 5.0, -1, 0.0, 1)
            SetPedKeepTask(spawned_ped, true)
        end
    end
end

-- Función para sentar a la mascota
function sentar(entidad)
    local animacionInicio = "creatures@rottweiler@amb@world_dog_sitting@base"
    local nombreAnimInicio = "base"
    local animacionFin = "creatures@rottweiler@amb@world_dog_sitting@exit"
    local nombreAnimFin = "exit"
    if IsEntityPlayingAnim(entidad, animacionInicio, nombreAnimInicio, 3) then
        RequestAnimDict(animacionFin)
        while not HasAnimDictLoaded(animacionFin) do
            Citizen.Wait(100)
        end
        TaskPlayAnim(spawned_ped, animacionFin, nombreAnimFin, 1.0, -1, -1, 2, 0, 0, 0, 0)
        Citizen.Wait(2500)
        seguirJugador()
        if HasEntityAnimFinished(spawned_ped, animacionFin, nombreAnimFin, 3) then
            ClearPedSecondaryTask(spawned_ped)
        end
    else
        RequestAnimDict(animacionInicio)
        while not HasAnimDictLoaded(animacionInicio) do
            Citizen.Wait(100)
        end
        TaskPlayAnim(spawned_ped, animacionInicio, nombreAnimInicio, 1.0, -1, -1, 2, 0, 0, 0, 0)
    end
end

-- Función para acostar a la mascota
function acostar(entidad)
    local animacionInicio = "creatures@rottweiler@amb@sleep_in_kennel@"
    local nombreAnimInicio = "sleep_in_kennel"
    local animacionFin = "creatures@rottweiler@amb@sleep_in_kennel@"
    local nombreAnimFin = "exit_kennel"
    if IsEntityPlayingAnim(entidad, animacionInicio, nombreAnimInicio, 3) then
        RequestAnimDict(animacionFin)
        while not HasAnimDictLoaded(animacionFin) do
            Citizen.Wait(100)
        end
        TaskPlayAnim(spawned_ped, animacionFin, nombreAnimFin, 1.0, -1, -1, 2, 0, 0, 0, 0)
        Citizen.Wait(2500)
        seguirJugador()
        if HasEntityAnimFinished(spawned_ped, animacionFin, nombreAnimFin, 3) then
            ClearPedSecondaryTask(spawned_ped)
        end
    else
        RequestAnimDict(animacionInicio)
        while not HasAnimDictLoaded(animacionInicio) do
            Citizen.Wait(100)
        end
        TaskPlayAnim(spawned_ped, animacionInicio, nombreAnimInicio, 1.0, -1, -1, 2, 0, 0, 0, 0)
    end
end

-- Función para entrar/salir del vehículo
function entrarVehiculo()
    if spawned_ped ~= nil then
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            if bindimi then
                bindimi = false
                ClearPedTasks(spawned_ped)

                local vehiculo = GetVehiclePedIsIn(PlayerPedId(), false)
                local rotacionVeh = GetEntityHeading(vehiculo)

                TaskGoToEntity(spawned_ped, vehiculo, -1, 0.5, 100, 1073741824, 0)
                TaskAchieveHeading(spawned_ped, rotacionVeh, -1)

                RequestAnimDict("creatures@rottweiler@in_vehicle@van")
                RequestAnimDict("creatures@rottweiler@amb@world_dog_sitting@base")

                while not HasAnimDictLoaded("creatures@rottweiler@in_vehicle@van") or
                    not HasAnimDictLoaded("creatures@rottweiler@amb@world_dog_sitting@base") do
                    Citizen.Wait(1)
                end

                TaskPlayAnim(spawned_ped, "creatures@rottweiler@in_vehicle@van", "get_in", 8.0, -4.0, -1, 2, 0.0)
                Citizen.Wait(700)
                ClearPedTasks(spawned_ped)

                AttachEntityToEntity(spawned_ped, vehiculo, GetEntityBoneIndexByName(vehiculo, "seat_pside_r"), 0.0,
                    0.0, 0.25)
                TaskPlayAnim(spawned_ped, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 8.0, -4.0, -1, 2,
                    0.0)
                notificar("Mascota subida al vehículo", 'success')
            else
                local vehiculo = GetEntityAttachedTo(spawned_ped)
                local posVeh = GetEntityCoords(vehiculo)
                local forwardX = GetEntityForwardVector(vehiculo).x * 3.7
                local forwardY = GetEntityForwardVector(vehiculo).y * 3.7
                local _, groundZ = GetGroundZFor_3dCoord(posVeh.x, posVeh.y, posVeh.z, 0)
                bindimi = true
                ClearPedTasks(spawned_ped)
                DetachEntity(spawned_ped)
                SetEntityCoords(spawned_ped, posVeh.x - forwardX, posVeh.y - forwardY, groundZ)
                notificar("Mascota bajada del vehículo", 'primary')
            end
        else
            notificar("Entra a un vehículo primero", 'error')
        end
    else
        notificar("No tienes una mascota activa", 'error')
    end
end

-- Función para solicitar control de red
function solicitarControlRed(callback)
    local netId = NetworkGetNetworkIdFromEntity(spawned_ped)
    local temporizador = 0
    NetworkRequestControlOfNetworkId(netId)
    while not NetworkHasControlOfNetworkId(netId) do
        Citizen.Wait(1)
        NetworkRequestControlOfNetworkId(netId)
        temporizador = temporizador + 1
        if temporizador == 5000 then
            print("Fallo al obtener control")
            callback(false)
            break
        end
    end
    callback(true)
end

-- Eventos
RegisterCommand(Config.openmenu, function()
    TriggerServerEvent("pet:control")
end)

-- Control por tecla si está configurado
if Config.key then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if IsControlJustReleased(0, GetKey(Config.key)) then
                TriggerServerEvent("pet:control")
            end
        end
    end)
end

-- Función para convertir la tecla de string a código de control
function GetKey(key)
    local keys = {
        ["A"] = 34,
        ["B"] = 29,
        ["C"] = 26,
        ["D"] = 30,
        ["E"] = 46,
        ["F"] = 49,
        ["G"] = 47,
        ["H"] = 74,
        ["I"] = 0,
        ["J"] = 0,
        ["K"] = 0,
        ["L"] = 0,
        ["M"] = 0,
        ["N"] = 249,
        ["O"] = 0,
        ["P"] = 0,
        ["Q"] = 44,
        ["R"] = 45,
        ["S"] = 33,
        ["T"] = 0,
        ["U"] = 0,
        ["V"] = 0,
        ["W"] = 32,
        ["X"] = 0,
        ["Y"] = 246,
        ["Z"] = 20,
        ["F1"] = 288,
        ["F2"] = 289,
        ["F3"] = 170,
        ["F4"] = 0,
        ["F5"] = 166,
        ["F6"] = 167,
        ["F7"] = 168,
        ["F9"] = 56,
        ["F10"] = 57,
        ["F11"] = 58,
        ["F12"] = 59
    }
    return keys[string.upper(key)] or nil
end

-- Menú del petmenu
RegisterNetEvent("pet:cl:control", function(var, petData)
    if var then
        -- Si petData es nil, usa los valores actuales de pcode y petStats
        if petData then
            pcode = petData.pet_code
            if petData.health then
                petStats.health = petData.health
            end
            if petData.hunger then
                petStats.hunger = petData.hunger
            end
            if petData.thirst then
                petStats.thirst = petData.thirst
            end
            if petData.hygiene then
                petStats.hygiene = petData.hygiene
            end
            if petData.affection then
                petStats.affection = petData.affection
            end
        end

        local menuItems = {{
            header = "MENÚ DE MASCOTA",
            isMenuHeader = true
        }}

        -- Agregar estadísticas si están habilitadas y cuidados también está habilitado
        if Config.menus.estadisticas and Config.menus.cuidados then
            table.insert(menuItems, {
                header = "ESTADO DE TU MASCOTA",
                isMenuHeader = true
            })
            table.insert(menuItems, {
                header = "Salud: " .. petStats.health .. "%",
                txt = "Estado físico general de tu mascota",
                icon = "fa-solid fa-heart-pulse",
                disabled = true
            })
            table.insert(menuItems, {
                header = "Hambre: " .. petStats.hunger .. "%",
                txt = "Nivel de alimentación de tu mascota",
                icon = "fa-solid fa-bowl-food",
                disabled = true
            })
            table.insert(menuItems, {
                header = "Sed: " .. petStats.thirst .. "%",
                txt = "Nivel de hidratación de tu mascota",
                icon = "fa-solid fa-droplet",
                disabled = true
            })
            table.insert(menuItems, {
                header = "Higiene: " .. petStats.hygiene .. "%",
                txt = "Limpieza y cuidado de tu mascota",
                icon = "fa-solid fa-bath",
                disabled = true
            })
            table.insert(menuItems, {
                header = "Cariño: " .. petStats.affection .. "%",
                txt = "Nivel de afecto y atención recibida",
                icon = "fa-solid fa-hand-holding-heart",
                disabled = true
            })
        end

        -- Menú de interacción (siempre visible)
        table.insert(menuItems, {
            header = "INTERACCIÓN",
            txt = "Acciones básicas con tu mascota",
            icon = "fa-solid fa-paw",
            params = {
                event = "dp-pets:openInteractionMenu"
            }
        })

        -- Menú de cuidados si está habilitado
        if Config.menus.cuidados then
            table.insert(menuItems, {
                header = "CUIDADOS",
                txt = "Atender las necesidades de tu mascota",
                icon = "fa-solid fa-hand-holding-medical",
                params = {
                    event = "dp-pets:openCareMenu"
                }
            })
        end

        -- Opción de liberar si está habilitada
        if Config.menus.liberar then
            table.insert(menuItems, {
                header = "LIBERAR MASCOTA",
                txt = "Dejar marchar a tu mascota permanentemente",
                icon = "fa-solid fa-heart-crack",
                params = {
                    event = "dp-pets:openReleaseMenu"
                }
            })
        end

        -- Cerrar menú (siempre visible)
        table.insert(menuItems, {
            header = "CERRAR MENÚ",
            icon = "fa-solid fa-xmark",
            params = {
                event = "qb-menu:closeMenu"
            }
        })

        exports['qb-menu']:openMenu(menuItems)
    else
        notificar("No tienes una mascota", 'error')
    end
end)

-- Función para guardar las estadísticas en el servidor
local function savePetStats()
    TriggerServerEvent("dp-pets:updateStats", petStats)
end

-- Función para disminuir necesidades de la mascota
function decreasePetNeeds()
    if spawned_ped and DoesEntityExist(spawned_ped) then
        local currentTime = GetGameTimer()

        -- Disminuir hambre y sed según configuración
        local randomDecreaseHunger = math.random(Config.needsDecrease.hunger.min, Config.needsDecrease.hunger.max)
        local randomDecreaseThirst = math.random(Config.needsDecrease.thirst.min, Config.needsDecrease.thirst.max)

        petStats.hunger = math.max(0, petStats.hunger - randomDecreaseHunger)
        petStats.thirst = math.max(0, petStats.thirst - randomDecreaseThirst)

        -- Disminuir higiene según configuración
        if currentTime - lastHygieneDecrease >= (Config.needsDecrease.hygiene.interval * 60 * 1000) then
            petStats.hygiene = math.max(0, petStats.hygiene - Config.needsDecrease.hygiene.amount)
            lastHygieneDecrease = currentTime

            -- Notificación si la higiene es crítica
            if petStats.hygiene <= Config.lowNeedThresholds.hygiene then
                notificar("¡Tu mascota está sucia (" .. petStats.hygiene .. "%)! Báñala.", 'error')
            end
        end

        -- Disminuir afecto según configuración
        if currentTime - lastAffectionDecrease >= (Config.needsDecrease.affection.interval * 60 * 1000) then
            petStats.affection = math.max(0, petStats.affection - Config.needsDecrease.affection.amount)
            lastAffectionDecrease = currentTime

            -- Notificación si el afecto es crítico
            if petStats.affection <= Config.lowNeedThresholds.affection then
                notificar("¡Tu mascota se siente ignorada (" .. petStats.affection .. "%)!", 'error')
            end
        end

        -- Notificaciones para hambre y sed
        if petStats.hunger <= Config.lowNeedThresholds.hunger then
            notificar("¡Tu mascota tiene hambre (" .. petStats.hunger .. "%)!", 'error')
        end
        if petStats.thirst <= Config.lowNeedThresholds.thirst then
            notificar("¡Tu mascota tiene sed (" .. petStats.thirst .. "%)!", 'error')
        end

        -- Si hambre o sed llegan a 0, reducir salud según configuración
        if petStats.hunger <= 0 or petStats.thirst <= 0 then
            petStats.health = math.max(0, petStats.health - Config.needsDecrease.health.amount)
            if petStats.health <= Config.lowNeedThresholds.health then
                notificar("¡Tu mascota está en peligro! Salud: " .. petStats.health .. "%", 'error')
            end
        end

        -- Muerte por salud <= 0
        if petStats.health <= 0 then
            notificar("¡Tu mascota ha muerto por falta de cuidados!", 'error')
            DeleteEntity(spawned_ped)
            spawned_ped = nil
            TriggerServerEvent("delete:pet")
        end

        -- Guardar cambios en el servidor
        savePetStats()
    end
end

-- Modificar el hilo que llama a decreasePetNeeds para que se ejecute cada minuto
Citizen.CreateThread(function()
    while true do
        if spawned_ped and DoesEntityExist(spawned_ped) then
            decreasePetNeeds()
        end
        Citizen.Wait(15000) -- Verificar cada minuto (60000 ms)
    end
end)

-- Menú de Interacción
RegisterNetEvent('dp-pets:openInteractionMenu', function()
    local menuItems = {{
        header = "INTERACCIÓN CON MASCOTA",
        isMenuHeader = true
    }}

    -- Verificar si la mascota está spawneda
    local isPetSpawned = spawned_ped and DoesEntityExist(spawned_ped)

    -- Opciones de llamar/mandar a casa (mutuamente excluyentes)
    if not isPetSpawned then
        table.insert(menuItems, {
            header = "Llamar mascota",
            icon = "fa-solid fa-bell",
            params = {
                event = "dp-pets:callPet"
            }
        })
    else
        table.insert(menuItems, {
            header = "Mandar a casa",
            icon = "fa-solid fa-house",
            params = {
                event = "dp-pets:sendHome"
            }
        })

        -- Verificar si está en un vehículo
        local isInVehicle = IsEntityAttachedToAnyVehicle(spawned_ped)

        -- Verificar si está sentada
        local isSitting = IsEntityPlayingAnim(spawned_ped, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 3)

        -- Verificar si está durmiendo
        local isSleeping = IsEntityPlayingAnim(spawned_ped, "creatures@rottweiler@amb@sleep_in_kennel@",
            "sleep_in_kennel", 3)

        -- Opciones de vehículo
        if not isInVehicle then
            table.insert(menuItems, {
                header = "Meter al vehículo",
                icon = "fa-solid fa-car-side",
                params = {
                    event = "dp-pets:putInVehicle"
                }
            })
        else
            table.insert(menuItems, {
                header = "Sacar del vehículo",
                icon = "fa-solid fa-person-walking",
                params = {
                    event = "dp-pets:takeOutVehicle"
                }
            })
        end

        -- Opciones de sentar/levantar
        if not isSitting then
            table.insert(menuItems, {
                header = "Sentar mascota",
                icon = "fa-solid fa-couch",
                params = {
                    event = "dp-pets:sitPet"
                }
            })
        else
            table.insert(menuItems, {
                header = "Levantar mascota",
                icon = "fa-solid fa-person-walking",
                params = {
                    event = "dp-pets:standPet"
                }
            })
        end

        -- Opciones de dormir/despertar
        if not isSleeping then
            table.insert(menuItems, {
                header = "Dormir mascota",
                icon = "fa-solid fa-moon",
                params = {
                    event = "dp-pets:sleepPet"
                }
            })
        else
            table.insert(menuItems, {
                header = "Despertar mascota",
                icon = "fa-solid fa-sun",
                params = {
                    event = "dp-pets:wakePet"
                }
            })
        end
    end

    -- Opción para volver
    table.insert(menuItems, {
        header = "Volver al menú principal",
        icon = "fa-solid fa-arrow-left",
        params = {
            event = "pet:cl:control",
            args = {true, {
                pet_code = pcode,
                health = petStats.health,
                hunger = petStats.hunger,
                thirst = petStats.thirst,
                hygiene = petStats.hygiene,
                affection = petStats.affection
            }}
        }
    })

    exports['qb-menu']:openMenu(menuItems)
end)

-- Nuevos eventos para las acciones específicas
RegisterNetEvent('dp-pets:callPet', function()
    if not pcode then
        notificar("No has seleccionado una mascota", 'error')
        return
    end
    spawnMascota(pcode)
end)

RegisterNetEvent('dp-pets:sendHome', function()
    if spawned_ped and DoesEntityExist(spawned_ped) then
        DeleteEntity(spawned_ped)
        spawned_ped = nil
        notificar("Mascota enviada a casa", 'primary')
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

RegisterNetEvent('dp-pets:putInVehicle', function()
    if spawned_ped then
        entrarVehiculo()
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

RegisterNetEvent('dp-pets:takeOutVehicle', function()
    if spawned_ped then
        entrarVehiculo() -- La misma función maneja meter y sacar
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

RegisterNetEvent('dp-pets:standPet', function()
    if spawned_ped then
        sentar(spawned_ped) -- La misma función maneja sentar y levantar
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

RegisterNetEvent('dp-pets:wakePet', function()
    if spawned_ped then
        acostar(spawned_ped) -- La misma función maneja dormir y despertar
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

-- Menú de Cuidados
RegisterNetEvent('dp-pets:openCareMenu', function()
    if not Config.menus.cuidados then
        return
    end

    local isPetPresent = spawned_ped and DoesEntityExist(spawned_ped)

    local menuItems = {{
        header = "CUIDAR A TU MASCOTA",
        isMenuHeader = true
    }, {
        header = "Curar",
        txt = isPetPresent and "Requiere: " .. Config.petItems.medkit.label or "¡La mascota debe estar contigo!",
        icon = "fa-solid fa-briefcase-medical",
        disabled = not isPetPresent,
        params = {
            event = isPetPresent and "dp-pets:healthPet" or nil
        }
    }, {
        header = "Alimentar",
        txt = isPetPresent and "Requiere: " .. Config.petItems.food.label or "¡La mascota debe estar contigo!",
        icon = "fa-solid fa-bone",
        disabled = not isPetPresent,
        params = {
            event = isPetPresent and "dp-pets:feedPet" or nil
        }
    }, {
        header = "Hidratar",
        txt = isPetPresent and "Requiere: " .. Config.petItems.water.label or "¡La mascota debe estar contigo!",
        icon = "fa-solid fa-bottle-water",
        disabled = not isPetPresent,
        params = {
            event = isPetPresent and "dp-pets:hydratePet" or nil
        }
    }, {
        header = "Limpiar",
        txt = isPetPresent and "Requiere: " .. Config.petItems.towel.label or "¡La mascota debe estar contigo!",
        icon = "fa-solid fa-shower",
        disabled = not isPetPresent,
        params = {
            event = isPetPresent and "dp-pets:cleanPet" or nil
        }
    }, {
        header = "Acariciar",
        txt = isPetPresent and "No requiere items" or "¡La mascota debe estar contigo!",
        icon = "fa-solid fa-hand",
        disabled = not isPetPresent,
        params = {
            event = isPetPresent and "dp-pets:petPet" or nil
        }
    }, {
        header = "Dar premio",
        txt = isPetPresent and "Requiere: " .. Config.petItems.treats.label or "¡La mascota debe estar contigo!",
        icon = "fa-solid fa-gift",
        disabled = not isPetPresent,
        params = {
            event = isPetPresent and "dp-pets:giveTreat" or nil
        }
    }, {
        header = "Volver al menú principal",
        icon = "fa-solid fa-arrow-left",
        params = {
            event = "pet:cl:control",
            args = {true, {
                pet_code = pcode,
                health = petStats.health,
                hunger = petStats.hunger,
                thirst = petStats.thirst,
                hygiene = petStats.hygiene,
                affection = petStats.affection
            }}
        }
    }}

    exports['qb-menu']:openMenu(menuItems)
end)

-- Menú de Liberación
RegisterNetEvent('dp-pets:openReleaseMenu', function()
    if not Config.menus.liberar then
        return
    end

    local menuItems = {{
        header = "¿LIBERAR MASCOTA?",
        txt = "¿Estás seguro de querer dejar marchar a tu mascota? Esta acción es permanente.",
        isMenuHeader = true
    }, {
        header = "CONFIRMAR LIBERACIÓN",
        txt = "Liberar a tu mascota permanentemente",
        icon = "fa-solid fa-heart-crack",
        params = {
            event = "dp-pets:deletePet"
        }
    }, {
        header = "Cancelar",
        icon = "fa-solid fa-ban",
        params = {
            event = "pet:cl:control",
            args = {true, pcode}
        }
    }}

    exports['qb-menu']:openMenu(menuItems)
end)

-- Eventos para las acciones de cuidado con items
RegisterNetEvent('dp-pets:healthPet', function()
    if not spawned_ped or not DoesEntityExist(spawned_ped) then
        notificar("No puedes curar a tu mascota si no está contigo", 'error')
        return
    end

    QBCore.Functions.TriggerCallback('dp-pets:useItem', function(success)
        if success then
            petStats.health = math.min(100, petStats.health + Config.petItems.medkit.increase.health)
            savePetStats()
            notificar("Has usado un " .. Config.petItems.medkit.label .. ". Salud: " .. petStats.health .. "%",
                'success')
        else
            notificar("Necesitas un " .. Config.petItems.medkit.label, 'error')
        end
    end, Config.petItems.medkit.name)
end)

RegisterNetEvent('dp-pets:feedPet', function()
    if not spawned_ped or not DoesEntityExist(spawned_ped) then
        notificar("No puedes alimentar a tu mascota si no está contigo", 'error')
        return
    end

    QBCore.Functions.TriggerCallback('dp-pets:useItem', function(success)
        if success then
            petStats.hunger = math.min(100, petStats.hunger + Config.petItems.food.increase.hunger)
            savePetStats()
            notificar("Has usado " .. Config.petItems.food.label .. ". Hambre: " .. petStats.hunger .. "%", 'success')
        else
            notificar("Necesitas " .. Config.petItems.food.label, 'error')
        end
    end, Config.petItems.food.name)
end)

RegisterNetEvent('dp-pets:hydratePet', function()
    if not spawned_ped or not DoesEntityExist(spawned_ped) then
        notificar("No puedes hidratar a tu mascota si no está contigo", 'error')
        return
    end

    QBCore.Functions.TriggerCallback('dp-pets:useItem', function(success)
        if success then
            petStats.thirst = math.min(100, petStats.thirst + Config.petItems.water.increase.thirst)
            savePetStats()
            notificar("Has usado " .. Config.petItems.water.label .. ". Sed: " .. petStats.thirst .. "%", 'success')
        else
            notificar("Necesitas " .. Config.petItems.water.label, 'error')
        end
    end, Config.petItems.water.name)
end)

RegisterNetEvent('dp-pets:cleanPet', function()
    if not spawned_ped or not DoesEntityExist(spawned_ped) then
        notificar("No puedes limpiar a tu mascota si no está contigo", 'error')
        return
    end

    QBCore.Functions.TriggerCallback('dp-pets:useItem', function(success)
        if success then
            petStats.hygiene = math.min(100, petStats.hygiene + Config.petItems.towel.increase.hygiene)
            savePetStats()
            notificar("Has usado una " .. Config.petItems.towel.label .. ". Higiene: " .. petStats.hygiene .. "%",
                'success')
        else
            notificar("Necesitas una " .. Config.petItems.towel.label, 'error')
        end
    end, Config.petItems.towel.name)
end)

RegisterNetEvent('dp-pets:petPet', function()
    if not spawned_ped or not DoesEntityExist(spawned_ped) then
        notificar("No puedes acariciar a tu mascota si no está contigo", 'error')
        return
    end

    petStats.affection = math.min(100, petStats.affection + 10)
    savePetStats()
    notificar("¡Mascota contenta! Afecto: " .. petStats.affection .. "%", 'success')
end)

RegisterNetEvent('dp-pets:giveTreat', function()
    if not spawned_ped or not DoesEntityExist(spawned_ped) then
        notificar("No puedes dar premios a tu mascota si no está contigo", 'error')
        return
    end

    QBCore.Functions.TriggerCallback('dp-pets:useItem', function(success)
        if success then
            petStats.hunger = math.min(100, petStats.hunger + Config.petItems.treats.increase.hunger)
            petStats.affection = math.min(100, petStats.affection + Config.petItems.treats.increase.affection)
            savePetStats()
            notificar(
                "Has dado " .. Config.petItems.treats.label .. ". Hambre: " .. petStats.hunger .. "%, Afecto: " ..
                    petStats.affection .. "%", 'success')
        else
            notificar("Necesitas " .. Config.petItems.treats.label, 'error')
        end
    end, Config.petItems.treats.name)
end)

-- Mantenemos los eventos originales
RegisterNetEvent('dp-pets:spawnPet', function()
    if not pcode then
        notificar("No has seleccionado una mascota", 'error')
        return
    end
    spawnMascota(pcode)
end)

RegisterNetEvent('dp-pets:vehiclePet', function()
    entrarVehiculo()
end)

RegisterNetEvent('dp-pets:sitPet', function()
    if spawned_ped then
        sentar(spawned_ped)
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

RegisterNetEvent('dp-pets:sleepPet', function()
    if spawned_ped then
        acostar(spawned_ped)
    else
        notificar("No tienes una mascota activa", 'error')
    end
end)

RegisterNetEvent('dp-pets:deletePet', function()
    if DoesEntityExist(spawned_ped) then
        DeleteEntity(spawned_ped)
    end
    TriggerServerEvent("delete:pet")
    exports['qb-menu']:closeMenu()
end)

RegisterNUICallback("box-menu", function()
    for k, v in pairs(Config.pets.dogs) do
        SendNUIMessage({
            action = "add-pet",
            name = v.name,
            img = v.img,
            id = k,
            price = v.price
        })
    end
end)

RegisterNUICallback("box-menu2", function()
    for k, v in pairs(Config.pets.others) do
        SendNUIMessage({
            action = "add-pet",
            name = v.name,
            img = v.img,
            id = k + 100, -- IDs diferentes para otros animales
            price = v.price
        })
    end
end)

RegisterNUICallback("buy", function(data, cb)
    if not petcode or not precio then
        cb({
            success = false
        })
        return
    end
    TriggerServerEvent("buy:pet", petcode, precio)
    cb({
        success = true
    })
end)

RegisterNUICallback("delete", function()
    SetNuiFocus(false, false)
    if DoesEntityExist(spawned_ped) then
        DeleteEntity(spawned_ped)
    end
    TriggerServerEvent("delete:pet")
end)

-- Función para notificar
function notificar(texto, tipo)
    QBCore.Functions.Notify(texto, tipo or 'primary', 5000)
end
