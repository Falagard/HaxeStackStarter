# SideWinder Client

This is the frontend client for the HaxeStackStarter project, built with [HaxeUI](http://haxeui.org/) and [OpenFL](https://www.openfl.org/).

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
   Navigate to the `Client` directory and run:
   ```bash
   hmm install
   ```
   This will install all dependencies listed in `hmm.json` (HaxeUI, OpenFL, Lime, etc.).

## Development Workflow

### VS Code Setup

1. Open the `Client` folder in VS Code.
2. Ensure you have the recommended extensions installed (Haxe, Lime, HashLink Debugger).
3. In the bottom left of the VS Code window, check the Lime extension settings.
4. **Change the target** from `HTML5` (or whatever is selected) to **`HashLink / Debug`** (recommended for development) or `HTML5 / Debug`.

### Running and Debugging

**Important: Start the Server**
Before running the client, you must start the backend server.
1. Open a new terminal in VS Code (`Terminal` -> `New Terminal`).
2. Navigate to the `Server` directory:
   ```bash
   cd ../Server
   ```
3. Run the server:
   ```bash
   run-server.bat
   ```

**Start the Client**
1. Open `Source/app/Main.hx`.
2. You can add a breakpoint in the `new()` constructor or specifically where it calls `super()`.
3. Press **F5** to start debugging.

This will build the project for the selected target (HashLink is faster for iteration) and launch the client with the debugger attached.

### Running via Command Line

You can also build and run using Lime commands:

**HashLink (Native Desktop)**:
```bash
lime test hl
```
Or build only:
```bash
lime build hl
```
And run using the helper script:
```bash
run-client.bat
```

**HTML5 (Web)**:
```bash
lime test html5
```

## Configuration

The API host is configured in `project.xml`:

```xml
<define name="api_host" value="http://127.0.0.1:8000" />
```

Ensure the server is running on this port before starting the client.
