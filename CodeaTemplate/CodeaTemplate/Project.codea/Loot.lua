Loot = class()

function Loot:init(pos)
    -- you can accept and set parameters here
    self.position = pos
    self.collected = false
    self.rise = 0
end

function Loot:collect(point)
    dtg = point:dist(self.position)

    if dtg < 50 and not self.collected then
        sound(SOUND_PICKUP, 195)
        self.collected = true
        return true
    end
    
    return false
end

function Loot:draw()
    -- Codea does not automatically call this method
    sprite("Planet Cute:Gem Green", self.position.x, self.position.y + 15 + self.rise, 50, 80)
    
    if self.collected then
        self.rise = self.rise + 15
    end
end

function Loot:touched(touch)
    -- Codea does not automatically call this method
end
