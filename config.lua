Config = {}

-- No framework bridge is needed: the same resource runs on QB, ESX and Qbox.
Config.Command = 'scene'
Config.RemoveCommand = 'sceneremove'
Config.AdminAce = 'scenes.admin' -- Optional: permits removing another player's nearby scene.
Config.CreateAce = nil -- Set to 'scenes.create' if creation should require an ACE.
Config.MaxTextLength = 198
Config.PlacementDistance = 8.0
Config.RemoveDistance = 3.0
Config.MaxPerPlayer = 10
Config.MaxScenes = 500
Config.CooldownSeconds = 2
Config.LifetimeHours = 24 -- 0 = no expiry.
Config.Persistence = true -- Saved on every change to data/scenes.json; no database needed.
Config.TextHeight = 0.12
Config.MarkerSize = 0.16
Config.Defaults = { color = 'white', size = 'medium', distance = 'medium' }

Config.Colors = {
    { id = 'white', label = 'White', rgb = { 255, 255, 255 } },
    { id = 'red', label = 'Red', rgb = { 255, 72, 72 } },
    { id = 'orange', label = 'Orange', rgb = { 255, 155, 65 } },
    { id = 'yellow', label = 'Yellow', rgb = { 255, 220, 70 } },
    { id = 'green', label = 'Green', rgb = { 108, 225, 130 } },
    { id = 'cyan', label = 'Cyan', rgb = { 49, 215, 239 } },
    { id = 'blue', label = 'Blue', rgb = { 100, 166, 255 } },
    { id = 'purple', label = 'Purple', rgb = { 185, 135, 255 } },
    { id = 'pink', label = 'Pink', rgb = { 255, 143, 199 } }
}
Config.Sizes = {
    { id = 'small', label = 'Small', scale = 0.25 },
    { id = 'medium', label = 'Medium', scale = 0.35 },
    { id = 'large', label = 'Large', scale = 0.48 },
    { id = 'huge', label = 'Huge', scale = 0.65 }
}
Config.Distances = {
    { id = 'small', label = 'Small', meters = 3.0 },
    { id = 'medium', label = 'Medium', meters = 8.0 },
    { id = 'large', label = 'Large', meters = 15.0 },
    { id = 'huge', label = 'Huge', meters = 25.0 }
}
