#!/bin/bash

SCRIPT_WD="$(dirname $(realpath $0))"

# * Plot the subclock intermodulation

function plot_sub_clock() {
    export DIR=ff; export FC=2.500e9; export SR=56e6; G=76
    echo DIR=$DIR; echo FC=$FC; echo SR=$SR; echo G=$G
    file=$SCRIPT_WD/$DIR/FC_${FC}_SR_${SR}_${G}db${SUFFIX}.npy
    python3 << EOF
import numpy as np
import matplotlib.pyplot as plt
import lib.plot as libplot
import lib.complex as complex

sig = np.load("$file")

libplot.enable_latex_fonts()
fig, (ax_ampl) = plt.subplots(nrows=1, ncols=1)
ax_ampl.specgram(sig, mode="magnitude", sides="twosided", NFFT=256, Fc=$FC, Fs=$SR)
ax_ampl.set_xlabel("Sample [\#]")
ax_ampl.set_xlim(left=0.1535, right=0.1560)
ax_ampl.set_ylabel("Frequency [Hz]")
#ax_ampl.set_ylim(bottom=2.472e9, top=2.547e9)
ax_ampl.axhline(y=2.496e9, label="2.496 GHz")

# plt.subplots_adjust(top=0.35)
plt.legend()
#plt.show()
plt.savefig("subclock_intermodulation.pdf")
EOF
}

# DONE: Use a custom Python to plot the FF wide band at 2.500e9, keeping only
# the specgram of the amplitude, and show how we can observe the 3rd harmonic of
# the 32 MHz sub-clock at 2.496e9 by looking at the mirror-looking AES signal.
# plot_sub_clock

# * Plot leak in NF

function plot_nf_leak() {
    export DIR=nf; export FC=138e6; export SR=8e6; G=76
    echo DIR=$DIR; echo FC=$FC; echo SR=$SR; echo G=$G
    file=$SCRIPT_WD/$DIR/FC_${FC}_SR_${SR}_${G}db${SUFFIX}.npy
    outplot="nf_amplitude_and_phase_rotation.pdf"
    echo "Press 's' to save fig to $outplot"
    python3 << EOF
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import lib.plot as libplot
import lib.complex as complex

sig = np.load("$file")

libplot.enable_latex_fonts()
quadplot = libplot.SignalQuadPlot(sig, sr=$SR, fc=$FC)

quadplot.sync = False
quadplot.sos_filter_ampl_time = signal.butter(1, 0.5e6, 'low', fs=$SR, output='sos')
quadplot.sos_filter_phase_time = signal.butter(1, 0.5e6, 'low', fs=$SR, output='sos')
quadplot.plot_init()

quadplot.ax_ampl_time.set_xlabel("Sample [\#]")
quadplot.ax_ampl_freq.set_xlabel("Time [s]")
quadplot.ax_phase_time.set_xlabel("Sample [\#]")
quadplot.ax_phase_freq.set_xlabel("Time [s]")

quadplot.ax_ampl_time.set_xlim(left=1.563e6, right=1.5693e6)
quadplot.ax_phase_time.set_xlim(left=1.563e6, right=1.5693e6)
quadplot.ax_ampl_time.set_ylim(bottom=1200, top=3200)
quadplot.ax_phase_time.set_ylim(bottom=-2, top=2.3)

quadplot.ax_ampl_freq.set_xlim(left=0.1953, right=0.1987)
quadplot.ax_phase_freq.set_xlim(left=0.1953, right=0.1987)

quadplot.plot()
# savefig doesn't output the same as interactive plot.
# quadplot.plot(save="$outplot")
EOF
    mv "$HOME/$outplot" "$SCRIPT_WD"
}

# DONE: Use a custom Python to plot the NF narrow band, without x axis sync,
# and show how the full AES looks like in amplitude and phase for both time and
# frequency.
# plot_nf_leak

# * Plot leak in FF

function plot_ff_leak() {
    export DIR=ff; export FC=2.510e9; export SR=8e6; G=76
    echo DIR=$DIR; echo FC=$FC; echo SR=$SR; echo G=$G
    file=$SCRIPT_WD/$DIR/FC_${FC}_SR_${SR}_${G}db${SUFFIX}.npy
    outplot="ff_amplitude_and_phase_rotation.pdf"
    echo "Press 's' to save fig to $outplot"
    python3 << EOF
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import lib.plot as libplot
import lib.complex as complex

sig = np.load("$file")

libplot.enable_latex_fonts()
quadplot = libplot.SignalQuadPlot(sig, sr=$SR, fc=$FC)

quadplot.sync = False
quadplot.sos_filter_ampl_time = signal.butter(1, 0.5e6, 'low', fs=$SR, output='sos')
quadplot.sos_filter_phase_time = signal.butter(1, 0.5e6, 'low', fs=$SR, output='sos')
quadplot.plot_init()

quadplot.ax_ampl_time.set_xlabel("Sample [\#]")
quadplot.ax_ampl_freq.set_xlabel("Time [s]")
quadplot.ax_phase_time.set_xlabel("Sample [\#]")
quadplot.ax_phase_freq.set_xlabel("Time [s]")

quadplot.ax_ampl_time.set_xlim(left=1.525e6, right=1.5316e6)
quadplot.ax_phase_time.set_xlim(left=1.525e6, right=1.5316e6)
quadplot.ax_ampl_time.set_ylim(bottom=800, top=2800)
quadplot.ax_phase_time.set_ylim(bottom=-2.1, top=2.3)

quadplot.ax_ampl_freq.set_xlim(left=0.1905, right=0.1940)
quadplot.ax_phase_freq.set_xlim(left=0.1905, right=0.1940)

quadplot.plot()
# savefig doesn't output the same as interactive plot.
# quadplot.plot(save="$outplot")
EOF
    mv "$HOME/$outplot" "$SCRIPT_WD"
}

# DONE: Use a custom Python to plot the FF narrow band at 2.510e8, without x
# axis sync, and show how the full AES looks like in amplitude and phase for
# both time and frequency.
# plot_ff_leak
