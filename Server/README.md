# HaxeStackStarter Server

This is the backend server for the HaxeStackStarter project, built with Haxe, Lime, and the SideWinder framework (based on CivetWeb).

## Prerequisites

- [Haxe 4.3+](https://haxe.org/download/)
- [VSCode](https://code.visualstudio.com/)
- [Haxe Extension for VSCode](https://marketplace.visualstudio.com/items?itemName=nadako.vshaxe)
- [Lime Extension for VSCode](https://marketplace.visualstudio.com/items?itemName=openfl.lime-vscode-extension)
- [HashLink Debugger Extension](https://marketplace.visualstudio.com/items?itemName=HaxeFoundation.haxe-hl) (required for HashLink debugging)
- [HMM (Haxe Module Manager)](https://github.com/andywhite37/hmm)

## Setup

1. **Install HMM** (if not already installed):
   Run the following commands in your terminal (command prompt):
   ```bash
   haxelib --global install hmm
   haxelib --global run hmm setup
   ```

2. **Install Project Dependencies**:
   Navigate to the `Server` directory and run:
   ```bash
   hmm install
   ```
   This will install all dependencies listed in `hmm.json` (SideWinder, lime, snake-server, etc.).

## Development Workflow

### VS Code Setup

1. Open the `Server` folder in VS Code.
2. Ensure you have the recommended extensions installed (Haxe, Lime, HashLink Debugger).
3. In the bottom left of the VS Code window, check the Lime extension settings.
4. **Change the target** from `HTML5` (or whatever is selected) to **`HashLink / Debug`**.

### Running and Debugging

1. Open `Source/Main.hx`.
2. You can add a breakpoint in the `new()` constructor or specifically where it calls `super()`.
3. Press **F5** to start debugging.

If you get an error about a missing configuration, click the Lime button in the bottom of the VS window and select Haxe completion provider to "Project using Lime/OpenFL command-line tools".

This will build the project for HashLink, copy necessary native libraries, and launch the server with the debugger attached.

### Running via Command Line

To build and run without the debugger:

1. Build for HashLink (HL):
   ```bash
   lime build hl
   ```
   This compiles the code and runs the post-build script (`copy-server-hdlls.bat`) to ensure `civetweb.hdll` and `sqlite.hdll` are in `Export/hl/bin`.

2. Run the server:
   ```bash
   run-server.bat
   ```
   The server will start at `http://127.0.0.1:8000`.

## Database Initialization and Default Content

The server uses SQLite. The database file is automatically created in the run directory if it doesn't exist.

### Auto-Seeding

On the first run, the `DatabaseSeeder` service checks if the database is empty. If so, it automatically seeds:
1.  **Default Admin User**
2.  **Default Home Page**

### Default Credentials

You can log in to the CMS/Admin panel using the following credentials:

-   **Email**: `admin@example.com`
-   **Username**: `admin`
-   **Password**: `SideWinder2024!`

## Project Structure

-   `Source/Main.hx`: Application entry point.
-   `Source/app/ServerApp.hx`: Main application configuration (DI, Middleware, Routes).
-   `Source/app/services/`: Business logic and services.
-   `Source/app/models/`: Data models and request/response structures.
-   `migrations/`: Database migration files.
-   `hmm.json`: Haxe dependencies manifest.
