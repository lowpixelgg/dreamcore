local imports = {
    getLocalPlayer = getLocalPlayer,
  }

  localPlayer = (imports.getLocalPlayer and getLocalPlayer()) or false
  execFunction = function(exec, ...) if not exec or (type(exec) ~= "function") then return false end; return exec(...) end
  isElement = function(element) return (element and isElement(element)) or false end
  destroyElement = function(element) return (isElement(element) and destroyElement(element)) or false end


  function getElementPosition(element, offX, offY, offZ)
    if not element or not isElement(element) then return false end
    if not offX or not offY or not offZ then
        return getElementPosition(element)
    else
        offX, offY, offZ = tonumber(offX) or 0, tonumber(offY) or 0, tonumber(offZ) or 0
        local cMatrix = getElementMatrix(element)
        return (offX*cMatrix[1][1]) + (offY*cMatrix[2][1]) + (offZ*cMatrix[3][1]) + cMatrix[4][1], (offX*cMatrix[1][2]) + (offY*cMatrix[2][2]) + (offZ*cMatrix[3][2]) + cMatrix[4][2], (offX*cMatrix[1][3]) + (offY*cMatrix[2][3]) + (offZ*cMatrix[3][3]) + cMatrix[4][3]
    end
  end

  function getInterpolationProgress(tick, interval)
    if not tick or not interval then return false end
    return ((CLIENT_CURRENT_TICK or getTickCount()) - tick)/interval
  end
