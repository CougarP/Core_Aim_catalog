# Core_Aim Phantom — Community Catalog

Public catalog of AI models (`.onnx`) and config files (`.json`) for **Core_Aim Phantom**.
The app reads `manifest.json` from this repo and lets users browse / download with one click.

---

## How it works

1. App calls `https://raw.githubusercontent.com/CougarP/Core_Aim_catalog/main/manifest.json`
2. UI lists models + configs in the **Marketplace** tab
3. User clicks **DOWNLOAD** → app fetches from `models/<file>` or `configs/<file>` in this repo
4. SHA256 is verified before saving locally

---

## Contributing

Anyone can submit models/configs. Approval is **manual** by the maintainer.

### 1. Add your file
- Models go in `models/`
- Configs go in `configs/`
- Filenames must be unique. Max size: 50 MB

### 2. Generate a manifest entry
Run the helper script (PowerShell):

```powershell
pwsh ./gen_manifest_entry.ps1 -Path models/my_model.onnx -Author "@yourname" -Game "Valorant" -Description "Tuned for VLR low-recoil targets"
```

It prints a JSON block. Copy it into `manifest.json` under `models` or `configs`.

### 3. Open a Pull Request
- Title: `add: <category>/<filename>`
- Body: describe the model (input size, classes, training notes), or the config (settings preset)
- Wait for maintainer approval

---

## Manifest schema

```json
{
  "schemaVersion": 1,
  "updated": "YYYY-MM-DD",
  "models": [
    {
      "name": "yolov8n_phantom.onnx",
      "size": 12500000,
      "sha256": "abcdef...",
      "author": "@CougarP",
      "game": "Valorant",
      "description": "Phantom-tuned YOLOv8n for VLR",
      "uploaded": "2026-04-22"
    }
  ],
  "configs": [
    {
      "name": "valorant_default.json",
      "size": 2048,
      "sha256": "abcdef...",
      "author": "@CougarP",
      "game": "Valorant",
      "description": "Balanced default for Valorant",
      "uploaded": "2026-04-22"
    }
  ]
}
```

---

## Rules

- No malware, no obfuscated payloads
- ONNX models only (no other binary formats)
- Configs must be valid JSON
- Maintainer reserves the right to reject any submission for any reason

---

## License

Each contributor retains rights to their submission. By opening a PR you agree the file may be redistributed via this repo and the Core_Aim Phantom app.
