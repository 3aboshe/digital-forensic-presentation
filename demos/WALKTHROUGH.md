# CyberKhana Steganography Workshop — Challenge Walkthrough

## Prerequisites

Install these tools before running the challenges:

```bash
brew install exiftool binwalk
gem install --user-install zsteg
pip3 install Pillow
```

Make sure `~/.gem/ruby/2.6.0/bin` is in your PATH for `zsteg`.

## Building the Challenges

Run the build script from the project root:

```bash
cd demos
chmod +x create_challenges.sh
./create_challenges.sh
```

This generates 6 challenge files from the source images.

---

## Demo 1 — Basic Forensics

### Challenge 1: `baby_patrick.txt` — file tool

**Scenario:** You found a suspicious `.txt` file. But is it really a text file?

**Steps:**
```bash
$ file baby_patrick.txt
baby_patrick.txt: JPEG image data, JFIF standard 1.01 ...
```

The `file` command reads the magic bytes and reveals it is actually a **JPEG image**, not a text file. The extension was lying.

```bash
$ cp baby_patrick.txt baby_patrick_solved.jpg
$ open baby_patrick_solved.jpg    # macOS
```

You now see Baby Patrick. The flag is also hidden in the EXIF comment:

```bash
$ exiftool baby_patrick.txt | grep Comment
Comment                         : Khana{dont_trust_extensions}
```

**Flag:** `Khana{dont_trust_extensions}`

---

### Challenge 2: `hacker_penguin.jpg` — strings tool

**Scenario:** This image looks normal, but there is readable text hidden inside the binary data.

**Steps:**
```bash
$ strings hacker_penguin.jpg | grep Khana
Khana{strings_see_everything}
```

The `strings` command scans the binary file and extracts all sequences of printable ASCII characters. The flag was appended after the JPEG image data.

You can also see it without grep:
```bash
$ strings hacker_penguin.jpg | tail -5
--- HIDDEN DATA ---
Khana{strings_see_everything}
--- END ---
```

**Flag:** `Khana{strings_see_everything}`

---

### Challenge 3: `mcafee_photo.jpg` — exiftool

**Scenario:** In 2012, antivirus pioneer John McAfee was on the run from authorities in Belize. He met with Vice News journalists who took a photo with him and posted it online. The problem? The photo contained EXIF GPS metadata that revealed his exact location in Guatemala, leading to his arrest.

This challenge recreates that scenario.

**Steps:**
```bash
$ exiftool mcafee_photo.jpg
```

Key fields to look at:
```
Author                          : Vice News
Description                     : Interview with subject — location undisclosed
Date/Time Original              : 2012:12:03 14:22:00
Camera Model Name               : iPhone 4S
Comment                         : Khana{metadata_reveals_location}
GPS Latitude                    : 14 deg 38' 5.64" N
GPS Longitude                   : 90 deg 30' 24.84" W
GPS Position                    : 14 deg 38' 5.64" N, 90 deg 30' 24.84" W
```

The GPS coordinates (14.63° N, 90.51° W) point to **Guatemala City, Guatemala** — exactly where McAfee was hiding.

**Lesson:** Always strip EXIF data before sharing sensitive photos. Use `exiftool -all= photo.jpg` to remove all metadata.

**Flag:** `Khana{metadata_reveals_location}`

---

### Challenge 4: `pilot.jpg` — xxd tool

**Scenario:** Someone appended secret data after the end of a JPEG file. A JPEG viewer will display the image normally, but the hidden data is visible in a hex dump.

**Steps:**
```bash
$ xxd pilot.jpg | tail -10
```

You will see the normal JPEG data ending with `ffd9` (JPEG end-of-image marker), followed by readable ASCII:

```
00041b00: ... ffd9 4b68  (...(.....Kh
00041b10: 616e 617b 6865 785f 6475 6d70 5f64 6574  ana{hex_dump_det
00041b20: 6563 7469 7665 7d                        ective}
```

The right column of the hex dump shows the ASCII representation where you can read the flag.

You can also find it with strings:
```bash
$ strings pilot.jpg | tail -3
Khana{hex_dump_detective}
```

**Flag:** `Khana{hex_dump_detective}`

---

## Demo 2 — Advanced Steganography

### Challenge 5: `follow_dream.jpg` — binwalk

**Scenario:** This "Follow That Dream" photo looks normal, but it has an entire ZIP archive hidden inside it. The ZIP contains a secret image (masked_cat.JPG) and a flag file.

**Steps:**
```bash
$ binwalk follow_dream.jpg

DECIMAL       HEXADECIMAL     DESCRIPTION
-------       -----------     -----------
0             0x0             JPEG image, total size: ...
181641        0x2C589         ZIP archive, file count: 2, total size: ...
```

binwalk detects both the JPEG and a ZIP archive at offset 181641. Extract it:

```bash
$ binwalk -e follow_dream.jpg
$ ls _follow_dream.jpg.extracted/
flag.txt    masked_cat.JPG

$ cat _follow_dream.jpg.extracted/flag.txt
Khana{binwalk_carved_the_secret}
```

The masked cat image was hidden inside the "Follow That Dream" photo all along.

**How it works:** A JPEG viewer only reads up to the JPEG end marker. Anything appended after that is invisible to image viewers but detectable by binwalk.

**Flag:** `Khana{binwalk_carved_the_secret}`

---

### Challenge 6: `linux_desktop.png` — zsteg

**Scenario:** This PNG image has a message hidden in the Least Significant Bits (LSB) of its pixel color values. The image looks completely normal to the human eye.

**Steps:**
```bash
$ zsteg linux_desktop.png
```

In the output, look for the `b1,rgb,lsb,xy` channel:
```
b1,rgb,lsb,xy       .. text: "Khana{lsb_master_detected}"
```

**How LSB works:** Each pixel has Red, Green, and Blue values (0-255). Changing the last bit of each value (e.g., 210 → 211) is imperceptible to the human eye but can encode binary data. `zsteg` reads these last bits and reconstructs the hidden message.

**Flag:** `Khana{lsb_master_detected}`

---

## All Flags Summary

| # | Challenge | Tool | Flag |
|---|-----------|------|------|
| 1 | baby_patrick.txt | `file` | `Khana{dont_trust_extensions}` |
| 2 | hacker_penguin.jpg | `strings` | `Khana{strings_see_everything}` |
| 3 | mcafee_photo.jpg | `exiftool` | `Khana{metadata_reveals_location}` |
| 4 | pilot.jpg | `xxd` | `Khana{hex_dump_detective}` |
| 5 | follow_dream.jpg | `binwalk` | `Khana{binwalk_carved_the_secret}` |
| 6 | linux_desktop.png | `zsteg` | `Khana{lsb_master_detected}` |

## Tips for Participants

- Always start with `file` to check the real file type
- Use `strings | grep` to search for readable text in any binary
- Check `exiftool` output for GPS, comments, and camera info
- Use `xxd | tail` to inspect data appended after end-of-file markers
- `binwalk` can find files hidden inside other files
- `zsteg` is specifically for PNG LSB steganography
