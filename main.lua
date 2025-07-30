-- name: Hide 'n Seek \\#7f7f7f\\[WIP]
--- incompatible: gamemode
-- pausable: false

-- waiting: 0 active: 1 seekers win: 2 hiders win: 3 unknown end: 4
np = gNetworkPlayers[0]
m = gMarioStates[0]
gGlobalSyncTable.roundState = 0
gGlobalSyncTable.displayTimer = 0
gGlobalSyncTable.touchTag = false
sRoundStartTimeout = 30 * 30
sRoundEndTimeout = 3 * 60 * 30
sLastRoundStartingSeekers = 0
sRoundTimer = 0
pauseExitTimer = 0
canLeave = false
sFlashingIndex = 0
cannonTimer = 0
fade = 255

local function on_or_off(value)
    if value then return "\\#00ffff\\Enabled" end
    return "\\#00ffff\\Disabled"
end

local function server_update()
    -- increment timer
    sRoundTimer = sRoundTimer + 1
    gGlobalSyncTable.displayTimer = math.floor(sRoundTimer / 30)

    -- figure out state of the game
    local hasSeeker = false
    local hasHider = false
    local connectedCount = 0
    for i=0,(MAX_PLAYERS-1) do
        if gNetworkPlayers[i].connected then
            connectedCount = connectedCount + 1
            if gPlayerSyncTable[i].seeking then
                hasSeeker = true
            else
                hasHider = true
            end
        end
    end

    -- only change state if there are 2 or more players
    if connectedCount < 2 then
        gGlobalSyncTable.roundState = 0
        return
    elseif gGlobalSyncTable.roundState == 0 then
        gGlobalSyncTable.roundState = 4
        sRoundTimer = 0
        gGlobalSyncTable.displayTimer = 0
    end

    -- check to see if the round should end
    if gGlobalSyncTable.roundState == 1 then
        if not hasHider or not hasSeeker or sRoundTimer > sRoundEndTimeout then
            if not hasHider then
                gGlobalSyncTable.roundState = 2
            elseif sRoundTimer > sRoundEndTimeout then
                gGlobalSyncTable.roundState = 3
            else
                gGlobalSyncTable.roundState = 4
            end
            sRoundTimer = 0
            gGlobalSyncTable.displayTimer = 0
        else
            return
        end
    end

    -- start round
    if sRoundTimer >= sRoundStartTimeout then
        -- reset seekers
        for i=0,(MAX_PLAYERS-1) do
            gPlayerSyncTable[i].seeking = false
        end
        hasSeeker = false

        -- pick random seeker and scale if there's more players
        local numStartingSeekers = connectedCount >> 2
        if numStartingSeekers == 0 then numStartingSeekers = 1 end

        local currRoundStartingSeekers = 0
        local startingSeekersProbabiltyArray = {}

        for i=0, (MAX_PLAYERS-1) do
            if i <= connectedCount-1 and (sLastRoundStartingSeekers & (1 << i)) == 0 then
                startingSeekersProbabiltyArray[i] = 200
            else
                startingSeekersProbabiltyArray[i] = 0
            end
        end
        
        for i2=0, numStartingSeekers-1 do
            local probabilityTotal = 0
            local probabilityTotalArray = {}

            for i3=0, (MAX_PLAYERS-1) do
                probabilityTotal = probabilityTotal + startingSeekersProbabiltyArray[i3]
                probabilityTotalArray[i3] = probabilityTotal
            end

            randomProbabilityTotal = math.random(0, probabilityTotal)

            for i4=0, (MAX_PLAYERS-1) do
                if randomProbabilityTotal < probabilityTotalArray[i4] then
                    gPlayerSyncTable[i4].seeking = true
                    currRoundStartingSeekers = currRoundStartingSeekers | (1 << i4)
                    startingSeekersProbabiltyArray[i4] = 0 -- make sure we dont select the same player twice
                    break
                end
            end
        end

        -- clear and dont set the last round seeker bits if there's only two players
        if connectedCount < 3 then
            sLastRoundStartingSeekers = 0
        else
            sLastRoundStartingSeekers = currRoundStartingSeekers
        end

        -- set round state
        gGlobalSyncTable.roundState = 1
        sRoundTimer = 0
        gGlobalSyncTable.displayTimer = 0
    end
end

local function update()
    pauseExitTimer = pauseExitTimer + 1

    if pauseExitTimer >= 900 and not canLeave then
        canLeave = true
    end
    if network_is_server() then
        server_update()
    end
end

local function screen_transition(trans)
    local s = gPlayerSyncTable[0]
    if not s.seeking then
        for i=1,(MAX_PLAYERS-1) do
            if gNetworkPlayers[i].connected and gNetworkPlayers[i].currLevelNum == np.currLevelNum and
                gNetworkPlayers[i].currActNum == np.currActNum and gNetworkPlayers[i].currAreaIndex == np.currAreaIndex
                and gPlayerSyncTable[i].seeking then

                local a = gMarioStates[i]

                if trans == WARP_TRANSITION_FADE_INTO_BOWSER or (m.floor.type == SURFACE_DEATH_PLANE and m.pos.y <= m.floorHeight + 2048) then
                    if dist_between_objects(m.marioObj, a.marioObj) <= 4000 and m.playerIndex == 0 then
                        s.seeking = true
                    end
                end
            end
        end
    end
end

--- @param m MarioState
local function mario_update(m)
    if (m.flags & MARIO_VANISH_CAP) ~= 0 then
        m.flags = m.flags & ~MARIO_VANISH_CAP
        stop_cap_music()
    end

  local s = gPlayerSyncTable[m.playerIndex]
  if m.playerIndex == 0 and m.action == ACT_IN_CANNON and m.actionState == 2 then
      cannonTimer = cannonTimer + 1
      if cannonTimer >= 90 then -- 90 is 3 seconds
          m.forwardVel = 100 * coss(m.faceAngle.x)

          m.vel.y = 100 * sins(m.faceAngle.x)

          m.pos.x = m.pos.x + 120 * coss(m.faceAngle.x) * sins(m.faceAngle.y)
          m.pos.y = m.pos.y + 120 * sins(m.faceAngle.x)
          m.pos.z = m.pos.z + 120 * coss(m.faceAngle.x) * coss(m.faceAngle.y)

          play_sound(SOUND_ACTION_FLYING_FAST, m.marioObj.header.gfx.cameraToObject)
          play_sound(SOUND_OBJ_POUNDING_CANNON, m.marioObj.header.gfx.cameraToObject)

          m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
          set_camera_mode(m.area.camera, m.area.camera.defMode, 1)

          set_mario_action(m, ACT_SHOT_FROM_CANNON, 0)
          queue_rumble_data_mario(m, 60, 70)
          m.usedObj.oAction = 2
          cannonTimer = 0
      end
  end

  if m.playerIndex == 0 and m.action == ACT_SHOT_FROM_CANNON then
      cannonTimer = 0
  end

    if m.playerIndex == 0 then
        if gPlayerSyncTable[m.playerIndex].seeking and gGlobalSyncTable.displayTimer == 0 and gGlobalSyncTable.roundState == 1 then
            warp_to_start_level()
        end
    end

    if s.seeking then
        m.marioBodyState.modelState = m.marioBodyState.modelState | MODEL_STATE_METAL
    end

    if m.playerIndex == 0 and (m.pos.x > 0x7FFF or m.pos.x < -0x8000 or m.pos.z > 0x7FFF or m.pos.z < -0x8000) then
        s.seeking = true
        warp_restart_level()
    end
end

--- @param levelNum LevelNum
local function in_vanilla_level(levelNum)
    return gNetworkPlayers[0].currLevelNum == levelNum and level_is_vanilla_level(levelNum)
end

---@param m MarioState
---@param action integer
local function before_set_mario_action(m, action)
    if m.playerIndex == 0 then
        if
            action == ACT_WAITING_FOR_DIALOG or
            action == ACT_READING_SIGN or
            action == ACT_READING_NPC_DIALOG or
            action == ACT_JUMBO_STAR_CUTSCENE or
            (action == ACT_READING_AUTOMATIC_DIALOG and get_id_from_behavior(m.interactObj.behavior) ~= id_bhvDoor and get_id_from_behavior(m.interactObj.behavior) ~= id_bhvStarDoor)
        then
            return 1
        elseif action == ACT_EXIT_LAND_SAVE_DIALOG then
            set_camera_mode(m.area.camera, m.area.camera.defMode, 1)
            return ACT_IDLE
        end
    end
end

--- @param m MarioState
local function before_phys_step(m)
    local s = gPlayerSyncTable[m.playerIndex]

    if m.action == ACT_BUBBLED or s.seeking then return end

    local hScale = 1.0
    local vScale = 1.0

    if (m.action & ACT_FLAG_SWIMMING) ~= 0 then
        hScale = hScale * 1.05
        if m.action ~= ACT_WATER_PLUNGE then
            vScale = vScale * 1.05
        end
    end
end

local function on_pvp_attack(attacker, victim)
    -- fix for hiders being caught during intermission
    if gGlobalSyncTable.roundState ~= 1 then
        return
    end

    -- this code runs when a player attacks another player
    local sAttacker = gPlayerSyncTable[attacker.playerIndex]
    local sVictim = gPlayerSyncTable[victim.playerIndex]

    -- only consider local player
    if victim.playerIndex ~= 0 then
        return
    end

    -- make victim a seeker
    if sAttacker.seeking and not sVictim.seeking then
        sVictim.seeking = true
    end
end

--- @param m MarioState
local function on_player_connected(m)
    local s = gPlayerSyncTable[m.playerIndex]
    s.seeking = true
    network_player_set_description(gNetworkPlayers[m.playerIndex], "Seeker", 255, 128, 128, 255)
end

local function on_player_disconnected(m)
    -- handle clearing of the last round beginning seekers bits when a player leaves
    if get_connected_count() < 3 then
        return
    end

    local np = gNetworkPlayers[m.playerIndex]
    sLastRoundStartingSeekers = sLastRoundStartingSeekers & ~(1 << np.globalIndex)
end

local function hud_top_render()
    local seconds = 0
    local text = ""

    if gGlobalSyncTable.roundState == 0 then
        seconds = 60
        text = "Waiting for Players..."
    elseif gGlobalSyncTable.roundState == 1 then
        seconds = math.floor(sRoundEndTimeout / 30 - gGlobalSyncTable.displayTimer)
        if seconds < 0 then seconds = 0 end
        text = "Time Remaining: " .. seconds .. "s"
    else
        seconds = math.floor(sRoundStartTimeout / 30 - gGlobalSyncTable.displayTimer)
        if seconds < 0 then seconds = 0 end
        text = "Starting in: " .. seconds .. "s"
    end

    local scale = 0.4

    local screenWidth = djui_hud_get_screen_width()
    local width = djui_hud_measure_text(text) * scale
    local height = 32 * scale

    local x = 12
    local y = 7

    local background = 0.0
    if seconds < 60 and gGlobalSyncTable.roundState == 1 then
        background = (math.sin(sFlashingIndex * 0.1) * 0.5 + 0.5) * 1
        background = background * background
        background = background * background
    end

    local flashIntensity = math.floor(255 * background)
    djui_hud_set_color(flashIntensity, 0, 0, fade / 1.4)
    djui_hud_render_rect_rounded_outlined(x - (12 * scale), y, width + (24 * scale), height, flashIntensity, 0, 0, 2.8, fade / 1.4)

    djui_hud_set_color(220, 220, 220, fade)
    djui_hud_print_colored_text(text, x, y, scale, fade)
end

local function hud_center_render()
    if gGlobalSyncTable.displayTimer > 3 then return end
    local text = ""
    if gGlobalSyncTable.roundState == 2 then
        text = "Seekers Win!"
    elseif gGlobalSyncTable.roundState == 3 then
        text = "Hiders Win!"
    elseif gGlobalSyncTable.roundState == 1 then
        text = "Go!"
    else
        return
    end

    local scale = 1

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local width = djui_hud_measure_text(text) * scale 
    local height = 32 * scale

    local x = (screenWidth - width) * 0.5
    local y = (screenHeight - height) * 0.5

    djui_hud_set_color(0, 0, 0, fade / 1.4)
    djui_hud_render_rect_rounded_outlined(x - (6 * scale), y, width + (12 * scale), height, 0, 0, 0, 3.5, fade / 1.4) 

    djui_hud_set_color(220, 220, 220, fade)
    djui_hud_print_colored_text(text, x, y, scale, fade)
end

--- @type MarioState
local function on_hud_render()
    djui_hud_set_resolution(1)
    djui_hud_set_font(0)

    hud_top_render()
    hud_center_render()

    sFlashingIndex = sFlashingIndex + 1

    if gLakituState.pos.y < m.waterLevel then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        if in_vanilla_level(LEVEL_JRB) then
            djui_hud_set_color(0, 100, 130, 100)
        elseif in_vanilla_level(LEVEL_LLL) then
            djui_hud_set_color(255, 20, 0, 175)
        else
            djui_hud_set_color(0, 50, 230, 100)
        end
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    elseif gLakituState.pos.y < find_poison_gas_level(m.pos.x, m.pos.z) then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        djui_hud_set_color(150, 200, 0, 100)
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    end
end

local function on_touch_tag_command()
    gGlobalSyncTable.touchTag = not gGlobalSyncTable.touchTag
    djui_chat_message_create("Touch tag: " .. on_or_off(gGlobalSyncTable.touchTag))
    return true
end

local function on_finish_command(msg)
    msg = string.lower(msg)
    if msg == "end" then
      sRoundTimer = sRoundEndTimeout
      network_send(true, {packet = "ON_END", message = (gNetworkPlayers[0].name) .. "\\#fff200\\ ended the round."})
      packet_receive({packet = "ON_END", message = (gNetworkPlayers[0].name) .. "\\#fff200\\ ended the round."})
      end
      return true
  end

local function level_init()
    local s = gPlayerSyncTable[0]

    pauseExitTimer = 0
    canLeave = false

    if s.seeking then canLeave = true end
end

local function on_pause_exit()
    local s = gPlayerSyncTable[0]

    if not canLeave and not s.seeking then
        djui_chat_message_create("\\#00ffff\\(" .. tostring(math.floor(30 - pauseExitTimer / 30)).."s) \\#ffffff\\Wait until you can leave!")
        return false
    end
end

function packet_receive(data)
    if data.packet == "ON_END" then
     djui_chat_message_create("[GAME]: " ..data.message)
     play_puzzle_jingle()
   end
end

function get_connected_count()
    local result = 0

    for i=0,(MAX_PLAYERS-1) do
        if gNetworkPlayers[i].connected then
            result = result + 1
        end
    end

    return result
end

local function on_round_state_changed()
    local rs = gGlobalSyncTable.roundState

    if rs == 1 then
        play_character_sound(m, CHAR_SOUND_HERE_WE_GO)
    elseif rs == 2 then
        play_sound(SOUND_MENU_CLICK_CHANGE_VIEW, m.marioObj.header.gfx.cameraToObject)
    elseif rs == 3 then
        play_sound(SOUND_MENU_CLICK_CHANGE_VIEW, m.marioObj.header.gfx.cameraToObject)
    end
end

local function on_seeking_changed(tag, oldVal, newVal)
    local m = gMarioStates[tag]
    local npT = gNetworkPlayers[tag]

    if newVal and not oldVal then
        play_sound(SOUND_OBJ_BOWSER_LAUGH, m.marioObj.header.gfx.cameraToObject)
        playerColor = network_get_player_text_color_string(m.playerIndex)
        djui_popup_create(playerColor .. npT.name .. "\\#ffa0a0\\ is now a seeker", 1)
        sRoundTimer = 32
    end

    if newVal then
        network_player_set_description(npT, "Seeker", 255, 128, 128, 255)
    else
        network_player_set_description(npT, "Hider", 128, 128, 255, 255)
    end
end

local function check_touch_tag_allowed(i)
    if gMarioStates[i].action ~= ACT_TELEPORT_FADE_IN and gMarioStates[i].action ~= ACT_TELEPORT_FADE_OUT and gMarioStates[i].action ~= ACT_PULLING_DOOR and gMarioStates[i].action ~= ACT_PUSHING_DOOR and gMarioStates[i].action ~= ACT_WARP_DOOR_SPAWN and gMarioStates[i].action ~= ACT_ENTERING_STAR_DOOR and gMarioStates[i].action ~= ACT_STAR_DANCE_EXIT and gMarioStates[i].action ~= ACT_STAR_DANCE_NO_EXIT and gMarioStates[i].action ~= ACT_STAR_DANCE_WATER and gMarioStates[i].action ~= ACT_PANTING and gMarioStates[i].action ~= ACT_UNINITIALIZED and gMarioStates[i].action ~= ACT_WARP_DOOR_SPAWN then
        return true
    end

    return false
end

local function on_interact(m, obj, intee)
    if intee == INTERACT_PLAYER then

        if not gGlobalSyncTable.touchTag then
            return
        end

        if m ~= gMarioStates[0] then
            for i=0,(MAX_PLAYERS-1) do
                if gNetworkPlayers[i].connected and gNetworkPlayers[i].currAreaSyncValid then
                    if gPlayerSyncTable[m.playerIndex].seeking and not gPlayerSyncTable[i].seeking and obj == gMarioStates[i].marioObj and check_touch_tag_allowed(i)  then
                        gPlayerSyncTable[i].seeking = true

                        network_player_set_description(gNetworkPlayers[i], "Seeker", 255, 128, 128, 255)
                    end
                end
            end
        end
    end
end

local function on_allow_interact(m, o, intType)
    if (intType & INTERACT_KOOPA_SHELL) ~= 0 then
        return false
    end

    return true
end

function allow_pvp_attack(attacker, victim)
    local sAttacker = gPlayerSyncTable[attacker.playerIndex]
    local sVictim = gPlayerSyncTable[victim.playerIndex]

    if (sAttacker.seeking and sVictim.seeking) or (not sAttacker.seeking and not sVictim.seeking) then
        return false
    end

    return true    
end

--- @param m MarioState
local function infinite_lives_update(m)
    m.numLives = 100
end

gServerSettings.bubbleDeath = 0
gLevelValues.disableActs = true

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_SCREEN_TRANSITION, screen_transition)
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)
hook_event(HOOK_ALLOW_PVP_ATTACK, allow_pvp_attack)
hook_event(HOOK_ON_PVP_ATTACK, on_pvp_attack)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_PLAYER_DISCONNECTED, on_player_disconnected)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_LEVEL_INIT, level_init)
hook_event(HOOK_ON_PAUSE_EXIT, on_pause_exit)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ALLOW_INTERACT, on_allow_interact)
hook_event(HOOK_USE_ACT_SELECT, function () return false end)
hook_event(HOOK_MARIO_UPDATE, infinite_lives_update)
hook_event(HOOK_ON_PACKET_RECEIVE, packet_receive)

if network_is_server() then
   hook_chat_command("ttt", "- Toggles touch tag on or off.", on_touch_tag_command)
   hook_chat_command("r", "\\#00ffff\\[end]\\#ffffff\\ - Defines the round state.", on_finish_command)
end

hook_on_sync_table_change(gGlobalSyncTable, "roundState", 0, on_round_state_changed)

for i = 0, (MAX_PLAYERS - 1) do
    gPlayerSyncTable[i].seeking = true
    hook_on_sync_table_change(gPlayerSyncTable[i], "seeking", i, on_seeking_changed)
    network_player_set_description(gNetworkPlayers[i], "Seeker", 255, 128, 128, 255)
end

-- WBmarioo is allowed to host this btw