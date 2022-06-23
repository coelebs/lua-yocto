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
        end
    end
end

local function get_layer_path(line)
    for w in line:gmatch("%S+") do
        if string.match(w, "/") then
            return w
        end
    end

    return nil
end

local function get_layers()
    local f = io.popen("bitbake-layers show-layers")
    if f ~= nil then
        local output = f:read("*a")
        for line in output:gmatch("[^\n]+") do
            if string.match(line, "/") then
                local layer = get_layer_path(line)
                if layer ~= nil then
                    index_layer(layer)
                end
            end
        end
    end
end

print(get_layers())
print(#M.index)
