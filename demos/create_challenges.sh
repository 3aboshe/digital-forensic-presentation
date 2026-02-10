#!/bin/bash
# ==========================================================
# CyberKhana Workshop — Challenge File Generator
# Re-run this script anytime to rebuild all demo files
# ==========================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
DEMOS="$SCRIPT_DIR"
SRC_IMG="$BASE_DIR/JohnMacafee.jpg"

echo "[*] CyberKhana Challenge Builder"
echo "================================"

if [ ! -f "$SRC_IMG" ]; then
  echo "[!] Source image not found: $SRC_IMG"
  echo "    Download a JPEG image and save it as steganography.jpg in the project root."
  exit 1
fi

# Clean previous builds
rm -f "$DEMOS"/challenge* "$DEMOS"/secret.txt "$DEMOS"/flag.txt "$DEMOS"/lsb_encode.py

# ----------------------------------------------------------
# CHALLENGE 1: Wrong extension + metadata + hidden strings
# Tools: file, strings, exiftool, xxd
# ----------------------------------------------------------
echo "[+] Building challenge1.txt (file / strings / exiftool / xxd demo)..."

# Write metadata while still a .jpg, then rename to .txt
cp "$SRC_IMG" "$DEMOS/challenge1.jpg"
exiftool -overwrite_original -Comment="Khana{metadata_is_never_safe}" "$DEMOS/challenge1.jpg" > /dev/null 2>&1
mv "$DEMOS/challenge1.jpg" "$DEMOS/challenge1.txt"
printf '\n\n--- HIDDEN DATA ---\nKhana{strings_will_find_me}\n--- END ---\n' >> "$DEMOS/challenge1.txt"

echo "    -> file challenge1.txt          (reveals JPEG)"
echo "    -> strings challenge1.txt       (finds Khana{strings_will_find_me})"
echo "    -> exiftool challenge1.txt      (Comment: Khana{metadata_is_never_safe})"
echo "    -> xxd challenge1.txt | head    (shows FF D8 FF header)"

# ----------------------------------------------------------
# CHALLENGE 2: Steghide-embedded secret
# Tools: steghide
# ----------------------------------------------------------
echo "[+] Building challenge2.jpg (steghide demo)..."

cp "$SRC_IMG" "$DEMOS/challenge2.jpg"
echo "Khana{steghide_password_cracked}" > "$DEMOS/secret.txt"

if command -v steghide &> /dev/null; then
  steghide embed -cf "$DEMOS/challenge2.jpg" -ef "$DEMOS/secret.txt" -p "workshop" -f > /dev/null 2>&1
  rm "$DEMOS/secret.txt"
  echo "    -> steghide extract -sf challenge2.jpg -p \"workshop\""
else
  echo "    [!] steghide not installed — embedding via raw append (demo-only)"
  printf '\xFF\xFE' >> "$DEMOS/challenge2.jpg"
  cat "$DEMOS/secret.txt" >> "$DEMOS/challenge2.jpg"
  rm "$DEMOS/secret.txt"
  echo "    -> steghide extract -sf challenge2.jpg -p \"workshop\""
  echo "    NOTE: Install steghide for proper LSB embedding. Current file uses appended data."
fi

# ----------------------------------------------------------
# CHALLENGE 3: Hidden ZIP inside JPEG
# Tools: binwalk
# ----------------------------------------------------------
echo "[+] Building challenge3.jpg (binwalk demo)..."

echo "Khana{binwalk_carved_the_secret}" > "$DEMOS/flag.txt"
cd "$DEMOS"
zip -q hidden_flag.zip flag.txt
cat "$SRC_IMG" hidden_flag.zip > challenge3.jpg
rm -f flag.txt hidden_flag.zip
cd "$BASE_DIR"

echo "    -> binwalk challenge3.jpg       (finds ZIP at offset)"
echo "    -> binwalk -e challenge3.jpg     (extracts hidden ZIP)"
echo "    -> cat _challenge3.jpg.extracted/flag.txt"

# ----------------------------------------------------------
# CHALLENGE 4: PNG with LSB-hidden message
# Tools: zsteg
# ----------------------------------------------------------
echo "[+] Building challenge4.png (zsteg / LSB demo)..."

# Convert JPEG to PNG first
sips -s format png "$SRC_IMG" --out "$DEMOS/challenge4.png" > /dev/null 2>&1

# Encode message in LSB using Python
python3 - "$DEMOS/challenge4.png" << 'PYEOF'
import sys
from PIL import Image

img_path = sys.argv[1]
message = "Khana{lsb_master_detected}"
# Add null terminator
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
print(f"    -> Encoded {len(message)} chars in LSB of {img.size[0]}x{img.size[1]} PNG")
PYEOF

echo "    -> zsteg challenge4.png         (finds Khana{lsb_master_detected})"

# ----------------------------------------------------------
echo ""
echo "================================"
echo "[*] All challenges created in: $DEMOS/"
echo ""
echo "Demo 1 commands (Basic Forensics):"
echo "  cd demos"
echo "  file challenge1.txt"
echo "  strings challenge1.txt | grep Khana"
echo "  exiftool challenge1.txt | grep -i comment"
echo "  xxd challenge1.txt | head"
echo ""
echo "Demo 2 commands (Advanced Stego):"
echo "  steghide extract -sf challenge2.jpg -p \"workshop\""
echo "  binwalk challenge3.jpg"
echo "  binwalk -e challenge3.jpg"
echo "  zsteg challenge4.png"
echo ""
echo "[*] Done."
