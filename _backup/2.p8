pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

function make_object(k,s,x,y,rx,ry,w,h)
	local a = {}
	a.kind = k
	a.spr = s -- beginning sprite
	a.x = x
	a.y = y
	a.room = {x = rx, y = ry}
	a.w = w
	a.h = h

	a.draw = function(self)
		if self.kind == 0 then
			spr(self.spr,self.x,self.y,1,1,self.faceLeft,false)
		elseif self.kind == 1 then
			if time % 15 == 0 then
				if self.spr == 4 then
					self.spr = 5
				else
					self.spr = 4
				end
			end
			spr(self.spr,self.x,self.y)
		elseif self.kind == 2 then
			if time % 14 == 0 then
				if self.spr == 6 then
					self.spr = 7
				else
					self.spr = 6
				end
			end
			spr(self.spr,self.x,self.y)
		end
	end
	return a
end

function make_player(x,y,w,h)
	local p = make_object(0,32,x,y,map_x,map_y,w,h)
	p.faceLeft = false
	p.orange = 0 -- number of orange carrots collected
	p.golden = 0 -- number of golden carrots collected
	p.move_dir = 0
	p.start_walksp = 0.5
	p.max_walksp = 2
	p.walksp = 0
	p.hsp = 0
	p.max_vsp = 5
	p.vsp = 0

	p.jump_key_down = false
	p.jump_key_released = true

	-- how many frames you have to get grounded, and
	-- allow a jump
	p.ground_buffer = 0
	p.ground_buffer_start = 5

	-- how many frames you have to jump when off ledge
	p.jump_buffer = 0
	p.jump_buffer_start = 4

	p.get_jumpsp = function()
		if p.orange == 0 then
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

	p.is_grounded = function()
		return hit(p.x, p.y+1, p.w, p.h, wall_flag) end

	p.update = function(self)
		move_player(self)
		check_room_transition(self) 
	end

	return p
end


-- COLLISIONS --
-- player against other objects, relative to map
function hit(x,y,w,h,f)
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
		if b.kind == 1 then --player hit orange
			a.orange += 1
			del(object,b)
		elseif b.kind == 2 then
			a.golden += 1
			del(object,b)
		end
	end
end

-- external player functions
function move_player(p)
	-- input and horizontal movement
	local accel = 0.2 -- horizontal accel
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
	p.walksp = mid(-p.max_walksp, p.walksp, p.max_walksp)
	p.hsp = p.move_dir * p.walksp

	-- jump vars
	local final_grv = grv -- vertical accel 
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
		p.jump_buffer = p.jump_buffer_start
	else
		p.jump_buffer = max(0, p.jump_buffer - 1)
	end

	-- if in the air and release jump button,
	-- increase gravity
	if not p.is_grounded() and p.jump_key_released then
		-- if falling
		if p.vsp > 0 then
			final_grv = grv * 1.5
		-- if raising
		else
			final_grv = grv * 3.5
		end
	end

	-- if jump pressed in time (you're given
	-- extra frames)
	-- and you are grounded, jump
	if p.jump_buffer > 0 and p.ground_buffer > 0 then
		p.vsp = p.get_jumpsp()
		p.jump_buffer = 0
	end

	-- end jump vars
	p.jump_key_down = false

	-- TODO wall jump

	-- gravity
	p.vsp = mid(-p.max_vsp, p.vsp+final_grv, p.max_vsp)

	-- horizontal collision
	if hit(p.x+p.hsp, p.y, p.w, p.h, wall_flag) then
		while not hit(p.x+sgn(p.hsp), p.y, p.w, p.h, wall_flag) do
			p.x += sgn(p.hsp)
		end
		p.hsp = 0
	end
	p.x += p.hsp

	-- vertical collision
	if hit(p.x, p.y+p.vsp, p.w, p.h, wall_flag) then
		while not hit(p.x, p.y+sgn(p.vsp), p.w, p.h, wall_flag) do
			p.y += sgn(p.vsp)
		end
		p.vsp = 0
	end
	p.y += p.vsp

	-- water collision
	if hit(p.x, p.y, p.w, p.h, flag_die) then
		-- die
		restart_game()
	end

	-- animations
	if p.move_dir == 1 then
		p.faceLeft = false
	elseif p.move_dir == -1 then
		p.faceLeft = true
	end

	if p.is_grounded() then
		-- not moving
		if p.hsp == 0 then 
			p.spr = 32
		elseif time % 5 == 0 then
			if p.spr == 32 then
				p.spr = 33
			else			
				p.spr = 32
			end
		end
		-- moving
	else
		p.spr = 33
	end
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






