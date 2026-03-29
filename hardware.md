# **Hardware Inventory**

Full hardware specifications for all BonConLab infrastructure.

## **Proxmox Nodes**

### **SB (Dell Optiplex 7080 Micro)**

Primary cluster node. Newest hardware, best CPU.

| Component | Specification |
| :---- | :---- |
| CPU | Intel Core i5-10500 (6C/12T, 3.1-4.5GHz, 65W) |
| RAM | 24GB DDR4-3200 (8GB + 16GB) |
| Boot Storage | 256GB NVMe (Kioxia) + 256GB NVMe (New) — ZFS mirror |
| Data Storage | 1TB SATA SSD (WD Blue) — sb-1tb-ssd |
| Network | 1G RJ45 (Onboard) + **2.5G USB 3.0 Adapter** |
| Interface ID | `enxf44dad05f100` (USB 2.5G) |
| Form Factor | Micro |

**M.2 slot notes**: Slots labeled "1" and "2" in circles on the board.

### **TMG (Dell Optiplex 3070 Micro)**

Lightweight services node. Lowest power draw.

| Component | Specification |
| :---- | :---- |
| CPU | Intel Core i5-9500T (6C/6T, 2.2-3.7GHz, 35W) |
| RAM | 16GB DDR4-3200 (2x 8GB matched) |
| Boot Storage | 256GB NVMe + 256GB SATA SSD (SanDisk X400) — ZFS mirror |
| Network | 1G RJ45 (Onboard) + **2.5G USB 3.0 Adapter** |
| Interface ID | `enxf44dad05f091` (USB 2.5G) |
| Form Factor | Micro |

### **DB (Dell Optiplex 7060 SFF)**

Storage & Backup Manager. *Rebuilt 2026-01-30.*

| Component | Specification | Connection |
| :---- | :---- | :---- |
| CPU | Intel Core i5-8500 (6C/6T, up to 4.1GHz, 65W) | Onboard |
| RAM | 32GB DDR4-2666 (4x 8GB matched) | Slots 1-4 |
| **Boot Storage** | 2x 500GB Samsung 870 EVO (ZFS Mirror) | SATA 0 & 2 (Mobo) |
| **Fast Data** | 1x 2TB NVMe (Samsung 970 EVO Plus) | M.2 Slot |
| **Warm Data** | 2x 2TB Crucial BX500 (ZFS Mirror) | SATA 3 (Mobo) & PCIe Card |
| **Expansion** | Glotrends PCIe x4 SATA Card | Blue x16 Slot |
| **Network** | 1G Onboard \+ 2.5G Realtek (PCIe) | Black x4 Slot |

**Notes:**

* **Warm Data Config:** Split between motherboard and PCIe card for controller redundancy.
* **Bays:** 3.5" bay converted to hold 2x SSDs. Optical drive bay available.
* **BIOS**: Version 1.2.22 (2018-11-01). Consider firmware update in a future session.
* **SATA Operation**: Must be set to **AHCI** in BIOS (not RAID On). RAID mode causes NVMe remapping through the AHCI controller, making the drive invisible to Linux (`/dev/nvme*` device nodes are not created). Dell OptiPlex 7060 SFF defaults to RAID mode on factory reset.
* **CMOS Battery**: CR2032 replaced 2026-03-21. Dead CMOS battery caused BIOS reset to factory defaults (RAID mode) after the 2026-03-19 power outage, making the NVMe pool db-2tb-nvme disappear until BIOS was corrected.

## **DP (Proxmox Node)**

### **DP (Datto ALTO 3 V2 enclosure, NUC7i5DNBE board)**

4th Proxmox cluster node. Original Datto ALTO 3 V2 enclosure with internals replaced by an Intel NUC Board NUC7i5DNBE. Hosts the HAOS VM.

| Component | Specification |
| :---- | :---- |
| CPU | Intel Core i5-7300U (2C/4T, up to 3.5GHz, 15W TDP) — 7th gen vPro |
| RAM | 16GB DDR4 (2x Samsung 8GB 1Rx8 PC4-3200AA, downclocked to 2133MHz by board) |
| Boot Storage | 256GB Intel SSDSCKKF256G8 + 256GB Samsung 840 PRO — ZFS mirror (SATA) |
| Network | Intel I219LM Gigabit Ethernet (1GbE) |
| Hostname | dp.local |
| IP | 10.0.0.5 (static, reserved in Unifi) |
| Role | Proxmox node — hosts HAOS VM (VM 401) |

**Proxmox config**: ZFS mirror boot pool (rpool). ZFS ARC max left at installer default (~782 MiB). Tailscale installed on bare metal with `--ssh` flag.

## **Raspberry Pis**

| Device | RAM | Current Role | Status |
| :---- | :---- | :---- | :---- |
| Raspberry Pi 4 Model B Rev 1.5 | 2GB | Packing Assistant app | Active |
| Raspberry Pi 3 Model B | 1GB | PiHole Backup DNS | Active |

**Pi 3 Notes:**

* Handles DNS filtering with ease (2700+ queries/second capability)  
* Running Raspberry Pi OS Lite with Log2Ram for SD card longevity  
* Uses official 2.5A power supply for stability  
* IP: 10.0.0.229 (reserved in Unifi as "PiHole\_Pi3")

## **External Storage**

All external drives are formatted **exFAT** for compatibility and media storage.

| Device | Capacity | Interface | Mount Point | Proxmox ID |
| :---- | :---- | :---- | :---- | :---- |
| WD Elements Desktop | 18TB | USB 3.0 | /mnt/external-18tb-hdd | external-18tb-hdd |
| Inateck Dock Slot 1 (WD40EDAZ) | 4TB | USB 3.0 | /mnt/external-4tb-hdd-1 | external-4tb-hdd-1 |
| Inateck Dock Slot 2 (WD40EDAZ) | 4TB | USB 3.0 | /mnt/external-4tb-hdd-2 | external-4tb-hdd-2 |

**Total external capacity**: 26TB

**Role**: Passthrough storage for NAS Container (Media Archives).

## **Network Hardware**

See [Network Configuration](https://www.google.com/search?q=network.md) for topology and IP assignments.

| Device | Role | Location |
| :---- | :---- | :---- |
| USG-3P | Gateway/Router | 1st Floor |
| USW-Flex-2.5G-5-PoE | Distribution Switch | 1st Floor |
| USW-Flex-2.5G-8-PoE | Homelab Switch | Upstairs (closet) |
| USW-Flex-2.5G-5-PoE | Garage Switch | Garage |
| Netgear GS208 | Unmanaged 8-port Gigabit | Upstairs (closet) |
| Unifi AC Pro | Wireless AP | Upstairs |
| Unifi AC Pro | Wireless AP | Garage |

## **Other Devices**

| Device | Location | Notes |
| :---- | :---- | :---- |
| Zigbee PoE Coordinator | 1st Floor | Connected to HA via Zigbee2MQTT |
| JetKVM | Homelab closet | Remote KVM access |
| Philips Hue Bridge | Upstairs | Connected via GS208 |
| Prusa Core One | Garage | 3D printer, networked via ethernet |
| PlayStation 5 | 1st Floor |  |
| Apple TV | 1st Floor |  |

