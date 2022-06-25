M = {}

M.index = {}

-- Parse path to return the package name
-- @param filename: path to the bitbake file
-- @param layer: the bitbake layer info
local function index_recipe(filename, layer)
    if not (string.match(filename, "bb$") or string.match(filename, "bbappend$")) then
        return nil
    end

    local basename = string.gsub(filename, "(.*/)(.*)", "%2")
    local index = string.find(basename, "_")
    local name
    if index == nil then
        local dot   = string.find(basename, "%.") - 1
        name = string.sub(basename, 0, dot)
    else
        name = string.sub(basename, 0, index - 1)
    end

    local recipe = {}
    recipe.filename = filename
    recipe.layer = layer

    if M.index[name] == nil then
        M.index[name] = {}
    end

    table.insert(M.index[name], recipe)
end

-- Iterate over every file in the layer directory with a bitbake extension and parse the package
-- @param layer: layer directory
local function index_layer(layer)
    local f = io.popen("find " .. layer.path .. " -iname \"*.bb\" -o -iname \"*.bbappend\"")
    if f ~= nil then
        local output = f:read("*a")
        for line in output:gmatch("[^\n]+") do
            index_recipe(line, layer)
        end
    end
end

-- Parse layer path from bb layer line
-- @param line: bb layer line
-- @param index: bb layer index
local function get_layer(line, index)
    local layer = {}
    layer.index = index

    local el = line:gmatch("%S+")
    layer.name = el()
    layer.path = el()
    layer.priority = el()

    return layer
end

-- Get the layers from bitbake-layers and parse them
local function get_layers()
    local f = io.popen("bitbake-layers show-layers")
    if f == nil then
        return nil
    end

    local output = f:read("*a")
    for line in output:gmatch("[^\n]+") do
        if string.match(line, "/") then
            local layer = get_layer(line)
            if layer ~= nil then
                index_layer(layer)
            end
        end
    end
    return f:close()
end

if get_layers() then
    print(#M.index)
else
    print("No layers found, please run in yocto sourced shell")
end
