[![](https://img.shields.io/badge/Octave-CI-blue?logo=Octave&logoColor=white)](https://github.com/cpp-lln-lab/CPP_retinotopy/actions)
![](https://github.com/cpp-lln-lab/CPP_retinotopy/workflows/CI/badge.svg)

[![codecov](https://codecov.io/gh/cpp-lln-lab/CPP_retinotopy/branch/master/graph/badge.svg)](https://codecov.io/gh/cpp-lln-lab/CPP_retinotopy)

[![Build Status](https://travis-ci.com/cpp-lln-lab/CPP_retinotopy.svg?branch=master)](https://travis-ci.com/cpp-lln-lab/CPP_retinotopy)

# RETINOTOPIC MAPPING STIMULUS

<!-- vscode-markdown-toc -->

- 1. [Depdendencies](#Depdendencies) \* 1.1. [mpm (beta)](#mpmbeta)
- 2. [Running the experiment](#Runningtheexperiment)
     _ 2.1. [Set up](#Setup)
     _ 2.2. [Running the retinotopy scripts](#Runningtheretinotopyscripts)
- 3. [Other scripts](#Otherscripts)
- 4. [Reporting a problem](#Reportingaproblem)
- 5. [Contributors](#Contributors)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## 1. <a name='Depdendencies'></a>Depdendencies

| Dependencies                                             | Used version |
| -------------------------------------------------------- | ------------ |
| [Matlab](https://www.mathworks.com/products/matlab.html) | 20???        |
| or [Octave](https://www.gnu.org/software/octave/)        | 4.?          |
| [Psychtoolbox](http://psychtoolbox.org/)                 | v3.15        |
| [JSONio](https://github.com/gllmflndn/JSONio)            | NA           |

### 1.1. <a name='mpmbeta'></a>mpm (beta)

You can use [matlab package manager](https://github.com/mobeets/mpm) to install the dependencies.

```matlab
mpm install -i fullpath_to_this_folder/dependencies.txt -c PTB_retinotopy --allpaths
```

## 2. <a name='Runningtheexperiment'></a>Running the experiment

### 2.1. <a name='Setup'></a>Set up

Before you can begin you will need to generate a checkerboard or ripple stimulus with the dimensions of the screen you are using for your experiment. For this, you will need to modify the script `GenCheckerboard.m` or `GenRipples.m` in the `input` folder and change the variable `width` or the `height` of your screen in pixels. After running this script the new checkerboard stimulus will be saved on your disk.

Some other things will need to be changed to match your needs. Most of it should be in :

- `SetParameters.m`
  - The parameter `Resolution` needs to be changed to reflect your screen dimensions (e.g. `[0 0 1024 768]` for 1024\*768).
  - The parameters `TR` and `Dummies` need to be adjusted for your scanner sequence.

In the following

- `Polar.m`
- `Eccen.m`
- `DriftingBar`

you will need to adapt the `VolsPerCycle` parameter such that you have enough volumes to fill approximately one minute per stimulus cycle.

For example, if your TR is 2 seconds you would want to have 30 volumes per cycle. (Note that shorter cycles work as well, but for inexperienced participants a minute per cycle is probably optimal).

### 2.2. <a name='Runningtheretinotopyscripts'></a>Running the retinotopy scripts

Any of the other parameters probably do not need to be changed at all.

Calling the `Polar` and `Eccen` program without any input arguments will run a demo which is triggered manually by pressing a key.

The first input argument is the subject name/ID, the second (optional) input argument defines the direction the stimulus is moving (that is either clockwise vs anticlockwise or contracting vs expanding).

## 3. <a name='Otherscripts'></a>Other scripts

There are also two scripts which can be used for population receptive field mapping. One is the standard protocol with bars traversing the visual field as in Dumoulin & Wandell (2008).

In addition, there is a dual phase-encoded protocol with which you could theoretically map both the polar angle and the eccentricity in the same scan. By including blank periods this could also be used in order to map population receptive fields. This still needs refactoring.

## 4. <a name='Reportingaproblem'></a>Reporting a problem

Get in touch by reporting an issue or sending a pull request

## 5. <a name='Contributors'></a>Contributors

Original version by [Sam Schwarzkopf](https://sampendu.net/sam-schwarzkopf/) (27th July 2010)

For more recent version of the same code () check it here on OSF: [DOI 10.17605/OSF.IO/2RGSM](https://osf.io/2rgsm/)

Some modifications (esp for eye tracking) have been done by [Tim Rohe](https://scholar.google.de/citations?user=mFO_FSAAAAAJ&hl=de).

Code cleaning and refactoring was done by Rémi Gau.

The loose style guide used here:

- use `PascalCase`
- structures that are passed around and centralize a lot of information (TARGET, BEHAVIOUR, PARAMETERS...) are in upper case
- [McCabe complexity](https://en.wikipedia.org/wiki/Cyclomatic_complexity) has to be inferior to 15 (see `checkcode('foo.m', '-cyc')`)
