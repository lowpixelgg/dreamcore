local imports = {
  dbPrepareString = dbPrepareString,
  dbConnect = dbConnect,
  dbExec = dbExec,
  type = type,
  tonumber = tonumber,
  tostring = tostring
}


local database = class:create("database", {
  connection = nil,
  table = dbTable
})


function database.public:create(...)
  local instance = self:createInstance()

  if instance and not instance:load(...) then
    instance:destroyInstance()
    return false
  end

  return instance
end


function database.public:destroy(...)
  if not database.public.isInstance(self) then return false end
  return self:unload(...)
end


function database.public:load(conn)
  if imports.type(conn) ~= "table" or not conn then return false end

  local host = database.private:prepareDatabaseOptionsString {
    host = conn.host,
    port = conn.port,
    dbname = conn.dbName
  }

  local options = database.private:prepareDatabaseOptionsString(conn.options)

  database.public.connection = imports.dbConnect(conn.dbType, host, conn.username, conn.password, options)

  if not self.connection then
    return false
  end

  return true
end

function database.public:table(tableName)
  local instance = dbTable:new(database.public.connection, tableName)
  return instance
end

function database.private:prepareDatabaseOptionsString(options)
  if not options then
    return ""
  end
  local optionsStrings = {}
  for key, value in pairs(options) do
    table.insert(optionsStrings, imports.tostring(key) .. "=" .. imports.tostring(value))
  end

  return table.concat(optionsStrings, ";")
end