local file = class:create("file")
file.public.validPointers = {
  rootDir = "~/",
  localDir = "@/"
}

function file.public:exists(path)
  if not path or (type(path) ~= "string") then return false end
  return fileExists(path) or false
end

function file.public:delete(path)
  if not file.public:exists(path) then return false end
  return fileDelete(path)
end

function file.public:read(path)
  if not file.public:exists(path) then return false end
  local cFile = fileOpen(path, true)
  if not cFile then return false end
  local size = fileGetSize(cFile)
  local data = fileRead(cFile, size)
  fileClose(cFile)
  return data, size
end

function file.public:write(path, data)
  if not path or (type(path) ~= "string") or not data then return false end
  local cFile = fileCreate(path)
  if not cFile then return false end
  fileWrite(cFile, data)
  fileClose(cFile)
  data = nil
  collectgarbage()
  return true
end

function file.public:parseURL(path)
  if not path or (type(path) ~= "string") then return false end
  local extension = string.match(path, "^.+%.(.+)$")
  extension = (extension and string.match(extension, "%w") and extension) or false
  local pointer, pointerEndN = nil, nil
  for i, j in pairs(file.public.validPointers) do
      local startN, endN = string.find(path, j)
      if startN and endN and (startN == 1) then
          pointer, pointerEndN = i, endN + 1
          break
      end
  end
  local url = string.sub(path, pointerEndN or 1, #path - ((extension and (#extension + 1)) or 0))
  if string.match(url, "%w") then
      local cURL = {
          pointer = pointer or false,
          url = (extension and (url.."."..extension)) or url,
          extension = extension,
          directory = string.match(url, "(.*[/\\])") or false
      }
      cURL.file = (cURL.extension and string.sub(cURL.url, (cURL.directory and (#cURL.directory + 1)) or 1)) or false
      return cURL
  end
  return false
end

function file.public:resolveURL(path, chroot)
  if not path or (type(path) ~= "string") or (chroot and (type(chroot) ~= "string")) then return false end
  local cURL = file.public:parseURL(path)
  if not cURL then return false end
  cURL.url = (cURL.pointer and string.gsub(cURL.url, file.public.validPointers[(cURL.pointer)], "")) or cURL.url
  local cDirs = string.split(cURL.url, "/")
  if #cDirs > 0 then
      if chroot then
          chroot = file.public:parseURL(((string.sub(chroot, #chroot) ~= "/") and chroot.."/") or chroot)
          chroot = (chroot and chroot.pointer and string.gsub(chroot.url, file.public.validPointers[(chroot.pointer)], "")) or chroot
      end
      cURL.url = false
      local vDirs = {}
      for i = 1, #cDirs, 1 do
          local j = cDirs[i]
          if j == "..." then
              if not chroot or (chroot ~= cURL.url) then
                  table.remove(vDirs, #vDirs)
              end
          else
              table.insert(vDirs, j)
          end
          cURL.url = table.concat(vDirs, "/")
          local __cURL = file.public:parseURL(cURL.url)
          cURL.url = (__cURL and not __cURL.file and cURL.url.."/") or cURL.url
      end
      cURL.url = ((cURL.pointer and file.public.validPointers[(cURL.pointer)]) or "")..(cURL.url or "")
  end
  return cURL.url
end