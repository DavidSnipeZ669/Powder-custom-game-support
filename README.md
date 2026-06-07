
# Powder Game Manager

A standalone application for managing custom game support in Powder.

## Features

- Web-based interface for managing game configurations
- Add, edit, and delete custom games
- Dynamic configuration management

## Installation

1. Clone this repository
2. Run `npm install` to install dependencies
3. Run `launch_game_manager.bat` to start the server
4. Open `http://localhost:3000` in your browser

## Usage

The Game Manager provides a web interface where you can:
- View supported games
- Add new custom games with their configurations
- Edit existing game configurations
- Delete game configurations

## Technical Details

The Game Manager stores configurations in `game-manager/config/config.json` and provides
an HTTP API for managing game configurations.

## License

MIT
