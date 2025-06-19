-- Copyright 2025 Elloramir.
-- All rights over the MIT license.

local fetch = require("fetch")
local json  = require("misc.json")

local app = {
    servers = {},
    client  = {},
    effects = { beams = {}, packets = {}, particles = {} },
    ui      = {},

    time        = 0,
    auto_mode   = true,
    auto_timer  = 0,

    total_requests   = 0,
    active_requests  = 0,
    success_count    = 0,
    last_response_ms = 0,
}

local endpoints = {
    {name = "Cat Fact",      url = "https://catfact.ninja/fact",                  color = {1,0.4,0},    radius = 40},
    {name = "Placeholder",   url = "https://jsonplaceholder.typicode.com/posts/1", color = {0.2,0.8,0.4}, radius = 35},
    {name = "HTTPBin",       url = "https://httpbin.org/json",                   color = {0.6,0.2,1},   radius = 45},
    {name = "ReqBin Echo",   url = "https://reqbin.com/echo/get/json",           color = {1,0.8,0.2},   radius = 30},
    {name = "Dog API",       url = "https://dog.ceo/api/breeds/image/random",    color = {0.8,0.2,0.6}, radius = 38},
}



function love.load()
    love.window.setTitle("Fetch HTTP Demo")
    love.graphics.setBackgroundColor(0.05,0.05,0.12)

    local w,h = love.graphics.getWidth(), love.graphics.getHeight()
    app.client = { x = w/2, y = h/2, radius = 25, energy = 100, pulse = 0 }

    app.ui.fonts = {
        large  = love.graphics.newFont(24),
        medium = love.graphics.newFont(16),
        small  = love.graphics.newFont(12),
    }

    for i,ep in ipairs(endpoints) do
        local angle = (i-1)/#endpoints * 2*math.pi
        ep.x = app.client.x + math.cos(angle)*200
        ep.y = app.client.y + math.sin(angle)*150
        ep.status = "idle"
        ep.data_received = 0
        ep.last_time = 0
        table.insert(app.servers, ep)
    end

    app.ui.title    = { text = "FETCH LIBRARY DEMO", x = w/2, y = 30 }
    app.ui.subtitle = { text = "Click planets to send requests • [SPACE] toggle auto • [R] reset • [ESC] quit", x = w/2, y = 60 }
end

function sendRequest(s)
    if s.status == "requesting" then return end
    s.status = "requesting"
    app.active_requests = app.active_requests + 1
    app.total_requests  = app.total_requests + 1

    createBeam(app.client.x,app.client.y, s.x,s.y, s.color, "out")
    createParticles(app.client.x,app.client.y, {0.4,0.8,1}, 8)

    local start_ms = love.timer.getTime()*1000
    fetch(s.url, nil, function(res)
        local now_ms = love.timer.getTime()*1000
        app.last_response_ms = now_ms - start_ms
        app.active_requests = app.active_requests - 1

        if res.code>=200 and res.code<300 then
            s.status = "success"
            s.data_received = s.data_received + #res.body
            s.last_time = app.last_response_ms
            app.success_count = app.success_count + 1

            local size = math.min(10, math.max(3, #res.body/200))
            createPacket(s.x,s.y, app.client.x,app.client.y, s.color, size)
            createBeam(s.x,s.y, app.client.x,app.client.y, s.color, "in")
            createParticles(s.x,s.y, s.color, 12)
            processData(res.body, s)
        else
            s.status = "error"
            createParticles(s.x,s.y, {1,0.3,0.3}, 15)
        end
    end)
end

local function drawPanel(x,y,w,h)
    love.graphics.setColor(0,0,0,0.6)
    love.graphics.rectangle("fill", x,y,w,h, 8,8)
    love.graphics.setColor(1,1,1,0.9)
end

function love.draw()
    -- background grid
    love.graphics.setColor(0.1,0.1,0.2,0.2)
    for x=0,800,50 do love.graphics.line(x,0,x,600) end
    for y=0,600,50 do love.graphics.line(0,y,800,y) end

    -- connections
    love.graphics.setColor(0.2,0.3,0.5,0.3)
    for _,s in ipairs(app.servers) do love.graphics.line(app.client.x,app.client.y, s.x,s.y) end

    -- effects
    for _,b in ipairs(app.effects.beams)   do b:draw() end
    for _,p in ipairs(app.effects.packets) do p:draw() end
    for _,p in ipairs(app.effects.particles) do p:draw() end

    -- servers
    for _,s in ipairs(app.servers) do
        local col = s.status=="requesting" and {1,1,0.3} or s.color
        love.graphics.setColor(col[1],col[2],col[3],0.2)
        love.graphics.circle("fill", s.x,s.y, s.radius*1.5)
        love.graphics.setColor(col)
        love.graphics.circle("fill", s.x,s.y, s.radius)
        love.graphics.setColor(1,1,1,0.6)
        love.graphics.circle("fill", s.x,s.y, s.radius*0.3)
        love.graphics.setFont(app.ui.fonts.small)
        love.graphics.printf(s.name, s.x-s.radius, s.y-s.radius-20, s.radius*2, "center")
        if s.data_received>0 then
            love.graphics.printf(string.format("%.1fkb", s.data_received/1024), s.x-s.radius, s.y+s.radius+5, s.radius*2, "center")
        end
    end

    -- client
    local pr = app.client.radius*(1+0.2*math.sin(app.time*4))
    love.graphics.setColor(0.4,0.8,1,0.3)
    love.graphics.circle("fill", app.client.x,app.client.y, pr*2)
    love.graphics.setColor(0.4,0.8,1)
    love.graphics.circle("fill", app.client.x,app.client.y, pr)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", app.client.x,app.client.y, pr*0.4)
    love.graphics.setFont(app.ui.fonts.medium)
    love.graphics.printf("YOUR APP", app.client.x-50, app.client.y-50, 100, "center")

    -- UI texts
    love.graphics.setFont(app.ui.fonts.large)
    love.graphics.setColor(0.4,0.8,1)
    -- love.graphics.printf(app.ui.title.text, app.ui.title.x-200, app.ui.title.y, 400, "center")
    -- love.graphics.setFont(app.ui.fonts.medium)
    -- love.graphics.printf(app.ui.subtitle.text, app.ui.subtitle.x-300, app.ui.subtitle.y, 600, "center")

    -- status panel
    drawPanel(20,520,260,60)
    love.graphics.setFont(app.ui.fonts.small)
    love.graphics.print(string.format("Total: %d  Active: %d  Success: %d", app.total_requests, app.active_requests, app.success_count), 30, 530)
    love.graphics.print(string.format("Last resp: %.1fms", app.last_response_ms), 30, 550)
end

function love.update(dt)
    fetch.update()
    app.time = app.time + dt
    if app.auto_mode then
        app.auto_timer = app.auto_timer + dt
        if app.auto_timer>0.1 then sendRequest(app.servers[math.random(#app.servers)]) app.auto_timer=0 end
    end
    for _,s in ipairs(app.servers) do if s.status~="requesting" then s.status="idle" end end
end

function love.mousepressed(x,y,b)
    if b==1 then for _,s in ipairs(app.servers) do if (x-s.x)^2+(y-s.y)^2 <= s.radius^2 then sendRequest(s) end end end
end

function love.keypressed(key)
    if key=="space" then app.auto_mode = not app.auto_mode
    elseif key=="r" then love.event.quit("restart")
    elseif key=="escape" then love.event.quit() end
end

-- Helper: Beams
Beam = {}
function Beam:draw()
    local alpha = self.life * 0.8
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],alpha)
    love.graphics.setLineWidth(self.thickness)
    local ex = self.x1 + (self.x2-self.x1)*self.progress
    local ey = self.y1 + (self.y2-self.y1)*self.progress
    love.graphics.line(self.x1,self.y1, ex,ey)
end

function createBeam(x1,y1,x2,y2,color,dir)
    local beam = { x1=x1,y1=y1,x2=x2,y2=y2,color=color,life=1,progress=0,thickness=(dir=="out" and 3 or 2) }
    setmetatable(beam,{__index=Beam})
    table.insert(app.effects.beams, beam)
end

-- Helper: Data Packets
Packet = {}
function Packet:draw()
    for i,pt in ipairs(self.trail) do love.graphics.setColor(self.color[1],self.color[2],self.color[3], pt.life*0.3)
        love.graphics.circle("fill", pt.x, pt.y, 2) end
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],0.9)
    love.graphics.circle("fill", self.x,self.y,self.size)
    love.graphics.setColor(1,1,1,0.4)
    love.graphics.circle("fill", self.x,self.y,self.size*0.5)

    -- move
    local dx,dy = self.target_x-self.x, self.target_y-self.y
    local dist = math.sqrt(dx*dx+dy*dy)
    if dist>5 then self.x=self.x+(dx/dist)*self.speed*love.timer.getDelta()
        self.y=self.y+(dy/dist)*self.speed*love.timer.getDelta() end
end

function createPacket(x1,y1,x2,y2,color,size)
    local p = { x=x1,y=y1,target_x=x2,target_y=y2,color=color,size=size,speed=200,trail={} }
    setmetatable(p,{__index=Packet})
    table.insert(app.effects.packets,p)
end

-- Helper: Particles
Particle = {}
function Particle:draw()
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.life*0.7)
    love.graphics.circle("fill", self.x,self.y,self.size)
end

function createParticles(x,y,color,count)
    for i=1,count do
        local p = { x=x,y=y, vx=math.random(-80,80), vy=math.random(-80,80), size=math.random(2,5), color=color, life=math.random(), decay=math.random(5,15)/10 }
        setmetatable(p,{__index=Particle})
        table.insert(app.effects.particles,p)
    end
end

-- Helper: Process JSON data (optional orbiting particles)
function processData(body,server)
    local ok,data = pcall(json.decode,body)
    if not ok or type(data)~="table" then return end
    -- optional: spawn orbit particles based on data size
end
