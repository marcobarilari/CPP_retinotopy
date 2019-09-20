# RETINOTOPIC MAPPING STIMULUS

Original verion by [Sam Schwarzkopf](https://sampendu.net/sam-schwarzkopf/) (27th July 2010)

## Depdendencies

| Dependencies                                             | Used version |
|----------------------------------------------------------|--------------|
| [Matlab](https://www.mathworks.com/products/matlab.html) | 20???        |
| or [Octave](https://www.gnu.org/software/octave/)        | 4.?          |
| [Psychtoolbox](http://psychtoolbox.org/)                 | v3.?         |


I use Cogent 2000 to trigger the program via the scanner pulse. This functionality is marked by comments and you can change these parts of the code to suit your needs.

## Running the experiment

### Set up

Before you can begin you will need to generate a checkerboard stimulus with precise dimensions of the screen you are using for your experiment. For this you will need to modify the script `GenCheckerboard.m` and change the variable `width` to the `height` of your screen in pixels. After running this script the new checkerboard stimulus will be saved on your disk.

### Running the retinotoy scripts

Then you will need to modify the `Polar.m` and `Eccen.m` functions.

The parameter `Resolution` needs to be changed to reflect your screen dimensions (e.g. `[0 0 1024 768]` for 1024*768).

The parameters `TR`, `Number_of_Slices` and `Dummies` need to be adjusted for your scanner sequence. Similarly, you will need to adapt the 'Vols_per_Cycle' parameter such that you have enough volumes to fill approximately one minute per stimulus cycle. For example, if your TR is 2 seconds you would want to have 30 volumes per cycle. (Note that shorter cycles work as well, but for inexperienced participants a minute per cycle is probably optimal).

Any of the other parameters probably do not need to be changed at all.

Calling the polar and eccentricity program without any input arguments will run a demo which is triggered manually by pressing a key. The first input argument is the subject name/ID, the second (optional) input argument defines the direction the stimulus is moving (that is either clockwise vs anticlockwise or contracting vs expanding).


## Other scripts

There are also two scripts which can be used for population receptive field mapping. One the one hand, there is the standard protocol with bars traversing the visual field as in Dumoulin & Wandell (2008).

In addition, there is a dual phase-encoded protocol with which you could theoretically map both the polar angle and the eccentricity in the same scan. By including blank periods this could also be used in order to map population receptive fields. I will add a more detailed description of these scripts later.


## Reporting a problem

Get in touch by reporting an issue or sending a pull request

## Contribute

This is the loose style guide used here:
- use PascalCase
- [McCabe complexity](https://en.wikipedia.org/wiki/Cyclomatic_complexity) has to be inferior to 15 (see `checkcode('foo.m', '-cyc')`)
