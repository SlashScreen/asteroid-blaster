pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	g = {} --game 
	g.screen = "title" --screen
	g.timer = 0 --timer used for spawn asteroids
	g.as = {} --asteroids
	p = {} --player
	p.cash = 0 --cash
	p.x = 0 --x on screen
	p.y = 0 --y on screen
	p.layers = {} --ship graphics layers
	p.layers.cockpit = {x=0,y=0,s=.9999} --window
	p.layers.thrusters = {x=0,y=0,s=.95} --back
end

function _update()
	if g.screen == "title" then
		--if x pressed begin
		if btn(5) then
			g.screen = "game"
		end
	elseif g.screen == "game" then
		--update game
		g.timer += 1
		if g.timer == 30 then
			g.timer = 0
			add(g.as,new_asteroid())
		end
		for _,obj in pairs(p.layers) do
			if obj.x > p.x-1 then
				obj.x -= obj.s
			elseif obj.x < p.x-1 then
				obj.x += obj.s
			end
			if obj.y > p.y then
				obj.y -= obj.s
			elseif obj.y < p.y then
				obj.y += obj.s
			end
			if abs(p.x-1-obj.x)<obj.s then
				obj.x = p.x
			end
			if abs(p.y-obj.y)<obj.s then
				obj.x = p.x
			end
		end
		--foreach(p.layers,chase)
		if btn(0) then
			p.x -= 1
		end
		if btn(1) then
			p.x += 1
		end
		if btn(2) then
			p.y -= 1
		end
		if btn(3) then
			p.y += 1
		end
		foreach(g.as,function(o) o.update() end)
	elseif g.screen == "dead" then
		--dead and store
	end
end

function _draw()
	cls()
	if g.screen == "title" then
		--if x pressed begin
		print("asteroid blasters")
		print("press x to begin")
	elseif g.screen == "game" then
		--draw game
		--draw layers 
		foreach(g.as,function(o) o.draw() end)
		sspr(11,0,2,1,p.x-1,p.y)
		sspr(10,2,4,2,p.layers.cockpit.x-2,p.layers.cockpit.y)
		sspr(9,6,6,2,p.layers.thrusters.x-3.5,p.layers.thrusters.y)
	elseif g.screen == "dead" then
		--dead and store
	end
end
-->8
--classes

--asteroid
function new_asteroid()
	local as = {}
	as.x = rnd(128)
	as.y = rnd(128)
	as.z = 0
	as.axis = nil --if 3d, axis of rotation as vector
	as.size = rnd(32) --unit is px
	as.shape = gen_aster_shape(as.size)
	--todo: if 3d, generate mesh here
	as.update = function(this)
		--if 3d, rotate also
		as.z += 1
		if as.z == 100 then
			phitbox = make_box(p.x,p.y,6,2)
			ashitbox = make_box(as.x,as.y,as.size,as.size) --haha
			if overlap(phitbox, ashitbox) then 
				g.screen = "dead"
			end
			del(g.as,as)
		end
	end
	--end update
	as.draw = function(this)
		--draw 3d or sprite
		x0 = (as.x+as.size/2)-(as.size/2)*(as.z/100)
		y0 = (as.y+as.size/2)-(as.size/2)*(as.z/100)
		x1 = (as.x+as.size/2)+(as.size/2)*(as.z/100)
		y1 = (as.y+as.size/2)+(as.size/2)*(as.z/100)
		rectfill(x0,y0,x1,y1,7)
		for _,c in pairs(as.shape.craters) do
			spr(16+c.c,as.x+c.x,as.y+c.y)
		end
		polyfill(dilate({x=as.x+as.size/2,y=as.x+as.size/2},as.z/100,as.shape.points))
	end
	--end draw
	return as
end

function make_box(x,y,w,h)
	local b = {}
	b.x = x
	b.y = y
	b.w = w
	b.h = h
	return b
end
-->8
--utils
function chase (obj)
	obj.x = p.x
	--[[
	if obj.x > p.x-1 then
		obj.x -= obj.s
	elseif obj.x < p.x-1 then
		obj.x += obj.s
	end
	if obj.y > p.y then
		obj.y -= obj.s
	elseif obj.y < p.y then
		obj.y += obj.s
	end]]
end

function overlap(a,b)
 return not (a.x>b.x+b.w 
          or a.y>b.y+b.h 
          or a.x+a.w<b.x 
          or a.y+a.h<b.y)
end

function polyfill(points)
      local xl,xr,ymin,ymax={},{},129,0xffff
      for k,v in pairs(points) do
          local p2=points[k%#points+1]
          local x1,y1,x2,y2,x_array=v.x,flr(v.y),p2.x,flr(p2.y),xr
          if y1==y2 then
              xl[y1],xr[y1]=min(xl[y1] or 32767,min(x1,x2)),max(xr[y1] or 0x8001,max(x1,x2))
          else
              if y1>y2 then
                  x_array,y1,y2,x1,x2=xl,y2,y1,x2,x1
              end    
              for y=y1,y2 do
                  x_array[y]=flr(x1+(x2-x1)*(y-y1)/(y2-y1))
              end
          end
          ymin,ymax=min(y1,ymin),max(y2,ymax)
      end
      for y=ymin,ymax do
          rectfill(xl[y],y,xr[y],y,8)
      end
  end
  
function gen_aster_shape(size)
	--generates points for an asteroid.
	--returns shape object
	--shape object:
	-- ||_ list of craters
	-- |_ lsit of points
	--crater object
	-- ||_ which crater sprite to use
	-- |_ point
	local sh = {}
	local craters = {}
	local pnts = {}
	for i = 0,flr(rnd(3))+1,1 do
		local crater = {}
		crater.x = rnd(size)
		crater.y = rnd(size)
		crater.c = flr(rnd(3)+.5)
		add(craters,crater)
	end
	for i = 0,7,1 do
		local pnt = {}
		x = cos(i*45)*(size/2) --x
		y = sin(i*45)*(size/2) --y
		pnt.x = x+rnd(-7) --x
		pnt.y = y+rnd(-7) --y
		add(pnts,pnt)
	end
	sh.craters = craters
	sh.points = pnts
	return sh
end

function dilate(origin,size,points)
	--dialates shape around an origin by size. returns points.
	
	--pseudocode:
	--loop through point, dialate around origin
	local out = {}
	for _,i in pairs(points) do
		local o = {}
		o.x = (origin.x - i.x )
		o.y = (origin.y - i.y )
		add(out,o)
	end
	return out
end
__gfx__
00000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000005005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700051551500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000058558500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000001100000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01660000001660000016600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01660000016666000166000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01660000001660000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006000000001600000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
