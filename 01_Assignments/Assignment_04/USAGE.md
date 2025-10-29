# Panorama Stitching - Updated Usage Guide

## Overview

The code has been updated to **automatically detect and process all image folders** in the `imagesets` directory. You no longer need to hardcode folder names!

## How It Works

### Automatic Folder Detection

- The code scans the `imagesets` folder for all subdirectories
- Each subdirectory is treated as a separate image dataset
- Known datasets use pre-configured parameters
- New/unknown datasets use sensible default parameters

### Default Parameters

For any new image folder not in the known datasets list:

- **Focal length**: 800 pixels (good for typical phone cameras)
- **360° panorama**: No (0)
- **Unordered images**: No (0) - assumes images are in correct sequence

### Known Datasets with Custom Parameters

The following datasets have optimized parameters:

- `ucsb4`, `family_house`, `glacier4`, `yellowstone2`, `GrandCanyon1`
- `yellowstone5`, `yellowstone4`, `west_campus1`, `redrock`, `intersection`
- `GrandCanyon2`

## Usage Examples

### 1. Process All Datasets Automatically

```matlab
% Run panorama stitching on ALL folders in imagesets directory
RunAllDatasets
```

This will:

- Automatically find all image folders
- Process each one sequentially
- Display results in separate figure windows
- Save panoramas to `results/` folder
- Continue processing even if one dataset fails

### 2. Process a Single Dataset by Index

```matlab
% Process the 3rd folder found in imagesets directory
panorama = main(3);
imshow(panorama);
```

### 3. Process a Specific Dataset by Name

```matlab
% Process a specific folder by path
panorama = main('imagesets/ImageSet01');
imshow(panorama);

% Or by full path
panorama = main('imagesets/GrandCanyon1');
imshow(panorama);
```

## Adding New Image Sets

### Step 1: Add Images

Simply create a new folder in the `imagesets` directory:

```
imagesets/
  ├── MyNewPanorama/
  │   ├── img1.jpg
  │   ├── img2.jpg
  │   ├── img3.jpg
  │   └── img4.jpg
  └── ...
```

### Step 2: Run the Code

```matlab
% Automatically processes ALL folders including new ones
RunAllDatasets
```

That's it! No code changes needed.

## Customizing Parameters for Specific Datasets

If the default parameters don't work well for a specific dataset, you can add custom parameters by editing the `known_datasets` struct in `main.m`:

```matlab
known_datasets = struct(...
    'MyNewPanorama', struct('focus', 1200, 'full360', 0, 'unordered', 0), ...
    % ... other datasets
);
```

Parameters:

- **focus**: Focal length in pixels (affects cylindrical warping)
  - Lower (400-600): Wide-angle views
  - Medium (800-1000): Standard camera
  - Higher (1500-2000): Telephoto/zoomed views
- **full360**: Set to 1 for 360° panoramas that should wrap around
- **unordered**: Set to 1 if images are not in sequential order

## Output

Results are saved to:

```
results/
  ├── DatasetName.jpg
  ├── DatasetName_from_unordered.jpg  (if unordered)
  └── ...
```

## Tips

1. **Image Overlap**: Adjacent images should overlap by 30-50%
2. **Camera Motion**: Best results with pure rotation (no translation)
3. **Image Order**: Name images sequentially (img1.jpg, img2.jpg, etc.)
4. **Quality**: Higher resolution images give better results but take longer
5. **Focal Length Tuning**: If panorama looks distorted, adjust the focal length parameter
