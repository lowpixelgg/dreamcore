local bundler = bundler:import()

function import(...)
    local cArgs = {...}
    
    if cArgs[1] == true then
        table.remove(cArgs, 1)

        local buildImports, cImports, __cImports = {}, {}, {}
        local isCompleteFetch = false
        if (#cArgs <= 0) then
            table.insert(buildImports, "core")
        elseif cArgs[1] == "*" then
            isCompleteFetch = true
            for i, j in pairs(bundler.private.buffer) do
                table.insert(buildImports, i)
            end
        else
            buildImports = cArgs
        end
        for i = 1, #buildImports, 1 do
            local j = buildImports[i]

            if (j ~= "imports") and bundler.private.buffer[j] and not __cImports[j] then
                __cImports[j] = true

                table.insert(cImports, {
                    index = bundler.private.buffer[j].module or j,
                    rw = bundler.private.buffer["imports"].rw..[[
                    ]]..bundler.private.buffer[j].rw
                })
            end
        end
        if #cImports <= 0 then return false end
        return cImports, isCompleteFetch
    else
        cArgs = ((#cArgs > 0) and ", \""..table.concat(cArgs, "\", \"").."\"") or ""
        return [[
        local cImports, isCompleteFetch = call(getResourceFromName("dreamcore"), "import", true]]..cArgs..[[)
        if not cImports then return false end
        local cReturns = (not isCompleteFetch and {}) or false
        for i = 1, #cImports, 1 do
            local j = cImports[i]
            assert(loadstring(j.rw))()
            if cReturns then cReturns[(#cReturns + 1)] = dreamcore[(j.index)] end
        end
        if isCompleteFetch then return dreamcore
        else return unpack(cReturns) end
        ]]
    end
    return false
end