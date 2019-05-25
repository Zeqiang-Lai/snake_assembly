.386
.model flat, stdcall
option casemap:none

include		masm32rt.inc

WALL_MAX_X	EQU	50
WALL_MAX_Y	EQU 20
MAX_LEN		EQU 100		; max length of snake

DEFAULT_SPEED		EQU 120
DEFAULT_DIR			EQU 'd'
DEFAULT_LAST_DIR	EQU 's'
DEFAULT_LEN			EQU 3

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

.data
b_wall			byte	'#'
b_snake			byte	'*'
b_snake_empty	byte	' '
b_snake_real	byte	'*'
b_food			byte	'$'

snake_x			dd	MAX_LEN dup(0)
snake_y			dd	MAX_LEN dup(0)
snake_len		dd	DEFAULT_LEN	; length of snake.
snake_x_init	dd	3,4,5
snake_y_init	dd	3,3,3

next_head_x		dd	?	
next_head_y		dd	?	

food_x	dd	1
food_y	dd	14

dir			dd	DEFAULT_DIR		; direction, key pressed(WASD).
last_dir	dd	DEFAULT_LAST_DIR
speed		dd	DEFAULT_SPEED	; speed of snake, one move in 'speed' ms.

game_over	db	FALSE
game_pause	db	FALSE
game_quit	db	FALSE

msg_game_over	byte	"Game over", 0

key			dd	?				; store the current pressed key.
hOutPut DWORD ?
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

draw_wall	proc
	pusha
	mov ecx, WALL_MAX_X
draw_top_bottom:
	push ecx
	invoke locate, ecx, 0
	pop ecx
	invoke print_wall
	push ecx
	invoke locate, ecx, WALL_MAX_Y
	pop ecx
	invoke print_wall
loop draw_top_bottom

	mov ecx, WALL_MAX_Y
draw_left_right:
	push ecx
	invoke locate, 0, ecx
	pop ecx
	invoke print_wall
	push ecx
	invoke locate, WALL_MAX_X, ecx
	pop ecx
	invoke print_wall
loop draw_left_right
	popa
	ret
draw_wall	endp

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

; TODO:
compute_food_loc proc
; the location of food should not be outside the wall.
	inc food_x
	ret
compute_food_loc endp

init_console	proc
	pusha
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
	invoke compute_food_loc
	invoke draw_food
init_food	endp

init_setting proc
	mov dir,		DEFAULT_DIR
	mov last_dir,	DEFAULT_LAST_DIR
	mov speed,		DEFAULT_SPEED
	mov game_over,	FALSE
	mov game_pause,	FALSE
	ret
init_setting endp

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
	invoke draw_wall
	invoke draw_snake
	ret
show_main_screen	endp

show_game_over_screen proc
	cls
	invoke locate, 30, 15
	print "Game over", 13, 10
	ret
show_game_over_screen endp

show_game_quit_screen proc
	invoke locate, 30, 10
	print "Are you sure you want to quit?", 13, 10
	invoke locate, 35, 11
	print "Yes(y), No(n)", 13, 10
	ret
show_game_quit_screen endp

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
; 4. Do nothing			-- any other key
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
	jmp other
on_dir:
	mov eax, key
	mov dir, eax
	invoke change_dir
	jmp other
on_quit:
	invoke launch_game_quit
other:
	;do nothing
	ret
on_key_pressed	endp

refresh_ui	proc
	invoke draw_snake
	invoke draw_food
	ret
refresh_ui	endp

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
	mov edi, offset snake_x
	mov esi, offset snake_y	

	xor ecx, ecx
L1:
	mov edx, [edi + ecx*4]
	cmp edx, next_head_x
	jne L1_INC
	mov edx, [esi + ecx*4]
	cmp edx, next_head_y
	jne L1_INC
	mov game_over, TRUE
	jmp L1_BREAK
L1_INC:
	inc ecx
	cmp ecx, head
	jne L1
L1_BREAK:

	ret
check_game_over	endp

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

main proc
	invoke init_console
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