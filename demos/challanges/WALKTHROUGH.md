# CyberKhana CTF — Challenge Walkthrough

## Prerequisites

```bash
brew install exiftool binwalk
gem install --user-install zsteg
pip3 install Pillow
```

Make sure `~/.gem/ruby/*/bin` is in your PATH for `zsteg`.

## Building the Challenges

```bash
cd demos/challanges
./build_new_challenges.sh
```

This generates 5 challenge files from the source images in `demos/images/`.

---

## Challenge 1: `suspicious.pdf` — "What Am I?"
**Difficulty:** Easy | **Points:** 50
**Tool:** `file`, `exiftool`

> We intercepted a document from a suspect's machine.
> Our analyst says it's a PDF, but it won't open in any reader.
> Something about this file isn't what it seems...
> Can you figure out what it really is and find the hidden flag?

### Step 1: Check the real file type

```bash
$ file suspicious.pdf
suspicious.pdf: JPEG image data, JFIF standard 1.01 ...
```

It's not a PDF at all — it's a JPEG image with a `.pdf` extension.

### Step 2: Find the flag

```bash
$ exiftool suspicious.pdf | grep Comment
Comment                         : khana{f1l3_typ3s_c4nt_h1d3}
```

### Step 3 (bonus): View the image

```bash
$ cp suspicious.pdf suspicious.jpg
$ open suspicious.jpg
```

**Flag:** `khana{f1l3_typ3s_c4nt_h1d3}`

**Lesson:** File extensions are just labels — the `file` command reads the magic bytes to determine the true type.

---

## Challenge 2: `linus.jpg` — "Carved"
**Difficulty:** Easy | **Points:** 75
**Tool:** `binwalk`

> "Talk is cheap. Show me the code." — Linus Torvalds
> Linus left us a message, but it's not in the pixels.
> There's more to this image than meets the eye.
> Look beyond what image viewers show you.

### Step 1: Scan for embedded files

```bash
$ binwalk linus.jpg

DECIMAL       HEXADECIMAL     DESCRIPTION
0             0x0             JPEG image ...
142193        0x22B71         ZIP archive, file count: 1 ...
```

A ZIP archive is hiding after the JPEG data.

### Step 2: Extract the hidden files

```bash
$ binwalk -e linus.jpg
$ ls _linus.jpg.extracted/
```

Nothing visible? The extracted file is a **hidden file** (starts with a dot).

### Step 3: Reveal the hidden file

```bash
$ ls -la _linus.jpg.extracted/*/
.flag_tmp.txt
```

### Step 4: Read the flag

```bash
$ cat _linus.jpg.extracted/*/.flag_tmp.txt
khana{b1nw4lk_c4rv3s_s3cr3ts}
```

**Flag:** `khana{b1nw4lk_c4rv3s_s3cr3ts}`

**Lesson:** JPEG viewers stop reading at the end-of-image marker (`FF D9`), but extra data can be appended after it. `binwalk` scans the entire file for known signatures and carves them out. On top of that, the extracted file is a **dotfile** — hidden from normal `ls` output. Always use `ls -la` in forensics.

---

## Challenge 3: `creation.png` — "Pixel Secrets"
**Difficulty:** Easy | **Points:** 150
**Tool:** `zsteg`

> Every pixel tells a story. Some tell secrets.
> This image looks completely normal — no weird extensions,
> no extra files hiding inside. But the secret is woven
> into the very fabric of the image itself.
> You'll need a tool that can see what the human eye can't.

### Step 1: Run zsteg

```bash
$ zsteg creation.png
```

### Step 2: Look for the `b1,rgb,lsb,xy` channel

```
b1,rgb,lsb,xy       .. text: "khana{z5t3g_p1x3l_m4st3r}"
```

**Flag:** `khana{z5t3g_p1x3l_m4st3r}`

**How LSB steganography works:**
- Every pixel has RGB values (e.g., Red=142, Green=210, Blue=88)
- The least significant bit of each value (the last bit) can be flipped without visible change (142 vs 143 looks identical)
- By encoding message bits into these LSBs across thousands of pixels, you can hide text inside an image
- `zsteg` reads those LSBs back out and reconstructs the hidden message

---

## Challenge 4: `gamer_cat.jpg` — "Layers"
**Difficulty:** Medium | **Points:** 300
**Tools:** `exiftool`, ROT13 decoder, `binwalk`, `unzip`

> This cat is hiding something. Actually, multiple somethings.
> Like an onion (or an ogre), this file has layers.
> Each layer you peel back reveals a clue for the next.
> Hint: Sometimes things are rotated.

### Step 1: Check metadata

```bash
$ exiftool gamer_cat.jpg
```

Key fields:
```
Author                          : Look deeper...
Description                     : password: s0e3af1p5_e0px
```

The author says "look deeper" — there's more to this file. The description contains a password, but it looks scrambled.

### Step 2: Decode the password (ROT13)

The hint says "sometimes things are rotated." ROT13 rotates each letter 13 positions in the alphabet.

```bash
$ echo "s0e3af1p5_e0px" | tr 'a-zA-Z' 'n-za-mN-ZA-M'
f0r3ns1c5_r0ck
```

The real password is `f0r3ns1c5_r0ck`.

### Step 3: Scan for hidden files

```bash
$ binwalk gamer_cat.jpg

DECIMAL       HEXADECIMAL     DESCRIPTION
0             0x0             JPEG image ...
206445        0x3266D         ZIP archive, file count: 1 ...
```

There's a ZIP archive embedded after the image data.

### Step 4: Extract the hidden ZIP

```bash
$ binwalk -e gamer_cat.jpg
$ ls _gamer_cat.jpg.extracted/*/
```

You'll find a ZIP file (possibly named `zip_3266D.bin` or similar).

### Step 5: Decrypt the ZIP with the password

```bash
$ cd _gamer_cat.jpg.extracted/*/
$ unzip -P "f0r3ns1c5_r0ck" *.bin
$ cat _flag_layers.txt
khana{l4y3r3d_f0r3ns1cs_pr0}
```

**Flag:** `khana{l4y3r3d_f0r3ns1cs_pr0}`

**Lesson:** Real-world forensic investigations often require chaining multiple tools together. A single file can contain multiple layers of hidden data, each requiring a different technique to uncover.

---

## Challenge 5: `deep_cave.jpg` — "Deep Cave"
**Difficulty:** Hard | **Points:** 500
**Tools:** `exiftool`, `strings`, hex decoder, `steghide`, `git`

> You've entered the cave. The flag is buried deep underground.
> An agent hid classified intel somewhere in this image, but before
> they could brief the team, they went dark. All we know is they
> said: "You'll need every tool in your arsenal."
> The flag won't come easy. Dig. Decode. Extract. And when you
> think you've reached the end... look at the history.

This is a 9-step chain. Each step gives you a clue for the next. No single tool will get you the flag.

### Step 1: Check metadata

```bash
$ exiftool deep_cave.jpg
```

Key fields:
```
Comment                         : Not everything is on the surface. Dig deeper.
Author                          : Follow the HINT markers
```

The comment tells you to dig deeper. The author tells you to look for "HINT markers" — this is a clue to use `strings`.

### Step 2: Search for the HINT markers

```bash
$ strings deep_cave.jpg | grep -A1 HINT
--- HINT ---
546865207061737370687261736520697320633476335f6b3379
```

You found a long hex string between HINT markers.

### Step 3: Decode the hex

That string is hex-encoded ASCII. Decode it:

```bash
$ echo '546865207061737370687261736520697320633476335f6b3379' | xxd -r -p
The passphrase is c4v3_k3y
```

Now you have a passphrase: `c4v3_k3y`. The word "passphrase" is a hint — steghide uses passphrases.

### Step 4: Extract hidden data with steghide

```bash
$ steghide extract -sf deep_cave.jpg -p "c4v3_k3y"
wrote extracted data to "classified.txt".
```

### Step 5: Read the extracted file

```bash
$ cat classified.txt
Someone stored the flag in a git repo,
then deleted everything and pushed again.
They thought it was gone for good.

  git clone https://github.com/3aboshe/deep-cave

Check what was there before they deleted it.
```

The flag was in a git repo but got deleted. Time to dig into git history.

### Step 6: Clone the repo

```bash
$ git clone https://github.com/3aboshe/deep-cave
$ cd deep-cave
```

### Step 7: Check the file

```bash
$ cat secret.txt
```

The file is **empty**. The data has been deleted. Dead end? Not quite... the challenge description said "look at the history."

### Step 8: Check git history

```bash
$ git log --oneline
b379496 scrubbed sensitive data — nothing to see here
0280ee3 added classified intel
```

Two commits. The second one says "scrubbed sensitive data" — someone tried to cover their tracks. But git never truly forgets.

### Step 9: Recover the deleted data

View the file from the previous commit:

```bash
$ git show HEAD~1:secret.txt
khana{d33p_c4v3_expl0r3r}
```

**Flag:** `khana{d33p_c4v3_expl0r3r}`

**Lesson:** This challenge chains 5 different skills: metadata analysis (exiftool), string extraction (strings), encoding recognition (hex), steganography (steghide), and git forensics (git log/show). Deleting a file or clearing its contents doesn't remove it from git history. In real forensic investigations, version control systems are goldmines — `git reflog`, `git show`, and `git diff` can recover data that someone thought was permanently destroyed.

---

## Challenge 6: `rickroll.wav` — "Never Gonna Give You Up"
**Difficulty:** Medium | **Points:** 250
**Tool:** `strings`, Audacity / Sonic Visualiser (spectrogram)

> We intercepted an audio transmission from a suspect's burner phone.
> At first it just sounds like a familiar song — but our analysts believe
> there's more to it than meets the ear.

### Step 1: Listen to the file

```bash
$ open rickroll.wav
```

It's "Never Gonna Give You Up" by Rick Astley. You just got rickrolled. But there's more...

### Step 2: Check for string hints

```bash
$ strings rickroll.wav | grep -i hint
--- HINT ---
The flag is hidden where your ears cannot reach. Try viewing the spectrogram.
--- END ---
```

The hint says to view the spectrogram — the frequency representation of the audio.

### Step 3: Open in Audacity or Sonic Visualiser

Open the file in Audacity:
1. **File → Open** → select `rickroll.wav`
2. Click the track name dropdown (▼) → **Spectrogram**
3. Look at the **8–20 kHz range** — large bold text fills the upper half of the spectrogram

You'll see the flag written clearly in the high frequencies:

```
KHANA{R1CK}
```

The text is embedded as bold, scaled-up sine waves across the 8–20kHz range. Each character is thick and unmissable on the spectrogram.

**Flag:** `khana{r1ck}`

**Lesson:** Audio steganography can hide data in frequencies humans can't hear. Spectrogram analysis is a key tool in audio forensics — it reveals patterns in the frequency domain that are completely invisible when just listening. This technique is used in real-world CTFs and has been found in actual malware communications.

---

## All Flags

| # | File | Difficulty | Points | Tool(s) | Flag |
|---|------|-----------|--------|---------|------|
| 1 | `suspicious.pdf` | Easy | 50 | `file`, `exiftool` | `khana{f1l3_typ3s_c4nt_h1d3}` |
| 2 | `linus.jpg` | Easy | 75 | `binwalk`, `ls -la` | `khana{b1nw4lk_c4rv3s_s3cr3ts}` |
| 3 | `creation.png` | Easy | 150 | `zsteg` | `khana{z5t3g_p1x3l_m4st3r}` |
| 4 | `gamer_cat.jpg` | Medium | 300 | `exiftool` + ROT13 + `binwalk` + `unzip` | `khana{l4y3r3d_f0r3ns1cs_pr0}` |
| 5 | `deep_cave.jpg` | Hard | 500 | `exiftool` + `strings` + hex + `steghide` + `git` | `khana{d33p_c4v3_expl0r3r}` |
| 6 | `rickroll.wav` | Medium | 250 | `strings` + spectrogram viewer | `khana{r1ck}` |
