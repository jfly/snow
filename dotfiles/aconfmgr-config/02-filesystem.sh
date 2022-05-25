CopyFile /etc/fstab
IgnorePath '/lost+found'

CreateLink /etc/systemd/system/multi-user.target.wants/remote-fs.target /usr/lib/systemd/system/remote-fs.target

### Fuse
AddPackage sshfs # FUSE client based on the SSH File Transfer Protocol
# Allow non-root users to specify the 'allow_other' or 'allow_root'
# mount options.
f="$(GetPackageOriginalFile fuse-common /etc/fuse.conf)"
sed -i 's/#user_allow_other/user_allow_other/' "$f"

### NFS
AddPackage libnfs # client library for accessing NFS shares
AddPackage nfs-utils # Support programs for Network File Systems
IgnorePath '/var/lib/rpcbind' # nfs-utils depends on rpcbind, which is intent upon creating this file.
IgnorePath '/var/lib/gssproxy/default.sock' # nfs-utils depends on gssproxy, which is intent upon creating this file.
IgnorePath /var/lib/nfs/state

### NTFS
AddPackage ntfs-3g # NTFS filesystem driver and utilities

### Recovery
AddPackage ext4magic # Recover deleted or overwritten files on ext3 and ext4 filesystems
