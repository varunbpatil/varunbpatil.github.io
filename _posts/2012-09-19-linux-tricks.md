---
layout: post
title: "Linux command line tools and tricks for Linux geeks"
---

I have gathered some of the best and most widely used linux command line tools and tricks from all over the web and from my recent Linux System Programming training from Cisco conducted by one of the best teachers I have ever had in quite some time, [Mr. Chandrashekar Babu](http://chandrashekar.info/). I use all or most of these commands at work and home frequently. Hope you find it useful and most importantly mind-boggling, fun and interesting, something that will keep you occupied over a long and boring weekend:)

#### A faster alternative to the "find" command

There is a command by the name "locate" in Linux that is much faster the super-useful "find" command, the reason being that "locate" command indexes files before-hand. The disadvantage is that files keep on getting added or removed making "locate" unreliable if the indexing is not done regularly.

* First index the files on your computer

		$ sudo updatedb

* Then, search for a file

		$ locate -ie <filename>


#### Downloading files using "wget"

"wget" is an extremely powerful command line tool to download files off the internet.

* Download file from a single url with

		$ wget <url>

* Download only a certain type of files from an URL(say mp3's)

		$ wget -r -A.mp3 <url>

* You can as well store multiple url's to download from in a file(one URL in each line) and give the filename as input to wget

		$ wget -i <filename>

* The best feature is that you can resume interrupted downloads by simply using the switch -c with any wget command above        

		$ wget -c <url>

* You can also mirror an entire website for offline viewing using the following command

		$ wget -rpk <url>


#### An alternative to "wget" -- "curl"

"curl" is another powerful tool that works very much similar to "wget". This package doesn't come by default. You will have to install it.

* Download file from a single url with

		$ curl <url>

* Download from multiple URL's with

		$ curl -O <URL1> -O <URL2>

* Resume an interrupted download

		$ curl -C <url>

* And lastly, find the definition of a word with
    
		$ curl dict://dict.org/d:<word_to_search_for>


#### Observing the differences between two files in a very colorful way

We all know the basic diff command to observe the difference between two files, and we also know how hard it is to interpret the result of running the command. This is where vimdiff comes in. It displays the two files side by side in two vim tabs. The obvious disadvantage is that you should know a few commands to navigate around vim. Most importantly, the output is colored, with different colors meaning different things as below:

* Same lines in both files do not have a background color.

* If a line is missing in one file, it is shown as - - - with a blue background.

* Partial line matches are shown in red background.


#### Splitting, compressing and encrypting files before transfering to others

We all at some point have had to deal with transferring large files across computers. The obvious method is to compress it before sending. For extremely large files we can create a multi-part archive using the following commands.

* First of all, create a zip archive using

		$ zip -re <compressed_file_name.zip> <file1> <dir1>

  The -r switch allows you to add directories to the archive.

  The -e switch allows encryption, where the program asks you to enter a passphrase that needs to be entered by the recepient in order to extract the archive.

* Now split the archive into multiple parts with

		$ split --bytes=1K <compressed_file_name.zip> <PREFIX>

  Here, - -bytes=1K specifies that we want parts that are at most 1K bytes in size.

  PREFIX is any user string... For example, if the PREFIX is given as "split_", then the files that are created will be named split_aa, split_ab, split_ac, etc.

* On the receiving side, you can extract the multipart zip archive with

		$ cat split_* > my_compressed_file.zip

  Where, "split_" was the PREFIX that the person who created the archive specified.

  Then, extract the whole zip file as follows.

		$ unzip my_compressed_file.zip


#### Encrypting a single file using "openssl" for secure local storage

* Encrypt a particular input file with

		$ openssl enc -aes-256-cbc -e -in <plain_text_file_name> -out <encrypted_file_name>

  You will be prompted to enter your password.

  Please also do remember to use the same encryption algorithm which in this case is aes-256-cbc( very secure ), when you want to decrypt the file, although there are several other encryption algorithms that openssl provides. i.e, you have to use the same crypto algorithm for both encryption and decryption of a particular file.

  The -e switch stands for encryption.

* To decrypt a file which was encrypted using openssl use

		$ openssl enc -aes-256-cbc -d -in <encrypted_file_name> -out <plain_text_file_name>

  The -d switch stands for decryption.        


#### Performing spell check on a file from command line using "ispell"

The program used to perform a very basic spell check from the command line is called "ispell".

* Run spell check on a given file with

		$ ispell <file_name>

  Now, you have several actions that you can take on misspelled words in the file

  - Type the number 'n' to replace the misspelled word with the word against that number.

  - Type 'R' to replace the misspelled word with a word that you wish to type in (i.e, which is not there in the numbered list).

  - Press spacebar to ignore that misspelled word just once.

  - Press 'A' to ignore that misspelled word in this entire ispell session.

  - press 'Q' to quit the program.


#### Finding out the public IP of a website

This is useful in cases where your DNS server is unable to resolve the website name into its public IP. This could happen because your ISP which also provides you with the DNS service has blocked that website. I used this technique recently when all Indian ISP's where asked to block peer-to-peer sharing sites by the Indian Government. Most of these ISP's simply configure their DNS server's so as to not resolve the website names of such websites into public IP's and thus make them inaccesible, but you can always access such sites using their IP addresses. You could have obtained the IP address of such a site before hand using the following command

	$ host <site_url>

Or, you could even possibly change the DNS server settings manually by setting it to the address of DNS servers provided by google which is 8.8.8.8. Since Google does not block these file sharing websites, you will be able to get the domain resolved successfully, unless your ISP is really intelligent and is blocking all traffic to such sites.        


#### How to put a CPU to 100% usage

This is one of my favorite command line tricks. It allows you to put the CPU to 100% usage. This way you can see how long your laptop battery lasts in the worst case, under heavy load.

	$ cat /dev/urandom > /dev/null

There is something very interesting going on here. /dev/urandom is a file which continuously generated random data. And keep in mind this is not just pseudo random data, it is pure random data, because the way /dev/urandom gets these input is from interrupts in the system like mouse movements, key presses on the keyboard, signals sent to the display, packets arriving over the network and a whole lot of other places which are truly unpredictable by any means.

This capability gives rise to an other super-cool feature. You can use this file to generate random passwords that are severely hard to crack as follows:

	$ egrep -ioam1 '[a-zA-Z0-9!@#$%^&*()_+-=]{8}' /dev/urandom

This command generates a random password of 8 characters length. Ofcourse, you can change the number 8 in the regular expression to a larger value to generate longer passwords.        

One thing you will notice that in dual core and quad core CPU's, only one of the cores is put to 100% usage and the load is automatically balanced between the available cores. So, if you want to put all the cores of your CPU to 100% usage, make sure you run the first command as many times as the number of cores, by launching multiple terminals simultaneously.

You can verify the 100% usage of the CPU by using the "$ top" command which will display all the processes that are running and the amount of resources that they are using. You should see cat command at the top almost all the time and also see 100% cpu usage when you run the command.

But, you should also notice that, even when you put all cores to 100% usage by running the command multiple times simultaneously, you will experience very little or no lag in mouse movement or keypress delay... This is the beauty of Linux, because Linux gives super-high priority to such hardware interrupts. If you were to do something similar on a windows systems, you had better be ready to face robotic mouse and window movements.


#### Another way to put your CPU to 100% usage

Here is another way to use Linux's super high precision calculator tool "bc" to put your CPU to 100% usage. All you need to do is run the command

	$ echo "scale=10000;4*a(1)" | bc -l -q

All this command is doing is computing the value of PI to 10000 decimal places and dumping it to the standard output. If you don't want your standard output clobbered with numbers you won't be using anytime in your life, you can redirect the standard output as follows

	$ echo "scale=10000;4*a(1)" | bc -l -q > /dev/null

This command gives rise to another very interesting command. You can compare the speeds of your computer and a friends computer and then boast that yours is faster or get a new computer after being humiliated, by running the same command as above, only this time, with the prefix time.

	$ time echo "scale=10000;4*a(1)" | bc -l -q > /dev/null

You can compare how many seconds (CPU time) the two computers took to calculate the value of PI to 10000 decimal places, which I can promise you is a heck of a lot of time even on my quad core second generation i5 laptop.        


#### Writing an ISO image file to a CDROM from the command line

We usually download .iso images of popular linux distros for installation or as live media, but end up using a GUI cd burning tool to create a bootable cdrom. But, if your feeling a bit geeky, you could try doing so from the command line with 

	$ cdrecord -v speed=0 driveopts=burnfree -eject dev=1,0,0 <src_iso_file>

speed=0 tells the program to write the disk at the lowest possible drive speed, which is good considering the shitty quality of cdroms that we get in India. But, if you are in a hurry, you can try speed=1 or speed=2. Keep in mind that these are relative speeds.        

-eject switch tells the program to eject the cdrom after the operation is complete.

Now, the most important part... specifying the device id. It is absolutely important that you specify the device id of your cd rom drive correctly or you may end up writing the iso to some other place on disk and corrupting your entire hard disk. To find out the device id of your cd-rom drive, just run this command prior to running the first command:

	$ cdrecord -scanbus

Your cd-roms device id should look something like 1,0,0 but need not be exactly the same on your system.        

Also, note that, you cannot create a bootable dvd disk using this command for distros like openSUSE or Fedora or Ubuntu or Slackware which come as dvd iso's. But, do not be disheartened, there is another more simpler command to burn a bootable dvd

	$ growisofs -dvd-compat -speed=0 -Z /dev/dvd=myfile.iso

Here, /dev/dvd is the device file that represents your dvd rom. It is quite likely to be the same on your system as well.

Donot use growisofs to burn a cdrom. The beauty of linux is that a single command does a single operation and does it well. So, we will stick to it.


#### Creating a bootable USB disk

Now, that you know how to create a bootable cdrom, you have to admit, it is a bit of a pain to buy and burn a cdrom every time you want to try a new linux distro and then wait forever until the OS is installed from the super-slow cd rom. The solution is to create a bootable usb disk and the procedure to create one, assuming you already have a partitioned and formatted pendrive, couldn't have been more easier. All you have to do is

	$ dd if=mylinux.iso of=/dev/sdb bs=20M

Here if stands for input file, of for output file and bs for block-size.        

After this, make sure you flush the write buffers to disk by issuing the command

	$ sync

Here /dev/sdb is the device file that represents your usb pendrive. It may be different on your system. But it is always something like sdb or sdc. To find out exactly, plug in your usb disk and then run '$ sudo fdisk -l'. You should be able to see a partition table for your pendrive at the bottom and also atleast one partition which would be something like sdb1 or sdc1. However, if you haven't formatted your pendrive before and want to learn how to do it from the command line, then read the next section.

If you haven't already realized, you can do amazing things with the dd command. You can create a backup of an entire hard disk partition by

	$ dd if=/dev/sda1 of=/dev/sda2

This command copied the entire partition sda1 on your hard disk to partition sda2. You can restore the partition simply by interchanging the if and of attributes. However, exercise extreme caution while using the dd command as you can completely mess up your hard drive and lose all data if you specify the if and of attributes wrongly.        


#### Partitioning and formatting a USB key

I have to admit partitioning and formatting a USB key from the command line is not as easy as right clicking and selecting format. But, I also have to tell you that the command line tool called "fdisk" provides unprecedented control over the process, and shouldn't be very difficult to get a hang of. First of all, plug in your pendrive and run

	$ sudo fdisk -l

Note down the device file for your pendrive. It should be something like /dev/sdb or /dev/sdc. Assuming yours is /dev/sdb, run

	$ sudo fdisk /dev/sdb

You are now into the fdisk program. You can press 'm' to see a list of all possible commands allowed.        

Supposing you already have a partition on your pendrive you can delete them by pressing 'd' and then entering the number of the partition.

If you do not have a partition, you have to create one. To create a new partition, simply press 'n'. You will be asked whether you want to create a primary or extended partition. Press 'p' to create a primary partition. You now have to tell, what type of file system you would like to have on the new partition. To do that, press 't' and then select 'c' for a FAT file system. You will be asked whether you want to create a primary or extended partition. Press 'p' to create a primary partition.

You now have to tell, what type of file system you would like to have on the new partition. To do that, press 't' and then select 'c' for a FAT file system. You will be asked whether you want to create a primary or extended partition. Press 'p' to create a primary partition. You now have to tell, what type of file system you would like to have on the new partition. To do that, press 't' and then select 'c' for a FAT file system. You will be asked whether you want to create a primary or extended partition. Press 'p' to create a primary partition. You now have to tell, what type of file system you would like to have on the new partition. To do that, press 't' and then enter 'c' for a FAT file system. There are several other filesystems supported. You can see a list of all those by pressing 'l'.

Note that fdisk will not write the partition table to disk until you explicitly tell it to do so. So, go ahead and enter 'w' to write the partition table to disk. You can quit the program without saving any changes to disk by pressing 'q' before you press 'w'. At this point, you have created a raw partition with no filesystem on it. As such, the pendrive is useless. Run

	$ sudo eject /dev/sdb

Now, unplug the drive and plug it in again. If your linux box supports automounting, you should get an error saying unable to read the disk. This is simply because you have not created any filesystem on the disk. Put in simple words, the disk is not formatted yet. So go ahead and eject the drive using the same command as above.

Now, format the pendrive as FAT using the command

	$ sudo mkfs.vfat /dev/sdb1

Note that the above command takes the specific partition to be formatted like sdb1 or sdc1, so different partitions on the disk may be formatted as different file systems. That's it, you are now ready to create your bootable USB disk using the commands in the previous section.


#### Ripping a CD or DVD for local storage

Sometimes, you need to return a dvd to a friend and you do not have enough time to burn a copy of the dvd or donot have an extra dvd drive that can do the job. Moreover, your USB drive read is much slower that read from disk. So, why not make an exact copy of the entire cd or dvd to your disk which you can view anytime later or burn it to a dvd later. All you have to do is enter the following command

	$ dd if=/dev/dvd of=myfile.iso bs=2048

Here, if stands for input file. As you already know, every device is a file in Linux. Hence, the dvd drive is represented by /dev/dvd and the cdrom drive most likely by /dev/cdrom. Use the one appropriate for your case.        

As you guessed, of stands for output file which is an exact mirror image of the cd or dvd which you can write to another cd or dvd anytime using the commands in the previous section.

Now, that you have an iso file on your disk, you cannot simply view it anytime you want. To access the contents of the iso file, you will need to mount it at a particular mount point. So, go ahead and create a mount point 

	$ sudo mkdir /tmp/myfiles
	$ sudo mount -o ro,loop -t iso9660 myfile.iso /tmp/myfiles
	$ cd /tmp/myfiles

Thats it... you can now access the files as though you were accessing them from the dvd or cd only much faster. You have to keep in mind that you will not be able to write anything directly into /tmp/myfiles just as you would simply not be able to write into a dvd or cd. Thats the reason, the iso file is mounted as read-only.
        

#### Hiding a file or directory within an image

This is one severely cool trick which allows you to hide any file or directory within a harmless looking image. When you click on such a file, all you see is the image on your default image viewer. The image is not altered in any way. What you don't see is the file you have hidden within the image.... Here is precisely how to do it.

* First you will need a harmless looking .png or .jpg image file... Feel free to download your favorite one from google images.

* Now, the file or directory you wish to hide has to be compressed into a zip archive.

		$ zip -r <compressed.zip> <file1> <dir1>

* Now, cat the image you downloaded with the compressed file you created above
    
		$ cat image.png compressed.zip > secret.png

  NOTE: do not change the ordering of the image and the compressed file. The image always has to always come first in the cat command.        

* Now, remove the files and directories you wanted to hide and also the compressed.zip file using the rm command.

Thats it... You now have a file by the name "secret.png" which if you open, will display the harmless looking image file. Nobody suspects that the image is hiding something sinister(unless ofcourse they are intelligent enough to do a ls -l and see the size of the image file)

Now, all you have to do to get back your secret files and directories is
    
	$ unzip secret.png

Don't worry if you get some weird warnings or errors when you run the command regarding some invalid content in the header. Thats the whole point you see !!! When we catted the image file at the start of the zip file, we inadvertently modified the header of secret.png, and hence the warnings and errors. Nonetheless, you should now see the compressed.zip file in the directory. Just extract its secret contents with

	$ unzip compressed.zip
        

#### How to completely paralyze any Linux system which is using the bash shell        

Most linux distros that you use today come preloaded with the bash shell as default, so you wouldn't need to worry much to completely wreck your college linux server box or your best friends laptop in a matter of seconds. Just type in the following command, sit back and relax while the system starts to choke itself.

	$ :(){ :|:& };:

This is one of the most cryptic commands you have probably ever seen and also one of the shortest ones considering the amount of carnage you are about to cause as soon as you press the enter key. But the command is really very simple to understand. So, here is the breakup of the command.

This command is creating a bash function by the name ':' , hence you see :()

The body of this bash function is within the curly braces { }

What we are doing within this function is calling the same function ':' again. Kinda like recursion. And this function call is running in the background. Thats the reason you see the ampersand (&) at the end. In short, this function is telling bash to keep on forking an innumerable number of child processes. But, this is just the function definition, no harm here. The actual fun starts after the semicolon(;) which as you know acts as a seperator between two linux commands. The first command was merely writing the function definition. But the ':' you see after the semicolon is the command that is actually calling the function ':'.


All hell is let loose on the system. Bash starts to fork child processes that grow exponentially. Within a matter of seconds, you will have millions of child processes on your system, and every system can only take so much. The system is in effect, choking itself, and in seconds, your system is completely lifeless.... mouse doesn't work, keypresses don't do anything... So you cannot even press Ctrl+C to stop the system from killing itself. All you can do at this point, is to hold down the power button for some time to hard-reboot the system. And the really funny and interesting about this command is that, the more processing power your system has, the faster it will kill-itself because it is creating child processes at a much faster rate that a slow, dim-witted computer where you might even have time to press Ctrl+C after you have realized your mistake. Now, you don't call this command the "bash fork bomb" for no reason.

This goes without saying that "With great power comes great responsibility" :P


#### Some random, super-cool command line fu

* A stopwatch on the terminal

		$ time read

  This will start a stopwatch on your terminal. Simply press Ctrl+D to stop the timer and see the elapsed time.        

* How to know how many CPU cores are there on the computer ?

		$ sudo cat /proc/cpuinfo | grep processor | wc -l

  Infact, you can see a lot of info about each of these cores with the command
    
		$ sudo cat /proc/cpuinfo

* Finding the name of the linux distro running on the computer

		$ sudo cat /etc/issue

* How to know whether you have a 32bit or 64bit OS running on your computer ?

		$ sudo getconf LONG_BIT

* Killing a process that has locked a particular file, when you know the file name that is locked, but don't know which process is locking it.

		$ sudo fuser -k <file_name>

  This is useful when you get an error saying this particular file is locked by another process. This happens many times when you are updating your linux installation and the process got terminated leaving the /var/lib/dpkg/cache file locked. You get an error when you try to re-start the system update again. You can use this command in such situations.

* Easiest way to re-run the previous command with superuser permissions

		$ sudo !!

This saves you from pressing up arrow and then home key and then typing sudo.        

* Easily doing a reverse search for a command you entered previously. In bash, simply press Ctrl+R and then start typing the part of the comamnd you remember. Hit enter when you find the command you were looking for. This command gives rise to another neat trick. Suppose you use a lengthy command very frequently during the session. The first time you run the long command, run it as follows

		$ <command> #my_label

  The next time you want to run the same command, all you have to do is press Ctrl+R to start reverse-search and then enter "my_label" followed by enter key... How cool is that !!!.        

* How to get vi stlye editing commands working in bash

		$ echo "set editing-mode vi" > ~/.inputrc

* some super useful bash command editing keys

    - Press Ctrl+W to erase a single word before the current cursor position.

    - Press Ctrl+U to erase the entire line before the current cursor position.

    - Press Ctrl+K to erase the entire line after the current cursor position.

    - Press Ctrl+A to go to the beginning of the command.

    - Press Ctrl+E to go the the end of the command.

* How to display a popup notification when a command completes ( requires libnotify to be installed )

		$ wget <URL> ; notify-send "wget" "your download is complete"

  The above command displays a popup notification once wget finishes downloading the file. wget can be replaced by any command actually. The first argument to the notify-send command is the "title" and the second argument is the "body" of the popup notification. You can change it to whatever you like.

* Turning of the monitor to save power when there is no hardware key available to do so(say, on a laptop)

		$ xset dpms force off

* How to copy the output of any command directly to the system clipboard

		$ <command> | xsel --clipboard

* How to open an file from the command line using the default application for that file

		$ xdg-open <file_name>

* How to save the output of any command as an image file

		$ <command> | convert label:@- <image_name.png>

* How to convert an entire man page into pdf format for later viewing        

		$ man -t <command_name> | ps2pdf - <command_name.pdf>

* Installing the same packages and software you already have on a fully configured linux system, on another freshly installed linux system in a single command

  First, run this command on the fully configured linux box

		$ sudo dpkg --get-selections > my_linux_software

  Then, transfer this file to the freshly installed linux box an enter the following command        

		$ cat may_linux_software|sudo dpkg --set-selections && sudo dselect install

  Ofcourse, you will need network connection on your freshly installed linux box, but you will be saved from laboriously selecting all your favorite software from the software management tool.        

* Deleting a particular line number from a given file without opening it in any editor

		$ sed -i 8d <file_name>

  This command deletes the 8th line from the specified file.

* Running a command at a specified time

		$ echo "command you want to run | at 01:00

  Note that the time is in 24hr format.        

* How to create a pencil sketch out of any image file  

		$ convert <input_image> -colorspace gray \( +clone -blur 0x2 \) +swap -compose divide -composite -linear-stretch 5%x0% <output_image>

  You can ofcourse add an alias or better still, a bash function for such long commands in your ~/.bashrc to make your life easier.

* How to check unread mail from your gmail inbox from the command line

		$ curl -u your_email@gmail.com:your_password --silent \
		  "https://mail.google.com/mail/feed/atom" | tr -d '\n' | \
		  awk -F '<entry>' '{for (i=2; i<=NF; i++) {print $i}}' | \
		  sed -n "s/<title>\(.*\)<\/title><summary>\(.*\)<\/summary.*name>\
		  \(.*\)<\/name><email>\(.*\)<\/email>.*/\n\3\(\4\) - \1 - \2\n/p"

  This command might look like too much to handle, but it is really extremely simple. All it is doing is reading from your gmail account's atom feed and formatting the output using awk and sed. As before, you are better of creating an alias(or a bash function) in your ~/.bashrc for this command.


#### A super-simple chat program that you can run from the command line

You will need to install "netcat" on your linux box for this to work.

* Open a terminal on Computer A and type in

		$ nc -l 12345

* Also note down the IP addr of Computer A by running the "ifconfig" command. Let us say, the IP addr of Computer A is a.b.c.d

* Now, open a terminal on another Computer B which also has "netcat" installed and type in

		$ nc a.b.c.d 12345

Here, 12345 is simply a port number. You can specify anything you want as long as it is not already in use.        

Thats it... You have a chat program running. Type anything and press enter, it will be immediately visible on the other computer. To test this out you might as well run the two commands on two different terminals on the same computer, in which case, you will have to replace the IP addr a.b.c.d by the simple string "localhost".


#### The fastest way to transfer files from Computer A to Computer B over the network from the command line

You will need "netcat" installed for this to work.

* On Computer A with ip addr a.b.c.d, run the command

		$ tar -cf - /path/to/dir | \
		  pv -s $(du -sb /path/to/dir | awk '{print $1}') | \
		  nc -l 12345

* On computer B, run

		$ nc a.b.c.d 12345 | pv | tar -xf -

All we are doing here is tarring the directory we want to transfer and then using netcat to transfer the file over the network. Note that there are actually no intermediate archives that are created either on Computer A or Computer B.

The pv command in the middle is only there to show you a progress bar of how much data is left to be transferred. This can be useful for large files. But you can always competely remove it from both of the above commands and still work correctly. Only thing is you won't have any feedback until the entire directory is transferred. Note that pv is not available as default on most linux boxes. You will have to install it.

You may be wondering why do we need to perform a tar when we are simply transferring a single file instead of a directory. The answer is you don't. To transfer a single file:

* On Computer A you will run

		$ cat /path/to/file | nc -l 12345

* To receive the file on Computer B, you would run,

		$ nc a.b.c.d 12345 > myfile

As simple as that!!!.        

A word of caution. On some computers with different version of netcat installed, you will need to replace the command "nc -l 12345" with "nc -l -p 12345" for netcat to work correctly. All other commands remain same.


#### How to get a progress bar while copying huge files

Normally cp command does not give you any output while you are copying files. You have no idea how much copying is left to be done. However you can use a slightly different command to copy large with a progress bar shown. As you might have guessed, the solution is to use "pv" command described in the previous section.

	$ cat originalfile.txt | pv > newfile.txt

<br />
<br />
<br />
<br />
<br />
<br />

Wuff... this is one huge article, but one which I enjoyed writing and one I hope you will enjoy executing. I have at some point used all of these commands in my day to day work. It is very likely that you may get errors saying command not found while executing some of these commands, because you don't have the necessary packages installed. You can always install them and continue playing or you can leave a comment below and I will help you get it working. Enjoy Linux :) :) and stay tuned for more comprehensive articles on specific Linux tools like vim, ssh, scp, rsync, git version control system and more in the future.

Once again I sincerely thank [Mr. Chandrashekar Babu](http://chandrashekar.info/) for his superb linux training classes at Cisco and for enlightening us about some of the above Linux command line tricks.
