Hero = class()

function Hero:init()
    -- you can accept and set parameters here
    self.position = vec2(0,0)
    self.size = 60
    self.health = 50
    self.attackPower = 1
    self.invulnDuration = 0
    self.knockVel = vec2(0,0)
    watch("HeroHealth")
end

function Hero:move(dir)
    newPos = self.position + dir * 20
    newPos = newPos + self.knockVel
    
    if world:isColliding(newPos) then
        -- hit wall
    else
        self.position = newPos
    end
    
    self.knockVel = self.knockVel * 0.7
end

function Hero:applyDamageFromPoint(point, damage)
    if self.invulnDuration == 0 then
        self.health = math.max(self.health - damage, 0)
        line = self.position - point
        line = line:normalize()
        self.invulnDuration = 0.5
        self.knockVel = self.knockVel + line * 20
    end
end

function Hero:attack()
    if self.currentAttack == nil then
        sound(SOUND_HIT,123)
        --print("Attacking")
        self.currentAttack = HeroAttack(self,self.attackPower)
    end
end

function Hero:damageAtPoint(point)
    if self.currentAttack then
        dta = self.position:dist(point) 
        if dta < self.currentAttack.currentSize * 0.4 then
            return dta/self.currentAttack.blastSize * 30
        end
    end
    
    return 0
end

function Hero:isDead()
    return self.health == 0
end

function Hero:drawDead()
    tint(50,50,50,255)
    sprite("Planet Cute:Character Boy", self.position.x + 5, self.position.y + 25, self.size + 20)
end

function Hero:draw()
    self.invulnDuration = math.max(self.invulnDuration - 1/60, 0)

    moveVec = vec2(Gravity.x, Gravity.y) + vec2(0,0.6)
    self:move(moveVec)

    pushStyle()

    if self.currentAttack then
        self.currentAttack:draw()
        if self.currentAttack:isDone() then
            self.currentAttack = nil
        end    
    end
    
    stroke(0,0,0,0)
    fill(15, 23, 65, 141)
    ellipse(self.position.x + 5, self.position.y - 5, self.size, self.size)

    tintForInvulnDuration(self.invulnDuration)
    --ellipse(self.position.x, self.position.y, self.size, self.size)
    sprite("Planet Cute:Character Boy", self.position.x + 5, self.position.y + 25, self.size + 20)
    
    popStyle()
    
    HeroHealth = self.health
end

function Hero:touched(touch)
    -- Codea does not automatically call this method
    if touch.state == ENDED then --and self.invulnDuration == 0 then
        self:attack()
    end
end
