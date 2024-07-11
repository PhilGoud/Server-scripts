# Chell
Description and scripts used on my homeserver named Chell
I won't think about checking things daily, so I will use Telegram to keep me informed

## A little background
I use a Lenovo M73 with Debian 12 with CasaOS on top of it  

Connected to it is :
- 1 USB 2.0 HDD used for parity
- 2 USB 3.0 docks composed of 4 HDDs
  
Most of my apps (Plex, Tranmission, AdGuard, Wireguard, HomeAssistant... ) will be in docker containers managed via CasaOS, except core system functions.

## Storage
### Mergerfs
I use mergerfs to pool together the 2 docks composed of 4 hard-drives
They are mounted via fstab to /mnt/disk-A1 to /mnt/disk-B4
Letter is the dock identifier and number is the disk position from left to right

**Location on my server** : /etc/fstab

### Snapraid
To ensure some disk parity, i use snapraid
Every day, it will update the parity disk and check the state

**Location on my server** : /scripts/

### SMART state
My disks may one day fail, so we will use SMART to get their state everyday

**Location on my server** : /scripts/

### Archive Backup
I use Wasabi as a storage for my backups with rclone service

**Location on my server** : /scripts/

## Torrent
I want to be notified when my Linux distros are there so I can enjoy them, so i will use a function of the settings.json file in /DATA/APPDATA/transmission/config folder to execute script at start/end of downloading

Those 4 lines are changed :

>"script-torrent-added-enabled": true,
>"script-torrent-added-filename": "/config/torrentstart.sh",  
>"script-torrent-done-enabled": true,  
>"script-torrent-done-filename": "/config/torrentdone.sh",  
>"script-torrent-done-seeding-enabled": false,

IMPORTANT : stop Transmission before changing those lines or it will overwrite config changes at shutdown (took me too much time to understand that, drove me crazy)

I will use a script at launch to check that torrent notifications are still active as I don't trust anything in life

**Location on my server** : /DATA/AppData/transmission/config


## Cron
Everything maintenance-related is started via crontab. 
Edit via 
  sudo crontab -e

**Example at** /crontab


