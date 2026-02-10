#!/bin/bash
# ==========================================================
# CyberKhana Workshop — Challenge File Generator
# Re-run this script anytime to rebuild all demo files
# Each challenge gets its own folder
# ==========================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
DEMOS="$SCRIPT_DIR"

echo "[*] CyberKhana Challenge Builder"
echo "================================"

# ----------------------------------------------------------
# Source images (must exist in demos/)
# ----------------------------------------------------------
BABY_PATRICK="$DEMOS/baby_patrick.JPG"
HACKER_PENGUIN="$DEMOS/IMG_6770.JPG"
MCAFEE="$BASE_DIR/JohnMacafee.jpg"
PILOT="$DEMOS/IMG_6769.JPG"
FOLLOW_DREAM="$DEMOS/IMG_6765.JPG"
MASKED_CAT="$DEMOS/masked_cat.JPG"
LINUX_DESKTOP="$DEMOS/IMG_6766.JPG"

# Verify source images exist
for img in "$BABY_PATRICK" "$HACKER_PENGUIN" "$MCAFEE" "$PILOT" "$FOLLOW_DREAM" "$MASKED_CAT" "$LINUX_DESKTOP"; do
  if [ ! -f "$img" ]; then
    echo "[!] Missing source image: $img"
    exit 1
  fi
done

# Clean previous challenge builds
rm -rf "$DEMOS"/1_file "$DEMOS"/2_strings "$DEMOS"/3_exiftool "$DEMOS"/4_xxd "$DEMOS"/5_binwalk "$DEMOS"/6_zsteg

# ----------------------------------------------------------
# CHALLENGE 1: file tool — Wrong extension
# ----------------------------------------------------------
echo ""
echo "[+] Challenge 1: 1_file/baby_patrick.txt"

mkdir -p "$DEMOS/1_file"
cp "$BABY_PATRICK" "$DEMOS/1_file/baby_patrick_tmp.jpg"
exiftool -overwrite_original -Comment="Khana{dont_trust_extensions}" "$DEMOS/1_file/baby_patrick_tmp.jpg" > /dev/null 2>&1
mv "$DEMOS/1_file/baby_patrick_tmp.jpg" "$DEMOS/1_file/baby_patrick.txt"

echo "    Solve: file baby_patrick.txt"
echo "    Then:  cp baby_patrick.txt baby_patrick.jpg"
echo "    Flag:  Khana{dont_trust_extensions}"

# ----------------------------------------------------------
# CHALLENGE 2: strings tool — Hidden text in image
# ----------------------------------------------------------
echo ""
echo "[+] Challenge 2: 2_strings/hacker_penguin.jpg"

mkdir -p "$DEMOS/2_strings"
cp "$HACKER_PENGUIN" "$DEMOS/2_strings/hacker_penguin.jpg"
printf '\n--- HIDDEN DATA ---\nKhana{strings_see_everything}\n--- END ---\n' >> "$DEMOS/2_strings/hacker_penguin.jpg"

echo "    Solve: strings hacker_penguin.jpg | grep Khana"
echo "    Flag:  Khana{strings_see_everything}"

# ----------------------------------------------------------
# CHALLENGE 3: exiftool — Metadata with GPS (McAfee story)
# ----------------------------------------------------------
echo ""
echo "[+] Challenge 3: 3_exiftool/mcafee_photo.jpg"

mkdir -p "$DEMOS/3_exiftool"
cp "$MCAFEE" "$DEMOS/3_exiftool/mcafee_photo.jpg"
exiftool -overwrite_original \
  -Comment="Khana{metadata_reveals_location}" \
  -Author="Vice News" \
  -Description="Interview with subject — location undisclosed" \
  -GPSLatitude="14.6349" \
  -GPSLatitudeRef="N" \
  -GPSLongitude="90.5069" \
  -GPSLongitudeRef="W" \
  -DateTimeOriginal="2012:12:03 14:22:00" \
  -Make="iPhone" \
  -Model="iPhone 4S" \
  "$DEMOS/3_exiftool/mcafee_photo.jpg" > /dev/null 2>&1

echo "    Solve: exiftool mcafee_photo.jpg"
echo "    Look:  GPS Position, Comment, Author, Date"
echo "    Flag:  Khana{metadata_reveals_location}"

# ----------------------------------------------------------
# CHALLENGE 4: xxd tool — Flag hidden in hex dump
# ----------------------------------------------------------
echo ""
echo "[+] Challenge 4: 4_xxd/pilot.jpg"

mkdir -p "$DEMOS/4_xxd"
cp "$PILOT" "$DEMOS/4_xxd/pilot.jpg"
printf 'Khana{hex_dump_detective}' >> "$DEMOS/4_xxd/pilot.jpg"

echo "    Solve: xxd pilot.jpg | tail -20"
echo "    Flag:  Khana{hex_dump_detective}"

# ----------------------------------------------------------
# CHALLENGE 5: binwalk — Hidden ZIP inside image
# ----------------------------------------------------------
echo ""
echo "[+] Challenge 5: 5_binwalk/follow_dream.jpg"

mkdir -p "$DEMOS/5_binwalk"
echo "Khana{binwalk_carved_the_secret}" > "$DEMOS/5_binwalk/flag.txt"
cd "$DEMOS/5_binwalk"
cp "$MASKED_CAT" masked_cat.JPG
zip -q hidden_flag.zip flag.txt masked_cat.JPG
cat "$FOLLOW_DREAM" hidden_flag.zip > follow_dream.jpg
rm -f flag.txt hidden_flag.zip masked_cat.JPG
cd "$BASE_DIR"

echo "    Solve: binwalk follow_dream.jpg"
echo "    Then:  binwalk -e follow_dream.jpg"
echo "    Flag:  Khana{binwalk_carved_the_secret}"

# ----------------------------------------------------------
# CHALLENGE 6: zsteg — LSB-encoded message in PNG
# ----------------------------------------------------------
echo ""
echo "[+] Challenge 6: 6_zsteg/linux_desktop.png"

mkdir -p "$DEMOS/6_zsteg"
sips -s format png "$LINUX_DESKTOP" --out "$DEMOS/6_zsteg/linux_desktop.png" > /dev/null 2>&1

python3 - "$DEMOS/6_zsteg/linux_desktop.png" << 'PYEOF'
import sys
from PIL import Image

img_path = sys.argv[1]
message = "Khana{lsb_master_detected}"
msg_bits = ''.join(format(ord(c), '08b') for c in message) + '00000000'

img = Image.open(img_path).convert('RGB')
pixels = list(img.getdata())
new_pixels = []
bit_idx = 0

for r, g, b in pixels:
    if bit_idx < len(msg_bits):
        r = (r & 0xFE) | int(msg_bits[bit_idx])
        bit_idx += 1
    if bit_idx < len(msg_bits):
        g = (g & 0xFE) | int(msg_bits[bit_idx])
        bit_idx += 1
    if bit_idx < len(msg_bits):
        b = (b & 0xFE) | int(msg_bits[bit_idx])
        bit_idx += 1
    new_pixels.append((r, g, b))

img_out = Image.new('RGB', img.size)
img_out.putdata(new_pixels)
img_out.save(img_path)
print(f"    Encoded {len(message)} chars in LSB of {img.size[0]}x{img.size[1]} PNG")
PYEOF

echo "    Solve: zsteg linux_desktop.png"
echo "    Flag:  Khana{lsb_master_detected}"

# ----------------------------------------------------------
echo ""
echo "================================"
echo "[*] All 6 challenges created:"
echo ""
echo "  1_file/baby_patrick.txt"
echo "  2_strings/hacker_penguin.jpg"
echo "  3_exiftool/mcafee_photo.jpg"
echo "  4_xxd/pilot.jpg"
echo "  5_binwalk/follow_dream.jpg"
echo "  6_zsteg/linux_desktop.png"
echo ""
echo "[*] Done."
