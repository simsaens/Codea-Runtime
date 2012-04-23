WorldBlock = class()

FLOOR = 0
WALL = 1


function WorldBlock:init(type,x,y)
    -- you can accept and set parameters here
    self.type = type
    self.size = vec2(100, 90)
    self.position = vec2(x,y)
    self.tint = color(255,255,255,255)
    self.actualPosition = vec2(self.position.x * self.size.x, self.position.y * self.size.y)
end

function WorldBlock:isColliding(point)
    ll = self.actualPosition - self.size * 0.5
    ur = self.actualPosition + self.size * 0.5
    
    if point.x > ll.x and point.x < ur.x and
       point.y > ll.y and point.y < ur.y then
        return true
    end
    
    return false
end

function WorldBlock:draw()
    -- Codea does not automatically call this method
    tint(self.tint)

    if self.type == FLOOR then
        sprite("Planet Cute:Dirt Block", self.actualPosition.x, self.actualPosition.y)
    elseif self.type == WALL then
        sprite("Planet Cute:Stone Block", self.actualPosition.x, self.actualPosition.y + 30)
    end
end

function WorldBlock:touched(touch)
    -- Codea does not automatically call this method
end
