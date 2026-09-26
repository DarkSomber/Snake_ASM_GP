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
	player_win_score equ 0FFh    ; score needed to win

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

	; ---- game state ----
	EXIT db 0h
	START_AGAIN db 0h
	START_AGAIN_KEY equ 39h  ; spacebar
	END_GAME_KEY equ 01h     ; esc

	; ---- TEMP DESIGN: copy/messages ----
	msg_game_over  db 'GAME OVER. PRESS ESC TO EXIT', 0Ah, 0Dh, '$'
	msg_game_over2 db '            PRESS SPACE TO START AGAIN', 0Ah, 0Dh, '$'
	msg_game_win   db 'YOU WIN! PRESS ANY KEY TO EXIT', 0Ah, 0Dh, '$'
	msg_start_game db 'WELCOME TO SNAKE. PRESS ESC TO QUIT.', 0Ah, 0Dh, '$'

	; lookup table used to convert the score byte into two ASCII digits
	; (hex nibble -> ASCII char, low nibble table then high nibble table)
	ascii db 16 dup ('0')
	db 16 dup ('1')
	db 16 dup ('2')
	db 16 dup ('3')
	db 16 dup ('4')
	db 16 dup ('5')
	db 16 dup ('6')
	db 16 dup ('7')
	db 16 dup ('8')
	db 16 dup ('9')
	db 16 dup ('A')
	db 16 dup ('B')
	db 16 dup ('C')
	db 16 dup ('D')
	db 16 dup ('E')
	db 16 dup ('F')
	db 16 dup ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F')
.code
MAIN:
	mov ax, @data
	mov ds, ax

	call INIT_GAME

	MAIN_LOOP:
		call MOVE_SNAKE
		call PRINT_SNAKE

		call CHECK_SNAKE_AET_FOOD
		call CHECK_SNAKE_IN_BORDERS
		call CHECK_SNAKE_NOOSE

		call GET_DIRECTION_BY_KEY
		call MAIN_LOOP_FRAME_RATE

		cmp [EXIT], 1h
		jnz MAIN_LOOP

	cmp [START_AGAIN], 1h
	jz MAIN

	call INIT_SCREEN_BACK_TO_OS
	mov ah, 4ch
	int 21h

INIT_GAME proc near
	mov byte ptr [player_score], 0h
	mov byte ptr [snake_direction], RIGHT
	mov word ptr [snake_previous_last_cell], screen_width * screen_height * 2d
	mov word ptr [food_location], 8d * screen_width * 2d + 10d * 2d
	mov byte ptr [EXIT], 0h
	mov byte ptr [START_AGAIN], 0h

	call INIT_SCREEN
	call INIT_SNAKE_BODY

	ret
INIT_GAME endp

; game over if the head's position matches any body cell
CHECK_SNAKE_NOOSE proc near
	push si
	push ax

	mov ax, snake_body[0h]
	mov si, 2h
	CHECK_SNAKE_NOOSE_LOOP:
		cmp ax, snake_body[si]
		jz CHECK_SNAKE_NOOSE_GAME_OVER
		add si, 2h
		cmp si, snake_len
		jnz CHECK_SNAKE_NOOSE_LOOP

	jmp END_CHECK_SNAKE_NOOSE

CHECK_SNAKE_NOOSE_GAME_OVER:
	call GAME_OVER

END_CHECK_SNAKE_NOOSE:
	pop ax
	pop si
	ret
CHECK_SNAKE_NOOSE endp

; only checks the south edge for now; east/west are handled by wraparound math
CHECK_SNAKE_IN_BORDERS proc near
	push ax
	mov ax, snake_body[0h]
	cmp ax, screen_width * screen_height * 2h
	jb CHECK_SNAKE_IN_BORDERS_VALID

	call GAME_OVER

CHECK_SNAKE_IN_BORDERS_VALID:
	pop ax
	ret
CHECK_SNAKE_IN_BORDERS endp

CHECK_SNAKE_AET_FOOD proc near
	push ax
	push si
	mov ax, snake_body[0h]
	cmp ax, food_location
	jnz END_CHECK_SNAKE_AET_FOOD

	call GENERATE_RANDOM_FOOD_LOCATION
	; draw new food
	mov si, [food_location]
	mov al, food_icon
	mov ah, food_color
	mov es:[si], ax
	; grow the snake by one cell at the old tail position
	mov ax, [snake_previous_last_cell]
	mov si, [snake_len]
	mov snake_body[si], ax
	add [snake_len], 2d
	; score
	inc byte ptr [player_score]
	call PRINT_PLAYER_SCORE

	cmp byte ptr [player_score], player_win_score
	jnz END_CHECK_SNAKE_AET_FOOD
	call WIN_GAME

END_CHECK_SNAKE_AET_FOOD:
	pop si
	pop ax
	ret
CHECK_SNAKE_AET_FOOD endp

GENERATE_RANDOM_FOOD_LOCATION proc near
	push ax
	push dx
	push si
	push bx
GENERATE_RANDOM_FOOD_LOCATION_AGAIN:
	; use the system clock tick count as a pseudo-random seed
	mov ah, 0h
	int 1Ah
	mov ax, dx
	mov dx, cx
	add dx, [snake_len]
	add dx, [snake_len]
	; 16-bit divide: dx:ax / cx -> ax = quotient, dx = remainder
	mov cx, screen_width * screen_height * 2h - food_bounders
	div cx
	; force to an even offset (video cells are 2 bytes each)
	and dx, 0FFFEh
	add dx, food_bounders / 2d
	; retry if the new spot lands on the snake's body
	mov si, 0d
	GENERATE_RANDOM_FOOD_LOCATION_AGAIN_LOOP:
		mov ax, snake_body[si]
		cmp dx, ax
		jz GENERATE_RANDOM_FOOD_LOCATION_AGAIN
		add si, 2d
		cmp si, [snake_len]
		jnz GENERATE_RANDOM_FOOD_LOCATION_AGAIN_LOOP

	mov [food_location], dx

	pop bx
	pop si
	pop dx
	pop ax
	ret
GENERATE_RANDOM_FOOD_LOCATION endp

; speeds the game up as the score climbs
MAIN_LOOP_FRAME_RATE proc near
	push ax
	push cx
	push dx
	push bx

	mov bx, 0h
	mov bl, [player_score]
	mov cl, 4d
	shr bx, cl
	; BIOS delay in cx:dx microseconds
	mov al, 0
	mov ah, 86h
	mov cx, 0000h
	mov dx, 0FFFFh
	sub dx, bx
	int 15h

	; pop order mirrors the push order above (ax,cx,dx,bx pushed,
	; so bx,dx,cx,ax popped) to keep the stack balanced
	pop bx
	pop dx
	pop cx
	pop ax
	ret
MAIN_LOOP_FRAME_RATE endp

WIN_GAME proc near
	push dx
	push ax

	mov dx, offset msg_game_win
	mov ah, 9h
	int 21h
	; wait for a keypress
	mov ax, 0h
	mov ah, 0h
	int 16h
	; clear key buffer
	mov ah, 0Ch
	int 21h

	mov byte ptr [EXIT], 1h

	pop ax
	pop dx
	ret
WIN_GAME endp

GAME_OVER proc near
	push dx
	push ax
	push bx

	mov dx, offset msg_game_over
	mov ah, 9h
	int 21h

	; TEMP DESIGN: blinking bar under the game-over message, made of
	; blank cells with the blink bit (bit 7) set on the attribute byte —
	; replace with the real game-over visual treatment
	mov bx, 0h
	GAME_OVER_BLINK_LABEL:
		mov ax, ' '
		mov ah, background_color
		or ah, 10000000b
		mov es:[bx + 3 * screen_width * 2d], ax
		add bx, 2h
		cmp bx, screen_width * 2d
		jnz GAME_OVER_BLINK_LABEL

	mov dx, offset msg_game_over2
	mov ah, 9h
	int 21h

GAME_OVER_GET_OTHER_KEY:
	mov ah, 0Ch
	int 21h
	mov ax, 0h
	mov ah, 0h
	int 16h

	cmp ah, END_GAME_KEY
	jz END_GAME_OVER

	cmp ah, START_AGAIN_KEY
	jz GAME_OVER_START_AGAIN

	jmp GAME_OVER_GET_OTHER_KEY

GAME_OVER_START_AGAIN:
	mov [START_AGAIN], 1h

END_GAME_OVER:
	mov ah, 0Ch
	int 21h

	mov byte ptr [EXIT], 1h

	pop bx
	pop ax
	pop dx
	ret
GAME_OVER endp

MOVE_SNAKE proc near
	push ax
	push bx
	; remember the tail's current cell so PRINT_SNAKE can erase it
	mov bx, snake_len
	mov ax, snake_body[bx - 2d]
	mov [snake_previous_last_cell], ax

	mov ax, snake_body[0h]
	call SHR_ARRAY
	cmp byte ptr [snake_direction], RIGHT
	jz MOVE_RIGHT
	cmp byte ptr [snake_direction], LEFT
	jz MOVE_LEFT
	cmp byte ptr [snake_direction], UP
	jz MOVE_UP
	cmp byte ptr [snake_direction], DOWN
	jz MOVE_DOWN

	MOVE_RIGHT:
		add ax, 2d
		jmp MOVE_TO_DIRECTION
	MOVE_LEFT:
		sub ax, 2d
		jmp MOVE_TO_DIRECTION
	MOVE_UP:
		sub ax, screen_width * 2d
		jmp MOVE_TO_DIRECTION
	MOVE_DOWN:
		add ax, screen_width * 2d
		jmp MOVE_TO_DIRECTION

MOVE_TO_DIRECTION:
	mov snake_body[0h], ax

	pop bx
	pop ax
	ret
MOVE_SNAKE endp

PRINT_SNAKE proc near
	push ax
	push si
	push bx
	; erase the old tail cell (blank space, background color)
	mov bx, [snake_previous_last_cell]
	mov al, ' '
	mov ah, background_color
	mov es:[bx], ax

	; TEMP DESIGN: head glyph/attribute
	mov al, snake_head_icon
	mov ah, snake_head_color
	mov bx, snake_body[0d]
	mov es:[bx], ax

	cmp snake_len, 2h
	jz END_PRINT_SNAKE

	; TEMP DESIGN: body glyph/attribute
	mov al, snake_body_icon
	mov ah, snake_body_color

	mov si, 2h
	PRINT_SNAKE_LOOP:
		mov bx, snake_body[si]
		mov es:[bx], ax
		add si, 2h
		cmp si, [snake_len]
		jnz PRINT_SNAKE_LOOP

END_PRINT_SNAKE:
	pop bx
	pop si
	pop ax
	ret
PRINT_SNAKE endp

; renders the score as "SCORE:XX" using the ascii lookup table
PRINT_PLAYER_SCORE proc near
	push ax
	push bx
	mov ah, player_score_color

	mov bx, 0h
	mov bl, [player_score]
	; low nibble digit
	mov al, ascii[bx + 256d]
	mov es:[player_score_label_offset], ax
	; high nibble digit
	mov al, ascii[bx]
	mov es:[player_score_label_offset - 2d], ax

	mov al, ':'
	mov es:[player_score_label_offset - 4d], ax

	mov al, 'E'
	mov es:[player_score_label_offset - 6d], ax

	mov al, 'R'
	mov es:[player_score_label_offset - 8d], ax

	mov al, 'O'
	mov es:[player_score_label_offset - 10d], ax

	mov al, 'C'
	mov es:[player_score_label_offset - 12d], ax

	mov al, 'S'
	mov es:[player_score_label_offset - 14d], ax

	pop bx
	pop ax
	ret
PRINT_PLAYER_SCORE endp

INIT_SCREEN proc near
	push ax
	push cx
	push si
	; graphics mode
	mov ah, 00h
	mov al, 13h
	int 10h
	; video segment
	mov ax, 0b800h
	mov es, ax
	; clear screen
	mov ax, 03h
	int 10h
	call WRITE_SCREEN_BACKGROUND
	call PRINT_PLAYER_SCORE
	; draw the first food
	mov si, [food_location]
	mov al, food_icon
	mov ah, food_color
	mov es:[si], ax

	mov dx, offset msg_start_game
	mov ah, 9h
	int 21h

	pop si
	pop cx
	pop ax
	ret
INIT_SCREEN endp

WRITE_SCREEN_BACKGROUND proc near
	push si
	push ax
	mov al, 0h
	mov ah, background_color
	mov si, 0
INIT_BACKGROUND_LOOP:
	mov es:[si], ax
	add si, 2d
	cmp si, 25d * 80d * 2d
	jnz INIT_BACKGROUND_LOOP

	pop ax
	pop si
	ret
WRITE_SCREEN_BACKGROUND endp

INIT_SCREEN_BACK_TO_OS proc near
	push ax
	push cx
	mov ax, 03h
	int 10h
	mov ah, 03h
	mov al, 13h
	int 10h

	pop cx
	pop ax
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

; reads a key if one is waiting and updates snake_direction.
; esc sets EXIT; if no key was pressed, direction is left unchanged.
GET_DIRECTION_BY_KEY proc near
	push ax
	push bx
	mov ax, 0h
	mov ah, 01h
	int 16h

	jz END_GET_DIRECTION_BY_KEY
	cmp ah, END_GAME_KEY
	jz GET_DIRECTION_BY_KEY_EXIT_GAME_IS_ON

	; a move is only valid if it's not a direct reversal;
	; |new - old| == 3 or 5 identifies the perpendicular/forward moves
	mov bh, ah
	mov bl, [snake_direction]
	sub bh, bl
	cmp bh, 3d
	jz GET_DIRECTION_BY_KEY_VALID_MOVE
	cmp bh, 5d
	jz GET_DIRECTION_BY_KEY_VALID_MOVE
	neg bh
	cmp bh, 3d
	jz GET_DIRECTION_BY_KEY_VALID_MOVE
	cmp bh, 5d
	jz GET_DIRECTION_BY_KEY_VALID_MOVE
	; invalid move, ignore it
	mov ah, 0Ch
	int 21h
	jmp END_GET_DIRECTION_BY_KEY

GET_DIRECTION_BY_KEY_VALID_MOVE:
	mov [snake_direction], ah
	mov ah, 0Ch
	int 21h
	jmp END_GET_DIRECTION_BY_KEY

GET_DIRECTION_BY_KEY_EXIT_GAME_IS_ON:
	mov byte ptr [EXIT], 1h
	mov ah, 0Ch
	int 21h

END_GET_DIRECTION_BY_KEY:
	pop bx
	pop ax
	ret
GET_DIRECTION_BY_KEY endp

; shifts every cell one slot toward the tail, freeing slot 0 for the new head
SHR_ARRAY proc near
	push bx
	push ax
	push si

	mov si, [snake_len]
	sub si, 2h
	L1:
		mov ax, snake_body[si - 2h]
		mov snake_body[si], ax
		sub si, 2h
		cmp si, 0h
		jnz L1

	pop si
	pop ax
	pop bx
	ret
SHR_ARRAY endp

end MAIN