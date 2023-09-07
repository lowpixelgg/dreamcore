local bundler = class:create("bundler")
function bundler.public:import() return bundler end
bundler.private.buffer = {}
bundler.private.platform = (localPlayer and "client") or "server"
bundler.private.utils = {
  "modules/misc/string.lua",
}

bundler.private.modules = {
  ["namespace"] = {module = "namespacer", namespace = "dreamcore.namespace", path = "modules/misc/namespacer.lua", endpoints = {"namespace", "class"}},
  ["class"] = {namespace = "dreamcore.class"},
  ["file"] = {module = "filesystem", namespace = "dreamcore.file", path = "modules/misc/fs.lua", endpoints = {"file"}},
}


function bundler.private:createUtils()
  if type(bundler.private.utils) == "table" then
      local rw = ""
      for i = 1, #bundler.private.utils, 1 do
          local j = file:read(bundler.private.utils[i])
          for k, v in pairs(bundler.private.modules) do
              j = string.gsub(j, k, v.namespace, _, true, "(", ".:)")
          end
          rw = rw..[[
          if true then
              ]]..j..[[
          end
          ]]
      end
      bundler.private.utils = rw
  end
  return bundler.private.utils
end

function bundler.private:createBuffer(index, name, rw)
  if not bundler.private.buffer[index] and rw then
      bundler.private.buffer[index] = {module = name, rw = rw}
      return true
  end
  return (bundler.private.buffer[index] and bundler.private.buffer[index].rw) or false
end

function bundler.private:createModule(name)
  if not name then return false end
  local module = bundler.private.modules[name]
  if not module then return false end
  if not bundler.private.buffer[(module.module)] then
      local rw = file:read(module.path)
      for i, j in pairs(bundler.private.modules) do
          local isBlacklisted = false
          for k = 1, #module.endpoints, 1 do
              local v = module.endpoints[k]
              if i == v then
                  isBlacklisted = true
                  break
              end
          end
          if not isBlacklisted then rw = string.gsub(rw, i, j.namespace, _, true, "(", ".:)") end
      end
      rw = ((name == "namespace") and string.gsub(rw, "class = {}", "local class = {}")) or rw

      for i = 1, #module.endpoints, 1 do
          local j = module.endpoints[i]
          rw = rw..[[
          dreamcore["]]..j..[["] = ]]..j..((bundler.private.modules[j] and bundler.private.modules[j].module and ".public") or "")..[[
          _G["]]..j..[["] = nil
          ]]
      end

      bundler.private:createBuffer(module.module, name, [[
      if not dreamcore.]]..name..[[ then
          ]]..rw..[[
      end
      ]])
  end
  return bundler.private.buffer[(module.module)].rw
end
for i, j in pairs(bundler.private.modules) do
  if j.module and j.endpoints then
      bundler.private:createModule(i)
  end
end

function bundler.private:createAPIs(exports)
  if not exports or (type(exports) ~= "table") then return false end
  local rw = ""
  for i, j in pairs(exports) do
      if (i == bundler.private.platform) or (i == "shared") then
          for k = 1, #j, 1 do
              local v = j[k]
              rw = rw..[[
              ]]..v.exportIndex..[[ = function(...)
                  return dreamcore.imports.call(dreamcore.imports.getResourceFromName(dreamcore.imports.resourceName), "]]..v.exportName..[[", ...)
              end
              ]]
          end
      end
  end
  return rw
end