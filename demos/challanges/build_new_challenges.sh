#!/bin/bash
# ==========================================================
# CyberKhana CTF — New Challenge Builder
# Builds 5 challenges that don't overlap with existing ones
# ==========================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMG_DIR="$(dirname "$SCRIPT_DIR")/images"
OUT="$SCRIPT_DIR"

echo "[*] CyberKhana CTF — New Challenge Builder"
echo "============================================"

# Verify source images
for f in IMG_6771.JPG IMG_6773.JPG IMG_6774.JPG IMG_6776.JPG; do
  if [ ! -f "$IMG_DIR/$f" ]; then
    echo "[!] Missing: $IMG_DIR/$f"
    exit 1
  fi
done

# Verify suspicious.jpeg exists in images folder
if [ ! -f "$IMG_DIR/suspicious.jpeg" ]; then
  echo "[!] Missing: $IMG_DIR/suspicious.jpeg"
  exit 1
fi

# Clean previous builds of these specific challenges
rm -f "$OUT/suspicious.pdf" "$OUT/linus.jpg" "$OUT/creation.png" "$OUT/gamer_cat.jpg" "$OUT/deep_cave.jpg"
rm -rf "$OUT/_deep_cave_tmp"

# ----------------------------------------------------------
# CHALLENGE: "What Am I?" — Easy (50pts)
# Tool: file
# Technique: Wrong file extension (JPEG disguised as PDF)
# ----------------------------------------------------------
echo ""
echo "[+] What Am I? (Easy, 50pts)"

cp "$IMG_DIR/suspicious.jpeg" "$OUT/suspicious.pdf"

echo "    File: suspicious.pdf"
echo ""
echo "    CTF Description:"
echo "      We intercepted a document from a suspect's machine."
echo "      Our analyst says it's a PDF, but it won't open in any reader."
echo "      Something about this file isn't what it seems..."
echo "      Can you figure out what it really is and find the hidden flag?"
echo ""
echo "    Solve: file suspicious.pdf → reveals JPEG"
echo "    Then: exiftool suspicious.pdf | grep Comment"
echo "    Flag: khana{f1l3_typ3s_c4nt_h1d3}"

# ----------------------------------------------------------
# CHALLENGE: "Carved" — Easy (75pts)
# Tool: binwalk
# Technique: ZIP hidden inside JPEG
# ----------------------------------------------------------
echo ""
echo "[+] Carved (Easy, 75pts)"

echo "khana{b1nw4lk_c4rv3s_s3cr3ts}" > "$OUT/.flag_tmp.txt"
cd "$OUT"
zip -q _hidden_tmp.zip .flag_tmp.txt
cat "$IMG_DIR/IMG_6771.JPG" _hidden_tmp.zip > linus.jpg
rm -f .flag_tmp.txt _hidden_tmp.zip
cd - > /dev/null

echo "    File: linus.jpg"
echo ""
echo "    CTF Description:"
echo "      \"Talk is cheap. Show me the code.\" — Linus Torvalds"
echo "      Linus left us a message, but it's not in the pixels."
echo "      There's more to this image than meets the eye."
echo "      Look beyond what image viewers show you."
echo ""
echo "    Solve: binwalk linus.jpg → finds ZIP"
echo "    Then: binwalk -e linus.jpg → extracts hidden file"
echo "    Then: ls -la _linus.jpg.extracted/ → reveals .flag_tmp.txt"
echo "    Flag: khana{b1nw4lk_c4rv3s_s3cr3ts}"

# ----------------------------------------------------------
# CHALLENGE: "Pixel Secrets" — Easy (150pts)
# Tool: zsteg
# Technique: PNG LSB steganography
# ----------------------------------------------------------
echo ""
echo "[+] Pixel Secrets (Easy, 150pts)"

sips -s format png "$IMG_DIR/IMG_6776.JPG" --out "$OUT/creation.png" > /dev/null 2>&1

python3 - "$OUT/creation.png" << 'PYEOF'
import sys
from PIL import Image

img_path = sys.argv[1]
message = "khana{z5t3g_p1x3l_m4st3r}"
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

echo "    File: creation.png"
echo ""
echo "    CTF Description:"
echo "      Every pixel tells a story. Some tell secrets."
echo "      This image looks completely normal — no weird extensions,"
echo "      no extra files hiding inside. But the secret is woven"
echo "      into the very fabric of the image itself."
echo "      You'll need a tool that can see what the human eye can't."
echo ""
echo "    Solve: zsteg creation.png → finds flag in b1,rgb,lsb,xy"
echo "    Flag: khana{z5t3g_p1x3l_m4st3r}"

# ----------------------------------------------------------
# CHALLENGE: "Layers" — Medium (300pts)
# Tools: exiftool + binwalk + ROT13 + unzip
# Technique: Multi-step chain
# ----------------------------------------------------------
echo ""
echo "[+] Layers (Medium, 300pts)"

# ROT13 of "f0r3ns1c5_r0ck" is "s0e3af1p5_e0px"
# We store the ROT13 version in EXIF, player must decode
PASSWORD="f0r3ns1c5_r0ck"
ROT13_PW=$(echo "$PASSWORD" | tr 'a-zA-Z' 'n-za-mN-ZA-M')

cp "$IMG_DIR/IMG_6774.JPG" "$OUT/gamer_cat.jpg"
exiftool -overwrite_original \
  -Author="Look deeper..." \
  -Description="password: $ROT13_PW" \
  "$OUT/gamer_cat.jpg" > /dev/null 2>&1

# Create password-protected ZIP with flag
echo "khana{l4y3r3d_f0r3ns1cs_pr0}" > "$OUT/_flag_layers.txt"
cd "$OUT"
zip -q -P "$PASSWORD" _layers_hidden.zip _flag_layers.txt
cat gamer_cat.jpg _layers_hidden.zip > gamer_cat_final.jpg
mv gamer_cat_final.jpg gamer_cat.jpg
rm -f _flag_layers.txt _layers_hidden.zip
cd - > /dev/null

echo "    File: gamer_cat.jpg"
echo ""
echo "    CTF Description:"
echo "      This cat is hiding something. Actually, multiple somethings."
echo "      Like an onion (or an ogre), this file has layers."
echo "      Each layer you peel back reveals a clue for the next."
echo "      Hint: Sometimes things are rotated."
echo ""
echo "    Solve chain:"
echo "      1. exiftool gamer_cat.jpg → Description: 'password: $ROT13_PW'"
echo "      2. ROT13 decode '$ROT13_PW' → '$PASSWORD'"
echo "      3. binwalk gamer_cat.jpg → finds ZIP at offset"
echo "      4. binwalk -e gamer_cat.jpg"
echo "      5. cd _gamer_cat.jpg.extracted"
echo "      6. unzip -P '$PASSWORD' *.zip"
echo "      7. cat _flag_layers.txt"
echo "    Flag: khana{l4y3r3d_f0r3ns1cs_pr0}"

# ----------------------------------------------------------
# CHALLENGE: "Deep Cave" — Hard (500pts)
# Tools: exiftool + strings + hex decode + steghide + git
# Technique: Multi-tool chain ending in git forensics
# Requires: steghide (macOS: sudo port install steghide)
# Requires: https://github.com/3aboshe/deep-cave repo set up
# ----------------------------------------------------------
echo ""
echo "[+] Deep Cave (Hard, 500pts)"

DC_PASSPHRASE="c4v3_k3y"
HEX_HINT=$(echo -n "The passphrase is $DC_PASSPHRASE" | xxd -p | tr -d '\n')
REPO_URL="https://github.com/3aboshe/deep-cave"

# Step A: Create the classified file with story + repo URL
# NOTE: steghide crashes with long paths, so we build in /tmp
TMPBUILD="/tmp/_dc_build_$$"
mkdir -p "$TMPBUILD"
cat > "$TMPBUILD/classified.txt" << 'CLEOF'
Someone stored the flag in a git repo,
then deleted everything and pushed again.
They thought it was gone for good.

  git clone https://github.com/3aboshe/deep-cave

Check what was there before they deleted it.
CLEOF

# Step B: Copy clean image and embed with steghide FIRST (needs valid JPEG)
cp "$IMG_DIR/IMG_6773.JPG" "$TMPBUILD/deep_cave.jpg"
steghide embed \
  -cf "$TMPBUILD/deep_cave.jpg" \
  -ef "$TMPBUILD/classified.txt" \
  -p "$DC_PASSPHRASE" \
  -f 2>/dev/null

# Step C: Add EXIF hints (safe — only modifies metadata segments)
exiftool -overwrite_original \
  -Comment="Not everything is on the surface. Dig deeper." \
  -Author="Follow the HINT markers" \
  "$TMPBUILD/deep_cave.jpg" > /dev/null 2>&1

# Step D: Append hex-encoded hint after JPEG data (found via strings)
printf '\n--- HINT ---\n%s\n--- END ---\n' "$HEX_HINT" >> "$TMPBUILD/deep_cave.jpg"

mv "$TMPBUILD/deep_cave.jpg" "$OUT/deep_cave.jpg"
rm -rf "$TMPBUILD"

# Cleanup temp
rm -rf "$OUT/_deep_cave_tmp"

echo "    File: deep_cave.jpg"
echo ""
echo "    CTF Description:"
echo "      You've entered the cave. The flag is buried deep underground."
echo "      An agent hid classified intel somewhere in this image, but before"
echo "      they could brief the team, they went dark. All we know is they"
echo "      said: \"You'll need every tool in your arsenal.\""
echo "      The flag won't come easy. Dig. Decode. Extract. And when you"
echo "      think you've reached the end... look at the history."
echo ""
echo "    Solve chain:"
echo "      1. exiftool deep_cave.jpg → Comment hints to dig deeper, Author says follow HINT markers"
echo "      2. strings deep_cave.jpg | grep HINT → finds hex string between HINT markers"
echo "      3. echo '$HEX_HINT' | xxd -r -p → 'The passphrase is $DC_PASSPHRASE'"
echo "      4. steghide extract -sf deep_cave.jpg -p '$DC_PASSPHRASE' → extracts classified.txt"
echo "      5. cat classified.txt → $REPO_URL"
echo "      6. git clone $REPO_URL && cd deep-cave"
echo "      7. cat secret.txt → file is EMPTY"
echo "      8. git log → sees 'scrubbed sensitive data' commit"
echo "      9. git show HEAD~1:secret.txt → khana{d33p_c4v3_expl0r3r}"
echo "    Flag: khana{d33p_c4v3_expl0r3r}"

# ----------------------------------------------------------
echo ""
echo "============================================"
echo "[*] 5 challenges built:"
echo ""
echo "  EASY:"
echo "    suspicious.pdf  (50pts)  — Wrong extension + file command"
echo "    linus.jpg       (75pts)  — binwalk file carving"
echo "    creation.png    (150pts) — PNG LSB / zsteg"
echo ""
echo "  MEDIUM:"
echo "    gamer_cat.jpg   (300pts) — exiftool → ROT13 → binwalk → unzip"
echo ""
echo "  HARD:"
echo "    deep_cave.jpg   (500pts) — exiftool → strings → hex → steghide → git forensics"
echo ""
echo "[*] Done."
