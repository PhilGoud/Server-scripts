# Chell
Description and scripts used on my homeserver named Chell
I won't think about checking things daily, so I will use Telegram to keep me updated on my server

## A little background on Chell
I use a Lenovo M73 with Debian 12 with CasaOS on top of it  
Connected to it is :
- 2 USB 3.0 docks composed of 4 HDDs
- 1 USB 2.0 HDD used for Trashes from backups
  
Most of my apps (Plex, Tranmission, AdGuard, Wireguard, HomeAssistant... ) will be in docker containers managed via CasaOS, except core system functions.

## Storage
### Mergerfs
I use mergerfs to pool the disks in the 2 docks composed of 4 hard-drives
One dock is name CAKE, the other one is used for cold redundancy and is called BOREALIS
They are mounted via fstab to /mnt/disk-A1 to /mnt/disk-A4 and /mnt/disk-B1 to /mnt/disk-B4
Letter is the dock identifier and number is the disk position from left to right


**Example** : fstab.txt

**Location on my server** : /etc/fstab

### SMART state
My disks may one day fail, so we will use SMART to get their state everyday


**script** smartcheck.sh

**Location on my server** : /scripts/

### Archive Backup
I use Wasabi as a storage for my backups with rclone service


**script** rclone.sh

**Location on my server** : /scripts/

### Sync CAKE > BOREALIS
Okay this script took me some time.
I wanted to sync CAKE to BOREALIS but realized that if one disk fails, i will delete the very files i wanted to save.
So what this script does is, folder by folder : 
- Copy all new and updated files from CAKE to BOREALIS (now all files on CAKE are on BOREALIS)
- Does a dry run of a rsync from BOREALIS to CAKE. If files are on BOREALIS but not on CAKE, that means there is some data loss on CAKE
- Logs thoses suspected datalosses in a file
  
Most of the time it will be some file I have deleted from CAKE and it is technicaly a data loss but a loss I wish.
So there is a script to rsync and delete on BOREALIS

Of course some folders change all the time and it would be very VERY tiring to run manually the script to accept thoses deletions
That's why folders can be or NOT be checked for data loss

There is a bit of terminal verbose just to check everything is alright but as specified, Telegram notification during checks and at the end are the true purpose.


**scripts** rsync.sh & rsync-delete.sh

**Location on my server** : /scripts/

### Disk usage
I may see some space left in CAKE but one of the drive is full, that's why i have a daily notification and an alert if disk is used at more than 90%


**scripts** diskusage.sh & diskfull-alert.sh

**Location on my server** : /scripts/

## Torrent
I want to be notified when my Linux distros are there so I can enjoy them, so i will use a function of the settings.json file in /DATA/APPDATA/transmission/config folder to execute script at (start/)end of downloading

Those 4 lines can be changed :

>"script-torrent-added-enabled": false,
>"script-torrent-added-filename": "",  
>"script-torrent-done-enabled": true,  
>"script-torrent-done-filename": "/config/torrentdone.sh",  
>"script-torrent-done-seeding-enabled": false,

IMPORTANT : stop Transmission before changing those lines or it will overwrite config changes at shutdown (took me too much time to understand that, drove me crazy)

I will use a script at launch to check that torrent notifications are still active as I don't trust anything in life


**script** torrentdone.sh

**Location on my server** : /DATA/AppData/transmission/config


## Cron
Everything maintenance-related is started via crontab. 
Edit via 
  sudo crontab -e
**example** crontab.txt

I can read a human-friendly version with a script
**script** tool/crontab.sh
**Location on my server** : /scripts/

##Tools

I did a small selection of script tools to use when I need them
From movies organizations to crawl and download, not forgetting about following how a log file is doing, you may need one of them one day, do not hesitate to read them
**Location on my server** : /scripts/tools/

## The rest

For curious people, if you search you will find some goodies not listed here to personnalize your server as I did :)

