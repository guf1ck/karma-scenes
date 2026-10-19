<div align="center">

# 🌟 Karma Developments — FREE Scenes V

### NoPixel V-inspired 3D text placement for FiveM

**QBCore • ESX • Qbox • Standalone**

[![FiveM](https://img.shields.io/badge/FiveM-GTA%20V-orange)](https://fivem.net/)
![Version](https://img.shields.io/badge/version-1.0.1-purple)
![Price](https://img.shields.io/badge/price-FREE-brightgreen)
![OneSync](https://img.shields.io/badge/OneSync-required-blue)

**[🌐 Karma Developments Store](https://karmadevelopments.shop)** · **[🛒 Browse Resources](https://karmadevelopments.shop/catalogue)** · **[💬 Discord / Support](https://dsc.gg/karmadevelopments)**

</div>

---

## 📖 About

**Karma Scenes V** is a free FiveM resource that lets players place customizable **3D text in the game world**. Point at a nearby surface, choose your text and appearance in the clean **PLACE SCENE** editor, and submit to create an in-world scene for roleplay.

Great for environmental storytelling, roleplay notes, location labels, and temporary messages. The resource works with **QBCore, ESX, Qbox, or standalone** servers, using the available framework for notifications when detected. No SQL database is needed.

> **Note:** “NoPixel V-inspired” refers to the visual direction. This is a separate resource from Karma Developments, not an official NoPixel release.

## ✨ Features

- 📝 Custom in-world 3D text, with a configurable maximum of **198 characters** by default.
- 🎯 Camera-based placement targeting nearby surfaces, with an in-game placement marker.
- 🖥️ Simple NUI editor with **Text, Color, Font Size, Distance**, and **Submit**.
- 🎨 **9 colors:** white, red, orange, yellow, green, cyan, blue, purple, and pink.
- 🔠 **4 font sizes:** Small, Medium, Large, Huge.
- 📏 **4 visibility distances:** Small (3 m), Medium (8 m), Large (15 m), Huge (25 m).
- 💾 Optional JSON persistence; scenes are saved in `data/scenes.json` after changes.
- ⏳ Configurable automatic expiration (**24 hours** by default; set to `0` for no expiration).
- 🗑️ Remove your own nearby scenes; optionally let admins remove other players' scenes through ACE.
- 🛡️ Server-side validation, creation cooldowns, placement-distance checks, and configurable scene limits.
- 🌍 Routing bucket-aware synchronization, so scenes are distributed only to players in their matching bucket.
- 📢 Framework-aware notifications, with a GTA notification-feed fallback for standalone servers.
- ⚙️ Customizable defaults and limits in `config.lua`.
- ✅ No framework bridge or SQL dependency required.

## 📋 Requirements

- A FiveM server running **GTA V** with **OneSync enabled** (declared by the resource as `dependency '/onesync'`).
- **Lua 5.4** support, as specified in `fxmanifest.lua`.
- A writable resource folder when persistence is enabled.

**Frameworks:** QBCore, ESX, Qbox and Standalone. Framework integrations are used for notifications; the underlying scene system is framework-independent.

## 📦 Installation

1. Download the resource and extract the ZIP archive.
2. Keep the folder name **`karma-scenes`** and place it in your server resources directory, for example:

   ```text
   resources/[standalone]/karma-scenes/
   ```

3. Add the following line to `server.cfg` (after any general OneSync/server configuration):

   ```cfg
   ensure karma-scenes
   ```

4. Make sure **OneSync is enabled**, and verify that the server can write to the resource's `data/` directory if using persistence.
5. Restart the server, or start the resource with `ensure karma-scenes` from the server console.
6. Join the server and type **`/scene`** to create your first scene.

**No SQL import is necessary.** The resource uses a JSON file for persistence.

## 🎮 How to Use

### Place a scene

1. Stand **on foot** and type **`/scene`** in chat.
2. Aim your camera at a nearby world surface, up to **8 meters** away by default.
3. When the red placement marker appears at a valid spot, press **E** to open the scene editor. The placement code also accepts **Enter** or the primary mouse button.
4. Enter your text, choose a **color**, **font size**, and **visibility distance**.
5. Click **SUBMIT** to save the scene. The server validates the request and sends a success/error notification.

While aiming, use **Esc/Back** to cancel. Typing `/scene` again also toggles off placement mode. In the editor, use **Esc** or **CLOSE** to exit.

### Remove a scene

Walk near one of your scenes and type:

```text
/sceneremove
```

The command targets the **nearest scene you have permission to remove** within **3 meters** by default. Admins with the configured ACE permission can also remove nearby scenes owned by others.

### Commands

| Command | Default behavior |
|---|---|
| `/scene` | Start or cancel 3D text placement mode |
| `/sceneremove` | Remove the nearest eligible scene within the configured removal range |

Command names can be changed in `config.lua`.

## ⚙️ Configuration

Edit **`karma-scenes/config.lua`** to customize the resource. These are the defaults included with **v1.0.1**:

```lua
Config.Command = 'scene'
Config.RemoveCommand = 'sceneremove'
Config.AdminAce = 'scenes.admin'
Config.CreateAce = nil

Config.MaxTextLength = 198
Config.PlacementDistance = 8.0
Config.RemoveDistance = 3.0
Config.MaxPerPlayer = 10
Config.MaxScenes = 500
Config.CooldownSeconds = 2
Config.LifetimeHours = 24
Config.Persistence = true

Config.TextHeight = 0.12
Config.MarkerSize = 0.16
Config.Defaults = { color = 'white', size = 'medium', distance = 'medium' }
```

| Setting | What it controls |
|---|---|
| `Config.Command` | Chat command for placement |
| `Config.RemoveCommand` | Chat command for deletion |
| `Config.AdminAce` | ACE permission that allows removing other players' scenes |
| `Config.CreateAce` | Optional ACE permission required for creation; `nil` allows normal players to create |
| `Config.MaxTextLength` | Maximum scene text length, counted in UTF-8 characters |
| `Config.PlacementDistance` | Maximum placement distance from the player |
| `Config.RemoveDistance` | Removal search radius |
| `Config.MaxPerPlayer` | Maximum scenes associated with one player's license identifier |
| `Config.MaxScenes` | Server-wide scene cap |
| `Config.CooldownSeconds` | Minimum interval between scene creation requests |
| `Config.LifetimeHours` | Scene expiration period; `0` disables expiration |
| `Config.Persistence` | Enable/disable JSON-based storage |
| `Config.TextHeight` | Vertical offset for rendered text |
| `Config.MarkerSize` | Placement marker dimensions |
| `Config.Defaults` | Default editor choices |

You can also adjust the entries in `Config.Colors`, `Config.Sizes`, and `Config.Distances`. Keep their IDs consistent with `Config.Defaults`.

### 🔐 Optional ACE permissions

To let a staff group delete scenes created by other players:

```cfg
add_ace group.admin scenes.admin allow
```

To require an ACE permission to **create** scenes, first set:

```lua
Config.CreateAce = 'scenes.create'
```

Then grant it to an appropriate group:

```cfg
add_ace group.admin scenes.create allow
```

> These are examples. Adapt the ACE group/principals to your server. When `Config.CreateAce = nil` (the default), creation is not ACE-gated. The admin permission does **not** bypass proximity or other scene validation checks.

## 🗂️ Resource Structure

```text
karma-scenes/
├── fxmanifest.lua
├── config.lua
├── client/
│   ├── main.lua              # Placement, drawing, NUI callbacks, commands
│   └── notify.lua            # Framework-aware notifications
├── server/
│   └── main.lua              # Sync, ownership, limits, expiry, persistence
├── shared/
│   └── validation.lua        # Shared input validation
├── data/
│   └── scenes.json           # Saved scene data
└── web/
    ├── index.html           # Scene editor layout
    ├── style.css            # Editor styling
    ├── app.js               # Editor interactions
    └── fonts/               # Bundled Barlow font assets and license text
```

## 💾 Storage & Synchronization

When `Config.Persistence` is enabled, the resource saves scene records in **`data/scenes.json`** after creation/removal and expiration. Scenes also have an owner (the player's FiveM **license** identifier), a routing bucket, and an expiration timestamp.

- **Default lifetime:** 24 hours. Expired scenes are removed automatically.
- **Restart behavior:** Persisted, unexpired scenes are loaded at resource startup.
- **Visibility:** Each player's client receives scenes from their current routing bucket and draws them only when they are within that scene's configured display distance.
- **Ownership:** Scene creators can remove their own scenes. Admins can be granted additional removal permissions.
- **Backups:** Back up `data/scenes.json` before editing, replacing, or reinstalling the resource. The resource attempts to preserve a recovery copy when it detects invalid saved JSON.

> For a clean public release, consider shipping `data/scenes.json` initialized as `{"version":1,"nextId":1,"scenes":[]}` so no test data is included.

## 🧩 Custom Notifications

`client/notify.lua` selects a notification backend based on running resources:

1. `qbx_core` (Qbox)
2. `qb-core` (QBCore)
3. `es_extended` (ESX)
4. GTA V native notification feed (Standalone fallback)

To integrate a custom notification script, edit the `Config.Notify` function in **`client/notify.lua`**.

## ❓ Troubleshooting

**`/scene` does not open anything**  
Check that `karma-scenes` started successfully, OneSync is enabled, and the NUI has finished loading. The command only starts placement when the player is alive and on foot.

**“Aim at a surface within reach.”**  
Move closer and aim at a static surface or object within `Config.PlacementDistance`. The placement ray excludes players and vehicles.

**My scene is not visible**  
Check your selected visibility distance, your distance from the text, whether the text is on screen, and whether the scene has expired. Scenes are scoped to routing buckets.

**A scene disappears after some time**  
The default expiration period is 24 hours. Change `Config.LifetimeHours` if needed.

**“Scene could not be saved.”**  
Check write permissions on the resource folder and `data/scenes.json`. Inspect your server console for storage errors.

**I cannot remove another player's scene**  
This is intentional. Configure `Config.AdminAce` and grant the appropriate ACE to trusted staff.

**The creation limit was reached**  
Check `Config.MaxPerPlayer` (default 10) and `Config.MaxScenes` (default 500), or remove existing scenes.

## ❤️ Support Karma Developments

Enjoy using **FREE Scenes V**? Supporting our work helps us release more free resources and improvements for the FiveM community.

- 🌐 **Store:** [karmadevelopments.shop](https://karmadevelopments.shop)
- 🛒 **More scripts & resources:** [Karma Developments Catalogue](https://karmadevelopments.shop/catalogue)
- 💬 **Community, downloads, updates & support:** [Karma Developments Discord](https://dsc.gg/karmadevelopments)

If this resource helps your server, consider **starring this GitHub repository ⭐**, sharing it with other FiveM developers, and checking out our other releases.

## 📄 Credits & License

**Published by:** Karma Developments  
**Resource:** Karma Scenes V  
**Manifest version:** `1.0.1`  
**Manifest author field:** `Ocean`  
**Bundled fonts:** Barlow (see `web/fonts/Barlow-OFL.txt` for the font's license terms).

The script is distributed as a **free resource**. A separate software license for the script was **not specified in the supplied ZIP**. Add your chosen `LICENSE` file before publicly granting reuse, redistribution, or modification rights.

---

<div align="center">

**Made for the FiveM community by Karma Developments 💜**

[**Visit Our Store**](https://karmadevelopments.shop) · [**Join Our Discord**](https://dsc.gg/karmadevelopments)

</div>
