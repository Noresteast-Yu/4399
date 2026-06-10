# Local object storage

The station photos are runtime objects served by MinIO. They are not bundled
into the Flutter APK.

## Start and seed

```powershell
cd C:\Users\24778\Documents\GitHub\4399
powershell -ExecutionPolicy Bypass -File .\tools\object-storage\start-minio.ps1
```

The script downloads the official Windows MinIO binaries into the current
user's local app-data directory, starts MinIO, creates the public
`station-media` bucket, and uploads the Tongji University seed photos.

- S3 endpoint: `http://127.0.0.1:9000`
- Admin console: `http://127.0.0.1:9001`
- Android emulator endpoint: `http://10.0.2.2:9000`
- Runtime data and credentials: `%LOCALAPPDATA%\SmartTravel\MinIO`

## Synchronize changed photos

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\object-storage\sync-station-photos.ps1
```

## Stop

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\object-storage\stop-minio.ps1
```

For a physical phone, set `OBJECT_STORAGE_PUBLIC_URL` in `backend/go/.env`
to the computer's LAN address, such as `http://192.168.1.20:9000`.
