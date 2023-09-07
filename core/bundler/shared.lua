local bundler = bundler:import()

bundler.private:createBuffer("imports", _, [[
    if not dreamcore then
        dreamcore = {}
        ]]..bundler.private:createModule("namespace")..[[
        ]]..bundler.private:createUtils()..[[
        dreamcore.imports = {
            resourceName = "dreamcore",
            type = type,
            pairs = pairs,
            call = call,
            pcall = pcall,
            assert = assert,
            setmetatable = setmetatable,
            outputDebugString = outputDebugString,
            loadstring = loadstring,
            getThisResource = getThisResource,
            getResourceFromName = getResourceFromName,
            table = table,
            string = string
        }
    end
]])
