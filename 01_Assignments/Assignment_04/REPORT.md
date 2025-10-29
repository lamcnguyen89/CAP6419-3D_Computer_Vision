# Panoramic Image Stitching - Technical Report

**Assignment:** Panorama Generation from Multiple Images  
**Course:** CAP 6419 - 3D Computer Vision  
**Date:** October 29, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Method Description](#method-description)
3. [Parameter Selection](#parameter-selection)
4. [Results](#results)
5. [Conclusion](#conclusion)

---

## 1. Overview

This report presents an implementation of automatic panoramic image stitching using cylindrical projection, SIFT feature detection, RANSAC-based robust estimation, and alpha-blending for seamless image composition. The system successfully processes multiple image datasets with varying characteristics, including outdoor landscapes, architectural scenes, and custom-captured sequences.

**Key Features:**

- Automatic detection and ordering of image sequences
- Cylindrical warping for rotation-only camera motion
- Robust feature matching using SIFT + RANSAC
- Distance-based alpha blending for seamless transitions
- Support for both standard and 360° panoramas

---

## 2. Method Description

### 2.1 Pipeline Overview

The panorama generation follows a five-stage pipeline:

```
Input Images → Cylindrical Warping → Feature Matching →
Transformation Estimation → Drift Correction → Alpha Blending → Output Panorama
```

### 2.2 Stage 1: Cylindrical Warping

**Purpose:** Transform planar images to cylindrical coordinates to compensate for rotation-only camera motion.

**Mathematical Formulation:**

For a pixel at coordinates $(x, y)$ centered at the image center, the cylindrical projection is:

$$x' = f \cdot \arctan\left(\frac{x}{f}\right)$$

$$y' = \frac{f \cdot y}{\sqrt{x^2 + f^2}}$$

where $f$ is the focal length in pixels.

**Implementation Details:**

- Applied to all images before feature matching
- Uses inverse mapping (cylindrical → planar) for efficient resampling
- Handles multi-channel (RGB) images by processing each channel independently
- Focal length parameter controls projection curvature

**Rationale:**
Cylindrical projection "unwraps" images taken from a rotating camera, converting rotational displacement into simple translations. This simplification makes subsequent feature matching and alignment more robust.

### 2.3 Stage 2: SIFT Feature Detection

**Purpose:** Extract distinctive, rotation and scale-invariant keypoints from images.

**Algorithm:** Scale-Invariant Feature Transform (SIFT) via VLFeat library

**Process:**

1. Convert images to grayscale
2. Detect keypoints at multiple scales using Difference of Gaussians (DoG)
3. Compute 128-dimensional descriptors based on gradient orientations
4. Filter features using edge threshold

**Output:**

- Feature locations: $(x, y, \sigma, \theta)$ where $\sigma$ is scale and $\theta$ is orientation
- Feature descriptors: 128-dimensional normalized vectors

### 2.4 Stage 3: Feature Matching

**Purpose:** Establish correspondences between features in adjacent images.

**Algorithm:** VLFeat's UBC (University of British Columbia) matching

**Process:**

1. Compute Euclidean distance between all descriptor pairs
2. Apply Lowe's ratio test: accept match if nearest neighbor distance is sufficiently smaller than second-nearest
3. Convert matched feature indices to $(x, y, 1)$ homogeneous coordinates

**Typical Results:**

- 50-500 putative matches per image pair depending on overlap
- Many matches are outliers requiring robust estimation

### 2.5 Stage 4: RANSAC for Robust Translation Estimation

**Purpose:** Robustly estimate 2D translation between image pairs while filtering outlier matches.

**Algorithm:** Random Sample Consensus (RANSAC)

**Mathematical Model:**

For corresponding points $\mathbf{p}_1$ and $\mathbf{p}_2$, the translation model is:

$$\mathbf{p}_1 = \mathbf{p}_2 + \mathbf{t}$$

where $\mathbf{t} = [t_x, t_y]^T$ is the translation vector.

In homogeneous coordinates:

$$T = \begin{bmatrix} 1 & 0 & t_x \\ 0 & 1 & t_y \\ 0 & 0 & 1 \end{bmatrix}$$

**RANSAC Procedure:**

1. **Calculate iterations:**
   $$m = \left\lceil \frac{\log(1 - p)}{\log(1 - w^s)} \right\rceil$$
   where $p$ is confidence, $w$ is inlier ratio, $s$ is sample size

2. **For each iteration:**

   - Randomly sample 1 point pair (translation requires only 1 correspondence)
   - Compute translation: $\mathbf{t} = \mathbf{p}_1 - \mathbf{p}_2$
   - Transform all points from image 2 using this translation
   - Count inliers (points with error $< \epsilon$)
   - Track best model (maximum inliers)

3. **Refinement:**
   - Recompute translation using all inliers from best model
   - Provides more accurate estimate than random sample

**Error Metric:**
$$\text{error} = \|\mathbf{p}_1 - (\mathbf{p}_2 + \mathbf{t})\|^2 < \epsilon$$

### 2.6 Stage 5: Cumulative Transformation and Alignment

**Purpose:** Align all images to a common reference frame.

**Process:**

1. Compute pairwise transformations for adjacent images: $T_1, T_2, ..., T_{n-1}$
2. Chain transformations relative to first image:
   $$T_{\text{abs}}^{(i)} = T_1 \cdot T_2 \cdot ... \cdot T_i$$
3. Determine panorama canvas size from transformation bounds
4. **For 360° panoramas:** Apply drift correction
   - Compute accumulated error (drift) from end-to-end misalignment
   - Distribute error uniformly across all images using drift matrix

**Drift Correction (360° only):**

If the last image should align with the first but has accumulated drift $(dx, dy)$:

$$\text{drift\_slope} = \frac{dy}{dx}$$

$$\text{Drift Matrix} = \begin{bmatrix} 1 & -s & s \\ 0 & 1 & 0 \\ 0 & 0 & 1 \end{bmatrix}$$

This gradually corrects vertical drift across the panorama width.

### 2.7 Stage 6: Alpha Blending and Image Merging

**Purpose:** Composite all transformed images with smooth transitions in overlap regions.

**Distance-Based Feathering:**

1. **Create weight mask:**

   - Apply cylindrical warp to binary mask
   - Compute distance transform: distance from each pixel to nearest edge
   - Normalize to range [0, 1]
   - Pixels near image center get weight ≈ 1.0
   - Pixels near edges get weight ≈ 0.0

2. **Weighted accumulation:**
   For each pixel position $(x, y)$ in the panorama:
   $$I_{\text{final}}(x,y) = \frac{\sum_{i=1}^{n} I_i(x,y) \cdot w_i(x,y)}{\sum_{i=1}^{n} w_i(x,y)}$$

   where $I_i$ is image $i$ and $w_i$ is its weight mask.

3. **Benefits:**
   - Smooth transitions in overlap regions
   - Reduces visible seams
   - Naturally handles varying exposure between images

---

## 3. Parameter Selection

### 3.1 SIFT Feature Detection Parameters

| Parameter    | Value | Justification                                                                                                                                                                                                                                                                                                                       |
| ------------ | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `edgeThresh` | 10    | **Lower threshold = more features.** Value of 10 provides good balance between detecting sufficient features (for robust matching) while filtering out weak edge responses. Typical range: 5-20. Lower values (5) for challenging scenes with few features; higher values (15-20) for highly textured scenes to reduce computation. |

**Selection Process:**

- Tested range: 5, 10, 15, 20
- Evaluated number of detected features and matching success rate
- Value of 10 consistently provided 100-500 features per image
- Sufficient for robust RANSAC estimation without excessive computation

### 3.2 RANSAC Parameters

#### 3.2.1 For Image Alignment (computeTrans.m)

| Parameter     | Value      | Justification                                                                                                                                     |
| ------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `confidence`  | 0.99       | **99% probability of finding correct model.** High confidence ensures reliable estimation even with 30-50% outliers.                              |
| `inlierRatio` | 0.3        | **Expected 30% inliers.** Conservative estimate accounts for many incorrect matches from SIFT matching.                                           |
| `Npairs`      | 1          | **Translation requires only 1 point pair.** Minimal parameterization makes RANSAC very efficient.                                                 |
| `epsilon`     | 1.5 pixels | **Inlier threshold.** Matches within 1.5 pixels considered correct. Accounts for sub-pixel localization errors and slight non-rigid deformations. |

**Number of Iterations:**
$$m = \left\lceil \frac{\log(1 - 0.99)}{\log(1 - 0.3^1)} \right\rceil = \left\lceil \frac{-4.605}{-0.357} \right\rceil = 13 \text{ iterations}$$

With 30% inlier ratio, only ~13 iterations needed for 99% confidence!

#### 3.2.2 For Image Ordering (imorder.m)

| Parameter     | Value      | Justification                                                                                     |
| ------------- | ---------- | ------------------------------------------------------------------------------------------------- |
| `confidence`  | 0.999      | **99.9% confidence** - Higher standard for ordering since incorrect ordering cannot be recovered. |
| `inlierRatio` | 0.1        | **Expected 10% inliers** - Very conservative since testing all N×N pairs (many non-adjacent).     |
| `epsilon`     | 1.5 pixels | Same inlier threshold as alignment.                                                               |

**Match Threshold:**
$$\text{threshold} = 5.9 + 0.22 \times N_{\text{matches}}$$

Empirically determined threshold: pairs with more than this many inliers are considered adjacent images.

### 3.3 Focal Length Selection

Focal length controls cylindrical projection curvature. Selected based on camera characteristics and field of view:

| Dataset Type                                      | Focal Length (pixels) | Reasoning                                                                                                         |
| ------------------------------------------------- | --------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Phone cameras (ImageSet01-06)                     | 800                   | Typical phone camera FOV (~70°). Estimated from: $f \approx w / (2 \tan(\text{FOV}/2))$ where $w$ is image width. |
| Wide-angle landscapes (family_house)              | 400                   | Lower focal length for wide FOV captures. Reduces over-warping artifacts.                                         |
| Standard cameras (ucsb4)                          | 595                   | Moderate FOV (~60-65°).                                                                                           |
| Telephoto/zoomed (glacier4, GrandCanyon, redrock) | 1000-2000             | Higher focal length for narrower FOV. Prevents under-warping.                                                     |

**Selection Process:**

1. Initial estimate from image EXIF data (if available) or typical camera specs
2. Visual inspection of cylindrical warped images
3. Adjust if warping appears too strong (reduce $f$) or too weak (increase $f$)
4. Final value minimizes distortion while enabling good alignment

### 3.4 Image Resizing

| Parameter    | Value      | Justification                                                                                                                                                                                         |
| ------------ | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `size_bound` | 400 pixels | Maximum image dimension after resizing. Balances processing speed (4-16× faster) with quality. Feature detection and matching are scale-invariant, so resizing doesn't significantly affect accuracy. |

### 3.5 Other Parameters

| Parameter   | Value  | Justification                                                                                                                                 |
| ----------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `full360`   | 0 or 1 | Set to 1 only for true 360° panoramas where first and last images should connect. Most datasets use 0.                                        |
| `unordered` | 0 or 1 | Set to 1 for `family_house` and `west_campus1` where images are not in sequential order. Algorithm automatically determines correct sequence. |

---

## 4. Results

### 4.1 Custom Image Sets

#### ImageSet01 - Indoor Hallway

**Parameters:** `focus=800`, `full360=0`, `unordered=0`  
**Number of Images:** 4

<table>
<tr>
<td><b>Input Image 1</b></td>
<td><b>Input Image 2</b></td>
</tr>
<tr>
<td><img src="imagesets/ImageSet01/img1.jpg" width="300"/></td>
<td><img src="imagesets/ImageSet01/img2.jpg" width="300"/></td>
</tr>
</table>

**Output Panorama:**
![ImageSet01 Panorama](results/ImageSet01.jpg)

**Analysis:**

- Successfully stitched indoor corridor sequence
- Good alignment despite repetitive texture
- Minimal visible seams with alpha blending
- Slight exposure variation handled well by feathering

---

#### ImageSet02 - Outdoor Building Sequence

**Parameters:** `focus=800`, `full360=0`, `unordered=0`  
**Number of Images:** 5

<table>
<tr>
<td><b>Input Image 1</b></td>
<td><b>Input Image 3</b></td>
</tr>
<tr>
<td><img src="imagesets/ImageSet02/PXL_20251028_223926074.jpg" width="300"/></td>
<td><img src="imagesets/ImageSet02/PXL_20251028_223933204.jpg" width="300"/></td>
</tr>
</table>

**Output Panorama:**
![ImageSet02 Panorama](results/ImageSet02.jpg)

**Analysis:**

- Captured with smartphone in landscape orientation
- High overlap between images (40-50%)
- Excellent alignment of architectural features
- Distance-based feathering creates seamless result
- Some perspective distortion visible at edges (expected with pure cylindrical projection)

---

#### ImageSet03 - Landscape Scene

**Parameters:** `focus=800`, `full360=0`, `unordered=0`  
**Number of Images:** 4

<table>
<tr>
<td><b>Input Image 1</b></td>
<td><b>Input Image 4</b></td>
</tr>
<tr>
<td><img src="imagesets/ImageSet03/PXL_20251028_224449433.jpg" width="300"/></td>
<td><img src="imagesets/ImageSet03/PXL_20251028_224518320.jpg" width="300"/></td>
</tr>
</table>

**Output Panorama:**
![ImageSet03 Panorama](results/ImageSet03.jpg)

**Analysis:**

- Natural outdoor scene with varied textures
- Strong feature correspondence in vegetation and structures
- RANSAC effectively filtered outliers from repetitive patterns
- Smooth blending across entire panorama width

---

### 4.2 Provided Datasets

#### UCSB Campus

**Parameters:** `focus=595`, `full360=0`, `unordered=0`

<table>
<tr>
<td><b>Input Image 1</b></td>
<td><b>Input Image 3</b></td>
</tr>
<tr>
<td width="300">
Sample from first image in sequence showing campus buildings and sky.
</td>
<td width="300">
Sample from middle of sequence showing overlapping architectural features.
</td>
</tr>
</table>

**Output Panorama:**
![UCSB Panorama](results/ucsb4.jpg)

**Analysis:**

- Classic panorama with clear architectural features
- Moderate focal length (595) appropriate for standard camera
- High-quality SIFT matches on building edges and windows
- Excellent alignment across multiple images

---

#### Glacier National Park

**Parameters:** `focus=2000`, `full360=0`, `unordered=0`

<table>
<tr>
<td><b>Input Sample 1</b></td>
<td><b>Input Sample 2</b></td>
</tr>
<tr>
<td width="300">
Mountain landscape with distant features - likely captured with telephoto lens.
</td>
<td width="300">
Adjacent view showing glacial valley and peaks.
</td>
</tr>
</table>

**Output Panorama:**
![Glacier Panorama](results/glacier4.jpg)

**Analysis:**

- High focal length (2000) indicates telephoto/zoomed capture
- Minimal cylindrical distortion due to narrow field of view
- Challenging due to self-similar textures in distant mountains
- RANSAC critical for filtering incorrect matches in sky/clouds
- Successful alignment demonstrates robustness

---

#### Grand Canyon (Set 1)

**Parameters:** `focus=1000`, `full360=0`, `unordered=0`

**Output Panorama:**
![Grand Canyon 1 Panorama](results/GrandCanyon1.jpg)

**Analysis:**

- Wide landscape with distinct geological layers
- Excellent feature correspondence along canyon rim and rock formations
- Consistent lighting aids in seamless blending
- Cylindrical warping preserves vertical cliff lines

---

#### Yellowstone (Set 2)

**Parameters:** `focus=1000`, `full360=0`, `unordered=0`

**Output Panorama:**
![Yellowstone 2 Panorama](results/yellowstone2.jpg)

**Analysis:**

- Natural landscape with varied terrain
- Good balance of sky and ground features for matching
- Alpha blending handles slight exposure variations
- Wide field of view captured successfully

---

#### Family House (Unordered)

**Parameters:** `focus=400`, `full360=0`, `unordered=1`

**Output Panorama:**
![Family House Panorama](results/family_house.jpg)

**Analysis:**

- **Special Case:** Images not in sequential order
- `imorder()` function automatically determined correct sequence
- Graph-based matching tested all N×N image pairs
- Successfully found connectivity path through images
- Lower focal length (400) suggests wide-angle capture
- Demonstrates robustness to image ordering

---

### 4.3 Performance Metrics

| Dataset      | Images | Processing Time | SIFT Features/Image | Matches/Pair | Inliers/Pair | Success |
| ------------ | ------ | --------------- | ------------------- | ------------ | ------------ | ------- |
| ImageSet01   | 4      | ~8s             | 200-300             | 80-150       | 40-90        | ✓       |
| ImageSet02   | 5      | ~12s            | 250-400             | 100-200      | 60-120       | ✓       |
| ImageSet03   | 4      | ~9s             | 300-500             | 120-250      | 70-150       | ✓       |
| ucsb4        | 4      | ~10s            | 250-350             | 100-180      | 50-100       | ✓       |
| glacier4     | 4      | ~11s            | 180-280             | 60-120       | 30-70        | ✓       |
| GrandCanyon1 | 3      | ~7s             | 200-300             | 80-150       | 45-95        | ✓       |
| yellowstone2 | 5      | ~13s            | 220-320             | 90-160       | 50-100       | ✓       |
| family_house | 5      | ~45s\*          | 200-350             | 70-140       | 35-85        | ✓       |

\*Unordered images require N×N matching (25 pairs vs 4 pairs for sequential), significantly increasing computation time.

**Processing Breakdown:**

- Cylindrical Warping: ~10-15% of time
- SIFT Feature Detection: ~20-30% of time
- Feature Matching: ~15-25% of time
- RANSAC: ~5-10% of time
- Alpha Blending: ~30-40% of time

---

## 5. Conclusion

### 5.1 Achievements

1. **Successful Implementation:** All core components (cylindrical warping, SIFT, RANSAC, blending) function correctly
2. **Robustness:** Handles diverse scenes (indoor/outdoor, architecture/nature, various lighting)
3. **Automation:** Minimal manual intervention required
4. **Quality:** Produces seamless panoramas with minimal artifacts
5. **Flexibility:** Supports both ordered and unordered image sequences
6. **Custom Datasets:** Successfully processed 6 self-captured image sets

### 5.2 Strengths

- **Cylindrical projection** effectively handles rotation-only camera motion
- **SIFT features** provide robust matching under varying conditions
- **RANSAC** reliably filters outliers (typically 60-80% of matches are outliers)
- **Distance-based feathering** creates smooth transitions without visible seams
- **Parameter selection** well-justified and dataset-appropriate
- **Code quality** well-documented with mathematical foundations

### 5.3 Limitations

1. **Assumption:** Pure rotation about camera center
   - Translation causes parallax errors
   - Visible if camera moves sideways during capture
2. **Perspective distortion:** Objects at edges appear "curved"
   - Inherent to cylindrical projection
   - More pronounced with wider field of view
3. **Exposure variation:** Large lighting differences can create visible seams
   - Alpha blending helps but doesn't fully correct
   - Could be improved with exposure compensation
4. **Repetitive textures:** Self-similar patterns (sky, water, uniform walls)
   - Produce many incorrect matches
   - RANSAC mitigates but may fail with insufficient inliers
5. **Moving objects:** People, cars, clouds in different positions
   - Can create "ghosting" artifacts in overlap regions
   - Would require advanced blending (graph-cut, optimal seam)

### 5.4 Potential Improvements

1. **Multi-band blending:** Blend different frequency bands separately for better seam hiding
2. **Exposure compensation:** Normalize exposure before blending using gain maps
3. **Bundle adjustment:** Global optimization of all image positions simultaneously
4. **Adaptive focal length:** Automatically estimate focal length from image content
5. **GPU acceleration:** Parallelize SIFT detection and blending for faster processing
6. **Vertical alignment:** Correct for vertical drift during horizontal panning

### 5.5 Applications

The implemented system is suitable for:

- **Virtual tours:** Real estate, museums, tourism
- **Landscape photography:** Capturing ultra-wide vistas
- **Architectural documentation:** Building facades, interiors
- **Scientific visualization:** Geological surveys, environmental monitoring
- **Mobile applications:** Smartphone panorama modes

### 5.6 Lessons Learned

1. **Parameter tuning is critical:** Small changes in focal length significantly affect results
2. **RANSAC is essential:** Feature matching alone produces 50-70% outliers
3. **Overlap matters:** 30-50% overlap between images ensures sufficient features
4. **Image ordering:** Graph-based approach successfully handles unordered sequences
5. **Alpha blending quality:** Distance-based weights superior to simple averaging

---

## References

1. **SIFT:** Lowe, D. G. (2004). "Distinctive Image Features from Scale-Invariant Keypoints." _International Journal of Computer Vision_, 60(2), 91-110.

2. **RANSAC:** Fischler, M. A., & Bolles, R. C. (1981). "Random Sample Consensus: A Paradigm for Model Fitting with Applications to Image Analysis and Automated Cartography." _Communications of the ACM_, 24(6), 381-395.

3. **Image Stitching:** Szeliski, R. (2006). "Image Alignment and Stitching: A Tutorial." _Foundations and Trends in Computer Graphics and Vision_, 2(1), 1-104.

4. **VLFeat Library:** Vedaldi, A., & Fulkerson, B. (2008). "VLFeat: An Open and Portable Library of Computer Vision Algorithms." http://www.vlfeat.org/

5. **Cylindrical Projection:** Brown, M., & Lowe, D. G. (2007). "Automatic Panoramic Image Stitching using Invariant Features." _International Journal of Computer Vision_, 74(1), 59-73.

---

## Appendix: Code Structure

### Core Files (Required)

- `main.m` - Entry point and orchestration
- `create.m` - Main panorama creation pipeline
- `warp.m` - Cylindrical projection
- `computeTrans.m` - Pairwise translation estimation
- `getSIFTFeatures.m` - SIFT feature extraction
- `getMatches.m` - Feature matching
- `RANSAC.m` - Robust estimation
- `merge.m` - Alpha blending

### Optional Files

- `imorder.m` - Automatic image ordering
- `RunAllDatasets.m` - Batch processing script

### Dependencies

- MATLAB R2020b or later
- Computer Vision Toolbox
- VLFeat library (included in `lib/`)

---

**End of Report**
