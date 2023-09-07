local dbTable = class:create("ormTable", {
  connection = nil,
  workingTable = nil,
  ID_COLUMN_NAME = "_id",
  ID_COLUMN_TYPE = "int",
}, _, "orm")

function dbTable.public:new(...)
  local instance = self:createInstance()

  if instance and not instance:load(...) then
    instance:destroyInstance()
    return false
  end

  return instance
end

function dbTable.public:load(conn, tableName)
  if not isElement(conn) or type(tableName) ~= "string" then return false end
  dbTable.public.workingTable = tableName
  dbTable.public.connection = conn

  return true
end


function dbTable.public:create (columns, options)
  if type(columns) ~= "table" then return false end
  if type(options) ~= "string" then
    options = ""
  else
    options = ", "..options
  end

  if not dbTable.public.connection then return false end

  table.insert(columns, {
    name = dbTable.public.ID_COLUMN_NAME,
    type = dbTable.public.ID_COLUMN_TYPE,
    options = "NOT NULL PRIMARY KEY AUTO_INCREMENT"
  })

  local columnsQueries = {}

  for i,column in ipairs(columns) do
    local columnQuery = dbPrepareString(dbTable.public.connection, "`??` ??", column.name, column.type)

    if column.size and tonumber(column.size) then
      columnQuery = columnQuery .. dbPrepareString(dbTable.public.connection, "(??)", column.size)
    end

    if not column.options or type(column.options) ~= "string" then
      column.options = ""
    end

    if string.len(column.options) > 0 then
      columnQuery = columnQuery .. " " ..column.options
    end

    table.insert(columnsQueries, columnQuery)
  end

  local queryString = dbPrepareString(dbTable.public.connection, "CREATE TABLE IF NOT EXISTS `??` (" .. table.concat(columnsQueries, ", ") .. " " .. options .. ");", dbTable.public.workingTable )

  return dbExec(dbTable.public.connection, queryString)
end


function dbTable.public:insert(values, callback, ...)
  if type(values) ~= "table" or not next(values) then return false end


  if not dbTable.public.connection then return false end

  local columnsQueries = {}
  local valuesQueries = {}
  local valuesCount = 0

  for column, value in pairs(values) do
    table.insert(columnsQueries, dbPrepareString(dbTable.public.connection, "`??`", column))
    table.insert(valuesQueries, dbPrepareString(dbTable.public.connection, "?", value))
    valuesCount = valuesCount + 1
  end

  if valuesCount == 0 then
    return dbTable.private:retrieveQueryResults(dbTable.public.connection, dbPrepareString(dbTable.public.connection, "INSERT INTO `??`;", dbTable.public.workingTable), callback, ...)
  end

  local columnsQuery = dbPrepareString(dbTable.public.connection, "(" .. table.concat(columnsQueries, ",") .. ")")
  local valuesQuery = dbPrepareString(dbTable.public.connection, "(" .. table.concat(valuesQueries, ",") .. ")")
  local queryString = dbPrepareString(dbTable.public.connection, "INSERT INTO `??` " .. columnsQuery .. " VALUES " .. valuesQuery .. ";", dbTable.public.workingTable)

  return dbTable.private:retrieveQueryResults(dbTable.public.connection, queryString, callback, ...)
end


function dbTable.public:update(setFields, whereFields, callback, ...)
  if not next(setFields) or type(whereFields) ~= "table" then return false end
  if not dbTable.public.connection then return false end


	local setQueries = {}

  for column, value in pairs(setFields) do
		if value == "NULL" then
			table.insert(setQueries, dbPrepareString(dbTable.public.connection, "`??`=NULL", column))
		else
			table.insert(setQueries, dbPrepareString(dbTable.public.connection, "`??`=?", column, value))
		end
	end

  local whereQueries = {}

  if not whereFields then
		whereFields = {}
	end

  for column, value in pairs(whereFields) do
		table.insert(whereQueries, dbPrepareString(dbTable.public.connection, "`??`=?", column, value))
	end

  local queryString = dbPrepareString(dbTable.public.connection, "UPDATE `??` SET " .. table.concat(setQueries, ", "), dbTable.public.workingTable)

  if #whereQueries > 0 then
		queryString = queryString .. dbPrepareString(dbTable.public.connection, " WHERE " .. table.concat(whereQueries, " AND "))
	end
	queryString = queryString .. ";"


	return dbTable.private:retrieveQueryResults(dbTable.public.connection, queryString, callback, ...)
end


function dbTable.public:select(columns, whereFields, callback, ...)
  if type(columns) ~= "table" then return false end
  if not dbTable.public.connection then return false end

  local whereQueries = {}
	if not whereFields then
		whereFields = {}
	end
	for column, value in pairs(whereFields) do
		table.insert(whereQueries, dbPrepareString(dbTable.public.connection, "`??`=?", column, value))
	end
	local whereQueryString = ""
	if #whereQueries > 0 then
		whereQueryString = " WHERE " .. table.concat(whereQueries, " AND ")
	end

	-- COLUMNS
	-- SELECT *
	if not columns or type(columns) ~= "table" or #columns == 0 then
    return dbTable.private:retrieveQueryResults(dbTable.public.connection, dbPrepareString("SELECT * FROM `??` " .. whereQueryString ..";", dbTable.public.workingTable), callback, ...)
	end
	local selectColumns = {}
	for i, name in ipairs(columns) do
		table.insert(selectColumns, dbPrepareString(dbTable.public.connection, "`??`", name))
	end


	-- SELECT COLUMNS
	local queryString = dbPrepareString(dbTable.public.connection,
  "SELECT " .. table.concat(selectColumns, ",") .." FROM `??` " .. whereQueryString ..";",
  dbTable.public.workingTable
	)
	return dbTable.private:retrieveQueryResults(dbTable.public.connection, queryString, callback, ...)
end


function dbTable.public:delete(whereFields, callback, ...)
  if not dbTable.public.connection then return false end

  local whereQueries = {}
	if not whereFields then
		whereFields = {}
	end
  
  for column, value in pairs(whereFields) do 
    table.insert(whereQueries, dbPrepareString(dbTable.public.connection, "`??`=?", column, value))
  end

  local whereQueryString = ""
  
  if #whereQueries > 0 then 
    whereQueryString = " WHERE " .. table.concat(whereQueries, " AND ")
  end

  local queryString = dbPrepareString(dbTable.public.connection,
    "DELETE FROM `??` " .. whereQueryString ..";",
    dbTable.public.workingTable
  )

  return dbTable.private:retrieveQueryResults(dbTable.public.connection, queryString, callback, ...)
end



function dbTable.private:retrieveQueryResults(connection, queryString, callback, ...)
  if not isElement(connection) then
    return false
  end
  if type(queryString) ~= "string" then
    return false
  end
  if type(callback) ~= "function" then
    local handle = dbQuery(connection, queryString)
    return dbPoll(handle, -1)
  else
    return not not dbQuery(function (queryHandle, args)
      local result = dbPoll(queryHandle, 0)
      if type(args) ~= "table" then
        args = {}
      end
      dbTable.private:executeCallback(callback, result, unpack(args))

    end, connection, queryString)
  end
end




function dbTable.private:executeCallback(callback, ...)
  if type(callback) ~= "function" then
    return false
  end
  local success, err = pcall(callback, ...)
  if not success then
    return false
  end
  return true
end