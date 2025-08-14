Config = {}

-- Configuración general
Config.Mysql = "oxmysql" -- mysql-async, ghmattimysql, oxmysql
Config.DPTextUI = true -- Cambia a false si no tienes dicho script
Config.openmenu = "petmenu" -- Comando para abrir el menú
Config.key = "H" -- Tecla para abrir el menú (puede ser nil para desactivar)

-- Configuración del NPC
Config.npc = "cs_zimbor"
Config.npcanim = "CODE_HUMAN_CROSS_ROAD_WAIT"
Config.npccoord = vector3(234.86, -16.62, 74.99)
Config.npccoordh = 178.51
Config.text = "Hablar con Arthur"
Config.controlkeys = 38 -- Tecla E

-- Distancias de interacción
Config.controldistance = 3 -- Distancia para interactuar
Config.textdistance = 3 -- Distancia para mostrar texto
Config.sleepdistance = 10 -- Distancia para desactivar el bucle

-- Configuración de la tienda
Config.shop = {
    cam = vector3(239.5, -20.0, 75.5),
    rot = vector3(-20.0, 0.0, -20.0),
    pedspawn = vector3(240.22, -18.0, 74.0),
    pedspawn_h = 120.0
}

-- Configuración de menús
Config.menus = {
    estadisticas = true, -- Mostrar/Ocultar estadísticas
    cuidados = true, -- Mostrar/Ocultar menú de cuidados
    liberar = true -- Mostrar/Ocultar opción de liberar mascota
}

-- Configuración de items para cuidados de mascotas
Config.petItems = {
    medkit = {
        name = "animal_medkit",
        label = "Botiquín para animales",
        increase = {
            health = 25 -- Aumenta 25% de salud
        },
        weight = 750,
        image = "animal_medkit.png"
    },
    food = {
        name = "animal_food",
        label = "Pienso para animales",
        increase = {
            hunger = 25 -- Aumenta 25% de hambre
        },
        weight = 1000,
        image = "animal_food.png"
    },
    water = {
        name = "animal_water",
        label = "Botella de agua para animales",
        increase = {
            thirst = 25 -- Aumenta 25% de sed
        },
        weight = 500,
        image = "animal_water.png"
    },
    towel = {
        name = "animal_towel",
        label = "Toalla húmeda",
        increase = {
            hygiene = 30 -- Aumenta 30% de higiene
        },
        weight = 250,
        image = "animal_towel.png"
    },
    treats = {
        name = "animal_treats",
        label = "Premios para animales",
        increase = {
            hunger = 25, -- Aumenta 25% de hambre
            affection = 10 -- Aumenta 10% de afecto
        },
        weight = 200,
        image = "animal_treats.png"
    }
}

-- Configuración de mascotas disponibles
Config.pets = {
    dogs = {
        [1] = {
            name = "Husky",
            pet_code = "a_c_husky",
            price = 56000,
            img = "dog2.png"
        },
        [2] = {
            name = "Poodle",
            pet_code = "a_c_poodle",
            price = 35000,
            img = "dog3.png"
        },
        [3] = {
            name = "Pug",
            pet_code = "a_c_pug",
            price = 27000,
            img = "dog4.png"
        },
        [4] = {
            name = "Retriever",
            pet_code = "a_c_retriever",
            price = 52000,
            img = "dog5.png"
        },
        [5] = {
            name = "Rottweiler",
            pet_code = "a_c_rottweiler",
            price = 60000,
            img = "dog6.png"
        },
        [6] = {
            name = "Shepherd",
            pet_code = "a_c_shepherd",
            price = 55000,
            img = "dog7.png"
        },
        [7] = {
            name = "Westy",
            pet_code = "a_c_westy",
            price = 33000,
            img = "dog8.png"
        },
        [8] = {
            name = "Bulldog",
            pet_code = "bulldog",
            price = 49000,
            img = "dog9.png"
        }
    },
    others = {
        [1] = {
            name = "Gato",
            pet_code = "a_c_cat_01",
            price = 15000,
            img = "cat.png"
        },
        [2] = {
            name = "Armadillo",
            pet_code = "armadillo",
            price = 65000,
            img = "armadillo.png"
        },
        [3] = {
            name = "Jabalí",
            pet_code = "a_c_boar",
            price = 95000,
            img = "boar.png"
        },
        [4] = {
            name = "Vaca",
            pet_code = "a_c_cow",
            price = 200000,
            img = "cow.png"
        },
        [5] = {
            name = "Coyote",
            pet_code = "a_c_coyote",
            price = 200000,
            img = "coyote.png"
        },
        [6] = {
            name = "Ciervo",
            pet_code = "a_c_deer",
            price = 190000,
            img = "deer.png"
        },
        [7] = {
            name = "Gallina",
            pet_code = "a_c_hen",
            price = 50000,
            img = "chicken.png"
        },
        [8] = {
            name = "Pantera",
            pet_code = "a_c_mtlion",
            price = 200000,
            img = "montainlion.png"
        },
        [9] = {
            name = "Cerdo",
            pet_code = "a_c_pig",
            price = 85000,
            img = "pig.png"
        },
        [10] = {
            name = "Conejo",
            pet_code = "a_c_rabbit_01",
            price = 65000,
            img = "rabbit.png"
        },
        [11] = {
            name = "Rata",
            pet_code = "a_c_rat",
            price = 45000,
            img = "rat.png"
        },
        [12] = {
            name = "Oso",
            pet_code = "bear",
            price = 300000,
            img = "bear.png"
        },
        [13] = {
            name = "Caballo",
            pet_code = "horse",
            price = 500000,
            img = "horse.png"
        },
        [14] = {
            name = "Cebra",
            pet_code = "zebra",
            price = 500000,
            img = "zebra.png"
        }
    }
}

-- Configuración de disminución de necesidades (en minutos)
Config.needsDecrease = {
    hunger = {
        min = 2, -- % mínimo que disminuye
        max = 5, -- % máximo que disminuye
        interval = 10 -- cada 10 minutos
    },
    thirst = {
        min = 2,
        max = 5,
        interval = 10
    },
    hygiene = {
        amount = 10, -- % que disminuye
        interval = 35 -- cada 35 minutos
    },
    affection = {
        amount = 5, -- % que disminuye
        interval = 60 -- cada 60 minutos
    },
    health = {
        amount = 1, -- % que disminuye si hambre o sed llegan a 0
        interval = 10 -- cada 10 minutos
    }
}

-- Umbrales para notificaciones de necesidades bajas
Config.lowNeedThresholds = {
    hunger = 30,
    thirst = 30,
    hygiene = 30,
    affection = 30,
    health = 5
}
