

## 📘 Google Photos → PhotoPrism Import & Archiving Tool

This tool automates the full pipeline of processing Google Takeout photo exports and preparing them for long‑term storage and PhotoPrism ingestion. It handles extraction, HEIC conversion, organization, archiving, and cleanup with minimal user intervention.

---

## 🚀 What the tool does

### 1. **Extracts Google Takeout ZIP files**
All ZIP files in the configured source directory are unpacked.  
Nested ZIPs inside the export are also detected and extracted automatically.

### 2. **Stages HEIC files**
All `.HEIC` images are moved into a dedicated `_original_heic` folder.  
This ensures clean separation between originals and converted files.

### 3. **Converts HEIC → JPEG**
Uses ImageMagick to convert each HEIC file into a JPEG placed in the working directory.  
Existing JPEGs are skipped to avoid duplicate work.

### 4. **Syncs processed files into PhotoPrism**
All new media files are copied into the PhotoPrism `originals` directory.

### 5. **Creates yearly ZIP archives**
Each media file is assigned a year using:
- EXIF `DateTimeOriginal`  
- Google Takeout JSON metadata  
- File modification time (fallback)

Files are added to a `YYYY_Photos.zip` archive for long‑term storage.

### 6. **Mirrors archives to additional locations**
Two optional mirror directories can be used for redundancy.

### 7. **Cleans up temporary files**
After successful processing, the working directory and staging folder are cleared.

---

## ⚙️ Interactive setup (first run)

When the script is run for the first time, it launches a guided setup that asks the user to confirm or override the default directories:

- Location of Google Takeout ZIP files  
- Working directory for extraction and conversion  
- PhotoPrism originals directory  
- Yearly archive directory  
- Optional mirror directories  
- HEIC conversion log location  

Each prompt shows a default value. Pressing **Enter** accepts the default.

Example:

```
Path to ZIP files [/mnt/z/GooglePhotoExportZips]:
```

If the user presses Enter, the default is used.  
If they type a new path, that becomes the new setting.

### Configuration file

After setup, the script writes a config file:

```
~/.google_photos_pipeline.conf
```

This file stores all chosen paths and is automatically loaded on every future run.

### Changing settings later

To update paths, simply delete the config file:

```
rm ~/.google_photos_pipeline.conf
```

The script will run the interactive setup again on the next launch.

---

## ▶️ Running the tool

Once configured, running the script is as simple as:

```
./google_photos_pipeline.sh
```

The script will:

- Load your saved configuration  
- Process any new ZIP files  
- Convert HEICs  
- Update PhotoPrism  
- Update yearly archives  
- Mirror archives  
- Clean up  

No further interaction is required unless you want to change your settings.

