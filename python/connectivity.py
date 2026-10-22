#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CONNECTIVITY - Python/Tkinter translation of the left half of the CONNECTIVITY
form of the author's article reader CEREBREADER.PRG (Dr. R. Beunis, Visual
FoxPro 9.0), as it runs in demo-4-1 (Fig. 16) of Beunis R. (2022) "The
electrosensory lateral line lobe in mormyrid fish : a stepping stone to the
understanding of the cerebellum ?" Part 2 (the cerebellum), Addendum 'Random
connectivity examined', Zenodo, doi:10.5281/zenodo.17613147.

Each timeslice of the A-path is fed by 256 granule cells (GrCs), each with a
random input permutation in which up to NOLI inputs may be lacking (replaced by
a redundant one).  A GrC with a lacking input fires at a 'wrong address' (the
pcWAF formula); the decorrelation (an averaging with P = D = 1%) of the
unchanging signal S1 (+ the slowly varying S2) is disturbed by these wrong
addressings.  Four runs of 50 iterations, allowing 0, 1, 2 and 3 lacking inputs
(3 and 5 inputs: three or five runs).

The translation follows the VFP code procedure by procedure (same names:
DORUN, PREP, RANDCOMB, COMBOR, S1BASE, S2BASE, WANDERINGLINE, ...).  With the
same random numbers the results are identical to those of the original
(checked against runs in Visual FoxPro 9: the averages after iteration 1, 2, 5,
10 and 50, the number of RAND calls, the combination lists, and the drawing of
the graphs pixel by pixel).  The graphs are drawn on a raster image (Pillow)
with the rule VFP follows for Form.Line; the texts with the character widths
VFP uses.

The random numbers are those of VFP's RAND() (the generator was measured),
starting as in a freshly started VFP: '(Re)Start this demo' gives exactly the
run of Fig. 16 and the video of the article.  The buttons '3/4/5 inputs'
continue the random sequence, as in VFP.

Deliberate differences from VFP:
  * The speed is taken from VFP 9 (on a 1280 x 720 screen, as the article's
    video); the run is shown twice as fast.  The run starts with the button
    '(Re)Start this demo' or one of the buttons '3/4/5 inputs'.  A playback
    speed control and Interrupt/Stop buttons were added.
  * Only the left half of the form is translated (the right half, with the
    'ordered' combination analysis, is not used in the article).

Usage:
  python connectivity.py                 the demo window
  python connectivity.py --speed 0.5     half speed
  python connectivity.py --seed 123      the random numbers of RAND(123) instead of the start-up state
  python connectivity.py --inputs 4 --dump d.txt --png g.png [--pm-seed 12345]
                                         (test: compute the whole run, write the averages
                                          as the VFP test copy does, and the end image;
                                          --pm-seed: the Park-Miller generator of the test copy)
"""

import argparse
import math
import sys
import time

# ======================================================================================
# Helpers
# ======================================================================================


VFP_SEED = 100001


def vfp_rand(seed=VFP_SEED):
    """RAND() of Visual FoxPro 9 (measured): x = (87137421 * x + 21132487) mod 2^32, RAND() = x / 2^32,
    a value >= 0.999995 is skipped; RAND(seed) sets x = seed; at start-up x = 100001.
    A run with the start-up state is the run of the article."""
    st = {"s": seed % 4294967296, "n": 0}

    def rand():
        s = st["s"]
        while True:
            s = (87137421 * s + 21132487) % 4294967296
            if s < 4294945822:              # 0.999995 * 2^32
                break
        st["s"] = s
        st["n"] += 1
        return s / 4294967296
    rand.state = st
    return rand


def park_miller(seed):
    """Park-Miller generator: exact in doubles, used in the VFP test copy (XRAND) (test: --pm-seed)."""
    st = {"s": seed % 2147483647 or 2147483646, "n": 0}

    def rand():
        st["s"] = (st["s"] * 16807) % 2147483647
        st["n"] += 1
        return st["s"] / 2147483647
    rand.state = st
    return rand


def vmod(a, b):
    """MOD(): the result has the sign of the divisor."""
    return a - math.floor(a / b) * b


# ======================================================================================
# Constants
# ======================================================================================
PNH, PNW = 516, 1264       # the form maximized on a 1280 x 720 screen (as in the article's video)
PNWOBJ = PNW / 12
FORM_W = PNW // 2
PNITS, PNCONSTEPS, NCOMBS = 50, 256, 256
PND = PNP = .01            # D-factor, P-factor
PNHMEM = 30                # (a global of the article reader, 30 at start-up)
ZWART, ROOD = (0, 0, 0), (255, 0, 0)
FCOLORS = [(0, 255, 0), (255, 128, 128), (0, 255, 255), (255, 255, 0), (255, 128, 255)]
LIST_H = 97                # (pnH - PCON3.Height) / 5


def FCOLOR(n):
    return FCOLORS[n]


def list_top(n):
    return 30 + n * LIST_H


# Timing, measured in VFP 9: iteration 1 of a run (generating the 256 random combinations of every
# timeslice) takes 3.7 to 6.7 s, every following iteration about 0.79 s. Shown twice as fast.
TS_FIRST_MS, RAND_MS, TS_MS = 2600 / 256, 0.0012, 790 / 256
AFTER_FIRST = 2
SPEEDS = [0.25, 0.5, 1, 2, 4, 8, 16]


# ======================================================================================
# The computing core
# ======================================================================================
class Connectivity:
    def __init__(self, rand, gfx, ui):
        self.rand, self.gfx, self.ui = rand, gfx, ui
        self.pnR = 1.0                  # global of the article reader (STORE 1 TO ... pnR)
        self.pnInputs = 4
        self.ordered = False            # PORCB.Caption: "Input permutations" / "Ordered combinations"
        self.S1 = [0.0] * (PNCONSTEPS + 1)
        self.MAKE_S1()
        # PLISTAG / PLISTOR: per NOLI the generated combinations (identical in every iteration)
        # and how far the run got (the lists exist for the iterations and timeslices computed)
        self.PL = {}
        self.plPause = False
        self.plBreak = False
        self.dumps = None               # test: {(nNOLI, nITC): (rand count, pnR, S4)}

    def MAKE_S1(self):
        for nTS in range(1, PNCONSTEPS + 1):
            self.S1[nTS] = self.S1BASE(nTS)

    @staticmethod
    def S1BASE(nTS):
        nTS = nTS / (1.5 * (257 - nTS) / 257 + .5)
        return max(1, (abs(vmod(nTS, 10) - 5) / 40) * 50 + 2 + ((math.sin(math.radians(nTS * 13 - 90)) + 1) / 4) * 25)

    def S2BASE(self, nL):
        return min(30, max(10, abs(PNHMEM) + self.WANDERINGLINE(nL) * (abs(vmod(nL, 10) - 5) / 40) * 50))

    def WANDERINGLINE(self, nX):
        nR = self.rand()
        self.pnR = nR if vmod(nX, 5) == 0 else self.pnR
        return self.pnR - .5

    def PREP(self):
        # pnCVC^pnInputs as close as possible to 256 (the max number of timeslices displayed)
        self.pnCVC = {3: 6, 4: 4, 5: 3}[self.pnInputs]
        self.nTS = self.pnCVC ** self.pnInputs
        # the 'wrong addressing' formula, e.g. (nAA-1)*64+(nBB-1)*16+(nCC-1)*4+(nDD-1)*1+1 for 4 inputs
        self.mult = [self.pnCVC ** (self.pnInputs - 1 - k) for k in range(self.pnInputs)]
        self.ui.set_spinners(1, 1, PNITS, self.nTS)

    def RANDCOMB(self, nNOLI):
        """A random combination 'as generated': rejected when more than nNOLI inputs would be
        lacking (a character occurring x (> nNOLI) times implies x-1 lacking inputs)."""
        n = self.pnInputs
        while True:
            cX = "".join(chr(96 + int(self.rand() * n) + 1) for _ in range(n))
            nFlag = 0
            for nR in range(1, n + 1):
                o = cX.count(chr(nR + 96))
                if o > nNOLI:
                    nFlag += o - 1
            if not nFlag > nNOLI:
                return cX

    def COMBOR(self, cRCAG):
        """Place the inputs 'in order of dimension' and fill in the gaps with the redundant ones."""
        n = self.pnInputs
        o = [" "] * n
        for nI in range(1, n + 1):
            cPI = chr(nI + 96)
            if cPI in cRCAG:
                o[nI - 1] = cPI
                cRCAG = cRCAG.replace(cPI, "", 1)
        for cRI in sorted(cRCAG):           # ALFABETIC
            o[o.index(" ")] = cRI
        return "".join(o)

    def list_text(self, n, it, ts):
        """The text of a list (PLISTAG / PLISTOR); '' when not computed."""
        s = self.PL.get(n)
        if not s or it > PNITS or ts > s["nTS"] or not (s["itc"] > it or (s["itc"] == it and s["tsc"] >= ts)):
            return ""
        arr = s["rcor"] if self.ordered else s["rcag"]
        t = ("%d parallel ordered combinations" if self.ordered
             else "%d parallel input permutations as generated at random") % NCOMBS
        t += "\r" + "Iteration %d Timeslice %d" % (it, ts) + "\r"
        return t + "".join(c + " " for c in arr[(ts - 1) * NCOMBS:ts * NCOMBS])

    def SPINCLICK(self):
        """ISP.Click: show the lists of the chosen iteration and timeslice."""
        it, ts = self.ui.get_spinners()
        for n in range(self.pnInputs):
            self.ui.set_list(n, self.list_text(n, it, ts))

    def PORCLICK(self):
        self.ordered = not self.ordered
        self.ui.set_por_caption(self.ordered)
        self.SPINCLICK()

    def DORUN(self):
        """Three, four or five decorrelation runs of 50 iterations, allowing 0, 1, ... lacking inputs.
        A generator: yields after every timeslice the time it took in VFP 9 (ms)."""
        g, n = self.gfx, self.pnInputs
        self.PREP()
        g.clear()                               # FOR nX=1 TO pnH : Line(0,nX,pnW/2,nX) in black
        self.ui.hide_lists()
        nSH = 90
        cvc, mult, nTSs, rand = self.pnCVC, self.mult, self.nTS, self.rand
        S1 = self.S1
        for nNOLI in range(n):
            nCLTop = list_top(nNOLI)
            self.ui.show_list(nNOLI)
            nFC = FCOLOR(nNOLI)
            S4 = [0.0] * (PNCONSTEPS + 1)
            slot = {"nTS": nTSs, "itc": 0, "tsc": 0, "rcag": [None] * (nTSs * NCOMBS), "rcor": [None] * (nTSs * NCOMBS)}
            self.PL[nNOLI] = slot
            W = [0] * (nTSs * NCOMBS)           # the wrong address of each combination
            base = nCLTop + nSH
            for nITC in range(1, PNITS + 1):
                nTSC = 0
                # the nested loops nA, nB, ... over the coordinate values of the dimensions
                for t in range(nTSs):
                    coords, r = [0] * n, t
                    for k in range(n - 1, -1, -1):
                        coords[k] = r % cvc + 1
                        r //= cvc
                    nTSC += 1
                    r0 = rand.state["n"]
                    for nCOMB in range(NCOMBS):
                        idx = t * NCOMBS + nCOMB
                        if nITC == 1:
                            cRCAG = self.RANDCOMB(nNOLI)
                            cRCOR = self.COMBOR(cRCAG)
                            slot["rcag"][idx], slot["rcor"][idx] = cRCAG, cRCOR
                            # the place k in cRCOR is the target dimension, its letter the source dimension
                            W[idx] = 1 + sum((coords[ord(cRCOR[k]) - 97] - 1) * mult[k] for k in range(n))
                        nTSWA = W[idx]                       # the (wrong) address
                        m = S4[nTSWA]                        # S4M: remember the actual AVG value
                        S4[nTSWA] = S4[nTSWA] - S4[nTSWA] * PND + (S1[nTSC] + self.S2BASE(nITC)) * PNP
                        if nITC == 1 or int(m) != int(S4[nTSWA]):   # redraw only when discretely different
                            g.line(nTSWA + 35, base, base - 55, ZWART)      # black line first to erase
                            g.line(nTSWA + 35, base, base - S4[nTSWA], nFC)
                    slot["itc"], slot["tsc"] = nITC, nTSC
                    if nITC == 1 and nTSC == 1:
                        self.ui.set_list(nNOLI, self.list_text(nNOLI, 1, 1))
                    yield TS_FIRST_MS + (rand.state["n"] - r0) * RAND_MS if nITC == 1 else TS_MS
                    while self.plPause and not self.plBreak:
                        yield 0
                    if self.plBreak:
                        return
                g.print("No inputs lacking" if nNOLI == 0 else
                        "%d input%s may be lacking" % (nNOLI, "" if nNOLI == 1 else "s"), 10, nCLTop, nFC)
                g.print("All dendrites receive distinct inputs" if nNOLI == 0 else
                        "Same input on %d dendrites allowed" % (nNOLI + 1), 10, nCLTop + 20, nFC)
                g.print(str(nITC), 10, nCLTop + 50, nFC)
                if self.dumps is not None and nITC in (1, 2, 5, 10, PNITS):
                    self.dumps[nNOLI, nITC] = (rand.state["n"], self.pnR, S4[1:257])


# ======================================================================================
# Drawing on the form (VFP Form.Line / Form.Print) on a Pillow image
# ======================================================================================
# the advance of the characters 32..126 of Arial 8 bold as VFP draws them (TextWidth, measured in VFP 9)
GDI8 = [3, 3, 5, 6, 6, 9, 8, 3, 4, 4, 4, 6, 3, 4, 3, 3, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 3, 6, 6, 6, 7, 11, 8, 7, 8,
        7, 6, 6, 8, 7, 3, 6, 7, 7, 10, 7, 8, 7, 8, 7, 7, 7, 7, 8, 10, 7, 7, 7, 4, 3, 4, 6, 6, 4, 6, 7, 6, 7, 7, 4, 7,
        7, 3, 3, 7, 3, 11, 7, 7, 7, 7, 5, 7, 4, 7, 6, 10, 6, 6, 6, 4, 3, 4, 6]


def _font(name, px):
    from PIL import ImageFont
    for f in (name, name.lower(), "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(f, px)
        except OSError:
            pass
    return ImageFont.load_default()


class Gfx:
    def __init__(self):
        from PIL import Image, ImageDraw
        self.img = Image.new("RGB", (FORM_W, PNH), ZWART)
        self.draw = ImageDraw.Draw(self.img)
        self.font = _font("arialbd.ttf", 10.667)       # FontSize 8, bold
        self.pending = None
        self.dirty = True

    def line(self, x, y1, y2, color):
        """A vertical Form.Line from y1 (integer) up to y2: VFP colours the rows INT(y2)+1 .. y1."""
        if self.pending:
            self.flush()
        top = int(y2) + 1
        if y1 >= top:
            self.img.paste(color, (x, top, x + 1, y1 + 1))
        self.dirty = True

    def clear(self):
        self.flush()
        self.img.paste(ZWART, (0, 1, FORM_W, PNH))
        self.dirty = True

    def print(self, s, x, y, color):
        """Form.Print: opaque text; VFP shows a printed text only once the next drawing operation
        comes (the last number of a run stays one iteration behind, as in the original)."""
        self.flush()
        self.pending = (s, x, y, color)

    def flush(self):
        if not self.pending:
            return
        s, x, y, color = self.pending
        self.pending = None
        w = sum(GDI8[ord(c) - 32] if 32 <= ord(c) <= 126 else 6 for c in s)
        self.img.paste(ZWART, (x, y, x + w, y + 14))
        cx = x
        for c in s:
            self.draw.text((cx, y + 11), c, fill=color, font=self.font, anchor="ls")
            cx += GDI8[ord(c) - 32] if 32 <= ord(c) <= 126 else 6
        self.dirty = True

    def blank(self):
        self.pending = None
        self.img.paste(ZWART, (0, 0, FORM_W, PNH))
        self.dirty = True


# ======================================================================================
# The window: the controls of the form (left half) and a panel
# ======================================================================================
INFO = ("Demo 4-1 - Fig. 16, p. 59\n"
        "Addendum 'Random connectivity examined'.\n"
        "A 4D input space with 4 PPVs per axis: 256 timeslices, each affected by 256 GrCs with a random "
        "input permutation. Four decorrelation runs of 50 iterations of the unchanging signal S1 "
        "(with P = D = 1%), allowing 0, 1, 2 and 3 lacking inputs: a GrC with a lacking input fires at a "
        "wrong address.\nThe buttons 3 / 4 / 5 inputs start the same runs in 3, 4 or 5 dimensions. With the "
        "spinners Iteration and Timeslice the 256 input permutations of every timeslice can be viewed, "
        "also 'ordered'.\n'(Re)Start this demo' repeats exactly the run of Fig. 16 (the random numbers of a "
        "freshly started Visual FoxPro).")


class App:
    def __init__(self, root, speed, seed):
        import tkinter as tk
        from PIL import ImageTk
        self.tk, self.root, self.speed, self.seed = tk, root, speed, seed
        self.state = "wait"
        self.run_id = 0
        root.title("CONNECTIVITY - Beunis 2022 (ELL Part 2), demo 4-1")
        root.configure(bg="#808080")
        root.resizable(False, False)
        self.formf = tk.Frame(root, width=FORM_W, height=PNH, bg="#000000")
        self.formf.grid(row=0, column=0, sticky="nw")
        self.gfx = Gfx()
        self.photo = ImageTk.PhotoImage(self.gfx.img)
        tk.Label(self.formf, image=self.photo, bd=0).place(x=0, y=0)
        self.build_form()
        self.panel = tk.Frame(root, bg="#d4d0c8", padx=5, pady=4, width=236, height=PNH)
        self.panel.grid(row=0, column=1, sticky="ns")
        self.build_panel()
        self.init()
        self.refresh()

    # ---- the controls of the form --------------------------------------------------------
    def build_form(self):
        tk = self.tk
        f = self.formf
        self.con = {}
        for n in (3, 4, 5):
            b = tk.Button(f, text="%d inputs" % n, font=("Arial", -12, "bold"), bg="#fdfdfd", relief="groove",
                          command=lambda n=n: self.start(n))
            b.place(x=int((n - 3) * PNWOBJ), y=0, width=int(PNWOBJ), height=30)
            self.con[n] = b
        small = ("Arial", -9, "bold")
        tk.Button(f, text="Iteration", font=small, bg="#fdfdfd", relief="groove").place(
            x=int(PNWOBJ * 3), y=0, width=52, height=30)
        tk.Button(f, text="Timeslice", font=small, bg="#fdfdfd", relief="groove").place(
            x=int(PNWOBJ * 4), y=0, width=52, height=30)
        self.it_var, self.ts_var = tk.IntVar(value=1), tk.IntVar(value=1)
        self.sp_it = tk.Spinbox(f, from_=1, to=PNITS, textvariable=self.it_var, font=small, justify="right",
                                command=self.spin)
        self.sp_it.place(x=int(PNWOBJ * 3 + PNWOBJ / 2), y=0, width=52, height=30)
        self.sp_ts = tk.Spinbox(f, from_=1, to=256, textvariable=self.ts_var, font=small, justify="right",
                                command=self.spin)
        self.sp_ts.place(x=int(PNWOBJ * 4 + PNWOBJ / 2), y=0, width=52, height=30)
        for sp in (self.sp_it, self.sp_ts):
            sp.bind("<Return>", lambda e: self.spin())
        self.por = tk.Button(f, text="Input permutations", font=small, bg="#fdfdfd", relief="groove",
                             command=lambda: self.conn.PORCLICK())
        self.por.place(x=int(PNWOBJ * 5), y=0, width=int(PNWOBJ), height=30)
        self.lists = []
        for n in range(5):
            t = tk.Text(f, bg="#000000", fg="#%02x%02x%02x" % FCOLOR(n), font=("Arial", -9, "bold"), wrap="word",
                        bd=1, relief="sunken", padx=3, pady=2, highlightthickness=0)
            self.lists.append(t)

    def spin(self):
        try:
            it = min(PNITS, max(1, int(self.sp_it.get())))
            ts = min(self.conn.nTS if hasattr(self.conn, "nTS") else 256, max(1, int(self.sp_ts.get())))
        except ValueError:
            it, ts = 1, 1
        self.it_var.set(it)
        self.ts_var.set(ts)
        self.conn.SPINCLICK()

    # ui interface of the core
    def set_spinners(self, it, ts, it_hi, ts_hi):
        self.sp_it.configure(to=it_hi)
        self.sp_ts.configure(to=ts_hi)
        self.it_var.set(it)
        self.ts_var.set(ts)

    def get_spinners(self):
        return self.it_var.get(), self.ts_var.get()

    def set_list(self, n, text):
        t = self.lists[n]
        t.configure(state="normal")
        t.delete("1.0", "end")
        t.insert("1.0", text.replace("\r", "\n"))
        t.configure(state="disabled")

    def hide_lists(self):
        for n in range(5):
            self.set_list(n, "")
            self.lists[n].place_forget()

    def show_list(self, n):
        self.lists[n].place(x=int(PNWOBJ * 3), y=list_top(n), width=int(PNWOBJ * 3), height=LIST_H)

    def set_por_caption(self, ordered):
        self.por.configure(text="Ordered combinations" if ordered else "Input permutations")

    # ---- the panel -------------------------------------------------------------------------
    def build_panel(self):
        tk = self.tk
        p = self.panel
        p.grid_propagate(False)
        p.pack_propagate(False)
        tk.Label(p, text="CONNECTIVITY", bg="#d4d0c8", font=("Arial", 11, "bold")).pack()
        tk.Label(p, text="ELL article Part 2, Beunis 2022 - live demo", bg="#d4d0c8", font=("Arial", 8)).pack()
        row = tk.Frame(p, bg="#d4d0c8")
        row.pack(pady=(3, 3))
        self.bint = tk.Button(row, text="", width=12, font=("Arial", 10, "bold"), bg="#ffd24d", bd=2, command=self.pause)
        self.bint.pack(side="left", padx=3)
        self.bstop = tk.Button(row, text="■  Stop", width=8, font=("Arial", 10, "bold"), bg="#ff6b5b", fg="#ffffff",
                               bd=2, command=self.stop)
        self.bstop.pack(side="left", padx=3)
        tk.Label(p, text=INFO, bg="#ffffff", font=("Arial", 8), justify="left", anchor="nw", wraplength=212,
                 relief="solid", bd=1, padx=3, pady=3).pack(fill="x", pady=(6, 3))
        row = tk.Frame(p, bg="#d4d0c8")
        row.pack(anchor="w", pady=(4, 0))
        tk.Label(row, text="Speed", bg="#d4d0c8", font=("Arial", 7, "bold")).pack(side="left")
        self.sbuttons = {}
        for sp in SPEEDS:
            b = tk.Button(row, text=("%g" % sp) + "x", font=("Arial", 7), pady=0, bg="#e1e1e1",
                          command=lambda sp=sp: self.set_speed(sp))
            b.pack(side="left", padx=1)
            self.sbuttons[sp] = b
        # '(Re)Start this demo': as in a freshly started VFP, i.e. exactly the run of the article
        self.bgo = tk.Button(p, text="(Re)Start this demo", font=("Arial", 11, "bold"), bd=2,
                             command=lambda: (self.init(), self.start(4)))
        self.bgo.pack(fill="x", pady=(8, 0))
        self.mark()
        self.mark_start()

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
        for sp, b in self.sbuttons.items():
            b.configure(bg="#ffff00" if sp == self.speed else "#e1e1e1")
        self.mark_run()

    def mark_run(self):
        running = self.state == "run"
        paused = bool(self.conn.plPause) if hasattr(self, "conn") else False
        self.bint.configure(text="▶  Resume" if paused else "❚❚  Interrupt",
                            bg="#7ee07e" if paused else "#ffd24d", state="normal" if running else "disabled")
        self.bstop.configure(state="normal" if running else "disabled")
        st = "disabled" if running else "normal"
        for w in list(self.con.values()) + [self.sp_it, self.sp_ts, self.por]:
            w.configure(state=st)

    # ---- running ---------------------------------------------------------------------------
    def init(self):
        """The form as it opens in a freshly started VFP (the random numbers from the start-up state)."""
        self.run_id += 1
        self.conn = Connectivity(vfp_rand(self.seed), self.gfx, self)
        self.gfx.blank()
        for n in range(5):                      # the form as it opens
            self.show_list(n)
        self.mark_con(0)
        self.state = "wait"
        self.mark_run()

    def mark_con(self, n):
        for k, b in self.con.items():
            b.configure(fg="#ff0000" if k == n else "#000000")

    def start(self, n):
        """CONCB.Click: the chosen number of inputs in red, then DORUN."""
        self.run_id += 1
        C = self.conn
        C.plPause = C.plBreak = False
        C.pnInputs = n
        self.mark_con(n)
        self.state = "run"
        self.mark_run()
        self.gen = C.DORUN()
        self.due = time.perf_counter()
        self.root.after(1, self.tick, self.run_id)

    def tick(self, rid):
        if rid != self.run_id:
            return
        t_end = time.perf_counter() + 0.03
        while True:
            if self.conn.plPause:
                self.due = time.perf_counter()
                break
            try:
                ms = next(self.gen)
            except StopIteration:
                self.state = "done"
                self.mark_run()
                return
            self.due += ms / 1000 / self.speed / AFTER_FIRST
            if self.due > time.perf_counter() + 0.004 or time.perf_counter() > t_end:
                break
        now = time.perf_counter()
        if self.due < now - 0.25:
            self.due = now                      # the computer lagged behind: do not try to catch up
        self.root.after(max(1, int((self.due - now) * 1000)), self.tick, rid)

    def refresh(self):
        if self.gfx.dirty:
            self.photo.paste(self.gfx.img)
            self.gfx.dirty = False
        self.root.after(30, self.refresh)

    def pause(self):
        if self.state == "run":
            self.conn.plPause = not self.conn.plPause
            self.mark_run()

    def stop(self):
        if self.state == "run":
            self.conn.plBreak = True
            self.conn.plPause = False
            self.run_id += 1
            self.state = "done"
            self.mark_run()


class NoUI:
    """For the test run without a window."""
    def set_spinners(self, *a): pass
    def get_spinners(self): return 1, 1
    def set_list(self, *a): pass
    def hide_lists(self): pass
    def show_list(self, *a): pass
    def set_por_caption(self, *a): pass


def main():
    ap = argparse.ArgumentParser(description="CONNECTIVITY - Python version of the CONNECTIVITY form (CEREBREADER.PRG)")
    ap.add_argument("--speed", type=float, default=1.0, help="playback speed (0.25..16; 1 = twice the speed of the VFP original)")
    ap.add_argument("--seed", type=int, default=VFP_SEED,
                    help="the random numbers of RAND(seed) (default: the start-up state of VFP, 100001)")
    ap.add_argument("--pm-seed", type=int, default=None, help="(test) the Park-Miller generator of the VFP test copy")
    ap.add_argument("--inputs", type=int, default=4, choices=(3, 4, 5), help="(test) number of inputs")
    ap.add_argument("--dump", help="(test) compute the whole run, write the averages to this file")
    ap.add_argument("--png", help="(test) compute the whole run, save the end image of the graphs")
    a = ap.parse_args()
    if a.dump or a.png:
        gfx = Gfx()
        C = Connectivity(park_miller(a.pm_seed) if a.pm_seed is not None else vfp_rand(a.seed), gfx, NoUI())
        C.pnInputs = a.inputs
        C.dumps = {}
        for _ in C.DORUN():
            pass
        if a.dump:
            with open(a.dump, "w") as f:
                for (nn, it), (cnt, r, s4) in sorted(C.dumps.items()):
                    f.write("S %d %d %d %.8f %s\n" % (nn, it, cnt, r, " ".join("%.8f" % v for v in s4)))
            for n in range(a.inputs):
                with open(a.dump, "a") as f:
                    f.write("L %d %s\n" % (n, C.list_text(n, 1, 1).replace("\r", "\\n")))
        if a.png:
            gfx.img.save(a.png)
        return
    import tkinter as tk
    root = tk.Tk()
    App(root, min(16, max(0.25, a.speed)), a.seed)
    root.mainloop()


if __name__ == "__main__":
    main()
