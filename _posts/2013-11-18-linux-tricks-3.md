---
layout: post
title: "Linux command line tools and tricks - Part 3"
---

Here is another sequel to my [Linux command line tools and tricks - Part 1]({% post_url 2012-09-19-linux-tricks %}) and [Linux command line tools and tricks - Part 2]({% post_url 2012-10-01-linux-tricks-2 %}) where I collect some of the most interesting command line tools and tricks from around the web. So, let's get started.

#### Using webcam as a mirror

    $ sudo apt-get install mplayer
    $ mplayer -vf mirror -v tv:// -tv device=/dev/video0:driver=v4l2

#### Download pronunciation of an English word as mp3 file

    $ word="apple"; wget http://ssl.gstatic.com/dictionary/static/sounds/de/0/$word.mp3

#### Remove duplicate files in a directory(based on md5sum)

    $ dir="/path/to/directory"  # set the directory path here
    $ diff \
      <(find ${dir} -type f -print0 | xargs -0 -n1 md5sum | sort | uniq -w32) \
      <(find ${dir} -type f -print0 | xargs -0 -n1 md5sum | sort) | \
      awk -F'  ' '/>/ {print $2}' | tr '\n' '\000' | xargs -I{} -0 -n1 rm -vrf {}
    $ find ${dir} -type d -empty -delete  # (bonus)delete any empty sub-directories

Command no. 2 above looks very scary. Fact is, it is very easy to understand.

The first "find" command,

    <(find ${dir} -type f -print0 | xargs -0 -n1 md5sum | sort | uniq -w32) \

basically finds out all the unique md5sums in the directory which is also the files that we would like to keep in the final output directory. Our main aim is to remove all the files that are not in the output of the above find command because they are duplicates of files that are already in the output of the above find command.

The second "find" command,

    <(find ${dir} -type f -print0 | xargs -0 -n1 md5sum | sort) | \

basically lists all files in the directory sorted by their md5sums.

So, if we subtract the output of the first find command from the output of the second find command, we are left with a list of files that we should remove from the directory to be left with no duplicate files in the end. And that is precisely what the rest of the command is doing.

    diff <(...) <(...)

This is basically subtracting the output of the first find command from the output of the second find command. The special notation used here, <(...) is what is known as "process substitution" which basically means that we are treating the output of a process/command as a file, which in this case, we are feeding to the diff command. The output of the above diff command is the list of files we need to remove, so we pipe the output of the diff command to "rm" via xargs after modifying the line endings to be null characters instead of newline using the "tr" command.

Couldn't be simpler !!!. Ofcourse, this command is perfect candidate for a tiny [shell script which you can find here](http://pastebin.com/raw.php?i=G6qnBXkB).

#### Deleting trailing whitespaces in a file

    $ sed -ri.bak 's/ *$//' <filename>

This is basically telling sed to replace any number of consecutive spaces at the end of each line in given file with nothing. The file is edited in-place, but a backup file is created in the same directory with the suffix .bak

#### ps command in tree format

    $ ps -auxwf

Clearly shows parent child relationship.

#### Check internet usage this session

To show the wireless internet usage this session(in MB), run the following command

    $ echo "scale=1; `cat /sys/class/net/wlan0/statistics/rx_bytes`/1000000" | bc

To show the wired internet usage this session(in MB), run the following command

    $ echo "scale=1; `cat /sys/class/net/eth0/statistics/rx_bytes`/1000000" | bc

#### Making Firefox faster by caching in RAM instead of on disk

__/dev/shm__ is of type tempfs. Its size is usually half of the available RAM. It is mapped to virtual memory i.e, RAM. Any file you create there will not be created on disk. So it is lost on reboot. To make Firefox faster, we simply tell Firefox to put its cache into /dev/shm. This also protects privacy since cache is not written to disk.

Type the URL "__about:config__" in your Firefox URL bar.

Search for "__browser.cache.disk__"

Add a new "__string__" entry: "__browser.cache.disk.parent_directory__" with the value "__/dev/shm__"

Make sure __browser.cache.disk.enable__ is True

That's it. Now, restart Firefox, and you should see a cache file created in /dev/shm.

#### Setting wallpaper via command line

    $ sudo apt-get install feh
    $ feh --bg-fill <path to image>

Can be used with startup scripts or login scripts. Especially useful in tiling window managers like [DWM]({% post_url 2013-09-28-dwm %}).

#### Faster sshfs

sshfs can be used to mount a remote directory locally using ssh, and hence comes with the security of ssh as well as the annoying delays in sync :P. So, if you are on an already secure connection, you can speed up sshfs by removing one layer of encryption using socat as below

On the remote server,

    $ sudo apt-get install socat
    $ socat TCP4-LISTEN:7777 EXEC:/usr/lib/sftp-server

On local machine,

    $ sshfs -o directport=7777 remote_hostname:/remote/dir /local/dir

Notice we don't specify a username for the remote machine in the above command.

#### Setting up a static IP via command line

Especially useful when you are running lightweight window managers like [DWM]({% post_url 2013-09-28-dwm %}) and do not have a tray applet to control network connections.

    $ sudo ifconfig eth0 10.0.0.1 netmask 255.255.255.0 up

#### Scanning for networks via command line

    $ sudo iwlist wlan0 scan   # scan for wireless networks
    $ sudo iwlist eth0 scan    # scan for wired networks
    $ sudo iwconfig wlan0 essid "actual essid" # select network

Again, this is useful if you do not have or do not want a tray applet to control networks (like nm-applet).

#### Creating a file that does not grow beyond a set size

Suppose you want to create a log file whose max size should not become more that 100 MB.

    $ dd if=/dev/zero of=./100mb.img bs=1M count=100  # create a 100 MB file
    $ mkfs.ext2 -t ext2 100mb.img  # create an ext2 filesystem
    $ mkdir /tmp/100mb
    $ sudo mount -t ext2 100mb.img /tmp/100mb/ # mount the filesystem
    $ touch /tmp/100mb/logfile

Now, logfile cannot grow beyond 100 MB. However, note that the fixed size you have in mind must be enough to create a filesystem in it.

#### Mounting an image file

You can create a complete backup(mirror image) of an external memory device like so.

    $ sudo dd if=/dev/sdX of=mem_bkup.img

and the reverse process will restore the backup onto your external memory device.

    $ sudo dd if=mem_bkup.img of=/dev/sdX

But what if you wanted to access the contents within mem\_bkup.img without restoring it back onto your external memory device ?
The solution is to mount mem_bkup.img. But this process is not straightforward.

First, run the following command.

    $ sudo fdisk -l mem_bkup.img

Note down the sector size (search for a line which has something like "units = sectors of 1*512 = 512 bytes"). So, the sector size in this case is 512 bytes. Also note down the start sector of the partition that you would like to mount. Let us suppose the start sector of the first partition is 'x'.

Multiply the start sector(x) and the sector size(512) to get the offset(y).

y = x * 512

Now, to mount partition 1, run the command

    $ sudo mount -o loop,offset=y mem_bkup.img <mount_point>

#### Multiple commands in the background, Important distinction

    $ (command1; command2; command3) &

Here, commands are executed sequentially but all of them are executed in the background.

    $ (command1 & command2) &

Here, command1 is started in the background followed immediately by command2 i.e, command2 does not wait for command1 to complete. Both the commands are still executed in the background. Note that & also performs the function of ; in that it seperates the two commands. Here, $! returns the pid of the process group and not the pid of either command1 or command2.

    $ (command1; command2) &
    $ wait $!

This is how you wait for the group of background tasks to complete in a script.

#### Disconnecting a process from the terminal

Suppose you start a program like say "vlc" from the terminal, it opens up an new window and you no longer need the terminal to be open. But if you close the terminal, vlc is also terminated, because it is attached to the terminal. To disconnect the two, just do the following.

Press Ctrl-Z to suspend vlc.

Then type the command "__$ jobs__" to note down the job id of the suspended process. Then run the following command to disconnect vlc from the terminal.

    $ bg  # to start running vlc in background
    $ disown %<job_id>  # disconnect vlc from terminal

NOTE: only background processes can be disowned(or disconnected).

#### Cron vs. Anacron

Cron does not run crontab jobs if your computer is powered down and hence is only suitable for servers. For desktop computers however, you have an alternative namely "Anacron" which, if your computer is powered off will run any pending tasks on next boot. To use Anacron on Ubuntu, just place your shell scripts in either __/etc/cron.daily__(for daily tasks) or __/etc/cron.weekly__(for weekly tasks) or __/etc/cron.monthly__(for monthly tasks).

You could also add your entry into __/etc/anacrontab__. The format of the entry is as follows.

__1st field - period__  = time period between execution of jobs

__2nd field - delay__   = delay after booting at which any pending jobs should run

__3rd field - job id__  = any unique string to identify this particular anacron job

__4th field - command__ = command to run

#### Limiting CPU usage of a currently running process

    $ cpulimit -p <pid> -l <percentage_of_cpu_to_use> -b

-b option tells cpulimit to run in the background.

#### Quickly listing pid of a process along with process name

The usual command to run for this purpose is

    $ ps ax | grep <process_name>

There is however a simpler alternative

    $ pgrep -l <process_name>

#### Selectively turning off processor cores

    $ echo 0 > /sys/devices/system/cpu/cpu1/online  # turn off processor core 1

If you have a quad core computer, you can turn off cpu1, cpu2, cpu3 while cpu0 continues to work.

#### Making sudo not prompt for password

    $ sudo visudo  # opens /etc/sudoers in vi editor

Then, append the following line at the end of the file and save.

    username ALL=NOPASSWD: ALL

#### Mounting an archive like a filesystem

    $ archivemount /path/to/archive /mount/point

Now you can perform any read/write operation on the contents of the archive. When you are done, just unmount.

    $ umount /mount/point

Any changes you made on the contents of the archive are automatically synced to the archive when you unmount.
