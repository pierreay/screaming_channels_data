#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

for i in list(range(10)):
    plt.plot(np.load("./amp__{}.npy".format(i)))
    plt.show()
