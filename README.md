# Water Collection App

A Flutter application designed to help users schedule and manage water collection reminders. It ensures you never miss a collection time by checking your schedule and sending timely local notifications.

## Features

- **Schedule Management**: Create, view, and manage weekly water collection schedules.
- **Local Notifications**: Receive reliable reminders with sound and vibration at your scheduled times.
- **Recurring Alarms**: Supports weekly recurring schedules (e.g., every Monday and Wednesday at 9:00 AM).
- **Offline Capable**: Uses a local SQLite database to store your schedules and settings.
- **Dark Mode**: Supports both light and dark themes for better visibility.

## Installation Steps

1.  **Prerequisites**: Ensure you have [Flutter](https://docs.flutter.dev/get-started/install) installed and set up on your machine.
2.  **Clone the Repository**:
    ```bash
    git clone <repository-url>
    cd water_collection_app
    ```
3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

## How to Run the App

1.  **Connect a Device**: Connect an Android device via USB or start an Android Emulator.
2.  **Run the App**:
    ```bash
    flutter run
    ```
    *Note: For the best experience with notifications, run on a physical device.*

## Folder Structure Explanation

The project's source code is located in the `lib` folder and organized as follows:

- **`lib/main.dart`**: The entry point of the application. Initializes services and sets up the app theme and routes.
- **`lib/models/`**: Contains data models.
    - `schedule_model.dart`: Defines the structure of a schedule item.
- **`lib/screens/`**: Contains the application's UI screens.
    - `splash_screen.dart`: The initial screen shown on app launch.
    - `reminder_list.dart`: The home screen displaying the list of scheduled reminders.
    - `schedule_setup.dart`: The form screen for creating and editing schedules.
    - `settings_screen.dart`: The settings screen for app configuration.
- **`lib/services/`**: Contains business logic and external service integrations.
    - `database_service.dart`: Handles SQLite database operations for saving/loading schedules.
    - `notification_service.dart`: Manages local notifications, including permissions and scheduling logic.
- **`lib/widgets/`**: Contains reusable UI components used across different screens.

## Screenshots

> | ![Home Screen](screenshots/home_screen.png) | ![Schedule Setup](screenshots/setup_screen.png) | ![Settings](screenshots/settings_screen.png) |

## Permissions

This app requires the following permissions which are requested at runtime:
- **Notifications**: To post alerts.
- **Exact Alarms**: To schedule notifications at precise times.
- **Vibration**: To vibrate the device during an alarm.
