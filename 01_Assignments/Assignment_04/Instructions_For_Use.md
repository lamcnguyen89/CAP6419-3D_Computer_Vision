## **How to Use This Code to Create a Panoramic Image**

This MATLAB script automatically stitches multiple images together to create a panorama. Here's a step-by-step guide:

---

### **Prerequisites**

Before running the code, you need:

1. **MATLAB** with the Computer Vision Toolbox installed
2. **A sequence of overlapping images** taken from the same camera position (more on this below)

---

### **Step 1: Capture Your Images**

**Key Requirements:**

- Take at least **4 overlapping images** of a scene
- Keep the camera in approximately the **same position** (rotate but don't move sideways)
- Each adjacent image should **overlap by 30-50%**
- Use consistent lighting and camera settings

**Example:** Stand in one spot and take 4 photos rotating left to right, each photo overlapping with the previous one.

---

### **Step 2: Organize Your Images**

1. Create a folder named `images` in the same directory as the MATLAB script
2. Name your images consistently, like: `img1.jpg`, `img2.jpg`, `img3.jpg`, `img4.jpg`
3. Images should be ordered from left to right (or right to left)

---

### **Step 3: Configure the Script**

At the top of the script (lines 64-68), adjust these parameters:

```matlab
imageFolder = 'images/';  % Folder with your images
imagePrefix = 'img';      % Prefix of your filenames
imageExt = '.jpg';        % File extension (.jpg, .png, etc.)
numImages = 4;            % How many images you have
referenceIdx = 2;         % Middle image (usually numImages/2)
```

**Example configurations:**

- If your files are `photo1.png`, `photo2.png`, etc.:
  - `imagePrefix = 'photo'`
  - `imageExt = '.png'`
- If you have 6 images:
  - `numImages = 6`
  - `referenceIdx = 3` (use the middle image)

---

### **Step 4: Run the Script**

1. Open MATLAB
2. Navigate to the folder containing Panorama.m
3. Either:
   - Click the **"Run"** button in the MATLAB editor, OR
   - Type `Panorama` in the Command Window and press Enter

---

### **What Happens When You Run It**

The script performs 5 main steps:

#### **1. Load Images** (Lines 79-95)

- Reads all your images from the folder
- Displays their sizes in the console

#### **2. Detect and Match Features** (Lines 97-156)

- Finds distinctive points (corners, edges) in each image
- Matches these points between adjacent images
- Uses RANSAC to filter out bad matches
- This is how the script knows how images align

#### **3. Compute Transformations** (Lines 158-179)

- Calculates the mathematical transformation (homography) needed to align each image
- All transformations are relative to the reference image (middle one)

#### **4. Create the Panorama Canvas** (Lines 181-214)

- Determines how big the final panorama needs to be
- Creates an empty canvas to hold all warped images

#### **5. Warp and Blend Images** (Lines 216-248)

- Transforms each image to align with the reference frame
- Overlaps and blends them together
- Produces the final panorama

---

### **Step 5: View Your Results**

After completion:

- A figure window will display your panorama
- The panorama is automatically saved as `panorama_4_images.jpg` (or whatever number you used)
- Console output shows statistics about the process

---

### **Troubleshooting Common Issues**

| Problem                          | Solution                                                                            |
| -------------------------------- | ----------------------------------------------------------------------------------- |
| **"Image file not found"**       | Check that `imageFolder`, `imagePrefix`, and `imageExt` match your actual filenames |
| **Poor stitching/visible seams** | Images may not overlap enough, or camera moved too much between shots               |
| **Black borders in panorama**    | Normal! These are areas where no image data exists                                  |
| **Not enough matches found**     | Try increasing `numFeatures` (line 71) from 500 to 1000                             |
| **Images don't align**           | Decrease `matchThreshold` (line 72) for stricter matching                           |

---

### **Advanced: Adjusting Parameters**

If the default settings don't work well, you can tune these parameters (lines 71-77):

- **`numFeatures = 500`**: More features = better matching but slower (try 300-1000)
- **`matchThreshold = 10.0`**: Lower = stricter matching (try 5.0-15.0)
- **`maxRatio = 0.7`**: Lowe's ratio test - lower is stricter (try 0.6-0.8)
- **`maxDistance = 1.5`**: RANSAC tolerance in pixels (try 1.0-3.0)

---

### **Example Workflow**

```
1. Take 5 photos of your room, rotating the camera
2. Name them: room1.jpg, room2.jpg, room3.jpg, room4.jpg, room5.jpg
3. Put them in an 'images' folder
4. Set: numImages = 5, referenceIdx = 3, imagePrefix = 'room'
5. Run the script
6. View your panorama in 'panorama_5_images.jpg'
```

---

### **Summary**

This code automates panorama creation by:

1. **Finding matching points** between overlapping images (using SURF features)
2. **Computing how to align** them (using homographies with RANSAC)
3. **Warping and blending** all images into a single wide-angle view

The key is having good overlapping images taken from the same camera position!

lamcnguyen89: Can you make a markdown file documenting what you just said?

GitHub Copilot: I'll create a markdown file documenting the detailed explanation of how to use the panorama code.
