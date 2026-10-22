#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RAWA_COUNTS - Python/Tkinter translation of the author's Visual FoxPro 9.0
program that counts 'right addressings' (RAs) and 'wrong addressings' (WAs)
(Dr. R. Beunis, 2022; vfp/rawa_counts.prg).

It accompanies the Addendum 'Random connectivity examined' of Beunis R. (2022)
"The electrosensory lateral line lobe in mormyrid fish : a stepping stone to
the understanding of the cerebellum ?" Part 2 (the cerebellum), Zenodo,
doi:10.5281/zenodo.17613147.

It is assumed that each timeslice of the A-path is affected by a set of GrCs
large enough to contain all input permutations, as determined by the
dimensionality of the ISU, the number of PPVs on each axis and the eventual
surnumerary dendrites.  The program
  - generates all possible input permutations and lists them,
  - lists the same permutations after an ordering procedure (ORDERINPUTS),
  - counts the totals of RAs and WAs and computes the RA ratio %,
  - counts how many permutations produce a specific number of WAs.

The translation follows the VFP code statement by statement and produces the
same text (checked against runs in Visual FoxPro 9).  One deliberate
difference: VFP prints the numbers in fixed-width fields (STR(n,5), the
15-character expression, RIGHT(STR(n,7),3)); a number that does not fit is
shown there as asterisks or loses its leading digits (e.g. 1295 WAs is shown as
'295').  Here such a field is widened instead, so that every number is shown in
full.  (count(..., exact=True) reproduces the VFP fields; it is only used to
check the translation against VFP.)

Usage:
    python rawa_counts.py                     (window with the input screen)
    python rawa_counts.py --dims 4 --ppv 4,4,4,4 --sur 0
                                              (text to the console)
"""

import argparse
import sys

AO = 96  # the 'ASCII offset' between 1 and ASC('a')


def vstr(n, width, exact):
    """VFP STR(n,width) for a whole number >= 0: asterisks when it does not fit
    (exact), else a widened field."""
    s = str(n)
    if len(s) > width:
        return '*' * width if exact else s
    return s.rjust(width)


def str_round(x):
    """VFP STR(x) (width 10, no decimals): rounds half up."""
    return str(int(x + 0.5)).rjust(10)


def alfabetic(c_in):
    """ALFABETIC: the characters of c_in in alphabetical order."""
    return ''.join(sorted(c_in))


def orderinputs(perm, dims, sur):
    """ORDERINPUTS: for the GrC the order of its inputs does not matter, so the
    permutation may be 'ordered': 'a' in place 1, 'b' in place 2 ... ; a lacking
    input leaves a blank, which is then filled with a redundant input."""
    ordered = [' '] * (dims + sur)
    rest = perm
    for i in range(1, dims + sur + 1):
        c = chr(i + AO)
        if c in rest:
            ordered[i - 1] = c
            rest = rest.replace(c, '', 1)
    for c in alfabetic(rest):
        # (only in 1D is there no blank left; VFP's STUFF at place 0 changes
        # nothing to the first character that is used)
        if ' ' in ordered:
            ordered[ordered.index(' ')] = c
    return ''.join(ordered)


def permutations(dims, sur):
    """The nested loops nA, nB, ..., nE, nP, nQ of the VFP program, with their
    EXITs: a loop of a dimension that is not there runs once."""
    rng = range(1, dims + 1)
    loops = [rng,                                   # nA
             rng if dims >= 2 else [1],             # nB (its letter is always used)
             rng if dims >= 3 else [1],             # nC
             rng if dims >= 4 else [1],             # nD
             rng if dims >= 5 else [1],             # nE
             rng if sur >= 1 else [1],              # nP
             rng if sur >= 2 else [1]]              # nQ
    used = [True, True, dims > 2, dims > 3, dims > 4, sur >= 1, sur == 2]

    def rec(k, prefix):
        if k == len(loops):
            yield prefix
            return
        for n in loops[k]:
            yield from rec(k + 1, prefix + (chr(n + AO) if used[k] else ''))
    return rec(0, '')


def count(dims, ppv, sur, exact=False):
    """Runs the program; returns its output as a list of lines (one per '?').
    ppv: the PPV numbers of the axes a..e (at least dims of them)."""
    pp = {chr(i + 1 + AO): ppv[i] for i in range(len(ppv))}
    out = []
    p = out.append
    if dims > 5:
        p("Too many dimensions")
        return out
    if sur > 2:
        p("Too many surnumerary dendrites")
        return out

    p("Your inputs : ")
    p("ISU dimensions : " + str(dims))
    for n in range(1, dims + 1):
        c = chr(n + AO)
        p("PPVs on " + c + "-axis : " + str(pp[c]))
    p("Added surnumerary dendrites : " + str(sur))
    p('')

    # The list of all the possible permutations and of their 'ordered' combinations
    perms = []
    combs = []
    for perm in permutations(dims, sur):
        perms.append(perm)
        combs.append(orderinputs(perm, dims, sur)[:dims])

    p("The original permutation list")
    p(''.join(x + ' ' for x in perms))
    p('')
    p('')
    p("The 'ordered' permutation list")
    p(''.join(x + ' ' for x in combs))
    p('')
    p('')

    ra_count = 0
    wa_count = 0
    wa_cats = []
    n_count = 0
    for comb in combs:
        n_count += 1
        # nWAsubcount is multiplied with the PPV number on each lacking dimension
        wa_sub = 1
        wa_expr = ' (1*'
        lis = ''  # the 'lacking inputs'
        for q in range(1, len(comb) + 1):
            if comb[q - 1] == chr(q + AO):  # this input is not lacking
                continue
            ref = chr(q + ord('a') - 1)
            lis += ref
            wa_sub *= pp[ref]
            wa_expr += str(pp[ref]) + '*'
        # subtract 1: every combination fires once at the right time (the RA)
        wa_sub -= 1
        wa_expr = wa_expr[:-1] + '-1)'
        wa_expr = wa_expr[:15].ljust(15) if exact else wa_expr.ljust(15)

        t = "GrC at RA fires every time the A-path engages a node in the " + lis + ' '
        kind = {1: "row", 2: "plane", 3: "volume", 4: "hypervolume"}.get(len(lis), '')
        p(comb + ' ' + vstr(1, 2, exact) + " RA " + vstr(wa_sub, 5, exact) + " WAs " + wa_expr +
          "  Lacking inputs : " + (lis + '   ')[:4] +
          ('' if len(lis) == 0 else " (" + t + kind + " in the " + str(len(comb)) + "D ISU)"))
        if n_count % 20 == 0:  # (VFP waits for a key after every 20 lines)
            p('')
            p('')

        ra_count += 1
        wa_count += wa_sub
        wa_cats.append(vstr(wa_sub, 7, True) if exact else wa_sub)

    p('')
    p("RA and WA count totals and the RA/(RA+WA) ratio")
    p(vstr(ra_count, 6, exact) + " RAs " + vstr(wa_count, 6, exact) + " WAs " +
      str_round(ra_count * 100 / (ra_count + wa_count)) + "% RAs")
    p('')

    # How many input combinations produce a specific number of WAs ?
    p("How many permutations produce a specific amount of WAs ?")
    p('')
    seen = {}
    for x in wa_cats:  # in the order of first appearance
        seen[x] = seen.get(x, 0) + 1
    for x, n in seen.items():
        shown = x[-3:] if exact else str(x).rjust(3)
        p(vstr(n, 5, exact) + " permutations causing " + shown +
          " WAs / causing a GrC to fire " + shown + " times at a wrong time")
    p('')
    p("Finished !")
    return out


def as_vfp_file(lines):
    """The text as VFP writes it with SET ALTERNATE: every '?' starts with CR LF."""
    return ''.join('\r\n' + x for x in lines)


# ----------------------------------------------------------------------------- window

def run_window():
    import tkinter as tk
    from tkinter import ttk

    root = tk.Tk()
    root.title("RA and WA counts – Beunis (2022b)")
    root.geometry("1100x720")

    frm = ttk.Frame(root, padding=8)
    frm.pack(side=tk.TOP, fill=tk.X)

    dims_v = tk.IntVar(value=4)
    sur_v = tk.IntVar(value=0)
    ppv_v = [tk.IntVar(value=4) for _ in range(5)]

    ttk.Label(frm, text="ISU dimensions (1–5):").grid(row=0, column=0, sticky='w')
    ttk.Spinbox(frm, from_=1, to=5, width=4, textvariable=dims_v, state='readonly',
                command=lambda: update_axes()).grid(row=0, column=1, sticky='w', padx=4)
    ttk.Label(frm, text="Surnumerary dendrites (0–2):").grid(row=0, column=2, sticky='w', padx=(16, 0))
    ttk.Spinbox(frm, from_=0, to=2, width=4, textvariable=sur_v,
                state='readonly').grid(row=0, column=3, sticky='w', padx=4)

    ttk.Label(frm, text="PPVs on each axis (1–99):").grid(row=1, column=0, sticky='w', pady=(6, 0))
    spins = []
    axf = ttk.Frame(frm)
    axf.grid(row=1, column=1, columnspan=6, sticky='w', pady=(6, 0))
    for i in range(5):
        ttk.Label(axf, text=chr(97 + i) + ":").pack(side=tk.LEFT, padx=(6 if i else 0, 2))
        s = ttk.Spinbox(axf, from_=1, to=99, width=4, textvariable=ppv_v[i])
        s.pack(side=tk.LEFT)
        spins.append(s)

    def update_axes():
        for i, s in enumerate(spins):
            s.configure(state='normal' if i < dims_v.get() else 'disabled')

    status = ttk.Label(frm, text="")
    status.grid(row=2, column=4, columnspan=3, sticky='w', pady=(6, 0))

    txtf = ttk.Frame(root)
    txtf.pack(side=tk.TOP, fill=tk.BOTH, expand=True, padx=8, pady=(0, 8))
    txt = tk.Text(txtf, wrap='char', font=('Courier New', 10))
    sb = ttk.Scrollbar(txtf, orient='vertical', command=txt.yview)
    txt.configure(yscrollcommand=sb.set)
    sb.pack(side=tk.RIGHT, fill=tk.Y)
    txt.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

    def go():
        try:
            dims = dims_v.get()
            ppv = [max(1, min(99, int(v.get()))) for v in ppv_v]
        except (tk.TclError, ValueError):
            status.configure(text="Please enter whole numbers.")
            return
        for v, n in zip(ppv_v, ppv):
            v.set(n)
        status.configure(text="Counting ...")
        root.update_idletasks()
        lines = count(dims, ppv, sur_v.get())
        txt.delete('1.0', tk.END)
        txt.insert('1.0', '\n'.join(lines))
        status.configure(text="")

    ttk.Button(frm, text="Count", command=go).grid(row=0, column=4, rowspan=2, padx=(24, 0))
    update_axes()
    go()
    root.mainloop()


def main():
    ap = argparse.ArgumentParser(description="RA and WA counts (Beunis 2022b, Addendum)")
    ap.add_argument('--dims', type=int, help="ISU dimensions (1-5)")
    ap.add_argument('--ppv', default='4,4,4,4,4', help="PPVs on the axes a,b,c,d,e (comma separated)")
    ap.add_argument('--sur', type=int, default=0, help="surnumerary dendrites (0-2)")
    ap.add_argument('--vfp-file', action='store_true', help="write CR LF before every line, as VFP's SET ALTERNATE")
    a = ap.parse_args()
    if a.dims is None:
        run_window()
        return
    ppv = [int(x) for x in a.ppv.split(',')]
    ppv += [4] * (5 - len(ppv))
    lines = count(a.dims, ppv, a.sur)
    if a.vfp_file:
        sys.stdout.buffer.write(as_vfp_file(lines).encode('cp1252'))
    else:
        print('\n'.join(lines))


if __name__ == '__main__':
    main()
