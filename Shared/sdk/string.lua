local imports = {
    string = string,
}


local string = class:create("string", utf8)
for i, j in pairs(imports.string) do
    string.public[i] = (not string.public[i] and j) or string.public[i]
end



local __string_gsub = string.public.gsub
function string.public.gsub(baseString, matchWord, replaceWord, matchLimit, isStrictcMatch, matchPrefix, matchPostfix)
    if not baseString or (type(baseString) ~= "string") or not matchWord or (type(matchWord) ~= "string") or not replaceWord or (type(replaceWord) ~= "string") then return false end
    matchPrefix, matchPostfix = (matchPrefix and (type(matchPrefix) == "string") and matchPrefix) or "", (matchPostfix and (type(matchPostfix) == "string") and matchPostfix) or ""
    matchWord = (isStrictcMatch and "%f[^"..matchPrefix.."%z%s]"..matchWord.."%f["..matchPostfix.."%z%s]") or matchPrefix..matchWord..matchPostfix
    return __string_gsub(baseString, matchWord, replaceWord, matchLimit)
end

function string.public.parse(baseString)
    if not baseString then return false end
    if tostring(baseString) == "nil" then return
    elseif tostring(baseString) == "false" then return false
    elseif tostring(baseString) == "true" then return true
    else return tonumber(baseString) or baseString end
end




function string.public.split(baseString, separator)
    if not baseString or (type(baseString) ~= "string") or not separator or (type(separator) ~= "string") then return false end
    baseString = baseString..separator
    local result = {}
    for matchValue in string.public.gmatch(baseString, "(.-)"..separator) do
        table.insert(result, matchValue)
    end
    return result
end
