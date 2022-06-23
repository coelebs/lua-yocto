M = {}

M.index = {}

local function get_package(filename)
    if not (string.match(filename, "bb$") or string.match(filename, "bbappend$")) then
        return nil
    end

    local basename = string.gsub(filename, "(.*/)(.*)", "%2")
    -- Convention is PACKAGENAME_PACKAGEVERSION.bb{append}
    local index = string.find(basename, "_")
    if index == nil then
        local dot   = string.find(basename, "%.") - 1
        return {string.sub(basename, 0, dot), filename}
    else
        return {string.sub(basename, 0, index - 1), filename}
    end
end

local function index_layer(layer)
    local f = io.popen("find " .. layer .. " -iname \"*.bb\"")
    if f ~= nil then
        local output = f:read("*a")
        for line in output:gmatch("[^\n]+") do
            M.index[#M.index+1] = get_package(line)
            print(M.index[#M.index][1], M.index[#M.index][2])
        end
    end
end

print(index_layer("/home/vin/projects/yocto/poky/meta"))
print(index_layer("/home/vin/projects/yocto/poky/meta-poky/"))
print(index_layer("/home/vin/projects/yocto/poky/meta-yocto-bsp//"))

print(#M.index)
