HeroAttack = class()

function HeroAttack:init(hero, power)
    -- you can accept and set parameters here
    self.duration = 0.3
    self.currentTime = 0
    self.endTime = self.currentTime + self.duration
    self.hero = hero
    self.size = hero.size
    self.blastSize = self.size + power*70
    self.currentSize = self.size
end

function HeroAttack:isDone()
    return self.currentTime > self.endTime*2
end

function HeroAttack:draw()
    self.currentTime = self.currentTime + 1/30
    
    -- Time in the attack, 0 to 1
    attackTime = (self.currentTime)/self.duration

    pushStyle()
    
    noFill()
    stroke(255, 0, 0, 255*(1-attackTime))
    strokeWidth(10*(1-attackTime))
    
    self.currentSize = self.blastSize * attackTime + (self.size * (1-attackTime))
    p = self.hero.position
    ellipse(p.x, p.y, self.currentSize)
    
    popStyle()
end

