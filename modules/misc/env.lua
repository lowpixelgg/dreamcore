local env = class:create("env");

function env.public.config()
  local cFile = fileOpen(".env", true)
  if not cFile then return false end
  local size = fileGetSize(cFile)
  local data = fileRead(cFile, size)
  fileClose(cFile)

  local formatString = [[
    process = {};
    process.env = ]]..data..[[
  ]]

  loadstring(formatString)();
  
  return true;
end