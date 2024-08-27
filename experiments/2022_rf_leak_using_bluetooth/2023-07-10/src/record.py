#!/usr/bin/python3

import os
from threading import Thread
from contextlib import nullcontext

import numpy as np
import SoapySDR

from screamingchannels import analyze
from screamingchannels import radio
from screamingchannels import config
from screamingchannels import device
from screamingchannels import log as l

RET_EXIT_AND_RESUME = 3

# WARN: Have to be set accordingly when changing center frequency in `.envrc`.
TARGET_FREQS   = [127e6, 2.547e9]
# Due to recording limitations (see MySoapySDRs.register()) and ploting
# limitations (see plot.py), the radios have to use the same sampling rate &
# bandwidth.
SAMPLING_RATES = [30e6, 30e6]

class MySoapySDRs():
    def __init__(self):
        l.LOGGER.debug("MySoapySDRs.__init__()")
        self.sdrs = []

    def register(self, sdr):
        l.LOGGER.debug("MySoapySDRs.register(idx={})".format(sdr.idx))
        self.sdrs.append(sdr)
        # Temporary hack to be compatible with nrf52_whad.py who access
        # self.radio.fs variable. This imply to have the same sampling rate
        # accross two SDRs.
        self.fs = sdr.fs

    def open(self):
        l.LOGGER.debug("MySoapySDRs.open()")
        for sdr in self.sdrs:
            sdr.open()

    def close(self):
        l.LOGGER.debug("MySoapySDRs.close()")
        for sdr in self.sdrs:
            sdr.close()

    def record(self, N):
        l.LOGGER.debug("MySoapySDRs.record(N={}).enter".format(N))
        thr = [None] * len(self.sdrs)
        for sdr in self.sdrs:
            thr[sdr.idx] = Thread(target=sdr.record, args=(N,))
            thr[sdr.idx].start()
        for sdr in self.sdrs:
            thr[sdr.idx].join()
        l.LOGGER.debug("MySoapySDRs.record(N={}).exit".format(N))

    def accept(self):
        l.LOGGER.debug("MySoapySDRs.accept()")
        for sdr in self.sdrs:
            sdr.accept()

    def save(self, dir, file):
        l.LOGGER.debug("MySoapySDRs.save(dir={}, file={})".format(dir, file))
        for sdr in self.sdrs:
            sdr.save(dir, file)

class MySoapySDR():
    def __init__(self, fs, freq, idx = 0):
        l.LOGGER.debug("MySoapySDR.__init__(fs={},freq={},idx={})".format(fs, freq, idx))
        self.fs = fs
        self.freq = freq
        self.idx = idx
        results = SoapySDR.Device.enumerate()
        self.sdr = SoapySDR.Device(results[idx])
        self.sdr.setSampleRate(SoapySDR.SOAPY_SDR_RX, 0, fs)
        self.sdr.setFrequency(SoapySDR.SOAPY_SDR_RX, 0, freq)
        self.sdr.setGain(SoapySDR.SOAPY_SDR_RX, 0, 76)
        self.sdr.setAntenna(SoapySDR.SOAPY_SDR_RX, 0, "TX/RX")

    def open(self):
        l.LOGGER.debug("MySoapySDR(idx={}).open()".format(self.idx))
        self.rx_stream = self.sdr.setupStream(SoapySDR.SOAPY_SDR_RX, SoapySDR.SOAPY_SDR_CF32)
        self.sdr.activateStream(self.rx_stream)
        self.rx_signal = np.array([0], np.complex64)

    def close(self):
        l.LOGGER.debug("MySoapySDR(idx={}).close().enter".format(self.idx))
        self.sdr.deactivateStream(self.rx_stream)
        self.sdr.closeStream(self.rx_stream)
        l.LOGGER.debug("MySoapySDR(idx={}).close().leave".format(self.idx))

    def record(self, N):
        l.LOGGER.debug("MySoapySDR(idx={}).record(N={:e}).enter".format(self.idx, N))
        N = int(N) # Required when N is specified using scientific notation.
        rx_buff_len = pow(2, 24)
        rx_buff = np.array([0] * rx_buff_len, np.complex64)
        self.rx_signal_candidate = np.array([0], np.complex64)
        while len(self.rx_signal_candidate) < N:
            sr = self.sdr.readStream(self.rx_stream, [rx_buff], rx_buff_len, timeoutUs=10000000)
            if sr.ret == rx_buff_len and sr.flags == 1 << 2:
                self.rx_signal_candidate = np.concatenate((self.rx_signal_candidate, rx_buff))
        l.LOGGER.debug("MySoapySDR(idx={}).record().leave".format(self.idx))

    def accept(self):
        l.LOGGER.debug("MySoapySDR(idx={}).accept()".format(self.idx))
        self.rx_signal = np.concatenate((self.rx_signal, self.rx_signal_candidate))

    def save(self, dir, file, abs = True):
        path = "{}/USRP_{}-{}MHz-{}Msps_{}.npy".format(dir, self.idx, TARGET_FREQS[self.idx] / 1e6, SAMPLING_RATES[self.idx] / 1e6, file)
        l.LOGGER.debug("MySoapySDR(idx={}).save(path={},abs={})".format(self.idx, path, abs))
        np.save(path, self.rx_signal if not abs else np.abs(self.rx_signal))

if __name__ == "__main__":
    cli_config = config.CliConfig(device_baudrate=115200,
                                  device_serial=os.getenv("TARGET_ADDR"),
                                  radio=radio.RadioType.USRP,
                                  radio_address="",
                                  radio_antenna="TX/RX",
                                  radio_frontend="",
                                  outfile="/tmp/gr_sink",
                                  loglevel="DEBUG",
                                  logfile="",
                                  ykush_port=0,
                                  ykush_serial="")

    collection_config = config.CollectionConfig(num_points=1,
                                                num_traces_per_point=1)

    # TODO Obsolete, to delete, replaced by SAMPLING_RATES and TARGET_FREQS global variables.
    radio_config = config.RadioConfig(target_freq=127e6,
                                      sampling_rate=30e6,
                                      usrp_gain=76)

    preprocess_config = config.PreprocessConfig(drop_start=3.05e-1,
                                                drop_end=3.8e-2)

    postprocess_config = config.PostprocessConfig(trigger_bandpass_lower=8.2e6,
                                                  trigger_bandpass_upper=9.2e6,
                                                  trigger_lowpass=1e4,
                                                  trigger_threshold=0.7,
                                                  trigger_length=1.4e-4,
                                                  trigger_skip=0,
                                                  trace_offset=-5.4e-5,
                                                  trace_length=3e-4,
                                                  template_autocorr_ratio=0.93,
                                                  template_name="template.npy")

    file_config = config.FileConfig(collection_config, radio_config, preprocess_config, postprocess_config)

    device_config = {"type": "NRF52_WHAD",
                     "fixed_plaintext": False,
                     "ltk_path": "/tmp/mirage_output_ltk",
                     "addr_path": "/tmp/mirage_output_addr",
                     "rand_path": "/tmp/mirage_output_rand",
                     "ediv_path": "/tmp/mirage_output_ediv"
                     }

    outpath = "/tmp"
    plot = True
    plot_out = ""
    template_out = "template.npy"
    explore = False
    resume = False
    resume_nb = 0

    l.init(cli_config.logfile, cli_config.loglevel)

    rad1 = MySoapySDR(SAMPLING_RATES[0], TARGET_FREQS[0], 0)
    rad2 = MySoapySDR(SAMPLING_RATES[1], TARGET_FREQS[1], 1)
    rad = MySoapySDRs()
    rad.register(rad1)
    rad.register(rad2)
    rad.open()

    with device.Device.create(device_config, baud=cli_config.device_baudrate, ser=cli_config.device_serial) as dev:
        dev.generate(num=file_config.collection.num_points, path=outpath)
        dev.init(rep=file_config.collection.num_traces_per_point)
        dev.radio = rad

        for idx in list(range(file_config.collection.num_points)):
            dev.configure(idx)
            try:
                dev.execute()
            except OSError as e:
                l.log_n_exit(e, e.strerror, RET_EXIT_AND_RESUME, traceback=True)
            dev.reset()

    rad.save("/tmp", "raw_abs")
    rad.close()
