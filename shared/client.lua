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
    while true do
        local espera = 1500
        local coordsJugador = GetEntityCoords(PlayerPedId())
        local distancia = #(coordsJugador - Config.npccoord)

        if distancia < Config.sleepdistance then
            espera = 1
            if distancia < Config.textdistance then
                DibujarTexto3D(Config.npccoord.x, Config.npccoord.y, Config.npccoord.z + 0.0, Config.text)
                if distancia < Config.controldistance and IsControlJustReleased(0, Config.controlkeys) then
                    SendNUIMessage({
                        action = "openmenu"
                    })
                    SetNuiFocus(true, true)
                end
            end
        end
        Citizen.Wait(espera)
    end
end)

-- Callbacks de NUI
RegisterNUICallback("closenui", function()
    SetNuiFocus(false, false)
end)

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

    for k, v in pairs(Config.items) do
        if id == k then
            -- Enviar el nombre y precio a la UI
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
        local minZoom = -2.0
        local maxZoom = 2.0
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

-- Menú del petmenu
RegisterNetEvent("pet:cl:control", function(var, petcodee)
    if var then
        pcode = petcodee
        local menuItems = {{
            header = "ESTADO DE TU MASCOTA",
            isMenuHeader = true
        }, {
            header = "Salud: 0%",
            txt = "Estado físico general de tu mascota",
            icon = "fa-solid fa-heart-pulse",
            disabled = true
        }, {
            header = "Hambre: 0%",
            txt = "Nivel de alimentación de tu mascota",
            icon = "fa-solid fa-bowl-food",
            disabled = true
        }, {
            header = "Sed: 0%",
            txt = "Nivel de hidratación de tu mascota",
            icon = "fa-solid fa-droplet",
            disabled = true
        }, {
            header = "Higiene: 0%",
            txt = "Limpieza y cuidado de tu mascota",
            icon = "fa-solid fa-bath",
            disabled = true
        }, {
            header = "Cariño: 0%",
            txt = "Nivel de afecto y atención recibida",
            icon = "fa-solid fa-hand-holding-heart",
            disabled = true
        }, {
            header = "INTERACCIÓN",
            txt = "Acciones básicas con tu mascota",
            icon = "fa-solid fa-paw",
            params = {
                event = "dp-pets:openInteractionMenu"
            }
        }, {
            header = "CUIDADOS",
            txt = "Atender las necesidades de tu mascota",
            icon = "fa-solid fa-hand-holding-medical",
            params = {
                event = "dp-pets:openCareMenu"
            }
        }, {
            header = "LIBERAR MASCOTA",
            txt = "Dejar marchar a tu mascota permanentemente",
            icon = "fa-solid fa-heart-crack",
            params = {
                event = "dp-pets:openReleaseMenu"
            }
        }, {
            header = "CERRAR MENÚ",
            icon = "fa-solid fa-xmark",
            params = {
                event = "qb-menu:closeMenu"
            }
        }}

        exports['qb-menu']:openMenu(menuItems)
    else
        notificar("No tienes una mascota", 'error')
    end
end)

-- Menú de Interacción
RegisterNetEvent('dp-pets:openInteractionMenu', function()
    local menuItems = {{
        header = "INTERACCIÓN CON MASCOTA",
        isMenuHeader = true
    }, {
        header = "Traer/Devolver mascota",
        icon = "fa-solid fa-house",
        params = {
            event = "dp-pets:spawnPet"
        }
    }, {
        header = "Meter/Sacar del Vehículo",
        icon = "fa-solid fa-car",
        params = {
            event = "dp-pets:vehiclePet"
        }
    }, {
        header = "Sentar/Levantar Mascota",
        icon = "fa-solid fa-chair",
        params = {
            event = "dp-pets:sitPet"
        }
    }, {
        header = "Dormir/Despertar Mascota",
        icon = "fa-solid fa-moon",
        params = {
            event = "dp-pets:sleepPet"
        }
    }, {
        header = "Volver al menú principal",
        icon = "fa-solid fa-arrow-left",
        params = {
            event = "pet:cl:control",
            args = {true, pcode}
        }
    }}

    exports['qb-menu']:openMenu(menuItems)
end)

-- Menú de Cuidados
RegisterNetEvent('dp-pets:openCareMenu', function()
    local menuItems = {{
        header = "CUIDAR A TU MASCOTA",
        isMenuHeader = true
    }, {
        header = "Alimentar",
        icon = "fa-solid fa-bone",
        params = {
            event = "dp-pets:feedPet"
        }
    }, {
        header = "Hidratar",
        icon = "fa-solid fa-bottle-water",
        params = {
            event = "dp-pets:hydratePet"
        }
    }, {
        header = "Bañar/Lavar",
        icon = "fa-solid fa-shower",
        params = {
            event = "dp-pets:cleanPet"
        }
    }, {
        header = "Acariciar",
        icon = "fa-solid fa-hand",
        params = {
            event = "dp-pets:petPet"
        }
    }, {
        header = "Volver al menú principal",
        icon = "fa-solid fa-arrow-left",
        params = {
            event = "pet:cl:control",
            args = {true, pcode}
        }
    }}

    exports['qb-menu']:openMenu(menuItems)
end)

-- Menú de Liberación
RegisterNetEvent('dp-pets:openReleaseMenu', function()
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

-- Eventos para las nuevas acciones (deberás implementar estas funciones)
RegisterNetEvent('dp-pets:feedPet', function()
    notificar("Has alimentado a tu mascota", 'success')
    -- Implementar lógica de alimentación
end)

RegisterNetEvent('dp-pets:hydratePet', function()
    notificar("Has dado agua a tu mascota", 'success')
    -- Implementar lógica de hidratación
end)

RegisterNetEvent('dp-pets:cleanPet', function()
    notificar("Has bañado a tu mascota", 'success')
    -- Implementar lógica de limpieza
end)

RegisterNetEvent('dp-pets:petPet', function()
    notificar("Has acariciado a tu mascota", 'success')
    -- Implementar lógica de cariño
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
    for k, v in pairs(Config.items) do
        if v.cattegory == "dog" then
            SendNUIMessage({
                action = "add-pet",
                name = v.name,
                img = v.img,
                id = k,
                price = v.price
            })
        end
    end
end)

RegisterNUICallback("box-menu2", function()
    for k, v in pairs(Config.items) do
        if v.cattegory == "others" then
            SendNUIMessage({
                action = "add-pet",
                name = v.name,
                img = v.img,
                id = k,
                price = v.price
            })
        end
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

-- Función para dibujar texto 3D
function DibujarTexto3D(x, y, z, texto)
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
