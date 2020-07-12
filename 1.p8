pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- object kinds 0 player, 1 orange, 2 golden, 
-- 		  		3 spikes, 4 flag

-- globals
k_left = 0
k_right = 1
k_up = 2
k_down = 3
k_jump = 4
k_special = 5

flag_wall = 0
flag_finish_line = 1
flag_solesand = 2

c_black = 0
c_dark_blue = 1
c_purple = 2
c_dark_green = 3
c_brown = 4
c_dark_grey = 5
c_grey = 6
c_white = 7
c_red = 8
c_orange = 9
c_yellow = 10
c_green = 11
c_blue = 12
c_violet = 13
c_pink = 14
c_tan = 15

player_sprite = 2
orange_spawn_sprite = 4 --orange dot
golden_spawn_sprite = 20--yellow dot
spike_sprite1 = 32 		--is also spawn sprite
spike_sprite2 = 48 		--is also spawn sprite
checkpoint_sprite = 16 	--is also spawn sprite
current_checkpoint_sprite = 17

orange_sprite = 5
golden_sprite = 21

map_x = 0
map_y = 0

one_sec = 1/30 -- 30 frames/sec

grv = 0.2

-- 0,1,2,3,4 spring,desert,fall,winter,moon
world = {}
	world.cur = 0
	world[0] = {}
		world[0].play_music  = function()
			music(0)
		end


		world[0].background = 12
		world[0].map_x = 0
		world[0].map_y = 0
		world[0].sx = 20
		world[0].sy = 20
	world[1] = {}
		world[1].play_music  = function()
			music(9)
		end

		world[1].background = 5
		world[1].map_x = 16
		world[1].map_y = 32
		world[1].sx = 56
		world[1].sy = 40
	world[2] = {}
		world[2].map_x = 64
		world[2].map_y = 32
		world[2].sx = 16
		world[2].sy = 56
	world[3] = {}
		world[3].map_x = 96
		world[3].map_y = 0
		world[3].sx = 104
		world[3].sy = 110
	world[4] = {}
		world[4].map_x = 112
		world[4].map_y = 16 
		world[4].sx = 104
		world[4].sy = 110

function _init()
	_update = title_update
	_draw = title_draw
end

function start_game()
	object = {}
	time = 0
	time_sec = 0
	total_deaths = 0
	total_orange = 0
	total_golden = 0

	background_col = world[world.cur].background
	world[world.cur].play_music()

	for mx=0,127 do for my=0,63 do
		local new_obj = nil
		local rx = mx-(mx%16) -- which room map position's in
		local ry = my-(my%16)
		local sx = (mx%16) * 8 -- where object is on screen,
		local sy = (my%16) * 8 -- relative to room

		-- find all objects in map
		local spr = mget(mx,my)

		if spr == player_sprite then
			new_obj = make_player(sx, sy, rx, ry)
			mset(mx,my,0)
		elseif spr == orange_spawn_sprite then
			new_obj = make_orange_carrot(sx, sy, rx, ry)
		elseif spr == golden_spawn_sprite then
			new_obj = make_golden_carrot(sx, sy, rx, ry)
		elseif spr == spike_sprite1 or 
			   spr == spike_sprite2 then
			new_obj = make_spike(spr, sx, sy, rx, ry)
		elseif spr == checkpoint_sprite then
			new_obj = make_checkpoint(sx, sy, rx, ry)
		end

		if new_obj ~= nil then
			add(object, new_obj)
		end
	end end
	_update = game_update
	_draw = game_draw
end

-- move player to last checkpoint
function restart_game()
	-- find active flag
	total_deaths += 1
	local flag = nil
	for o in all(object) do
		if o.kind == 4 and o.active then
			flag = o
		end
	end

	-- if no current checkpoint, reset entire game
	-- otherwise, move player to last checkpoint
	if flag == nil then
		_init()
	else
		for o in all(object) do
			if o.kind == 0 then
				map_x = flag.room.x	
				map_y = flag.room.y	
				o.x = flag.x
				o.y = flag.y
				break
			end
		end
	end
end

-- move to new world
function world_complete()
	world.cur += 1
	if world.cur > 1 then -- TODO
		game_win()
	else
		for o in all(object) do
			if o.kind == 0 then
				map_x = world[world.cur].map_x
				map_y = world[world.cur].map_y
				o.x = world[world.cur].sx
				o.y = world[world.cur].sy
				o.orange = 0
				break
			end
		end
		world[world.cur].play_music()
		background_col = world[world.cur].background
	end
end

function game_win()
	local i=0
	while i < 128 do
		rectfill(0,0,128,i)
		i += 1
	end
	music(7,300)
	_update = win_update
	_draw = win_draw
end

function title_update()
	if btn(k_special) and btn(k_jump) then
		start_game()
	end
end

function title_draw()
	cls()
	pal(c_pink, c_dark_green)
	rectfill(0,0,127,127,12)
	color(7)
	print("~ press x+c ~", 35, 70)
	spr(38,70,10,2,2)
	map(0,32,0,0,32,32)
end

function game_update()
	time += 1
	if time >= 2000 then time = 0 end --avoid overflow
	time_sec = min(time_sec + one_sec, 9999)

	for o in all(object) do
		o:update()
	end
end

function game_draw()
	cls()
	palt(0,true)
	rectfill(0,0,127,127,background_col)
	map(map_x,map_y,0,0,32,32)

	for o in all(object) do
		if o.room.x == map_x and
		   o.room.y == map_y then
			o:draw()
			if o.kind == 0 then --findplayer for debug reasons
				player = o
			end
		end
	end
end

function win_update()
end

function win_draw()
	cls()
	rectfill(0,0,127,127,0)

	local msg = {}
	msg[0] = 'you win!'
	msg[1] = 'stats:'
	msg[2] = 'time: '..flr(time_sec)
	msg[3] = 'deaths: '..total_deaths
	msg[4] = '   x '..total_orange
	msg[5] = '   x '..total_golden..'/6'

	rect(127/4,0,127*3/4,16*#msg,7)

	for i=0,1 do
		print(msg[i], 64-#msg[i]*2, 10+10*i, 10-(i*3))
	end

	for i=2,#msg do
		print(msg[i], 36, 10+10*i, 7)
		print(msg[i], 36, 10+10*i, 7)
		print(msg[i], 36, 10+10*i, 7)
		print(msg[i], 36, 10+10*i, 7)
	end

	spr(orange_sprite, 36, 10+10*4)
	spr(golden_sprite, 36, 10+10*5)

end









