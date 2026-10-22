# SIMCOR2 – live demos of the ELL article, Part 2 (the cerebellum)

Live demos accompanying the article:

> Beunis R. (2022). The electrosensory lateral line lobe in mormyrid fish : a stepping stone to the understanding of the cerebellum ? (Part 2/2 : the cerebellum). Zenodo. https://doi.org/10.5281/zenodo.17613147

The programs were written by the author in Visual FoxPro 9.0. The figures and videos of the article were made with them. They are available here in three forms: a web version (runs in any modern web browser, nothing to install), a Python version and the original Visual FoxPro source.

The demos of Part 1 are in the repository [simcor1](https://github.com/rob-beunis/simcor1).


## Live programs

**DECORRELATOR – demos 80–83 (section "From MGC to PuC")**
The decorrelation procedure of Part 1, applied to the Purkinje cell: the iBCM rule, no broad spike, a non-inverted driving signal, and the effect of the Ca-threshold.

- Demo 80 – Fig. 7, p. 34: https://rob-beunis.github.io/simcor2/?demo=80
- Demo 81 – Fig. 8a, p. 34: https://rob-beunis.github.io/simcor2/?demo=81
- Demo 82 – Fig. 8b, p. 34: https://rob-beunis.github.io/simcor2/?demo=82
- Demo 83 – Fig. 8c, p. 34: https://rob-beunis.github.io/simcor2/?demo=83

A chosen demo first shows its settings; it starts with the button "(Re)Start this demo" at the bottom of the panel. The buttons "Interrupt" (then "Resume") and "Stop" interrupt and stop the run. Every run takes a different random course (the random signal S2). Optional additions to the address: `&speed=0.5` (0.25 to 16; at 1x a demo runs twice as fast as the original in Visual FoxPro 9) and `&seed=123` (a reproducible run).

**CONNECTIVITY – demo 4-1 (Addendum "Random connectivity examined"), Fig. 16, p. 59**
https://rob-beunis.github.io/simcor2/connectivity.html

A 4-dimensional input space with 4 values per axis: 256 timeslices, each affected by 256 granule cells with a random input permutation. Four decorrelation runs of 50 iterations, allowing 0, 1, 2 and 3 lacking inputs: a granule cell with a lacking input fires at a wrong address. The buttons "3 / 4 / 5 inputs" start the same runs in 3, 4 or 5 dimensions; with the spinners "Iteration" and "Timeslice" the 256 input permutations of every timeslice can be viewed, also "ordered". "(Re)Start this demo" uses the random numbers of a freshly started Visual FoxPro, so that the run is the one of Fig. 16 and the video.

**RA and WA counts (Addendum)**
https://rob-beunis.github.io/simcor2/counts.html?dims=4&ppv=4,4,4,4&sur=0

Counts of "right addressings" (RAs) and "wrong addressings" (WAs) as a function of the dimensionality of the input space, the number of values (PPVs) per axis and the number of surnumerary dendrites, with an input screen. The source code of this program was published with the article (formerly as a Word file on Dropbox).

Every button has an explanation (tooltip). With a mouse, rest the pointer on the button; on a tablet or phone, press and hold the button for about half a second. The pages count anonymous visits and demo starts with GoatCounter (no cookies, no personal data).


## Contents of this repository

- `index.html` – DECORRELATOR, demos 80–83 (web version, a single self-contained file).
- `connectivity.html` – CONNECTIVITY, demo 4-1 (web version).
- `counts.html` – RA and WA counts (web version).
- `python/decorrelator.py`, `python/connectivity.py`, `python/rawa_counts.py` (with `START_*.bat` files)
  The Python/Tkinter versions. They require Python 3 and Pillow (`pip install pillow`; `rawa_counts.py` needs only Python). Options: `decorrelator.py --demo 81 --speed 0.5 --seed 123`; `connectivity.py --speed 0.5`; `rawa_counts.py --dims 4 --ppv 4,4,4,4 --sur 0` (text to the console instead of the window).
- `vfp/decorrelator.prg` (and `vfp/decorrelator_original_dutch_comments.prg`) – the original DECORRELATOR program, the same as in simcor1: `DO decorrelator WITH "80"`.
- `vfp/connectivity.prg` – the original CONNECTIVITY form: `DO connectivity WITH .T.,"1*I"` (demo 4-1, as in the article reader) or `DO connectivity` (the whole form, also with its right half, which is not used in the article).
- `vfp/rawa_counts.prg` – the original RA/WA counts program, unchanged.

The DECORRELATOR and CONNECTIVITY forms come from the author's article reader, a larger Visual FoxPro program (`CEREBREADER.PRG`), with which the figures and videos were made. They are copied into the stand-alone programs with a short start-up part; changes for these versions are marked with `&& GitHub version:` in the code. The computing itself is unchanged. The VFP programs use fixed pixel positions, as in the article; they look as in the figures on a work area of about 1280 × 720 (for instance a 1920 × 1080 screen at 150 % scaling).


## How the translations were checked

The Python and web versions follow the VFP code procedure by procedure, with the same procedure names, rules and parameters, and the same screen layout as the screenshots in the article. They were checked against runs of the original in Visual FoxPro 9:

- DECORRELATOR: with the same random numbers, identical results (all table values after the first, second, tenth and last iteration, the number of random numbers used, the positions of all line objects, all texts). See simcor1 for the details and the deliberate differences (speed, start button, Interrupt/Stop, demo panel).
- CONNECTIVITY: with 3, 4 and 5 inputs identical averages after iterations 1, 2, 5, 10 and 50, the same number of random numbers, the same combination lists, and the same drawing of the graphs pixel by pixel. Only the left half of the form is translated. At the end of a run, Windows does not show the very last drawing operations of VFP; therefore the last iteration number stays one behind ("49"), as in the video.
- RA and WA counts: for 14 combinations of inputs (1 to 5 dimensions, 0 to 2 surnumerary dendrites, unequal PPVs) the same text, character for character. VFP prints the numbers in fixed-width fields; a number that does not fit is shown there as asterisks or loses its leading digits (for instance with 5 dimensions and 6 PPVs per axis). The translations widen such a field instead, so that every number is shown in full.


## Acknowledgement

The original programs were written by the author in Visual FoxPro 9.0. The translations into Python and into the web versions were made with the assistance of Claude (Anthropic), an AI assistant, under the direction of the author, and were checked against the original programs.


## Author

Rob Beunis, independent researcher (retired clinical neuropsychiatrist), Antwerp, Belgium.
ORCID [0009-0001-0529-2095](https://orcid.org/0009-0001-0529-2095)


## License

MIT, see `LICENSE`.
