charSelectOn = 0
custom_hud = true

for mod in pairs(gActiveMods) do
    if _G.charSelectExists then
		charSelectOn = 1
    end
end

function render_custom_star_icon(x, y, scaleW, scaleH)
    if charSelectOn == 1 then
        local starIcon = _G.charSelect.character_get_current_table().starIcon

        if starIcon == nil then
            djui_hud_render_texture(gTextures.star, x, y, scaleW, scaleH)
        else
            djui_hud_render_texture(starIcon, x, y, scaleW * 16/starIcon.width, scaleH * 16/starIcon.height)
        end
    else
        djui_hud_render_texture(gTextures.star, x, y, scaleW, scaleH)
    end
end

function render_coins_segment(x, y, scaleW, scaleH)
    coins = tostring(string.format(hud_get_value(HUD_DISPLAY_COINS))):gsub("-", "M")

    if gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE_GROUNDS and gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE_COURTYARD and gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE then
        djui_hud_render_texture(gTextures.coin, 2, 39, 0.7, 0.7)
        djui_hud_print_text(coins, 15, 39, 0.7)
    end
end

function on_hud_render_behind()
    if not custom_hud then return end

    hud_hide()
    if obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil then return end
    if gNetworkPlayers[0].currActNum == 99 then return end
    djui_hud_set_resolution(RESOLUTION_N64)
    screenWidth = djui_hud_get_screen_width()
    screenHeight = djui_hud_get_screen_height()
    halfScreenWidth = djui_hud_get_screen_width() / 2
    halfScreenHeight = djui_hud_get_screen_height() / 2
    djui_hud_set_font(FONT_HUD)

    if custom_hud then
        render_coins_segment(15, 39, 0.7, 0.7)
        render_custom_star_icon(2, 25, 0.7, 0.7)
        render_power_meter(screenWidth - 64, 0, 64, 64)
        render_timer(hud_get_value(HUD_DISPLAY_TIMER), halfScreenWidth - 47, screenHeight * 0.85)

        if gMarioStates[0].numStars < 100 then
            if gMarioStates[0].numStars < 10 then
                djui_hud_print_text(tostring(gMarioStates[0].numStars), 15, 25, 0.7) 
            else
                djui_hud_print_text(tostring(gMarioStates[0].numStars), 15, 25, 0.7)
            end
        else
            djui_hud_print_text(tostring(gMarioStates[0].numStars), 15, 25, 0.7)
        end
   end
end

function render_power_meter(x, y, scaleW, scaleH)
    local health = math.ceil(gMarioStates[0].health / 256) - 1
    djui_hud_set_color(255, 255, 255, 255)
    hud_render_power_meter(gMarioStates[0].health, x, y, scaleW, scaleH)
end

function render_timer(timer, x, y)
    djui_hud_set_color(255, 255, 255, 255)

    if hud_get_value(HUD_DISPLAY_TIMER) > 0 then
djui_hud_print_text(convert_time(hud_get_value(HUD_DISPLAY_TIMER)), djui_hud_get_screen_width() - 0.7 * 77, djui_hud_get_screen_height() - 0.7 * 18, 0.7)
djui_hud_print_text("'", djui_hud_get_screen_width() - 0.7 * 64, djui_hud_get_screen_height() - 0.7 * 25, 0.7)
djui_hud_print_text("\"", djui_hud_get_screen_width() - 0.7 * 29, djui_hud_get_screen_height() - 0.7 * 25, 0.7)
    end
end

function convert_time(time)
    minutes = math.floor(time / 30 / 60 % 60)
    seconds = math.floor(time / 30 % 60)
    centiseconds = math.floor(time / 30 % 1 * 10)

    if seconds < 10 then
        seconds = "0" .. tostring(seconds)
    end
    return minutes .. " " .. seconds .. " " .. centiseconds
end

hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render_behind)