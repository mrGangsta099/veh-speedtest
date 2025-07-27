# veh-speedtest

A modern and lightweight FiveM resource for vehicle speed testing with an elegant HUD interface, milestone tracking, and record keeping.

## Features

- **Speed Testing**: Time how long it takes for vehicles to reach target speeds
- **Modern HUD**: Clean, minimalist interface with progress bar
- **Speed Milestones**: Get notified when reaching speed intervals (every 50 km/h or mph)
- **Record Keeping**: Automatic saving of best times per vehicle model
- **Sound Effects**: Audio feedback for milestones and events
- **Dual Units**: Support for both km/h and mph
- **Real-time Display**: Live speed and time tracking

## Installation

1. Download or clone this repository
2. Place the `veh-speedtest` folder in your FiveM server's `resources` directory
3. Add `start veh-speedtest` to your `server.cfg`
4. Restart your server or start the resource manually

## Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/startrun` | Start a speed test | `/startrun <target_speed>` |
| `/stoprun` | Stop the current speed test | `/stoprun` |
| `/showchrono` | Display saved records | `/showchrono` |

### Examples
```
/startrun 200    # Start a test to reach 200 km/h (or mph)
/stoprun         # Stop the current test
/showchrono      # View your records
```

## Configuration

Edit the configuration at the top of `client.lua`:

```lua
local Config = {
    speedUnit = 'km/h',           -- Speed unit ('km/h', 'mph')
    sounds = true,                -- Enable sounds
    milestones = true,            -- Enable speed milestones
    hudPosition = {x = 0.085, y = 0.75},  -- HUD position on screen
    hudSize = {width = 0.14, height = 0.08}  -- HUD dimensions
}
```

### Configuration Options

- **speedUnit**: Choose between `'km/h'` or `'mph'`
- **sounds**: Enable/disable sound effects
- **milestones**: Enable/disable milestone notifications
- **hudPosition**: Adjust HUD position (x, y coordinates from 0.0 to 1.0)
- **hudSize**: Adjust HUD dimensions

## How It Works

1. Get in any vehicle
2. Use `/startrun <speed>` to begin timing
3. Accelerate to reach the target speed
4. The timer stops automatically when the target is reached
5. Your time is saved as a record for that vehicle model
6. View your records with `/showchrono`

## Features in Detail

### HUD Interface
- **Clean Design**: Minimal, modern interface that doesn't obstruct gameplay
- **Progress Bar**: Visual indicator of speed progress
- **Real-time Updates**: Live speed and time display updated every frame
- **Smooth Animation**: Fluid progress bar and counter updates

### Milestone System
- Automatically tracks speed milestones every 50 units
- Only activates for speeds above 100 km/h (62 mph)
- Audio and visual notifications when milestones are reached
- Timestamps for each milestone

### Record System
- Saves best times per vehicle model and target speed
- Persistent storage during the session
- Detailed vehicle information (manufacturer and model)
- Easy viewing with the `/showchrono` command

## Requirements
- No additional dependencies required

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/mrGangsta099/veh-speedtest/edit/main/LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

If you encounter any issues or have suggestions:
- Open an issue on GitHub
- Provide detailed information about the problem
- Include your FiveM server version and any error messages

## Changelog

### v1.0.0
- Initial release
- Basic speed testing functionality
- Modern HUD interface
- Milestone tracking
- Record keeping system
- Sound effects
- Dual unit support (km/h and mph)
