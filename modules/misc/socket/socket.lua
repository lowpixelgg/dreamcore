local imports = {
    webui = exports.webui;
}

local socket = class:create("socket")

socket.public.buffer = {}

if localPlayer then
  function socket.public:create(...) 
    if self ~= socket.public then return false end
    local instance = self:createInstance()
    
    if instance and not instance:load(...) then 
      instance:destroyInstance()
      return false
    end
    
    return instance
  end
  
  
  function socket.public:load(id, host, transport)
    if not socket.public:isInstance(self) then return false end
    if not id or (type(id) ~= "string") or socket.public.buffer[id] then return false end


    local exists = imports.webui:getBrowser(id);
    self.id = id

    if (not exists) then 
      imports.webui:startUp()
      self.browser = imports.webui:createGhost(id, 0, 0, 0.01, 0.01, "http://mta/dreamcore/modules/misc/socket/bundler/index.html", true)
      setBrowserRenderingPaused(imports.webui:getBrowser(self.browser), true);
      imports.webui:executeJavascript(self.browser, "createClass('"..self.id.."', '"..host.."', '"..transport.."');")
    else
      self.browser = id;
    end


    return self
  end
  
  function socket.public:unload()
    if not socket.public:isInstance(self) then return false end
    self:destroyInstance()
    return true
  end
  
  
  function socket.public:emit(event, data)
    if type(data) ~= "string" and type(data) ~= "table" and type(data) ~= "number" then return false end

    if type(data) == "table" then 
      data = toJSON(data)
    end
    
    if type(data) == "string" then 
      data = "'"..data.."'"
    end


    imports.webui:executeJavascriptWithoutEvent(self.browser, "sockets['"..self.id.."'].emit('"..event.."', "..data..")")
  end
  
  function socket.public:on(event, callback) 
    -- Registry the event
    imports.webui:executeJavascriptWithoutEvent(self.browser, "sockets['"..self.id.."'].on('"..event.."')")

    -- Handle the event callback
    addEvent(event, true)
    addEventHandler(event, root, function (...) 
      return callback(...)
    end)
  end
  
  function socket.public:onAny(callback) 
    -- Registry the event
    imports.webui:executeJavascriptWithoutEvent(self.browser, "sockets['"..self.id.."'].onAny()")
    
    -- Handle the event callback
    addEvent("__any")
    addEventHandler("__any", root, function (...) 
      return callback(...)
    end)
  end
  
  
  function socket.public:fetch(id) 
    if self ~= socket.public then return false end
    
    local browser = imports.webui:getBrowser(id);

    if (browser) then 
      return socket.public:create(id)
    end
  end
end