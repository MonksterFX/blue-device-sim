# Project Structure

## Directory Organization

### Core/
- Core functionality and business logic
- `Bluetooth/`: Bluetooth communication and management
  - BluetoothManager and related core bluetooth functionality

### Features/
- Main feature modules of the application
- Each feature should be self-contained with its own Views, ViewModels, and Models
- Example: Settings, Device Management, etc.

### UI/
- Reusable UI components
- Shared styles and themes
- Custom SwiftUI views and modifiers

### Services/
- Network services
- Data persistence
- Third-party integrations

### Utilities/
- Helper functions
- Extensions
- Common utilities

### Configuration/
- Environment configuration
- App settings
- Feature flags

### Localization/
- Localized strings
- Language-specific resources

### Resources/
- Assets
- Fonts
- Configuration files
- Other static resources

## Architecture Guidelines

- Following MVVM architecture with SwiftUI
- Each feature module should be independent and follow the same structure:
  - Views/
  - ViewModels/
  - Models/
  - Services/ (if needed)

## Best Practices

- Use Swift's latest features and protocol-oriented programming
- Prefer value types (structs) over classes
- Follow Apple's Human Interface Guidelines
- Implement proper state management using @Published and @StateObject
- Use async/await for concurrency
- Handle proper error management using Result type

## Testing

- Unit tests for business logic
- UI tests for critical user flows
- Separate test targets for different testing types 