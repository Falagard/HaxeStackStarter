# HaxeStackStarter

A full-stack Haxe starter kit designed for scalable applications with a clear separation between framework ("Core") and application ("App") logic. This architecture allows you to use `HaxeStackStarter` as an upstream remote, pulling in framework updates while maintaining your own project-specific code.

## Key Features

*   **Full Stack Haxe**: Share models and logic between Client (HTML5/JS) and Server (HashLink/C++).
*   **Core/App Architecture**: Framework infrastructure is isolated in `core/` packages, while business logic lives in `app/`.
*   **HaxeUI**: Rich, cross-platform UI framework for the client.
*   **Upstream-Ready**: Designed to be cloned and updated via `git merge upstream/main`.

## Documentation

*   **[Architecture Guide](ARCHITECTURE.md)**: Detailed explanation of the directory structure, extension points, and the **Upstream Workflow** (how to set up your project and collaborate).
*   **[Implementation Plan](implementation_plan.md)**: History of the refactoring process.

## Quick Start

### Prerequisites
*   Haxe 4.3+
*   Lime / OpenFL
*   VS Code with Haxe extension

### Running the Server
The server runs on HashLink.

```bash
cd Server
lime build hl
./run-server.bat
```
*Server API will be available at http://127.0.0.1:8000*

### Running the Client
The client builds to HTML5.

```bash
cd Client
lime build html5
./run-client.bat
```
*Client will launch in your default browser.*

## Development Setup

The project is split into a **Client** and a **Server**, each with its own VS Code workspace file. To develop effectively:

1.  **Open Workspaces**: Open the `Server` directory in one VS Code instance and the `Client` directory in another.
2.  **Dependencies**:
    *   Open a terminal in the `Server` directory and run `hmm install`.
    *   Open a terminal in the `Client` directory and run `hmm install`.
    *   If a dependency changes, run `hmm reinstall`.

## Debugging

To debug the application:

1.  **Select Target**: Open the workspace you want to debug (`Client` or `Server`).
2.  **Lime Settings**: In the VS Code bottom bar, switch the output to **HashLink Debug** in the Lime settings.
3.  **Launch**: Run the HashLink debugger for the selected target.

> [!IMPORTANT]
> **Debugging Limitation**: You cannot debug both the Client and the Server simultaneously due to a limitation with HashLink debugging. You must choose one to debug at a time.

## Repository Structure

*   **/Server**: HashLink-based server application.
*   **/Client**: HTML5-based client application.
*   **/Shared**: Code shared between Client and Server (Models, Interfaces).

## License
[Add License Here]
