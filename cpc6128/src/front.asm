; ------------------------------------------------------------------------------
; The front end: the attract screen ("The Cast"), the menus (simplified from the
; Steam version's 3x3 button grids), the records, and the level-complete screen's
; text. A port of the BBC version's (fe_main and the rest), kept in extra bank 1
; above the compiled meanie (FRONT_ORG). The logic bank calls it through
; front_call (in the low RAM), with what it needs of the game's state in fe_args.
; It draws with the low RAM's plotter, in the 256x256 mode, unscrolled (the BBC
; version's layout, its 256-pixel-wide screen as the Steam version's), and its
; text is in the CPC's own font (copy_font copies it to fe_font at start-up).
; ------------------------------------------------------------------------------

; A = 0: the attract screen, then the menus; 1: just the menus. A = the level chosen.
fe_main
        or a : jr nz,.menus
        call fe_clear_records                   ; (at the start: no records yet)
        call fe_attract
.menus  jp fe_menus

; No records: no best times or gems, no ratings
fe_clear_records
        ld hl,rec_best_lo : ld bc,2 * NUM_LEVELS : ld a,#FF : call .fill
        ld hl,rec_gem : ld bc,NUM_LEVELS : xor a : call .fill
        ld hl,rec_rate : ld bc,5 * NUM_LEVELS : ld a,#FF
.fill   ld (hl),a : inc hl : dec bc : ld e,a : ld a,b : or c : ld a,e : jr nz,.fill
        ret

; Start tune A unless it's the one playing
fe_music
        ld hl,snd_cur : cp (hl) : ret z
        ld (hl),a : ld (snd_music_req),a
        ret

; The screen: the 256x256 mode, buffer 0 on show, unscrolled and cleared, with
; background colour A (the BBC's colours: 2 green, 6 cyan)
fe_screen
        push af
        xor a : ld (flip_pending),a
        ld hl,black_pens : call set_palette     ; (hidden while it's set up)
        xor a : call set_mode
        xor a : ld (back),a : ld (front),a
        ld a,#80 : ld (back_page),a
        xor a : call fill_back
        xor a : ld hl,0 : call show_at
        xor a : ld (clip_l),a : ld (clip_h),a
        ld hl,0 : ld (clip_t),hl
        ld a,64 : ld (clip_r),a
        pop af : and 7 : ld e,a : ld d,0 : ld hl,fe_bbc_colours : add hl,de
        ld a,(hl) : ld (fe_pens),a
        ld hl,fe_pens : call set_palette
        ld a,PM_PLOT : ld (p_mode),a
        ld a,3 : ld (txt_colour),a              ; (black text)
        ret
fe_bbc_colours db #54, #4C, #52, #4A, #55, #4D, #53, #4B     ; black, red, green, yellow, blue, magenta, cyan, white
fe_pens    db 0, #4D, #4A, #54, #54             ; (pens 0-3 - the BBC's colours 0, 2, 1, 3 - the border)
black_pens db #54, #54, #54, #54, #54

; ---- Text

; Print the string after the CALL: its byte column, its pixel row, then the
; characters, ending with 0
print_inline
        ex (sp),hl
        ld a,(hl) : inc hl : ld (txt_col),a
        ld a,(hl) : inc hl : ld (txt_y),a : xor a : ld (txt_y + 1),a
        call print_hl
        ex (sp),hl
        ret
; ... centred across the screen: its pixel row, then the characters
print_centre
        ex (sp),hl
        ld a,(hl) : inc hl : ld (txt_y),a : xor a : ld (txt_y + 1),a
        call str_len : ld b,a : ld a,32 : sub b : ld (txt_col),a
        call print_hl
        ex (sp),hl
        ret

; Print the string at HL (HL is left after its 0), from txt_col, txt_y
print_hl
        ld a,(hl) : inc hl : or a : ret z
        push hl : call fe_char : pop hl
        jr print_hl

; A = the length of the string at HL (HL kept)
str_len push hl : ld b,0
.len    ld a,(hl) : or a : jr z,.done
        inc hl : inc b : jr .len
.done   ld a,b : pop hl
        ret

; Print character A at txt_col, txt_y, and move on
fe_char call print_char
        ld a,(txt_col) : add a,2 : ld (txt_col),a
        ret

; Draw character A at byte column txt_col, pixel row txt_y (in the window's
; coordinates, as plot's), in txt_colour: each row two screen bytes, the left and
; right 4 pixels
print_char
        sub 32 : ret c
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld de,fe_font : add hl,de : ld (txt_src),hl
        ld b,0
.row    ld hl,(txt_y) : ld e,b : ld d,0 : add hl,de : ex de,hl
        ld a,(txt_col) : call scr_addr
        push hl : ld hl,(txt_src) : ld c,(hl) : inc hl : ld (txt_src),hl : pop hl
        ld a,c : rrca : rrca : rrca : rrca : and 15 : call txt_nibble
        inc l : jr nz,.right                    ; (the next byte, within the 2K)
        ld a,h : and #F8 : ld d,a : ld a,h : inc a : and 7 : or d : ld h,a
.right  ld a,c : and 15 : call txt_nibble
        inc b : ld a,b : cp 8 : jr nz,.row
        ret

; 4 pixels (A, the leftmost in bit 3) to the screen byte at HL, in txt_colour (B, C kept)
txt_nibble
        ld e,a : add a,a : add a,a : add a,a : add a,a : or e : cpl
        and (hl) : ld d,a                       ; (the byte with those pixels clear)
        ld a,(txt_colour) : rrca : jr nc,.lo
        ld a,d : or e : ld d,a
.lo     ld a,(txt_colour) : and 2 : jr z,.hi
        ld a,e : add a,a : add a,a : add a,a : add a,a : or d : ld d,a
.hi     ld (hl),d
        ret

; HL = the back buffer's address of byte column A, pixel row DE (the window's
; coordinates, as plot's) (BC kept)
scr_addr
        push bc
        ld c,a
        ld a,e : and 7 : add a,a : add a,a : add a,a : ld b,a      ; (the line in the cell, * 8)
        ld l,e : ld h,d : srl h : rr l : srl h : rr l : srl h : rr l
        ld h,rowoff_lo >> 8 : ld a,(hl) : inc h : ld h,(hl) : ld l,a
        ld a,c : add a,l : ld l,a : jr nc,.nc
        inc h
.nc     ld a,h : and 7 : add a,b : ld b,a
        ld a,(back_page) : add a,b : ld h,a
        pop bc
        ret

; ---- The first attract screen ("The Cast", from the Steam version's oDemoBubble):
; the Steam version's 256-pixel-wide layout

MACRO CAST_SPRITE img, x, y
        ld a,{img} : ld (p_img),a
        ld hl,{x} : ld (p_x),hl
        ld hl,{y} : ld (p_y),hl
        call plot
MEND

fe_attract
        ld a,TUNE_INTRO : call fe_music
        ld a,2 : call fe_screen                 ; (green, as the Steam start room)
        CAST_SPRITE IMG_Frak, 128 - 28, 8 * 3 + 6
        call print_centre : db 10 + 8 * 3, "The Cast", 0
        call print_centre : db 10 + 8 * 4, "--------", 0
        CAST_SPRITE IMG_TroggBody_r, 64, 8 * 10 + 4
        CAST_SPRITE IMG_TroggLegs_r_0, 64, 8 * 10 + 4
        call print_inline : db (192 - 20) >> 2, 10 + 8 * 7, "Trogg", 0
        call print_centre : db 10 + 8 * 10, "vs.", 0
        CAST_SPRITE IMG_Scrubbly, 64, 8 * 17
        call print_inline : db (192 - 32) >> 2, 10 + 8 * 13, "Scrubbly", 0
        CAST_SPRITE IMG_Hooter, 64, 8 * 21 - 4
        call print_inline : db (192 - 24) >> 2, 10 + 8 * 17 + 4, "Hooter", 0
        CAST_SPRITE IMG_Poglet, 64, 8 * 25
        call print_inline : db (192 - 24) >> 2, 10 + 8 * 22, "Poglet", 0
        call print_centre : db 256 - 10 - 8 * 3, "Collect all the keys to win!", 0
        call print_centre : db 256 - 10 - 8 * 1, "(C) 1984-2026 Nick Pelling", 0
        call fe_release
.wait   call fe_select_key : jr z,.wait
        ret

; ---- Keys

; NZ if Space, Return, Enter, P or Y is pressed
fe_select_key
        ld a,KEY_SPACE : call key_pressed : ret nz
        ld a,KEY_RETURN : call key_pressed : ret nz
        ld a,KEY_ENTER : call key_pressed : ret nz
        ld a,KEY_P : call key_pressed : ret nz
        ld a,KEY_Y : jp key_pressed

; Wait until none of the menu keys is pressed
fe_release
        ld hl,fe_keys : ld b,fe_keys_end - fe_keys
.key    ld a,(hl) : call key_pressed : jr nz,fe_release
        inc hl : djnz .key
        ret
fe_keys db KEY_SPACE, KEY_RETURN, KEY_ENTER, KEY_P, KEY_Y, KEY_ESC
        db KEY_Z, KEY_LEFT, KEY_X, KEY_RIGHT, KEY_O, KEY_UP, KEY_K, KEY_DOWN
fe_keys_end

; ---- The menus

; The top menu, then a level group's: A = the level chosen
fe_menus
.top    xor a : ld (fe_kind),a
        ld a,(fe_top_sel) : ld (fe_sel),a
        call fe_grid
        push af : ld a,(fe_sel) : ld (fe_top_sel),a : pop af
        jr c,.top                               ; (Escape: stay on the top menu)
        or a : jr nz,.not_replay
        ld a,(fe_last) : ret                    ; (replay the last level)
.not_replay
        cp 1 : jr nz,.not_difficulty
        ; the next difficulty: Easy, Hard, Harder, Insane (the Steam version's 1, 2, 4, 6), Zero
        ld a,(fe_diff) : ld e,a : ld d,0 : ld hl,next_difficulty : add hl,de
        ld a,(hl) : ld (fe_diff),a
        jr .top
.not_difficulty
        cp 2 : jr nz,.group
        xor a : ret                             ; (Training)
.group  sub 3 : ld (fe_group),a
        ld a,1 : ld (fe_kind),a
        xor a : ld (fe_sel),a
        call fe_grid
        jr c,.top                               ; (Escape: back to the top menu)
        ; the level: 1 + group * 9 + button
        ld a,(fe_group) : ld b,a : add a,a : add a,a : add a,a : add a,b : ld b,a
        ld a,(fe_sel) : add a,b : inc a
        ret
next_difficulty db 1, 2, 4, 4, 6, 6, 0          ; (Zero, Easy, Hard, Harder, Insane, Zero...)
fe_tunes db TUNE_SELECT, TUNE_LEVELS

; A 3x3 grid of buttons (fe_kind: the top menu or a level group), with button
; fe_sel selected, moved around with Z X O K (or the cursor keys): carry clear and
; A = fe_sel when one is chosen, carry set on Escape
fe_grid
        ld a,(fe_kind) : ld e,a : ld d,0 : ld hl,fe_tunes : add hl,de
        ld a,(hl) : call fe_music               ; (as the Steam version's select and level screens)
        ld a,6 : call fe_screen                 ; (cyan)
        ld a,8 : ld (fe_i),a
.buttons
        ld a,(fe_i) : call fe_button
        ld a,(fe_i) : ld c,a : ld a,3 : call fe_frame
        ld a,(fe_i) : dec a : ld (fe_i),a : jp p,.buttons
        ld a,255 : ld (fe_flash),a
        call fe_release
.loop   ; the selected button's border flashes yellow and magenta
        ld a,(vsyncs) : and 16 : ld a,1 : jr z,.colour
        ld a,2
.colour ld hl,fe_flash : cp (hl) : jr z,.keys
        ld (hl),a : ld b,a : ld a,(fe_sel) : ld c,a : ld a,b : call fe_frame
.keys   call fe_select_key : jr z,.not_select
        ld a,(fe_sel) : or a                    ; (carry clear)
        ret
.not_select
        ld a,KEY_ESC : call key_pressed : jr z,.not_escape
        scf
        ret
.not_escape
        ld a,(fe_sel) : ld (fe_i),a             ; (the new selection, if it moves)
        ld a,KEY_Z : call key_pressed : jr nz,.left
        ld a,KEY_LEFT : call key_pressed : jr z,.not_left
.left   ld a,(fe_i) : call fe_col : jp z,.loop
        ld hl,fe_i : dec (hl) : jr .moved
.not_left
        ld a,KEY_X : call key_pressed : jr nz,.right
        ld a,KEY_RIGHT : call key_pressed : jr z,.not_right
.right  ld a,(fe_i) : call fe_col : cp 2 : jp z,.loop
        ld hl,fe_i : inc (hl) : jr .moved
.not_right
        ld a,KEY_O : call key_pressed : jr nz,.up
        ld a,KEY_UP : call key_pressed : jr z,.not_up
.up     ld a,(fe_i) : cp 3 : jp c,.loop
        sub 3 : ld (fe_i),a : jr .moved
.not_up ld a,KEY_K : call key_pressed : jr nz,.down
        ld a,KEY_DOWN : call key_pressed : jp z,.loop
.down   ld a,(fe_i) : cp 6 : jp nc,.loop
        add a,3 : ld (fe_i),a
.moved  ld a,(fe_sel) : ld c,a : ld a,3 : call fe_frame     ; (the old one back to black)
        ld a,(fe_i) : ld (fe_sel),a
        ld a,255 : ld (fe_flash),a
        call fe_release
        jp .loop

; A = A MOD 3 (A 0-8), Z if 0
fe_col  cp 3 : jr c,.done
        sub 3 : cp 3 : jr c,.done
        sub 3
.done   or a
        ret

; fe_bx, fe_y0 = button A's byte column and top row (its box is 80 x 82)
fe_where
        push af : call fe_col
        ld e,a : ld d,0 : ld hl,fe_bx_of : add hl,de : ld a,(hl) : ld (fe_bx),a
        pop af : ld e,0
.row    cp 3 : jr c,.have_row
        sub 3 : inc e : jr .row
.have_row
        ld d,0 : ld hl,fe_y0_of : add hl,de : ld a,(hl) : ld (fe_y0),a
        ret
fe_bx_of db 1, 22, 43                           ; ((4 + 84 * column) / 4: the BBC's, less its 32 pixels in)
fe_y0_of db 1, 86, 171

; The border of button C in colour A: 2 pixels wide
fe_frame
        ld e,a : ld d,0 : ld hl,fe_pattern : add hl,de : ld a,(hl) : ld (fe_pat),a
        ld a,c : call fe_where
        ld a,(fe_y0) : call fe_hrow
        ld a,(fe_y0) : inc a : call fe_hrow
        ld a,(fe_y0) : add a,80 : call fe_hrow
        ld a,(fe_y0) : add a,81 : call fe_hrow
        ; the sides: the left 2 pixels of the first byte, the right 2 of the last
        ld b,82
.side   ld a,(fe_y0) : add a,b : dec a : ld e,a : ld d,0
        ld a,(fe_bx) : call scr_addr
        ld a,#CC : call fe_pixels
        ld de,19 : add hl,de : ld a,#33 : call fe_pixels
        djnz .side
        ret
fe_pattern db #00, #0F, #F0, #FF                ; (a byte of colour 0-3)

; A row of the current button's border: 20 bytes at row A
fe_hrow ld e,a : ld d,0 : ld a,(fe_bx) : call scr_addr
        ld b,20
.byte   ld a,#FF : call fe_pixels
        inc hl : djnz .byte
        ret

; Pixels A (a mask) of the screen byte at HL in fe_pat's colour (B, E kept)
fe_pixels
        ld c,a : cpl : and (hl) : ld d,a
        ld a,(fe_pat) : and c : or d : ld (hl),a
        ret

; Print the string after the CALL centred in the current button, the byte after the
; CALL rows down
fe_title
        ex (sp),hl
        ld a,(fe_y0) : add a,(hl) : inc hl
        call fe_centred
        ex (sp),hl
        ret
; ... the string at HL, A rows down (HL is left after its 0)
fe_centred
        ld (txt_y),a : xor a : ld (txt_y + 1),a
        call str_len : ld b,a : ld a,(fe_bx) : add a,10 : sub b : ld (txt_col),a
        jp print_hl

; Print level A's name centred in the current button, at row C
fe_level_name
        ld l,a : ld h,0 : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de : add hl,hl   ; (* 10)
        ld de,level_names : add hl,de
        ld a,c : jr fe_centred

; Image A at (B, C) in the current button
fe_sprite
        ld (p_img),a
        ld a,(fe_bx) : ld l,a : ld h,0 : add hl,hl : add hl,hl
        ld e,b : ld d,0 : add hl,de : ld (p_x),hl
        ld a,(fe_y0) : add a,c : ld l,a : ld a,0 : adc a,0 : ld h,a : ld (p_y),hl
        jp plot
MACRO BUTTON_SPRITE img, dx, dy
        ld a,{img} : ld bc,({dx}) * 256 + ({dy}) : call fe_sprite
MEND

; Draw button A's contents
fe_button
        push af : call fe_where : pop af
        ld b,a : ld a,(fe_kind) : or a : ld a,b : jp nz,fe_level_button
        add a,a : ld e,a : ld d,0 : ld hl,.top : add hl,de
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        jp (hl)
.top    dw .b_replay, .b_difficulty, .b_training, .b_classic, .b_moving
        dw .b_vertical, .b_sliding, .b_placing, .b_bouncing
.b_replay
        call fe_title : db 6, "Replay", 0
        ld a,(fe_y0) : add a,38 : ld c,a : ld a,(fe_last)
        jp fe_level_name
.b_difficulty
        call fe_title : db 6, "Difficulty", 0
        ; a balloon for each level of difficulty, and its name
        ld a,(fe_diff) : ld e,a : ld d,0 : ld hl,diff_balloons : add hl,de
        ld a,(hl) : ld (fe_i2),a
.balloons
        ld a,(fe_i2) : or a : jr z,.named
        add a,a : add a,a : add a,a : add a,a : add a,2 : ld b,a : ld c,44   ; (x = 2 + 16 * n)
        ld a,IMG_Balloon : call fe_sprite
        ld hl,fe_i2 : dec (hl) : jr .balloons
.named  ld a,(fe_diff) : add a,a : ld e,a : ld d,0 : ld hl,diff_names : add hl,de
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        ld a,(fe_y0) : add a,64
        jp fe_centred
.b_training
        call fe_title : db 6, "Training", 0
        BUTTON_SPRITE IMG_TroggBody_r, 40, 62
        BUTTON_SPRITE IMG_TroggLegs_r_0, 40, 62
        ret
.b_classic
        call fe_title : db 6, "Classic", 0
        BUTTON_SPRITE IMG_TroggBody_l, 40, 62
        BUTTON_SPRITE IMG_TroggLegs_l_1, 40, 62
        ret
.b_moving
        call fe_title : db 6, "Moving", 0
        BUTTON_SPRITE IMG_Scrubbly, 40, 66
        ret
.b_vertical
        call fe_title : db 6, "Vertical", 0
        BUTTON_SPRITE IMG_Poglet, 40, 66
        ret
.b_sliding
        call fe_title : db 6, "Sliding", 0
        BUTTON_SPRITE IMG_Log1, 8, 66
        BUTTON_SPRITE IMG_Hooter, 40, 66
        ret
.b_placing
        call fe_title : db 6, "Placing", 0
        BUTTON_SPRITE IMG_Girder3, 22, 48
        BUTTON_SPRITE IMG_Girder3, 22, 66
        ret
.b_bouncing
        call fe_title : db 6, "Bouncing", 0
        BUTTON_SPRITE IMG_Spring, 40, 66
        ret
diff_balloons db 0, 1, 2, 2, 3, 3, 4
diff_names dw n_zero, n_easy, n_hard, n_hard, n_harder, n_harder, n_insane
n_zero   db "Zero", 0
n_easy   db "Easy", 0
n_hard   db "Hard", 0
n_harder db "Harder", 0
n_insane db "Insane", 0

; A level button (button A of the group): the column's meanie on its platform
; (as in the Steam version: Scrubbly, Poglet, Hooter), the level's name, its target
; time and the best so far, and its medals
fe_level_button
        ld (fe_i2),a
        call fe_col : jr z,.scrubbly
        cp 1 : jr z,.poglet
        BUTTON_SPRITE IMG_Girder3, 7, 52
        BUTTON_SPRITE IMG_Hooter, 23, 52
        jr .name
.scrubbly
        BUTTON_SPRITE IMG_Ledge2, 7, 52
        BUTTON_SPRITE IMG_Scrubbly, 23, 52
        jr .name
.poglet BUTTON_SPRITE IMG_Log5, 7, 52
        BUTTON_SPRITE IMG_Poglet, 23, 52
.name   ; the level: 1 + group * 9 + button
        ld a,(fe_group) : ld b,a : add a,a : add a,a : add a,a : add a,b : ld b,a
        ld a,(fe_i2) : add a,b : inc a : ld (fe_lev),a
        ld a,(fe_y0) : add a,70 : ld c,a : ld a,(fe_lev) : call fe_level_name
        ; its target time at the top right, and the best so far below it
        call fe_lev_de
        ld hl,level_good_lo : add hl,de : ld c,(hl)
        ld hl,level_good_hi : add hl,de : ld b,(hl)
        ld a,7 : call fe_time_at
        call fe_lev_de
        ld hl,rec_best_hi : add hl,de : ld a,(hl) : cp #FF : jr z,.no_best
        ld b,a : ld hl,rec_best_lo : add hl,de : ld c,(hl)
        ld a,43 : call fe_time_at
.no_best
        ; the medals: the rating (at this difficulty), the gems, the speed
        call fe_rate_index : ld a,(hl)
        cp 3 : jr c,.rated
        cp #FF : jr z,.unrated
        ld a,3 : jr .rated
.unrated
        ld a,5                                  ; (as the BBC version)
.rated  add a,a : ld e,a : ld d,0 : ld hl,fe_rating_icons : add hl,de
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        ld a,11 : call fe_icon_at
        call fe_lev_de
        ld hl,rec_gem : add hl,de : ld a,(hl) : or a
        ld hl,icon_Gem_Small : jr nz,.gem
        ld hl,icon_Gem_Outline_Small
.gem    ld a,14 : call fe_icon_at
        ; the stopwatch: if the best time beats the target
        call fe_lev_de
        ld hl,rec_best_lo : add hl,de : ld c,(hl)
        ld hl,rec_best_hi : add hl,de : ld b,(hl)
        ld hl,level_good_lo : add hl,de : ld a,(hl)
        ld hl,level_good_hi : add hl,de : ld h,(hl) : ld l,a
        ld a,c : sub l : ld a,b : sbc a,h       ; (carry if the best is less)
        ld hl,icon_Stopwatch_Small : jr c,.watch
        ld hl,icon_Stopwatch_Outline_Small
.watch  ld a,17
        ; (and on)

; Draw the icon at HL at byte column A of the current button, 62 rows down (its
; width and height, then its bytes, column by column; colour 0 leaves the screen alone)
fe_icon_at
        ld c,a : ld a,(fe_bx) : add a,c : ld (fe_n),a
        ld a,(hl) : ld (fe_iw),a : inc hl
        ld a,(hl) : ld (fe_ih),a : inc hl
.col    xor a : ld (fe_r),a
.row    push hl
        ld a,(fe_y0) : add a,62 : ld e,a : ld a,(fe_r) : add a,e : ld e,a : ld d,0
        ld a,(fe_n) : call scr_addr
        pop de : ld a,(de) : inc de : push de
        or a : jr z,.clear
        ld c,a : rrca : rrca : rrca : rrca : or c : and #0F       ; (its pixels' mask)
        ld b,a : rlca : rlca : rlca : rlca : or b
        cpl : and (hl) : or c : ld (hl),a
.clear  pop hl
        ld a,(fe_r) : inc a : ld (fe_r),a
        ld b,a : ld a,(fe_ih) : cp b : jr nz,.row
        ld a,(fe_n) : inc a : ld (fe_n),a
        ld a,(fe_iw) : dec a : ld (fe_iw),a : jr nz,.col
        ret
fe_rating_icons
        dw icon_Rating_1_Small, icon_Rating_2_Small, icon_Rating_3_Small, icon_Rating_Tick_Small
        dw icon_Rating_None_Small, icon_Stopwatch_Outline_Small

; DE = fe_lev
fe_lev_de
        ld a,(fe_lev) : ld e,a : ld d,0
        ret

; Print the time BC (game ticks) as m:ss, at byte column 11 of the current button,
; A rows down
fe_time_at
        ld e,a : ld a,(fe_y0) : add a,e : ld (txt_y),a : xor a : ld (txt_y + 1),a
        ld a,(fe_bx) : add a,11 : ld (txt_col),a
        ld h,b : ld l,c : call fe_mss
        ld hl,fe_text : jp print_hl

; fe_text = "m:ss" (and 0) for the time HL (game ticks), at most 9:59; A = the
; ticks over the seconds
fe_mss  ld a,50 : call fe_div16 : push af       ; (seconds)
        ld de,600 : or a : sbc hl,de : add hl,de : jr c,.ok
        ld hl,599
.ok     ld a,60 : call fe_div16 : ld b,a        ; (HL = minutes, B = seconds)
        ld a,l : add a,'0' : ld (fe_text),a
        ld a,':' : ld (fe_text + 1),a
        ld a,b : ld c,'0' - 1
.tens   inc c : sub 10 : jr nc,.tens
        add a,10 + '0' : ld (fe_text + 3),a
        ld a,c : ld (fe_text + 2),a
        xor a : ld (fe_text + 4),a
        pop af
        ret

; HL = HL / A, the remainder in A
fe_div16
        ld c,a : xor a : ld b,16
.loop   add hl,hl : rla : cp c : jr c,.no
        sub c : inc l
.no     djnz .loop
        ret

; ---- The level-complete screen's text (see win_screen): centred in the window,
; 40 rows up from its middle (60 with a medal)
fe_win
        ld a,3 : ld (txt_colour),a              ; (black)
        ld a,(clip_h) : or a : ld a,128 : jr z,.middle
        ld a,(clip_h) : srl a
.middle sub 40 : ld b,a
        ld a,(fe_done_restarts) : cp 3 : ld a,b : jr nc,.base
        sub 20
.base   ld (fe_wy),a
        call fe_win_text : db 0, "We've done it!", 0
        ; the time, to a thousandth of a second (m:ss.mmm)
        ld hl,(fe_done_ticks) : call fe_mss     ; (A = the ticks over: 20 ms each)
        ld c,a
        ld a,'.' : ld (fe_text + 4),a
        ; the milliseconds: ticks * 20, so the digits are ticks / 5, (ticks MOD 5) * 2 and 0
        ld a,c : ld b,'0' - 1
.fifths inc b : sub 5 : jr nc,.fifths
        add a,5 : add a,a : add a,'0' : ld (fe_text + 6),a
        ld a,b : ld (fe_text + 5),a
        ld a,'0' : ld (fe_text + 7),a
        xor a : ld (fe_text + 8),a
        ld a,16 : call fe_win_line
        ld hl,fe_text : call fe_win_print
        ld a,32 : ld (fe_wdy),a
        ld a,(fe_done_gems) : or a : jr z,.no_gems
        call fe_win_text : db 32, "You collected all the gems!", 0
        ld a,48 : ld (fe_wdy),a
.no_gems
        ; the medal
        ld a,(fe_done_restarts) : cp 3 : ret nc
        ld a,(fe_wdy) : add a,32 : ld (fe_wdy),a
        ld a,(fe_done_restarts) : add a,a : ld e,a : ld d,0 : ld hl,fe_medal_text : add hl,de
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        push hl : ld a,(fe_wdy) : call fe_win_line : pop hl
        jp fe_win_print
fe_medal_text dw fe_gold, fe_silver, fe_bronze
fe_gold   db "!!! Gold Medal !!!", 0
fe_silver db "!!! Silver Medal !!!", 0
fe_bronze db "!!! Bronze Medal !!!", 0

; Print the string after the CALL (after a byte: its row below fe_wy), centred
fe_win_text
        ex (sp),hl
        ld a,(hl) : inc hl
        push hl : call fe_win_line : pop hl
        call fe_win_print
        ex (sp),hl
        ret
; txt_y = the window's top + fe_wy + A
fe_win_line
        ld hl,fe_wy : add a,(hl) : ld e,a : ld d,0
        ld hl,(clip_t) : add hl,de : ld (txt_y),hl
        ret
; Print the string at HL centred across the window, at txt_y (HL left after its 0)
fe_win_print
        call str_len : ld b,a
        ld a,(clip_l) : ld c,a : ld a,(clip_r) : sub c : srl a : add a,c   ; (the middle column: clip_r
        sub b : ld (txt_col),a                                          ; may be 256, as 0)
        jp print_hl

; ---- The records (they last until the machine is switched off)

; Add the result of the level just finished (fe_done_*) to the records
fe_record
        ld a,(fe_done_level) : ld (fe_lev),a
        call fe_lev_de
        ld hl,rec_best_lo : add hl,de : ld c,(hl)
        ld hl,rec_best_hi : add hl,de : ld b,(hl)
        ld hl,(fe_done_ticks) : or a : sbc hl,bc : jr nc,.not_best
        ld hl,(fe_done_ticks)
        ld a,l : ld bc,rec_best_lo : call .store
        ld a,h : ld bc,rec_best_hi : call .store
.not_best
        ld a,(fe_done_gems) : or a : jr z,.no_gem
        ld a,1 : ld bc,rec_gem : call .store
.no_gem call fe_rate_index
        ld a,(fe_done_restarts) : cp (hl) : ret nc
        ld (hl),a
        ret
.store  push hl : ld h,b : ld l,c : add hl,de : ld (hl),a : pop hl
        ret

; HL = level fe_lev's rating at this difficulty: in rec_rate (4 a level: Easy, Hard,
; Harder, Insane), or at Zero, rec_rate0
fe_rate_index
        ld a,(fe_diff) : or a : jr z,.zero
        srl a : ld c,a                          ; (Easy 1, Hard 2, Harder 4, Insane 6: 0-3)
        ld a,(fe_lev) : add a,a : add a,a : add a,c
        ld e,a : ld d,0 : ld hl,rec_rate : add hl,de
        ret
.zero   call fe_lev_de : ld hl,rec_rate0 : add hl,de
        ret

        INCLUDE "gen/names.asm"

; The front end's variables
fe_sel     db 0                     ; the selected button
fe_top_sel db 0                     ; ... on the top menu
fe_group   db 0
fe_kind    db 0                     ; 0 the top menu, 1 a level group
fe_bx      db 0                     ; the button being drawn: its byte column and top row
fe_y0      db 0
fe_flash   db 0
fe_i       db 0
fe_i2      db 0
fe_n       db 0
fe_pat     db 0
fe_lev     db 0
fe_iw      db 0
fe_ih      db 0
fe_r       db 0
fe_wy      db 0                     ; (fe_win)
fe_wdy     db 0
fe_text    DEFS 9
txt_col    db 0                     ; print_char: where, and in what colour
txt_y      dw 0
txt_colour db 3
txt_src    dw 0
rec_best_lo DEFS NUM_LEVELS         ; the records: each level's best time (game ticks), #FFFF if none
rec_best_hi DEFS NUM_LEVELS
rec_gem    DEFS NUM_LEVELS          ; ... 1 if it's been completed with all the gems
rec_rate   DEFS NUM_LEVELS * 4      ; ... fewest restarts, at each difficulty (Easy, Hard, Harder, Insane), #FF if none
rec_rate0  DEFS NUM_LEVELS          ; ... and at Zero (no balloons or daggers: for speed runs)
fe_font    DEFS 96 * 8              ; the font, characters 32-127 (copy_font)
