local orm = class:create("orm", {
  connection = nil,
  table = dbTable
})


function orm.public:create(...)
  local instance = self:createInstance()

  if instance and not instance:load(...) then
    instance:destroyInstance()
    return false
  end

  return instance
end


function orm.public:destroy(...)
  if not orm.public.isInstance(self) then return false end
  return self:unload(...)
end


function orm.public:load(conn)
  if type(conn) ~= "table" or not conn then return false end

  local host = orm.private:prepareormOptionsString {
    host = conn.host,
    port = conn.port,
    dbname = conn.dbName
  }

  local options = orm.private:prepareormOptionsString(conn.options)

  orm.public.connection = dbConnect(conn.dbType, host, conn.username, conn.password, options)

  if not self.connection then
    return false
  end

  return true
end

function orm.public:table(tableName)
  local instance = ormTable:new(orm.public.connection, tableName)
  return instance
end

function orm.private:prepareormOptionsString(options)
  if not options then
    return ""
  end
  local optionsStrings = {}
  for key, value in pairs(options) do
    table.insert(optionsStrings, tostring(key) .. "=" .. tostring(value))
  end

  return table.concat(optionsStrings, ";")
end