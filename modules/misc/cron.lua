local imports = {
  type = type,
  pcall = pcall,
}
local cron = class:create("cron")


function cron.public:create(...) 
  if self ~= cron.public then return false end
  local instance = self:createInstance()
  
  if instance and not instance:load(...) then 
    instance:destroyInstance()
    return false
  end
  
  return instance
end


function cron.public:load(timestamp, exec, storage) 
  self.beat = nil
  self.timestamp = timestamp
  self.exec = exec
  self.storage = storage
  
  self.beat = thread:createHeartbeat(function () self:invocation()  return true end, function () end, 1000)
end


function cron.public:isBefore() 
  return os.time() > self.timestamp
end


function cron.public:invocation () 
  if self:isBefore() then 
    if self.beat then 
      self.beat:destroy()
      
      self:executeCallback(self.exec, self.storage)
      
      self.beat = nil
      self.timestamp = nil
      self.exec = nil
      self.storage = nil
      
      self:destroy()
    end
  end
end


function cron.public:executeCallback(callback, ...)
  if imports.type(callback) ~= "function" then
    return false
  end
  local success, err = imports.pcall(callback, ...)
  if not success then
    return false
  end
  return true
end


function cron.public:destroy()
  if not cron.public:isInstance(self) then return false end
  
  self:destroyInstance()
  return true
end