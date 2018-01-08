---
layout: post
title: "Alternatives to Truecrypt on Linux"
---

Since Truecrypt has mysteriously shutdown, here are a few alternative encryption tools for Linux.

#### dm-crypt (cryptsetup)

dm-crypt(cryptsetup) is an alternative to Truecrypt for creating encrypted containers. Although dm-crypt doesn't come with a GUI like Truecrypt does, the following are some very simple steps to help you create your own LUKS encrypted container on Linux.

Download and install the [latest version of cryptsetup](https://code.google.com/p/cryptsetup/wiki/Downloads?tm=2).

First, create a container of the required size (Later on, I will show you how to extend the size of this container when needed). Let us create a 512MB container below.

    $ dd if=/dev/urandom of=crypt_data bs=1M count=512

The name of the container we have created above is 'crypt_data'.

Next, find out a free loop device that you can use to loop mount the above file.

    # losetup -f

Suppose, the output of the above command is '/dev/loop0',

    # losetup /dev/loop0 /path/to/crypt_data

Now, create a LUKS container inside the file.

    # cryptsetup luksFormat /dev/loop0

You will be prompted to enter and verify the passphrase.

Now, for a quick sanity check of the process so far, run

    $ file /path/to/crypt_data

You should see output like "crypt_data: LUKS encrypted file ..."

Now, map the LUKS container

    # cryptsetup luksOpen /dev/loop0 raw_data

After this step, you should see the file '/dev/mapper/raw_data' created.

The LUKS container doesn't yet contain a file system. So let's go ahead and format the container as EXT4.

    # mkfs.ext4 /dev/mapper/raw_data

Now, go ahead and mount the file.

    $ mkdir /tmp/raw_data

    # mount /dev/mapper/raw_data /tmp/raw_data

Done !!!. Dump the files that you want to encrypt into /tmp/raw_data. When you are done, follow the reverse process as below.

Unmount the file.

    # umount /tmp/raw_data

Close the LUKS container

    # cryptsetup luksClose raw_data

Free the loop device.

    # losetup -d /dev/loop0

Done !!!. Your new encrypted container is crypt_data.

The steps above seem to be cumbersome, but they are only needed to create a new encrypted container. Using an existing LUKS encrypted container is as simple as below (assuming /dev/loop0 is a free loop device).

    # losetup /dev/loop0 /path/to/crypt_data

    # cryptsetup luksOpen /dev/loop0 raw_data

    # mount /dev/mapper/raw_data /tmp/raw_data

The raw data is now ready to be consumed/modified at /tmp/raw_data. When you are done,

    # umount /tmp/raw_data

    # cryptsetup luksClose raw_data

    # losetup -d /dev/loop0

That's it.

Now, what if the size of the container you created is no longer enough, and you want to extend it. Don't fret. It's easy. Most of the process being similar to the above.

Suppose, you want to extend the container's size by 128MB,

    $ dd if=/dev/urandom bs=1M count=128 | cat - >> /path/to/crypt_data

    # losetup /dev/loop0 /path/to/crypt_data

    # cryptsetup luksOpen /dev/loop0 raw_data

Now, resize the encrypted portion of the container.

    # cryptsetup resize raw_data

Next, resize the filesystem.

    # e2fsck -f /dev/mapper/raw_data

    # resize2fs /dev/mapper/raw_data

That's it. Resizing is complete. You can now mount and use the resized container like before.

    # mount /dev/mapper/raw_data /tmp/raw_data

#### tcplay : create and open truecrypt containers

While the latest versions of cryptsetup allow you to create and open truecrypt containers, there is another utility called tcplay which also allows you to do just that (without installing truecrypt, ofcourse). Again, many of the steps are same as the one's for dm-crypt(cryptsetup).

Install tcplay in ubuntu.

    # apt-get install tcplay

First, create a container of the required size (512MB in this case).

    $ dd if=/dev/urandom of=crypt_data bs=1M count=512

Find out a free loop device.

    # losetup -f

Suppose the output is '/dev/loop0',

    # losetup /dev/loop0 /path/to/crypt_data

Create the truecrypt container.

    # tcplay -c -d /dev/loop0

Map the container.

    # tcplay -m raw_data -d /dev/loop0

You should now see the file '/dev/mapper/raw_data'.

Create a filesystem inside the container.

    # mkfs.ext4 /dev/mapper/raw_data

Mount the filesystem.

    $ mkdir /tmp/raw_data

    # mount /dev/mapper/raw_data /tmp/raw_data

Ready !!!. Copy raw files into /tmp/raw_data. When you are done, follow the reverse process.

Unmount the filesystem.

    # umount /tmp/raw_data

Unmap the file.

    # dmsetup remove raw_data

Free the loop device.

    # losetup -d /dev/loop0

Ofcourse, the above steps are only to be followed to create a new truecrypt container. To use an existing truecrypt container (like the one already created with the now abandoned Truecrypt), the following steps suffice.

    # losetup /dev/loop0 /path/to/crypt_data

    # tcplay -m raw_data -d /dev/loop0

    # mount /dev/mapper/raw_data /tmp/raw_data

To finish, follow the reverse procedure.

    # umount /tmp/raw_data

    # dmsetup remove raw_data

    # losetup -d /dev/loop0

#### EncFS : userspace encryption

With Truecrypt, dm-crypt(cryptsetup) and tcplay you have to create a single file (container) and a filesystem within that to hold your encrypted files. EncFS works on the existing filesystem. Also, no root permissions required.

To create an encrypted directory 'crypt_data' with EncFS,

    $ mkdir /tmp/raw_data

    $ encfs /absolute/path/to/crypt_data /tmp/raw_data

NOTE: encfs requires you to specify absolute paths on the command line.

You will be prompted for a passphrase.

Now, you can copy the raw files (unencrypted) into /tmp/raw_data. When you are done,

    $ fusermount -u /tmp/raw_data

You should see the encrypted files inside 'crypt_data'.

That's very simple !!!.

#### BONUS : Using truecrypt and EncFS on Android

[Cryptonite](https://code.google.com/p/cryptonite/) is an android app (still in development) that allows you to easily mount (on Cyanogenmod), export, browse EncFS encrypted directories from the GUI. Truecrypt support is only via command line/terminal emulator (at the moment).
