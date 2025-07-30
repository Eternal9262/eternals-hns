TEXTURE_QUARTER_CIRCLE = get_texture_info("quarter_circle")
smlua_audio_utils_replace_sequence(0x1B, 0x14, 75, "sfx")

---@param x number|integer
---@param y number|integer
---@param width number|integer
---@param height number|integer
---@param cornerRaidus number|integer
function djui_hud_render_rect_rounded(x, y, width, height, cornerRaidus)
    if cornerRaidus > width then cornerRaidus = width end
    if cornerRaidus > height then cornerRaidus = height end
    djui_hud_render_rect(x + (cornerRaidus / 2), y, width - cornerRaidus, height)
    djui_hud_render_rect(x, y + (cornerRaidus / 2), cornerRaidus / 2, height - cornerRaidus)
    djui_hud_render_rect(x + width - cornerRaidus / 2, y + (cornerRaidus / 2), cornerRaidus / 2, height - cornerRaidus)
    local circleDimensions = (1 / 64) * cornerRaidus / 2
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x, y, circleDimensions, circleDimensions)
    djui_hud_set_rotation(0x4000, 0, 0)
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x, y + height, circleDimensions, circleDimensions)
    djui_hud_set_rotation(-0x4000, 0, 0)
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x + width, y, circleDimensions, circleDimensions)
    djui_hud_set_rotation(0x8000, 0, 0)
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x + width, y + height, circleDimensions, circleDimensions)
    djui_hud_set_rotation(0, 0, 0)
end

---@param x number|integer
---@param y number|integer
---@param width number|integer
---@param height number|integer
---@param oR number|integer
---@param oG number|integer
---@param oB number|integer
---@param thickness number|integer
---@param opacity number|integer|nil
function djui_hud_render_rect_rounded_outlined(x, y, width, height, oR, oG, oB, thickness, opacity)
    if opacity == nil then opacity = 255 end
    local cornerRaidus = thickness
    djui_hud_render_rect(x, y, width, height)
    djui_hud_set_color(oR, oG, oB, opacity)
    djui_hud_render_rect(x - thickness, y, thickness, height)
    djui_hud_render_rect(x + (width - thickness) + thickness, y, thickness, height)
    djui_hud_render_rect(x, y - thickness, width, thickness)
    djui_hud_render_rect(x, y + (height - thickness) + thickness, width, thickness)
    local circleDimensions = (1 / 64) * cornerRaidus
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x - thickness, y - thickness, circleDimensions, circleDimensions)
    djui_hud_set_rotation(0x4000, 0, 0)
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x - thickness, y + height + thickness, circleDimensions, circleDimensions)
    djui_hud_set_rotation(-0x4000, 0, 0)
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x + width + thickness, y - thickness, circleDimensions, circleDimensions)
    djui_hud_set_rotation(0x8000, 0, 0)
    djui_hud_render_texture(TEXTURE_QUARTER_CIRCLE, x + width + thickness, y + height + thickness, circleDimensions, circleDimensions)
    djui_hud_set_rotation(0, 0, 0)
end

---@param text string
---@param x integer
---@param y integer
---@param scale integer
function djui_hud_print_colored_text(text, x, y, scale, opacity)
	local inSlash = false
    local hex = ""
    if opacity == nil then opacity = 255 end

	for i = 1, #text do
		local c = text:sub(i,i)

		if c == "\\" then
			inSlash = not inSlash

            if inSlash then
                hex = ""
            end
        elseif inSlash then
            hex = hex .. c
		elseif not inSlash then
            if hex:len() == 7 then
                local r, g, b = hex_to_rgb(hex)
                djui_hud_set_color(r, g, b, opacity)
            end
            djui_hud_print_text(c, x, y, scale)
            x = x + (djui_hud_measure_text(c) * scale)
		end
	end
end