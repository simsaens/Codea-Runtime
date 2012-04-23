Monster = class()

function Monster:init(hero, pos)
    -- you can accept and set parameters here
    self.hero = hero
    self.position = pos
    self.health = 38
    self.dead = false
    self.shakeAmount = 0
    self.opacity = 255
    self.aggressionRadius = 200
    self.knockVel = vec2(0,0)
    self.invulnDuration = 0
    parameter("MonsterHitRadius",10,200,60)
    
    self.hitRadius = MonsterHitRadius
end

function Monster:moveToHero()
    line = self.hero.position - self.position
    line = line:normalize()
    
    self.position = self.position + line * 2
end

function Monster:moveAwayFromHero(amount)
    line = self.position - self.hero.position
    line = line:normalize()
    
    self.knockVel = self.knockVel + line * amount
end

function Monster:shake()
    self.shakeAmount = 3
end

function Monster:draw()
    self.hitRadius = MonsterHitRadius
    self.invulnDuration = math.max(self.invulnDuration - 1/60, 0)
    
    if self.dead then
        pushStyle()
        
        pushMatrix()
        
        translate(self.position.x, self.position.y + -20)
        scale(1,-1)
        tint(190*self.opacity/255,self.opacity)
        sprite("Planet Cute:Enemy Bug", 0,0)
        popMatrix()
        
        self.opacity = self.opacity * 0.98

        popStyle()
    else
        distToHero = self.hero.position:dist(self.position)
                         
        if distToHero < self.hitRadius and self.invulnDuration == 0 then
            -- damage hero
            self.hero:applyDamageFromPoint(self.position, 5)
        end

        damage = self.hero:damageAtPoint(self.position)
        if damage > 0 and self.invulnDuration == 0 then
            self:moveAwayFromHero(damage)
            self.health = self.health - damage
            self.invulnDuration = 0.5
            --self:shake()
            if self.health <= 0 then
                self.dead = true
            end
        elseif distToHero < self.aggressionRadius and
                self.invulnDuration == 0 then
            self:moveToHero()
        end
        
        self.position = self.position + self.knockVel
        self.knockVel = self.knockVel * 0.7
        
        -- Codea does not automatically call this method
        pushStyle()
        
        tintForInvulnDuration(self.invulnDuration)
        shake = vec2(math.random() * self.shakeAmount, math.random() * self.shakeAmount)
        sprite("Planet Cute:Enemy Bug", self.position.x + shake.x, self.position.y + 35 + shake.y) 
    
        popStyle()
    end
    
    self.shakeAmount = self.shakeAmount * 0.582
end

function Monster:touched(touch)
    -- Codea does not automatically call this method
end
