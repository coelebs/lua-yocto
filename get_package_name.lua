M = {}

M.index = {}

-- Parse bitbake filename
local function parse_filename(filename)
    local basename = string.gsub(filename, "(.*/)(.*)", "%2")
    local index = string.find(basename, "_")
    local dot   = string.find(basename, ".bb") - 1
    local name
    local version
    if index == nil then
        name = string.sub(basename, 0, dot)
    else
        name = string.sub(basename, 0, index - 1)
        version = string.sub(basename, index + 1, dot)
        if version == "%" then
            version = nil
        end
    end

    return name, version
end

-- Add recipe to index. When it's an bbappend recipe and unversioned, it will
-- be added to all the available recipe versions
local function add_recipe(name, version, recipetype, recipe)
    if version == nil and recipetype == "append" then
        for _, v in pairs(M.index[name]) do
            table.insert(v, recipe)
        end
        return
    end

    if M.index[name][version] == nil then
        M.index[name][version] = {}
    end


    table.insert(M.index[name][version], recipe)
end

-- Parse path to return the package name
-- @param filename: path to the bitbake file
-- @param layer: the bitbake layer info
local function index_recipe(filename, layer)
    local recipetype
    if string.match(filename, "bb$") then
        recipetype = "recipe"
    elseif string.match(filename, "bbappend$") then
        recipetype = "append"
    else
        return nil
    end

    local recipe = {}
    recipe.filename = filename
    recipe.layer = layer

    local name, version = parse_filename(filename)

    if M.index[name] == nil then
        M.index[name] = {}
    end

    if version == nil and recipetype == "recipe" then
        version = "unversioned"
    end

    add_recipe(name, version, recipetype, recipe)
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

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local function pick_recipe()
    get_layers()

    pickers.new({}, {
        prompt_title = "Select recipe: ",
        finder = finders.new_table {
            results = M.index["busybox"]["1.35.0"],
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.filename,
                    ordinal = entry.filename,
                }
            end
        },
        sorter = conf.generic_sorter({}),
    }):find()
end

pick_recipe()
