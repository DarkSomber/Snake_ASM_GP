.model small
.stack 200h
.data
	; ---- screen geometry ----
	screen_width  equ 80d
	screen_height equ 25d

	; ---- TEMP DESIGN: colors (BIOS attribute bytes, bg/fg nibble) ----
	background_color   equ 07h   ; light gray text on black
	player_score_color equ 0Fh   ; bright white text on black
	food_color         equ 0Ch   ; bright red text on black
	snake_head_color   equ 0Ah   ; bright green text on black
	snake_body_color   equ 02h   ; green text on black

	; ---- TEMP DESIGN: icons/characters (ASCII placeholders) ----
	food_icon        equ '*'    ; food glyph
	snake_head_icon  equ '@'    ; snake head glyph
	snake_body_icon  equ 'o'    ; snake body glyph

	; ---- player ----
	; score label is printed at the bottom-right corner of the screen
	player_score_label_offset equ (screen_height * screen_width - 1d) * 2d
	player_score db ?
	player_win_score equ 0FFh    ; score needed to win original is 0FFh: 255

	; ---- snake ----
	; snake_body holds cell offsets into the video buffer, head first
	; sized for the max possible length (win score + a few slots)
	snake_len dw ?
	snake_body dw player_win_score + 3h dup(?)
	; remembers the tail's old position so we can erase it after moving
	snake_previous_last_cell dw ?

	; ---- movement ----
	; BIOS scan codes for arrow keys; default direction is right
	RIGHT equ 4Dh
	LEFT  equ 4Bh
	UP    equ 48h
	DOWN  equ 50h
	snake_direction db ?

	; ---- food ----
	food_location dw ?
	; keeps new food spawns out of the score label / border area
	food_bounders equ 2d * screen_width * 2d

	; ---- immunity fruit ----
	; while active the snake ignores its own body AND missiles/explosions.
	; the snake is tinted while immune and the tint fades out cell by cell
	; (tail first) as the timer runs down.
	immunity_active db 0h
	immunity_timer  db 0h
	immunity_food_location dw 0FFFFh     ; 0FFFFh = no fruit on the map
	immunity_duration equ 50d            ; frames of immunity (~3 seconds)
	immunity_food_icon  equ 'I'
	immunity_food_color equ 0Bh          ; bright cyan
	immune_head_color   equ 0Bh          ; bright cyan head while immune
	immune_body_color   equ 03h          ; cyan body while immune

	; ---- shortening fruit ----
	shrink_food_location dw 0FFFFh       ; 0FFFFh = no fruit on the map
	shrink_amount equ 2d                 ; bytes cut off the tail (1 cell)
	min_snake_len equ 4d                 ; shortest snake the fruit leaves (2 cells)
	shrink_food_icon  equ 'S'
	shrink_food_color equ 0Eh            ; yellow

	; ---- OBSTACLES ----

	; ---- rocks ----
	num_rocks equ 10d
	rock_icon equ 'R'
	rock_color equ 08h                 ; dark gray
	rock_locations dw num_rocks dup(?)
	rock_none equ 0FFFFh               ; marks an unused rock slot
	; the snake starts in row 3 heading right; keep that lane rock-free so a
	; rock can never kill the snake before the player gets a chance to react
	start_lane_begin equ 3d * screen_width * 2d
	start_lane_end   equ 4d * screen_width * 2d

	; ---- missiles and explosions ----
	missile_state db 0       ; 0 = none, 1 = in flight, 2 = exploding, 3 = warning
	missile_location dw ?
	missile_direction db ?   ; LEFT, RIGHT, UP or DOWN
	missile_timer db 0       ; frames left in the warning or explosion phase
	missile_fuse db 0        ; frames of flight before the missile explodes

	; missile design
	missile_icon_hor equ '-'
	missile_icon_ver equ '|'
	missile_color equ 0Eh

	; missile warning
	missile_state_warning equ 3h
	warning_frames equ 54d       ; ~3.5 seconds
	warning_icon equ '!'
	warning_color equ 8Ch        ; bright red and blinking (0Ch for steady)

	; explosion design
	explosion_icon equ '*'
	explosion_color equ 0Fh

	; explosion marker
	missile_target dw ?
	target_icon equ 'X'
	target_color equ 0Ch         ; bright red
	missile_max_steps_hor equ 77d    ; col 1 to col 78
	missile_max_steps_ver equ 22d    ; row 1 to row 23



	; ---- game state ----
	EXIT db 0h
	START_AGAIN db 0h
	START_AGAIN_KEY equ 39h  ; spacebar
	END_GAME_KEY equ 01h     ; esc
	PAUSE_KEY    equ 19h     ; 'P' scan code
	ENTER_KEY    equ 1Ch     ; enter scan code

	; ---- leaderboard ----
	; the last max_scores runs are kept in the order they were played (when it
	; is full the oldest run is dropped); they are sorted by score, highest
	; first, only when they are drawn. it is only shown on the end screen
	; (death or win) and while paused.
	max_scores   equ 5d
	name_len_max equ 5d
	lb_count  db 0h
	lb_names  db max_scores * name_len_max dup(' ')
	lb_scores db max_scores dup(0)
	lb_order  db max_scores dup(0)         ; display order, filled by the sort
	name_buf  db 'A', ' ', ' ', ' ', ' '   ; name being typed
	name_pos  db 0h                        ; slot the cursor is on
	pc_attr   db 0h                        ; scratch for PRINT_CENTERED

	; ---- panel (drawn over the middle of the screen) ----
	panel_row equ 6d
	panel_col equ 25d
	panel_w   equ 30d
	panel_h   equ 13d
	panel_origin equ (panel_row * screen_width + panel_col) * 2d
	panel_color        equ 1Fh     ; white on blue
	panel_title_color  equ 1Eh     ; yellow on blue
	panel_bracket_color equ 1Bh    ; cyan on blue
	panel_select_color equ 70h     ; black on gray = selected letter
	panel_save_buf dw panel_w * panel_h dup(?)

	; text rows (as byte offsets of the start of the row)
	row_pause_title equ 7d  * screen_width * 2d
	row_title       equ 8d  * screen_width * 2d
	row_score       equ 9d  * screen_width * 2d
	row_prompt      equ 11d * screen_width * 2d
	row_slots       equ 13d * screen_width * 2d
	row_hint1       equ 15d * screen_width * 2d
	row_hint2       equ 16d * screen_width * 2d
	row_hint3       equ 17d * screen_width * 2d
	row_lb_first    equ 10d * screen_width * 2d
	row_footer      equ 16d * screen_width * 2d
	name_slots_origin equ row_slots + (panel_col + (panel_w - 15d) / 2d) * 2d

	txt_game_over   db 'GAME OVER', 0
	txt_you_win     db 'YOU WIN!', 0
	end_title       dw ?                   ; title string END_SCREEN shows
	txt_enter_name  db 'ENTER YOUR NAME', 0
	txt_hint1       db 'UP/DOWN: CHANGE LETTER', 0
	txt_hint2       db 'LEFT/RIGHT: MOVE', 0
	txt_hint3       db 'ENTER: CONFIRM', 0
	txt_leaderboard db 'LEADERBOARD', 0
	txt_paused      db 'PAUSED', 0
	txt_footer_dead db 'SPACE: AGAIN   ESC: EXIT', 0
	txt_footer_pause db 'P: RESUME   ESC: QUIT', 0
	score_line      db 'SCORE: 000', 0
	lb_row_buf      db '1. XXXXX  000', 0

	; ---- TEMP DESIGN: copy/messages ----
	msg_start_game db 'WELCOME TO SNAKE. ESC: QUIT   P: PAUSE', 0Ah, 0Dh, '$'

	; lookup table for the score label: ascii[score] is the high digit and
	; ascii[score + 256] is the low digit (hex digits, 0-F)
	ascii db 16 dup ('0')
	db     16 dup ('1')
	db     16 dup ('2')
	db     16 dup ('3')
	db     16 dup ('4')
	db     16 dup ('5')
	db     16 dup ('6')
	db     16 dup ('7')
	db     16 dup ('8')
	db     16 dup ('9')
	db     16 dup ('A')
	db     16 dup ('B')
	db     16 dup ('C')
	db     16 dup ('D')
	db     16 dup ('E')
	db     16 dup ('F')
	db     16 dup ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F')
.code
MAIN:
	mov    ax, @data
	mov    ds, ax

	call   INIT_GAME

MAIN_LOOP:
	call   MOVE_SNAKE
	call   REDRAW_PICKUPS
	call   PRINT_SNAKE

	call   UPDATE_MISSILE
	call   CHECK_MISSILE_COLLISION
	cmp    byte ptr [EXIT], 1h          ; died: stop this frame here
	jnz JFIX_SKIP_1
	jmp  MAIN_LOOP_FINISHED
JFIX_SKIP_1:

	call   CHECK_SNAKE_AET_FOOD
	cmp    byte ptr [EXIT], 1h          ; died or won
	jnz JFIX_SKIP_2
	jmp  MAIN_LOOP_FINISHED
JFIX_SKIP_2:
	call   CHECK_SNAKE_AET_IMMUNITY_FOOD
	call   CHECK_SNAKE_AET_SHRINK_FOOD
	call   UPDATE_IMMUNITY
	call   CHECK_SNAKE_IN_BORDERS
	cmp    byte ptr [EXIT], 1h
	jz     MAIN_LOOP_FINISHED
	call   CHECK_SNAKE_NOOSE
	cmp    byte ptr [EXIT], 1h
	jz     MAIN_LOOP_FINISHED
	call   CHECK_SNAKE_ROCK_COLLISION
	cmp    byte ptr [EXIT], 1h
	jz     MAIN_LOOP_FINISHED

	call   GET_DIRECTION_BY_KEY
	call   MAIN_LOOP_FRAME_RATE

	cmp    [EXIT], 1h
	jz JFIX_SKIP_3
	jmp  MAIN_LOOP
JFIX_SKIP_3:

MAIN_LOOP_FINISHED:
	cmp    [START_AGAIN], 1h
	jnz JFIX_SKIP_4
	jmp  MAIN
JFIX_SKIP_4:

	call   INIT_SCREEN_BACK_TO_OS
	mov    ah, 4ch
	int    21h

	; missile state: 0 = no missile, 1 = in flight, 2 = explosion, 3 = warning
	UPDATE_MISSILE proc near
		cmp  byte ptr [missile_state], 0
		jz   SPAWN_MISSILE_CHANCE

		cmp  byte ptr [missile_state], 1
		jnz JFIX_SKIP_5
		jmp  MOVE_MISSILE
JFIX_SKIP_5:

		cmp  byte ptr [missile_state], 2
		jnz  CHECK_STATE_3
		jmp  HANDLE_EXPLOSION

CHECK_STATE_3:
		cmp  byte ptr [missile_state], missile_state_warning
		jz JFIX_SKIP_6
		jmp  END_UPDATE_MISSILE
JFIX_SKIP_6:
		jmp  HANDLE_WARNING

SPAWN_MISSILE_CHANCE:
		in   al, 40h              ; fast-changing hardware counter
		and  al, 0Fh              ; 07h = more frequent spawns, 1Fh = rarer
		jz JFIX_SKIP_7
		jmp  END_UPDATE_MISSILE
JFIX_SKIP_7:
		call GENERATE_RANDOM_MISSILE_DIRECTION
		call GENERATE_RANDOM_MISSILE_LOCATION

		; random fuse
		push ax
		push cx
		push dx

		mov  ah, 0h
		int  1Ah
		mov  ax, dx

		xor  dx, dx
		mov  cx, 50d
		div  cx

		add  dx, 10d                          ; fuse is 10..59 frames
		mov  byte ptr [missile_fuse], dl

		pop  dx
		pop  cx
		pop  ax

		call CALC_MISSILE_TARGET

		; start the warning instead of launching
		mov  byte ptr [missile_state], missile_state_warning
		mov  byte ptr [missile_timer], warning_frames
		ret

END_UPDATE_MISSILE:
		ret

MOVE_MISSILE:
		call DRAW_TARGET_MARK
		; erase old missile location
		mov  bx, [missile_location]
		mov  al, ' '
		mov  ah, background_color
		mov  es:[bx], ax

		dec  byte ptr [missile_fuse]
		jnz JFIX_SKIP_8
		jmp  TRIGGER_EXPLOSION
JFIX_SKIP_8:
		cmp  byte ptr [missile_direction], RIGHT
		jz   MOVE_MISSILE_RIGHT
		cmp  byte ptr [missile_direction], LEFT
		jnz JFIX_SKIP_9
		jmp  MOVE_MISSILE_LEFT
JFIX_SKIP_9:
		cmp  byte ptr [missile_direction], UP
		jnz JFIX_SKIP_10
		jmp  MOVE_MISSILE_UP
JFIX_SKIP_10:
		cmp  byte ptr [missile_direction], DOWN
		jnz JFIX_SKIP_11
		jmp  MOVE_MISSILE_DOWN
JFIX_SKIP_11:
		ret

MOVE_MISSILE_RIGHT:
		mov  ax, [missile_location]
		xor  dx, dx
		mov  bx, screen_width * 2d
		div  bx                           ; dx = column offset in bytes
		cmp  dx, (screen_width - 2d) * 2d ; column 78 or beyond
		jb JFIX_SKIP_12
		jmp  TRIGGER_EXPLOSION
JFIX_SKIP_12:
		add  word ptr [missile_location], 2d
		mov  al, missile_icon_hor
		jmp  DRAW_MISSILE

MOVE_MISSILE_LEFT:
		mov  ax, [missile_location]
		xor  dx, dx
		mov  bx, screen_width * 2d
		div  bx
		cmp  dx, 2d                       ; column 1 or before
		ja JFIX_SKIP_13
		jmp  TRIGGER_EXPLOSION
JFIX_SKIP_13:
		sub  word ptr [missile_location], 2d
		mov  al, missile_icon_hor
		jmp  DRAW_MISSILE

MOVE_MISSILE_UP:
		cmp  word ptr [missile_location], 2d * screen_width * 2d   ; row 1 or above
		jb   TRIGGER_EXPLOSION
		sub  word ptr [missile_location], screen_width * 2d
		mov  al, missile_icon_ver
		jmp  DRAW_MISSILE

MOVE_MISSILE_DOWN:
		cmp  word ptr [missile_location], (screen_height - 2d) * screen_width * 2d ; row 23+
		jae  TRIGGER_EXPLOSION
		add  word ptr [missile_location], screen_width * 2d
		mov  al, missile_icon_ver

DRAW_MISSILE:
		; al = icon
		mov  bx, [missile_location]
		mov  ah, missile_color
		mov  es:[bx], ax
		ret

TRIGGER_EXPLOSION:
		mov  byte ptr [missile_state], 2h
		mov  byte ptr [missile_timer], 10d    ; 10 frames, ~0.65 seconds
		call DRAW_EXPLOSION
		ret

HANDLE_EXPLOSION:
		dec  byte ptr [missile_timer]
		jnz  END_HANDLE_EXPLOSION
		; timer hit zero: clear the explosion and reset the missile
		call CLEAR_EXPLOSION
		; the blast may have erased the score label and the food
		call PRINT_PLAYER_SCORE
		mov  si, [food_location]
		mov  al, food_icon
		mov  ah, food_color
		mov  es:[si], ax
		mov  byte ptr [missile_state], 0h
END_HANDLE_EXPLOSION:
		ret

HANDLE_WARNING:
		call DRAW_TARGET_MARK
		mov  bx, [missile_location]
		dec  byte ptr [missile_timer]
		jz   LAUNCH_MISSILE

		; flash the "!" on and off
		mov  al, warning_icon
		test byte ptr [missile_timer], 8h
		jnz  DRAW_WARNING_CELL
		mov  al, ' '
DRAW_WARNING_CELL:
		mov  ah, warning_color
		mov  es:[bx], ax
		ret

LAUNCH_MISSILE:
		mov  al, ' '                      ; erase the "!"
		mov  ah, background_color
		mov  es:[bx], ax
		mov  byte ptr [missile_state], 1h
		ret
	UPDATE_MISSILE endp

	; in: ax = character and attribute. draws it in a plus shape around the
	; missile location (used to both draw and erase the explosion)
	DRAW_PLUS_GRID proc near
		push bx
		mov  bx, [missile_location]

		mov  es:[bx], ax            ; center
		mov  es:[bx - 2], ax        ; left
		mov  es:[bx + 2], ax        ; right
		mov  es:[bx - 160d], ax     ; up
		mov  es:[bx + 160d], ax     ; down

		pop  bx
		ret
	DRAW_PLUS_GRID endp

	DRAW_EXPLOSION proc near
		mov  al, explosion_icon
		mov  ah, explosion_color
		call DRAW_PLUS_GRID
		ret
	DRAW_EXPLOSION endp

	CLEAR_EXPLOSION proc near
		mov  al, ' '
		mov  ah, background_color
		call DRAW_PLUS_GRID
		ret
	CLEAR_EXPLOSION endp

	CHECK_MISSILE_COLLISION proc near
		cmp  byte ptr [missile_state], 0h
		jnz JFIX_SKIP_14
		jmp  END_MISSILE_COLLISION
JFIX_SKIP_14:

		; an immune snake passes straight through missiles and explosions
		cmp  byte ptr [immunity_active], 1h
		jnz JFIX_SKIP_15
		jmp  END_MISSILE_COLLISION
JFIX_SKIP_15:

		mov  ax, snake_body[0h]             ; the snake's head

		cmp  byte ptr [missile_state], 1h
		jz   CHECK_FLIGHT_COLLISION

		cmp  byte ptr [missile_state], 2h
		jz   CHECK_BLAST_COLLISION
		ret

CHECK_FLIGHT_COLLISION:
		cmp  ax, [missile_location]
		jnz JFIX_SKIP_16
		jmp  MISSILE_DEATH
JFIX_SKIP_16:
		jmp  END_MISSILE_COLLISION

CHECK_BLAST_COLLISION:
		mov  bx, [missile_location]
		cmp  ax, bx                 ; center
		jnz JFIX_SKIP_17
		jmp  MISSILE_DEATH
JFIX_SKIP_17:
		add  bx, 2
		cmp  ax, bx                 ; right
		jz   MISSILE_DEATH
		sub  bx, 4
		cmp  ax, bx                 ; left
		jz   MISSILE_DEATH
		add  bx, 2                  ; back to center
		add  bx, 160d
		cmp  ax, bx                 ; down
		jz   MISSILE_DEATH
		sub  bx, 320d
		cmp  ax, bx                 ; up
		jz   MISSILE_DEATH
END_MISSILE_COLLISION:
		ret

MISSILE_DEATH:
		call GAME_OVER
		ret
	CHECK_MISSILE_COLLISION endp

	GENERATE_RANDOM_MISSILE_LOCATION proc near
		push ax
		push bx
		push cx
		push dx

		mov  ah, 0h
		int  1Ah
		mov  ax, dx                    ; random value

		cmp  byte ptr [missile_direction], RIGHT
		jnz JFIX_SKIP_18
		jmp  SPAWN_FROM_LEFT
JFIX_SKIP_18:
		cmp  byte ptr [missile_direction], LEFT
		jnz JFIX_SKIP_19
		jmp  SPAWN_FROM_RIGHT
JFIX_SKIP_19:
		cmp  byte ptr [missile_direction], DOWN
		jz   SPAWN_FROM_TOP

SPAWN_FROM_BOTTOM:
		; direction UP: row 23, random column
		xor  dx, dx
		mov  cx, 78d
		div  cx
		inc  dx                        ; column 1..78
		mov  ax, 23d * screen_width
		add  ax, dx
		jmp  SPAWN_STORE

SPAWN_FROM_TOP:
		; direction DOWN: row 1, random column
		xor  dx, dx
		mov  cx, 78d
		div  cx
		inc  dx                        ; column 1..78
		mov  ax, 1d * screen_width
		add  ax, dx
		jmp  SPAWN_STORE

SPAWN_FROM_LEFT:
		; direction RIGHT: column 1, random row
		xor  dx, dx
		mov  cx, 23d
		div  cx
		inc  dx                        ; row 1..23
		mov  ax, dx
		mov  cx, screen_width
		mul  cx
		add  ax, 1d                    ; column 1
		jmp  SPAWN_STORE

SPAWN_FROM_RIGHT:
		; direction LEFT: column 78, random row
		xor  dx, dx
		mov  cx, 23d
		div  cx
		inc  dx                        ; row 1..23
		mov  ax, dx
		mov  cx, screen_width
		mul  cx
		add  ax, 78d                   ; column 78

SPAWN_STORE:
		shl  ax, 1                     ; cell index -> byte offset
		mov  [missile_location], ax

		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	GENERATE_RANDOM_MISSILE_LOCATION endp

	GENERATE_RANDOM_MISSILE_DIRECTION proc near
		push ax
		push dx
		mov  ah, 0h
		int  1Ah                       ; system timer ticks
		mov  ax, dx
		and  ax, 03h

		cmp  ax, 0h
		jz   SET_DIR_RIGHT
		cmp  ax, 1h
		jz   SET_DIR_LEFT
		cmp  ax, 2h
		jz   SET_DIR_UP

SET_DIR_DOWN:
		mov  byte ptr [missile_direction], DOWN
		jmp  END_GEN_DIR
SET_DIR_UP:
		mov  byte ptr [missile_direction], UP
		jmp  END_GEN_DIR
SET_DIR_LEFT:
		mov  byte ptr [missile_direction], LEFT
		jmp  END_GEN_DIR
SET_DIR_RIGHT:
		mov  byte ptr [missile_direction], RIGHT
END_GEN_DIR:
		pop  dx
		pop  ax
		ret
	GENERATE_RANDOM_MISSILE_DIRECTION endp

	; works out where the 'X' target mark goes, from the missile direction and location
	; formula: target = location + step * min(fuse - 1, max steps for this direction)
	CALC_MISSILE_TARGET proc near
		push ax
		push bx
		push cx
		push dx

		mov  al, [missile_fuse]
		xor  ah, ah
		dec  ax
		mov  cx, ax                        ; cx = steps allowed by the fuse

		cmp  byte ptr [missile_direction], RIGHT
		jnz JFIX_SKIP_20
		jmp  TARGET_RIGHT
JFIX_SKIP_20:
		cmp  byte ptr [missile_direction], LEFT
		jz   TARGET_LEFT
		cmp  byte ptr [missile_direction], UP
		jz   TARGET_UP

TARGET_DOWN:
		mov  bx, missile_max_steps_ver
		mov  dx, screen_width * 2d
		jmp  TARGET_CLAMP
TARGET_UP:
		mov  bx, missile_max_steps_ver
		mov  dx, -(screen_width * 2d)
		jmp  TARGET_CLAMP
TARGET_LEFT:
		mov  bx, missile_max_steps_hor
		mov  dx, -2d
		jmp  TARGET_CLAMP
TARGET_RIGHT:
		mov  bx, missile_max_steps_hor
		mov  dx, 2d

TARGET_CLAMP:
		cmp  cx, bx
		jbe  TARGET_STEPS_OK
		mov  cx, bx                        ; the screen edge stops it before the fuse
TARGET_STEPS_OK:
		mov  ax, cx
		imul dx                            ; ax = steps * step size (low word is enough)
		add  ax, [missile_location]
		mov  [missile_target], ax

		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	CALC_MISSILE_TARGET endp

	DRAW_TARGET_MARK proc near
		push ax
		push bx
		mov  bx, [missile_target]
		mov  al, target_icon
		mov  ah, target_color
		mov  es:[bx], ax
		pop  bx
		pop  ax
		ret
	DRAW_TARGET_MARK endp

	INIT_GAME proc near
		mov  byte ptr [player_score], 0h
		mov  byte ptr [snake_direction], RIGHT
		mov  word ptr [snake_previous_last_cell], screen_width * screen_height * 2d
		mov  word ptr [food_location], 8d * screen_width * 2d + 10d * 2d
		mov  byte ptr [EXIT], 0h
		mov  byte ptr [START_AGAIN], 0h
		mov  byte ptr [missile_state], 0h   ; so a missile doesn't carry over to the next game
		mov  byte ptr [missile_timer], 0h

		; fruit state is reset too, so nothing carries over after a restart
		mov  byte ptr [immunity_active], 0h
		mov  byte ptr [immunity_timer], 0h
		mov  word ptr [immunity_food_location], 0FFFFh
		mov  word ptr [shrink_food_location], 0FFFFh

		call INIT_SCREEN
		call INIT_SNAKE_BODY

		; empty the rock table first (it still holds the last game's rocks after
		; a restart); the rocks themselves are placed last, around everything else
		call CLEAR_ROCKS
		call GENERATE_RANDOM_IMMUNITY_LOCATION
		call DRAW_IMMUNITY_FOOD
		call GENERATE_RANDOM_SHRINK_FOOD
		call DRAW_SHRINK_FOOD
		call GENERATE_RANDOM_ROCKS
		call DRAW_ROCKS

		ret
	INIT_GAME endp

	; game over if the head's position matches any body cell
	CHECK_SNAKE_NOOSE proc near
		push si
		push ax

		; an immune snake can pass through its own body
		cmp  byte ptr [immunity_active], 1h
		jz   END_CHECK_SNAKE_NOOSE

		mov  ax, snake_body[0h]
		mov  si, 2h
CHECK_SNAKE_NOOSE_LOOP:
		cmp  ax, snake_body[si]
		jz   CHECK_SNAKE_NOOSE_GAME_OVER
		add  si, 2h
		cmp  si, snake_len
		jnz  CHECK_SNAKE_NOOSE_LOOP

		jmp  END_CHECK_SNAKE_NOOSE

CHECK_SNAKE_NOOSE_GAME_OVER:
		call GAME_OVER

END_CHECK_SNAKE_NOOSE:
		pop  ax
		pop  si
		ret
	CHECK_SNAKE_NOOSE endp

	; only checks the south edge; east/west are handled by wraparound math
	CHECK_SNAKE_IN_BORDERS proc near
		push ax
		mov  ax, snake_body[0h]
		cmp  ax, screen_width * screen_height * 2h
		jb   CHECK_SNAKE_IN_BORDERS_VALID

		call GAME_OVER

CHECK_SNAKE_IN_BORDERS_VALID:
		pop  ax
		ret
	CHECK_SNAKE_IN_BORDERS endp

	CHECK_SNAKE_AET_FOOD proc near
		push ax
		push si
		mov  ax, snake_body[0h]
		cmp  ax, food_location
		jz JFIX_SKIP_21
		jmp  END_CHECK_SNAKE_AET_FOOD
JFIX_SKIP_21:

		call GENERATE_RANDOM_FOOD_LOCATION
		; draw new food
		mov  si, [food_location]
		mov  al, food_icon
		mov  ah, food_color
		mov  es:[si], ax
		; grow the snake by one cell at the old tail position
		mov  ax, [snake_previous_last_cell]
		mov  si, [snake_len]
		mov  snake_body[si], ax
		add  [snake_len], 2d
		; score
		inc  byte ptr [player_score]
		call PRINT_PLAYER_SCORE

		cmp  byte ptr [player_score], player_win_score
		jnz  END_CHECK_SNAKE_AET_FOOD
		call WIN_GAME

END_CHECK_SNAKE_AET_FOOD:
		pop  si
		pop  ax
		ret
	CHECK_SNAKE_AET_FOOD endp

	; ======================= IMMUNITY FRUIT =======================

	; pickup: starts the immunity timer
	CHECK_SNAKE_AET_IMMUNITY_FOOD proc near
		push ax
		mov  ax, snake_body[0h]
		cmp  ax, immunity_food_location
		jnz  END_CHECK_IMMUNITY_FOOD

		mov  byte ptr [immunity_active], 1h
		mov  byte ptr [immunity_timer], immunity_duration
		; move the fruit "off the map" so it can't be eaten twice
		mov  word ptr [immunity_food_location], 0FFFFh

END_CHECK_IMMUNITY_FOOD:
		pop  ax
		ret
	CHECK_SNAKE_AET_IMMUNITY_FOOD endp

	; counts the immunity down; when it runs out a new fruit appears
	UPDATE_IMMUNITY proc near
		cmp  byte ptr [immunity_active], 1h
		jnz  END_UPDATE_IMMUNITY
		dec  byte ptr [immunity_timer]
		jnz  END_UPDATE_IMMUNITY
		mov  byte ptr [immunity_active], 0h
		call GENERATE_RANDOM_IMMUNITY_LOCATION
		call DRAW_IMMUNITY_FOOD
END_UPDATE_IMMUNITY:
		ret
	UPDATE_IMMUNITY endp

	; picks a random cell for the immunity fruit
	; (not on the snake, the red food, the shortening fruit or a rock)
	GENERATE_RANDOM_IMMUNITY_LOCATION proc near
		push ax
		push cx
		push dx
		push si
GEN_IMMUNITY_AGAIN:
		; same random trick as the red food: use the clock ticks as a seed
		mov  ah, 0h
		int  1Ah
		mov  ax, dx
		mov  dx, cx
		add  dx, [snake_len]
		add  dx, [snake_len]
		mov  cx, screen_width * screen_height * 2h - food_bounders
		div  cx
		and  dx, 0FFFEh
		add  dx, food_bounders / 2d

		cmp  dx, [food_location]
		jz   GEN_IMMUNITY_AGAIN
		cmp  dx, [shrink_food_location]
		jnz JFIX_SKIP_22
		jmp  GEN_IMMUNITY_AGAIN
JFIX_SKIP_22:
		call CELL_HAS_ROCK
		jnc JFIX_SKIP_23
		jmp  GEN_IMMUNITY_AGAIN
JFIX_SKIP_23:

		; retry if it landed on the snake
		mov  si, 0d
GEN_IMMUNITY_LOOP:
		mov  ax, snake_body[si]
		cmp  dx, ax
		jnz JFIX_SKIP_24
		jmp  GEN_IMMUNITY_AGAIN
JFIX_SKIP_24:
		add  si, 2d
		cmp  si, [snake_len]
		jnz  GEN_IMMUNITY_LOOP

		mov  [immunity_food_location], dx

		pop  si
		pop  dx
		pop  cx
		pop  ax
		ret
	GENERATE_RANDOM_IMMUNITY_LOCATION endp

	DRAW_IMMUNITY_FOOD proc near
		push ax
		push si
		mov  si, [immunity_food_location]
		mov  al, immunity_food_icon
		mov  ah, immunity_food_color
		mov  es:[si], ax
		pop  si
		pop  ax
		ret
	DRAW_IMMUNITY_FOOD endp

	; ======================= SHORTENING FRUIT =======================

	CHECK_SNAKE_AET_SHRINK_FOOD proc near
		push ax
		push si

		mov  ax, snake_body[0h]
		cmp  ax, [shrink_food_location]
		jnz  END_CHECK_SNAKE_AET_SHRINK_FOOD

		call SHRINK_SNAKE
		call GENERATE_RANDOM_SHRINK_FOOD

		mov  si, [shrink_food_location]
		mov  al, shrink_food_icon
		mov  ah, shrink_food_color
		mov  es:[si], ax

END_CHECK_SNAKE_AET_SHRINK_FOOD:
		pop  si
		pop  ax
		ret
	CHECK_SNAKE_AET_SHRINK_FOOD endp

	GENERATE_RANDOM_SHRINK_FOOD proc near
		push ax
		push dx
		push si
		push bx
		push cx

GENERATE_RANDOM_SHRINK_RANDOM:
		mov  ah, 00h
		int  1Ah

		mov  ax, dx
		mov  dx, cx
		add  dx, [snake_len]

		; zero-extend player_score before using it in the 16-bit sum
		xor  bx, bx
		mov  bl, [player_score]
		add  dx, bx

		mov  cx, screen_width * screen_height * 2h - food_bounders
		div  cx

		and  dx, 0FFFEh
		add  dx, food_bounders / 2d
		mov  bx, dx
		mov  cx, (screen_width * screen_height) - (food_bounders / 2d)

GENERATE_RANDOM_SHRINK_TRY:
		; never share a cell with the red food, the immunity fruit or a rock
		cmp  bx, [food_location]
		jnz JFIX_SKIP_25
		jmp  GENERATE_RANDOM_SHRINK_NEXT
JFIX_SKIP_25:
		cmp  bx, [immunity_food_location]
		jz   GENERATE_RANDOM_SHRINK_NEXT
		mov  dx, bx
		call CELL_HAS_ROCK
		jc   GENERATE_RANDOM_SHRINK_NEXT

		mov  si, 0h

CHECK_SHRINK_AGAINST_SNAKE:
		cmp  si, [snake_len]
		jb JFIX_SKIP_26
		jmp  GENERATE_RANDOM_SHRINK_FOUND
JFIX_SKIP_26:
		mov  ax, snake_body[si]
		cmp  bx, ax
		jz   GENERATE_RANDOM_SHRINK_NEXT

		add  si, 2h
		jmp  CHECK_SHRINK_AGAINST_SNAKE

GENERATE_RANDOM_SHRINK_NEXT:
		add  bx, 2d
		cmp  bx, screen_width * screen_height * 2d - food_bounders / 2d
		jb   GENERATE_RANDOM_SHRINK_RETRY
		mov  bx, food_bounders / 2d
GENERATE_RANDOM_SHRINK_RETRY:
		dec  cx
		jz JFIX_SKIP_27
		jmp  GENERATE_RANDOM_SHRINK_TRY
JFIX_SKIP_27:
		jmp  GENERATE_RANDOM_SHRINK_RANDOM

GENERATE_RANDOM_SHRINK_FOUND:
		mov  [shrink_food_location], bx

		pop  cx
		pop  bx
		pop  si
		pop  dx
		pop  ax
		ret
	GENERATE_RANDOM_SHRINK_FOOD endp

	DRAW_SHRINK_FOOD proc near
		push ax
		push si
		mov  si, [shrink_food_location]
		mov  al, shrink_food_icon
		mov  ah, shrink_food_color
		mov  es:[si], ax
		pop  si
		pop  ax
		ret
	DRAW_SHRINK_FOOD endp

	; cuts shrink_amount bytes off the tail, never going below min_snake_len
	SHRINK_SNAKE proc near
		push ax
		push bx
		push si
		push dx
		push di

		mov  ax, [snake_len]
		cmp  ax, min_snake_len
		ja JFIX_SKIP_28
		jmp  SHRINK_SNAKE_DONE
JFIX_SKIP_28:

		mov  bx, ax
		sub  bx, shrink_amount

		cmp  bx, min_snake_len
		jae  SHRINK_SNAKE_ERASE
		mov  bx, min_snake_len

SHRINK_SNAKE_ERASE:
		mov  si, bx

SHRINK_SNAKE_ERASE_LOOP:
		cmp  si, [snake_len]
		jae  SHRINK_SNAKE_SAVE

		mov  dx, snake_body[si]
		mov  al, ' '
		mov  ah, background_color
		mov  di, dx
		mov  es:[di], ax

		add  si, 2d
		jmp  SHRINK_SNAKE_ERASE_LOOP

SHRINK_SNAKE_SAVE:
		mov  [snake_len], bx

SHRINK_SNAKE_DONE:
		pop  di
		pop  dx
		pop  si
		pop  bx
		pop  ax
		ret
	SHRINK_SNAKE endp

	; ======================= ROCKS =======================

	CLEAR_ROCKS proc near
		push si
		mov  si, 0d
CLEAR_ROCKS_LOOP:
		mov  word ptr rock_locations[si], rock_none
		add  si, 2d
		cmp  si, num_rocks * 2d
		jnz  CLEAR_ROCKS_LOOP
		pop  si
		ret
	CLEAR_ROCKS endp

	; in: dx = video-buffer cell offset.  out: carry set if a rock sits there
	CELL_HAS_ROCK proc near
		push si
		mov  si, 0d
CELL_HAS_ROCK_LOOP:
		cmp  dx, rock_locations[si]
		jz   CELL_HAS_ROCK_YES
		add  si, 2d
		cmp  si, num_rocks * 2d
		jnz  CELL_HAS_ROCK_LOOP
		clc
		pop  si
		ret
CELL_HAS_ROCK_YES:
		stc
		pop  si
		ret
	CELL_HAS_ROCK endp

	; places num_rocks rocks on free cells: not on the snake, the red food,
	; either fruit, the starting lane, or each other
	GENERATE_RANDOM_ROCKS proc near
		push ax
		push cx
		push dx
		push si
		push bx
		push di

		mov  di, 0d
GEN_ROCK_NEXT:
		cmp  di, num_rocks * 2d
		jnz JFIX_SKIP_29
		jmp  END_GEN_ROCKS
JFIX_SKIP_29:
GEN_ROCK_AGAIN:
		mov  ah, 0h
		int  1Ah
		mov  ax, dx
		mov  dx, cx
		add  dx, di                        ; offset seed per rock
		mov  cx, screen_width * screen_height * 2h - food_bounders
		div  cx
		and  dx, 0FFFEh
		add  dx, food_bounders / 2d

		cmp  dx, [food_location]
		jz   GEN_ROCK_AGAIN
		cmp  dx, [immunity_food_location]
		jz   GEN_ROCK_AGAIN
		cmp  dx, [shrink_food_location]
		jnz JFIX_SKIP_30
		jmp  GEN_ROCK_AGAIN
JFIX_SKIP_30:

		; keep the snake's starting lane clear
		cmp  dx, start_lane_begin
		jb   GEN_ROCK_LANE_OK
		cmp  dx, start_lane_end
		jae JFIX_SKIP_31
		jmp  GEN_ROCK_AGAIN
JFIX_SKIP_31:
GEN_ROCK_LANE_OK:

		mov  si, 0d
GEN_ROCK_SNAKE_LOOP:
		mov  ax, snake_body[si]
		cmp  dx, ax
		jnz JFIX_SKIP_32
		jmp  GEN_ROCK_AGAIN
JFIX_SKIP_32:
		add  si, 2d
		cmp  si, [snake_len]
		jnz  GEN_ROCK_SNAKE_LOOP

		; check overlap with the rocks placed so far
		mov  si, 0d
GEN_ROCK_PREV_LOOP:
		cmp  si, di
		jz   GEN_ROCK_PLACE
		mov  ax, rock_locations[si]
		cmp  dx, ax
		jnz JFIX_SKIP_33
		jmp  GEN_ROCK_AGAIN
JFIX_SKIP_33:
		add  si, 2d
		jmp  GEN_ROCK_PREV_LOOP

GEN_ROCK_PLACE:
		mov  rock_locations[di], dx
		add  di, 2d
		jmp  GEN_ROCK_NEXT

END_GEN_ROCKS:
		pop  di
		pop  bx
		pop  si
		pop  dx
		pop  cx
		pop  ax
		ret
	GENERATE_RANDOM_ROCKS endp

	DRAW_ROCKS proc near
		push ax
		push si
		push bx

		mov  si, 0d
DRAW_ROCKS_LOOP:
		mov  bx, rock_locations[si]
		mov  al, rock_icon
		mov  ah, rock_color
		mov  es:[bx], ax
		add  si, 2d
		cmp  si, num_rocks * 2d
		jnz  DRAW_ROCKS_LOOP

		pop  bx
		pop  si
		pop  ax
		ret
	DRAW_ROCKS endp

	; hitting a rock ends the game, unless the snake is immune
	CHECK_SNAKE_ROCK_COLLISION proc near
		push ax
		push si

		cmp  byte ptr [immunity_active], 1h
		jz   END_CHECK_ROCK_COLLISION

		mov  ax, snake_body[0h]
		mov  si, 0d
CHECK_ROCK_LOOP:
		cmp  ax, rock_locations[si]
		jz   ROCK_COLLISION_GAME_OVER
		add  si, 2d
		cmp  si, num_rocks * 2d
		jnz  CHECK_ROCK_LOOP

		jmp  END_CHECK_ROCK_COLLISION

ROCK_COLLISION_GAME_OVER:
		call GAME_OVER

END_CHECK_ROCK_COLLISION:
		pop  si
		pop  ax
		ret
	CHECK_SNAKE_ROCK_COLLISION endp

	; redraws every pickup (and the rocks) each frame. the missile and explosion erase cells
	; as they pass, so without this a fruit could vanish from the screen while
	; still being on the map. fruits that are off the map (0FFFFh) are skipped.
	REDRAW_PICKUPS proc near
		push ax
		push si

		mov  si, [food_location]
		mov  al, food_icon
		mov  ah, food_color
		mov  es:[si], ax

		cmp  word ptr [immunity_food_location], 0FFFFh
		jz   REDRAW_SKIP_IMMUNITY
		call DRAW_IMMUNITY_FOOD
REDRAW_SKIP_IMMUNITY:
		cmp  word ptr [shrink_food_location], 0FFFFh
		jz   REDRAW_SKIP_SHRINK
		call DRAW_SHRINK_FOOD
REDRAW_SKIP_SHRINK:
		call DRAW_ROCKS
		pop  si
		pop  ax
		ret
	REDRAW_PICKUPS endp

	GENERATE_RANDOM_FOOD_LOCATION proc near
		push ax
		push dx
		push si
		push bx
GENERATE_RANDOM_FOOD_LOCATION_AGAIN:
		; use the system clock tick count as a pseudo-random seed
		mov  ah, 0h
		int  1Ah
		mov  ax, dx
		mov  dx, cx
		add  dx, [snake_len]
		add  dx, [snake_len]
		; 16-bit divide: dx:ax / cx -> ax = quotient, dx = remainder
		mov  cx, screen_width * screen_height * 2h - food_bounders
		div  cx
		; force to an even offset (video cells are 2 bytes each)
		and  dx, 0FFFEh
		add  dx, food_bounders / 2d
		; retry if it lands on either fruit or a rock
		cmp  dx, [immunity_food_location]
		jz   GENERATE_RANDOM_FOOD_LOCATION_AGAIN
		cmp  dx, [shrink_food_location]
		jnz JFIX_SKIP_34
		jmp  GENERATE_RANDOM_FOOD_LOCATION_AGAIN
JFIX_SKIP_34:
		call CELL_HAS_ROCK
		jnc JFIX_SKIP_35
		jmp  GENERATE_RANDOM_FOOD_LOCATION_AGAIN
JFIX_SKIP_35:
		; retry if the new spot lands on the snake's body
		mov  si, 0d
GENERATE_RANDOM_FOOD_LOCATION_AGAIN_LOOP:
		mov  ax, snake_body[si]
		cmp  dx, ax
		jnz JFIX_SKIP_36
		jmp  GENERATE_RANDOM_FOOD_LOCATION_AGAIN
JFIX_SKIP_36:
		add  si, 2d
		cmp  si, [snake_len]
		jnz  GENERATE_RANDOM_FOOD_LOCATION_AGAIN_LOOP

		mov  [food_location], dx

		pop  bx
		pop  si
		pop  dx
		pop  ax
		ret
	GENERATE_RANDOM_FOOD_LOCATION endp

	; speeds the game up as the score climbs
	MAIN_LOOP_FRAME_RATE proc near
		push ax
		push cx
		push dx
		push bx

		mov  bx, 0h
		mov  bl, [player_score]
		mov  cl, 4d
		shr  bx, cl
		; BIOS delay in cx:dx microseconds
		mov  al, 0
		mov  ah, 86h
		mov  cx, 0000h
		mov  dx, 0FFFFh
		sub  dx, bx
		int  15h

		pop  bx
		pop  dx
		pop  cx
		pop  ax
		ret
	MAIN_LOOP_FRAME_RATE endp

	; shared end screen for death and win: name entry, then leaderboard,
	; then SPACE (play again) or ESC (exit). the title comes from [end_title].
	END_SCREEN proc near
		push ax
		push bx
		push cx
		push dx
		push si
		push di

		; several checks can fire in the same frame; only the first one counts
		cmp  byte ptr [EXIT], 1h
		jnz  END_SCREEN_FIRST
		jmp  END_END_SCREEN
END_SCREEN_FIRST:
		mov  byte ptr [EXIT], 1h

		; ---- step 1: ask for the player's name ----
		call DRAW_PANEL

		mov  ah, panel_title_color
		mov  dx, row_title
		mov  si, [end_title]
		call PRINT_CENTERED

		mov  al, [player_score]
		mov  di, offset score_line + 7d
		call BYTE_TO_DEC3
		mov  ah, panel_color
		mov  dx, row_score
		mov  si, offset score_line
		call PRINT_CENTERED

		mov  dx, row_prompt
		mov  si, offset txt_enter_name
		call PRINT_CENTERED
		mov  dx, row_hint1
		mov  si, offset txt_hint1
		call PRINT_CENTERED
		mov  dx, row_hint2
		mov  si, offset txt_hint2
		call PRINT_CENTERED
		mov  dx, row_hint3
		mov  si, offset txt_hint3
		call PRINT_CENTERED

		call ENTER_NAME
		jc   END_SCREEN_SKIP_SAVE          ; esc: show the board without saving
		call ADD_SCORE
END_SCREEN_SKIP_SAVE:

		; ---- step 2: leaderboard ----
		call DRAW_PANEL
		mov  ah, panel_title_color
		mov  dx, row_title
		mov  si, offset txt_leaderboard
		call PRINT_CENTERED
		call DRAW_LEADERBOARD_ROWS
		mov  ah, panel_color
		mov  dx, row_footer
		mov  si, offset txt_footer_dead
		call PRINT_CENTERED

		mov  ax, 0C00h                     ; flush stray keys
		int  21h
END_SCREEN_GET_KEY:
		mov  ah, 0h
		int  16h

		cmp  ah, END_GAME_KEY
		jz   END_END_SCREEN

		cmp  ah, START_AGAIN_KEY
		jz   END_SCREEN_START_AGAIN

		jmp  END_SCREEN_GET_KEY

END_SCREEN_START_AGAIN:
		mov  [START_AGAIN], 1h

END_END_SCREEN:
		mov  ax, 0C00h
		int  21h

		pop  di
		pop  si
		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	END_SCREEN endp

	; death: every existing "call GAME_OVER" keeps working
	GAME_OVER proc near
		mov  word ptr [end_title], offset txt_game_over
		call END_SCREEN
		ret
	GAME_OVER endp

	; win: same name entry and leaderboard, different title
	WIN_GAME proc near
		mov  word ptr [end_title], offset txt_you_win
		call END_SCREEN
		ret
	WIN_GAME endp

	; ======================= LEADERBOARD / PAUSE =======================

	; freezes the game and shows the leaderboard until P (resume) or ESC (quit)
	PAUSE_GAME proc near
		push ax
		push dx
		push si

		call SAVE_PANEL
		call DRAW_PANEL

		mov  ah, panel_title_color
		mov  dx, row_pause_title
		mov  si, offset txt_paused
		call PRINT_CENTERED
		mov  dx, row_title
		mov  si, offset txt_leaderboard
		call PRINT_CENTERED
		call DRAW_LEADERBOARD_ROWS
		mov  ah, panel_color
		mov  dx, row_footer
		mov  si, offset txt_footer_pause
		call PRINT_CENTERED

PAUSE_WAIT_KEY:
		mov  ah, 0h
		int  16h
		cmp  ah, PAUSE_KEY
		jz   PAUSE_RESUME
		cmp  ah, END_GAME_KEY
		jnz  PAUSE_WAIT_KEY
		mov  byte ptr [EXIT], 1h

PAUSE_RESUME:
		call RESTORE_PANEL                 ; put the game cells back
		mov  ax, 0C00h                     ; flush keys pressed while paused
		int  21h

		pop  si
		pop  dx
		pop  ax
		ret
	PAUSE_GAME endp

	; lets the player type a name: up/down change the letter (blank, A-Z),
	; left/right move between the 5 slots, enter confirms.
	; out: name_buf holds the name; carry set if the player pressed esc
	ENTER_NAME proc near
		push ax
		push bx
		push si

		mov  byte ptr [name_buf + 0], 'A'
		mov  byte ptr [name_buf + 1], ' '
		mov  byte ptr [name_buf + 2], ' '
		mov  byte ptr [name_buf + 3], ' '
		mov  byte ptr [name_buf + 4], ' '
		mov  byte ptr [name_pos], 0h
		mov  ax, 0C00h                     ; ignore arrows pressed during the game
		int  21h

EN_DRAW:
		call DRAW_NAME_SLOTS
EN_KEY:
		mov  ah, 0h
		int  16h
		cmp  ah, ENTER_KEY
		jnz JFIX_SKIP_37
		jmp  EN_DONE
JFIX_SKIP_37:
		cmp  ah, END_GAME_KEY
		jnz JFIX_SKIP_38
		jmp  EN_SKIP
JFIX_SKIP_38:
		cmp  ah, UP
		jz   EN_UP
		cmp  ah, DOWN
		jnz JFIX_SKIP_39
		jmp  EN_DOWN
JFIX_SKIP_39:
		cmp  ah, LEFT
		jnz JFIX_SKIP_40
		jmp  EN_LEFT
JFIX_SKIP_40:
		cmp  ah, RIGHT
		jnz JFIX_SKIP_41
		jmp  EN_RIGHT
JFIX_SKIP_41:
		jmp  EN_KEY

EN_UP:
		mov  bx, 0h
		mov  bl, [name_pos]
		mov  al, name_buf[bx]
		cmp  al, ' '
		jz   EN_UP_FROM_BLANK
		cmp  al, 'Z'
		jz   EN_UP_TO_BLANK
		inc  al
		jmp  EN_STORE
EN_UP_FROM_BLANK:
		mov  al, 'A'
		jmp  EN_STORE
EN_UP_TO_BLANK:
		mov  al, ' '
		jmp  EN_STORE

EN_DOWN:
		mov  bx, 0h
		mov  bl, [name_pos]
		mov  al, name_buf[bx]
		cmp  al, ' '
		jz   EN_DOWN_FROM_BLANK
		cmp  al, 'A'
		jz   EN_DOWN_TO_BLANK
		dec  al
		jmp  EN_STORE
EN_DOWN_FROM_BLANK:
		mov  al, 'Z'
		jmp  EN_STORE
EN_DOWN_TO_BLANK:
		mov  al, ' '

EN_STORE:
		mov  name_buf[bx], al
		jmp  EN_DRAW

EN_LEFT:
		cmp  byte ptr [name_pos], 0h
		jnz JFIX_SKIP_42
		jmp  EN_DRAW
JFIX_SKIP_42:
		dec  byte ptr [name_pos]
		jmp  EN_DRAW

EN_RIGHT:
		cmp  byte ptr [name_pos], name_len_max - 1d
		jb JFIX_SKIP_43
		jmp  EN_DRAW
JFIX_SKIP_43:
		inc  byte ptr [name_pos]
		jmp  EN_DRAW

EN_DONE:
		; an all-blank name becomes "ANON"
		mov  si, 0h
EN_CHECK_BLANK:
		cmp  name_buf[si], ' '
		jnz  EN_NAME_OK
		inc  si
		cmp  si, name_len_max
		jnz  EN_CHECK_BLANK
		mov  byte ptr [name_buf + 0], 'A'
		mov  byte ptr [name_buf + 1], 'N'
		mov  byte ptr [name_buf + 2], 'O'
		mov  byte ptr [name_buf + 3], 'N'
EN_NAME_OK:
		clc
		jmp  EN_END
EN_SKIP:
		stc
EN_END:
		pop  si
		pop  bx
		pop  ax
		ret
	ENTER_NAME endp

	; draws "[A][ ][ ][ ][ ]" with the selected letter highlighted
	DRAW_NAME_SLOTS proc near
		push ax
		push bx
		push si
		push di

		mov  di, name_slots_origin
		mov  si, 0h
		mov  bx, 0h
		mov  bl, [name_pos]
DNS_LOOP:
		mov  ah, panel_bracket_color
		mov  al, '['
		mov  es:[di], ax

		mov  al, name_buf[si]
		mov  ah, panel_color
		cmp  bx, si
		jnz  DNS_PUT_LETTER
		mov  ah, panel_select_color
DNS_PUT_LETTER:
		mov  es:[di + 2d], ax

		mov  ah, panel_bracket_color
		mov  al, ']'
		mov  es:[di + 4d], ax

		add  di, 6d
		inc  si
		cmp  si, name_len_max
		jz JFIX_SKIP_44
		jmp  DNS_LOOP
JFIX_SKIP_44:

		pop  di
		pop  si
		pop  bx
		pop  ax
		ret
	DRAW_NAME_SLOTS endp

	; stores the finished run (name_buf + player_score). when the board is
	; full the oldest run is dropped to make room.
	ADD_SCORE proc near
		push ax
		push bx
		push si

		cmp  byte ptr [lb_count], max_scores
		jae JFIX_SKIP_45
		jmp  AS_APPEND
JFIX_SKIP_45:

		; full: slide everything one slot toward the front (drops the oldest)
		mov  si, name_len_max
AS_SHIFT_NAMES:
		mov  al, lb_names[si]
		mov  lb_names[si - name_len_max], al
		inc  si
		cmp  si, max_scores * name_len_max
		jnz  AS_SHIFT_NAMES
		mov  si, 1h
AS_SHIFT_SCORES:
		mov  al, lb_scores[si]
		mov  lb_scores[si - 1d], al
		inc  si
		cmp  si, max_scores
		jnz  AS_SHIFT_SCORES
		mov  bl, max_scores - 1d           ; new run goes into the last slot
		jmp  AS_STORE

AS_APPEND:
		mov  bl, [lb_count]
		inc  byte ptr [lb_count]

AS_STORE:
		mov  bh, 0h
		mov  al, [player_score]
		mov  lb_scores[bx], al

		; name offset = slot * 5
		mov  ax, bx
		shl  ax, 1
		shl  ax, 1
		add  ax, bx
		mov  bx, ax
		mov  si, 0h
AS_COPY_NAME:
		mov  al, name_buf[si]
		mov  lb_names[bx + si], al
		inc  si
		cmp  si, name_len_max
		jnz  AS_COPY_NAME

		pop  si
		pop  bx
		pop  ax
		ret
	ADD_SCORE endp

	; fills lb_order with the slot numbers sorted by score, highest first
	; (equal scores keep the order they were played in)
	SORT_LEADERBOARD proc near
		push ax
		push bx
		push cx
		push dx
		push si
		push di

		mov  cx, 0h
		mov  cl, [lb_count]
		cmp  cx, 0h
		jnz JFIX_SKIP_46
		jmp  SORT_DONE
JFIX_SKIP_46:

		mov  si, 0h
SORT_INIT:
		mov  ax, si
		mov  lb_order[si], al
		inc  si
		cmp  si, cx
		jb   SORT_INIT

		mov  dx, cx                        ; number of bubble passes
SORT_PASS:
		mov  si, 0h
SORT_INNER:
		mov  ax, si
		inc  ax
		cmp  ax, cx
		jb JFIX_SKIP_47
		jmp  SORT_PASS_END
JFIX_SKIP_47:

		mov  bl, lb_order[si]
		mov  bh, 0h
		mov  al, lb_scores[bx]             ; score of the entry in front
		mov  di, si
		mov  bl, lb_order[di + 1d]
		mov  bh, 0h
		mov  ah, lb_scores[bx]             ; score of the entry behind it
		cmp  al, ah
		jae  SORT_NO_SWAP

		mov  bl, lb_order[si]
		mov  bh, lb_order[di + 1d]
		mov  lb_order[si], bh
		mov  lb_order[di + 1d], bl
SORT_NO_SWAP:
		inc  si
		jmp  SORT_INNER
SORT_PASS_END:
		dec  dx
		jz JFIX_SKIP_48
		jmp  SORT_PASS
JFIX_SKIP_48:

SORT_DONE:
		pop  di
		pop  si
		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	SORT_LEADERBOARD endp

	; draws the 5 leaderboard lines ("1. NAME   123"); free slots show dashes
	DRAW_LEADERBOARD_ROWS proc near
		push ax
		push bx
		push cx
		push dx
		push si
		push di

		call SORT_LEADERBOARD

		mov  cx, 0h                        ; rank - 1
DLR_LOOP:
		mov  al, cl
		add  al, '1'
		mov  lb_row_buf[0], al

		cmp  cl, [lb_count]
		jb JFIX_SKIP_49
		jmp  DLR_EMPTY
JFIX_SKIP_49:

		; slot = lb_order[rank]
		mov  si, cx
		mov  bl, lb_order[si]
		mov  bh, 0h

		; name = lb_names[slot * 5 .. slot * 5 + 4]
		mov  ax, bx
		shl  ax, 1
		shl  ax, 1
		add  ax, bx
		mov  si, ax
		mov  di, 0h
DLR_COPY_NAME:
		mov  al, lb_names[si]
		mov  lb_row_buf[di + 3d], al
		inc  si
		inc  di
		cmp  di, name_len_max
		jnz  DLR_COPY_NAME

		mov  al, lb_scores[bx]
		mov  di, offset lb_row_buf + 10d
		call BYTE_TO_DEC3
		jmp  DLR_PRINT

DLR_EMPTY:
		mov  di, 0h
DLR_DASH_NAME:
		mov  lb_row_buf[di + 3d], '-'
		inc  di
		cmp  di, name_len_max
		jnz  DLR_DASH_NAME
		mov  lb_row_buf[10], '-'
		mov  lb_row_buf[11], '-'
		mov  lb_row_buf[12], '-'

DLR_PRINT:
		mov  ax, cx
		mov  dx, screen_width * 2d
		mul  dx                            ; ax = rank * one text row
		add  ax, row_lb_first
		mov  dx, ax
		mov  ah, panel_color
		cmp  cl, 0h
		jnz  DLR_ATTR_SET
		mov  ah, panel_title_color         ; highlight the top score
DLR_ATTR_SET:
		mov  si, offset lb_row_buf
		call PRINT_CENTERED

		inc  cx
		cmp  cx, max_scores
		jz JFIX_SKIP_50
		jmp  DLR_LOOP
JFIX_SKIP_50:

		pop  di
		pop  si
		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	DRAW_LEADERBOARD_ROWS endp

	; in: al = 0..255, di -> 3 bytes of text to fill with decimal digits
	BYTE_TO_DEC3 proc near
		push ax
		push bx
		push di

		mov  ah, 0h
		mov  bl, 100d
		div  bl                            ; al = hundreds, ah = remainder
		add  al, '0'
		mov  [di], al
		inc  di

		mov  al, ah
		mov  ah, 0h
		mov  bl, 10d
		div  bl                            ; al = tens, ah = ones
		add  al, '0'
		mov  [di], al
		inc  di

		add  ah, '0'
		mov  [di], ah

		pop  di
		pop  bx
		pop  ax
		ret
	BYTE_TO_DEC3 endp

	; prints a 0-terminated string centred inside the panel
	; in: ds:si = string, dx = byte offset of the start of the screen row,
	;     ah = attribute
	PRINT_CENTERED proc near
		push ax
		push bx
		push cx
		push dx
		push si
		push di

		mov  [pc_attr], ah

		; cx = string length
		mov  bx, si
		mov  cx, 0h
PC_LEN:
		cmp  byte ptr [bx], 0h
		jz   PC_LEN_DONE
		inc  bx
		inc  cx
		jmp  PC_LEN
PC_LEN_DONE:
		; column = panel_col + (panel_w - length) / 2
		mov  bx, panel_w
		sub  bx, cx
		shr  bx, 1
		add  bx, panel_col
		shl  bx, 1                         ; cells are 2 bytes
		mov  di, dx
		add  di, bx

		mov  ah, [pc_attr]
		cld
PC_PRINT:
		lodsb
		cmp  al, 0h
		jz   PC_DONE
		stosw
		jmp  PC_PRINT
PC_DONE:
		pop  di
		pop  si
		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	PRINT_CENTERED endp

	; clears the panel area and draws its border
	DRAW_PANEL proc near
		push ax
		push bx
		push si
		push di

		mov  di, panel_origin
		mov  bx, 0h                        ; panel row
DP_ROW:
		mov  si, 0h                        ; panel column
		push di
DP_COL:
		mov  al, ' '
		cmp  si, 0h
		jz   DP_SIDE
		cmp  si, panel_w - 1d
		jnz  DP_CHECK_ROW
DP_SIDE:
		mov  al, '|'
DP_CHECK_ROW:
		cmp  bx, 0h
		jz   DP_EDGE_ROW
		cmp  bx, panel_h - 1d
		jnz  DP_PUT
DP_EDGE_ROW:
		mov  al, '-'
		cmp  si, 0h
		jz   DP_CORNER
		cmp  si, panel_w - 1d
		jnz  DP_PUT
DP_CORNER:
		mov  al, '+'
DP_PUT:
		mov  ah, panel_color
		mov  es:[di], ax
		add  di, 2d
		inc  si
		cmp  si, panel_w
		jz JFIX_SKIP_51
		jmp  DP_COL
JFIX_SKIP_51:

		pop  di
		add  di, screen_width * 2d
		inc  bx
		cmp  bx, panel_h
		jz JFIX_SKIP_52
		jmp  DP_ROW
JFIX_SKIP_52:

		pop  di
		pop  si
		pop  bx
		pop  ax
		ret
	DRAW_PANEL endp

	; remembers what is on screen under the panel (used while paused)
	SAVE_PANEL proc near
		push ax
		push bx
		push cx
		push dx
		push di

		mov  bx, panel_origin
		mov  di, 0h
		mov  dx, panel_h
SAVE_PANEL_ROW:
		mov  cx, panel_w
		push bx
SAVE_PANEL_COL:
		mov  ax, es:[bx]
		mov  panel_save_buf[di], ax
		add  bx, 2d
		add  di, 2d
		loop SAVE_PANEL_COL
		pop  bx
		add  bx, screen_width * 2d
		dec  dx
		jnz  SAVE_PANEL_ROW

		pop  di
		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	SAVE_PANEL endp

	; puts back the cells SAVE_PANEL remembered
	RESTORE_PANEL proc near
		push ax
		push bx
		push cx
		push dx
		push di

		mov  bx, panel_origin
		mov  di, 0h
		mov  dx, panel_h
RESTORE_PANEL_ROW:
		mov  cx, panel_w
		push bx
RESTORE_PANEL_COL:
		mov  ax, panel_save_buf[di]
		mov  es:[bx], ax
		add  bx, 2d
		add  di, 2d
		loop RESTORE_PANEL_COL
		pop  bx
		add  bx, screen_width * 2d
		dec  dx
		jnz  RESTORE_PANEL_ROW

		pop  di
		pop  dx
		pop  cx
		pop  bx
		pop  ax
		ret
	RESTORE_PANEL endp

	MOVE_SNAKE proc near
		push ax
		push bx
		; remember the tail's current cell so PRINT_SNAKE can erase it
		mov  bx, snake_len
		mov  ax, snake_body[bx - 2d]
		mov  [snake_previous_last_cell], ax

		mov  ax, snake_body[0h]
		call SHR_ARRAY
		cmp  byte ptr [snake_direction], RIGHT
		jz   MOVE_RIGHT
		cmp  byte ptr [snake_direction], LEFT
		jz   MOVE_LEFT
		cmp  byte ptr [snake_direction], UP
		jz   MOVE_UP
		cmp  byte ptr [snake_direction], DOWN
		jz   MOVE_DOWN

MOVE_RIGHT:
		add  ax, 2d
		jmp  MOVE_TO_DIRECTION
MOVE_LEFT:
		sub  ax, 2d
		jmp  MOVE_TO_DIRECTION
MOVE_UP:
		sub  ax, screen_width * 2d
		jmp  MOVE_TO_DIRECTION
MOVE_DOWN:
		add  ax, screen_width * 2d
		jmp  MOVE_TO_DIRECTION

MOVE_TO_DIRECTION:
		mov  snake_body[0h], ax

		pop  bx
		pop  ax
		ret
	MOVE_SNAKE endp

	PRINT_SNAKE proc near
		push ax
		push si
		push bx
		push cx
		push dx
		; erase the old tail cell (blank space, background color)
		mov  bx, [snake_previous_last_cell]
		mov  al, ' '
		mov  ah, background_color
		mov  es:[bx], ax

		; if the snake was crossing a rock (immunity), put the rock back
		mov  si, 0d
PRINT_SNAKE_ROCK_LOOP:
		cmp  bx, rock_locations[si]
		jnz  PRINT_SNAKE_ROCK_NEXT
		mov  al, rock_icon
		mov  ah, rock_color
		mov  es:[bx], ax
		jmp  PRINT_SNAKE_ROCK_DONE
PRINT_SNAKE_ROCK_NEXT:
		add  si, 2d
		cmp  si, num_rocks * 2d
		jnz  PRINT_SNAKE_ROCK_LOOP
PRINT_SNAKE_ROCK_DONE:

		; cx = how many bytes of snake_body (head first) still wear the
		; immunity colour. cells = ceil(timer * cells_in_snake / duration),
		; so the tint shrinks from the tail toward the head as the timer
		; runs out. cx = 0 when immunity is off.
		mov  cx, 0h
		cmp  byte ptr [immunity_active], 1h
		jnz  PRINT_SNAKE_COLOR_READY
		mov  ax, [snake_len]
		shr  ax, 1                         ; cells in the snake
		mov  bl, [immunity_timer]
		xor  bh, bh
		mul  bx                            ; dx:ax = cells * timer (fits in 16 bits)
		add  ax, immunity_duration - 1d    ; round up
		mov  bx, immunity_duration
		xor  dx, dx
		div  bx                            ; ax = coloured cells
		shl  ax, 1                         ; cells -> byte offset limit
		mov  cx, ax
PRINT_SNAKE_COLOR_READY:

		; TEMP DESIGN: head glyph/attribute
		mov  al, snake_head_icon
		mov  ah, snake_head_color
		cmp  cx, 0h
		jz   PRINT_SNAKE_HEAD_DRAW
		mov  ah, immune_head_color
PRINT_SNAKE_HEAD_DRAW:
		mov  bx, snake_body[0d]
		mov  es:[bx], ax

		cmp  snake_len, 2h
		jz   END_PRINT_SNAKE

		; TEMP DESIGN: body glyph/attribute (immune colour while si < cx)
		mov  al, snake_body_icon

		mov  si, 2h
PRINT_SNAKE_LOOP:
		mov  ah, snake_body_color
		cmp  si, cx
		jae  PRINT_SNAKE_BODY_DRAW
		mov  ah, immune_body_color
PRINT_SNAKE_BODY_DRAW:
		mov  bx, snake_body[si]
		mov  es:[bx], ax
		add  si, 2h
		cmp  si, [snake_len]
		jnz  PRINT_SNAKE_LOOP

END_PRINT_SNAKE:
		pop  dx
		pop  cx
		pop  bx
		pop  si
		pop  ax
		ret
	PRINT_SNAKE endp

	; draws the score label at the bottom-right corner. the label text is
	; written right to left, so the stores below run backwards.
	PRINT_PLAYER_SCORE proc near
		push ax
		push bx
		mov  ah, player_score_color

		mov  bx, 0h
		mov  bl, [player_score]
		; low digit
		mov  al, ascii[bx + 256d]
		mov  es:[player_score_label_offset], ax
		; high digit
		mov  al, ascii[bx]
		mov  es:[player_score_label_offset - 2d], ax

		mov  al, ':'
		mov  es:[player_score_label_offset - 4d], ax

		mov  al, 'E'
		mov  es:[player_score_label_offset - 6d], ax

		mov  al, 'R'
		mov  es:[player_score_label_offset - 8d], ax

		mov  al, 'O'
		mov  es:[player_score_label_offset - 10d], ax

		mov  al, 'C'
		mov  es:[player_score_label_offset - 12d], ax

		mov  al, 'S'
		mov  es:[player_score_label_offset - 14d], ax

		pop  bx
		pop  ax
		ret
	PRINT_PLAYER_SCORE endp

	INIT_SCREEN proc near
		push ax
		push cx
		push si
		; graphics mode
		mov  ah, 00h
		mov  al, 13h
		int  10h
		; video segment
		mov  ax, 0b800h
		mov  es, ax
		; clear screen
		mov  ax, 03h
		int  10h
		call WRITE_SCREEN_BACKGROUND
		call PRINT_PLAYER_SCORE
		; draw the first food
		mov  si, [food_location]
		mov  al, food_icon
		mov  ah, food_color
		mov  es:[si], ax

		mov  dx, offset msg_start_game
		mov  ah, 9h
		int  21h

		pop  si
		pop  cx
		pop  ax
		ret
	INIT_SCREEN endp

	WRITE_SCREEN_BACKGROUND proc near
		push si
		push ax
		mov  al, 0h
		mov  ah, background_color
		mov  si, 0
INIT_BACKGROUND_LOOP:
		mov  es:[si], ax
		add  si, 2d
		cmp  si, 25d * 80d * 2d
		jnz  INIT_BACKGROUND_LOOP

		pop  ax
		pop  si
		ret
	WRITE_SCREEN_BACKGROUND endp

	INIT_SCREEN_BACK_TO_OS proc near
		push ax
		push cx
		mov  ax, 03h
		int  10h
		mov  ah, 03h
		mov  al, 13h
		int  10h

		pop  cx
		pop  ax
		ret
	INIT_SCREEN_BACK_TO_OS endp

	; starting body: 4 cells in a row, head pointing right
	INIT_SNAKE_BODY proc near
		mov word ptr snake_body[6d], 4d + 3d * screen_width * 2d
		mov word ptr snake_body[4d], 6d + 3d * screen_width * 2d
		mov word ptr snake_body[2d], 8d + 3d * screen_width * 2d
		mov word ptr snake_body[0d], 10d + 3d * screen_width * 2d
		mov word ptr [snake_len], 8d

		ret
	INIT_SNAKE_BODY endp

	; reads a key if one is waiting: esc sets EXIT, P pauses, and an arrow
	; key that is not a reversal updates snake_direction. with no key
	; pressed the direction is left unchanged.
	GET_DIRECTION_BY_KEY proc near
		push ax
		push bx
		mov  ax, 0h
		mov  ah, 01h
		int  16h

		jnz JFIX_SKIP_53
		jmp  END_GET_DIRECTION_BY_KEY
JFIX_SKIP_53:
		cmp  ah, END_GAME_KEY
		jnz JFIX_SKIP_54
		jmp  GET_DIRECTION_BY_KEY_EXIT_GAME_IS_ON
JFIX_SKIP_54:
		cmp  ah, PAUSE_KEY
		jnz JFIX_SKIP_55
		jmp  GET_DIRECTION_BY_KEY_PAUSE
JFIX_SKIP_55:

		; only perpendicular turns are accepted: the scan codes of two
		; perpendicular arrows differ by 3 or 5, a reversal differs by 2 or 8
		mov  bh, ah
		mov  bl, [snake_direction]
		sub  bh, bl
		cmp  bh, 3d
		jnz JFIX_SKIP_56
		jmp  GET_DIRECTION_BY_KEY_VALID_MOVE
JFIX_SKIP_56:
		cmp  bh, 5d
		jnz JFIX_SKIP_57
		jmp  GET_DIRECTION_BY_KEY_VALID_MOVE
JFIX_SKIP_57:
		neg  bh
		cmp  bh, 3d
		jz   GET_DIRECTION_BY_KEY_VALID_MOVE
		cmp  bh, 5d
		jz   GET_DIRECTION_BY_KEY_VALID_MOVE
		; reversal or unrelated key: ignore it
		mov  ah, 0Ch
		int  21h
		jmp  END_GET_DIRECTION_BY_KEY

GET_DIRECTION_BY_KEY_PAUSE:
		mov  ax, 0C00h                    ; drop the 'P' from the key buffer
		int  21h
		call PAUSE_GAME
		jmp  END_GET_DIRECTION_BY_KEY

GET_DIRECTION_BY_KEY_VALID_MOVE:
		mov  [snake_direction], ah
		mov  ah, 0Ch
		int  21h
		jmp  END_GET_DIRECTION_BY_KEY

GET_DIRECTION_BY_KEY_EXIT_GAME_IS_ON:
		mov  byte ptr [EXIT], 1h
		mov  ah, 0Ch
		int  21h

END_GET_DIRECTION_BY_KEY:
		pop  bx
		pop  ax
		ret
	GET_DIRECTION_BY_KEY endp

	; shifts every cell one slot toward the tail, freeing slot 0 for the new head
	SHR_ARRAY proc near
		push bx
		push ax
		push si

		mov  si, [snake_len]
		sub  si, 2h
L1:
		mov  ax, snake_body[si - 2h]
		mov  snake_body[si], ax
		sub  si, 2h
		cmp  si, 0h
		jnz  L1

		pop  si
		pop  ax
		pop  bx
		ret
	SHR_ARRAY endp

	end MAIN