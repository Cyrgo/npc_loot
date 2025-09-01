# QBX NPC Body Looting System

A FiveM resource for the QBX Framework that allows players to search dead NPC bodies for loot.

## Features

- **Body Searching**: Search dead NPCs for cash and items
- **Configurable Rewards**: Customizable loot tables and reward chances
- **Target Integration**: Works with ox_target or manual key press system

## Installation

This resource should be added as a git submodule to your QBX server.

1. Clone or add as submodule to your resources folder
2. Add `ensure npc_loot` to your server.cfg
3. Configure the settings in `config.lua`
4. Restart your server

OR just add to [standalone] foler.

## Configuration

Edit `config.lua` to customize:

- Search reward chances and amounts
- Animation settings
- Target system preferences
- Debug mode options

## Dependencies

- QBX Core
- ox_lib
- ox_inventory
- ox_target (if using target mode)

## Usage

### For Players

**Searching Bodies:**
1. Find a dead NPC
2. Use the interaction to search (target menu or E key)
3. Complete the progress bar to find loot

### For Developers

The resource follows QBX patterns and integrates with:
- Inventory system
- Target system
- Anti-exploit systems

## License

MIT License