---
layout: post
title: "OTP scanner in Python using OpenCV and Tesseract (Part 2)"
---

We saw in the [previous post]({% post_url 2018-01-28-OTP-scanner-1 %}) how to use OpenCV to capture an image using the laptop's webcam.

![Step3]({{ "/assets/OTP/step3.jpg" | absolute_url }})

In this post, we continue to look at how to extract the OTP from the captured image.

<br/><br/>

#### Step 4: Image pre-processing

1. Apply [medianBlur](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_filtering/py_filtering.html#median-filtering) to reduce noise/smooth out the image.

    ```python
    # Remove noise with median blurring
    image = cv2.medianBlur(image, 5)
    ```

2. Convert to grayscale. We don't need the color information.

    ```python
    # Convert to grayscale
    grayscale = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    ```

    ![Step4_1]({{ "/assets/OTP/step4_1.jpg" | absolute_url }})

3. Convert to a binary image (image with two colors only - black and white). This makes it easier to identify edges in the image.

   The way we do this is using [Adaptive Thresholding](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_thresholding/py_thresholding.html?highlight=adaptive#adaptive-thresholding). Adaptive Thresholding works here because the lighting conditions are not uniform across the image and thus a different threshold is calculated and used in different parts of the image. The threshold value is used to classify image pixels as either black or white depending on whether the original pixel values are below or above the threshold respectively. The input to this function is the grayscale image from the previous step.

    ```python
    # Convert to a binary image with adaptive thresholding.
    threshold = cv2.adaptiveThreshold(grayscale, 255, \
                                      cv2.ADAPTIVE_THRESH_GAUSSIAN_C, \
                                      cv2.THRESH_BINARY, 101, 0)
    ```

    The second argument (255) is the pixel value to be used if the original pixel value exceeds the threshold.

    The third argument (cv2.ADAPTIVE_THRESH_GAUSSIAN_C) determines how the threshold is calculated.	From the doc - threshold value is the weighted sum of neighbourhood values where weights are a gaussian window.

    The fourth argument (cv2.THRESH_BINARY) specifies that we want to convert to a binary image (black and white pixels only).

    The fifth argument (101) is the size of a pixel neighborhood that is used to calculate a threshold value for the pixel.

    The sixth argument (0) is a constant subtracted from the mean or weighted mean.

    ![Step4_2]({{ "/assets/OTP/step4_2.jpg" | absolute_url }})

4. Next, we run a [canny edge detector](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_canny/py_canny.html?highlight=canny) on the threshold image to detect edges in the image. The input to this function is the thresholded image from the previous step.

    ```python
    # Run canny edge detector on the binary image
    edge = cv2.Canny(threshold, 100, 200)
    ```

    The second and third arguments are the lower and upper threshold for detecting edges. Lower values result in a lot of noise. Edges are detected where there aren't any. Higher values result in failure to detect edges because the pixel gradient is too small.

    A lot of applications I found on the internet apply canny edge detector directly to the graysale image from step 2. That method did not seem to work correctly for this particular application because of the nearly identical light gray and white pixels in the image resulting in a failure to detect edges under certain lighting conditions. I found that edge detection works better if I first apply adaptive thresholding on the grayscale image giving the image better contrast/gradient (black vs white) as can be seen in the image above.

    ![Step4_3]({{ "/assets/OTP/step4_3.jpg" | absolute_url }})

    We can clearly see that the canny edge detector has successfully detected several rectangular regions, one of which contains the OTP we are looking for.

<br/><br/>

#### Step 5: Finding contours

Once we have detected edges in the image, it is time to detect [contours](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_contours/py_contours_begin/py_contours_begin.html#contours-getting-started) from those edges. These contours give us the bounding rectangles for the different regions in the image.

```python
# Key for sorting contours based on the area of their bounding box
def contour_key(contour):
    # Get the minimum area bounding box for the contour
    rect = cv2.minAreaRect(contour)

    # Get the width and height of the bounding box
    w, h = rect[1]
    if w < h:
        w, h = h, w

    # We are only interested in rectangular contours (w > h)
    if h > 0 and w/h < 1.5:
        return 0
    else:
        return w * h


# Find the top 10 contours based on the area of their bounding rectangles
contours = cv2.findContours(edge, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)[1]
contours = sorted(contours, key=contour_key, reverse=True)[:10]
```

At the start of the [first post]({% post_url 2018-01-28-OTP-scanner-1 %}), I mentioned that we are mostly interested in large rectangular regions. This is where that logic comes into force. We sort the contours in descending order by the area of their bounding rectangle. Also, we reject any contours whose bounding rectangle width is not atleast 1.5 times the height. This leaves us with 10 contours whose bounding rectangles are the largest we have found in the image.

<br/><br/>

#### Step 6: Getting the bounding boxes

Once we have the top 10 contours by area of their bounding rectangles, we need to get the bounding boxes for those contours. These boxes may be rotated.
The following code gathers all the (interesting) bounding boxes into the `boxes` list for further processing later on.

```python
# Get minimum area bounding boxes for the contours
def get_bounding_boxes(contours, image):
    boxes = []

    if DEBUG:
        image_copy = image.copy()

    for contour in contours:
        rect = cv2.minAreaRect(contour)
        boxes.append(rect)

        # Overlay bounding box on top of the webcam image
        if DEBUG:
            box = cv2.boxPoints(rect)
            box = np.int0(box)
            cv2.drawContours(image_copy, [box], 0, (0,255,0), 3)

    if DEBUG:
        cv2.imwrite("/tmp/boxes.jpg", image_copy)

    return boxes
```

In `DEBUG = True` mode, we write the bounding boxes over the original image so that it is possible to visually inspect the regions that we have identified in the image as potential candidates that might contain the OTP.

![Step6]({{ "/assets/OTP/step6.jpg" | absolute_url }})

The above image shows the top 10 bounding boxes (by area of bounding rectangle) that we found for the image taken by the webcam.
Only rectangular bounding boxes with width atleast 1.5 times the height were selected. That is the reason we don't see a bounding box aroung the light gray region in the image.

We have successfully found a bounding box around the region containing the OTP.

<br/><br/>

We have come a long way. We now have bounding boxes for potential OTP-containing regions in the original image. All we have to do now is to pass each of those regions separately through an Optical Character Recognition (OCR) algorithm. One of those regions will give us the OTP we are looking for.

Let's look at how to do that in the [next post]({% post_url 2018-01-28-OTP-scanner-3 %}).
