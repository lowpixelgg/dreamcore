local buffer = {
  types = {},
  parents = {},
  instances = {}
}

class = {}
class.__index = class
local namespace = nil

function class:create(typef, parent, nspace)
  if self ~= class then return false end
  if not typef or (type(typef) ~= "string") or (parent and ((type(parent) ~= "table") or buffer.instances[parent])) or buffer.types[typef] then return false end
  nspace = (nspace and (type(nspace) == "string") and nspace) or false
  if nspace and not namespace.private.types[nspace] then return false end
  parent = parent or {}
  parent.__index = parent
  if nspace then
      namespace.private.types[nspace].public[typef] = parent
      namespace.private.classes[nspace] = parent
  else
      _G[typef] = parent
  end
  buffer.types[typef] = true
  buffer.parents[parent], buffer.instances[parent] = {}, {type = typef, nspace = nspace, public = parent, private = setmetatable({}, {__index = parent})}
  function parent:getType()
      if not self or not buffer.instances[self] then return false end
      return (buffer.parents[self] and buffer.instances[self].type) or (buffer.instances[(buffer.instances[self])].type) or false
  end
  
  function parent:isInstance(instance)
      if (self ~= parent) or not buffer.parents[parent] then return false end
      return (buffer.parents[parent][instance] and true) or false
  end
  function parent:createInstance()
      if (self ~= parent) or not buffer.parents[parent] then return false end
      local cInstance = setmetatable({}, {__index = self})
      
      buffer.instances[cInstance], buffer.parents[parent][cInstance] = parent, true
      function cInstance:destroyInstance()
          if (self ~= cInstance) or not buffer.instances[self] then return false end
          buffer.instances[self], buffer.parents[parent][self] = nil, nil
          self = nil
          collectgarbage()
          return true
      end
      return cInstance
  end


  return {public = buffer.instances[parent].public, private = buffer.instances[parent].private}
end

function class:destroy(instance)
  if self ~= class then return false end
  if not instance or (type(instance) ~= "table") or not buffer.parents[instance] then return false end
  for i, j in pairs(buffer.parents[instance]) do
      if i then
          i:destroyInstance()
      end
  end
  local type, nspace = buffer.instances[instance].type, buffer.instances[instance].nspace
  if buffer.instances[instance].nspace then
      if namespace.private.types[nspace] and namespace.private.types[nspace][typef] and (namespace.private.types[nspace][typef] == buffer.instances[instance].public) then
          namespace.private.types[nspace][typef] = nil
      end
  else
      if _G[type] and (_G[type] == buffer.instances[instance].public) then
          _G[type] = nil
      end
  end
  buffer.types[typef] = nil
  buffer.instances[instance], buffer.parents[instance] = nil, nil
  instance = nil
  collectgarbage()
  return true
end




--------------------------
--[[ Class: Namespace ]]--
--------------------------  
namespace = class:create("namespace")
namespace.private.types = {}
namespace.private.classes = {}

function namespace.public:create(typef, parent)
  if (self ~= namespace.public) and (self ~= namespace.private) or (parent and ((type(parent) ~= "table") or buffer.instances[parent])) then return false end
  if not type or (type(typef) ~= "string") or namespace.private.types[typef] then return false end
  local parent = parent or {}
  _G[typef] = parent
  local cNamespace = self:createInstance()
  namespace.private.classes[typef] = {}
  namespace.private.types[typef] = {instance = cNamespace, public = parent, private = setmetatable({}, {__index = parent})}
  return {public = namespace.private.types[typef].public, private = namespace.private.types[typef].private}
end

function namespace.public:destroy(typef)
  if (self ~= namespace.public) and (self ~= namespace.private) then return false end
  if not type or (type(typef) ~= "string") or not namespace.private.types[typef] then return false end
  if _G[typef] and (_G[typef] == namespace.private.types[typef].public) then
      _G[typef] = nil
  end
  for i, j in pairs(namespace.private.classes[typef]) do
      if i then
          class:destroy(i)
      end
  end
  namespace.private.types[typef].instance:destroyInstance()
  namespace.private.types[typef], namespace.private.classes[typef] = nil, nil
  return true
end


function getInstancesByType(typef)
  local instances = {}
  for instance, instanceData in pairs(buffer.instances) do
    if instanceData.type == typef then
      table.insert(instances, instance)
    end
  end
  return instances
end