---
layout: post
title: "OTP scanner in Python using OpenCV and Tesseract (Part 4)"
---

In the previous three posts, we were able to successfully extract the OTP from an image of our phone's screen taken by a webcam.

In this post, we will continue our automation conquest by building a GUI automation system using [`pyautogui`](https://pyautogui.readthedocs.io/en/latest/) that can automatically log us in to the VPN and the virtual desktop with no user intervention whatsoever.

<br/><br/>

#### Step 9: Automatically connect to VPN and virtual desktop

```python
# Wait until the given image appears on the screen before taking the next step
def pyautogui_wait(image):
    while True:
        center = pyautogui.locateCenterOnScreen(image)
        if center:
            return center
        else:
            time.sleep(0.5)


PYAUTOGUI_IMAGES_PATH = os.path.join(os.path.dirname(sys.argv[0]), 'pyautogui_images')


# GUI automation using pyautogui to connect to VPN if not already connected
def connect_VPN():
    ping_cmd = 'ping -c 1 ' + credentials.login['url'] + ' > /dev/null 2>&1'

    resp = os.system(ping_cmd)
    if resp == 0:
        # Already connect to VPN
        print("Already connected to VPN...")
        return False

    cols, rows = pyautogui.size()

    pyautogui.moveTo(cols-2, rows-2)
    pyautogui.click()
    time.sleep(1)
    pyautogui.moveTo(1447, 681)
    pyautogui.click()
    pyautogui_wait(os.path.join(PYAUTOGUI_IMAGES_PATH, 'vpn.png'))
    pyautogui.typewrite(credentials.login['password'])
    pyautogui.press('tab')
    pyautogui.typewrite(text) # OTP
    pyautogui.press('enter')

    # Wait until VPN connection is successful
    while True:
        resp = os.system(ping_cmd)
        if resp == 0:
            print("Connected to VPN...")
            break
        time.sleep(0.5)

    return True


def start_virtual_desktop():
    ps = subprocess.Popen(['ps', 'ax'], stdout=subprocess.PIPE)
    out = ps.communicate()[0]
    for line in out.decode('utf-8').split('\n'):
        if 'vmware-view' in line:
            # Nothing to do if the virtual desktop is already running
            print("Virtual desktop already running...")
            return False

    subprocess.Popen(["vmware-view"], \
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    center = pyautogui_wait(os.path.join(PYAUTOGUI_IMAGES_PATH, 'vd1.png'))
    pyautogui.moveTo(*center)
    pyautogui.doubleClick()
    pyautogui_wait(os.path.join(PYAUTOGUI_IMAGES_PATH, 'vd2.png'))
    pyautogui.typewrite(credentials.login['username'])
    pyautogui.press('tab')
    pyautogui.typewrite(text) # OTP
    pyautogui.press('enter')
    pyautogui_wait(os.path.join(PYAUTOGUI_IMAGES_PATH, 'vd3.png'))
    pyautogui.typewrite(credentials.login['password'])
    pyautogui.press('enter')
    center = pyautogui_wait(os.path.join(PYAUTOGUI_IMAGES_PATH, 'vd4.png'))
    pyautogui.moveTo(*center)
    pyautogui.doubleClick()
    print("Started virtual desktop...")

    return True
```

The above code automatically connects to the VPN and starts the virtual desktop using the OTP extracted from the webcam image and other login credentials stored on disk (credentials.py).

__The above code is completely specific to my desktop environment__, but nevertheless, I still want to show you some of the most basic GUI automation you can accomplish using `pyautogui`.

<br/>

Following are the most frequently used pyautogui command you'll need to know:

1. [`pyautogui.moveTo()`](https://pyautogui.readthedocs.io/en/latest/mouse.html#mouse-movement) to move the mouse pointer to a particular location on screen.

2. [`pyautogui.click()` and `pyautogui.doubleClick()`](https://pyautogui.readthedocs.io/en/latest/mouse.html#mouse-clicks) to perform a single and double mouse click respectively.

3. [`pyautogui.typewrite()`](https://pyautogui.readthedocs.io/en/latest/keyboard.html#the-typewrite-function) to type a string using the keyboard (for example, "hello world").

4. [`pyautogui.press()`](https://pyautogui.readthedocs.io/en/latest/keyboard.html#the-press-keydown-and-keyup-functions) to press a specific key on the keyboard (for example, the \<Enter\> key).

5. [`pyautogui.hotkey()`](https://pyautogui.readthedocs.io/en/latest/keyboard.html#the-hotkey-function) to simulate multiple key presses in a particular sequence (for example, "ctrl" "v" to paste).

<br/>

The feature of `pyautogui` that I really wanted to highlight in this post is - [`pyautogui.locateCenterOnScreen()`](https://pyautogui.readthedocs.io/en/latest/screenshot.html#the-locate-functions) - since it took me quite some time to get it working correctly.

Very often in GUI automation you'll need to wait until a particular object appears on the screen (for example, an application window or a login window) before you can perform any automated mouse or keyboard actions.

The way you do that is using `pyautogui.locateCenterOnScreen()`.

```python
def pyautogui_wait(image):
    while True:
        center = pyautogui.locateCenterOnScreen(image)
        if center:
            return center
        else:
            time.sleep(0.5)
```

The above code waits until a given `image` appears on the screen. Useful for waiting until an application window opens up or until a login window appears on screen.
Once the `image` appears on the screen the coordinates of its center are returned to the caller. The `center` coordinates can then be used in further pyautogui commands (for example, to move the mouse pointer to that position).

<br/>

__Now, how do you get images that can be passed to `pyautogui.locateCenterOnScreen()` ?__

On Linux, I found that the `scrot -s` command works perfectly.
Once you run this command you'll have to select a rectangular region for the screenshot.
You might want to pin the window/object you are trying to take a screenshot of (so that the window/object is always on top) before you run this command.
You can then pass this screenshot image directly to `pyautogui.locateCenterOnScreen()`.


<br/><br/>

We have successfully completed our OTP scanner and GUI automation...
