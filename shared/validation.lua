SceneRules = {}

function SceneRules.option(options, id)
    for _, entry in ipairs(options) do
        if entry.id == id then return entry end
    end
end

function SceneRules.finite(value)
    return type(value) == 'number' and value == value and math.abs(value) < 100000.0
end

function SceneRules.integer(value)
    return type(value) == 'number' and value >= 0 and value < 9007199254740991 and value % 1 == 0
end

function SceneRules.coords(value)
    return type(value) == 'table' and SceneRules.finite(value.x)
        and SceneRules.finite(value.y) and SceneRules.finite(value.z)
end

function SceneRules.text(value)
    if type(value) ~= 'string' or #value > Config.MaxTextLength * 4 then
        return nil, 'Your scene text is too long.'
    end
    -- GTA formatting tokens are not allowed in player text.
    value = value:gsub('~', ''):gsub('%c', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    local length = utf8.len(value)
    if not length or length < 1 then return nil, 'Enter some scene text.' end
    if length > Config.MaxTextLength then
        return nil, ('Use no more than %s characters.'):format(Config.MaxTextLength)
    end
    return value
end

function SceneRules.payload(data)
    if type(data) ~= 'table' then return nil, 'Invalid scene.' end
    local text, err = SceneRules.text(data.text)
    if not text then return nil, err end
    if not SceneRules.coords(data.coords) then return nil, 'Invalid placement.' end
    if not SceneRules.option(Config.Colors, data.color)
        or not SceneRules.option(Config.Sizes, data.size)
        or not SceneRules.option(Config.Distances, data.distance) then
        return nil, 'Choose a valid color, size and distance.'
    end
    return { text = text, coords = { x = data.coords.x, y = data.coords.y, z = data.coords.z },
        color = data.color, size = data.size, distance = data.distance }
end

function SceneRules.distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)
end
