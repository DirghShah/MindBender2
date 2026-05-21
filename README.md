# MindBender — Prompting Playground for Kids

A classroom playground where students prompt an LLM to write HTML/CSS that
recreates a target screen the teacher shows them. Live preview updates as they
chat. Teacher walks the room and picks whose page got closest.

- **App**: Multiplatform SwiftUI (macOS, iPadOS, iOS) with a chat panel, a target
  image panel, and a `WKWebView` live preview.
- **Backend**: A tiny Vapor (Swift) proxy that holds the Groq API key and
  rate-limits per IP. Runs on the teacher's laptop.
- **LLM**: [Groq](https://console.groq.com) free tier, model
  `llama-3.3-70b-versatile`.

## Repo layout

```
Package.swift                Swift package: App, Shared, MindBenderProxy
Sources/
  Shared/                    DTOs, system prompt, HTML extractor
  App/                       SwiftUI views + view model (imported by Xcode shim)
    Panes/                   Target / Chat / Preview / Compare
    Platform/                #if os splits live ONLY here
  MindBenderProxy/           Vapor server
Tests/
  SharedTests/               HTMLExtractor unit tests
  MindBenderProxyTests/      RateLimiter unit tests
MindBenderApp/               Xcode shim (you create the .xcodeproj)
```

## 1. Run the proxy (teacher's laptop)

```sh
cp .env.example .env
# Fill GROQ_API_KEY in .env from https://console.groq.com
swift run MindBenderProxy serve
```

By default it binds `0.0.0.0:8080`. Find your laptop's LAN IP (System
Settings → Network) — students will point their iPads at
`http://YOUR_LAN_IP:8080`.

Smoke test:

```sh
curl -X POST http://localhost:8080/chat \
  -H 'content-type: application/json' \
  -d '{"messages":[{"role":"user","content":"make a red button centered on the page"}]}'
```

You should get JSON back with a `content` field containing a fenced HTML block.

Rate limit defaults: bucket of 10, refills 0.2 tokens/sec per IP (≈12 requests
per minute sustained, burst of 10). Eleventh rapid request returns `429` with a
`Retry-After` header.

## 2. Build the app (Xcode, on a Mac)

The Swift package handles the proxy. The iOS/iPadOS/macOS app needs an Xcode
project for signing and bundle resources. The repo ships everything the project
needs except the `.xcodeproj` itself — create it once:

1. In Xcode: **File → New → Project → Multiplatform → App**.
2. Product name: `MindBenderApp`. Bundle ID: anything you like (e.g.
   `com.yourname.mindbender`). Save it into the existing
   `MindBenderApp/` folder, replacing the default Swift entry file with the
   provided `MindBenderApp/MindBenderApp/MindBenderApp.swift`.
3. **File → Add Package Dependencies → Add Local…** → pick the repo root
   (the folder containing `Package.swift`). Add the **App** library product to
   the target.
4. In **Target → Info**: set Info.plist source to
   `MindBenderApp/MindBenderApp/Info.plist`.
5. In **Target → Signing & Capabilities**:
   - Turn on **App Sandbox** for the macOS destination.
   - Use the provided `MindBenderApp.entitlements`.
   - Enable **Outgoing Connections (Client)** — already in the entitlements file.
6. Build and run on My Mac, iPad Simulator, iPhone Simulator.

The first time an iPad on the LAN hits the teacher's laptop, iOS will prompt
"Allow MindBender to find devices on your local network" — tap Allow.

## 3. Use it in class

1. Teacher loads a target image via the picker (or drags onto the Mac app).
2. Student types a prompt: *"a blue header at the top that says Hello, with
   three red boxes below in a row"*.
3. Live preview updates in 1–3 seconds.
4. Iterate: *"make the boxes have rounded corners"*, *"center everything"*.
5. Teacher taps **Compare** → full-screen split of target image vs preview, and
   walks the room.
6. **New Round** clears the chat. Either keep the same target or swap in a
   harder one.

## Tests

```sh
swift test
```

Runs `HTMLExtractorTests` and `RateLimiterTests` (the proxy boots via
`XCTVapor` so no live Groq call is made).

## Gotchas (worth knowing if something breaks)

- **`http://` URLs from device builds** need `NSAllowsLocalNetworking` in
  Info.plist — already set.
- **Local Network prompt on iOS 14+** requires `NSLocalNetworkUsageDescription`
  — already set. Without it, requests silently fail.
- **macOS sandbox** requires `com.apple.security.network.client` — already set.
- **`WKWebView` reloads on every state tick** unless we diff first — `WebView`
  already does that via its `Coordinator`.
- **Groq rate limits** surface as 429s with a friendly toast.

## What's intentionally NOT in v1

- No streaming (Groq is fast enough). `/chat/stream` is a future hook.
- No accounts, no persistence — quit the app, lose the history.
- No automatic image-vs-preview similarity score. Teacher eyeballs it.
- No multiplayer/room concept. Each device is a single seat.
