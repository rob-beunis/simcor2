#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DECORRELATOR - Python/Tkinter translation of the DECORRELATOR form of the
author's article reader CEREBREADER.PRG (Dr. R. Beunis, Visual FoxPro 9.0).

The program 'visualizes' the decorrelation procedure of the electrosensory
lateral line lobe (ELL) of mormyrid fish and its implementation variants.  This
copy shows the demos of Beunis R. (2022) "The electrosensory lateral line lobe
in mormyrid fish : a stepping stone to the understanding of the cerebellum ?"
Part 2 (the cerebellum), Zenodo, doi:10.5281/zenodo.17613147: the decorrelation
procedure applied to the Purkinje cell (demos 80-83, Figs. 7 and 8).  The
program is the same as in the repository simcor1 (Part 1).

A signal S3 (the sum of an unchanging signal S1 and a signal S2 that is
different at every iteration) is fed 250 times to a decorrelation procedure.
S4 emerges as the correlated component, S5 as the uncorrelated component; the
yellow histogram shows the 'fit' of S5 to S2 at every iteration.

The translation follows the VFP code procedure by procedure (same names: DEMO,
MEM, STEP, MAKE_S1, MAKE_S2, SUBTRACT, GETPDVALUES, ONECYCLE, ALLCYCLES,
EXECUTE, DRAWALLLINES, DRAWSPECIFICLINE, LBSIGNALTEXT, DISPLAYONCB,
LBPCAPTION, ...).  The tables SIMCOR1..4 and MATRIX become lists; every value
that VFP stores in a table field is rounded the way VFP does it.  The form is
drawn on a raster image (Pillow) with the VFP line objects at the same pixel
positions.  With the same random numbers, the results are identical to those
of the original (checked against runs in Visual FoxPro 9).

Deliberate differences from VFP:
  * RAND() -> a Park-Miller generator.  Reproducing the exact random sequence
    of a VFP run is impossible; with --seed a run is reproducible.
  * The speed of an iteration and of a screen drawing is taken from VFP 9;
    a demo runs twice as fast (only demos 5, 6 and 26 start with the first
    drawing in slow motion, at the speed of VFP).  A demo starts with the
    button '(Re)Start this demo' (VFP waits for a key).  A playback speed
    control, Interrupt/Stop buttons (instead of clicking / right-clicking the
    text box) and a demo panel were added.
  * The parameter table MEM.DBF is not kept between sessions: every demo
    starts from the demo values.
  * Only the modes used in the article are translated: basic simulation
    (MODE 1) and ELL simulation (MODE 2) (and MODE 6).  The eye blink (EBR)
    modes 3..5 belong to other articles.

Usage:
  python decorrelator.py               demo 80
  python decorrelator.py --demo 81     demo 81 (video "demo-1-81" of the article)
  python decorrelator.py --speed 0.5   half speed
  python decorrelator.py --seed 123    reproducible run
"""

import argparse
import math
import re
import sys
import time
from decimal import Decimal, ROUND_HALF_UP

# ======================================================================================
# VFP helpers
# ======================================================================================
_Q = {d: Decimal(1).scaleb(-d) for d in range(0, 12)}


def fld(x, d):
    """REPLACE into a numeric field N(w,d): VFP first rounds the exact binary value to
    d+3 decimals, then that decimal number half away from zero to d decimals."""
    if x != x or x in (float("inf"), float("-inf")):
        return x
    neg = x < 0
    q = Decimal(abs(x)).quantize(_Q[d + 3], rounding=ROUND_HALF_UP)
    n = int(q.scaleb(d + 3))
    r = ((n + 500) // 1000) / 10 ** d
    return -r if neg and r != 0 else r


def vstr(x, length=10, dec=0):
    """STR(): same rounding; fewer decimals when the number does not fit, else asterisks."""
    for dd in range(dec, -1, -1):
        v = fld(x, dd)
        s = "%.*f" % (dd, abs(v))
        if v < 0:
            s = "-" + s
        if len(s) <= length:
            return s.rjust(length)
    return "*" * length


def ltrim(s):
    return s.lstrip(" ")


vint = math.trunc                     # INT(): towards zero


def vround(x, d):                     # ROUND()
    return fld(x, d)


def vval(s):                          # VAL(): the leading number
    import re
    m = re.match(r"\s*([+-]?(\d+\.?\d*|\.\d+))", s)
    return float(m.group(1)) if m else 0.0


def sign(x):
    return (x > 0) - (x < 0)


def park_miller(seed):
    """Park-Miller generator: exact in doubles (also used in the VFP test copy)."""
    s = [seed % 2147483647]
    if s[0] <= 0:
        s[0] += 2147483646

    def rand():
        s[0] = (s[0] * 16807) % 2147483647
        return s[0] / 2147483647
    return rand


# ======================================================================================
# Constants
# ======================================================================================
STEPS, LEFT1, LEFT2, HI = 250, 30, 330, 95
C_ZWART, C_LICHTGRIJS, C_GRIJS, C_WIT = (0, 0, 0), (192, 192, 192), (128, 128, 128), (255, 255, 255)
C_LICHTROOD, C_ROOD, C_DONKERROOD = (255, 128, 128), (255, 0, 0), (128, 0, 0)
C_BLAUW, C_GEEL, C_CYAAN = (0, 0, 255), (255, 255, 0), (0, 255, 255)

MEMFIELDS = [("S1", 0), ("S1JIT", 0), ("S1LIFT", 0), ("S2", 0), ("S2JIT", 0), ("S2LIFT", 0), ("ISI", 0), ("USDUR", 0),
             ("USFORCE", 0), ("S4START", 0), ("AUTOLIFT", 0), ("ILFMAX", 0), ("F3_13", 0), ("F3_4", 0), ("F3_5", 0),
             ("F3_6", 0), ("F3_7", 0), ("IBCM", 0), ("CAP", 1), ("P", 1), ("D", 1), ("P0", 3), ("D0", 2), ("CWA", 0),
             ("WA", 0), ("GFDUR", 0), ("GFDMODE", 0), ("GFTRIG", 0), ("GFTMODE", 0), ("MODE", 0), ("VARIANT", 0),
             ("DEMO", 0), ("PEN", 0), ("CA", 0), ("B", 0), ("N", 0), ("MGCFUC", 0), ("DISPLAY", None), ("TIMES", 0),
             ("DLW", 0), ("STOP", 0), ("SLOW", 0)]
MEMDEC = dict(MEMFIELDS)
PCFIELDS = ["S1", "S1JIT", "S1LIFT", "S2", "S2JIT", "S2LIFT", "ISI", "USDUR", "USFORCE", "S4START", "AUTOLIFT", "ILFMAX",
            "F3_13", "F3_4", "F3_5", "F3_6", "F3_7", "IBCM", "CAP", "P", "D", "P0", "D0", "CWA", "WA", "GFDUR", "GFDMODE",
            "GFTRIG", "GFTMODE", "MODE", "VARIANT", "DEMO", "PEN", "CA", "B", "N", "MGCFUC", "DISPLAY", "TIMES", "DLW",
            "STOP", "SLOW"]
PCOBJECTS = ["SP1_1", "OP1_2", "SP1_3", "SP2_1", "OP2_2", "SP2_3", "SP2_4", "SP2_5", "SP2_6", "SP1_8", "OP2_7", "SP2_8",
             "SP3_1", "SP3_4", "SP3_5", "SP3_6", "SP3_7", "SP3_8", "SP3_9", "SP4_1", "SP4_2", "SP4_3", "SP4_4", "OP4_5",
             "SP4_6", "SP4_7", "SP4_8", "SP4_9", "SP5_9", "SP5_1", "SP5_2", "SP5_3", "OP5_4", "SP5_5", "SP5_6", "SP5_7",
             "SP5_8", "TX6_9"]
BIG = 2147483647
SPINIT = {  # SPDB.Init: [SpinnerLowValue, SpinnerHighValue, Value]
    "SP1_1": [1, 5, 1], "SP2_1": [1, 6, 1], "SP1_3": [0, 200, 0], "SP2_3": [0, 200, 0], "SP1_8": [-1, 200, -1],
    "SP2_4": [0, 250, 0], "SP2_5": [0, 20, 0], "SP2_6": [0, 300, 0], "SP2_8": [0, 10, 1], "SP3_1": [1, 3, 1],
    "SP3_4": [0, 8, 0], "SP3_5": [0, 8, 0], "SP3_6": [0, 1, 0], "SP3_7": [0, 1, 0], "SP3_8": [0, 1, 0],
    "SP3_9": [-300, 300, 0], "SP4_1": [-20, 20, 2], "SP4_2": [-20, 20, 2], "SP4_3": [-10, 10, 0], "SP4_4": [-10, 10, 0],
    "SP4_6": [0, 5, 0], "SP4_7": [1, 250, 0], "SP4_8": [1, 7, 1], "SP4_9": [1, 250, 1], "SP5_1": [1, 7, 1],
    "SP5_2": [0, 70, 0], "SP5_3": [1, 99, 1], "SP5_8": [1, 2, 1], "SP5_9": [0, 3, 1],
    "SP5_5": [-BIG, BIG, 0], "SP5_6": [-BIG, BIG, 0], "SP5_7": [-BIG, BIG, 0]}

# demo settings (PROCEDURE DEMO of the DECORRELATOR form); only the first CASE of a number counts
DEMOS = {
    4: "MGCFUC=1,MODE=1,F3_13=1,S1=1,S2=1,S4START=-1",
    5: "MGCFUC=1,MODE=1,F3_13=1,S1=1,S2=1,S4START=-1,DISPLAY='1234500LF'",
    6: "MGCFUC=1,MODE=1,F3_13=2,S1=1,S2=1,S4START=-1",
    7: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=1,D=1",
    8: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=2,D=2",
    9: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=5,D=5",
    10: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=10,D=10",
    11: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=5,D=2",
    12: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=2,D=5",
    13: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=3,D=2",
    14: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=2,D=3",
    15: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S2JIT=1,S4START=-1,P=2,D=2",
    16: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S1JIT=1,S4START=-1,P=2,D=2",
    17: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=1,CWA=1,P=2,D=2",
    18: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=2,CWA=1,P=2,D=2",
    19: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=5,CWA=1,P=2,D=2",
    21: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=1,CWA=0,P=2,D=2",
    22: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=1,CWA=0,P=4,D=2",
    23: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=2,CWA=0,P=2,D=2",
    24: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=2,CWA=0,P=6,D=2",
    25: "MGCFUC=1,MODE=1,F3_13=1,S1=1,S2=1,S4START=-1",
    26: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,ILFMAX=10,P=2,D=2,SLOW=20",
    27: "MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=3,S4START=0,P=0,D=2,P0=1,D0=1,B=20,N=10,CA=0",
    28: "MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,P=0,D=2,P0=1,D0=1,B=20,N=10,CA=0",
    29: "MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,P=2,D=2,P0=1,D0=1,CAP=20,B=20,N=10,CA=40",
    30: "MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,P=2,D=2,P0=1,D0=1,CAP=40,B=20,N=10,CA=40",
    31: "MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,P=2,D=2,P0=1,D0=1,CAP=55,B=20,N=10,CA=40",
    32: "MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,P=2,D=2,P0=1,D0=1,CAP=55,B=20,N=10,CA=40",
    33: "MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,P=2,D=2,P0=.1,D0=.1,B=20,N=10,CA=40,TIMES=5",
    34: "MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,P=2,D=2,P0=.01,D0=.01,B=20,N=10,CA=40,TIMES=25",
    35: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=30,S2LIFT=30,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    36: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=30,S2LIFT=30,S4START=0,ILFMAX=10,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    37: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=26,S2LIFT=26,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    38: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=25,S2LIFT=25,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    39: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=24,S2LIFT=24,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    40: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=20,S2LIFT=21,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    41: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=20,S2LIFT=20,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    42: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=31,S2LIFT=31,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    43: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=33,S2LIFT=33,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    44: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=35,S2LIFT=35,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    45: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=43,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    46: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=47,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    47: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=0,S1=3,S2=2,S1LIFT=43,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    48: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=30,S2LIFT=30,S4START=0,P=6,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    49: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=29,S2LIFT=29,S4START=0,P=2,D=6,P0=0,D0=0,B=20,N=10,CA=40",
    50: "MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,ILFMAX=2,WA=2,CWA=0,P=6,D=2",
    51: "MGCFUC=1,MODE=2,VARIANT=70,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=50,AUTOLIFT=1,PEN=0",
    52: "MGCFUC=1,MODE=2,VARIANT=45,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=50,AUTOLIFT=1,PEN=0",
    53: "MGCFUC=1,MODE=2,VARIANT=33,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=50,AUTOLIFT=1,PEN=0",
    54: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=29,S2LIFT=29,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40",
    55: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=29,S2LIFT=29,S4START=0,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40,PEN=1,TIMES=2",
    56: "MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=29,S2LIFT=29,S4START=0,ILFMAX=2,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40,PEN=1,TIMES=2",
    80: "MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=1,S4START=0,P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=42",
    81: "MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=2,S4START=0,P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=21",
    82: "MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=2,S4START=0,P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=11",
    83: "MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=2,S4START=0,P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=31"}


class Rec:
    """One record of a SIMCOR table."""
    __slots__ = ("SUMTS", "AVGTS", "LFITH25", "S1VAL", "S2VAL", "S3VAL", "S4VAL", "S5VAL", "S6VAL")

    def __init__(self):
        for f in self.__slots__:
            setattr(self, f, 0.0)


class Line:
    """A vertical VFP Line object (class L): Top, Height (whole pixels), Left, BorderColor."""
    __slots__ = ("top", "height", "left", "color")

    def __init__(self, left):
        self.top, self.height, self.left, self.color = -10, 1, left, C_ZWART


class Obj:
    """A label or a horizontal line of the form."""

    def __init__(self, **kw):
        self.top, self.left, self.height, self.width, self.visible, self.caption, self.color = 0, 0, 0, 0, True, "", C_ZWART
        self.__dict__.update(kw)


# ======================================================================================
# The computing core (DECORRELATOR and DASHBOARD forms)
# ======================================================================================
class Decorrelator:
    def __init__(self, rand=None, height=542):
        import random
        self.rand = rand or random.random
        self.nH = height            # height of the maximized form (author's screen: 542)
        self.cmd = ""               # pcCMD
        self.initForm()

    # ---- PROCEDURE Activate ---------------------------------------------------------------------
    def initForm(self):
        self.pnIC = self.pnL = self.pnCycles = 0
        self.pnSpeed = 3
        self.pnAVMinS1 = self.pnAVMinS4 = self.pnAVMinS2 = self.pnAVMinS5 = self.pnAVMinS3 = 99999
        self.pnMaxLFITH = self.pnMaxFit = self.pnF = self.pnP = self.pnD = self.pnPv = self.pnDv = 0
        self.pnLift1 = self.pnLift2 = self.pnLift3 = self.pnLift4 = self.pnLiftM1 = self.pnLiftM2 = self.pnLiftM3 = 0
        self.pnAVG1 = self.pnAVG2 = self.pnAVG3 = self.pnAVG4 = self.pnAVG5 = self.pnAVG6 = 0
        self.pnAVMaxS2 = self.pnAVMaxS5 = self.pnBShift = self.pnLift = self.pnMRS2 = self.pnMRMAXS2 = 0
        self.pnLiftS1 = self.pnLiftS2 = 0
        self.pnDivS1 = self.pnDivS2 = self.pnDivMax = self.pnR = 1
        self.pnValueSet = self.pnILF = 1
        self.pnHMem = 30
        self.pcILF, self.pcGFDUR, self.pcWA = [], [], []
        self.plBox = self.plBreak = self.plPause = self.plQuit = self.plFlag = self.plEBR = self.plScreenShow = False
        for k in range(1, 9):
            setattr(self, "pnTop%d" % k, 0)
        # LBS[9,8]: 1..7 captions per MODE, 8 = top position, 9 = extra room under the baseline
        self.LBS = [["" for _ in range(9)] for _ in range(10)]
        self.SIMCOR = [None] + [[None] + [Rec() for _ in range(STEPS)] for _ in range(4)]
        self.MATRIX = [None] + [bytearray(STEPS + 1) for _ in range(STEPS)]
        self.MEM = {f: ("" if d is None else 0) for f, d in MEMFIELDS}
        self.L = {}
        for n in ("L1", "L2", "L3", "L6", "L8", "LR41", "LR52", "LR63"):
            self.L[n] = [None] + [Line(i + LEFT1) for i in range(1, STEPS + 1)]
        for n in ("L4", "L5", "L7", "LR14", "LR25", "LR36", "LFIT25"):
            self.L[n] = [None] + [Line(i + LEFT2) for i in range(1, STEPS + 1)]
        O = self.obj = {}
        for k in range(1, 9):
            O["LBS%d" % k] = Obj(left=LEFT1 if k <= 3 else LEFT2, width=STEPS, height=12)
            O["LTA%d" % k] = Obj(left=LEFT2 - 10 if k > 3 else LEFT1 - 10, width=270, color=C_ZWART)
        O["LTC3"] = Obj(left=LEFT1 - 10, width=270, color=C_WIT)
        O["LTB3"] = Obj(left=LEFT1 - 10, width=270, color=C_DONKERROOD)
        O["LTN3"] = Obj(left=LEFT1 - 10, width=270, color=C_BLAUW)
        O["LTC5"] = Obj(left=LEFT2 - 10, width=270, color=C_WIT)
        for n in ("LTCL3", "LTBL3", "LTNL3", "LTCL5"):
            O[n] = Obj(left=5, width=12, height=10, caption=n[0] + n[1:].lower())
        O["LB01"] = Obj(left=LEFT2 + 1, width=STEPS, height=5, visible=False, color=C_LICHTROOD)
        O["LB011"] = Obj(left=LEFT2 + 1, width=STEPS, height=5, visible=False, color=C_WIT)
        O["LB02"] = Obj(left=LEFT2 + 1, width=STEPS, height=5, visible=False, color=C_CYAAN)
        O["LB022"] = Obj(left=LEFT2 + 1, width=STEPS, height=5, visible=False, color=C_WIT)
        O["S5HALT"] = Obj(left=LEFT2 - 10, width=270, visible=False, color=C_GEEL)
        O["LBP"] = Obj(left=LEFT1, width=STEPS, height=180, caption="Decorrelating algorithm")
        O["FIT1"] = Obj(left=LEFT2, width=STEPS, height=30, caption="")
        self.boxes = []
        # dashboard
        self.SP = {k: {"low": v[0], "high": v[1], "value": v[2]} for k, v in SPINIT.items()}
        self.OP = {"OP1_2": 0, "OP2_2": 0, "OP2_7": 0, "OP4_5": 0, "OP5_4": 0}
        self.OPCAP = {"OP1_2": "S1 with jitter", "OP2_2": "S2 with jitter", "OP2_7": "Set autolift on",
                      "OP4_5": "Correlated\raddressings", "OP5_4": "Let PEN adjust B and Ca"}
        self.TX = {"TX6_9": ""}
        self.CB = {"CB" + k[2:]: "Cb" + k[2:] for k in SPINIT}
        self.EN = {}
        self._cV = ""
        self.PNTOP()
        O["LBP"].top = self.nH - O["LBP"].height - 2
        O["FIT1"].top = self.nH - 15
        self.MEMGET()
        self.MEMLIST("")
        self.DASHBOARDCOHERENCE()

    def enabled(self, name):
        return self.EN.get(name, True)

    # REPLACE: SUMTS n(8,2), AVGTS n(10,4), LFITH25 n(10,2), S1VAL..S6VAL n(7,2)
    @staticmethod
    def setS(rec, f, v):
        setattr(rec, f, fld(v, 4 if f == "AVGTS" else 2))

    def setMem(self, f, v):
        d = MEMDEC[f]
        self.MEM[f] = v if d is None else int(fld(v, 0)) if d == 0 else fld(v, d)

    # ==================================================================================
    # STEP: one timeslice
    # ==================================================================================
    def STEP(self):
        M, T1 = self.MEM, self.SIMCOR[1]
        nTimes = 1 if M["MODE"] == 3 else 2 if M["MODE"] == 4 else 4 if M["MODE"] == 5 else 1
        if self.pnL == 0 and (self.pnIC == 0 or M["S1JIT"] == 1 or M["AUTOLIFT"] == 1):
            self.MAKE_S1(1)
            if M["MODE"] in (4, 5, 6):
                self.MAKE_S1(2)
            if M["MODE"] == 5:
                self.MAKE_S1(3)
                self.MAKE_S1(4)
            if M["MODE"] in (3, 4, 5, 6, 7):
                self.MAKE_MATRIX()
        if self.pnL == 0 and (self.pnIC == 0 or (M["MODE"] in (1, 2, 6) and M["S2"] != 6)):
            self.MAKE_S2(1)
            for r in range(1, STEPS + 1):
                self.setS(T1[r], "S3VAL", T1[r].S1VAL + T1[r].S2VAL)
        self.pnL += 1
        pnL = self.pnL
        if M["ILFMAX"] == 1:
            self.pnILF = 1
        elif M["ILFMAX"] > 1:
            self.pnILF = self.pcILF[pnL] / 10
        elif M["ILFMAX"] == 0:
            self.pnILF = 2 if pnL < 125 else 1
        pnILF, pnP, pnD = self.pnILF, self.pnP, self.pnD
        R = T1[pnL]
        if self.pnIC == 0:
            self.setS(R, "AVGTS", R.S3VAL if M["S4START"] == -1 else M["S4START"])
        elif M["MODE"] == 1:                               # basic formulae, P and D in parallel
            if M["F3_13"] == 1:                            # SUM and AVG
                self.setS(R, "SUMTS", R.SUMTS + R.S3VAL)
                self.setS(R, "AVGTS", R.SUMTS / self.pnIC)
            elif M["F3_13"] == 2:                          # AVG derived
                self.setS(R, "AVGTS", R.AVGTS - R.AVGTS * (1 / (self.pnIC + 1)) + R.S3VAL * (1 / (self.pnIC + 1)))
                if pnL == STEPS:
                    self.pnPv = 100 * (1 / self.pnIC)
                    self.pnDv = 100 - 100 * (self.pnIC / (self.pnIC + 1))
            elif M["F3_13"] == 3:                          # fixed P and D
                self.setS(R, "AVGTS", R.AVGTS - R.AVGTS * pnILF * pnD + R.S3VAL * pnP)
                if M["WA"] > 0:
                    self.SCATTERADDRESS(pnP, pnD, R.S3VAL)
        elif M["MODE"] == 2:                               # ELL
            nAVGTS = 0
            nAS = R.AVGTS * pnILF + R.S3VAL                # the 'algebraic summing'
            if M["F3_4"] < 5:
                nAVGTS = nAVGTS + self.NONASSOCP(M["F3_4"], R)
            elif nAS < M["B"]:
                nAVGTS = nAVGTS + self.NONASSOCP(M["F3_4"] - 4, R)
            if M["F3_5"] < 5:
                nAVGTS = nAVGTS + self.NONASSOCD(M["F3_5"], R)
            elif nAS < M["B"]:
                nAVGTS = nAVGTS + self.NONASSOCD(M["F3_5"] - 4, R)
            if M["F3_6"] == 1:                             # BSa-P%
                if nAS >= M["B"] + self.pnBShift and nAS < M["CA"] + self.pnBShift:
                    nAVGTS = nAVGTS + (M["CA"] + self.pnBShift - nAS) * pnP
            if M["F3_7"] == 1:                             # BSa-D%
                if nAS >= M["B"] + self.pnBShift and nAS >= M["CA"] + self.pnBShift:
                    nAVGTS = nAVGTS + (M["CA"] + self.pnBShift - nAS) * pnD
            if M["WA"] > 0:
                self.SCATTERADDRESS_ELL(pnP, pnD, R.S3VAL)
            else:
                self.setS(R, "AVGTS", max(0, R.AVGTS + nAVGTS))
        elif M["MODE"] == 6:                               # PuC
            nS3VAL = R.S3VAL
            for r in range(1, STEPS + 1):
                if not self.MATRIX[r][pnL]:
                    continue
                Q = T1[r]
                nAS = Q.AVGTS * pnILF + nS3VAL
                nAVGTS = 0
                if M["ISI"] <= pnL <= M["ISI"] + M["USDUR"]:
                    nAS = nAS + M["USFORCE"]
                if M["IBCM"] == 1:                         # iBCM rule
                    nAVGTS = nAVGTS + (M["CA"] - nAS) * (pnP if nAS < M["CA"] else pnD)
                else:
                    if M["F3_6"] == 1 and nAS < M["CA"]:
                        nAVGTS = nAVGTS + (M["CA"] - nAS) * pnP
                    if M["F3_7"] == 1 and nAS >= M["CA"]:
                        nAVGTS = nAVGTS + (M["CA"] - nAS) * pnD
                self.setS(Q, "AVGTS", max(0, Q.AVGTS + nAVGTS))
            if pnL == 250:
                for nX in range(1, STEPS + 1):
                    nSynCount, nSynSum = 0, 0
                    for r in range(1, STEPS + 1):
                        if not self.MATRIX[r][nX]:
                            continue
                        nSynSum = nSynSum + min(M["CAP"] if M["F3_4"] == 8 else 300, T1[r].AVGTS)
                        nSynCount += 1
                    nMemS4VAL = T1[nX].S4VAL
                    self.setS(T1[nX], "S4VAL", nSynSum / max(1, nSynCount))
                    if vround(nMemS4VAL, 1) != vround(T1[nX].S4VAL, 1):
                        self.plFlag = True
        for nY in range(1, nTimes + 1):
            T = self.SIMCOR[nY]
            if M["MODE"] in (1, 2, 6):
                if M["ILFMAX"] == 1:
                    self.setS(T[pnL], "S4VAL", T[pnL].AVGTS)
                else:
                    self.setS(T[pnL], "S4VAL", T[pnL].AVGTS * pnILF)
            if pnL == STEPS:
                self.SUBTRACT(nY)
                if M["MODE"] < 4 or nY == nTimes:
                    self.pnIC = max(1, self.pnIC + 1)

    def MAKE_MATRIX(self):
        """MATRIX: for each of the 250 synapses when and how long the GrC fires (modes 3..7)."""
        M = self.MEM
        for r in range(1, STEPS + 1):
            self.MATRIX[r] = bytearray(STEPS + 1)
        for r in range(1, STEPS + 1):
            S = self.MATRIX[r]
            g = M["GFTMODE"]
            nTo = M["GFTRIG"] if g == 1 else self.rand() * M["GFTRIG"] + 1 if g == 2 else \
                self.rand() ** 2 * M["GFTRIG"] + 1 if g == 3 else 1
            nX = 1
            while nX <= nTo:
                g = M["GFDMODE"]
                nGFDUR = M["GFDUR"] if g == 1 else self.rand() * M["GFDUR"] + 1 if g == 2 else \
                    self.rand() * M["ISI"] + 1 if g == 3 else self.rand() * 250 + 1 if g == 4 else \
                    self.rand() ** 2 * M["GFDUR"] + 1 if g == 5 else self.rand() ** 2 * M["ISI"] + 1 if g == 6 else \
                    self.rand() ** 2 * 250 + 1 if g == 7 else M["GFDUR"]
                ln = vint(nGFDUR)
                if M["GFTMODE"] == 0:                      # GrC firing covers all timeslices
                    for k in range(r, min(r + ln, STEPS + 1)):
                        S[k] = 1
                else:
                    for _ in range(10):
                        nMoment = vint(self.rand() * (STEPS - 1)) + 1
                        rng = range(nMoment, min(nMoment + ln, STEPS + 1))
                        if not any(S[k] for k in rng):
                            for k in rng:
                                S[k] = 1
                            break
                nX += 1

    def NONASSOCP(self, nF, R):
        M = self.MEM
        if (nF == 1 and R.AVGTS < 1000) or (nF == 2 and R.AVGTS < M["CAP"]):
            return max(1, R.AVGTS) * M["P0"] * self.pnILF / 100
        if nF == 3 or (nF == 4 and R.AVGTS < M["CAP"]):
            return M["P0"] * self.pnILF
        return 0

    def NONASSOCD(self, nF, R):
        M = self.MEM
        if nF == 2:
            return -max(1, R.AVGTS) * M["D0"] * self.pnILF / 100
        if nF == 4:
            return -M["D0"] * self.pnILF
        return 0

    def SCATTERADDRESS_ELL(self, pnP, pnD, nS3VAL):
        """Pure random addressing in ELL mode (the right signal also goes to a wrong address)."""
        M, T1 = self.MEM, self.SIMCOR[1]
        for _ in range(M["WA"]):
            nRec2 = vint(self.rand() * STEPS + 1)
            Q = T1[nRec2]
            nAVGTS = 0
            if M["F3_5"] == 4:
                nAS = Q.AVGTS * self.pcILF[nRec2] * pnP + nS3VAL if M["ILFMAX"] > 1 else Q.AVGTS * pnP + nS3VAL
                if M["B"] + self.pnBShift <= nAS < M["CA"] + self.pnBShift:
                    nAVGTS = nAVGTS + (M["CA"] + self.pnBShift - nAS) * pnP
            if M["F3_6"] == 1:
                nAS = Q.AVGTS * self.pcILF[nRec2] * pnD + nS3VAL if M["ILFMAX"] > 1 else Q.AVGTS * pnD + nS3VAL
                if nAS >= M["B"] + self.pnBShift and nAS >= M["CA"] + self.pnBShift:
                    nAVGTS = nAVGTS + (M["CA"] + self.pnBShift - nAS) * pnD
            self.setS(Q, "AVGTS", max(0, Q.AVGTS + nAVGTS))

    def SCATTERADDRESS(self, pnP, pnD, nS3VAL):
        """Wrong addressing in basic mode."""
        M, T1, nRec = self.MEM, self.SIMCOR[1], self.pnL
        if M["CWA"] == 0:                                  # no correlation: pure random addressing (RA)
            for _ in range(M["WA"]):
                nRec2 = vint(self.rand() * STEPS + 1)
                Q = T1[nRec2]
                if M["ILFMAX"] > 1:
                    self.setS(Q, "AVGTS", Q.AVGTS - Q.AVGTS * self.pcILF[nRec2] * pnD + nS3VAL * pnP)
                else:
                    self.setS(Q, "AVGTS", Q.AVGTS - Q.AVGTS * pnD + nS3VAL * pnP)
        elif M["CWA"] == 1:                                # the same wrong addresses at every iteration
            for nX in range(1, M["WA"] + 1):
                nRecRand = self.pcWA[(nRec - 1) * M["WA"] + nX]
                s3 = T1[nRecRand].S3VAL
                Q = T1[nRec]
                self.setS(Q, "AVGTS", Q.AVGTS - Q.AVGTS * pnD + s3 * pnP)

    def MAKE_S1(self, k):
        M, T = self.MEM, self.SIMCOR[k]
        nS = 0
        for nL in range(1, STEPS + 1):
            if M["S1"] in (1, 4):
                nS = self.S1BASE(nL)
            elif M["S1"] == 2:
                nS = 0
            elif M["S1"] == 3:
                nS = -self.S1BASE(nL)
            elif M["S1"] == 5 and M["MODE"] == 6:
                nS = 40 if M["ISI"] <= nL <= M["ISI"] + M["USDUR"] else 20
            elif M["S1"] == 5 and M["MODE"] == 3:
                nS = 80 if M["ISI"] <= nL <= M["ISI"] + M["USDUR"] else 40
            self.setS(T[nL], "S1VAL", nS + M["S1LIFT"] + (self.pnLiftS1 if M["AUTOLIFT"] == 1 else 0))
        if M["S1"] == 4:
            self.pnAVG1 = sum(T[r].S1VAL for r in range(1, STEPS + 1)) / STEPS
            for r in range(1, STEPS + 1):
                self.setS(T[r], "S1VAL", T[r].S1VAL - self.pnAVG1)
                self.setS(T[r], "S1VAL", -T[r].S1VAL)
                self.setS(T[r], "S1VAL", T[r].S1VAL + self.pnAVG1)
        for r in range(1, STEPS + 1):
            self.setS(T[r], "S1VAL", T[r].S1VAL / self.pnDivS1)
        self.pnAVG1 = self.MEDIAN("1")

    def MAKE_S2(self, k):
        M, T = self.MEM, self.SIMCOR[k]
        nS = 0
        for nL in range(1, STEPS + 1):
            if M["S2"] in (1, 4, 6):
                nS = self.S2BASE(nL)
            elif M["S2"] == 2:                             # flat
                nS = 0
            elif M["S2"] == 3:
                nS = -self.S2BASE(nL)
            elif M["S2"] == 5 and M["MODE"] == 3:
                nS = 80 if M["ISI"] <= nL <= M["ISI"] + M["USDUR"] else 40
            self.setS(T[nL], "S2VAL", nS + M["S2LIFT"] + (self.pnLiftS2 if M["AUTOLIFT"] == 1 else 0))
            self.pnHMem = nS
        if M["S2"] == 4:
            self.pnAVG2 = sum(T[r].S2VAL for r in range(1, STEPS + 1)) / STEPS
            for r in range(1, STEPS + 1):
                self.setS(T[r], "S2VAL", T[r].S2VAL - self.pnAVG2)
                self.setS(T[r], "S2VAL", -T[r].S2VAL)
                self.setS(T[r], "S2VAL", T[r].S2VAL + self.pnAVG2)
        for r in range(1, STEPS + 1):
            self.setS(T[r], "S2VAL", T[r].S2VAL / self.pnDivS2)
        self.pnAVG2 = self.MEDIAN("2")

    def S1BASE(self, nL):
        M = self.MEM
        return max(1, (abs((nL % 10) - 5) / 40) * 50 + 2 + ((math.sin((nL * 13 - 90) * math.pi / 180) + 1) / 4) * 25 +
                   ((self.rand() - .5) * 5 if M["S1JIT"] == 1 else 0))

    def S2BASE(self, nL):
        M = self.MEM
        a = abs(self.pnHMem)
        w = self.WANDERINGLINE(nL)
        j = (self.rand() - .5) * 10 if M["S2JIT"] == 1 else 0
        return min(30, max(10, a + w * (abs((nL % 10) - 5) / 40) * 50 + j))

    def WANDERINGLINE(self, nX):
        nR = self.rand()
        self.pnR = nR if nX % 5 == 0 else self.pnR
        return self.pnR - .5

    def MEDIAN(self, c):
        """The 125th of the 250 sorted values (always of SIMCOR1)."""
        f = "S%sVAL" % c
        a = sorted(getattr(self.SIMCOR[1][r], f) for r in range(1, STEPS + 1))
        return a[124]

    def SUBTRACT(self, nY):
        """S5 out of S3 and S4, the minima, and the fit."""
        M, T = self.MEM, self.SIMCOR[nY]
        nFit1 = 0
        self.pnAVMinS1 = self.pnAVMinS4 = self.pnAVMinS2 = self.pnAVMinS5 = self.pnAVMinS3 = 99999.00
        self.pnAVMaxS5 = 0
        self.pnMRS2 = 0
        for r in range(1, STEPS + 1):
            R = T[r]
            if M["MODE"] == 6 and M["S2"] == 6:
                self.setS(R, "S5VAL", R.S1VAL + R.S4VAL)
                self.setS(R, "S6VAL", R.S2VAL + R.S4VAL)
            elif M["MODE"] in (1, 3, 4):
                self.setS(R, "S5VAL", R.S3VAL - R.S4VAL)
            elif M["MODE"] == 5:
                self.setS(R, "S5VAL", max(0, R.S3VAL - R.S4VAL))
            else:                                          # in MGCs the apical and basilar output are summed
                self.setS(R, "S5VAL", R.S3VAL + R.S4VAL)
                self.pnAVMaxS2 = max(self.pnAVMaxS2, R.S2VAL)
                self.pnAVMaxS5 = max(self.pnAVMaxS5, R.S5VAL)
            self.pnAVMinS1 = min(self.pnAVMinS1, R.S1VAL)
            self.pnAVMinS4 = min(self.pnAVMinS4, R.S4VAL)
            self.pnAVMinS2 = min(self.pnAVMinS2, R.S2VAL)
            self.pnAVMinS5 = min(self.pnAVMinS5, R.S5VAL)
            self.pnAVMinS3 = min(self.pnAVMinS3, R.S3VAL)
        self.pnLiftM1 = self.pnAVMinS4 - self.pnAVMinS1
        self.pnLiftM2 = self.pnAVMinS5 - self.pnAVMinS2
        self.pnLiftM3 = self.pnAVMinS4 - self.pnAVMinS3
        self.pnLift1 = self.pnAVG4 - self.pnAVG1
        self.pnLift2 = self.pnAVG5 - self.pnAVG2
        self.pnLift3 = self.pnAVG4 - self.pnAVG3
        if M["S2"] == 6:
            self.pnLift4 = self.pnAVG6 - self.pnAVG1
        if M["PEN"] == 1:
            self.pnBShift = max(0, self.pnBShift + (.1 if (self.pnAVMaxS5 - self.pnAVMinS5) > 3 else -.1))
            self.pnMRS2 = max(self.pnMRS2, self.pnAVMaxS2 - self.pnAVMinS2)
            self.pnMRMAXS2 = max(self.pnMRS2, self.pnMRMAXS2)
            O = self.obj
            O["LTC3"].top = vint(self.pnTop3 - self.SP["SP5_5"]["value"] - 1 - self.pnBShift)
            O["LTCL3"].top = O["LTC3"].top - 4
            O["LTB3"].top = vint(self.pnTop3 - self.SP["SP5_6"]["value"] - 1 - self.pnBShift)
            O["LTBL3"].top = O["LTB3"].top - 4
        self.pnAVG3 = self.MEDIAN("3")
        self.pnAVG4 = self.MEDIAN("4")
        self.pnAVG5 = self.MEDIAN("5")
        if M["S2"] == 6:
            self.pnAVG6 = self.MEDIAN("6")
        nfS2VAL = nfS5VAL = 0
        for nL in range(1, STEPS):
            R = T[nL]
            if nL > 1:
                nFit1 = nFit1 + ((nfS2VAL - R.S2VAL) - (nfS5VAL - R.S5VAL)) ** 2
                if M["AUTOLIFT"] == 1 and M["VARIANT"] >= 10 and R.S5VAL < M["VARIANT"]:   # no output of the MGC
                    self.pnLiftS1 = self.pnLiftS1 + .001
                    self.pnLiftS2 = self.pnLiftS2 + .001
            nfS2VAL, nfS5VAL = R.S2VAL, R.S5VAL
        nIC = self.pnIC % 250
        if M["MODE"] in (3, 4, 5):
            if self.plEBR and not self.plFlag:
                self.pnIC = self.pnCycles - 1
            self.obj["FIT1"].caption = "Iterations : " + vstr(self.pnIC + 1, 4)
        else:
            self.obj["FIT1"].caption = "Iterations : " + vstr(self.pnIC + 1, 4) + \
                ("      " + "Fit S2-S5 : " + ltrim(vstr(nFit1, 6, 2)) if "f" not in M["DISPLAY"] else "")
        if 2 <= nIC <= STEPS - 1 and nFit1 < 10000000000:
            self.setS(T[nIC + 1], "LFITH25", nFit1)
        return nFit1

    # ==================================================================================
    # Execution (CB6_x, ALLCYCLES, ONECYCLE), as generator: yields after every iteration
    # ({'drawn': True} when the screen was redrawn)
    # ==================================================================================
    def GETPDVALUES(self):
        if self.pnIC > 0:
            return
        M = self.MEM
        self.pnD = M["D"] / 100
        self.pnP = M["P"] / 100
        self.pcILF = [0] + [vint(self.rand() * (M["ILFMAX"] - 1) * 10 + 10) for _ in range(STEPS)]
        self.pcGFDUR = [0] + [vint(self.rand() * (M["GFDUR"] - 1) + 1) for _ in range(STEPS)]
        self.rand()                                        # RAND(-1)
        self.pcWA = [0] + [vint(self.rand() * STEPS + 1) for _ in range(STEPS) for _ in range(M["WA"])]

    def ONESTEP(self):
        self.STEP()
        if self.pnL == STEPS:
            self.pnL = 0

    def ONECYCLE(self):
        while True:
            self.ONESTEP()
            if self.pnL == 0 or self.plBreak:
                break
        if self.pnSpeed == 2 and (self.pnIC == 1 or self.pnIC / 10 == vint(self.pnIC / 10) or self.pnIC < self.MEM["SLOW"]):
            self.DRAWALLLINES()
            return True
        return False

    def ALLCYCLES(self):
        self.plEBR = False
        DLW = max(1, self.MEM["DLW"])
        for nX in range(self.pnIC + 1, self.pnCycles + 1, DLW):
            self.plFlag = False
            drawn = self.ONECYCLE()
            if nX == 1:
                self.LBPCAPTION()
            yield {"drawn": drawn}
            if self.plBreak:
                break
            if nX == self.MEM["STOP"] or (self.plEBR and not self.plFlag and nX > 5):
                break
        if not self.plQuit:
            self.plBreak = False
            self.DRAWALLLINES()
            self.LBPCAPTION()
            yield {"drawn": True, "end": True}

    def _clear_fit(self):
        for r in range(1, STEPS + 1):
            self.SIMCOR[1][r].LFITH25 = 0
        for i in range(1, STEPS + 1):
            self.L["LFIT25"][i].height = 0

    def CB6_4(self):                                       # execute 250 loops (drawing every 10 loops)
        self.plBreak = False
        self._clear_fit()
        self.pnCycles = self.pnCycles + STEPS
        self.GETPDVALUES()
        self.pnSpeed = 2
        yield from self.ALLCYCLES()
        self.plPause = False

    def CB6_5(self):                                       # execute 250 loops (drawing at the end only)
        self._clear_fit()
        self.pnCycles = self.pnCycles + STEPS
        self.GETPDVALUES()
        self.pnSpeed = 3
        yield from self.ALLCYCLES()
        self.DRAWALLLINES()
        if self.plBox:
            T = self.SIMCOR[1]

            def mn(f):
                return min(getattr(T[r], f) for r in range(1, STEPS + 1))
            self.boxes = [(LEFT1, self.pnTop1, LEFT1 + STEPS + 1, self.pnTop1 - mn("S1VAL")),
                          (LEFT1, self.pnTop2, LEFT1 + STEPS + 1, self.pnTop2 - mn("S2VAL")),
                          (LEFT1, self.pnTop3, LEFT1 + STEPS + 1, self.pnTop3 - mn("S3VAL")),
                          (LEFT2, self.pnTop1, LEFT2 + STEPS + 1, self.pnTop1 - mn("S4VAL"))]
            self.plBox = False
        yield {"drawn": True, "end": True}

    def CB6_3(self):                                       # one loop, fast
        self.plBreak = False
        self.GETPDVALUES()
        self.pnSpeed = 2
        drawn = self.ONECYCLE()
        yield {"drawn": drawn, "end": True}

    def EXECUTE(self):
        """PROCEDURE EXECUTE (called from DEMO)."""
        nTimes = max(1, self.MEM["TIMES"])
        n = vval(self.cmd)
        if n == 4:
            yield from self.CB6_3()
        elif n == 25:
            yield from self.CB6_5()
        elif n > 4:
            for _ in range(nTimes):
                if nTimes < 3:
                    yield from self.CB6_4()
                else:
                    yield from self.CB6_5()
                if self.plQuit:
                    return

    # ==================================================================================
    # Drawing: positions of the line objects (the screen itself is painted by Form)
    # ==================================================================================
    def DRAWALLLINES(self):
        M, T1, O = self.MEM, self.SIMCOR[1], self.obj
        self.pnMaxFit = O["FIT1"].top - O["LBS5"].top - O["LBS5"].height - 5
        self.pnMaxLFITH = max(T1[r].LFITH25 for r in range(1, STEPS + 1))
        self.pnDivMax = vint(self.pnMaxLFITH / self.pnMaxFit) + 1
        nMax4 = nMax5 = 0
        DLW = max(1, M["DLW"])
        last = self.pnIC == self.pnCycles or self.plScreenShow
        for nL in range(1, STEPS + 1, DLW):
            self.DRAWALLLINESOF1STEP(nL)
            if last:
                nMax4 = max(nMax4, self.L["L4"][nL].height)
                nMax5 = max(nMax5, self.L["L5"][nL].height)
        if last and M["MODE"] < 3:
            nLim4 = self.pnTop4 - 2 if M["MODE"] in (3, 4) else 90
            if nMax4 > nLim4:
                for nL in range(1, STEPS + 1):
                    ln = self.L["L4"][nL]
                    ln.height = vint(max(0, ln.height - (nMax4 - nLim4) - 10))
                    ln.top = vint(self.pnTop4 - ln.height - 10)
                    self.L["LR14"][nL].top = vint(self.L["LR14"][nL].top + (nMax4 - nLim4))
            O["LB01"].visible = O["LB011"].visible = nMax4 > nLim4
            nLim5 = 180 if M["MODE"] in (3, 4) else 80
            if nMax5 > nLim5:
                for nL in range(1, STEPS + 1):
                    ln = self.L["L5"][nL]
                    ln.height = vint(max(0, ln.height - (nMax5 - nLim5) - 10))
                    ln.top = vint(self.pnTop5 - ln.height - 10)
                    self.L["LR25"][nL].top = vint(self.L["LR25"][nL].top + (nMax5 - nLim5))
            O["LB02"].visible = O["LB022"].visible = nMax5 > nLim5
        LBS = self.LBS
        for nX in range(1, 6):
            o = O["LBS%d" % nX]
            o.top = vint(LBS[8][nX] + LBS[9][nX])
            if nX in (1, 2) and self.SP["SP%d_1" % nX]["value"] == 3 and self.SP["SP%d_3" % nX]["value"] == 0:
                o.top = vint(LBS[8][nX] - o.height - 5)
            if nX == 3:
                o.top = vint(LBS[8][3] + max(0 if M["S1"] == 3 else LBS[9][1], LBS[9][3]))
            if nX > 1:
                LBS[9][nX] = 0
        self.LBPCAPTION()

    def DRAWALLLINESOF1STEP(self, nL):
        M, R = self.MEM, self.SIMCOR[1][nL]
        self.pnF = 1
        if self.pnIC <= 0:
            return
        D = self.DRAWSPECIFICLINE
        D(self.pnTop2, R.S2VAL, "2", nL, C_CYAAN)
        D(self.pnTop3, R.S3VAL, "3", nL, C_CYAAN)
        D(self.pnTop6 if M["S2"] == 6 else self.pnTop4, R.S4VAL, "4", nL, C_LICHTROOD)
        D(self.pnTop5, R.S5VAL - (self.pnLiftM2 if M["MODE"] == 1 else 0), "5", nL, C_CYAAN)
        if self.pnIC == 1 or self.pnIC == self.pnCycles or M["S1JIT"] == 1 or M["AUTOLIFT"] == 1 or self.plScreenShow:
            D(self.pnTop1, R.S1VAL, "1", nL, C_LICHTROOD)
            if sign(R.S1VAL) == sign(R.S2VAL) or sign(R.S2VAL) == 0:
                D(self.pnTop3, R.S1VAL, "6", nL, C_LICHTROOD)
        if M["S2"] == 6:
            D(self.pnTop4, R.S6VAL, "7", nL, C_LICHTROOD)
            D(self.pnTop4 - (self.AP(R, "1", "6") - self.pnLift4), 2, "R36", nL, C_CYAAN)
            D(self.pnTop1 - (self.AP(R, "6", "1") + self.pnLift4), 2, "R63", nL, C_CYAAN)
        if M["MODE"] not in (3, 7):
            if M["MODE"] == 1:
                D(self.pnTop4 - (R.S1VAL + self.pnLiftM1), 2, "R14", nL, C_CYAAN)    # projection of 1 on 4
                D(self.pnTop1 - (R.S4VAL - self.pnLiftM1), 2, "R41", nL, C_CYAAN)    # projection of 4 on 1
            else:
                D(self.pnTop3 + (-R.S3VAL - R.S4VAL), 2, "8", nL, C_GEEL)
                if M["S2"] == 6:
                    D(self.pnTop6 - (self.AP(R, "3", "4") - self.pnLift3), 2, "R14", nL, C_CYAAN)
                    D(self.pnTop3 - (self.AP(R, "4", "3") + self.pnLift3), 2, "R41", nL, C_ROOD)
                else:
                    D(self.pnTop4 - (self.AP(R, "1", "4") - self.pnLiftM1), 2, "R14", nL, C_CYAAN)
                    D(self.pnTop1 - (self.AP(R, "4", "1") + self.pnLiftM1), 2, "R41", nL, C_CYAAN)
            if M["S2"] == 6:
                D(self.pnTop5 - (self.AP(R, "2", "5") - self.pnLift2), 2, "R25", nL, C_ROOD)
                D(self.pnTop2 - (self.AP(R, "5", "2") + self.pnLift2), 2, "R52", nL, C_ROOD)
            else:
                D(self.pnTop5 - (R.S2VAL + (self.pnLiftM2 if M["MODE"] in (2, 6) else 0)), 2, "R25", nL, C_ROOD)
                D(self.pnTop2 - (R.S5VAL - self.pnLiftM2), 2, "R52", nL, C_ROOD)
        if "f" not in M["DISPLAY"] and M["MODE"] in (1, 2, 6) and nL > 1:
            nT = self.obj["LBP"].top + self.obj["LBP"].height - 15
            D(nT, R.LFITH25 / self.pnDivMax, "FIT25", nL, C_GEEL)

    def AP(self, R, c1, c2):
        """Mirror of S<c1> around the median of S<c2>."""
        nVal = getattr(R, "S%sVAL" % c1)
        nVal = nVal - getattr(self, "pnAVG" + c2)
        nVal = -nVal
        return nVal + getattr(self, "pnAVG" + c2)

    def DRAWSPECIFICLINE(self, nTop, nSVAL, cT, nL, nColor):
        nSVAL = self.pnF * nSVAL
        ln = self.L["L" + cT][nL]
        ln.color = nColor
        if nSVAL >= 0:
            ln.height = vint(nSVAL)
            ln.top = vint(nTop - nSVAL)
        else:
            ln.top = vint(nTop - 1)
            ln.height = vint(-nSVAL)
        nT = vval(cT.replace("R", ""))
        if 1 <= nT <= 5:
            nT = int(nT)
            self.LBS[9][nT] = max(self.LBS[9][nT] or 0, -min(0, nSVAL))

    # ==================================================================================
    # DEMO, MEM and the dashboard
    # ==================================================================================
    def DEMO(self, nDemo):
        self.cmd = str(nDemo)
        for f, v in (("TIMES", 0), ("AUTOLIFT", 0), ("PEN", 0), ("VARIANT", 0), ("S1JIT", 0), ("S2JIT", 0),
                     ("S1LIFT", 0), ("S2LIFT", 0), ("WA", 0), ("CWA", 0), ("ILFMAX", 1), ("ISI", 0), ("USDUR", 0),
                     ("USFORCE", 0), ("GFDUR", 1), ("GFDMODE", 1), ("GFTRIG", 1), ("GFTMODE", 0), ("DLW", 1),
                     ("STOP", 0), ("CAP", 1000), ("SLOW", 0), ("IBCM", 0), ("DISPLAY", "12345000LF"), ("F3_4", 0),
                     ("F3_5", 0), ("F3_6", 0), ("F3_7", 0), ("S1", 1), ("S2", 1)):
            self.setMem(f, v)
        self.plBox = False
        if nDemo == 25:                    # boxes added: DEMO executes CB6_5 itself and returns
            self.plBox = True
            self.MEMLIST(DEMOS[25])
            return
        if nDemo in DEMOS:
            self.MEMLIST(DEMOS[nDemo])
        self.SP["SP5_3"]["value"] = nDemo
        self.DASHBOARDCOHERENCE()

    def MEMLIST(self, cList):
        """PROCEDURE MEM(cList): field=value list -> MEM.DBF and dashboard."""
        self.DASHBOARDCOHERENCE()
        for it in [s for s in cList.split(",") if s]:
            p = it.find("=")
            if p <= 0:
                break
            cName, cValue = it[:p], it[p + 1:]
            nValue = max(vval(cValue), vval(cValue.replace(".", ",")))   # VAL with '.' and with ','
            idx = PCFIELDS.index(cName) if cName in PCFIELDS else -1
            cObj = PCOBJECTS[idx] if 0 <= idx < len(PCOBJECTS) else ""
            if cObj.startswith("SP"):
                self.SP[cObj]["value"] = nValue
                self.DISPLAYONCB(cObj)
            elif cObj.startswith("OP"):
                self.OP[cObj] = nValue
            elif cObj.startswith("TX"):
                self.TX[cObj] = cValue.replace("'", "")
            if MEMDEC[cName] is None:
                self.setMem(cName, cValue.replace("'", ""))
            else:
                self.setMem(cName, nValue)
        self.MEMGET()
        self.DASHBOARDCOHERENCE()
        self.LBPCAPTION()

    def MEMGET(self):
        for o, f in zip(PCOBJECTS, PCFIELDS):
            nV = self.MEM[f]
            if o.startswith("SP"):
                sp = self.SP[o]
                if sp["low"] <= nV <= sp["high"]:
                    sp["value"] = nV
                else:
                    sp["value"] = abs(sp["low"])
                    self.setMem(f, sp["value"])
                self.DISPLAYONCB(o)
            elif o.startswith("OP"):
                self.OP[o] = nV
            else:
                self.TX[o] = nV

    def DASHBOARDCOHERENCE(self):
        m = self.SP["SP5_1"]["value"]
        lC1, lC2, lC3 = m == 1, m == 2, m in (3, 4, 5, 6, 7)
        us = self.SP["SP2_5"]["value"] > 0
        self.EN.update({"CB2_4": lC3, "CB2_5": lC3, "CB2_6": lC3, "OP2_7": lC2, "CB3_1": lC1, "CB3_4": not lC1,
                        "CB3_5": lC3, "CB3_6": not lC1, "CB3_7": not lC1, "CB3_8": not lC1, "CB3_9": not lC1,
                        "CB4_3": not lC1, "CB4_4": not lC1, "CB4_7": lC3, "CB4_8": lC3 and us, "CB4_9": lC3,
                        "CB5_9": lC3 and us, "OP5_4": lC2, "CB5_6": lC2, "CB5_7": lC2})
        self.PNTOP()
        self.LBSIGNALTEXT()
        return ""

    def PNTOP(self):
        self.pnTop1, self.pnTop2, self.pnTop3 = 1 * HI, 2 * HI, 3 * HI
        if getattr(self, "SP", None) and self.SP["SP5_3"]["value"] == 51:
            self.pnTop3 = 3 * HI + 30
        self.pnTop4, self.pnTop5, self.pnTop6, self.pnTop7, self.pnTop8 = 1 * HI, 2 * HI, 3 * HI, 4 * HI, 5 * HI
        if getattr(self, "obj", None):
            self.obj["LB01"].top, self.obj["LB011"].top = self.pnTop4 - 5, self.pnTop4 - 10
            self.obj["LB02"].top, self.obj["LB022"].top = self.pnTop5 - 5, self.pnTop5 - 10

    def LBSIGNALTEXT(self):
        M, LBS, O = self.MEM, self.LBS, self.obj
        LBS[1][1] = "S1 : Same signal repeated for every iteration\rModulation of S4 projected over S1"
        LBS[1][2] = "S2 : Random signal different for every iteration\rModulation of S5 projected over S2"
        LBS[1][3] = "S3 : The sum of S1 and S2, will serve as input\r250 timeslices"
        LBS[1][4] = "S4 : Time-correlated component filtered out of S3\rModulation of S1 projected over S4"
        LBS[1][5] = "S5 : Time-uncorrelated component (S3-S4+constant)\rModulation of S2 projected over S5"
        cC1a = "flat" if M["S1"] == 2 else "inverted CC of the DS (iCC)" if M["S1"] == 3 else \
            "antiphased CC of the DS (iCC)" if M["S1"] == 4 else "CC of the DS"
        cC1b = "flat" if M["S1"] == 2 else "iCC" if M["S1"] > 2 else "CC"
        cC2a = "flat" if M["S2"] == 2 else "inverted UC of the DS (iUC)" if M["S2"] == 3 else \
            "antiphased UC of the DS (iUC)" if M["S2"] == 4 else "UC of the DS"
        cC2b = "flat" if M["S2"] == 2 else "iUC" if M["S2"] > 2 else "UC"
        nLift1 = vround(self.pnLiftS1, 0) + M["S1LIFT"] if M["VARIANT"] >= 10 else M["S1LIFT"]
        nLift2 = vround(self.pnLiftS2, 0) + M["S2LIFT"] if M["VARIANT"] >= 10 else M["S2LIFT"]

        def lift(n):
            return "" if n == 0 else " + excitatory lift of " + ltrim(vstr(n))
        LBS[2][1] = "S1 : " + cC1a + lift(nLift1)
        LBS[2][2] = "S2 : " + cC2a + lift(nLift2)
        cC3 = cC2b if cC1b.startswith("flat") else cC1b if cC2b.startswith("flat") else "iDS" if "i" in cC1b + cC2b else "DS"
        cC1ib = ("i" + cC1b).replace("ii", "").replace("iflat", "flat")
        LBS[2][3] = ("S3 : " + cC1b + " + " + cC2b + " = " + cC3 + "\rSummed basilar output" + lift(nLift1 + nLift2)).replace("flat + flat = ", "")
        LBS[2][4] = "S4 : SUM(ApO) evolving to " + cC1ib
        LBS[2][5] = ("S5 : SUM(ApO) + " + cC3 + " evolving to " + cC2b + "\r(" + cC1ib + " + " + cC3 + " = " + cC2b + " when successful)" +
                     ("\rSUM(ApO) annulling the " + cC1b + " in the " + cC3 if not cC2b.startswith("flat") else "")).replace("\r(flat + flat = flat)", "")
        LBS[6][1] = "S1 : " + cC1a + lift(nLift1)
        LBS[6][2] = "S2 : " + cC2a + lift(nLift2)
        LBS[6][3] = ("S3 : " + cC1b + " + " + cC2b + " = " + cC3 + "\rCC + UC = DS (AF input)" + lift(nLift1 + nLift2)).replace("flat + flat = ", "")
        LBS[6][4] = "S4 : ILF*aSS evolving to " + cC1ib
        LBS[6][5] = ("S5 : ILF*aSS + " + cC3 + " evolving to " + cC2b + "\r(" + cC1ib + " + " + cC3 + " = " + cC2b + " when successful)" +
                     ("\rILF*aSS annulling the " + cC1b + " in the " + cC3 if not cC2b.startswith("flat") else "")).replace("\r(flat + flat = flat)", "")
        if M["S1"] == 5:
            LBS[6][1] = "S1 : DS = CS signal with added US surge"
            LBS[6][2] = "S2 : " + cC2a + lift(nLift2)
            LBS[6][3] = "S3 = S1"
            LBS[6][4] = "S4 : negative image of the DS when successful"
            LBS[6][5] = "S5 : PuC activity profile when successful"
        LBS[3][3], LBS[3][6] = "(S3) CS-Tone signal + US signal", "(S4) SUM(ApO) / PuC activity"
        LBS[4][1], LBS[4][2], LBS[4][4], LBS[4][8] = "(S3) CS-tone signal", "(S3) CS-light signal", \
            "(S4) PuC reaction on CS-tone", "(S4) PuC reaction on CS-light"
        LBS[7][1], LBS[7][2], LBS[7][3] = "S1", "S2", "S1 + S2"
        LBS[7][4] = "-S1 = S2 - (S1 + S2) , delivered by the PuC as S1"
        LBS[7][5] = "-S2 = S1 - (S1 + S2) , delivered by the PuC as S2"
        LBS[7][6] = "- (S1 + S2)"
        mode = self.SP["SP5_1"]["value"]
        for nX in range(1, 9):
            o = O["LBS%d" % nX]
            o.caption = LBS[mode][nX] if 1 <= mode <= 7 else ""
            o.height = 12 * (o.caption.count("\r") + 1)
        if M["S2"] == 6:
            for nX in range(1, 7):
                o = O["LBS%d" % nX]
                o.caption = LBS[7][nX]
                o.height = 12 * (o.caption.count("\r") + 1)
        for nX in range(1, 9):
            LBS[8][nX] = getattr(self, "pnTop%d" % nX) + 2
            O["LBS%d" % nX].top = LBS[8][nX]
            LBS[9][nX] = 0
        lC2 = mode in (2, 6)
        for n in ("LTC3", "LTCL3", "LTB3", "LTBL3", "LTN3", "LTNL3", "LTC5", "LTCL5", "S5HALT"):
            O[n].top = -10
        ca, b, n_ = self.SP["SP5_5"]["value"], self.SP["SP5_6"]["value"], self.SP["SP5_7"]["value"]
        for nX in range(1, 9):
            nY = getattr(self, "pnTop%d" % nX)
            if nX in (3, 5):
                O["LTC%d" % nX].top = nY - ca - 1 if lC2 else -10
                O["LTCL%d" % nX].top = nY - ca - 5 if lC2 else -10
                O["LTCL%d" % nX].caption = "Ca"
                O["LTCL%d" % nX].visible = ca > 0
                if nX == 5:
                    O["LTCL5"].left = LEFT2 - 27
            if nX == 3 and mode == 2:
                O["LTB3"].top = nY - b - 1 if lC2 else -10
                O["LTBL3"].top = nY - b - 5 if lC2 else -10
                O["LTBL3"].caption = "B"
                O["LTN3"].top = nY - n_ - 1 if lC2 else -10
                O["LTNL3"].top = nY - n_ - 5 if lC2 else -10
                O["LTNL3"].caption = "N"
            O["LTA%d" % nX].top = nY - 1
        self.pnMaxFit = O["FIT1"].top - O["LBS5"].top - O["LBS5"].height - 5
        for nX in range(1, STEPS + 1):
            self.L["L6"][nX].left = nX + (LEFT1 if M["MODE"] in (1, 2, 6) else LEFT2)
        for nX in range(1, 9):
            O["LBS%d" % nX].visible = O["LTA%d" % nX].visible = False
        O["S5HALT"].visible = False
        if M["S2"] == 6:
            for nX in range(1, 7):
                O["LBS%d" % nX].visible = O["LTA%d" % nX].visible = True
        else:
            for nX in range(1, 9):
                if M["MODE"] in (1, 2, 6, 7) and nX in (6, 7, 8):
                    continue
                if M["MODE"] == 3 and nX in (1, 2, 3, 4, 5, 7, 8):
                    continue
                if M["MODE"] == 4 and nX in (3, 6, 7, 8):
                    continue
                if M["MODE"] == 5:
                    continue
                O["LBS%d" % nX].visible = O["LTA%d" % nX].visible = True
        if M["AUTOLIFT"] == 1:
            O["S5HALT"].visible = True
            O["S5HALT"].top = self.pnTop2 - M["VARIANT"]

    def DISPLAYONCB(self, name):
        """Caption of the dashboard button next to a spinner."""
        nL, nT, SP, CB = int(name[2]), int(name[4]), self.SP, self.CB

        def v(n):
            return SP[n]["value"]

        def s(x, ln=10, d=0):
            return ltrim(vstr(x, ln, d))
        if nL == 1:
            if nT == 1:
                nV = v("SP1_1")
                CB["CB1_1"] = "S1 " + {1: "modulated", 2: "flat", 3: "inverted", 4: "antiphased",
                                       5: "with US surge at " + s(v("SP2_4"))}.get(nV, "")
            elif nT == 3:
                CB["CB1_3"] = "Lift S1 = " + s(v("SP1_3"))
            elif nT == 8:
                CB["CB1_8"] = "Start with S4 = S3" if v("SP1_8") == -1 else "Start with S4 = " + s(v("SP1_8"))
        elif nL == 2:
            if nT == 1:
                CB["CB2_1"] = "S2 " + {1: "modulated", 2: "flat", 3: "inverted", 4: "antiphased",
                                       5: "predefined for virtual US", 6: "modulated but unchanging"}.get(v("SP2_1"), "")
            elif nT == 3:
                CB["CB2_3"] = "Lift S2 = " + s(v("SP2_3"))
            elif nT == 4:
                CB["CB2_4"] = "US at timeslice " + s(v("SP2_4"))
                CB["CB2_5"] = "US duration = " + s(v("SP2_5"))
                CB["CB2_6"] = "US-CF force excess = " + s(v("SP2_6"))
            elif nT == 8:
                nV = v("SP2_8")
                CB["CB2_8"] = "ILF=2 when ic<=125, ILF=1 when ic>125" if nV == 0 else "Input load factor maximum = " + s(nV)
        elif nL == 3:
            CB["CB3_1"] = {1: "SUM and AVG", 2: "AVG derived", 3: "P and D in parallel and as set"}.get(v("SP3_1"), "")
            cnaP = s(v("SP4_3"), 6, 3)
            nCap = v("SP3_9")
            cCap = "capped at " + s(nCap) if nCap >= 0 else "capped at " + s(-nCap * 2) + "\rPuC-capped at " + s(-nCap)
            opts = ["NO na-P", "na-P = " + cnaP + "%\rnon capped", "na-P = " + cnaP + "%\r" + cCap,
                    "na-P = " + cnaP + " constant\rnon capped", "na-P = " + cnaP + " constant\r" + cCap,
                    "neg-BSa-P = " + cnaP + "%\rnon capped", "neg-BSa-P = " + cnaP + "%\r" + cCap,
                    "neg-BSa-P = " + cnaP + " constant\rnon capped", "neg-BSa-P = " + cnaP + " constant\r" + cCap]
            nV = v("SP3_4")
            cV = opts[int(nV)] if nV == int(nV) and 0 <= nV <= 8 else self._cV
            CB["CB3_4"] = cV.replace("BS", "CF") if v("SP5_1") >= 3 else cV
            cnaD = s(v("SP4_4"), 5, 2)
            dv = {0: "NO na-D", 2: "na-D = " + cnaD + "%", 4: "na-D = " + cnaD + " constant",
                  6: "neg-BSa-D = " + cnaD + "%", 8: "neg-BSa-D = " + cnaD + " constant"}.get(v("SP3_5"))
            if dv is not None:
                cV = dv
            CB["CB3_5"] = cV.replace("BS", "CF") if v("SP5_1") >= 3 else cV
            cP, cD = s(v("SP4_1"), 5, 1), s(v("SP4_2"), 5, 1)
            nV = v("SP3_8")
            if nV == 0:
                cV = "NO iBCM rule"
            elif nV == 1:
                cV = "WITH iBCM rule"
            CB["CB3_8"] = cV
            if nV == 1:
                SP["SP3_6"]["value"] = 2
                SP["SP3_7"]["value"] = 2
            both = "BSa-P = " + cP + "%\riBCM rule\rBSa-D = " + cD + "%"
            cV = {0: "NO BSa-P", 1: "BSa-P = " + cP + "%", 2: both}.get(v("SP3_6"), cV)
            CB["CB3_6"] = cV.replace("BS", "CF") if v("SP5_1") >= 3 else cV
            cV = {0: "NO BSa-D", 1: "BSa-D = " + cD + "%", 2: both}.get(v("SP3_7"), cV)
            CB["CB3_7"] = cV.replace("BS", "CF") if v("SP5_1") >= 3 else cV
            self._cV = cV
        elif nL == 4:
            CB["CB4_1"] = "P% = " + s(v("SP4_1"), 4, 1)
            self.DISPLAYONCB("SP3_5")
            CB["CB4_2"] = "D% = " + s(v("SP4_2"), 4, 1)
            self.DISPLAYONCB("SP3_6")
            CB["CB4_3"] = "na-P = " + s(v("SP4_3"), 6, 3)
            self.DISPLAYONCB("SP3_4")
            CB["CB4_4"] = "na-D = " + s(v("SP4_4"), 5, 2)
            self.DISPLAYONCB("SP3_4")
            nCap = v("SP3_9")
            CB["CB3_9"] = "Synaps capping at " + s(nCap) if nCap >= 0 else "PuC capping at " + s(-nCap)
            self.DISPLAYONCB("SP3_4")
            CB["CB4_6"] = s(v("SP4_6")) + " wrong addressings"
            cV = s(v("SP4_7"))
            CB["CB4_7"] = "GFD = " + cV
            CB["CB4_8"] = "GrC burst duration =\r" + {1: cV, 2: "RAND(1-" + cV + ")", 3: "RAND(1-ISI)", 4: "RAND(1-250)",
                                                       5: "RAND^2(1-" + cV + ")", 6: "RAND^2(1-ISI)",
                                                       7: "RAND^2(1-250)"}.get(v("SP4_8"), "") + " timeslices"
            CB["CB4_9"] = "GFT = " + s(v("SP4_9"))
        elif nL == 5:
            if nT == 1:
                CB["CB5_1"] = {1: "Basic simulation", 2: "ELL simulation\r(MGC)", 3: "EBR simulation",
                               4: "EBR simulation 2", 5: "EBR simulation 3", 6: "PuC simulation",
                               7: "EBR-PUC"}.get(v("SP5_1"), "")
                self.DISPLAYONCB("SP3_5")
                self.DISPLAYONCB("SP3_6")
            elif nT == 2:
                nV = v("SP5_2")
                CB["CB5_2"] = "No lift increment when S5 > " + s(nV) if nV >= 10 else "Variant " + s(nV)
            elif nT == 3:
                CB["CB5_3"] = "Load values of demo " + s(v("SP5_3"))
            elif nT == 5:
                CB["CB5_5"] = "Ca-threshold\r= " + s(v("SP5_5"))
            elif nT == 6:
                CB["CB5_6"] = "B-threshold\r= " + s(v("SP5_6"))
            elif nT == 7:
                CB["CB5_7"] = "N-threshold\r= " + s(v("SP5_7"))
            elif nT == 8:
                CB["CB5_8"] = "Value Set " + s(v("SP5_8"))
            elif nT == 9:
                cV, nV = s(v("SP4_9")), v("SP5_9")
                CB["CB5_9"] = "GrC bursts cover\rall timeslices" if nV == 0 else \
                    "GrCs burst\r" + {1: cV, 2: "RAND(1-" + cV + ")", 3: "RAND^2(1-" + cV + ")"}.get(nV, "") + " times/cycle"

    def LBPCAPTION(self):
        """The demo text in the box at the bottom left (EditBox LBP)."""
        M = self.MEM
        cFields = ["MODE", "VARIANT", "F3_13", "F3_4", "F3_5", "F3_6", "F3_7", "IBCM", "S1", "S2", "S1JIT", "S2JIT",
                   "S1LIFT", "S2LIFT", "ISI", "USDUR", "USFORCE", "S4START", "AUTOLIFT", "ILFMAX", "P", "D", "CAP",
                   "CWA", "WA", "GFDUR", "GFDMODE", "GFTRIG", "GFTMODE", "PEN", "CA", "B", "N", "DEMO"]
        # 0 = not shown when 0 ; 1 = not shown when 1 ; + = always shown ; - = never shown
        cShowIf = ["0", "0", "0", "+", "+", "+", "+", "1", "1", "1", "0", "0", "+", "+", "0", "0", "0", "+", "-", "1",
                   "0", "0", "0", "0", "0", "1", "0", "1", "1", "0", "0", "+", "+", "-"]
        cLBP = "DECORRELATING ALGORITHM" + (" DEMO " + self.cmd if self.cmd else "")
        cCMem = ""
        for nX, cX in enumerate(cFields):
            cO = PCOBJECTS[PCFIELDS.index(cX)].replace("SP", "CB")
            if not self.enabled(cO):
                continue
            cC = self.OPCAP[cO] if cO.startswith("OP") else self.CB[cO]
            if cC.startswith("N-t"):
                cC = "N-threshold = 10"
            if "stimulus" in cC:
                cLBP = cLBP.replace("signal", "signal at" + cC[cC.find("=") + 1:])
            if M["MODE"] == 1 and M["F3_13"] < 3 and "%" in cC:       # with SUM+AVG or AVG derived
                cC = cC[:5] + ltrim(vstr(self.pnPv if cC.startswith("P") else self.pnDv, 5, 1))
                if M["F3_13"] == 1:
                    continue
            if M["MODE"] in (1, 3, 4, 5) and "-t" in cC:              # no thresholds unless ELL
                continue
            if M["MODE"] in (2, 3, 4, 5, 6, 7) and ("% =" in cC or "capping" in cC):
                continue
            if M["MODE"] == 5 and ("S4" in cC or "GrC" in cC):
                continue
            if cC.startswith("Lift S1"):
                cCMem = cC
                continue
            if cC.startswith("NO"):
                continue
            if "iBCM" in cC and "iBCM" in cCMem:
                continue
            if cC.startswith("Lift S2") and cCMem.startswith("Lift S1"):
                nCMem = vval(cC[cC.find("=") + 1:]) + vval(cCMem[cCMem.find("=") + 1:])
                if nCMem + self.pnLiftS1 + self.pnLiftS2 > 0:
                    cC = "Excitatory lift added to S3 = " + ltrim(vstr(nCMem + vround(self.pnLiftS1, 0) + vround(self.pnLiftS2, 0))) + \
                        (" (autolifted)" if M["AUTOLIFT"] == 1 else "")
                    cLBP = cLBP + "\r" + cC
                elif self.pnLift > 0:
                    cC = "Excitatory lift added to S3 = " + ltrim(vstr(nCMem + vround(self.pnLift, 0))) + \
                        (" (autolifted)" if M["AUTOLIFT"] == 1 else "")
                    cLBP = cLBP + "\r" + cC
                continue
            if "GFD =" in cC or "GFT =" in cC:
                continue
            if (cC.startswith("B-t") or cC.startswith("Ca-t")) and self.pnBShift > 0:
                cC = cC + "+" + ltrim(vstr(self.pnBShift, 6, 2))
            cSI = cShowIf[nX]
            if cSI == "-":
                cCMem = ""
                continue
            if 48 + M[cX] != ord(cSI):
                cC = cC.replace("\r", " ")
                pair = ("na-" in cC and "na-" in cCMem) or ("Variant" in cC and "simul" in cCMem) or \
                       ("US" in cC and "US" in cCMem) or ("Sa-" in cC and "Sa-" in cCMem) or \
                       ("Fa-" in cC and "Fa-" in cCMem) or ("S2" in cC and "S1" in cCMem) or \
                       ("D%" in cC and "P%" in cCMem) or ("N-t" in cC and "B-t" in cCMem)
                cLBP = cLBP + (("\r" if len(cCMem + cC) > 40 else "   ") if pair else "\r") + cC
                cLBP = cLBP.replace("wrong addressings", "wrong addressing(s) for each right one")
                cLBP = cLBP.replace("US-", "").replace("US dur", "dur")
                cCMem = cC
            else:
                cCMem = ""
        cLBP = cLBP + ("" if M["MODE"] in (3, 4, 5) else "\r" + ("FIT-height reduced by factor " + ltrim(vstr(self.pnDivMax)) + " ." if self.pnDivMax > 1 else ""))
        nO = cLBP.count("\r")
        cLBP = cLBP + "\r" * max(1, 10 - nO) + "Click to interrupt / RightClick to stop"
        self.obj["LBP"].caption = cLBP
        if M["AUTOLIFT"] == 1:
            self.LBSIGNALTEXT()


# ======================================================================================
# The window: the form (Pillow raster image) and a demo panel (Tk)
# ======================================================================================
SECTIONS = [
    ("Part 2 - From MGC to PuC: PuC simulation (iBCM rule)", [
        (80, "Fig. 7, p. 34", "PuC simulation: iBCM rule, no B-spike, non-inverted DS; Ca-threshold 42"),
        (81, "Fig. 8a, p. 34", "S2 flat (no UC), Ca-threshold 21"),
        (82, "Fig. 8b, p. 34", "S2 flat, Ca-threshold 11: LTD on synapses already at a minimum"),
        (83, "Fig. 8c, p. 34", "S2 flat, Ca-threshold 31: a 'lift' of S4")])]
DEMOINFO = {n: (sec, fig, txt) for sec, lst in SECTIONS for n, fig, txt in lst}
SPEEDS = (0.25, 0.5, 1, 2, 4, 8, 16)
# Timing, measured in VFP 9 per mode: computing one iteration (250 timeslices), and drawing the screen
# (DRAWALLLINES), which moves the 13 line objects of every timeslice one after the other, so that the new
# state appears from left to right; the first drawing of a run takes longer. The slow start of demo 26
# (SLOW) is a counting loop of SLOW*1000000/ic^2 steps (about 15000 steps per ms).
# A demo runs twice as fast as in VFP (AFTER_FIRST); only demos 5, 6 and 26 start with the first drawing in
# slow motion, at the speed of VFP.
CYCLE_MS = {1: 10, 2: 16, 6: 32}
DRAW_MS = {1: 960, 2: 1060, 6: 1080}
FIRST_DRAW_MS = {1: 6100, 2: 5900, 6: 6500}
SLOW_STEPS_PER_MS = 15000
AFTER_FIRST = 2
SLOW_START = (5, 6, 26)
FORM_W = 632


def _font(name, px):
    from PIL import ImageFont
    for f in (name, name.lower(), "DejaVuSans-Bold.ttf" if "bd" in name else "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(f, px)
        except OSError:
            pass
    return ImageFont.load_default()


class Form:
    """Paints the form on a Pillow image: labels first, then the line objects (VFP z-order)."""

    def __init__(self):
        self.f_lbs = _font("arialbd.ttf", 9)
        self.f_lbp = _font("arial.ttf", 11)
        self.f_fit = _font("arial.ttf", 12)
        self.f_ltl = _font("arialbd.ttf", 8)

    def _text(self, dr, s, cx, baseline, font):
        w = dr.textlength(s, font=font)
        dr.text((cx - w / 2, baseline), s, fill=(0, 0, 0), font=font, anchor="ls")

    def _label(self, img, o, bg, font, line_h, pad):
        from PIL import Image, ImageDraw
        if not o.visible or o.width <= 0 or o.height <= 0:
            return
        sub = Image.new("RGB", (o.width, o.height), bg)
        dr = ImageDraw.Draw(sub)
        for k, s in enumerate(str(o.caption).split("\r")):
            self._text(dr, s, o.width / 2, pad + k * line_h, font)
        img.paste(sub, (o.left, o.top))

    def paint(self, D, shown=None):
        from PIL import Image, ImageDraw
        H, O, L = D.nH, D.obj, shown or D.L
        img = Image.new("RGB", (FORM_W, H), C_GRIJS)
        dr = ImageDraw.Draw(img)
        for b in D.boxes:
            dr.rectangle((b[0], min(b[1], b[3]), b[2], max(b[1], b[3])), outline=(0, 0, 0))
        self._label(img, O["FIT1"], (240, 240, 240), self.f_fit, 0, 12)
        for n in ("LB01", "LB011", "LB02", "LB022"):
            o = O[n]
            if o.visible:
                dr.rectangle((o.left, o.top, o.left + o.width - 1, o.top + o.height - 1), fill=o.color)
        p = O["LBP"]
        dr.rectangle((p.left, p.top, p.left + p.width - 1, p.top + p.height - 1), fill=(171, 173, 179))
        dr.rectangle((p.left + 1, p.top + 1, p.left + p.width - 2, p.top + p.height - 2), fill=(255, 255, 255))
        dr.rectangle((p.left + 2, p.top + 2, p.left + p.width - 3, p.top + p.height - 3), fill=(240, 240, 240))
        lines = []
        caption = re.sub(r"\r*Click to (interrupt|resume) / RightClick to stop$", "", p.caption)   # the buttons do it
        for para in caption.split("\r"):
            line = ""
            for w in para.split(" ") if para else [""]:
                t = w if line == "" else line + " " + w
                if dr.textlength(t, font=self.f_lbp) > p.width - 10 and line != "":
                    lines.append(line)
                    line = w
                else:
                    line = t
            lines.append(line)
        for k, s in enumerate(lines):
            if p.top + 15 + k * 14 < p.top + p.height - 2:
                self._text(dr, s, p.left + p.width / 2, p.top + 15 + k * 14, self.f_lbp)
        for k in range(1, 9):
            self._label(img, O["LBS%d" % k], (192, 192, 192), self.f_lbs, 11, 9)
        # line objects: a vertical line covers the rows Top .. Top+Height-1
        for n in ("L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "LR41", "LR52", "LR63", "LR14", "LR25", "LR36", "LFIT25"):
            for ln in L[n][1:]:
                if ln.height > 0 and ln.top + ln.height > 0:
                    dr.line((ln.left, ln.top, ln.left, ln.top + ln.height - 1), fill=ln.color)
        # horizontal lines (class LT): Left .. Left+Width-1

        def hline(o):
            if o.visible and o.top >= 0:
                dr.line((o.left, o.top, o.left + o.width - 1, o.top), fill=o.color)
        for n in ("LTC3", "LTB3", "LTN3", "LTC5"):
            hline(O[n])
        for n in ("LTCL3", "LTBL3", "LTNL3", "LTCL5"):
            if O[n].top >= 0:
                self._label(img, O[n], (240, 240, 240), self.f_ltl, 0, 8)
        for k in range(1, 9):
            hline(O["LTA%d" % k])
        hline(O["S5HALT"])
        return img


class App:
    def __init__(self, root, demo, speed, seed, scale):
        import tkinter as tk
        self.tk = tk
        self.root, self.speed, self.seed, self.scale = root, speed, seed, scale
        self.form = Form()
        self.D = None
        self.demo = demo
        self.state = "idle"
        self.run_id = 0
        root.title("DECORRELATOR - Beunis 2022 (ELL Part 2)")
        root.configure(bg="#808080")
        self.cv = tk.Label(root, bd=0, bg="#808080")
        self.cv.grid(row=0, column=0, sticky="nw")
        self.panel = tk.Frame(root, bg="#d4d0c8", padx=5, pady=4)
        self.panel.grid(row=0, column=1, sticky="ns")
        self.build_panel()
        self.select(demo)

    def build_panel(self):
        tk = self.tk
        tk.Label(self.panel, text="DECORRELATOR", bg="#d4d0c8", font=("Arial", 11, "bold")).pack()
        tk.Label(self.panel, text="ELL article Part 2, Beunis 2022 - live demos", bg="#d4d0c8", font=("Arial", 8)).pack()
        row = tk.Frame(self.panel, bg="#d4d0c8")
        row.pack(pady=(3, 3))
        self.bint = tk.Button(row, text="", width=12, font=("Arial", 10, "bold"), bg="#ffd24d", bd=2,
                              command=self.pause)
        self.bint.pack(side="left", padx=3)
        self.bstop = tk.Button(row, text="\u25a0  Stop", width=8, font=("Arial", 10, "bold"), bg="#ff6b5b", fg="#ffffff",
                               bd=2, command=self.stop)
        self.bstop.pack(side="left", padx=3)
        self.buttons = {}
        for sec, lst in SECTIONS:
            tk.Label(self.panel, text=sec, bg="#d4d0c8", font=("Arial", 7, "bold"), anchor="w").pack(fill="x", pady=(3, 0))
            row = None
            for k, (n, fig, txt) in enumerate(lst):
                if k % 7 == 0:
                    row = tk.Frame(self.panel, bg="#d4d0c8")
                    row.pack(anchor="w")
                b = tk.Button(row, text=str(n), width=3, font=("Arial", 7, "bold"), pady=0, bg="#e1e1e1",
                              command=lambda n=n: self.select(n))
                b.pack(side="left", padx=1, pady=1)
                self.buttons[n] = b
        self.info = tk.Label(self.panel, text="", bg="#ffffff", font=("Arial", 8), justify="left", anchor="nw",
                             wraplength=210, width=34, height=6, relief="solid", bd=1)
        self.info.pack(fill="x", pady=(6, 3))
        row = tk.Frame(self.panel, bg="#d4d0c8")
        row.pack(anchor="w")
        tk.Label(row, text="Speed", bg="#d4d0c8", font=("Arial", 7, "bold")).pack(side="left")
        self.sbuttons = {}
        for sp in SPEEDS:
            b = tk.Button(row, text=("%g" % sp) + "x", font=("Arial", 7), pady=0, bg="#e1e1e1",
                          command=lambda sp=sp: self.set_speed(sp))
            b.pack(side="left", padx=1)
            self.sbuttons[sp] = b
        self.bgo = tk.Button(self.panel, text="(Re)Start this demo", font=("Arial", 11, "bold"), bd=2, height=1,
                             command=self.start)
        self.bgo.pack(fill="x", pady=(6, 0))
        self.mark_start()

    def start(self):
        """'(Re)Start this demo': starts the chosen demo, or runs it again."""
        if self.state != "wait":
            self.select(self.demo)
        self.go()

    def mark_start(self):
        """The start button is red on yellow as long as no demo is running."""
        if self.state == "run":
            self.bgo.configure(bg="#e1e1e1", fg="#000000", activebackground="#e5f1fb", activeforeground="#000000")
        else:
            self.bgo.configure(bg="#ffff00", fg="#ff0000", activebackground="#ffff80", activeforeground="#ff0000")
        self.root.after(250, self.mark_start)

    def set_speed(self, sp):
        self.speed = sp
        self.mark()

    def mark(self):
        for n, b in self.buttons.items():
            b.configure(bg="#ffff00" if n == self.demo else "#e1e1e1")
        for sp, b in self.sbuttons.items():
            b.configure(bg="#ffff00" if sp == self.speed else "#e1e1e1")
        sec, fig, txt = DEMOINFO.get(self.demo, ("", "", ""))
        self.info.configure(text="Demo %d - %s\n%s" % (self.demo, fig, txt))
        self.mark_run()

    def mark_run(self):
        """The Interrupt / Resume and Stop buttons."""
        running = self.state == "run"
        paused = bool(self.D and self.D.plPause)
        self.bint.configure(text="\u25b6  Resume" if paused else "\u275a\u275a  Interrupt",
                            bg="#7ee07e" if paused else "#ffd24d", state="normal" if running else "disabled")
        self.bstop.configure(state="normal" if running else "disabled")

    def select(self, n):
        self.run_id += 1
        self.demo = n
        rnd = park_miller(self.seed if self.seed is not None else int(time.time() * 1000) % 2147483645 + 1)
        self.D = Decorrelator(rand=rnd, height=542)
        self.D.DEMO(n)
        self.state = "wait"
        self.shown = clone_lines(self.D.L)
        self.draws = 0
        self.mark()
        self.show()                         # the demo starts with the button '(Re)Start this demo'

    def show(self):
        from PIL import Image, ImageTk
        img = self.form.paint(self.D, self.shown)
        if self.scale != 1:
            img = img.resize((round(img.width * self.scale), round(img.height * self.scale)), Image.LANCZOS)
        self.tkimg = ImageTk.PhotoImage(img)
        self.cv.configure(image=self.tkimg)

    def pause(self):
        if self.state != "run":
            return
        D = self.D
        D.plPause = not D.plPause
        self.show()
        self.mark_run()

    def stop(self):
        if self.state == "run":
            self.D.plBreak = True
            self.D.plPause = False
            self.mark_run()

    def go(self):
        self.state = "run"
        self.mark_run()
        self.show()
        self.gen = self.D.EXECUTE()
        self.due = time.perf_counter()
        self.cyc = CYCLE_MS.get(self.D.MEM["MODE"], 10) / 1000
        self.root.after(1, self.tick, self.run_id)

    def tick(self, rid):
        if rid != self.run_id:
            return
        if self.D.plPause:
            self.root.after(50, self.tick, rid)
            return
        t_end = time.perf_counter() + 0.03
        while True:
            try:
                r = next(self.gen)
            except StopIteration:
                self.shown = clone_lines(self.D.L)
                self.show()
                self.state = "done"
                self.mark_run()
                return
            slow_start = self.demo in SLOW_START and self.draws == 0
            f = 1 if slow_start else AFTER_FIRST
            self.due += self.cyc / self.speed / f
            if r["drawn"]:
                D, mode = self.D, self.D.MEM["MODE"]
                if not r.get("end") and D.MEM["SLOW"] > 0 and D.pnIC >= 2:
                    self.due += D.MEM["SLOW"] * 1e6 / (D.pnIC * D.pnIC) / SLOW_STEPS_PER_MS / 1000 / self.speed / f
                ms = FIRST_DRAW_MS.get(mode, 6000) if slow_start else DRAW_MS.get(mode, 960) / AFTER_FIRST
                self.draws += 1
                self.sweep_target, self.sweep_done = clone_lines(D.L), 0
                self.sweep_ms, self.sweep_t0 = ms, max(self.due, time.perf_counter())
                self.root.after(max(1, int((self.sweep_t0 - time.perf_counter()) * 1000)), self.sweep, rid)
                return
            if self.due > time.perf_counter() + 0.004 or time.perf_counter() > t_end:
                break
        now = time.perf_counter()
        if self.due < now - 0.25:
            self.due = now                      # the computer lagged behind: do not try to catch up
        self.root.after(max(1, int((self.due - now) * 1000)), self.tick, rid)

    def sweep(self, rid):
        """DRAWALLLINES: the new positions appear timeslice by timeslice, from left to right."""
        if rid != self.run_id:
            return
        if self.D.plPause:
            self.sweep_t0 += 0.05
            self.root.after(50, self.sweep, rid)
            return
        k = min(STEPS, int(STEPS * (time.perf_counter() - self.sweep_t0) * self.speed * 1000 / self.sweep_ms) + 1)
        for n, a in self.sweep_target.items():
            self.shown[n][self.sweep_done + 1:k + 1] = a[self.sweep_done + 1:k + 1]
        self.sweep_done = k
        self.show()
        if k < STEPS:
            self.root.after(30, self.sweep, rid)
        else:
            self.due = time.perf_counter()
            self.root.after(1, self.tick, rid)


def clone_lines(L):
    out = {}
    for n, a in L.items():
        b = [None]
        for ln in a[1:]:
            c = Line(ln.left)
            c.top, c.height, c.color = ln.top, ln.height, ln.color
            b.append(c)
        out[n] = b
    return out


def main():
    ap = argparse.ArgumentParser(description="DECORRELATOR - Python version of the DECORRELATOR form (CEREBREADER.PRG)")
    ap.add_argument("--demo", type=int, default=80, help="demo number of the original program (80..83)")
    ap.add_argument("--speed", type=float, default=1.0, help="playback speed (0.25..16; 1 = speed of the VFP original)")
    ap.add_argument("--seed", type=int, default=None, help="fixed seed for a reproducible run")
    ap.add_argument("--scale", type=float, default=1.0, help="zoom factor of the form (e.g. 1.5)")
    a = ap.parse_args()
    if a.demo not in DEMOINFO:
        sys.exit("unknown demo %d" % a.demo)
    import tkinter as tk
    root = tk.Tk()
    App(root, a.demo, min(16, max(0.25, a.speed)), a.seed, a.scale)
    root.mainloop()


if __name__ == "__main__":
    main()
