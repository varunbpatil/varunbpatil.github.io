---
layout: post
title: "Coursera Video Downloader"
---

__[UPDATE 22-JAN-2018]: You can now download videos for an entire course in one go__

The video download link below a coursera lecture video for some reason always downloads the least quality video.
So, I decided to write a simple `Python + Selenium + Requests` script to download high quality (720p) lecture videos from the Coursera course you have access to. This script automates the process of downloading and naming high quality videos from Coursera (with minimum user intervention).

Please note that this script is in no way designed to circumvent Coursera. You can only download the lecture videos, if you have access (i.e, enrolled). The downloaded videos are only meant for personal use.

You can get the code from [github](https://github.com/varunbpatil/Coursera_Video_Downloader) as well.

NOTE: This script downloads all the lecture videos for ~~a given week~~ the entire course. The URL input to this script should be the Coursera page that contains the lecture videos for ~~one week~~ the first week. For [example](https://www.coursera.org/learn/convolutional-neural-networks/home/week/1),

<img src="/assets/coursera.png" />

This script will download `mp4` video files to the directory from which it is run.

#### Dependencies

- Python

- [Selenium](https://selenium-python.readthedocs.io/)

- [Requests](http://docs.python-requests.org/en/master/)


{% highlight python linenos %}
# Coursera Video Downloader v1.0

from selenium import webdriver
import requests
import sys


# Example course_url - https://www.coursera.org/learn/convolutional-neural-networks/home/week/1
if len(sys.argv) != 2:
    print('Usage: cvd.py <course_url>')
    exit(1)


browser = webdriver.Firefox()
browser.implicitly_wait(60)
browser.get(sys.argv[1])


# Login
username = browser.find_element_by_id("emailInput-input")
password = browser.find_element_by_id("passwordInput-input")
login    = browser.find_element_by_xpath("//button[contains(@class, 'Button_1fxeab1-o_O-primary_cv02ee-o_O-md_28awn8 w-100')]")
username.send_keys("...")      # your username here
password.send_keys("...")      # your password here
login.click()


# Prepare a list of all the video hyperlinks
video_urls = []
video_names = []

while True:
    try:
        browser.get(url)
    except WebDriverException:
        break

    # Coursera redirects to week1 url if the week number is wrong
    if browser.current_url != url:
        break

    link_objs = browser.find_elements_by_class_name('rc-ItemLink.nostyle')

    for link in link_objs:
        link_url  = link.get_attribute("href")
        link_name = link_url.split('/')[-1]
        link_type = link_url.split('/')[-3]

        if link_type == "lecture":
            video_urls.append(link_url)
            video_names.append(link_name)

    next_week = str(int(url.split('/')[-1]) + 1)
    url = '/'.join(url.split('/')[:-1] + [next_week])


# Download videos
resolution_selected = False

for i, (video_url, video_name) in enumerate(zip(video_urls, video_names)):
    browser.get(video_url)
    
    if not resolution_selected:
        x = input("Please select video resolution and then press Enter...")
        resolution_selected = True
        browser.get(video_url)

    download_url = browser.find_element_by_id('c-video_html5_api').get_attribute("src")

    response = requests.get(download_url, stream = True)
    handle = open(str(i + 1) + "-" + video_name + ".mp4", "wb")

    for chunk in response.iter_content(chunk_size = 1 * 1024 * 1024):
        if chunk:
            handle.write(chunk)

    handle.close()


browser.close()
{% endhighlight %}


#### Code deep dive

{% highlight python %}
browser = webdriver.Firefox()
{% endhighlight %}

Currently using firefox as the browser. Please feel free to change it to [some other browser](https://selenium-python.readthedocs.io/installation.html#drivers).

{% highlight python %}
browser.implicitly_wait(60)
{% endhighlight %}

This waits for a maximum of 60 seconds for the page to load correctly before performing any action. Increase this if you are on a very slow connection. Note that this does not affect the download times for videos. This is only for the page load times.

{% highlight python %}
username.send_keys("...")      # your username here
password.send_keys("...")      # your password here
{% endhighlight %}

Please modify this part with your Coursera account username and password.


{% highlight python %}
# Prepare a list of all the video hyperlinks
video_urls = []
video_names = []

while True:
    try:
        browser.get(url)
    except WebDriverException:
        break

    # Coursera redirects to week1 url if the week number is wrong
    if browser.current_url != url:
        break

    link_objs = browser.find_elements_by_class_name('rc-ItemLink.nostyle')

    for link in link_objs:
        link_url  = link.get_attribute("href")
        link_name = link_url.split('/')[-1]
        link_type = link_url.split('/')[-3]

        if link_type == "lecture":
            video_urls.append(link_url)
            video_names.append(link_name)

    next_week = str(int(url.split('/')[-1]) + 1)
    url = '/'.join(url.split('/')[:-1] + [next_week])
{% endhighlight %}

In this part of the code, we collect all the video URL's that need to be downloaded for all the weeks of the entire course.
Note that Coursera redirects URL to week 1 if the week number in the URL is wrong. We use this knowledge to decide when to abort gathering video URL's once we have gathered video URL's for the entire course.


{% highlight python %}
# Download videos
for i, (video_url, video_name) in enumerate(zip(video_urls, video_names)):
    browser.get(video_url)
    
    if not resolution_selected:
        x = input("Please select video resolution and then press Enter...")
        resolution_selected = True
        browser.get(video_url)

    download_url = browser.find_element_by_id('c-video_html5_api').get_attribute("src")

    response = requests.get(download_url, stream = True)
    handle = open(str(i + 1) + "-" + video_name + ".mp4", "wb")

    for chunk in response.iter_content(chunk_size = 1 * 1024 * 1024):
        if chunk:
            handle.write(chunk)

    handle.close()
{% endhighlight %}

This is the main video download code. The for loop before this just creates a list of lecture videos to download for ~~that week~~ the entire course.
In this for loop, we actually download the videos. This particular step `requires user intervention` which is detailed below.


#### User intervention

The above script is not entirely automated (atleast, not yet). The problem here is that by default, the videos start playing with "low" quality and I couldn't figure out a way, using selenium, to automatically change the quality to "high". So, the user will have to `manually change the video quality` as desired before the script actually starts downloading the video.

Note that this manual user intervention is required only once per execution of the script. Once the video quality is set manually, all the subsequent video downloads will be of that quality.

When the script is run, you will see the following message on the terminal.

    Please select video resolution and then press Enter...
    
At this point, open the browser window (that selenium created) and select the preferred video quality by clicking on the gear icon on the bottom right of the video being played. After you have done that, go back to the terminal and press Enter. Actual video downloading with your selected video quality will now start.


#### Misc

I haven't found a way to automate the video quality selection yet. Suggestions are welcome.

If you're wondering, why use `selenium` and not `requests` library directly, it is because, the dynamic javascript rendering of the pages makes it difficult (impossible?) to get the inner HTML (video url's, etc) using plain HTTP requests.

The script in its current version is capable of downloading ~~only one week's worth of videos~~ videos for the entire course. ~~I'm working on allowing it to download videos for an entire course~~.
