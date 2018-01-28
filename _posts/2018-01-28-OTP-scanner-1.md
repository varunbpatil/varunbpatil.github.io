---
layout: post
title: "OTP scanner in Python using OpenCV and Tesseract (Part 1)"
---

The company I work for uses a one-time-password (OTP) generated on a mobile phone app to login to its virtual private network (VPN) and virtual desktop.
It was becoming quite a pain to enter the username, password and OTP twice (once to connect to the VPN and again to login to the virtual desktop) every time I wanted to login.
So, I set out to automate everything so that I could sit back and relax for a minute while the program logs me in and sets up my work environment.

This is the first in a series of blog posts chronicling how I went about achieving this automation.

__The entire code is available on [GitHub](https://github.com/varunbpatil/OTP_scanner).__

<br/><br/>

#### Problem Statement

The problem is quite simple. How do you extract a piece of text (the OTP) from an image of your phone screen taken by your laptop webcam ?

An image is worth a thousand words...

![Problem Statement]({{ "/assets/OTP/problem_statement.jpg" | absolute_url }})

<br/><br/>

#### Attacking the problem

The entire problem can be broken down into three steps:

1. Identify the region in the image that contains the OTP.

2. Use an optical character recognition algorithm (OCR) to extract the text from the region.

3. Use a GUI automation library to perform a series of mouse movements, mouse clicks, keyboard presses, etc to automatically connect to the VPN and virtual desktop.

[`OpenCV`](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_tutorials.html) helps us with the first part of the problem, [`Tesseract`](https://github.com/madmaze/pytesseract) with the second and [`pyautogui`](https://pyautogui.readthedocs.io/en/latest/) with the third.

<br/>

Identifying the region of the image that contains the OTP is by far the most challenging part of the problem.

Our algorithm will need to be resilient in the face of :

1. Rotated images (like the one shown above).

2. Varied external lighting conditions.

3. Varied screen brightness of the phone.

4. Other objects in the image like hands, fingers, faces, etc.

But, we have one thing going for us. We know that the OTP is contained in a rectangular region (possibly rotated).
Using `OpenCV`, we can identify potential candidate regions and pass them all through the OCR one by one and one of them should give us the OTP we need.

<br/><br/>

#### Step 1: Dependencies

The following are the libraries we will need.

```python
from PIL import Image
import pytesseract             # Python interface to tesseract for OCR
import cv2                     # OpenCV computer vision library
import os
import numpy as np
import re
import subprocess
import pyautogui               # GUI automation library
import time
import sys
import credentials
```

* [PIL](https://pillow.readthedocs.io/en/latest/) for reading and writing images.
* [pytesseract](https://github.com/madmaze/pytesseract) - The OCR (Optical Character Recognition) program.
* [cv2](https://docs.opencv.org/3.1.0/index.html) - OpenCV - for computer vision.
* [numpy](http://www.numpy.org/) for manipulating images.
* [pyautogui](https://pyautogui.readthedocs.io/en/latest/) for GUI automation.

<br/><br/>

#### Step 2: Global configuration

```python
pyautogui.PAUSE = 0.5          # Pause one second after each pyautogui command
pyautogui.FAILSAFE = True      # Moving cursor to top-left will cause exception
DEBUG = False                  # If True, write intermediate images to /tmp
```

`pyautogui.PAUSE` is the time (in seconds) that pyautogui pauses between each pyautogui command.

`pyautogui.FAILSAFE` is a [failsafe mechanism](https://pyautogui.readthedocs.io/en/latest/introduction.html#fail-safes) in order to exit the program with an exception in case pyautogui starts behaving erratically or uncontrollably.

`DEBUG = True` dumps all intermediate images to the /tmp directory for visual inspection.

You might also have noticed the `import credentials` statement previously. This is where I store my login and passwords (not under version control) that we will be using later to automatically connect to the VPN and the virtual desktop. Create a file called __credentials.py__ in the same directory as otp.py with the following contents:

```python
# credentials.py (place in the same directory as otp.py)
login = {
    'username' : '...',
    'password' : '...',
    'url'      : '...'
}
```

<br/><br/>

#### Step 3: Capturing an image from webcam

The following is the function which uses `OpenCV` to capture an image of your phone's screen using your laptop's webcam.

The webcam settings in the code below are the default hardware settings for Lenovo T440s. They will need to be tweaked based on your webcam. I'll show you how in a little while.

```python
# Get image from webcam using OpenCV
def get_image():
    print("Waiting 5 seconds before capturing image... Press <space> to capture image immediately...")

    cam = cv2.VideoCapture(0)  # ls /sys/class/video4linux

    # Hardware defaults for Lenovo T440s
    cam.set(3, 1280)           # Width
    cam.set(4, 720)            # Height
    cam.set(10, 128/255)       # Brightness (max = 255)
    cam.set(11, 32/255)        # Contrast (max = 255)
    cam.set(12, 64/100)        # Saturation (max = 100)
    cam.set(13, 0.5)           # Hue (0 = -180, 1 = +180)

    num_frames = 0
    while True:
        ret, image = cam.read()
        if not ret:
            print("Camera not functional...")
            sys.exit(1)

        cv2.imshow('image', image)

        # Capture image if <space> is pressed
        if (cv2.waitKey(1) & 0xFF) == ord(' '):
            break

        # Wait 5 seconds before capturing image
        num_frames += 1
        if num_frames / 10 == 5:
            break

    cam.release()
    cv2.destroyAllWindows()

    if DEBUG:
        cv2.imwrite("/tmp/image.jpg", image)

    return image
 ```

 The above function waits for 5 seconds or until the \<space\> key is pressed to capture an image. A window is displayed mirroring what the webcam sees.

 If `DEBUG = True`, the captured image is also written to /tmp/image.jpg

 <br/>

 __Webcam configuration__

 The webcam configuration in the above code took me quite a while to figure out how to do correctly. Here is how you go about it.

 On Linux, I used the [`guvcview`](http://guvcview.sourceforge.net/) application to find out the numeric values for my webcam's default settings.

 Launch `guvcview`, then Settings \=\> Hardware Defaults. Note down the default values.

 Now, to configure OpenCV with the default values, you use the `cam.set()` function. The first argument is the [property](https://docs.opencv.org/2.4/modules/highgui/doc/reading_and_writing_images_and_video.html#videocapture-get) you want to set and the second argument is the value you want to set it to.

Note that we cannot specify the default values directly to OpenCV. The second argument expects a value between 0 and 1 and so, we will have to divide the value by the range of supported values.


![Step3]({{ "/assets/OTP/step3.jpg" | absolute_url }})


<br/><br/>

Now that we have captured an image of our phone's screen, lets see how we can go about extracting the OTP from it in the [next post]({% post_url 2018-01-28-OTP-scanner-2 %}).

