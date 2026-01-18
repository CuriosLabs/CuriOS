# Backup Your Computer

One of the main goals of Curi*OS* is to get you up and running quickly. This includes
making it easy to manage your backups.

The Curi*OS* management tool, `curios-manager` (shortcut: Super+Return), includes
a `Backup` tool. This tool is powered by [restic](https://restic.net/), a fast
and secure program that can back up your files to **many different storage types**,
including self-hosted and online services. **Securely**, with use of cryptography
in every parts of the process. **Reliability**, enabling you to make sure that your
files can be restored when needed.
![curios-manager backup](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_main_backup.png?raw=true "curios-manager backup")

## Setup a Repository

The `Backup > Setup your backup` menu prepares a "repository". A repository is the
secure location (for example, a folder on your USB drive) where `restic` will store
your encrypted backups and the information needed to manage them.
![curios-manager repository setup](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_repo_config.png?raw=true "curios-manager repository setup")
Every repository type setup will require you to define a password.

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

For AWS S3 storage, you will need to provide your AWS access key, your AWS secret
key and the S3 bucket URL (including region), i.e: `s3.us-east-1.amazonaws.com/bucket_name`
To back up to AWS S3, you first need an Amazon Web Services account. Within your
AWS account, you must create an S3 bucket (which is like a root folder for
storage) and generate an "Access Key" and "Secret Key" for authentication.

- **AWS Access Key:** Your unique access key ID.
- **AWS Secret Key:** Your secret password for the access key.
- **S3 Bucket URL:** The address of your bucket, including its region (e.g., `s3.us-east-1.amazonaws.com/my-backup-bucket`).

Please consult the official AWS documentation for instructions on how to create
a bucket and generate security credentials. Once you have them, you can enter
them here.
You will also be prompted to set a repository password. The repository will then
be initialized, you can now use the `Backup now` menu.

### S3-compatible server (MinIO, RustFS...)

For S3-compatible storage that is **not** Amazon AWS, you must provide an access
key and the secret key of your S3 bucket. You must also provide the complete URL
(IP/host name and port number included) of the bucket. For example on a **RustFS**
server running on a NAS on your local network, the URL could look like this:
`http://192.168.1.231:9000/bucket_name`.
You will also be prompted to set a repository password. The repository will then
be initialized, you can now use the `Backup now` menu.

## Backing Up

![curios-manager backup menu](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_now.png?raw=true "curios-manager backup menu")

The `Backup > Backup now` menu will back up your HOME directory `/home/<username>`
content including hidden directories. The root partition `/` and its content
will not be backed up in order to save space on your backups repository. In case
of catastrophic failure it will be easier to re-install your system from fresh
(See our [installation guide](getting-started.md)) and then restore your home directory.

Content of a backup at a specific point in time is called a "snapshot".

## Restoring from a Repository

To restore your home directory use the `Backup > Restore from backup` menu. You
will be presented with a list of available snapshots:
![curios-manager backup restore menu](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_restore.png?raw=true "curios-manager backup restore menu")
Choose one and let the tool do his work. Already existing files will be overwritten.
New files in your HOME directory will **not** be deleted.

## Repository Stats

To check your repository status and list the available snapshots, go to
`Backup > Backup stats`.
![curios-manager backup stats](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_backup_snapshots.png?raw=true "curios-manager backup stats")

## Notes

Configuration details like the repository URL and S3 access key are stored in a
hidden file named `.env` located in your home directory (`~/`).
S3 secret key and repository password are safely stored with `secret-tool`.

## Protection against Ransomware

The backup tool is able to manage (add/remove) the snapshots even the remotely
stored snapshots on your S3 server. So, an attacker/ransomware might be able to
**delete** your backup snapshots.
To protect your backups against ransomware attacks, you can configure your S3 storage
(AWS or compatible servers like RustFS) to use **Object Lock** with **Compliance
Mode**. This ensures that your backup files cannot be deleted or overwritten by
anyone, including the system administrator or a ransomware script, for a
specified period (e.g., 7 days).

### Prerequisites

- **Versioning**: Must be enabled (automatically enabled with Object Lock).
- **Object Lock**: Must be enabled at bucket creation.

### Configuration - AWS CLI

You can use the standard `aws` CLI tool to configure this on AWS or any S3-compatible
server.

1. **Create a Bucket with Object Lock Enabled**

    *Note: Object Lock must usually be enabled when creating the bucket.*

    ```bash
    # Replace <bucket-name> and <url> with your details
    # For AWS, omit --endpoint-url
    aws s3api create-bucket \
        --bucket <bucket-name> \
        --object-lock-enabled-for-bucket \
        --endpoint-url <your-s3-server-url>
    ```

2. **Set Default Retention Policy (7 Days Compliance)**

    This ensures every new backup file uploaded gets a 7-day lock including
    **Compliance Mode**.
    In Compliance Mode, no one can delete the file until the lock expires.

    ```bash
    aws s3api put-object-lock-configuration \
        --bucket <bucket-name> \
        --object-lock-configuration '{
            "ObjectLockEnabled": "Enabled",
            "Rule": {
                "DefaultRetention": {
                    "Mode": "COMPLIANCE",
                    "Days": 7
                }
            }
        }' \
        --endpoint-url <your-s3-server-url>
    ```

Once configured, simply use this bucket when setting up your backup repository in
Curi*OS*.

### Configuration - RustFS

Here is a screenshot of a RustFS bucket configured with **Object Lock** and
**Compliance Mode**:
![RustFS in Compliance mode](https://github.com/CuriosLabs/CuriOS/blob/master/img/rustfs_ransomware_protection_mode.png?raw=true "RustFS protection mode")

Once configured, simply use this bucket when setting up your backup repository in
Curi*OS*.

---
**Next**: [Work with AI tools](ai-tools.md).

**Previous**: [First Steps](first-steps.md).

**Back**: [index](index.md)
