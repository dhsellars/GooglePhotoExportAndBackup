
---

## 🔧 What the tool does

### Extraction  
All ZIP files from Google Takeout are unpacked into a working directory. Nested ZIPs inside the export are also detected and extracted automatically.

### HEIC staging and conversion  
HEIC files are moved into a dedicated staging folder.  
Each HEIC is converted to JPEG using ImageMagick, and the JPEGs are placed back into the working directory.

### Import into PhotoPrism  
All processed files in the working directory are copied into your PhotoPrism `originals` directory using a verbose copy so you can see each file as it transfers.

### Yearly archives  
Each media file is assigned a year using:
- EXIF `DateTimeOriginal`
- Google Takeout JSON metadata
- File modification time (fallback)

Files are added to a `YYYY_Photos.zip` archive for long‑term storage.

### Mirroring  
Yearly archives are copied to two optional mirror locations for redundancy.

---

## ⚙️ Interactive setup

On the first run, the script asks you to confirm or override default paths:

- Google Takeout ZIP directory  
- Working directory  
- PhotoPrism originals directory  
- Yearly archive directory  
- Mirror directories  
- HEIC conversion log location  

Press **Enter** to accept any default.

Your choices are saved to:

```
~/.google_photos_pipeline.conf
```

Future runs load this automatically.

To reset the configuration:

```
rm ~/.google_photos_pipeline.conf
```

The script will prompt you again on the next run.

---

## ▶️ Running the tool

Run the script directly:

```
./google_photos_pipeline.sh
```

The script will:

- extract ZIPs  
- convert HEICs  
- copy files into PhotoPrism  
- build yearly archives  
- mirror archives  

No cleanup is performed, so you can inspect the working directory after each run.

---
