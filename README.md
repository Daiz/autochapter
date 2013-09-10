# AutoChapter

**AutoChapter** is a node.js module / CLI tool for generating MKV/OGM chapter files out of [Avisynth](http://avisynth.nl/index.php/Main_Page) trims.

## Features

- Calculate chapter points from Avisynth `Trim()` commands
- Snap chapter points to keyframes (XviD & x264 stats files supported)
- Visually verify and adjust chapter points with a browser-based interface (TBD)
- Automatic chapter naming (intended for anime) (TBD)
- Template system for custom chapter naming / ordered chapters (TBD)
- VFR support via MKV timecodes (v1 and v2) (TBD)
- Exports MKV and OGM type chapters (TBD)

## Installation (TBD)

```
npm install -g autochapter
```

# Usage

You should have an Avisynth script with a bunch of trims on a single line, eg.

```
Trim(567,1582)++Trim(1583,4276)++Trim(7880,29031)++Trim(31736,48215)++Trim(48216,50910)
```

AutoChapter will always look for the first line containing a trim command and use it for the chapter generation.