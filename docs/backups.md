# Backup Your Computer

One of Curi*OS*'s main goal is to provide rapid deployment, you should become
operational in less than 10 minutes on your machine, and it include managing
backups.

Curi*OS* management tool `curios-manager` (shortcut: Super+Return) came with a
`Backup` tool. Under the hood it run [restic](https://restic.net/), it provide
fast and secure backup program that can back up your files to **many different
storage types**, including self-hosted and online services. **Securely**, with use
of cryptography in every parts of the process. **Reliability**, enabling you to
make sure that your files can be restored when needed.
![curios-manager backup](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_main_backup.png?raw=true "curios-manager backup")

## Setup a Repository

The `Backup > Setup your backup` menu will prepare a new repository. This is simply
a directory containing a set of sub-directories and files created by `restic` to
store your backups, some corresponding metadata and encryption keys.
![curios-manager repository setup](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_repo_config.png?raw=true "curios-manager repository setup")
Every repository type setup required you to define a password.

> [!WARNING]
> Remembering your password is important! If you lose it, you won’t be able to
> access data stored in the repository.
> Password must be at least 6 characters long!

Passwords are securely stored with `secret-tool`.

Available repository type are:
- Local USB hard drives.
- Amazon AWS (S3 server).
- Other S3-compatible server like MinIO and RustFS.

**Note**: Google Cloud Storage and Backblaze B2 will be available in future
releases.

### USB Hard drives

Plugin your external USB hard disk. In the `COSMIC files` (shortcut: `Super+F`)
make sure the drive is mounted, if so an eject button will appear, if not click
on the USB drive name on the left panel.
In the `curios-manager` menu `Backup > Setup your backup`, choose the `Local (USB)`
option, you should be prompted with a list of the currently plugged and mounted
USB drives. Select a USB drive, you will then be prompted to setup a password for
this repository. The repository will then be initialized, you can now use the
`Backup now` menu.

### Amazon AWS

### S3-compatible server (MinIO, RustFS...)

For S3-compatible storage that is **not** Amazon AWS, you must provide an access
key and the secret key of your S3 bucket. You must also provide the complete URL
(IP/host name and port number included) of the bucket. For example on a RustFS
running on a NAS on your local network, the URL look like this:
`http://192.168.1.231:9000/bucket_name`.
You will also be prompted to set a repository password. The repository will then
be initialized, you can now use the `Backup now` menu.

## Backing Up

![curios-manager backup menu](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_now.png?raw=true "curios-manager backup menu")

The `Backup > Backup now` menu will backing up your HOME directory `/home/<username>`
content including hidden directories. The root partition `/` and its content
will not be backed up in order to save space on your backups repository. In case
of catastrophic failure it will be easier to re-install your system from fresh
(See our [installation guide](getting-started.md)) and then restore your home directory.

Content of a backup at a specific point in time is called a "snapshot".

## Restoring from a Repository

![curios-manager backup restore menu](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_restore.png?raw=true "curios-manager backup restore menu")

## Repository Stats

![curios-manager backup stats](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_snapshots.png?raw=true "curios-manager backup stats")

## Notes

Repository URL and access key (for S3 server) are stored in your `~/.env` file.
S3 secret key and repository password are safely stored with `secret-tool`.

**Previous**: [First Steps](first-steps.md).

**Back**: [index](index.md)
