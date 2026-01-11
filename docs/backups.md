# Backup Your Computer

One of Curi*OS*'s main goal is to provide rapid deployment, you should become
operational in less than 10 minutes on your machine, and it include managing
backups.

Curi*OS* management tool `curios-manager` (shortcut: Super+Return) came with a
`Backup` menu. Under the hood it run [restic](https://restic.net/), it provide
fast and secure backup program that can back up your files to **many different
storage types**, including self-hosted and online services. **Securely**, with use
of cryptography in every parts of the process. **Verifiability**, enabling you to
make sure that your files can be restored when needed.
![curios-manager backup](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_main_backup.png?raw=true "curios-manager backup")
![curios-manager backup menu](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_now.png?raw=true "curios-manager backup menu")
## Setup a Repository

## Backing Up

The `Backup > Backup now` menu will backing up your HOME directory `/home/<username>`
content including hidden directories. The root partition `/` and its content
will not be backed up in order to save space on your backups repository. In case
of catastrophic failure it will be easier to re-install your system from fresh
(See our [installation guide](getting-started.md)) and then restore your home directory.

Content of a backup at a specific point in time is called a "snapshot".

## Restoring from a Repository

## Repository Stats

**Previous**: [First Steps](first-steps.md).

**Back**: [index](index.md)
