# Unlock BitLocker drives via Bitwarden + cryptsetup, no retyped passwords

**Date:** 2026-09-20 (updated 2026-09-20 — renamed `bw-*` → `bit-*`, added interactive menu, `laptop` drive moved out to a plain `fstab` auto-mount since it's no longer BitLocker-encrypted; updated 2026-09-27 — `nani` permanently decrypted too, moved to `fstab` at `/mnt/study`)
**Category:** bitlocker (portable — works on any Linux distro/WM, `cryptsetup` + `bw` CLI only)
**Files touched:** `~/.local/bin/bit-unlock`, `~/.local/bin/bit-lock`, `/etc/fstab` — stored copies in `bitlocker/files/.local/bin/` and `bitlocker/files/etc/fstab`

<!-- graph:begin -->
**Graph:** [[BitLocker]] · [[Windows]] · [[Bitwarden]]
<!-- graph:end -->

## What
Two scripts to unlock and mount **actually BitLocker-encrypted** NTFS partitions from
Linux using a passphrase pulled live from Bitwarden, instead of retyping the BitLocker
password/recovery key every time or storing it in a plaintext keyfile on disk.

- `bit-unlock` (no arguments) — interactive numbered menu, pick one or more drives by
  number (space-separated) or `a` for all.
- `bit-unlock all` / `bit-unlock both` — unlock + mount every known drive, no prompt.
- `bit-unlock <name> [<name>...]` — unlock + mount one or more specific drives (e.g.
  `bit-unlock nani`, or `bit-unlock nani desktop-c`), no prompt.
- `bit-lock` / `bit-lock all` / `bit-lock both` / `bit-lock <name> [<name>...]` — same
  selection syntax (including the interactive menu with no arguments), cleanly unmounts
  and closes instead.

Known drives (hardcoded in both scripts):

| Name | Partition | Bitwarden item | Mount point |
|---|---|---|---|
| `desktop-c` | `/dev/nvme0n1p3` | `BitLocker - DESKTOP-8PKDU07 C:` | `/mnt/desktop-c` |

`desktop-c` is the actual live dual-booted Windows OS partition (`DESKTOP-8PKDU07`), not a
data-only drive — worth being more deliberate about writes there.

**`laptop` (`/dev/nvme0n1p5`, now `Data`) and `nani` (`/dev/nvme0n1p6`, now `Study`) are
deliberately not in this tool at all anymore** — both were permanently decrypted, so
they're plain `/etc/fstab` entries, always mounted, no unlock step of any kind. See Notes.

## Why
Wanted to stop retyping BitLocker passwords/recovery keys by hand every time, since all of
them are already stored in Bitwarden. Considered and rejected two other approaches first:

1. A plaintext keyfile on disk (`/etc/bitlocker-keys/*.key`) — rejected because this
   machine's root filesystem (`nvme0n1p9`, btrfs) is itself unencrypted, so a keyfile would
   be readable by anyone with physical access via a live USB, indefinitely, no
   re-authentication ever required.
2. Autofill into the GUI unlock dialog via `wtype` (Wayland keystroke injection), triggered
   from the Bitwarden CLI — worked in principle (Mango supports the needed
   `wlr_virtual_keyboard_manager_v1` protocol) but is unnecessarily complex and carries a
   focus-hijack risk (types into whatever window happens to be focused). Realized
   `cryptsetup open --key-file=-` can read the passphrase straight from stdin, so it can be
   piped directly from `bw get password` with no GUI interaction, no keystroke injection,
   and no extra `wtype` dependency at all.

The `BW_SESSION` caching (see Notes) exists so the master password isn't needed on every
single unlock, without ever writing the vault's session key to persistent disk.

## Change

`~/.local/bin/bit-unlock`:
```bash
#!/usr/bin/env bash
# Unlock BitLocker-encrypted partitions and mount them, using a passphrase
# stored in Bitwarden. With no arguments, shows an interactive menu.
# Usage:
#   bit-unlock                     interactive menu
#   bit-unlock all | both          unlock every known drive
#   bit-unlock <name> [<name>...]  unlock one or more specific drives
set -uo pipefail

KNOWN_DRIVES=(desktop-c)

usage() {
    echo "usage: bit-unlock [all|both]" >&2
    echo "   or: bit-unlock <name> [<name>...]   (desktop-c)" >&2
    echo "   with no arguments, shows an interactive menu" >&2
    exit 1
}

prompt_drives() {
    echo "Which drive(s) to unlock?" >&2
    local i=1
    for d in "${KNOWN_DRIVES[@]}"; do
        echo "  $i) $d" >&2
        i=$((i + 1))
    done
    echo "  a) all" >&2
    read -r -p "Enter numbers separated by spaces, or 'a' for all: " REPLY

    local choice DRIVES=()
    for choice in $REPLY; do
        case "$choice" in
            a|all|both)
                DRIVES=("${KNOWN_DRIVES[@]}")
                break
                ;;
            ''|*[!0-9]*)
                echo "ignoring invalid choice '$choice'" >&2
                ;;
            *)
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#KNOWN_DRIVES[@]}" ]; then
                    DRIVES+=("${KNOWN_DRIVES[$((choice - 1))]}")
                else
                    echo "ignoring out-of-range choice '$choice'" >&2
                fi
                ;;
        esac
    done

    [ "${#DRIVES[@]}" -gt 0 ] || { echo "nothing selected" >&2; exit 1; }
    printf '%s\n' "${DRIVES[@]}"
}

unlock_one() {
    local NAME="$1" PART LABEL ITEM

    case "$NAME" in
        desktop-c)
            PART="/dev/nvme0n1p3"
            LABEL="desktop-c"
            ITEM="BitLocker - DESKTOP-8PKDU07 C:"
            ;;
        *)
            echo "unknown drive '$NAME' — known: desktop-c" >&2
            return 1
            ;;
    esac

    local MAPPER="bitlocker-$LABEL"
    local MOUNTDEV="/dev/mapper/$MAPPER"
    local MOUNTPOINT="/mnt/$LABEL"
    local SESSION_FILE="/run/user/$(id -u)/bw-cli-session"

    if [ -e "$MOUNTDEV" ]; then
        echo "[$NAME] already unlocked at $MOUNTDEV" >&2
    else
        # Reuse a cached session (tmpfs only, never touches disk, cleared on
        # logout/reboot) if it's still valid; otherwise unlock fresh and
        # cache it.
        if [ -z "${BW_SESSION:-}" ] && [ -f "$SESSION_FILE" ]; then
            BW_SESSION="$(cat "$SESSION_FILE")"
        fi
        if [ -z "${BW_SESSION:-}" ] || [ "$(bw status --session "$BW_SESSION" 2>/dev/null | jq -r '.status')" != "unlocked" ]; then
            BW_SESSION="$(bw unlock --raw)"
            install -m 600 /dev/null "$SESSION_FILE"
            printf '%s' "$BW_SESSION" > "$SESSION_FILE"
        fi
        export BW_SESSION

        local PASSWORD
        PASSWORD="$(bw get password "$ITEM" --session "$BW_SESSION")"
        printf '%s' "$PASSWORD" | sudo cryptsetup open --type bitlk --key-file=- "$PART" "$MAPPER"
        unset PASSWORD
    fi

    sudo mkdir -p "$MOUNTPOINT"
    if mountpoint -q "$MOUNTPOINT"; then
        echo "[$NAME] already mounted at $MOUNTPOINT" >&2
    else
        sudo mount -o uid="$(id -u)",gid="$(id -g)" "$MOUNTDEV" "$MOUNTPOINT"
        echo "[$NAME] mounted at $MOUNTPOINT"
    fi
}

if [ "$#" -eq 0 ]; then
    mapfile -t DRIVES < <(prompt_drives)
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
elif [ "$1" = "all" ] || [ "$1" = "both" ]; then
    DRIVES=("${KNOWN_DRIVES[@]}")
else
    DRIVES=("$@")
fi

STATUS=0
for d in "${DRIVES[@]}"; do
    echo "=== $d ==="
    unlock_one "$d" || STATUS=1
    echo
done
exit "$STATUS"
```

`~/.local/bin/bit-lock`:
```bash
#!/usr/bin/env bash
# Cleanly unmount and close drives previously opened with bit-unlock.
# With no arguments, shows an interactive menu to pick which drive(s).
# Usage:
#   bit-lock                     interactive menu
#   bit-lock all | both          close every known drive
#   bit-lock <name> [<name>...]  close one or more specific drives
set -uo pipefail

KNOWN_DRIVES=(desktop-c)

usage() {
    echo "usage: bit-lock [all|both]" >&2
    echo "   or: bit-lock <name> [<name>...]   (desktop-c)" >&2
    echo "   with no arguments, shows an interactive menu" >&2
    exit 1
}

prompt_drives() {
    echo "Which drive(s) to lock?" >&2
    local i=1
    for d in "${KNOWN_DRIVES[@]}"; do
        echo "  $i) $d" >&2
        i=$((i + 1))
    done
    echo "  a) all" >&2
    read -r -p "Enter numbers separated by spaces, or 'a' for all: " REPLY

    local choice DRIVES=()
    for choice in $REPLY; do
        case "$choice" in
            a|all|both)
                DRIVES=("${KNOWN_DRIVES[@]}")
                break
                ;;
            ''|*[!0-9]*)
                echo "ignoring invalid choice '$choice'" >&2
                ;;
            *)
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#KNOWN_DRIVES[@]}" ]; then
                    DRIVES+=("${KNOWN_DRIVES[$((choice - 1))]}")
                else
                    echo "ignoring out-of-range choice '$choice'" >&2
                fi
                ;;
        esac
    done

    [ "${#DRIVES[@]}" -gt 0 ] || { echo "nothing selected" >&2; exit 1; }
    printf '%s\n' "${DRIVES[@]}"
}

label_for() {
    case "$1" in
        desktop-c) echo "desktop-c" ;;
        *) return 1 ;;
    esac
}

lock_one() {
    local NAME="$1" LABEL
    LABEL="$(label_for "$NAME")" || {
        echo "unknown drive '$NAME' — known: desktop-c" >&2
        return 1
    }

    local MAPPER="bitlocker-$LABEL"
    local MOUNTPOINT="/mnt/$LABEL"

    if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
        sudo umount "$MOUNTPOINT"
    fi

    if [ -e "/dev/mapper/$MAPPER" ]; then
        sudo cryptsetup close "$MAPPER"
    fi

    echo "closed $NAME"
}

if [ "$#" -eq 0 ]; then
    mapfile -t DRIVES < <(prompt_drives)
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
elif [ "$1" = "all" ] || [ "$1" = "both" ]; then
    DRIVES=("${KNOWN_DRIVES[@]}")
else
    DRIVES=("$@")
fi

STATUS=0
for d in "${DRIVES[@]}"; do
    lock_one "$d" || STATUS=1
done
exit "$STATUS"
```

`/etc/fstab` (appended lines — `laptop`, now labeled `Data`; `nani`, now labeled `Study`):
```
UUID=5AAAE353AAE32A69  /mnt/data   ntfs3  uid=1000,gid=1000,nofail                 0  0
UUID=1246765146763597  /mnt/study  ntfs3  uid=1000,gid=1000,nofail,x-mount.mkdir  0  0
```
Both confirmed working after a reboot: mounted read-write, owned by the invoking user,
no interaction needed. `x-mount.mkdir` creates the mount point if it's missing, so a fresh
setup doesn't need a separate `mkdir`.

Both scripts are `chmod 755`; `~/.local/bin` is already on `PATH`.

Setup performed once: `sudo pacman -S bitwarden-cli`, then `bw login` (interactive, one
time), then `bw unlock` the first time any script runs (subsequent runs reuse the cached
session — see Notes).

Each BitLocker password is stored as a Bitwarden **Login**-type item (not a Secure Note —
`bw get password` specifically reads a Login item's password field) with the key pasted
into the password field, named to match the table above.

## Notes
- **Session caching is memory-only, by design.** The vault session key is cached to
  `/run/user/<uid>/bw-cli-session` (mode `600`), which is tmpfs — RAM-backed, never
  written to actual disk, wiped on logout/reboot. Storing it persistently would be worse
  than the plaintext-keyfile approach that was rejected, since a live `BW_SESSION` can
  decrypt the *entire* vault, not just one drive's key.
- **`--key-file=-` doesn't strip trailing newlines** (per `cryptsetup`'s own man page) — the
  script deliberately captures the password into a shell variable first (which strips the
  trailing newline via normal command substitution) rather than piping `bw get password`
  straight into `cryptsetup`, to avoid a silent passphrase mismatch.
- **Mount uses `-o uid=,gid=`** so the mounted NTFS tree is owned by the invoking user, not
  root — otherwise every `cp`/`mv` afterward would need `sudo` too. Same reasoning applied
  to the `laptop` `fstab` entry below.
- **Corruption-safety checklist confirmed before using this regularly:** Fast Startup and
  Hibernate are both off on `DESKTOP-8PKDU07` (the only actual bootable Windows install
  among these partitions — `laptop`/`nani` are just old data drives from other machines, no
  OS ever boots from them so their hibernation state is irrelevant). Without Fast Startup
  off, resuming Windows after writing to shared NTFS partitions from Linux risks corruption
  from Windows' stale in-memory filesystem cache overwriting on-disk changes.
- **`laptop` moved out of `bit-unlock`/`bit-lock` entirely — it's no longer BitLocker at
  all, so it doesn't belong in a tool named after BitLocker.** Full history: originally
  this drive (`/dev/nvme0n1p5`) threw `WARNING: BitLocker volume size 269481934848 does not
  match the underlying device size 216046501888` on every unlock (BitLocker's header
  remembering an original ~251GiB size from before this partition was resized/migrated down
  to its current 201.2GiB) — cosmetic only, `cryptsetup`/`ntfs3` handled it fine at the
  time. Attempted a proper fix on 2026-09-20 by decrypting (turning off BitLocker) in
  Windows, intending to immediately re-encrypt for fresh size metadata — but **Windows 10
  Home cannot re-enable BitLocker on a data volume at all** (full BitLocker is
  Pro/Enterprise/Education only; Home only has TPM-gated Device Encryption for the OS
  drive). Decided to leave it permanently unencrypted rather than upgrade Windows editions
  for one data volume.
  Since there's no secret to protect anymore, it doesn't need an interactive unlock step at
  all — moved to a plain `/etc/fstab` entry (see Change above), always mounted at
  `/mnt/data` from boot, `nofail` so boot doesn't hang if it's ever missing.
  Its NTFS UUID changed after decryption (was a different value under the BitLocker
  container) and its volume label changed from `New Volume` to `Data` at some point — the
  `fstab` line uses the new UUID (`5AAAE353AAE32A69`), confirmed via `lsblk`. The old
  Bitwarden item (`BitLocker - LAPTOP-ADN3BT6B New Volume`) is unused now; left in the
  vault as a historical record rather than deleted, but its password is meaningless.
- **`nani` also permanently decrypted on 2026-09-27 and moved to `fstab` at `/mnt/study`.**
  Unlike `laptop`, this was a choice, not a technical dead end: it's a data-only drive
  judged not to hold anything sensitive, and the unlock step wasn't worth it. Decrypted
  from Windows (`DESKTOP-8PKDU07`) with `manage-bde -off <letter>:` after unlocking it
  there — the same route as `laptop`. `cryptsetup` can only open/close a BitLocker
  container, it can't safely remove one. The NTFS UUID (`1246765146763597`) stayed the same
  after decryption, unlike `laptop`'s. The mount point changed from `/mnt/nani-newvolume` to
  `/mnt/study`, matching its `Study` label the way `Data` is at `/mnt/data`. The old
  `/mnt/nani-newvolume` and `/mnt/laptop-newvolume` directories are empty leftovers.
  Bitwarden item `BitLocker - NANI New Volume` is now unused.
- **Dolphin can't unlock the BitLocker drives via its own GUI prompt** — no polkit
  authentication agent is installed on this machine (only bare `polkitd`, no
  `polkit-kde-agent`/`polkit-gnome`/etc.), so udisks2's encrypted-unlock authorization
  request has nothing to render a dialog with and just fails silently. Not fixed — these
  scripts bypass udisks2/polkit entirely by calling `cryptsetup` directly via `sudo`.
  (Separately, `nvme0n1p7`/`p8`, `RECOVERY` and `RESTORE`, mount fine via Dolphin — they're
  plain NTFS, not BitLocker at all, and the password prompt Dolphin does show for them is
  just the Linux account password, a system-partition mount authorization check, not a
  BitLocker key — that one path does work without an agent, for reasons not fully
  resolved.)
- **Interactive menu added on request** — running either script with no arguments now
  prompts with a numbered list (space-separated numbers, or `a` for all) instead of
  requiring drive names as command-line arguments. Direct arguments (`all`/`both`, or one
  or more names) still work unprompted, for scripting/muscle-memory use.
- **Future plan, not yet decided/scheduled — may decrypt `desktop-c` and migrate it to
  VeraCrypt.** Thinking about using VeraCrypt instead of BitLocker for encrypting drives
  going forward — plausibly prompted by the two BitLocker limitations hit above (the
  unrepairable size-mismatch metadata, and Windows 10 Home being unable to re-enable
  BitLocker on a data volume at all). VeraCrypt is cross-platform and edition-independent,
  which would sidestep both. The 2026-09-20 version of this plan covered `nani` too; `nani`
  has since been left unencrypted instead (see above), so `desktop-c` (`/dev/nvme0n1p3`) is
  the only remaining candidate, "if necessary" (not committed to a timeline). If/when this
  happens, `bit-unlock`/`bit-lock` would need real changes, not just a new table row —
  they're built specifically around `cryptsetup --type bitlk`, and VeraCrypt volumes aren't
  unlocked that way (VeraCrypt has its own CLI/format, not handled by `cryptsetup`'s
  `bitlk` support). `desktop-c` is the live Windows OS partition, not just a data volume —
  worth extra care/planning if it's ever actually decrypted.
