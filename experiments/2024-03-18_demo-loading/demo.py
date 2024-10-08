#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

# * Library

# Custom dtype used to store our datasets.
DTYPE = np.dtype([('real', np.int16), ('imag', np.int16)])

def dtype_to_complex64(arr):
    """Convert our custom dtype to standard Numpy format."""
    return arr.view(np.int16).astype(np.float32).view(np.complex64)

def load_traces(fmt):
    traces_iq = []
    i = 0
    # Assume first trace of the dataset to be correctly recorded.
    ref_trace = dtype_to_complex64(np.fromfile(fmt.format(0), dtype=DTYPE))
    while True:
        try:
            candidate = fmt.format(i)
            trace_iq = dtype_to_complex64(np.fromfile(candidate, dtype=DTYPE))
        except:
            break
        else:
            # Set bad recorded entries to zeros.
            if trace_iq.shape != ref_trace.shape:
                print("Replace {} with zeroes".format(candidate))
                traces_iq.append(np.zeros(ref_trace.shape, dtype=ref_trace.dtype))
            else:
                traces_iq.append(trace_iq)
            i += 1
    return np.array(traces_iq), i

# * Load the data

train_traces_iq, train_traces_nb = load_traces("train/{}_trace_ff.npy")
train_keys = np.load("train/k.npy")
train_plaintexts = np.load("train/p.npy")

attack_traces_iq, attack_traces_nb = load_traces("attack/{}_trace_ff.npy")
attack_keys = np.load("attack/k.npy")
attack_plaintexts = np.load("attack/p.npy")

print("Train traces: {} loaded".format(train_traces_nb))
print(np.shape(train_traces_iq))
print("Train keys:")
print(np.shape(train_keys))
print("Train plaintexts:")
print(np.shape(train_plaintexts))

print("Attack traces: {} loaded".format(attack_traces_nb))
print(np.shape(attack_traces_iq))
print("Attack keys:")
print(np.shape(attack_keys))
print("Attack plaintexts:")
print(np.shape(attack_plaintexts))

# * Compute traces to test (train from and to attack)

# Amplitude
train_traces_amp = np.abs(train_traces_iq)
attack_traces_amp = np.abs(attack_traces_iq)
# I
train_traces_i = np.real(train_traces_iq)
attack_traces_i = np.real(attack_traces_iq)
# Q
train_traces_q = np.imag(train_traces_iq)
attack_traces_q = np.imag(attack_traces_iq)

# * Plot some traces to check

plt.plot(train_traces_amp[0])
plt.title("Amplitude trace of signal 0 from training set")
plt.show()

plt.plot(train_traces_i[0])
plt.title("I trace of signal 0 from training set")
plt.show()

plt.plot(train_traces_q[0])
plt.title("Q trace of signal 0 from training set")
plt.show()
