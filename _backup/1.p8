pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- object 0 is player, 1 orange, 2 golden, 
-- 		  3 is lilies,

-- globals
k_left = 0
k_right = 1
k_up = 2
k_down = 3
k_jump = 4
k_special = 5

flag_wall = 0
flag_orange = 1
flag_golden = 2
flag_die = 3

player_spawn_sprite = 1
orange_spawn_sprite = 16
golden_spawn_sprite = 17

map_x = 0
map_y = 0

one_sec = 1/30 -- 30 frames/sec

grv = 0.2

function _init()
	_update = title_update
	_draw = title_draw
end

function start_game()
	object = {}
	time = 0
	time_sec = 0

	for mx=0,127 do for my=0,63 do
		local new_obj = nil
		local rx = mx-(mx%16) -- which room map position's in
		local ry = my-(my%16)
		local sx = (mx%16) * 8 -- where object is on screen,
		local sy = (my%16) * 8 -- relative to room

		-- find all objects in map
		if mget(mx,my) == player_spawn_sprite then
			new_obj = make_player(sx, sy, 7, 7)
		elseif mget(mx,my) == orange_spawn_sprite then
			new_obj = make_object(
				1, orange_spawn_sprite, sx, sy, rx, ry, 7, 7)
		elseif mget(mx,my) == golden_spawn_sprite then
			new_obj = make_object(
				2, golden_spawn_sprite, sx, sy, rx, ry, 7, 7)
		end

		if new_obj ~= nil then
			add(object, new_obj)
		end
		
	end end
	_update = game_update
	_draw = game_draw
end

-- TODO move player to last checkpoint instead
function restart_game()
	start_game()
end

function title_update()
	if btn(k_special) and btn(k_jump) then
		start_game()
	end
end

function title_draw()
	cls()
	rectfill(0,0,127,127,12)
	color(7)
	print("~ press x+c ~", 35, 70)
	spr(35,10,10,2,2)
	map(0,32,0,0,32,32)
end

function game_update()
	time += 1
	if time >= 2000 then time = 0 end --avoid overflow
	time_sec = time_sec + one_sec

	local player -- find player
	for o in all(object) do
		if o.kind == 0 then
			player = o
			player:update()
			break
		end
	end

	for o in all(object) do
		if o.room.x == map_x and
		   o.room.y == map_y then
			collide(player, o)
		end
	end
end

function game_draw()
	cls()
	palt(0,true)
	rectfill(0,0,127,127,15)
	circfill(0,127,50,13)
	circ(0,127,50,2)
	circfill(70,127,50,13)
	circ(70,127,50,2)
	spr(35,10,10,2,2)
	map(map_x,map_y,0,0,32,32)

	-- debug
	print('map: '..map_x..","..map_y)

	for o in all(object) do
		if o.room.x == map_x and
		   o.room.y == map_y then
			o:draw()
		end
	end
end

