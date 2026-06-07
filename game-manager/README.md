
# Powder Game Manager

This is a companion application for Powder that allows you to manage custom game support.

## Features

- View supported games
- Add new custom games
- Edit existing game configurations
- Delete game configurations

## How to Use

1. Double-click `launch_game_manager.bat` to start the Game Manager
2. Open your web browser and navigate to `http://localhost:3000`
3. Use the interface to manage your game configurations

## Technical Details

The Game Manager stores game configurations in `game-manager/config/config.json`.
When you add a new game, it will be added to this file and can be used by Powder.

## Notes

- This is a standalone application that works alongside Powder
- Game configurations added here will need to be manually integrated with Powder's main configuration
- For full integration, you may need to modify Powder's `app.asar` file
