--[[

    script made by Muqa (discord: muqa | github: https://github.com/Muqa1)

    credits to https://github.com/Keramis/Cat_ESP_STANDAPI and https://gitlab.com/undefinedscripts/undefined-for-stand/-/blob/main/Undefined.lua for some functions

]]
local __luapack_arg__ = arg

util.require_natives(1651208000)
util.keep_running()
local menuroot = menu.my_root()

--== tables ==--
local components = { -- name is components but its actually my overall cfg
    localplayer = false,
    line = false,
    box = true,
    txtscale = 0.4,
    name = true,
    tags = true,
    healthbar = true,
    healtText = true,
    weaponName = true,
    distance = true,
    maxDistance = 10000,
    sRd = 300, -- simplified rendering distance
}
local colors = {
    box = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
    line = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
    name = {r = 0.0, g = 1.0, b = 1.0, a = 1.0},
    weapon = {r = 1.0, g = 1.0, b = 0.0, a = 1.0},
    distance = {r = 0.5, g = 0.5, b = 0.5, a = 1.0},
}
local bones = {
    leftFoot = 14201,
    rightFoot = 52301,

    rightHand = 57005,
    leftHand = 18905,

    leftForearm = 61163,
    rightForearm = 28252,

    pelvis = 11816,

    head = 31086,
}
--== tables ==--

--== functions ==--
local function worldToScreen(coords)
    local sx = memory.alloc()
    local sy = memory.alloc()
    local success = GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(coords.x, coords.y, coords.z, sx, sy)
    local screenx = memory.read_float(sx) local screeny = memory.read_float(sy) --memory.free(sx) memory.free(sy)
    return {x = screenx, y = screeny, success = success}
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
--== functions ==--

--== script loop ==--
menu.toggle_loop(menuroot, "Enable ESP", {"muqaesp"}, "Enables the ESP", function ()
    local playerlist = players.list_except(not components.localplayer)
    local lPlayer = players.user()
    for i = 1, #playerlist do

        local targetped = PLAYER.GET_PLAYER_PED(playerlist[i])
        local dist = math.floor(v3.distance(players.get_position(lPlayer), players.get_position(playerlist[i])))
        local health = ENTITY.GET_ENTITY_HEALTH(targetped)-100

        if (health <= 0) or (dist > components.maxDistance) then
            goto continue
        end

        if not (dist > components.sRd) then 
            local head = PED.GET_PED_BONE_COORDS(targetped, bones.head, 0, 0, 0); head.z = head.z + 0.2
            local w2sHead = worldToScreen(head)

            local w2sPelvis = worldToScreen(PED.GET_PED_BONE_COORDS(targetped, bones.pelvis, 0, 0, 0))

            local leftFoot = PED.GET_PED_BONE_COORDS(targetped, bones.leftFoot, 0, 0, 0); leftFoot.z = leftFoot.z - 0.1
            local w2sLfoot = worldToScreen(leftFoot)
            local rightFoot = PED.GET_PED_BONE_COORDS(targetped, bones.rightFoot, 0, 0, 0); rightFoot.z = rightFoot.z - 0.1
            local w2sRfoot = worldToScreen(rightFoot)

            local w2sRhand = worldToScreen(PED.GET_PED_BONE_COORDS(targetped, bones.rightHand, 0, 0, 0))
            local w2sLhand = worldToScreen(PED.GET_PED_BONE_COORDS(targetped, bones.leftHand, 0, 0, 0))

            local w2sRforearm = worldToScreen(PED.GET_PED_BONE_COORDS(targetped, bones.rightForearm, 0, 0, 0))
            local w2sLforearm = worldToScreen(PED.GET_PED_BONE_COORDS(targetped, bones.leftForearm, 0, 0, 0))

            --------------------------
            if w2sHead.success and w2sLfoot.success and w2sRfoot.success then -- only draw if the player is within our screen

                local x_max = math.max(w2sHead.x, w2sPelvis.x, w2sLfoot.x, w2sRfoot.x, w2sRhand.x, w2sLhand.x, w2sRforearm.x, w2sLforearm.x)
                local x_min = math.min(w2sHead.x, w2sPelvis.x, w2sLfoot.x, w2sRfoot.x, w2sRhand.x, w2sLhand.x, w2sRforearm.x, w2sLforearm.x)
                local y_max = math.max(w2sHead.y, w2sPelvis.y, w2sLfoot.y, w2sRfoot.y, w2sRhand.y, w2sLhand.y, w2sRforearm.y, w2sLforearm.y)
                local y_min = math.min(w2sHead.y, w2sPelvis.y, w2sLfoot.y, w2sRfoot.y, w2sRhand.y, w2sLhand.y, w2sRforearm.y, w2sLforearm.y)

                local x, y, w, h = x_min, y_min, x_max - x_min, y_max - y_min

                local maxhealth = ENTITY.GET_ENTITY_MAX_HEALTH(targetped)-100
                local top_offset, bottom_offset = 0.0, 0.0
    
                if components.box then
                    directx.draw_line(x, y, x + w, y, colors.box) -- top
                    directx.draw_line(x, y, x, y + h, colors.box) -- left
                    directx.draw_line(x + w, y, x + w, y + h, colors.box) -- right
                    directx.draw_line(x, y + h, x + w, y + h, colors.box) -- bottom
                end
    
                if components.line then 
                    directx.draw_line( 0.5, 1.0, x+w*0.5, y+h, colors.line)
                end

                if components.healthbar then 
                    local ratio = health / maxhealth
                    directx.draw_rect( x-0.002, y, -0.002, h, {r = 1.0 - (1.0 * ratio), g = (1.0 * ratio), b = 0.0, a = 1.0})
                    directx.draw_rect( x-0.002, y, -0.002, h - (h * (health / maxhealth)), {r = 0.0, g = 0.0, b = 0.0, a = 1.0})
                end

                if components.healthText then
                    directx.draw_text(x-0.006, y, math.floor((health / maxhealth) * 100), ALIGN_TOP_RIGHT, components.txtscale, {r = 0.0, g = 1.0, b = 0.0, a = 1.0}, true)
                end

                if components.name then 
                    local name = players.get_name(playerlist[i])
                    directx.draw_text(x+w*0.5, y - 0.002, name, ALIGN_BOTTOM_CENTRE, components.txtscale, colors.name, true)
                    local width, height = directx.get_text_size(name, components.txtscale)
                    top_offset = top_offset + height
                end

                if components.tags then 
                    directx.draw_text(x+w*0.5, y-top_offset - 0.002, players.get_tags_string(playerlist[i]), ALIGN_BOTTOM_CENTRE, components.txtscale, colors.name, true)
                end

                if components.weaponName then 
                    local name = getWeaponName(targetped)
                    if name then
                        directx.draw_text(x+w*0.5, y+h+0.002, name, ALIGN_TOP_CENTRE, components.txtscale, colors.weapon, true)
                        local width, height = directx.get_text_size(name, components.txtscale)
                        bottom_offset = bottom_offset + height
                    end
                end

                if components.distance then 
                    directx.draw_text(x+w*0.5, y+h+bottom_offset+0.002, dist.. "m", ALIGN_TOP_CENTRE, components.txtscale, colors.distance, true)
                end
            end
        else 
            local w2sPos = worldToScreen(players.get_position(playerlist[i]))
            if w2sPos.success then 
                local top_offset, bottom_offset = 0.0, 0.0
                local x, y = w2sPos.x, w2sPos.y
            
                if components.name then 
                    local name = players.get_name(playerlist[i])
                    directx.draw_text(x, y, name, ALIGN_BOTTOM_CENTRE, components.txtscale, colors.name, true)
                    local width, height = directx.get_text_size(name, components.txtscale)
                    top_offset = top_offset + height
                end

                if components.tags then 
                    directx.draw_text(x, y - top_offset - 0.002, players.get_tags_string(playerlist[i]), ALIGN_BOTTOM_CENTRE, components.txtscale, colors.name, true)
                end

                if components.weaponName then 
                    local name = getWeaponName(targetped)
                    if name then
                        directx.draw_text(x, y+0.002, name, ALIGN_TOP_CENTRE, components.txtscale, colors.weapon, true)
                        local width, height = directx.get_text_size(name, components.txtscale)
                        bottom_offset = bottom_offset + height
                    end
                end

                if components.distance then 
                    directx.draw_text(x, y+bottom_offset+0.002, dist.. "m", ALIGN_TOP_CENTRE, components.txtscale, colors.distance, true)
                end

                if components.line then 
                    directx.draw_line( 0.5, 1.0, x, y, colors.line)
                end
            end
        end
        ::continue::
    end
end)
--== script loop ==--

--== menu elements ==--
local espComponents = menu.list(menuroot, "ESP Components", {"muqaesplist"}, "What elements you want the ESP to display.")

menu.toggle(espComponents, "Box ESP", {"muqaespbox"}, "Draws a box around the player.", function (toggle)
    components.box = toggle
end, components.box)

menu.toggle(espComponents, "Line ESP", {"muqaespline"}, "Draws a line to the players feet.", function (toggle)
    components.line = toggle
end, components.line)

menu.toggle(espComponents, "Healthbar", {"muqaesphealthbar"}, "Draws a healthbar.", function (toggle)
    components.healthbar = toggle
end, components.healthbar)

menu.toggle(espComponents, "Health Text", {"muqaesphealthtext"}, "Draws the players health next to the healthbar.", function (toggle)
    components.healthText = toggle
end, components.healthText)

menu.toggle(espComponents, "Name ESP", {"muqaespname"}, "Draws the players name.", function (toggle)
    components.name = toggle
end, components.name)

menu.toggle(espComponents, "Show Tags", {"muqaesptags"}, "Draws the players tags above their name.", function (toggle)
    components.tags = toggle
end, components.tags)

menu.toggle(espComponents, "Weapon ESP", {"muqaespname"}, "Draws the players current weapon name.", function (toggle)
    components.weaponName = toggle
end, components.weaponName)

menu.toggle(espComponents, "Distance ESP", {"muqaespdist"}, "Draws the players distance from you under the weapon name.", function (toggle)
    components.distance = toggle
end, components.distance)
------------------------
local espSetts = menu.list(menuroot, "ESP Settings", {"muqaespsettings"}, "Change the esp settings (mostly colors).")

local function RGB(x)
    return math.floor(255 * x)
end

menu.toggle(espSetts, "Draw Localplayer", {"muqaespbox"}, "Should the localplayer aka you be drawn aswell.", function (toggle)
    components.localplayer = toggle
end, components.localplayer)

menu.slider(espSetts, "Max Distance", {"muqaespboxmaxdst"}, "The maximum distance at which the player will be rendered.", 0, 10000, components.maxDistance, 1, function(value)
    components.maxDistance = value
end)

menu.slider(espSetts, "Simplified Rendering Distance", {"muqaespboxmaxsrd"}, "Past this distance the player bounding box wont be calculated since u cant see the box anyway.", 0, 10000, components.sRd, 1, function(value)
    components.sRd = value
end)

menu.slider(espSetts, "Text Scale", {"muqaespboxtxtscale"}, "Change the ESP text size.", 0, 100, components.txtscale * 100, 1, function(value)
    components.txtscale = (value / 100)
end)

local boxColor = menu.list(espSetts, "Box Color", {"muqaespsettingsbox"}, "Change the box color.")
menu.slider(boxColor, "R", {"muqaespboxcolorr"}, "", 0, 255, RGB(colors.box.r), 1, function(value)
    colors.box.r = (value / 255)
end)
menu.slider(boxColor, "G", {"muqaespboxcolorg"}, "", 0, 255, RGB(colors.box.g), 1, function(value)
    colors.box.g = (value / 255)
end)
menu.slider(boxColor, "B", {"muqaespboxcolorb"}, "", 0, 255, RGB(colors.box.b), 1, function(value)
    colors.box.b = (value / 255)
end)
menu.slider(boxColor, "A", {"muqaespboxcolora"}, "", 0, 255, RGB(colors.box.a), 1, function(value)
    colors.box.a = (value / 255)
end)

local lineColor = menu.list(espSetts, "Line Color", {"muqaespsettingsline"}, "Change the line color.")
menu.slider(lineColor, "R", {"muqaesplinecolorr"}, "", 0, 255, RGB(colors.line.r), 1, function(value)
    colors.line.r = (value / 255)
end)
menu.slider(lineColor, "G", {"muqaesplinecolorg"}, "", 0, 255, RGB(colors.line.g), 1, function(value)
    colors.line.g = (value / 255)
end)
menu.slider(lineColor, "B", {"muqaesplinecolorb"}, "", 0, 255, RGB(colors.line.b), 1, function(value)
    colors.line.b = (value / 255)
end)
menu.slider(lineColor, "A", {"muqaesplinecolora"}, "", 0, 255, RGB(colors.line.a), 1, function(value)
    colors.line.a = (value / 255)
end)

local nameColor = menu.list(espSetts, "Name Color", {"muqaespsettingsname"}, "Change the name color.")
menu.slider(nameColor, "R", {"muqaespnamecolorr"}, "", 0, 255, RGB(colors.name.r), 1, function(value)
    colors.name.r = (value / 255)
end)
menu.slider(nameColor, "G", {"muqaespnamecolorg"}, "", 0, 255, RGB(colors.name.g), 1, function(value)
    colors.name.g = (value / 255)
end)
menu.slider(nameColor, "B", {"muqaespnamecolorb"}, "", 0, 255, RGB(colors.name.b), 1, function(value)
    colors.name.b = (value / 255)
end)
menu.slider(nameColor, "A", {"muqaespnamecolora"}, "", 0, 255, RGB(colors.name.a), 1, function(value)
    colors.name.a = (value / 255)
end)

local weaponColor = menu.list(espSetts, "Weapon Color", {"muqaespsettingsweapon"}, "Change the weapon color.")
menu.slider(weaponColor, "R", {"muqaespweaponcolorr"}, "", 0, 255, RGB(colors.weapon.r), 1, function(value)
    colors.weapon.r = (value / 255)
end)
menu.slider(weaponColor, "G", {"muqaespweaponcolorg"}, "", 0, 255, RGB(colors.weapon.g), 1, function(value)
    colors.weapon.g = (value / 255)
end)
menu.slider(weaponColor, "B", {"muqaespweaponcolorb"}, "", 0, 255, RGB(colors.weapon.b), 1, function(value)
    colors.weapon.b = (value / 255)
end)
menu.slider(weaponColor, "A", {"muqaespweaponcolora"}, "", 0, 255, RGB(colors.weapon.a), 1, function(value)
    colors.weapon.a = (value / 255)
end)

local distColor = menu.list(espSetts, "Distance Color", {"muqaespsettingsdist"}, "Change the distance color.")
menu.slider(distColor, "R", {"muqaespdistcolorr"}, "", 0, 255, RGB(colors.distance.r), 1, function(value)
    colors.distance.r = (value / 255)
end)
menu.slider(distColor, "G", {"muqaespdistcolorg"}, "", 0, 255, RGB(colors.distance.g), 1, function(value)
    colors.distance.g = (value / 255)
end)
menu.slider(distColor, "B", {"muqaespdistcolorb"}, "", 0, 255, RGB(colors.distance.b), 1, function(value)
    colors.distance.b = (value / 255)
end)
menu.slider(distColor, "A", {"muqaespdistcolora"}, "", 0, 255, RGB(colors.distance.a), 1, function(value)
    colors.distance.a = (value / 255)
end)
--== menu elements ==--
