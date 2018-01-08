---
layout: post
title: "Linux command line tools and tricks - Part 2"
---

Hope you enjoyed the first part of my Linux tools and tricks. Here, I give you few more interesting commands and tools for daily use and for fun.

#### Securely delete files so that they can't be recovered

We have all seen movies where federal departments are able to recover data from hard drives of cons. If only they knew how to use linux. Linux allows you to completely destroy previous data by overwriting it with all zeroes/nulls, making it impossible to recover, no matter how much government funding the person trying to recover your data receives. And the process couldn't have been more simpler.
        
	$ dd if=/dev/zero of=<file_to_delete>;sync;rm -f <file_to_delete>

If you remember, we had used the "dd" command to create a bootable usb in part 1 of my Linux hacks. There is a special file in linux by the name /dev/zero which contains nothing but zeroes. However, this is not a physical file on disk, and is generated on the fly. So, the file size you are trying to delete securely doesn't matter. The "sync" command just flushes the output buffers. Up to this step you have only overwritten the file on the disk. You can view it with your favorite editor, but all you will see is junk data. Now it is safe to remove the file using the normal "rm" command.

#### Recording a super-high quality screen-cast from the command line

Let us get straight down to business with the command.

	$ ffmpeg -f x11grab -r 30 -s 1366x768 -i :0.0 -vcodec libx264 -vpre lossless_ultrafast -crf 0 -threads 0 /tmp/output.mkv

Looks complicated, but really very easy to break it down. 

-f x11grab tells ffmpeg that the input will be from the x11 windowing system. x11 is simply a standard for GUI.

-r 30 tells the frame rate which in this case will be 30 fps.

-s 1366X768 tells the size of the screen to record. Please be sure to specify a resolution suitable for your computer, otherwise you will get an error.

-i :0.0 tells ffmpeg to record from your display. This is required because there can be multiple monitors attached. This is nothing but the value of a shell variable by the name $DISPLAY. You can say "$ echo $DISPLAY" to confirm it on your machine.

-vcodec specifies the video codecs to use.

-vpre specifies some video presets... to make the video recording lossless.

The other options can be ignored. The last argument is the file name where the screen-cast will be stored.

#### Using pushd and popd to navigate directories

we are all familiar with the cd command to navigate directories. But power users use something else in addition. They are pushd and popd. The commands and what they do are super simple.

	$ pushd <dir_name>

The above command will push the present working directory onto a stack and then automatically cd to '<'dir_name'>'.        

When you are done with the new directory, if you want to get back to the old one, without having to type in the name, you just do

	$ popd

That's it. You are in your previous working directory. This method can be used to navigate between commonly used directories.        

You can view the current directory stack at any time using the command

	$ dirs -l -p -v

The above command displays the number of the directory on the stack as well. You will notice that, always, the current directory will be on the stack regardless of whether you use pushd or popd. You can use these numbers to cd to a specific directory on the stack like so

	$ popd +2   

This will cd to the second directory on the stack(from the top of the stack).        

You can clear the entire contents of the directory stack with

	$ dirs -c

#### Share any directory with any user via a web browser        

First, cd to the directory that you want to share with others and then enter this simple command.

	$ python -m SimpleHTTPServer

Now, ask the other person to open a web browser and enter the URL as follows.

	<IP_addr_of_your_machine>:8000

You can easily find out the IP addr of your machine using the "$ ifconfig" command.

Now the other user should be able to see the contents of your directory and all subdirectories recursively, in a simple text interface.

#### Translate an English sentence to speech in other language and play it on your speakers

This is a simple hack which uses Google Translate and google tts(text to speech) to convert any English sentence into another language and play the speech on your computer's speakers. The disadvantage at this moment is that Google Translate does not have support for text to speech conversion for many languages. However, for those languages that do have tts support, you can have fun trying them. For example, the following command speaks out the phrase "I will sleep" in Russian !!!

	$ wget -q -O - -U Mozilla 'http://translate.google.com/translate_tts?tl=ru&q=I will sleep' | mpg123 -q -

We have seen in Part 1 of Linux tools and tricks that wget is used to download files off the internet. It does the same thing here are well. Only this time, the output wont be written to a file, but to standard output. This is specified using the -O - option. Of course, you would not want some mp3 non-ascii symbols to ruin your terminal. That is why we use the -q option to quiet the wget command. -U specifies the user-agent that the web server will see, or in simple words, the name of the web browser. We are cheating the web server into believing that the request is coming from a Mozilla browser. The parameters following the ? are GET request parameters. One of them is tl which specifies the language you want the sentence translated into. The second GET request parameter is q which specifies the sentence to translate. The order of the parameters may be interchanged without any problem, and you can specify any English sentence and any language(provided that language has tts support) The second GET request parameter is q which specifies the sentence to translate. The order of the parameters may be interchanged without any problem, and you can specify any English sentence and any language(provided that language has tts support). Now, all we are doing is piping the output to another program by the name mpg123 that can play the mp3 stream that it receives from the standard output of wget. You will have to install the mpg123 program on your computer for this hack to work. Happy translating :)

#### Taking a screen-shot when print-screen does not work

	$ chvt 7; sleep 10; import -display :0.0 -window root image.png

Let us break down the command.

chvt 7 means change to virtual terminal 7. If you have noticed while using linux that there are many virtual terminals that you can access by pressing CTRL-ALT-F1 to CTRL-ALT-F7. CTRL-ALT-F7 is usually the virtual terminal that is running the x11 windowing system. That is where you would want to take your screen-shot.

sleep 10 means do nothing(sleep) for 10 seconds. This gives you 10 seconds the position the window of which you want the screen-shot to be taken in the foreground. You can adjust this to your liking, just do not make it too low.

The next command simply imports the contents from your display into a file named image.png in the directory from which you executed the command.

As in the screen-casts command that you saw previously :0.0 refers to your display. You can see this by typing "$ echo $DISPLAY".

Simple, and guaranteed way to take a screen-shot no matter which linux box you are using.

#### Executing a command continuosly

Have you encountered a situation where you are copying gigabytes of data and you don't know how much has been copied to the destination yet? The following command will help you out.

	$ sudo watch du -sh /path/to/destination_dir

The above command will show how many megabytes(M) or gigabytes(G) of data are being copied to the destination and the information is updated every two seconds. You can ofcourse change the interval at which the command is repeated by using the -n switch as follows

	$ sudo watch -n 10 du -sh /path/to/destination_dir

This command is the same as the previous one except that the du command is executed at 10sec intervals rather than the default 2sec intervals.

In fact you can pass as argument to watch any command that you want to execute repeatedly. Here, the du command was only used as an example. 

You can exit the command by pressing Ctrl+C.

#### Gstreamer fun - Capture webcam video from command line and save to file

Gstreamer is a media framework which means it allows you to form codecs (which are called plugins in gstreamer parlance) into a pipeline which allows you to do really interesting things with your media. The following is one very simple example.

The following Gstreamer pipeline allows you to run the webcam on your laptop using just the command line...

	$ gst-launch v4l2src device=/dev/video0 ! \
	  "video/x-raw-yuv, width=640, height=480, framerate=30/1" ! \
	  xvimagesink

gst-launch is the command to create a gstreamer pipeline. A gstreamer pipeline is nothing but a collection of the appropriate codecs in the proper order. Each component (or plugin) of the pipeline is seperated by a bang(!). The first plugin, v4l2src identifies the source of the input, which in our case is the webcam. In Linux, everything is a file and the file that represents the webcam is /dev/video0... how convenient... Linux rocks !!! The next component within the quotes are called the filter caps... Do not bother much about what it does, but it is used to negotiate some parameters between adjacent plugins. The final component is a sink, which in this case refers to the screen where the video captured from the webcam is displayed. 

If you want to record the webcam video to a file, then all you need is a minor modification to the above command...

	$ gst-launch v4l2src device=/dev/video0 ! \
	  "video/x-raw-yuv, widht=640, height=480, framerate=30/1" ! \
	  x264enc ! mpegtsmux ! filesink location=webcam.h264

The Gstreamer pipeline in this case is essentially the same as the previous, the only difference being that the sink in this case is a file rather than the screen, as a result of which the video captured from the webcam is saved to the specified file.          

Now, you can play the recorded webcam video from the command line as follows

	$ vlc webcam.h264

#### More Gstreamer fun - Extract mp3 from mp4 video in command line        

We can do some really cool things with a Gstreamer pipeline. Here is just one more example. Have you every searched the farthest reaches of the internet to convert a mp4 music video that you downloaded off youtube to a mp3 so you could play it on your mp3 player.  The task couldn't have been more easier.

	$ gst-launch filesrc location=<mp4 file> ! decodebin2 ! \
	  audioconvert ! lame quality=0 ! filesink location=<mp3 file>

Let us understand this simple Gstreamer pipeline. The first plugin gives us the source(or input) which is a mp4 file on your computer. The second component "decodebin2" is a sort of universal decoder in Gstreamer. It does all the hard work like identifying the type of input stream(in this case mpeg4), calling the appropriate decoder to decode this stream, etc on your behalf so you don't have to worry about all the minute details. The third plugin "audioconvert" is responsible for converting the decoded stream into raw audio. But this raw audio is just bits and bytes which cannot be played by your favorite mp3 player, because your player cannot identify this raw data as mp3. So, there needs to be some metadata (like headers) to identify this file as mp3 and this is the work of the "lame" plugin, which is a mp3 encoder(it encodes the raw audio into an mp3 stream). The "quality=0" is nothing but one of the parameters of the lame encoder which tells it to use the best quality algorithm to encode the mp3 file(higher quality means slower encoding). And finally the stream is written to a sink, which in this case is a file on your computer.

#### Safe reboot (Linux SysRq magic)

Whenever you find yourself holding down the power button to force shutdown your linux box, you are at risk of losing important data and corrupt existing data on disk because the disks have not been synced yet, which will happen only when you end a process(like say a text editor) correctly.There is however a neat method that linux provides to safely reboot your linux box, when you cannot work with the GUI or cannot open a console.

To use it, you will need to enable SysRq(System Request) on your linux machine, which is disabled by default. You can enable it by

	$ sudo echo "kernel.sysrq = 1" >> /etc/sysctl.conf

Now, reboot your system to make sysrq available.

If you haven't already noticed, every modern keyboard has a dedicated sysrq key which is mostly the same as the Print Screen key. Ha!!! noticed it now. Good for you. To send Sysrq messages to the kernel, you will have to use the key combination "Alt+PrintScr"

So, the next time you are left looking for the power button to hard-reboot your system, spare your computer hard-disks some trouble and use the key sequence --- "Alt+PrintScr+sub" (i.e, press 's' followed by 'u' followed by 'b' while keeping the Alt and PrintScr keys depressed the whole time). Each of these keys sends a special signal as interrupts to the kernel which you can be sure the kernel will service even though nothing on the outside seems to be working for you(although the only thing that isn't working mostly is the Xwindows system).

To put is plainly, pressing "Alt+PrintScr+s", forces data in buffers to be synced to the disks, so you don't lose data that you haven't saved yet. "Alt+PrintScr+u" unmounts any filesystems that have been mounted. "Alt+PrintScr+b" tells the kernel to reboot the system. There you go, a safe reboot :)

#### Faster keyboard cursor movement in Linux
Have you found yourself wishing that the keyboard cursor moved a bit faster while working on the terminal or in an editor like vim or emacs. The solution is a one-liner as below

	$ xset r rate 200 60

What is this command doing? It is basically decreasing the keypress interval delay to 200(from the default 250 or something) and increasing the rate of keypress to 60(from the default 30). Be sure to add the command to your bashrc. Feel free to change the numerics according to your needs, I found the above settings quite comfortable. For faster cursor movement, decrease the first value and increase the second value in the command.

<br />
<br />
<br />
<br />
<br />
<br />
<br />

__Stay tuned for more additions to this page.__
