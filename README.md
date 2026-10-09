# BattleRecorder

A small [Venice Unleashed](https://veniceunleashed.net/) (Battlefield 3) mod that records a player's movement and aim input and plays it back through server-side bots. Recordings stack: each new recording is played back alongside the earlier ones while you record, so a single player can build up a scene with several "ghost" soldiers.

This is an early experiment (`mod.json` version `0`). See [Status and limitations](#status-and-limitations).

## How it works

- **Recording** - every post-frame server update, the server samples the recording player's `EntryInput`: all 64 input levels (`GetLevel(0..63)`) plus authoritative aiming pitch and yaw. The soldier's transform at the start of the recording is stored as the spawn point.
- **Playback** - for each stored recording the server spawns a bot (`Bot1`, `Bot2`, ...) at the recorded start transform with the default MP soldier blueprint and the US assault kit, then replays the recorded input levels and aim frame by frame.
- **Layering** - starting a new recording while earlier recordings exist automatically starts playback of those recordings, so you can act alongside them.
- Recordings are kept in server memory only; they are lost when the server or mod restarts.

## Requirements

- A Venice Unleashed server and client (the mod has client and server extension code; no WebUI).

## Installation

1. Copy (or clone) this repository into your server's `Admin/Mods/` directory as `BattleRecorder`.
2. Add `BattleRecorder` to `Admin/ModList.txt`.
3. Start or restart the server.

## Usage

The mod registers client console commands. Open the in-game console while spawned as a soldier:

| Command | What it does |
|---|---|
| `battlerecorder.record` | Start recording your soldier's input (requires you to be spawned). Also starts playback of any existing recordings. |
| `battlerecorder.stop` | Stop recording, save it to the list of recordings, stop playback and remove all bots. |
| `battlerecorder.play` | Spawn one bot per saved recording and play them back. |
| `battlerecorder.clear` | Delete all saved recordings. |

Commands are registered with `Console:Register('record' | 'stop' | 'play' | 'clear', ...)`; VU normally prefixes client console commands with the mod name as shown above.

Typical flow: `record` -> move around -> `stop` -> `record` again to act alongside the first take -> `stop` -> `play` to watch all takes.

## Project structure

```
mod.json                 Mod metadata
ext/Client/__init__.lua  Console commands; sends NetEvents to the server
ext/Server/__init__.lua  Recording, storage and playback logic
ext/Server/bots.lua      Bot helper: create/spawn/destroy bots, dispatches 'Bot:Update' each frame
ext/Shared/__init__.lua  Placeholder template (Partition:Loaded handler with example "SomeType"/"SomeGuid" code); not used by the recorder
```

## Status and limitations

Work in progress. Things to be aware of, based on the current code:

- Only movement/aim input is recorded and replayed; there is no saving to disk.
- Bots always spawn on team 1, squad 1 with a fixed soldier blueprint and kit.
- Playback looks recordings up by the bot's player id (`m_Recordings[bot.id]`), which assumes bot ids line up with recording indices. This may not hold on servers with other players.
- `ext/Shared/__init__.lua` is unmodified template code and references a placeholder `Guid("SomeGuid")`.
- `play` does not stop by itself when recordings end; use `stop` to remove the bots.
