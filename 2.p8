pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- makes -- 
-----------
-- generic object init
function make_object(k,s,x,y,rx,ry,w,h)
	local a = {}
	a.kind = k
	a.spr = s -- beginning sprite
	a.x = x
	a.y = y
	a.room = {x = rx, y = ry}
	a.w = w
	a.h = h

	-- default draws and updates
	a.update = function(self)
		-- nothing
	end

	a.draw = function(self)
		spr(self.spr, self.x, self.y)
	end
	return a
end

function make_player(x,y,rx,ry)
	local p = make_object(0,32,x,y,rx,ry,7,7)
	map_x = rx -- put map where player spawns
	map_y = ry

	p.can_move = true
	p.faceLeft = false
	p.orange = 0 -- number of orange carrots collected
	p.golden = 0 -- number of golden carrots collected
	p.move_dir = 0
	p.start_walksp = 0.5
	p.max_walksp = 2
	p.max_walksp_solesand = 1
	p.walksp = 0
	p.hsp = 0
	p.vsp_max_onwall = 2 --to implement TODO
	p.vsp_max = 5
	p.vsp = 0
	p.extra_jump = false -- for when u collect orange carrot
	p.walksp_wjump = 2

	-- timers
	p.jump_key_down = false
	p.jump_key_released = true
	
	p.ground_buffer = 0
	p.ground_buffer_start = 5

	p.jump_buffer = 0
	p.jump_buffer_start = 4

	p.respawn_buffer_start = 15
	p.respawn_buffer = p.respawn_buffer_start

	p.orange_buffer_start = 5
	p.orange_buffer = p.orange_buffer_start

	p.walljumpdelay = 0
	p.walljumpdelay_max = 10

	-- functions
	p.update = function(self)
		if self.can_move then move_player(self) end
		check_room_transition(self) 

		for o in all(object) do 
			if o.room.x == map_x and
			   o.room.y == map_y then
				collide(self, o)
			end
		end

		-- orange count handling
		if (self.orange_buffer == 0) then
			self.orange = max(0, self.orange - 1)
			self.orange_buffer = self.orange_buffer_start
		else
			self.orange_buffer = mid(0, self.orange_buffer - one_sec,
				self.orange_buffer_start)
		end

		-- death handling
		if self.respawn_buffer < self.respawn_buffer_start then
			self.respawn_buffer = max(0, self.respawn_buffer - 1)
			self.can_move = false
		end

		if self.respawn_buffer <= 0 then
			restart_game()
			self.orange = 0
			self.can_move = true
			self.respawn_buffer = self.respawn_buffer_start
		end

		-- finish line handling
		if solid(p.x, p.y, p.w, p.h, flag_finish_line) then
			world_complete()
		end
	end

	p.draw = function(self)
		-- change color
		color(1)
		if p.orange == 0 then
			pal()
		elseif p.orange == 1 then
			pal(c_pink, c_red)
		elseif p.orange == 2 then
			pal(c_pink, c_dark_green)
		elseif p.orange == 3 then
			pal(c_pink, c_blue)
		elseif p.orange == 4 then
			pal(c_pink, c_blue)
			pal(c_grey, c_violet)
		else --if p.orange => 5 then
			pal(c_pink, c_purple)
			pal(c_grey, c_violet)
			pal(c_dark_blue, c_red)
		end

		-- animations
		if self.move_dir == 1 then
			self.faceLeft = false
		elseif self.move_dir == -1 then
			self.faceLeft = true
		end

		if self.is_grounded() then
			-- not moving
			if self.hsp == 0 then 
				self.spr = 2
			-- moving
			elseif time % 5 == 0 then
				if self.spr == 2 then
					self.spr = 3
				else			
					self.spr = 2
				end
			end
		else
			if self.is_onwall_left() then
				self.faceLeft = true
				self.spr = 18
			elseif self.is_onwall_right() then
				self.faceLeft = false
				self.spr = 18
			else
				self.spr = 3
			end
		end

		spr(self.spr,self.x,self.y,1,1,self.faceLeft,false)
		pal()
	end

	p.is_grounded = function()
		return solid(p.x, p.y+1, p.w, p.h, flag_wall) end

	p.is_wall_above = function()
		return solid(p.x, p.y-1, p.w, p.h, flag_wall) end

	p.is_on_solesand = function()
		return solid(p.x, p.y+1, p.w, p.h, flag_solesand) end

	p.is_onwall_right = function()
		return solid(p.x+1, p.y, p.w, p.h, flag_wall) end
	p.is_onwall_left = function()
		return solid(p.x-1, p.y, p.w, p.h, flag_wall) end

	p.get_jumpsp = function()
		if p.orange == 0 or p.is_on_solesand() then
			return -1
		elseif p.orange == 1 then
			return -2
		elseif p.orange == 2 then
			return -2.7
		elseif p.orange == 3 then
			return -3.3
		elseif p.orange == 4 then
			return -3.7
		else --if p.orange => 5 then
			return -4.2
		end
	end

	p.get_jumpsp_wjump = function()
		if p.orange == 0 then
			return -1
		elseif p.orange == 1 then
			return -2
		else
			return -3
		end
	end

	p.get_orange = function()
		p.orange = min(p.orange+1,5) 
		p.extra_jump = true
		p.orange_buffer = p.orange_buffer_start
	end

	p.start_die = function()
		p.respawn_buffer -= 1
	end

	return p
end

function make_orange_carrot(x,y,rx,ry)
	local a = make_object(1,s,x,y,rx,ry,7,7)

	a.active = true
	a.reset_buffer = 0 --in seconds 
	a.reset_buffer_start = 5

	a.draw = function(self)
		if (a.active) then
			if time % 15 == 0 then
				if self.spr == 6 then
					self.spr = 5
				else
					self.spr = 6
				end
			end
			spr(self.spr,self.x,self.y)
		end
	end

	a.update = function(self)
		if (a.reset_buffer <= 0) then
			a.active = true
		else
			a.reset_buffer = 
				mid(0, a.reset_buffer - one_sec, a.reset_buffer_start)
		end

	end

	a.set_inactive = function(self)
		a.active = false
		a.reset_buffer = a.reset_buffer_start
	end

	return a
end

function make_golden_carrot(x,y,rx,ry)
	local a = make_object(2,s,x,y,rx,ry,7,7)

	a.draw = function(self)
		if time % 14 == 0 then
			if self.spr == 21 then
				self.spr = 22
			else
				self.spr = 21
			end
		end
		spr(self.spr,self.x,self.y)
	end

	return a
end

function make_spike(spr, x, y, rx, ry)
	local o = make_object(3, spr, x, y, rx, ry, 1, 1)
	return o
end

function make_checkpoint(x, y, rx, ry)
	local o = make_object(4, checkpoint_sprite, x, y, rx, ry, 7, 7)

	o.active = false -- player respawns at this cp if tru

	o.update = function(self)
		if self.active then
			self.spr = current_checkpoint_sprite
		else
			self.spr = checkpoint_sprite
		end
	end

	o.setActive = function(self)
		for o in all(object) do
			if o.kind == 4 then
				o.active = false
			end
		end
		self.active = true
	end

	return o
end

-- COLLISIONS --
-- player against other objects, relative to map
function solid(x,y,w,h,f)
	for i=x, x+w, w do
		if fget(mget(i/8+map_x, y/8+map_y), f) or
		    fget(mget(i/8+map_x, (y+h)/8+map_y), f) then
			return true
		end
	end
	return false
end

-- objects a and b, relative to screen
function collide(a, b)
	if a == b then return end
	local dx = a.x - b.x
	local dy = a.y - b.y
	if abs(dx) < ceil((a.w+b.w)/2) and 
		abs(dy) < ceil((a.h+b.h)/2) then
		collide_event(a,b)
	end
end

function collide_event(a,b)
	if a.kind == 0 then
		if b.kind == 1 and b.active then --player hit orange carrot
			a.get_orange()
			total_orange += 1
			sfx(22)
			b.set_inactive(b)
		elseif b.kind == 2 then --player hit golden carrot
			a.golden += 1
			total_golden += 1
			sfx(20)
			del(object,b)
		elseif b.kind == 3 then
			a.start_die()
		elseif b.kind == 4 then
			b.setActive(b)
		end
	end
end

-- external player functions
function move_player(p)
	-- input and horizontal movement
	local accel = 0.2 -- horizontal accel
	p.walljumpdelay = max(p.walljumpdelay-1, 0)

	local max_walksp_final = p.max_walksp
	if p.is_on_solesand() then
		max_walksp_final = p.max_walksp_solesand
	end

	if p.walljumpdelay == 0 then
		if btn(k_left) and btn(k_right) then
			p.move_dir = 0
			p.walksp = p.start_walksp
		elseif btn(k_left) then
			p.move_dir = -1
			p.walksp += accel
		elseif btn(k_right) then
			p.move_dir = 1
			p.walksp += accel
		else
			p.move_dir = 0
			p.walksp = p.start_walksp
		end
		p.walksp = mid(-max_walksp_final, p.walksp, max_walksp_final)
		p.hsp = p.move_dir * p.walksp
	else
		p.hsp = p.move_dir * p.walksp_wjump
	end

	-- jump vars
	local grv_final = grv -- vertical accel 
	if btn(k_jump) and p.jump_key_released then 
		p.jump_key_down = true
		p.jump_key_released = false
	end

	if not btn(k_jump) then
		p.jump_key_released = true
	end

	if p.jump_key_down then
		p.ground_buffer = p.ground_buffer_start
	else
		p.ground_buffer = max(0, p.ground_buffer - 1)
	end

	if p.is_grounded() then
		p.walljumpdelay = 0
		p.jump_buffer = p.jump_buffer_start
		p.extra_jump = false
	else
		p.jump_buffer = max(0, p.jump_buffer - 1)
	end

	-- if in the air and release jump button,
	-- increase gravity
	if not p.is_grounded() and p.jump_key_released then
		-- if falling
		if p.vsp > 0 then
			grv_final = grv * 1.5
		-- if raising
		else
			grv_final = grv * 3.5
		end
	end

	-- if jump pressed in time (you're given
	-- extra frames)
	-- and you are grounded, jump
	if (p.jump_buffer > 0 or p.extra_jump) and 
	    p.ground_buffer > 0 and not p.is_wall_above() then
		p.vsp = p.get_jumpsp()
		p.extra_jump = false
		sfx(21)
		p.jump_buffer = 0
	end

	-- wall jump
	if p.jump_key_down and 
	   not p.can_jump and
	   not solid(p.x, p.y+3, p.w, p.h, flag_wall) and 
	  (p.is_onwall_right() or p.is_onwall_left()) then 
			
			if p.is_onwall_right() then
				p.move_dir = -1	
			elseif p.is_onwall_left() then
				p.move_dir = 1	
			end

			p.vsp = p.get_jumpsp_wjump()
			p.walljumpdelay = p.walljumpdelay_max
			p.jump_released = false
	end

	-- slow descent if onwall
	local vsp_max_final = p.vsp_max
	if (p.is_onwall_right() or p.is_onwall_left()) and p.vsp > 0 then
		vsp_max_final = p.vsp_max_onwall
		grv_final = 0.1
	end

	-- end jump vars
	p.jump_key_down = false

	-- gravity
	p.vsp = mid(-vsp_max_final, p.vsp+grv_final, vsp_max_final)

	-- horizontal collision
	if solid(p.x+p.hsp, p.y, p.w, p.h, flag_wall) then
		while not solid(p.x+sgn(p.hsp), p.y, p.w, p.h, flag_wall) do
			p.x += sgn(p.hsp)
		end
		p.hsp = 0
	end
	p.x += p.hsp

	-- vertical collision
	if solid(p.x, p.y+p.vsp, p.w, p.h, flag_wall) then
		while not solid(p.x, p.y+sgn(p.vsp), p.w, p.h, flag_wall) do
			p.y += sgn(p.vsp)
		end

		--[[
		-- wiggle thru corners
		-- TODO Will not work until
		-- collisions are checked based off sprites rather than map

		local amount = 1
		for i=1, amount do 
			for j=1, -1, -2 do
				if not solid(p.x + (i*j), p.y, p.w, p.h, flag_wall) then
					p.x += (i*j)
				end
			end 
		end --]]

		p.vsp = 0
	end
	p.y += p.vsp

	end

function check_room_transition(p)
	for x=p.x, p.x+p.w, p.w do
		if x > 128 then
			map_x += 16
			p.x = 0
		elseif x < 0 then
			map_x -= 16
			p.x = 128 - p.w
		end
	end
	for y=p.y, p.y+p.h, p.h do
		if y > 128 then
			map_y += 16
			p.y = 0
		elseif y < 0 then
			map_y -= 16
			p.y = 128 - p.h
		end
	end
	p.room = {x = map_x, y = map_y}
end






