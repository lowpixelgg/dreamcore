local network = class:create("network", {
  identifier = md5(getResourceName(getThisResource())),
  isServerInstance = (not localPlayer and true) or false,
  bandwidth = 1250000
})
network.private.buffer = {}
network.private.cache = {
  execSerials = {}
}

triggerRemoteEvent = (localPlayer and triggerServerEvent) or triggerClientEvent
triggerRemoteLatentEvent = (localPlayer and triggerLatentServerEvent) or triggerLatentClientEvent

addEvent("dreamcore:Networker:API", true)
addEventHandler("dreamcore:Networker:API", root, function(serial, payload)
  if not serial or not payload or not payload.processType or (payload.isRestricted and (serial ~= network.public.identifier)) then return false end
  if payload.processType == "emit" then
      local cNetwork = network.public:fetch(payload.networkName)
      if cNetwork and not cNetwork.isCallback then
          for i = 1, #cNetwork.priority.index, 1 do
              local j = cNetwork.priority.index[i]
              if not cNetwork.priority.handlers[j].config.isAsync then
                  network.private.execNetwork(cNetwork, j, _, serial, payload)
              else
                  thread:create(function(self) network.private.execNetwork(cNetwork, j, self, serial, payload) end):resume()
              end
          end
          for i, j in pairs(cNetwork.handlers) do
              if not j.config.isAsync then
                  network.private.execNetwork(cNetwork, i, _, serial, payload)
              else
                  thread:create(function(self) network.private.execNetwork(cNetwork, i, self, serial, payload) end):resume()
              end
          end
      end
  elseif payload.processType == "emitCallback" then
      if not payload.isSignal then
          local cNetwork = network.public:fetch(payload.networkName)
          if cNetwork and cNetwork.isCallback and cNetwork.handler then
              payload.isSignal = true
              payload.isRestricted = true
              if not cNetwork.handler.config.isAsync then
                  network.private.execNetwork(cNetwork, cNetwork.handler.exec, _, serial, payload)
              else
                  thread:create(function(self) network.private.execNetwork(cNetwork, cNetwork.handler.exec, self, serial, payload) end):resume()
              end
          end
      else
          if network.private.cache.execSerials[(payload.execSerial)] then
              network.private.cache.execSerials[(payload.execSerial)](unpack(payload.processArgs))
              network.private.deserializeExec(payload.execSerial)
          end
      end
  end
end)

function network.private.fetchArg(index, pool)
  index = tonumber(index) or 1
  index = (((index - math.floor(index)) == 0) and index) or 1
  if not pool or (type(pool) ~= "table") then return false end
  local argValue = pool[index]
  table.remove(pool, index)
  return argValue
end

function network.private.execNetwork(cNetwork, exec, cThread, serial, payload)
  if not cNetwork.isCallback then
      if cThread then
          exec(cThread, unpack(payload.processArgs))
      else
          exec(unpack(payload.processArgs))
      end
      local execData = cNetwork.priority.handlers[exec] or cNetwork.handlers[exec]
      execData.config.subscriptionCount = (execData.config.subscriptionLimit and (execData.config.subscriptionCount + 1)) or false
      if execData.config.subscriptionLimit and (execData.config.subscriptionCount >= execData.config.subscriptionLimit) then
          cNetwork:off(exec)
      end
  else
      if cThread then
          payload.processArgs = { exec(cThread, unpack(payload.processArgs)) }
      else
          payload.processArgs = { exec(unpack(payload.processArgs)) }
      end
      if not payload.isRemote then
          triggerEvent("dreamcore:Networker:API", resourceRoot, serial, payload)
      else
          if not payload.isReceiver or not network.public.isServerInstance then
              if not payload.isLatent then
                  triggerRemoteEvent("dreamcore:Networker:API", resourceRoot, serial, payload)
              else
                  triggerRemoteLatentEvent("dreamcore:Networker:API", network.public.bandwidth, false, resourceRoot, serial, payload)
              end
          else
              if not payload.isLatent then
                  triggerRemoteEvent(payload.isReceiver, "dreamcore:Networker:API", resourceRoot, serial, payload)
              else
                  triggerRemoteLatentEvent(payload.isReceiver, "dreamcore:Networker:API", network.public.bandwidth, false, resourceRoot, serial, payload)
              end
          end
      end
  end
  return true
end

function network.private.serializeExec(exec)
  if not exec or (type(exec) ~= "function") then return false end
  local cSerial = md5(network.public.identifier..":"..tostring(exec))
  network.private.cache.execSerials[cSerial] = exec
  return cSerial
end

function network.private.deserializeExec(serial)
  network.private.cache.execSerials[serial] = nil
  return true
end

function network.public:create(...)
  if self ~= network.public then return false end
  local cNetwork = self:createInstance()
  if cNetwork and not cNetwork:load(...) then
      cNetwork:destroyInstance()
      return false
  end
  return cNetwork
end

function network.public:destroy(...)
  if not network.public:isInstance(self) then return false end
  return self:unload(...)
end

function network.public:load(name, isCallback)
  if not network.public:isInstance(self) then return false end
  if not name or (type(name) ~= "string") or network.private.buffer[name] then return false end
  self.name = name
  self.owner = network.public.identifier
  self.isCallback = (isCallback and true) or false
  if not self.isCallback then self.priority, self.handlers = {index = {}, handlers = {}}, {} end
  network.private.buffer[name] = self
  return true
end

function network.public:unload()
  if not network.public:isInstance(self) then return false end
  network.private.buffer[(self.name)] = nil
  self:destroyInstance()
  return true
end

function network.public:fetch(name, isRemote)
  if self ~= network.public then return false end
  local cNetwork = network.private.buffer[name] or false
  if not cNetwork and isRemote then
      cNetwork = network.public:create(name)
  end
  return cNetwork
end

function network.public:on(exec, config)
  if not network.public:isInstance(self) then return false end
  if not exec or (type(exec) ~= "function") then return false end
  config = (config and (type(config) == "table") and config) or {}
  config.isAsync = (config.isAsync and true) or false
  config.isPrioritized = (not self.isCallback and config.isPrioritized and true) or false
  config.subscriptionLimit = (not self.isCallback and tonumber(config.subscriptionLimit)) or false
  config.subscriptionLimit = (config.subscriptionLimit and math.max(1, config.subscriptionLimit)) or config.subscriptionLimit
  config.subscriptionCount = (config.subscriptionLimit and 0) or false
  if self.isCallback then
      if not self.handler then
          self.handler = {exec = exec, config = config}
          return true
      end
  else
      if not self.priority.handlers[exec] and not self.handlers[exec] then
          if config.isPrioritized then
              self.priority.handlers[exec] = {index = #self.priority.index + 1, config = config}
              table.insert(self.priority.index, exec)
          else self.handlers[exec] = {config = config} end
          return true
      end
  end
  return false
end

function network.public:off(exec)
  if not network.public:isInstance(self) then return false end
  if not exec or (type(exec) ~= "function") then return false end
  if self.isCallback then
      if self.handler and (self.handler == exec) then
          self.handler = nil
          return true
      end
  else
      if self.priority.handlers[exec] or self.handlers[exec] then
          if self.priority.handlers[exec] then
              for i = self.priority.handlers[exec].index + 1, #self.priority.index, 1 do
                  local j = self.priority.index[i]
                  self.priority.handlers[j].index = index - 1
              end
              table.remove(self.priority.index, self.priority.handlers[exec].index)
              self.priority.handlers[exec] = nil
          else self.handlers[exec] = nil end
          return true
      end
  end
  return false
end

function network.public:emit(...)
  if not self then return false end
  local cArgs = { ... }
  local payload = {
      isRemote = false,
      isRestricted = false,
      processType = "emit",
      networkName = false
  }
  if self == network.public then
      payload.networkName, payload.isRemote = network.private.fetchArg(_, cArgs), network.private.fetchArg(_, cArgs)
      if payload.isRemote then
          payload.isLatent = network.private.fetchArg(_, cArgs)
          if network.public.isServerInstance then
              payload.isReceiver = network.private.fetchArg(_, cArgs)
              payload.isReceiver = (payload.isReceiver and isElement(payload.isReceiver) and (getElementType(payload.isReceiver) == "player") and payload.isReceiver) or false
          end
      end
  else
      payload.isRestricted = true
      payload.networkName = self.name
  end
  payload.processArgs = cArgs
  if not payload.isRemote then
      triggerEvent("dreamcore:Networker:API", resourceRoot, network.public.identifier, payload)
  else
      if not payload.isReceiver then
          if not payload.isLatent then
              triggerRemoteEvent("dreamcore:Networker:API", resourceRoot, network.public.identifier, payload)
          else
              triggerRemoteLatentEvent("dreamcore:Networker:API", network.public.bandwidth, false, resourceRoot, network.public.identifier, payload)
          end
      else
          if not payload.isLatent then
              triggerRemoteEvent(payload.isReceiver, "dreamcore:Networker:API", resourceRoot, network.public.identifier, payload)
          else
              triggerRemoteLatentEvent(payload.isReceiver, "dreamcore:Networker:API", network.public.bandwidth, false, resourceRoot, network.public.identifier, payload)
          end
      end
  end
  return true
end

function network.public:emitCallback(...)
  if not self or not thread:getThread() then return false end
  local cPromise = thread:createPromise()
  local cArgs, cExec = {...}, cPromise.resolve
  local payload = {
      isRemote = false,
      isRestricted = false,
      processType = "emitCallback",
      networkName = false,
      execSerial = network.private.serializeExec(cExec)
  }
  if self == network.public then
      payload.networkName, payload.isRemote = network.private.fetchArg(_, cArgs), network.private.fetchArg(_, cArgs)
      if payload.isRemote then
          payload.isLatent = network.private.fetchArg(_, cArgs)
          if not network.public.isServerInstance then
              payload.isReceiver = localPlayer
          else
              payload.isReceiver = network.private.fetchArg(_, cArgs)
              payload.isReceiver = (payload.isReceiver and isElement(payload.isReceiver) and (getElementType(payload.isReceiver) == "player") and payload.isReceiver) or false
              if not payload.isReceiver then return false end
          end
      end
  else
      payload.isRestricted = true
      payload.networkName = self.name
  end
  payload.processArgs = cArgs
  if not payload.isRemote then
      triggerEvent("dreamcore:Networker:API", resourceRoot, network.public.identifier, payload)
  else
      if not network.public.isServerInstance then
          if not payload.isLatent then
              triggerRemoteEvent("dreamcore:Networker:API", resourceRoot, network.public.identifier, payload)
          else
              triggerRemoteLatentEvent("dreamcore:Networker:API", network.public.bandwidth, false, resourceRoot, network.public.identifier, payload)
          end
      else
          if not payload.isLatent then
              triggerRemoteEvent(payload.isReceiver, "dreamcore:Networker:API", resourceRoot, network.public.identifier, payload)
          else
              triggerRemoteLatentEvent(payload.isReceiver, "dreamcore:Networker:API", network.public.bandwidth, false, resourceRoot, network.public.identifier, payload)
          end
      end
  end
  return cPromise
end