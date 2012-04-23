supportedOrientations(LANDSCAPE_ANY)

-- Use this function to perform your initial setup
function setup()
    math.randomseed(1275)

    guy = Hero()
    guy.position = vec2(WIDTH/2,HEIGHT/2)   

    world = World(guy,8,9)
    
    guy.world = world    
end

-- This function gets called once every frame
function draw()
    background(0)
    
    translate(-70, -60)
    
    world:draw()
    
    if guy:isDead() then
        guy:drawDead()
    else
        guy:draw()
    end
end

function touched(touch)
    guy:touched(touch)
end