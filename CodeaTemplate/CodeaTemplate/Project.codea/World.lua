World = class()

function World:init(hero, w, h)
    -- you can accept and set parameters here
    self.hero = hero
    self.blocks = {}
    self.walls = {}
    self.monsters = {}
    self.loot = {}
    
    for x = 1,w do
        self.blocks[x] = {}
        for y = 1,h do
            t = FLOOR
            if math.random() < 0.1 or x == 1 or y == 1
                or x == w or y == h then
                t = WALL
            end
            self.blocks[x][y] = WorldBlock(t,x,y)
            
            if t == WALL then
                table.insert(self.walls, self.blocks[x][y])
            else
                if math.random() < 0.06 then
                    table.insert(self.loot, Loot(self.blocks[x][y].actualPosition))
                elseif math.random() < 0.16 then
                    table.insert(self.monsters, Monster(hero, self.blocks[x][y].actualPosition))
                end
            end
            
            if (x == 2 or y == 2 or x == w-1 or y == h-1)
                and t == FLOOR then
                self.blocks[x][y].tint = color(230, 201, 201, 255)
            end
        end
    end
end

function World:isColliding(point)
    for i,v in ipairs(self.walls) do
        if v:isColliding(point) then
            return true
        end
    end
    
    return false
end

function World:draw()
    -- Codea does not automatically call this method
    itemDrawn = false
    for y = #self.blocks[1],1,-1 do
        --if not itemDrawn and math.floor((item.position.y - 45) / 90) == y then
        --    item:draw()
        --    itemDrawn = true
        --end
        for x = 1,#self.blocks do
            self.blocks[x][y]:draw()
        end
        
    end
    
    for i,m in ipairs(self.loot) do
        if m:collect(self.hero.position) then
            self.hero.attackPower = self.hero.attackPower + 0.5
        end
        m:draw()
    end
    
    for i,m in ipairs(self.monsters) do
        m:draw()
    end
end

function World:touched(touch)
    -- Codea does not automatically call this method
end
