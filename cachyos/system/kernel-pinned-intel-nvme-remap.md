# LTS kernel pinned at 6.18.50-3: CachyOS dropped `intel-nvme-remap` (main kernel fixed in 7.2.9)

**Date:** 2026-09-28 (updated 2026-10-05)
**Category:** system
**Files touched:** `/etc/pacman.conf` (copy: [`files/etc/pacman.conf`](../files/etc/pacman.conf))

## What
Holding the CachyOS LTS kernel packages, its NVIDIA module, and NVIDIA's user-space
packages with `IgnorePkg`. The main `linux-cachyos` kernel updates normally again since
7.2.9-1 restored the driver. Everything else updates normally.

## Why
The laptop's NVMe drive sits behind the chipset's Intel RST "remap" mode (storage
controller `00:17.0`, `8086:06d7`, 400 Series mobile RAID). In that mode the NVMe
disappears from the PCI bus, and the kernel only sees it through
`intel-nvme-remap`: Daniel Drake's (Endless OS) out-of-tree driver. It was rejected
upstream in 2019 and CachyOS carried it as its own patch, built in.

CachyOS dropped that patch from `linux-cachyos` 7.2.5 onward and from LTS 6.18.52. With
no driver, the boot image can't find the root drive, so every one of those kernels boots
straight into emergency mode. Hit it twice here: 7.2.6/7.2.7 first, then 7.2.7 + LTS
6.18.52 together. Recovered both times by restoring a snapper snapshot.

Verified by extracting each package's `usr/lib/modules/<ver>/modules.builtin` and looking
for `drivers/pci/controller/intel-nvme-remap`:

| Kernel | Has the driver | Boots |
|---|---|---|
| 7.2.4-3 | yes | yes |
| LTS 6.18.50-3 | yes | yes |
| 7.2.5–7.2.8-2 | no | no (emergency mode) |
| 7.2.9-1 | yes | yes (confirmed 2026-10-05) |
| LTS 6.18.52-1, 6.18.55-1 | no | no (emergency mode) |

Upstream bug: [CachyOS/linux-cachyos#1054](https://github.com/CachyOS/linux-cachyos/issues/1054).
It was open with no maintainer response as of 2026-09-28. On 2026-10-01 the maintainer
(ptr1337) said they would look at rebasing the patch back in for the next 7.3 and 7.2
releases. Before that, it was unclear whether the
patch was lost by accident or dropped on purpose. `linux-cachyos` 7.2.9-1 (2026-10-03)
has it built in again; LTS 6.18.55-1 still doesn't. The issue was still open on
2026-10-05.

## Change
In `/etc/pacman.conf`, under `[options]` (replaces the commented `#IgnorePkg =`):
```
IgnorePkg = linux-cachyos-lts linux-cachyos-lts-headers linux-cachyos-lts-nvidia-open nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia
```
One-liner that applies it on a fresh install:
```
sudo sed -i 's/^#IgnorePkg\s*=.*/IgnorePkg = linux-cachyos-lts linux-cachyos-lts-headers linux-cachyos-lts-nvidia-open nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia/' /etc/pacman.conf
```
Then `sudo pacman -Syu` as usual. Pacman prints `ignoring package upgrade` for each held
package.

## Notes
- **History:** from 2026-09-28 to 2026-10-05 the main kernel was held too, at 7.2.4-3
  (`linux-cachyos linux-cachyos-headers linux-cachyos-nvidia-open` were also in the
  `IgnorePkg` line). Those three were removed with
  `sudo sed -i 's/^IgnorePkg = linux-cachyos linux-cachyos-headers linux-cachyos-nvidia-open /IgnorePkg = /' /etc/pacman.conf`
  after 7.2.9-1 was checked and found to have the driver again.
- **When the hold can go entirely:** once an LTS package has the driver (check it the
  same way as below), delete the whole `IgnorePkg` line.
- **The NVIDIA hold will start blocking main-kernel updates** once NVIDIA ships a driver
  newer than 615.71.09: the next `linux-cachyos-nvidia-open` will need the newer
  `nvidia-utils`, which is held. At that point either a fixed LTS is out (drop the hold)
  or remove the LTS kernel and its NVIDIA module and drop the hold.
- **Why the NVIDIA user-space packages are held too:** the held LTS kernel module
  (`linux-cachyos-lts-nvidia-open`) requires `nvidia-utils=615.71.09` exactly, and
  `lib32-nvidia-utils` requires the same `nvidia-utils`. The OpenCL packages don't declare
  a version but come from the same driver release, so they're held to keep everything on
  one version. If
  user space upgraded alone, the NVIDIA GPU would stop working, and the HDMI port is
  wired to it.
- **Spotting a new kernel:** `checkupdates` hides `IgnorePkg` packages, so it won't show
  held kernels. Compare repo vs installed directly instead:
  ```
  checkupdates >/dev/null; pacman -Sl --dbpath /tmp/checkup-db-$(id -u) cachyos-v3 | grep -E " linux-cachyos(-lts)? "
  ```
  Known-broken versions as of 2026-10-05: `linux-cachyos` 7.2.5 through 7.2.8-2, and
  `linux-cachyos-lts` 6.18.52-1 and 6.18.55-1.
- **Before removing the hold,** check each new kernel package for the driver without
  installing it:
  ```
  checkupdates >/dev/null
  URL=$(pacman -Sddp --dbpath /tmp/checkup-db-$(id -u) linux-cachyos | tail -1)
  curl -sSfL -o /tmp/k.pkg.tar.zst "$URL"     # or cp if URL is file://
  tar --zstd -xOf /tmp/k.pkg.tar.zst --wildcards '*/modules.builtin' | grep nvme-remap
  ```
  No output means it's still missing, so keep holding. Check the LTS package the same way.
  Forum reports saying "LTS 6.18.52 works" came from machines without RST remap and were
  wrong for this laptop.
- **Arch's stock `linux` kernel won't work either.** It never had this driver.
- **How long this is OK for:** weeks to a couple of months. After that you're missing
  kernel security fixes, and other packages will eventually expect a newer kernel.
- **Permanent alternative:** switch the BIOS storage mode from RST/RAID to AHCI, after
  which any kernel works. Windows/BitLocker has to be prepared first: suspend BitLocker,
  have the recovery key saved, run `bcdedit /set {current} safeboot minimal`, switch
  the BIOS, boot Windows once in Safe Mode, run `bcdedit /deletevalue {current} safeboot`,
  resume BitLocker. See [[windows-dual-boot-order-and-bitlocker]] for this machine's
  Windows boot setup.
- **Other alternative, not taken:** building `linux-cachyos` yourself with the driver
  restored. Someone on #1054 did this for 7.2.6 on the same chipset family and it booted.
  Costs: about 1–2 h of building per kernel release, plus building the NVIDIA module
  (or `nvidia-open-dkms`) for it. If ever done, take the driver from CachyOS's own 7.2.4
  patch. The #1054 build also dropped the `sysdata.nvme_remap_dev` assignment. That's
  harmless while IOMMU DMA translation is off, which is the case here: `/sys/class/iommu`
  is empty and only interrupt remapping is enabled.
- **Emergency-mode boots leave no logs.** Root never mounts, so the journal stays in
  RAM and is lost on reboot. To capture the error next time, run
  `journalctl -b | grep -iE "nvme|remap|root|initrd"` in the emergency shell
  *before* restoring a snapshot.
- After a snapshot restore, power off fully instead of restarting. A warm restart after
  one restore left the laptop panel (eDP-1) missing.
- **Restarts may also hit emergency mode on a working kernel (unconfirmed).** On
  2026-10-03, 7.2.4-3 went into emergency mode after a restart (following a
  `mkinitcpio` 42.2 update), then booted fine from a full power-off with the same boot
  images. Suspected cause: the firmware doesn't fully reset the RST controller on a warm
  restart. After kernel or `mkinitcpio` updates, power off fully instead of restarting.
