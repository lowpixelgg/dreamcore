local imports = {
  type = type,
  pairs = pairs,
  tostring = tostring,
  tonumber = tonumber,
  toJSON = toJSON,
  fromJSON = fromJSON,
  select = select,
  unpack = unpack,
  print = print,
  getmetatable = getmetatable,
  loadstring = loadstring
}


local table = class:create("table", table)
table.private.inspectTypes = {
  raw = {
    ["nil"] = true,
    ["string"] = true,
    ["number"] = true,
    ["boolean"] = true
  }
}

function table.public.length(baseTable)
  if not baseTable or (imports.type(baseTable) ~= "table") then return false end
  return (baseTable.__T and baseTable.__T.length) or #baseTable
end

function table.public.pack(...)
  return {__T = {
    length = imports.select("#", ...)
  }, ...}
end

function table.public.push(baseTable, insert)
    baseTable[#baseTable + 1] = insert
end

function table.public.unpack(baseTable)
  if not baseTable or (imports.type(baseTable) ~= "table") then return false end
  return imports.unpack(baseTable, 1, table.public.length(baseTable))
end

function table.public.encode(baseTable, encoding)
  if not baseTable or (imports.type(baseTable) ~= "table") then return false end
  if encoding == "json" then return imports.toJSON(baseTable) end
end

function table.public.decode(baseString, encoding)
  if not baseString or (imports.type(baseString) ~= "string") then return false end
  if encoding == "json" then return imports.fromJSON(baseString ) end
end

function table.public.clone(baseTable, isRecursive)
  if not baseTable or (imports.type(baseTable) ~= "table") then return false end
  local __baseTable = {}
  for i, j in imports.pairs(baseTable) do
      if (imports.type(j) == "table") and isRecursive then
          __baseTable[i] = table.public.clone(j, isRecursive)
      else
          __baseTable[i] = j
      end
  end
  return __baseTable
end

function table.public.last(baseTable)
  if not baseTable or (imports.type(baseTable) ~= "table") then return false end

  local last_key = nil

  for key, value in pairs(baseTable) do
    if last_key == nil or key > last_key then
      last_key = key
    end
  end

  return last_key
end


function table.public.find(baseTable, condiction)
  if not baseTable or (imports.type(baseTable) ~= "table") then return false end
  for i, v in pairs(baseTable) do
    local c = condiction(v, i)
    if (c) then
      return i,v
    end
  end
end


function table.public.filter(baseTable, condiction)
  if not baseTable or (imports.type(baseTable) ~= "table") then return false end
  local filteredTable = {}
  for i, v in pairs(baseTable) do
    if condiction(v, i) then
      table.public.push(filteredTable, v)
    end
  end

  return filteredTable
end