---
layout: post
title: "OTP scanner in Python using OpenCV and Tesseract (Part 3)"
---

In the previous two posts, we have seen how to gather the interesting regions of the image for further analysis. We have gathered the top 10 (by area) bounding boxes, one of which contains the OTP. We now have to crop the image to these bounding boxes, rotate them if need be and perform OCR on the cropped images to see if any of them contain the OTP we are interested in.

![Step6]({{ "/assets/OTP/step6.jpg" | absolute_url }})

<br/><br/>

#### Step 7: Crop and rotate bounding box

In the previous step, we have identified the bounding boxes of interest that could potentially contain the OTP. For each bounding box of interest, we will now rotate the original image captured by the webcam so that the bounding box is horizontal and then crop the image to the bounding box.

```python
# Perform OCR on a single box
def ocr_int(i, box, image):
    center = box[0] # Center of the bounding rectangle
    w, h   = box[1] # Width and height of the bounding rectangle
    angle  = box[2] # Angle of the bounding rectangle
    if w < h:
        w, h = h, w
        angle += 90.0

    rows, cols, _ = image.shape

    # Rotate image
    M       = cv2.getRotationMatrix2D(center, angle, 1)
    rotated = cv2.warpAffine(image, M, (cols, rows))

    # Crop rotated image.
    # Ensure that the crop region lies within the image.
    start_x = int(center[1] - (h * 0.6 / 2))
    end_x   = int(start_x + h * 0.6)
    start_y = int(center[0] - (w * 0.6 / 2))
    end_y   = int(start_y + w * 0.6)
    start_x = start_x if 0 <= start_x < rows else (0 if start_x < 0 else rows-1)
    end_x   = end_x if 0 <= end_x < rows else (0 if end_x < 0 else rows-1)
    start_y = start_y if 0 <= start_y < cols else (0 if start_y < 0 else cols-1)
    end_y   = end_y if 0 <= end_y < cols else (0 if end_y < 0 else cols-1)
    crop    = rotated[start_x:end_x, start_y:end_y]
```

Each bounding box returned by [`cv2.minAreaRect()`](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_contours/py_contour_features/py_contour_features.html#b-rotated-rectangle) in the previous step contains the center of the bounding box, width, height and the angle by which it is rotated in the original image.

In case the logic at the start of the function to determine the width, height and angle of rotation seem a bit weird, it is !!!. It took me a long time to figure it out. I won't go into the details because [this blog](https://namkeenman.wordpress.com/2015/12/18/open-cv-determine-angle-of-rotatedrect-minarearect/) does a pretty good job of explaining the details.

To put it simply, the angle returned by `cv2.minAreaRect()` is always in the interval [-90, 0) i.e, between -90 and 0 degrees not including 0. The function gives -90 degrees if the rectangle it outputs isn't rotated, i.e. the rectangle has two sides exactly horizontal and two sides exactly vertical. As the rectangle rotates clockwise, the angle increases (goes towards zero). When zero is reached, the angle given by the function ticks back over to -90 degrees again (courtesy [stackoverflow](https://stackoverflow.com/questions/15956124/minarearect-angles-unsure-about-the-angle-returned)).

The width and height returned also depend on the angle of rotation. The width is not always longer than the height. The logic at the start of the function calculates the correct width and height of the bounding box and also the angle by which it has to be rotated so that it is horizontal.

```python
center = box[0] # Center of the bounding rectangle
w, h   = box[1] # Width and height of the bounding rectangle
angle  = box[2] # Angle of the bounding rectangle
if w < h:
    w, h = h, w
    angle += 90.0
```

Once we have that sorted out, we rotate the original image by the angle required so that the bounding box we are trying to analyze is horizontal.

```python
# Rotate image
M       = cv2.getRotationMatrix2D(center, angle, 1)
rotated = cv2.warpAffine(image, M, (cols, rows))
```

Once we have rotated the image so that the bounding box is horizontal, we are ready to crop the image to the dimensions of the bounding box.

```python
# Crop rotated image.
# Ensure that the crop region lies within the image.
start_x = int(center[1] - (h * 0.6 / 2))
end_x   = int(start_x + h * 0.6)
start_y = int(center[0] - (w * 0.6 / 2))
end_y   = int(start_y + w * 0.6)
start_x = start_x if 0 <= start_x < rows else (0 if start_x < 0 else rows-1)
end_x   = end_x if 0 <= end_x < rows else (0 if end_x < 0 else rows-1)
start_y = start_y if 0 <= start_y < cols else (0 if start_y < 0 else cols-1)
end_y   = end_y if 0 <= end_y < cols else (0 if end_y < 0 else cols-1)
crop    = rotated[start_x:end_x, start_y:end_y]
```

There is quite a bit going on here. Let me explain.

* The rotated image `rotated` is actually a numpy array of pixel values.

* We know the center of the bounding box and width, height of the bounding box.
  This allows us to determine the two corners of the rectangle as follows.

  ```python
  start_x = int(center[1] - (h * 0.6 / 2))
  end_x   = int(start_x + h * 0.6)
  start_y = int(center[0] - (w * 0.6 / 2))
  end_y   = int(start_y + w * 0.6)
  ```

  Two important things worth mentioning here:

  1. The values returned by OpenCV functions are (width, height) pairs.
     This corresponds to (columns, rows) of the image (if we are talking about the image as a numpy array).
     i.e, width corresponds to columns(y) of the image and height corresponds to rows(x) of the image.

     So, start_x and end_x crop the height of the image whereas start_y and end_y crop the width of the image.
  2. Notice that I have additionally constrained the width and height of the bounding box to six-tenths of the actual width and height. This allows us to zoom in on the actual OTP within the bounding box. This is something that I have tuned for this particular application.

* Finally, the width and height values of the bounding box returned by `cv2.minAreaRect` correspond to the rotated rectangular bounding boxes in the original image. If we were to use these width and height values directly to crop the corresponding region in the rotated image we may end up with values that fall outside the rotated image (negative values or values greater than the size of the rotated image). This is made worse by the fact that python allows negative values for slicing arrays. This leads to a wrong crop. So, the following lines of code restrict the crop region to within the image boundaries even after rotation.

  ```python
  start_x = start_x if 0 <= start_x < rows else (0 if start_x < 0 else rows-1)
  end_x   = end_x if 0 <= end_x < rows else (0 if end_x < 0 else rows-1)
  start_y = start_y if 0 <= start_y < cols else (0 if start_y < 0 else cols-1)
  end_y   = end_y if 0 <= end_y < cols else (0 if end_y < 0 else cols-1)
  ```

<br/>

That's it !!! We now have several cropped regions (one for each of the top 10 bounding boxes by area) from which we will try to extract our OTP.

<br/>

This is what the rotated and cropped region corresponding to the bounding box containing the OTP looks like...

![Step7]({{ "/assets/OTP/step7.jpg" | absolute_url }})

<br/><br/>

#### Step 8: Optical Character Recognition (OCR)

We pass each of our cropped regions (one for each of the top 10 bounding boxes by area) to `pytesseract` (the python interface to `Tesseract`). We then match the output of pytesseract to a regular expression which our OTP is supposed to conform to (we can do this because our OTP is always 6 digits). If any of the outputs from pytesseract match our regular expression, we have found the OTP we are looking for !!!.

However, before we proceed, we will need to pre-process the cropped region obtained in the previous step. `Tesseract` does not do a very good job if the cropped region is passed as it is.

First, we convert the cropped region to grayscale, since we don't need the color information.

```python
# Convert to grayscale
grayscale = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
```

Then, we apply [Adaptive Thresholding](https://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_thresholding/py_thresholding.html?highlight=adaptive#adaptive-thresholding) on the cropped region to convert it into a binary image.

```python
# Convert to a binary image using adaptive thresholding.
threshold = cv2.adaptiveThreshold(grayscale, 255, \
				  cv2.ADAPTIVE_THRESH_GAUSSIAN_C, \
				  cv2.THRESH_BINARY, 1001, 11)
```

In `DEBUG = True` mode, we also write this binary image to /tmp/ for visual inspection.

<br/>

This is what the binary image for the cropped region containing the OTP looks like...

![Step8]({{ "/assets/OTP/step8.jpg" | absolute_url }})

We can immediately see a vast improvement in the clarity of the binary image when compared to the rotated and cropped image in the previous step. `Tesseract` is able to do a much better job on such binary images.

<br/>

And then, the final OCR step.

```python
text = pytesseract.image_to_string(Image.fromarray(threshold, "L"), \
				   config="-psm 7 -c tessedit_char_whitelist=1234567890")
```

Since the text we are looking for is comprised only of digits from 0 to 9, we can pass this information as a whitelist (`tessedit_char_whitelist`) to pytesseract.

Also, since the text we are looking for is in a single line, we also pass the configuration parameter "-psm 7" (see `man tesseract` for details).

Tesseract returns the text it thinks it has found. If no text is found, an empty string is returned. We now compare this text returned by pytesseract to a regular expression which corresponds to two groups of 3 digits possibly separated by a space. If we have a match, then we have successfully found our OTP. This method eliminates all but 1 of the 10 regions we had identified as potentially containing the OTP since `Tesseract` won't be able to find any text which matches this regular expression in those other regions.

```python
r = re.search(r'(\d{3})[ ]?(\d{3})', text)
if r:
    return (r.group(1) + r.group(2))
```


<br/><br/>

__That's it !!!. We have now succesfully extracted the OTP from the image.__

<br/><br/>

In the [next post]({% post_url 2018-01-28-OTP-scanner-4 %}), we shall take a look at how to use the OTP extracted above to automatically login to the VPN and virtual desktop using the `pyautogui` GUI automation library.
