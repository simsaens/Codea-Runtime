function tintForInvulnDuration(inv)
    if inv > 0 then
        flashAmount = (math.sin(inv*20)+1)*0.5
        tint(255,255,255,255 * flashAmount)
    else
        tint(255,255,255,255)
    end
end