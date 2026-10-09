# Seismic Horizon Picker & PSDM Viewer

**A MATLAB-based toolkit for interactive visualization, seismic trace-header inspection, and multi-horizon picking and editing on Prestack Depth Migration (PSDM) seismic reflection sections.**

This repository contains two MATLAB programs designed to facilitate the interpretation of depth-migrated seismic reflection data in marine geophysical research.

The toolkit supports SEG-Y data visualization, interactive trace-header inspection, manual horizon picking, multi-horizon editing, and export of interpreted horizons as CMP–Depth text files.

## 1. Overview

Interpreting seismic reflection sections requires accurate identification and tracing of subsurface geological interfaces, such as the seafloor, sedimentary boundaries, faults, basement surfaces, and plate interfaces.

This toolkit provides a lightweight MATLAB-based workflow for visualizing PSDM sections and manually interpreting seismic horizons without requiring a dedicated commercial seismic interpretation platform.

The repository contains two complementary programs:

| Program | Description |
|---|---|
| `plot_psdm_segy_Single.m` | Visualizes PSDM SEG-Y sections and provides interactive amplitude and trace-header inspection. |
| `edit_horizons_from_segy.m` | Provides a graphical interface for creating, loading, editing, and exporting multiple seismic horizons. |

Both programs read seismic amplitudes stored in IBM 32-bit floating-point format.

## 2. Features

### 2.1 PSDM Section Viewer

`plot_psdm_segy_Single.m`

A MATLAB seismic section viewer with interactive trace-header inspection.

**Main features:**

- Direct reading of supported SEG-Y files.
- IBM 32-bit floating-point amplitude conversion.
- Selection of CMP ranges for visualization.
- Configurable trace and sample subsampling.
- Three horizontal coordinate options:
  - CMP number
  - Trace index
  - Along-line distance
- Depth-domain visualization using user-defined vertical sampling intervals.
- Adjustable amplitude clipping based on percentiles.
- Seismic amplitude polarity reversal.
- Custom seismic color mapping.
- Interactive inspection of seismic amplitudes and trace-header information.
- Optional high-resolution PNG export.

**Interactive trace inspection**

Click on the seismic section to select the nearest displayed seismic sample.

The program highlights the selected location and displays:

| Category | Information |
|---|---|
| Sample information | Depth, amplitude |
| Trace identification | CMP number, trace index, trace sequence numbers |
| Acquisition information | Field record, energy source point, trace within field |
| Geometry | Source X/Y, receiver group X/Y, CDP X/Y |
| Coordinate metadata | Coordinate scalar, coordinate units |
| Additional headers | Inline, crossline, shotpoint |
| Sampling metadata | Recording delay, number of samples, sample interval |

Coordinate scaling is applied according to the SEG-Y coordinate scalar.

### 2.2 Interactive Horizon Picker and Editor

`edit_horizons_from_segy.m`

An interactive seismic horizon interpretation tool for PSDM sections.

**Main features:**

- Display PSDM seismic sections in depth.
- Load multiple existing horizons.
- Create new horizons.
- Display several horizons simultaneously with different colors.
- Select the active horizon for editing.
- Add control points interactively.
- Drag existing control points horizontally and vertically.
- Extend horizons from either end.
- Replace incorrectly interpreted horizon segments.
- Delete selected control points.
- Undo editing operations.
- Zoom and navigate through the seismic section.
- Save interpreted horizons as CMP–Depth text files.
- Preserve existing files through a Save As workflow.
- Warn about unsaved modifications before closing.

Only the active horizon is edited, while other loaded horizons remain visible as references.

## 3. Repository Structure

```text
Seismic-Horizon-Picker/
│
├── plot_psdm_segy_Single.m
├── edit_horizons_from_segy.m
├── README.md
├── LICENSE
└── .gitignore
```

The `LICENSE` and `.gitignore` files are optional repository files.

## 4. Requirements

- MATLAB with support for local functions in scripts.
- MATLAB graphical interface support.
- SEG-Y seismic reflection data in IBM 32-bit floating-point format (format code 1).
- Depth-migrated seismic data with a known vertical sampling interval.

The programs use MATLAB built-in functions for binary file reading, numerical processing, visualization, and graphical interaction.

No additional third-party SEG-Y reader is required.

**Important:** The programs are primarily designed for PSDM data. Depth coordinates are calculated from user-defined parameters rather than automatically derived from SEG-Y metadata.

## 5. Installation

1. Download or clone this repository.
2. Open MATLAB.
3. Set the MATLAB current folder to the repository directory.
4. Open the desired `.m` file.
5. Modify the user settings according to your SEG-Y data.
6. Run the script or function.

To clone the repository:

```bash
git clone https://github.com/houukai-spec/Seismic-Horizon-Picker.git
```

Alternatively, download the repository as a ZIP archive from GitHub.

## 6. Usage

### 6.1 Visualizing a PSDM Section

Open:

```matlab
plot_psdm_segy_Single.m
```

Modify the user settings near the beginning of the script.

**Input and output paths**

```matlab
inputSegyPath = "D:\SeismicData\section.sgy";
outputPngPath = "";
```

Set `outputPngPath` to an output filename if you want to export a PNG image.

For example:

```matlab
outputPngPath = "D:\SeismicData\section.png";
```

**CMP selection**

```matlab
cmpMinimum = -Inf;
cmpMaximum = Inf;
```

These parameters define the CMP range to load.

For example:

```matlab
cmpMinimum = 1000;
cmpMaximum = 5000;
```

**Trace and sample subsampling**

```matlab
traceStep  = 1;
sampleStep = 1;
```

A value of `1` reads every trace or sample. Larger values reduce the amount of data loaded and can improve performance when handling large seismic datasets.

**Depth configuration**

```matlab
depthSampleM = 2.0;
firstDepthM  = 0.0;
```

The depth of sample \(i\) is calculated as:

\[
z_i=z_0+(i-1)\Delta z
\]

where:

- \(z_i\) is the depth of sample \(i\), in meters.
- \(z_0\) is the depth of the first sample.
- \(\Delta z\) is the vertical sampling interval.

These values must correspond to the actual vertical sampling of the PSDM data.

**Horizontal axis configuration**

```matlab
xAxisType = "cmp";
```

Available options:

| Value | Horizontal axis |
|---|---|
| `"cmp"` | CMP number |
| `"trace"` | Trace index in the SEG-Y file |
| `"distance"` | Cumulative distance calculated from CDP coordinates, in kilometers |

The distance option assumes that scaled CDP coordinates are expressed in meters in a suitable projected coordinate system.

**Amplitude display**

```matlab
clipPercentile = 99;
polarity = 1;
```

`clipPercentile` controls amplitude saturation using a percentile of absolute amplitude values.

Set `polarity = -1` to reverse the seismic amplitude polarity.

**Image export**

```matlab
pngResolution = 300;
colorMapSize = 256;
```

When a PNG output path is specified, the seismic axes are exported using the configured resolution.

**Run the script**

```matlab
plot_psdm_segy_Single
```

A seismic section window will appear.

Click on the section to examine the nearest displayed sample and its associated trace-header information.

### 6.2 Picking and Editing Seismic Horizons

Open:

```matlab
edit_horizons_from_segy.m
```

**Configure the initial directories**

```matlab
sectionDirectory = "D:\SeismicData";
horizonDirectory = "D:\SeismicData\Horizons";
```

These settings specify the initial directories used by the file-selection dialogs.

**Configure depth sampling**

```matlab
depthSampleM = 2;
firstDepthM = 0;
```

**Configure display limits**

```matlab
maxDisplayTraces = 20000;
maxDisplaySamples = 10000;
```

These parameters limit the number of traces and samples used for visualization.

The original CMP values are retained for horizon output, even when the section display is subsampled.

**Additional settings**

```matlab
clipPercentile = 99;
polarity = 1;
snapDepthToSample = true;
pickRadiusPixels = 10;
maxVisibleMarkers = 100;
```

| Parameter | Description |
|---|---|
| `clipPercentile` | Amplitude clipping percentile |
| `polarity` | Amplitude polarity multiplier |
| `snapDepthToSample` | Snap edited points to the configured depth sampling grid |
| `pickRadiusPixels` | Pixel tolerance for selecting existing points |
| `maxVisibleMarkers` | Controls the approximate density of displayed point markers |

**Run the function**

```matlab
edit_horizons_from_segy
```

The program will prompt you to:

1. Select a PSDM SEG-Y file.
2. Optionally load one or more existing horizon TXT files.
3. Create new horizons or edit loaded horizons.

### 6.3 Horizon Editing Operations

| Operation | Action |
|---|---|
| Add a point | Left-click on the seismic section |
| Select a point | Click near an existing control point |
| Move a point | Click and drag horizontally or vertically |
| Extend a horizon | Add points outside the existing picked range |
| Delete a point | Select a point and press `Delete` |
| Undo | Press `Ctrl+Z` or `Backspace` |
| Save current horizon | Press `Enter` |
| Redraw a segment | Click `重拾区段` (Redraw Segment) |
| Cancel segment selection | Press `Esc` |
| Zoom | Use the mouse wheel or zoom buttons |
| Reset view | Click `全图` (Full View) |

**Redrawing a horizon segment**

To replace an incorrectly interpreted segment:

1. Select the target horizon.
2. Click the Redraw Segment button.
3. Click the first endpoint of the segment.
4. Click the second endpoint.
5. The existing points between the two endpoints will be removed and replaced by the selected endpoints.
6. Add new control points between the endpoints to reconstruct the horizon.

Press `Esc` to cancel the endpoint-selection process.

**Managing multiple horizons**

The horizon list allows switching between different interpretations.

Each horizon is assigned a different display color. Existing horizons remain visible when another horizon is selected.

Unsaved changes are indicated by an asterisk (`*`) in the horizon list.

### 6.4 Saving Horizons

The editor exports horizons in a two-column text format:

```text
CMP    Depth_m
1001   NaN
1002   NaN
1003   2450
1004   2452
1005   2454
1006   2456
1007   NaN
```

The columns represent:

| Column | Description |
|---|---|
| `CMP` | CMP/CDP ensemble number |
| `Depth_m` | Interpreted horizon depth in meters |

Control points are linearly interpolated to the CMP numbers present in the input SEG-Y file.

Mathematically, for two adjacent control points \((x_1,z_1)\) and \((x_2,z_2)\), the interpolated depth is:

\[
z(x)=z_1+\frac{z_2-z_1}{x_2-x_1}(x-x_1)
\]

where \(x\) represents CMP number.

`NaN` values are used for undefined horizon depths, including regions outside the interpreted range. Existing internal `NaN` gaps are retained in the editing workflow.

For newly created horizons, interpolated depths are snapped to the configured depth sampling interval when `snapDepthToSample` is enabled.

For loaded horizons, the software avoids resnapping the entire existing horizon, helping preserve previously stored depth values.

**File protection**

New horizons can be saved to their specified filenames.

When editing an existing horizon, the standard Save operation uses a Save As dialog to help prevent accidental overwriting.

The editor also checks for unsaved modifications before closing.

## 7. SEG-Y Data Format

Both programs directly read seismic data from binary SEG-Y files.

The seismic amplitudes are decoded using IBM 32-bit floating-point conversion.

The decoder uses the IBM floating-point representation:

\[
A=(-1)^s \times f \times 16^{(e-64)}
\]

where:

- \(s\) is the sign bit.
- \(f\) is the fractional mantissa.
- \(e\) is the stored exponent.

The programs use big-endian binary reading.

### Supported data characteristics

| Property | Support |
|---|---|
| SEG-Y binary data | Yes |
| IBM 32-bit floating-point amplitudes | Yes |
| IEEE 32-bit floating-point amplitudes | Not currently decoded |
| CMP/CDP ensemble number | Yes |
| Depth-domain visualization | Yes, with manual depth configuration |
| Trace-header inspection | Viewer |
| Multi-horizon interpretation | Editor |

The horizon editor also accounts for the SEG-Y sample format code when calculating trace size. However, its amplitude decoder is currently implemented for IBM 32-bit floating-point data.

The viewer assumes a conventional 3600-byte initial SEG-Y header and fixed-length traces. The editor additionally reads the extended textual-header count when determining the start of trace data.

Both programs assume a regular trace layout suitable for their respective binary-reading implementations.

## 8. Input and Output

### Input

**Seismic data**

- `.sgy`
- `.segy`

PSDM seismic sections containing supported IBM floating-point amplitudes.

**Existing horizon files**

- `.txt`

Two-column CMP–Depth text files with a header row.

Example:

```text
CMP    Depth_m
1001   2400
1002   2402
1003   2404
```

### Output

**PSDM viewer**

- Interactive seismic figure.
- Optional PNG image.
- MATLAB structure containing amplitude data, depth coordinates, trace indices, selected trace-header fields, and visualization handles.

**Horizon editor**

- CMP–Depth text files containing interpreted horizon depths.
- Undefined regions represented by `NaN`.

The output TXT files can be imported into MATLAB or other software for subsequent analysis and visualization.

## 9. Applications

Potential applications include:

- Interpretation of marine multichannel seismic (MCS) reflection profiles.
- Seafloor and sedimentary horizon identification.
- Mapping of basement reflectors.
- Interpretation of plate-boundary interfaces and décollement structures.
- Geological structural interpretation.
- Preparation of horizon-depth datasets for subsequent geophysical analysis.
- Quality control of PSDM sections and SEG-Y trace headers.

The software is intended primarily for research and educational use.

## 10. Limitations and Notes

1. **Data format:** Both programs currently decode IBM 32-bit floating-point amplitudes. Other SEG-Y sample formats require modifications.

2. **Depth coordinates:** The vertical sampling interval and first-sample depth must be supplied manually. Incorrect settings will produce incorrect depth labels and horizon depths.

3. **Trace geometry:** The programs assume fixed-length traces. The viewer also assumes a conventional 3600-byte header, while the editor supports an extended textual-header count.

4. **Distance calculation:** Along-line distance in the viewer is calculated from consecutive selected CDP coordinates. It requires appropriate coordinate units and geometry.

5. **Display subsampling:** Reducing the number of traces and samples improves visualization performance but may obscure fine seismic structures.

6. **Horizon interpolation:** Horizon depths are interpolated linearly with respect to CMP number, not physical distance.

7. **Horizon editing:** Picking is manual. The current implementation does not perform automated seismic reflector tracking or machine-learning-based horizon detection.

8. **Existing files:** The editor is designed to preserve original horizon files by using a Save As workflow for existing horizons.

9. **Data validation:** Users should verify SEG-Y header definitions, amplitude format, CMP indexing, and depth sampling before scientific interpretation.

## 11. Suggested Workflow

A typical workflow is:

1. Prepare a PSDM SEG-Y section.
2. Open the section using `plot_psdm_segy_Single.m`.
3. Inspect seismic amplitudes, CMP numbering, and trace-header information.
4. Verify depth sampling and polarity.
5. Open the same section using `edit_horizons_from_segy.m`.
6. Load existing horizons or create new interpretations.
7. Pick and refine seismic reflectors.
8. Save each interpreted horizon as a CMP–Depth TXT file.
9. Use the exported horizons for subsequent geological or geophysical analysis.

## 12. Future Development

Possible future extensions include:

- Support for IEEE floating-point SEG-Y data.
- Automatic interpretation of depth coordinates from additional metadata.
- Distance-based horizon export.
- Automatic horizon tracking.
- Semiautomatic seismic reflector picking.
- Integration with machine-learning-based interpretation methods.
- Additional visualization and export options.

These are possible future developments and are not implemented in the current version.

## 13. Contributing

Suggestions, bug reports, and contributions are welcome.

If you encounter issues with SEG-Y compatibility, trace-header interpretation, or horizon editing, please open a GitHub Issue with a description of the problem and the relevant data format.

## 14. License

This project is distributed under the MIT License if the corresponding `LICENSE` file is included in the repository.

See the `LICENSE` file for details.

## 15. Keywords

Seismic Reflection · Marine Geophysics · PSDM · SEG-Y · MATLAB · Seismic Interpretation · Horizon Picking · Trace Headers · Multichannel Seismic · Geological Structure
