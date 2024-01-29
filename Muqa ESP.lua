util.require_natives(1651208000)
util.keep_running()

local wait = util.yield()
local function getLocalPed()
    return PLAYER.PLAYER_PED_ID()
end
local getEntityCoords = ENTITY.GET_ENTITY_COORDS
local menuroot = menu.my_root()



function GetPlayerName_ped(ped)
    local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)
    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(playerID)
    return playerName
end
function GetPlayerName_pid(pid)
    local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(pid)
    return playerName
end

local function drawLine(c1, c2, r, g, b, a)
    GRAPHICS.DRAW_LINE(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, r, g, b, a)
end

local function worldToScreen(coords)
    local sx = memory.alloc()
    local sy = memory.alloc()
    local success = GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(coords.x, coords.y, coords.z, sx, sy)
    local screenx = memory.read_float(sx) local screeny = memory.read_float(sy) --memory.free(sx) memory.free(sy)
    return {x = screenx, y = screeny, success = success}
end

local whiteColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

local colors = {
    red = {255, 0, 0},
    orange = {255, 127, 0},
    yellow = {255, 255, 0},
    green = {0, 255, 0},
    blue = {0, 0, 255},
    purple = {148, 0, 211}
}

local colorProximities = {
    {"Red", 200*200, 255, 0, 0},
    {"Orange", 400*400, 255, 127, 0},
    {"Yellow", 600*600, 255, 255, 0},
    {"Green", 800*800, 0, 255, 0},
    {"Blue", 1000*1000, 0, 0, 255},
    {"Purple", 1200*1200, 148, 0, 211},
}

local components = {
    line = false,
    box = true,
    txtscale = 0.5,
    name = true,
    healthbar = true,
    healtText = true,
    weaponName = true,
}

local bones = {
    leftFoot = 14201,
    rightFoot = 52301,

    rightHand = 57005,
    leftHand = 18905,

    leftForearm = 61163,
    rightForearm = 28252,

    head = 31086,
}

local function DrawOutlinedRect(x,y,x1,y1,color)
    directx.draw_line(x, y, x1, y, color) -- top
    directx.draw_line(x, y, x, y1, color) -- left
    directx.draw_line(x1, y, x1, y1, color) -- right
    directx.draw_line(x, y1, x1, y1, color) -- bottom
end

local weapons = util.get_weapons()
local weaponHash = memory.alloc_int()
local function getWeaponName(ped)
    WEAPON.GET_CURRENT_PED_WEAPON(ped, weaponHash, true)
    local readWeaponHash = memory.read_int(weaponHash)
    local weaponName
    for _, wep in weapons do
        if wep.hash == readWeaponHash then
            weaponName = util.get_label_text(wep.label_key)
            break
        end
    end
    return weaponName
end

menu.toggle_loop(menuroot, "Enable ESP", {"muqaesp"}, "Enables the ESP", function ()
    local playerlist = players.list(false, true, true)
    for i = 1, #playerlist do

        local targetped = PLAYER.GET_PLAYER_PED(playerlist[i])

        local health = ENTITY.GET_ENTITY_HEALTH(targetped)-100 -- this would be near maxhealth but i dont want to do all of this processing if the player is dead

        if health <= 0 then 
            goto continue
        end

        local topOfHead = PED.GET_PED_BONE_COORDS(targetped, bones.head, 0, 0, 0); topOfHead.z = topOfHead.z + 0.2
        local bottomOfFeet = PED.GET_PED_BONE_COORDS(targetped, bones.head, 0, 0, 0); bottomOfFeet.z = topOfHead.z - 1.94

        local leftFoot = PED.GET_PED_BONE_COORDS(targetped, bones.leftFoot, 0, 0, 0); leftFoot.z = leftFoot.z - 0.1
        local rightFoot = PED.GET_PED_BONE_COORDS(targetped, bones.rightFoot, 0, 0, 0); rightFoot.z = rightFoot.z - 0.1

        local rightHand = PED.GET_PED_BONE_COORDS(targetped, bones.rightHand, 0, 0, 0)
        local leftHand = PED.GET_PED_BONE_COORDS(targetped, bones.leftHand, 0, 0, 0)

        local rightForearm = PED.GET_PED_BONE_COORDS(targetped, bones.rightForearm, 0, 0, 0)
        local leftForearm = PED.GET_PED_BONE_COORDS(targetped, bones.leftForearm, 0, 0, 0)

        local w2sHead = worldToScreen(topOfHead)
        local w2sFeet = worldToScreen(bottomOfFeet)

        local w2sLfoot = worldToScreen(leftFoot)
        local w2sRfoot = worldToScreen(rightFoot)

        local w2sRhand = worldToScreen(rightHand)
        local w2sLhand = worldToScreen(leftHand)

        local w2sRforearm = worldToScreen(rightForearm)
        local w2sLforearm = worldToScreen(leftForearm)
 
        --------------------------
        if w2sHead.success and w2sFeet.success and w2sLfoot.success and w2sRfoot.success then -- only draw if the player is within our screen

            local x_max = math.max(w2sHead.x, w2sLfoot.x, w2sRfoot.x, w2sRhand.x, w2sLhand.x, w2sRforearm.x, w2sLforearm.x)
            local x_min = math.min(w2sHead.x, w2sLfoot.x, w2sRfoot.x, w2sRhand.x, w2sLhand.x, w2sRforearm.x, w2sLforearm.x)
            local y_max = math.max(w2sHead.y, w2sLfoot.y, w2sRfoot.y, w2sRhand.y, w2sLhand.y, w2sRforearm.y, w2sLforearm.y)
            local y_min = math.min(w2sHead.y, w2sLfoot.y, w2sRfoot.y, w2sRhand.y, w2sLhand.y, w2sRforearm.y, w2sLforearm.y)
            
            local x = x_min
            local y = y_min
            local w = x_max - x_min
            local h = y_max - y_min

            local playerName = NETWORK.NETWORK_PLAYER_GET_NAME(playerlist[i])
            local maxhealth = ENTITY.GET_ENTITY_MAX_HEALTH(targetped)-100
    
            local color = {r = 1.0, g = 0.0, b = 1.0, a = 1.0}
    
            if components.box then
                DrawOutlinedRect( x, y, x + w, y + h, color)
            end
    
            if components.line then 
                directx.draw_line( 0.5, 1.0, x+w*0.5, y+h, color)
            end

            if components.healthbar then 
                local healthBarSize = h * (health / maxhealth)

                directx.draw_rect( x-0.002, y, -0.002, h, {r = 0.0, g = 1.0, b = 0.0, a = 1.0})
                directx.draw_rect( x-0.002, y, -0.002, h-healthBarSize, {r = 0.0, g = 0.0, b = 0.0, a = 1.0})
            end

            if components.healthText then
                directx.draw_text(x-0.006, y, math.floor((health / maxhealth) * 100), ALIGN_TOP_RIGHT, 0.4, {r = 0.0, g = 1.0, b = 0.0, a = 1.0}, true)
            end

            if components.name then 
                directx.draw_text(x+w*0.5, y - 0.002, playerName, ALIGN_BOTTOM_CENTRE, 0.4, {r = 1.0, g = 1.0, b = 1.0, a = 1.0}, true)
            end

            if components.weaponName then 
                local name = getWeaponName(targetped)
                if not name then name = "" end
                directx.draw_text(x+w*0.5, y+h+0.002, name, ALIGN_TOP_CENTRE, 0.4, {r = 1.0, g = 1.0, b = 1.0, a = 1.0}, true)
            end

            --directx.draw_text(w2sLfoot.x, w2sLfoot.y, "O", ALIGN_TOP_CENTRE, 0.4, {r = 1.0, g = 1.0, b = 1.0, a = 1.0}, true)
            --directx.draw_text(w2sRfoot.x, w2sRfoot.y, "O", ALIGN_TOP_CENTRE, 0.4, {r = 1.0, g = 0.0, b = 1.0, a = 1.0}, true)
            --DrawOutlinedRect( x_min, y_min, x_max, y_max, color)

        end
        ::continue::
    end
end)

local espComponents = menu.list(menuroot, "ESP Components/Enabled", {"Muqa ESP Enabled"}, "What elements you want the ESP to display.")

menu.toggle(espComponents, "Box ESP", {"muqaespbox"}, "Draws a box around the player.", function (toggle)
    components.box = toggle
end, true)

menu.toggle(espComponents, "Line ESP", {"muqaespline"}, "Draws a line to the players feet.", function (toggle)
    components.line = toggle
end, false)

menu.toggle(espComponents, "Healthbar", {"muqaesphealthbar"}, "Draws a healthbar.", function (toggle)
    components.healthbar = toggle
end, true)

menu.toggle(espComponents, "Health Text", {"muqaesphealthtext"}, "Draws the players health next to the healthbar.", function (toggle)
    components.healthText = toggle
end, false)

menu.toggle(espComponents, "Name ESP", {"muqaespname"}, "Draws the players name.", function (toggle)
    components.name = toggle
end, true)

menu.toggle(espComponents, "Weapon ESP", {"muqaespname"}, "Draws the players current weapon name.", function (toggle)
    components.weaponName = toggle
end, true)