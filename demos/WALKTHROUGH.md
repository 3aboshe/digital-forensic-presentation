# CyberKhana Steganography Workshop — Challenge Walkthrough

## Prerequisites

```bash
brew install exiftool binwalk
gem install --user-install zsteg
pip3 install Pillow
```

Make sure `~/.gem/ruby/2.6.0/bin` is in your PATH for `zsteg`.

## Building the Challenges

```bash
cd demos
./create_challenges.sh
```

This generates 6 challenge folders from the source images.

---

## Challenge 1: `1_file/baby_patrick.txt`
**Tool:** `file`

**Scenario:** You found a suspicious `.txt` file. But is it really text?

```bash
$ cd 1_file
$ file baby_patrick.txt
baby_patrick.txt: JPEG image data, JFIF standard 1.01 ...
```

It is a JPEG, not a text file. Rename it to view:

```bash
$ cp baby_patrick.txt baby_patrick.jpg
$ open baby_patrick.jpg
```

The flag is also in the EXIF comment:

```bash
$ exiftool baby_patrick.txt | grep Comment
Comment                         : Khana{dont_trust_extensions}
```

**Flag:** `Khana{dont_trust_extensions}`

---

## Challenge 2: `2_strings/hacker_penguin.jpg`
**Tool:** `strings`

**Scenario:** This image looks normal, but readable text is hidden in the binary data.

```bash
$ cd 2_strings
$ strings hacker_penguin.jpg | grep Khana
Khana{strings_see_everything}
```

Without grep:

```bash
$ strings hacker_penguin.jpg | tail -5
--- HIDDEN DATA ---
Khana{strings_see_everything}
--- END ---
```

**Flag:** `Khana{strings_see_everything}`

---

## Challenge 3: `3_exiftool/mcafee_photo.jpg`
**Tool:** `exiftool`

**Scenario:** In 2012, John McAfee was on the run. A Vice News journalist took a photo with him and posted it online. The EXIF GPS data revealed his exact location in Guatemala.

```bash
$ cd 3_exiftool
$ exiftool mcafee_photo.jpg
```

Key fields:
```
Author                          : Vice News
Date/Time Original              : 2012:12:03 14:22:00
Camera Model Name               : iPhone 4S
Comment                         : Khana{metadata_reveals_location}
GPS Latitude                    : 14 deg 38' 5.64" N
GPS Longitude                   : 90 deg 30' 24.84" W
```

The GPS coordinates point to **Guatemala City** — where McAfee was hiding.

**Lesson:** Always strip EXIF data before sharing sensitive photos: `exiftool -all= photo.jpg`

**Flag:** `Khana{metadata_reveals_location}`

---

## Challenge 4: `4_xxd/pilot.jpg`
**Tool:** `xxd`

**Scenario:** Secret data was appended after the JPEG end-of-image marker. Image viewers display the photo normally, but the hidden data is in the hex dump.

```bash
$ cd 4_xxd
$ xxd pilot.jpg | tail -10
```

Look for the ASCII column on the right:
```
00041b00: ... ffd9 4b68  (...(.....Kh
00041b10: 616e 617b 6865 785f 6475 6d70 5f64 6574  ana{hex_dump_det
00041b20: 6563 7469 7665 7d                        ective}
```

**Flag:** `Khana{hex_dump_detective}`

---

## Challenge 5: `5_binwalk/follow_dream.jpg`
**Tool:** `binwalk`

**Scenario:** This photo has a ZIP archive hidden inside. The ZIP contains a secret image and a flag file.

```bash
$ cd 5_binwalk
$ binwalk follow_dream.jpg

DECIMAL       HEXADECIMAL     DESCRIPTION
0             0x0             JPEG image ...
181641        0x2C589         ZIP archive, file count: 2 ...
```

Extract:

```bash
$ binwalk -e follow_dream.jpg
$ ls _follow_dream.jpg.extracted/
flag.txt    masked_cat.JPG

$ cat _follow_dream.jpg.extracted/flag.txt
Khana{binwalk_carved_the_secret}
```

The masked cat image was hidden inside the "Follow That Dream" photo.

**Flag:** `Khana{binwalk_carved_the_secret}`

---

## Challenge 6: `6_zsteg/linux_desktop.png`
**Tool:** `zsteg`

**Scenario:** A message is hidden in the Least Significant Bits of pixel color values. The image looks normal.

```bash
$ cd 6_zsteg
$ zsteg linux_desktop.png
```

Look for `b1,rgb,lsb,xy`:
```
b1,rgb,lsb,xy       .. text: "Khana{lsb_master_detected}"
```

**How LSB works:** Changing the last bit of each RGB value (e.g., 210 → 211) is invisible to the human eye but encodes data.

**Flag:** `Khana{lsb_master_detected}`

---

## All Flags

| # | Folder | Tool | Flag |
|---|--------|------|------|
| 1 | `1_file/` | `file` | `Khana{dont_trust_extensions}` |
| 2 | `2_strings/` | `strings` | `Khana{strings_see_everything}` |
| 3 | `3_exiftool/` | `exiftool` | `Khana{metadata_reveals_location}` |
| 4 | `4_xxd/` | `xxd` | `Khana{hex_dump_detective}` |
| 5 | `5_binwalk/` | `binwalk` | `Khana{binwalk_carved_the_secret}` |
| 6 | `6_zsteg/` | `zsteg` | `Khana{lsb_master_detected}` |
