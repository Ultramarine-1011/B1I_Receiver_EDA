"""Window-domain lock evidence, separate from per-window error validity.

The numerical quality metrics come from measured correlations only. A single
unusable window freezes loop updates but does not necessarily imply loss of lock.
"""


class LockEvidence:
    def __init__(self):
        self.history = self.population = self.seen = self.invalid_run = 0
        self.carrier_good = self.code_good = self.carrier_bad = self.code_bad = 0
        self.carrier_lock = self.code_lock = False

    def update(self, usable: bool, pll_mode: bool, phase_mean_square: float,
               frequency_mean_hz: float, code_mean_chips: float):
        oldest = (self.history >> 127) & 1
        self.history = ((self.history << 1) | int(usable)) & ((1 << 128)-1)
        self.population += int(usable) - oldest
        self.seen = min(self.seen+1, 128)
        self.invalid_run = 0 if usable else self.invalid_run+1
        evidence = self.seen == 128 and self.population >= 64
        carrier_good = (evidence and pll_mode and phase_mean_square < 0.05**2
                        and abs(frequency_mean_hz) < 10)
        code_good = evidence and abs(code_mean_chips) < 0.10
        self.carrier_good = self.carrier_good+1 if carrier_good else 0
        self.code_good = self.code_good+1 if code_good else 0
        self.carrier_bad = 0 if carrier_good else self.carrier_bad+1
        self.code_bad = 0 if code_good else self.code_bad+1
        if self.invalid_run >= 16:
            self.carrier_lock = self.code_lock = False
            self.carrier_good = self.code_good = 0
        else:
            if self.carrier_good >= 32:
                self.carrier_lock = True
            elif self.carrier_bad >= 4:
                self.carrier_lock = False
            if self.code_good >= 32:
                self.code_lock = True
            elif self.code_bad >= 4:
                self.code_lock = False
        return self.carrier_lock, self.code_lock


def self_test():
    detector = LockEvidence()
    for k in range(512):
        # Seventy-five percent usable, never 32 consecutive usable windows.
        detector.update(k % 4 != 0, True, 0.01**2, 0.5, 0.02)
    assert detector.carrier_lock and detector.code_lock
    for _ in range(15):
        detector.update(False, True, 0.01**2, 0.5, 0.02)
    assert detector.carrier_lock and detector.code_lock
    detector.update(False, True, 0.01**2, 0.5, 0.02)
    assert not detector.carrier_lock and not detector.code_lock
    noise = LockEvidence()
    for k in range(1024):
        # Favorable instantaneous phase alone cannot lock sparse noise peaks.
        noise.update(k % 32 == 0, True, 0.0, 0.0, 0.0)
    assert not noise.carrier_lock and not noise.code_lock
    for _ in range(300):
        detector.update(True, True, 0.0, 0.0, 0.0)
    assert detector.carrier_lock and detector.code_lock
    for _ in range(4):
        detector.update(True, True, 0.2**2, 0.0, 0.0)
    assert not detector.carrier_lock and detector.code_lock
    return True


if __name__ == '__main__':
    self_test()
    print('LOCK_EVIDENCE_MODEL_PASS')
