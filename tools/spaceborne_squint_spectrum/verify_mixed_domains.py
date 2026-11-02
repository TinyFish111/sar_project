"""用连续求积核验两种混合域、反演关系与距离压缩自相关。

为让积分边缘误差可控，额外选择有解析频谱的高斯调频脉冲。
它是核验工具的测试波形，不改变正文矩形脉冲和一般 p 的表达式。
慢时间 eta 为一维（s），快时间频率为一维（Hz）；分块积分矩阵
的行为距离频率、列为慢时间，单位明确区别于原始回波矩阵约定。
"""

from pathlib import Path
import json

import numpy as np
from scipy.integrate import quad, simpson
import sympy as sp

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "scratch" / "spaceborne_squint_spectrum" / "verification"
LIGHT_SPEED = 299792458.0
CARRIER = 1e9
RANGE = 30000.0
VELOCITY = 250.0
SQUINT = np.pi / 6
HALF_APERTURE = 0.04
PULSE_SCALE = 0.3e-6
CHIRP_RATE = 3e12
GAUSSIAN_REAL = 1 / (2 * PULSE_SCALE**2)
GAUSSIAN_COMPLEX = GAUSSIAN_REAL - 1j * np.pi * CHIRP_RATE


def pulse(time):
    return np.exp(-GAUSSIAN_COMPLEX * np.asarray(time) ** 2)


def pulse_spectrum(frequency):
    return np.sqrt(np.pi / GAUSSIAN_COMPLEX) * np.exp(
        -np.pi**2 * np.asarray(frequency) ** 2 / GAUSSIAN_COMPLEX
    )


def range_change(eta):
    """稳定计算变化斜距；返回值单位 m，避免相近大数相减。"""
    reference_range = RANGE / np.cos(SQUINT)
    closing_speed = VELOCITY * np.sin(SQUINT)
    closest_time = RANGE * np.tan(SQUINT) / VELOCITY
    distance = np.sqrt(RANGE**2 + VELOCITY**2 * (eta - closest_time) ** 2)
    return (VELOCITY**2 * eta**2 - 2 * reference_range * closing_speed * eta) / (
        distance + reference_range
    )


def complex_quad(function, lower, upper):
    return (
        quad(lambda x: function(x).real, lower, upper, epsabs=1e-12)[0]
        + 1j * quad(lambda x: function(x).imag, lower, upper, epsabs=1e-12)[0]
    )


def verify_raw_stationary_derivatives():
    eta, tau, fc, fa, kr = sp.symbols("eta tau fc fa kr", real=True)
    c = sp.symbols("c", positive=True)
    distance = sp.Function("R")(eta)
    offset = tau - 2 * distance / c
    phase = (
        4 * sp.pi * fc * distance / c + 2 * sp.pi * fa * eta - sp.pi * kr * offset**2
    )
    first = 4 * sp.pi / c * (fc + kr * offset) * sp.diff(distance, eta) + 2 * sp.pi * fa
    second = (
        4
        * sp.pi
        / c
        * (
            (fc + kr * offset) * sp.diff(distance, eta, 2)
            - 2 * kr / c * sp.diff(distance, eta) ** 2
        )
    )
    assert sp.simplify(sp.diff(phase, eta) - first) == 0
    assert sp.simplify(sp.diff(phase, eta, 2) - second) == 0


def main():
    verify_raw_stationary_derivatives()
    wave_number = 4 * np.pi * CARRIER / LIGHT_SPEED
    normalization = abs(pulse_spectrum(0.0))
    frequency_time_errors = []
    for eta in [-0.02, 0.0, 0.02]:
        change = range_change(eta)
        for frequency in [-2e6, 0.0, 2e6]:
            # 积分变量 t=(tau-d)/T 无量纲；保留对参考快时间原点的相位。
            numeric = (
                PULSE_SCALE
                * complex_quad(
                    lambda t: pulse(PULSE_SCALE * t)
                    * np.exp(
                        -2j
                        * np.pi
                        * frequency
                        * (2 * change / LIGHT_SPEED + PULSE_SCALE * t)
                    ),
                    -10,
                    10,
                )
                * np.exp(-1j * wave_number * change)
            )
            analytic = pulse_spectrum(frequency) * np.exp(
                -4j * np.pi * (CARRIER + frequency) * change / LIGHT_SPEED
            )
            frequency_time_errors.append(float(abs(numeric - analytic) / normalization))

    frequencies = np.linspace(-12e6, 12e6, 4097)
    eta = np.linspace(-HALF_APERTURE, HALF_APERTURE, 2001)
    change = range_change(eta)
    amplitude = (1 - (eta / HALF_APERTURE) ** 2) ** 4
    doppler_center = 2 * CARRIER * VELOCITY * np.sin(SQUINT) / LIGHT_SPEED
    rows = []
    for doppler_offset in [-20.0, 0.0, 20.0]:
        fa = doppler_center + doppler_offset
        slow_phase = wave_number * change + 2 * np.pi * fa * eta
        centered_geometry = np.empty(frequencies.size, dtype=complex)
        for start in range(0, frequencies.size, 256):
            selected = frequencies[start : start + 256]
            phase = (
                slow_phase[None, :]
                + 4 * np.pi / LIGHT_SPEED * selected[:, None] * change[None, :]
            )
            centered_geometry[start : start + selected.size] = simpson(
                amplitude[None, :] * np.exp(-1j * phase), x=eta, axis=1
            )
        for fast_offset in [-0.6e-6, 0.0, 0.6e-6]:
            # 去除相同的常数载频相位，tau=d(0)+fast_offset。
            integrand = (
                amplitude
                * pulse(fast_offset - 2 * change / LIGHT_SPEED)
                * np.exp(-1j * slow_phase)
            )
            direct = simpson(integrand, x=eta)
            coarse = simpson(integrand[::2], x=eta[::2])
            inverse = simpson(
                pulse_spectrum(frequencies)
                * centered_geometry
                * np.exp(2j * np.pi * frequencies * fast_offset),
                x=frequencies,
            )
            rows.append(
                {
                    "doppler_offset_hz": doppler_offset,
                    "fast_time_offset_s": fast_offset,
                    "relative_two_route_error": float(
                        abs(inverse - direct) / abs(direct)
                    ),
                    "relative_eta_grid_change": float(
                        abs(direct - coarse) / abs(direct)
                    ),
                }
            )

    correlation_errors = []
    for shift in [-2 * PULSE_SCALE, 0.0, 2 * PULSE_SCALE]:
        direct = PULSE_SCALE * complex_quad(
            lambda t: pulse(PULSE_SCALE * t) * np.conj(pulse(PULSE_SCALE * t - shift)),
            -12,
            12,
        )
        inverse = simpson(
            abs(pulse_spectrum(frequencies)) ** 2
            * np.exp(2j * np.pi * frequencies * shift),
            x=frequencies,
        )
        exact = np.sqrt(np.pi / (2 * GAUSSIAN_REAL)) * np.exp(
            -abs(GAUSSIAN_COMPLEX) ** 2 * shift**2 / (2 * GAUSSIAN_REAL)
        )
        correlation_errors.append(
            float(
                max(abs(direct - exact), abs(inverse - exact))
                / np.sqrt(np.pi / (2 * GAUSSIAN_REAL))
            )
        )

    summary = {
        "raw_rd_stationary_derivatives_passed": True,
        "frequency_time_max_error_normalized_by_peak_spectrum": max(
            frequency_time_errors
        ),
        "rd_max_relative_two_route_error": max(
            row["relative_two_route_error"] for row in rows
        ),
        "rd_max_relative_eta_grid_change": max(
            row["relative_eta_grid_change"] for row in rows
        ),
        "correlation_max_error_normalized_by_peak": max(correlation_errors),
        "parameters": {
            "closest_range_m": RANGE,
            "velocity_m_s": VELOCITY,
            "carrier_hz": CARRIER,
            "effective_squint_deg": 30,
            "half_aperture_s": HALF_APERTURE,
            "gaussian_time_scale_s": PULSE_SCALE,
            "chirp_rate_hz_per_s": CHIRP_RATE,
            "eta_samples": eta.size,
            "frequency_samples": frequencies.size,
            "frequency_limits_hz": [-12e6, 12e6],
        },
        "rd_route_checks": rows,
    }
    assert summary["frequency_time_max_error_normalized_by_peak_spectrum"] < 1e-10
    assert summary["rd_max_relative_two_route_error"] < 1e-8
    assert summary["rd_max_relative_eta_grid_change"] < 1e-8
    assert summary["correlation_max_error_normalized_by_peak"] < 1e-10
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "mixed_domain_checks.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
