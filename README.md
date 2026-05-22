# MindBender — Prompting Playground for Kids

A classroom playground where students prompt an LLM to write HTML/CSS and see
the result render live. The teacher shows a target screen (projector,
printout, slide — outside the app) and students compete to get their preview
as close to it as possible.

- **App**: Multiplatform SwiftUI (macOS, iPadOS, iOS). Two panes only — chat
  on the left, live `WKWebView` preview on the right.
- **Backend**: A small Vapor (Swift) proxy that holds the Groq API key and
  rate-limits per IP. Runs on the teacher's laptop.
- **LLM**: [Groq](https://console.groq.com) free tier, model
  `llama-3.3-70b-versatile`.

## Repo layout

```
Package.swift                Swift package: App, Shared, MindBenderProxy
Sources/
  Shared/                    DTOs, system prompt, HTML extractor
  App/                       SwiftUI views + view model
    Panes/                   Chat / Preview
    Platform/                WebView wrapper (only #if os splits live here)
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
`http://YOUR_LAN_IP:8080` via the Settings gear in the app.

Smoke test:

```sh
curl -X POST http://localhost:8080/chat \
  -H 'content-type: application/json' \
  -d '{"messages":[{"role":"user","content":"make a red button centered on the page"}]}'
```

Returns JSON with a `content` field containing a fenced HTML block.

Rate limit defaults: bucket of 10, refills 0.2 tokens/sec per IP (≈12 requests
per minute sustained, burst of 10). Eleventh rapid request returns `429` with
`Retry-After`.

## 2. Build the app (Xcode, on a Mac)

The Swift package builds the proxy. The iOS/iPadOS/macOS app needs an Xcode
project for signing and bundle resources. Create it once:

1. In Xcode: **File → New → Project → Multiplatform → App**.
2. Product name: `MindBenderApp`. Bundle ID: anything (e.g.
   `com.yourname.mindbender`). Save it into the existing
   `MindBenderApp/` folder, replacing the default Swift entry file with the
   provided `MindBenderApp/MindBenderApp/MindBenderApp.swift`.
3. **File → Add Package Dependencies → Add Local…** → pick the repo root
   (the folder containing `Package.swift`). Add the **App** library product to
   the target.
4. In **Target → Info**: point Info.plist at
   `MindBenderApp/MindBenderApp/Info.plist`.
5. In **Target → Signing & Capabilities** (Mac destination): enable
   **App Sandbox**, use the provided `MindBenderApp.entitlements`,
   and make sure **Outgoing Connections (Client)** is on.
6. Build and run on My Mac, iPad Simulator, iPhone Simulator.

First time an iPad on the LAN hits the laptop, iOS prompts "Allow MindBender
to find devices on your local network" — tap Allow.

## 3. Use it in class

1. Teacher shows the target screen on the projector / hands out a printout.
2. Each student opens the app and types a prompt:
   *"a blue header at the top that says Hello, with three red boxes in a row
   below it"*.
3. Live preview updates in 1–3 seconds.
4. Iterate: *"make the boxes rounded"*, *"center everything"*, …
5. Teacher walks around comparing each device's preview to the target and
   picks whoever got closest.
6. **New chat** (top-right) wipes the chat and preview to start a new round.

## Tests

```sh
swift test
```

Runs `HTMLExtractorTests` and `RateLimiterTests`.

## What's intentionally NOT in v1

- No target image in the app — teacher shows it separately.
- No streaming. Groq is fast enough that a 1–3s spinner is fine.
- No accounts, no persistence. Quit the app, lose history.
- No multiplayer / room concept. Each device is a single seat.
