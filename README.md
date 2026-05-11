# Smart Parking Web

This is a working browser-based Smart Parking demo built with HTML, CSS, and JavaScript. It runs immediately with a local `localStorage` data store so you can review the user and admin flows before wiring Firebase, Google Maps, or sensor endpoints.

## What is included

- User and admin sign-up / sign-in
- One parking-area-per-admin flow
- Parking-area registration
- Real map-based parking-area pin placement with drag-and-drop selection
- Automatic parking-area rectangle generation from center pin + length + width
- Nearby OpenStreetMap footprint snapping for more map-accurate parking-area shapes
- Manual boundary-point pinning with calculated enclosed area display
- Slot creation with row and column labels like `A1`, `B2`
- Real map-based slot-center pinning with slot rectangle sizing
- Automatic rectangular slot-grid generation from parking-area dimensions
- Automatic driving aisle gap between slot rows for more realistic parking layout
- Search-based parking-area lookup while registering the parking area
- Map-style slot pinning board
- Nearby parking-area discovery with browser geolocation or demo location
- Realtime-style slot updates through reactive local state
- Reservation with expiry cleanup
- Auto-allocation
- Embedded in-app navigation inside the web app using Leaflet, OpenStreetMap, and OSRM
- Entry and exit confirmation
- Parking history
- Admin logs
- Manual admin slot override
- Simulated sensor updates

## How to run

The site is static, so you can open it with a local web server.

### Option 1: VS Code Live Server

1. Open `M:\Manju\smart-parking-web` in VS Code.
2. Start Live Server on `index.html`.
3. Open the served URL in your browser.

### Option 2: Python HTTP server

From `M:\Manju\smart-parking-web` run:

```powershell
python -m http.server 8080
```

Then open:

`http://localhost:8080`

### Option 3: Included PowerShell server

From `M:\Manju\smart-parking-web` run:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-local-server.ps1
```

Then open:

`http://127.0.0.1:8090`

### Option 4: Secure Caddy server

From `M:\Manju\smart-parking-web` run:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-caddy-secure-server.ps1
```

Then open:

`https://localhost:8447`

## Demo credentials

After clicking `Load Demo Data`:

- Admin: `admin@smartparking.demo / Admin123`
- User: `user@smartparking.demo / User1234`

## Important notes

- Browser geolocation works best over `http://localhost` or HTTPS.
- The current app uses `localStorage` as the source of truth.
- The parking-area and slot pickers use `Leaflet` with `OpenStreetMap` tiles for the admin map experience.
- User navigation now stays inside the web app using Leaflet with OpenStreetMap tiles and OSRM route guidance.
- Parking boundaries are now generated automatically from the center pin and entered dimensions.
- The data and business logic are isolated in `js/modules/store.js`, which is the file to replace first when integrating Firebase.

## Suggested next integration steps

1. Replace `store.js` with Firebase Auth and Firestore data access.
2. Replace the map-style board with your preferred production map provider if needed.
3. Add a secure sensor ingestion endpoint using Firebase Functions or a backend API.
4. Move reservation expiry cleanup to backend jobs or server-side triggers.
5. Add role-based Firestore security rules and App Check.
