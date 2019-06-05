.386
.model flat, stdcall
option casemap:none

include		masm32rt.inc

INFO_ORIGIN_X	EQU 89
INFO_ORIGIN_Y	EQU 0

WALL_MAX_X	EQU	80
WALL_MAX_Y	EQU 29

MAX_LEN		EQU 100		; max length of snake

DEFAULT_DIR			EQU 'd'
DEFAULT_LAST_DIR	EQU 's'
DEFAULT_LEN			EQU 3
DEFAULT_FOOD_X		EQU	20
DEFAULT_FOOD_Y		EQU	3

DEFAULT_SPEED		EQU 125
FASTEST_SPEED		EQU 25
SLOWEST_SPEED		EQU 500
SPEED_INCREMENT		EQU 25

TRUE	EQU	1
FALSE	EQU 0

UP		EQU	'w'		
DOWN	EQU	's'		
LEFT	EQU	'a'		
RIGHT	EQU	'd'		
KPAUSE	EQU	' '
KESC	EQU 27
KYES	EQU 'y'
KNO		EQU	'n'
KFASTER	EQU	'='
KSLOWER	EQU '-'

; map selection 
upper_bound			equ	13
lower_bound			equ	16
start_bound				equ	14

.data
; UI
b_wall			byte	'#'
b_snake			byte	'*'
b_snake_empty	byte	' '
b_snake_real	byte	'*'
b_food			byte	'$'
b_logo			byte	'*'
b_box			byte	'+'

msg_game_over	byte	"Game over", 0
formatD			byte	"%d", 0

; map selection 
optional_map1		byte	'map1',0
optional_map2		byte	'map2',0
optional_map3		byte	'map3',0
select_arrow			byte	'<--',0
clear_str					byte	'        ',0
select_page_title		byte	"Please Select a Map",0		
optional_map_x		dword	56
select_arrow_x			dword	61
optional_map_y		dword	14
map_number			dword	3
map_no					dword	?
control_keyword		dword	?


; map
game_map		db	WALL_MAX_X*WALL_MAX_Y dup(0)
map_x_size		dd	WALL_MAX_X
map_y_size		dd  WALL_MAX_Y

screen_map		db  120*29 dup(0)
screen_x_size	dd	120
screen_y_size	dd	29

; model
snake_x			dd	MAX_LEN dup(0)
snake_y			dd	MAX_LEN dup(0)
snake_len		dd	DEFAULT_LEN	; length of snake.
snake_x_init	dd	3,4,5
snake_y_init	dd	3,3,3

next_head_x		dd	?	
next_head_y		dd	?	

food_x	dd	DEFAULT_FOOD_X
food_y	dd	DEFAULT_FOOD_Y

score	dd	0

dir			dd	DEFAULT_DIR		; direction, key pressed(WASD).
last_dir	dd	DEFAULT_LAST_DIR
speed		dd	DEFAULT_SPEED	; speed of snake, one move in 'speed' ms.

game_over	db	FALSE
game_pause	db	FALSE
game_quit	db	FALSE

; system
map_file		DWORD	?
game_map_path		byte	"maps/map1", 0
welcome_map_path	byte	"UI/welcome", 0
logo_map_path		byte	"UI/logo", 0
info_box_map_path	byte	"UI/info_box", 0
read_mode			byte	"rb", 0

key			dd		?				; store the current pressed key.
hOutPut		DWORD	?
CCI CONSOLE_CURSOR_INFO {}

.code
print_wall proc
	pusha
	invoke crt_putchar, b_wall
	popa
	ret
print_wall endp

print_snake proc
	pusha
	invoke crt_putchar, b_snake
	popa
	ret
print_snake endp

print_food	proc
	pusha
	invoke crt_putchar, b_food
	popa
	ret
print_food	endp

draw_snake	proc
	local tmp_x, tmp_y:dword
	pusha

	mov edi, offset snake_x
	mov esi, offset snake_y
	xor ecx, ecx
L1:
	mov edx, [edi + ecx*4]
	mov tmp_x, edx
	mov edx, [esi + ecx*4]
	mov tmp_y, edx
	pusha
	invoke locate, tmp_x, tmp_y
	popa
	invoke print_snake
	inc ecx
	cmp ecx, snake_len
	jne L1 

	popa
	ret
draw_snake	endp

draw_food	proc
	invoke locate, food_x, food_y
	invoke print_food
	ret
draw_food	endp

draw_score	proc
; we seperate this procedure from draw_info_panel
; to get better performance.
; this procedure will be called from refresh_ui as well.
	invoke locate, INFO_ORIGIN_X+20, INFO_ORIGIN_Y+12
	invoke crt_printf, offset formatD, score
	ret
draw_score	endp

draw_speed	proc
; we seperate this procedure from draw_info_panel
; to get better performance.
; this procedure will be called from refresh_ui as well.
	invoke locate, INFO_ORIGIN_X+20, INFO_ORIGIN_Y+14
	invoke crt_printf, offset formatD, speed
	ret
draw_speed	endp

draw_map	proc	map_array:DWORD, size_x:DWORD, size_y:DWORD, block:BYTE
	mov ebx, map_array
	xor esi, esi
outer_loop:
	xor edi, edi
inner_loop:
	mov eax, esi
	mul size_x
	add eax, ebx
	add eax, edi
	mov dl, [eax]
	cmp dl, 1
	jne l1
	invoke locate, edi, esi
	invoke crt_putchar, block
l1:
	inc edi
	mov eax, size_x
	cmp edi, eax
	jne inner_loop
end_inner:
	inc esi
	mov eax, size_y
	cmp esi, eax
	jne outer_loop
end_outer:
	ret
draw_map	endp

read_map_from_file	proc map_path:DWORD, map_array:DWORD, size_x:DWORD, size_y:DWORD
	pusha
	invoke crt_fopen, map_path, offset read_mode
	mov map_file, eax
	mov eax, size_x
	mul size_y
	invoke crt_fread, map_array, 1, eax, map_file
	popa
	ret
read_map_from_file	endp

draw_info_panel	proc
	pusha
	invoke read_map_from_file, offset logo_map_path, offset screen_map, screen_x_size, screen_y_size
	invoke draw_map, offset screen_map, screen_x_size, screen_y_size, b_logo

	;invoke read_map_from_file, offset info_box_map_path, offset screen_map, screen_x_size, screen_y_size
	;invoke draw_map, offset screen_map, screen_x_size, screen_y_size, b_box

	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+12
	print "Current Score: ", 13, 10
	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+13
	print "Target  Score: ", 13, 10

	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+14
	print "Current Speed: ", 13, 10

	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+20
	print "Control: ", 13, 10
	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+22
	print "ESC:     quit the game", 13, 10
	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+23
	print "Space:  pause the game", 13, 10
	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+24
	print "wasd: movement control", 13, 10
	invoke locate, INFO_ORIGIN_X, INFO_ORIGIN_Y+25
	print "+-:      speed control", 13, 10

	invoke locate, INFO_ORIGIN_X+6, INFO_ORIGIN_Y+28
	print "Made by Ze", 13, 10
	popa
	ret
draw_info_panel endp

clear_snake proc
	push edx
	mov dl, b_snake_empty
	mov b_snake, dl
	invoke draw_snake
	mov dl, b_snake_real
	mov b_snake, dl
	pop edx
	ret
clear_snake endp

refresh_food_ordinate proc
;refresh food_x,food_y
	local _st:SYSTEMTIME
	pusha
	l1:
	invoke GetSystemTime ,addr _st
	movzx eax, SYSTEMTIME.wMilliseconds[_st]
	invoke crt_srand,eax
	invoke crt_rand
	and eax,0FFh
	cmp eax,WALL_MAX_X
	jge l1
	mov food_x,eax
	l2:
	invoke GetSystemTime ,addr _st
	movzx eax, SYSTEMTIME.wMilliseconds[_st]
	invoke crt_srand,eax
	invoke crt_rand
	and eax,0FFh
	cmp eax,WALL_MAX_Y
	jge l2
	mov food_y,eax
	popa
	ret
refresh_food_ordinate endp

wall_hit_test	proc pos_x:DWORD, pos_y:DWORD
; check will next head hit the wall.
; use next_head_x, next_head_y as cordinates.
; result is store in **eax**, TRUE if hit, otherwise, FALSE
	mov ebx, offset game_map
	mov edi, pos_x
	mov esi, pos_y

	mov eax, esi
	mul map_x_size
	add eax, ebx
	add eax, edi
	mov dl, [eax]

	cmp dl, 1
	jne l2
l1:
	mov eax, TRUE		; hit
	jmp l3	
l2:
	mov eax, FALSE		; not hit
l3:
	ret
wall_hit_test	endp

snake_hit_test	proc pos_x:DWORD, pos_y:DWORD
; check will next head hit the snake itself.
; use next_head_x, next_head_y as cordinates.
; result is store in **eax**, TRUE if hit, otherwise, FALSE
	local head:dword
	mov edx, snake_len
	mov head, edx
	dec head

	; check did snake eat itself?
	mov edi, offset snake_x
	mov esi, offset snake_y	

	mov eax, FALSE
	xor ecx, ecx
L1:
	mov edx, [edi + ecx*4]
	cmp edx, pos_x
	jne L1_INC
	mov edx, [esi + ecx*4]
	cmp edx, pos_y
	jne L1_INC
	mov eax, TRUE
	jmp L1_BREAK
L1_INC:
	inc ecx
	cmp ecx, head
	jne L1
L1_BREAK:
	ret
snake_hit_test	endp

compute_food_loc proc
; the location of food should not be outside the wall.
	pusha
l1:
	invoke refresh_food_ordinate
	invoke snake_hit_test, food_x,food_y
	cmp eax,TRUE
	je l1
	invoke wall_hit_test,food_x,food_y
	cmp eax,TRUE
	je l1
	popa
	ret
compute_food_loc endp

init_console	proc
	pusha
	cls
	SetConsoleCaption "Snake"
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov hOutPut, eax
	;Turn off the cursor
	invoke GetConsoleCursorInfo, hOutPut, ADDR CCI
	mov CCI.bVisible, 0
	invoke SetConsoleCursorInfo, hOutPut, ADDR CCI
	popa
	ret
init_console	endp

init_snake proc
	pusha
	mov snake_len, DEFAULT_LEN

	mov edi, offset snake_x
	mov esi, offset snake_x_init
	xor ecx, ecx
L1:
	mov edx, [esi + ecx*4]
	mov [edi + ecx*4], edx
	inc ecx
	cmp ecx, snake_len
	jne L1 

	mov edi, offset snake_y
	mov esi, offset snake_y_init
	xor ecx, ecx
L2:
	mov edx, [esi + ecx*4]
	mov [edi + ecx*4], edx
	inc ecx
	cmp ecx, snake_len
	jne L2

	popa
	ret
init_snake endp

init_food	proc
	;mov food_x, DEFAULT_FOOD_X
	;mov food_y, DEFAULT_FOOD_Y
	invoke compute_food_loc
	invoke draw_food
init_food	endp

init_setting proc
	mov dir,		DEFAULT_DIR
	mov last_dir,	DEFAULT_LAST_DIR
	mov speed,		DEFAULT_SPEED
	mov game_over,	FALSE
	mov game_pause,	FALSE
	mov score,		0
	ret
init_setting endp

check_game_over	proc
; game would be over, under these situation:
; 1. snake eat itself
; 2. hit the wall(if the wall is solid)
; 3. eat the bad food(future work)[optional]
	
	local head:dword
	pusha

	mov edx, snake_len
	mov head, edx
	dec head

	; check did snake eat itself?
	invoke snake_hit_test, next_head_x, next_head_y
	cmp eax, TRUE
	je L1
	; check did snake hit the wall?
	invoke wall_hit_test, next_head_x, next_head_y
	cmp eax, TRUE
	je L1 
	jmp L2
L1:
	mov game_over, TRUE
L2: 
	ret
check_game_over	endp

compute_next_head proc
	local head:dword
	pusha
	mov edx, snake_len
	mov head, edx
	dec head

	mov edi, offset snake_x
	mov esi, offset snake_y

	mov ecx, head
	mov edx, [edi + ecx*4]
	mov next_head_x, edx
	mov edx, [esi + ecx*4]
	mov next_head_y, edx

	cmp dir, UP
	je up
	cmp dir, LEFT
	je left
	cmp dir, DOWN
	je down
	cmp dir, RIGHT
	je right
up:
	mov ecx, head
	mov edx, [esi + ecx*4]
	dec edx					; y = y-1; x = x;
	cmp edx, 0
	jne up_valid
	mov edx, WALL_MAX_Y-1
up_valid:
	mov next_head_y, edx
	jmp end_move
left:
	mov ecx, head
	mov edx, [edi + ecx*4]
	dec edx					; y = y; x = x-1;
	cmp edx, 0
	jne left_valid
	mov edx, WALL_MAX_X-1
left_valid:
	mov next_head_x, edx
	jmp end_move
down:
	mov ecx, head
	mov edx, [esi + ecx*4]
	inc edx					; y = y+1; x = x;
	cmp edx, WALL_MAX_Y
	jne down_valid
	mov edx, 1
down_valid:
	mov next_head_y, edx
	jmp end_move
right:
	mov ecx, head
	mov edx, [edi + ecx*4]
	inc edx					; y = y; x = x+1;
	cmp edx, WALL_MAX_X
	jne right_valid
	mov edx, 1
right_valid:
	mov next_head_x, edx
	jmp end_move
end_move:
	popa
	ret
compute_next_head endp

compute_next_loc proc
	local head:dword
	pusha 

	mov edx, snake_len
	mov head, edx
	dec head
	
	mov edi, offset snake_x
	mov esi, offset snake_y

	; check does next head encounter food.
	mov ecx, head
	mov edx, next_head_x
	cmp edx, food_x
	jne not_eat
	mov edx, next_head_y
	cmp edx, food_y
	jne not_eat
	jmp ate

not_eat:
	; snake_x[i] = snake_x[i+1]
	xor ecx, ecx
L1:
	mov edx, [edi + ecx*4 + 4]
	mov [edi + ecx*4], edx
	mov edx, [esi + ecx*4 + 4]
	mov [esi + ecx*4], edx
	inc ecx
	cmp ecx, head
	jne L1
L1_done:
	; set head location
	mov edx, next_head_x
	mov [edi + ecx*4], edx
	mov edx, next_head_y
	mov [esi + ecx*4], edx
	jmp end_move
ate:
	; encounter food, 
	; let the food become a part of snake body
	mov ecx, snake_len

	mov edx, food_x
	mov [edi + ecx*4], edx
	mov edx, food_y
	mov [esi + ecx*4], edx

	inc ecx
	mov snake_len, ecx

	inc score
	; genreate new food
	invoke compute_food_loc

end_move:
	popa
	ret
compute_next_loc endp

change_dir	proc
; 1. check whether the current direction is opposite to the past
; if 1 is true, change the direction,
; otherwise, use the last direction.
	push edx

	cmp dir, UP
	je	dir_up
	cmp dir, LEFT
	je	dir_left
	cmp dir, DOWN
	je	dir_down
	cmp dir, RIGHT
	je	dir_right
	; invalid input, this instruction should be impossible to execute.
	jmp false
dir_up:
	cmp last_dir, DOWN
	je	false
	jmp	true
dir_left:
	cmp last_dir, RIGHT
	je	false
	jmp	true
dir_down:
	cmp last_dir, UP
	je	false
	jmp	true
dir_right:
	cmp last_dir, LEFT
	je	false
	jmp	true
false:
	mov edx, last_dir
	mov dir, edx
true:
	pop edx
	ret
change_dir	endp

show_main_screen	proc
	invoke draw_map, offset game_map, map_x_size, map_y_size, b_wall
	invoke draw_snake
	invoke draw_info_panel
	invoke draw_score
	ret
show_main_screen	endp

show_game_over_screen proc
	cls
	invoke locate, 56, 11
	print "GAME OVER", 13, 10
	invoke locate, 48, 12
	print "PRESS ANY KEY TO RESTART", 13, 10
	ret
show_game_over_screen endp

show_game_quit_screen proc
	invoke locate, 45, 10
	print "Are you sure you want to quit?", 13, 10
	invoke locate, 53, 11
	print "Yes(y), No(n)", 13, 10
	ret
show_game_quit_screen endp

show_welcome_screen	proc
	invoke read_map_from_file, offset welcome_map_path, offset screen_map, screen_x_size, screen_y_size
	invoke draw_map, offset screen_map, screen_x_size, screen_y_size, b_wall
	;invoke locate, 55, 11
	;print "SNAKE GAME", 13, 10

	invoke locate, 49, 18
	print "PRESS ANY KEY TO START", 13, 10
	ret
show_welcome_screen	endp

launch_game_quit proc
; used for main screen, to prevent unexpected quit.
	cls
	invoke show_game_quit_screen
	invoke crt__getch
	mov key, eax
	cmp key, KYES
	je yes_quit
	cmp key, KNO
	je resume_game
yes_quit:
	mov game_quit, TRUE
	jmp done
resume_game:
	cls
	invoke show_main_screen
done:
	ret
launch_game_quit endp

on_key_pressed	proc
; Notice: this procedure is only used by **main screen**
; regconize which type of key is pressed. 
; then execute corrsponding route.
; 1. Change direction	-- w,a,s,d
; 2. Quit the game		-- ESC
; 3. Pause the game		-- space
; 4. speed control		-- +-
; 5. Do nothing			-- any other key
	cmp key, UP
	je	on_dir
	cmp key, LEFT
	je	on_dir
	cmp key, DOWN
	je	on_dir
	cmp key, RIGHT
	je	on_dir
	cmp key, KESC
	je on_quit
	cmp key, KFASTER
	je on_faster
	cmp key, KSLOWER
	je on_slower
	jmp other
on_dir:
	mov eax, key
	mov dir, eax
	invoke change_dir
	jmp other
on_quit:
	invoke launch_game_quit
	jmp other
on_faster:
	cmp speed, FASTEST_SPEED
	je other
	sub speed, SPEED_INCREMENT
	jmp other
on_slower:
	cmp speed, SLOWEST_SPEED
	je other
	add speed, SPEED_INCREMENT
other:
	;do nothing
	ret
on_key_pressed	endp

refresh_ui	proc
	invoke draw_snake
	invoke draw_food
	invoke draw_score
	invoke draw_speed
	ret
refresh_ui	endp

start_game	proc
	game_loop:
		invoke crt__kbhit
		test eax, eax
		jz move

	input_key:
		mov eax, dir		; store last direction
		mov last_dir, eax
		invoke crt__getch
		mov key, eax
		invoke on_key_pressed
		cmp game_quit, TRUE
		je end_game

	move:
		invoke compute_next_head

		invoke check_game_over
		cmp game_over, TRUE
		je end_game		

		invoke clear_snake
		invoke compute_next_loc

	update_ui:
		invoke refresh_ui
		invoke Sleep, speed
	jmp game_loop
end_game:
	ret
start_game endp

launch_game	proc
	cls
	invoke init_setting
	invoke init_snake
	invoke init_food
	invoke show_main_screen
	invoke start_game
	ret
launch_game endp

launch_game_over	proc
	invoke show_game_over_screen

	; wait for user input
	; 1.	   ESC:		quit the game
	; 2. Any other:		restart

	invoke crt__getch
	mov key, eax
	cmp key, KESC

	; nothing need to be done here to restart the game
	jne l_done			
	mov game_quit, TRUE
l_done:
	ret
launch_game_over	endp

launch_welcome	proc
	invoke show_welcome_screen
	invoke crt__getch
	mov key, eax
	cmp key, KESC
	jne l_done			
	mov game_quit, TRUE
l_done:
	ret
launch_welcome	endp

launch_map_selection proc
; launch map selection screen and get user selection, 
; store it in map_num.
	cls
	invoke	locate,51,12
	invoke	crt_puts,offset select_page_title
	invoke locate,optional_map_x	,optional_map_y
	invoke	crt_puts,offset optional_map1
	inc		optional_map_y
	invoke locate,optional_map_x,optional_map_y
	invoke	crt_puts,offset optional_map2
	inc		optional_map_y
	invoke locate,optional_map_x	,optional_map_y
	invoke	crt_puts,offset optional_map3
	invoke	locate,select_arrow_x,optional_map_y
	invoke	crt_puts,offset select_arrow
l1:
	invoke	crt__getch
	mov		control_keyword,eax
	cmp		control_keyword,'s'
	je			pointer_down
	cmp		control_keyword,0dh
	jne		l1
	mov		eax,optional_map_y
	sub		eax,upper_bound
	mov		map_no,eax
	ret
pointer_down:
	invoke	locate,select_arrow_x,optional_map_y
	invoke	crt_puts,offset clear_str	
	cmp		optional_map_y,lower_bound
	je			l2
	inc		optional_map_y
	jmp		l3
l2:
	mov		optional_map_y,start_bound
	jmp		l3
l3:
	invoke	locate,select_arrow_x,optional_map_y
	invoke	crt_puts,offset select_arrow
	jmp		l1
	ret
launch_map_selection endp

select_map proc
; this procedure change default map path to selected map path.
; use map_no(dword) as the user selection.
; game_map_path will be modified.
	
	ret
select_map endp

main proc
	invoke init_console
	invoke launch_welcome
	cmp game_quit, TRUE
	je  try_quit
	invoke launch_map_selection
	invoke select_map
	invoke read_map_from_file, offset game_map_path, offset game_map, WALL_MAX_X, WALL_MAX_Y
main_loop:
	invoke launch_game
	cmp game_over, TRUE
	jne try_quit
	invoke launch_game_over
try_quit:
	cmp game_quit, TRUE
	jne main_loop
	ret
main endp
end main