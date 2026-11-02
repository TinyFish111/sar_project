"""核验孔径内时不变、目标距离间变化的等效速度频谱推导。

不生成正式回波。每个目标的慢时间数组为一维（s），距离为最近斜距（m）。
同一目标的 V_r 是常数，目标间由 V_r(r) 决定；不混淆时间导数与距离导数。
"""

from pathlib import Path
import json
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy.integrate import quad, simpson
from scipy.special import fresnel
import sympy as sp

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "scratch" / "spaceborne_squint_spectrum" / "verification"
OUTPUT.mkdir(parents=True, exist_ok=True)
C_LIGHT = 299792458.0
FC, BANDWIDTH, HALF_APERTURE = 5.3e9, 100e6, 4.0
REFERENCE_RANGE, REFERENCE_SPEED, VELOCITY_SLOPE = 800000.0, 7100.0, 0.001
THETA = np.pi / 4


def equivalent_velocity(r):
    """只随目标最近斜距变化的教学函数，r 的单位 m，返回 m/s。"""
    return REFERENCE_SPEED + VELOCITY_SLOPE * (r - REFERENCE_RANGE)


def target_parameters(r):
    velocity = float(equivalent_velocity(r))
    return (
        velocity,
        r / np.cos(THETA),
        velocity * np.sin(THETA),
        r * np.tan(THETA) / velocity,
    )


def range_state(eta, r):
    """求同一目标的时间导数时，其距离标签及等效速度都固定。"""
    velocity, r0, u0, tc = target_parameters(r)
    eta = np.asarray(eta, dtype=float)
    distance = np.sqrt(r * r + velocity**2 * (eta - tc) ** 2)
    rate = velocity**2 * (eta - tc) / distance
    curvature = velocity**2 * r * r / distance**3
    # 有理化计算变化距离，避免两个相近的大距离直接相减。
    change = (velocity**2 * eta**2 - 2 * r0 * u0 * eta) / (distance + r0)
    return distance, rate, curvature, change


def verify_symbolic():
    eta, tc = sp.symbols("eta tc", real=True)
    r, velocity = sp.symbols("r V", positive=True)
    distance = sp.sqrt(r * r + velocity**2 * (eta - tc) ** 2)
    rate = velocity**2 * (eta - tc) / distance
    curvature = velocity**2 * r * r / distance**3
    assert sp.simplify(sp.diff(distance, eta) - rate) == 0
    assert sp.simplify(sp.diff(rate, eta) - curvature) == 0
    assert (
        sp.simplify(
            sp.diff(curvature, eta) + 3 * velocity**4 * r * r * (eta - tc) / distance**5
        )
        == 0
    )
    f, beta = sp.symbols("F beta", positive=True)
    q = sp.sqrt(f * f - beta * beta)
    assert sp.simplify(sp.diff(q, f) - f / q) == 0
    assert sp.simplify(sp.diff(q, f, 2) + beta**2 / q**3) == 0
    assert sp.simplify(sp.diff(q, f, 3) - 3 * beta**2 * f / q**5) == 0
    varying_velocity = sp.Function("V")(r)
    q_range = sp.sqrt(f * f - beta**2 / varying_velocity**2)
    expected = beta**2 * sp.diff(varying_velocity, r) / (q_range * varying_velocity**3)
    assert sp.simplify(sp.diff(q_range, r) - expected) == 0
    alpha = sp.symbols("alpha", real=True)
    d = sp.sqrt(1 - alpha * alpha)
    x, rs = alpha * r / (velocity * d), r / d
    assert sp.simplify(velocity * x - alpha * rs) == 0
    assert sp.simplify(rs - velocity * alpha * x - r * d) == 0
    return True


def verify_fresnel():
    errors, pulse_width = [], 20e-6
    for chirp_rate in [2e11, -2e11]:
        for frequency in [-2e6, 0.0, 1.5e6, 3e6]:
            za, zb = np.sqrt(2 * abs(chirp_rate)) * (
                np.array([-pulse_width / 2, pulse_width / 2]) - frequency / chirp_rate
            )
            sa, ca = fresnel(za)
            sb, cb = fresnel(zb)
            analytic = np.exp(-1j * np.pi * frequency**2 / chirp_rate) / np.sqrt(
                2 * abs(chirp_rate)
            )
            analytic *= cb - ca + 1j * np.sign(chirp_rate) * (sb - sa)

            def value(t):
                u = t * pulse_width
                return np.exp(
                    1j * np.pi * chirp_rate * u * u - 2j * np.pi * frequency * u
                )

            numeric = pulse_width * (
                quad(
                    lambda t: value(t).real,
                    -0.5,
                    0.5,
                    epsabs=1e-12,
                    epsrel=1e-12,
                    limit=600,
                )[0]
                + 1j
                * quad(
                    lambda t: value(t).imag,
                    -0.5,
                    0.5,
                    epsabs=1e-12,
                    epsrel=1e-12,
                    limit=600,
                )[0]
            )
            errors.append(abs(analytic - numeric) / pulse_width)
    assert max(errors) < 1e-11
    return max(errors)


def main():
    symbolic_ok, fresnel_error = verify_symbolic(), verify_fresnel()
    targets, integrals_summary, phase_errors, time_errors, phase_algebra_errors = (
        [],
        [],
        [],
        [],
        [],
    )
    times_plot = np.linspace(-HALF_APERTURE, HALF_APERTURE, 1001)
    for r in [700000.0, 800000.0, 900000.0]:
        velocity, r0, u0, tc = target_parameters(r)
        actual_range = range_state(times_plot, r)[0]
        # 保持 R0 和 u0，单独比较全场景误用同一个速度的后果。
        wrong_range = np.sqrt(
            r0 * r0 - 2 * r0 * u0 * times_plot + REFERENCE_SPEED**2 * times_plot**2
        )
        delta = actual_range - wrong_range
        k0 = 4 * np.pi * FC / C_LIGHT
        phase_errors.append(k0 * delta)
        targets.append(
            {
                "closest_range_m": r,
                "velocity_m_s": velocity,
                "reference_range_m": r0,
                "closing_speed_m_s": u0,
                "closest_time_s": tc,
                "curvature_at_zero_m_s2": float(range_state(0.0, r)[2]),
                "global_velocity_max_range_error_m": float(max(abs(delta))),
                "global_velocity_max_phase_error_rad": float(k0 * max(abs(delta))),
            }
        )
        for f_tau in [-BANDWIDTH / 2, 0.0, BANDWIDTH / 2]:
            f_total = FC + f_tau
            k = 4 * np.pi * f_total / C_LIGHT
            fa = 2 * f_total * u0 / C_LIGHT
            alpha = -C_LIGHT * fa / (2 * f_total * velocity)
            d = np.sqrt(1 - alpha * alpha)
            root = tc + alpha * r / (velocity * d)
            time_errors.append(abs(root))
            phase_algebra_errors.append(abs(k * r * d + 2 * np.pi * fa * tc - k * r0))
            values = []
            for count in [100001, 200001, 400001]:
                eta = np.linspace(-HALF_APERTURE, HALF_APERTURE, count)
                change = range_state(eta, r)[3]
                amplitude = (1 - (eta / HALF_APERTURE) ** 2) ** 4
                values.append(
                    simpson(
                        amplitude * np.exp(-1j * (k * change + 2 * np.pi * fa * eta)),
                        x=eta,
                    )
                )
            # 去除共同常数相位后，eta_s=0，只剩曲率幅度与 -pi/4。
            spa = np.sqrt(2 * np.pi / (k * range_state(0.0, r)[2])) * np.exp(
                -1j * np.pi / 4
            )
            row = {
                "closest_range_m": r,
                "range_frequency_hz": f_tau,
                "azimuth_frequency_hz": fa,
                "stationary_time_s": float(root),
                "integral_abs_s": float(abs(values[-1])),
                "relative_quadrature_change": float(
                    abs(values[-1] - values[-2]) / abs(values[-1])
                ),
                "previous_relative_quadrature_change": float(
                    abs(values[-2] - values[-3]) / abs(values[-2])
                ),
                "spa_relative_complex_error": float(
                    abs(spa - values[-1]) / abs(values[-1])
                ),
            }
            assert row["relative_quadrature_change"] < 2e-6
            integrals_summary.append(row)
    taylor_checks = []
    for r in [700000.0, 800000.0, 900000.0]:
        velocity, _, u0, _ = target_parameters(r)
        fa = 2 * FC * u0 / C_LIGHT
        beta = C_LIGHT * fa / (2 * velocity)
        d = np.sqrt(1 - (beta / FC) ** 2)
        f_tau = BANDWIDTH / 2
        exact = np.sqrt((FC + f_tau) ** 2 - beta * beta)
        second = FC * d + f_tau / d - beta**2 * f_tau**2 / (2 * FC**3 * d**3)
        third = second + beta**2 * f_tau**3 / (2 * FC**4 * d**5)
        taylor_checks.append(
            {
                "closest_range_m": r,
                "second_order_phase_error_rad": float(
                    4 * np.pi * r / C_LIGHT * (second - exact)
                ),
                "third_order_phase_error_rad": float(
                    4 * np.pi * r / C_LIGHT * (third - exact)
                ),
            }
        )
    metrics = {
        "model": "V_r(r) is constant in eta for each target and varies across target ranges",
        "symbolic_identities_passed": symbolic_ok,
        "fresnel_max_absolute_error_divided_by_pulse_width": fresnel_error,
        "parameters": {
            "carrier_hz": FC,
            "bandwidth_hz": BANDWIDTH,
            "half_aperture_s": HALF_APERTURE,
            "reference_closest_range_m": REFERENCE_RANGE,
            "reference_speed_m_s": REFERENCE_SPEED,
            "velocity_range_slope_per_s": VELOCITY_SLOPE,
            "effective_squint_deg": 45.0,
            "quadrature_grid_counts": [100001, 200001, 400001],
        },
        "stationary_time_max_error_s": max(time_errors),
        "stationary_phase_max_algebra_error_rad": max(phase_algebra_errors),
        "pi_over_four_range_threshold_m": C_LIGHT / (16 * (FC + BANDWIDTH / 2)),
        "targets": targets,
        "integral_checks": integrals_summary,
        "range_frequency_taylor_checks": taylor_checks,
    }
    assert max(time_errors) < 1e-10
    assert max(phase_algebra_errors) < 2e-7
    (OUTPUT / "metrics.json").write_text(
        json.dumps(metrics, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    plt.rcParams.update(
        {
            "font.family": "Microsoft YaHei",
            "axes.unicode_minus": False,
            "font.size": 10,
            "axes.labelsize": 10,
            "axes.titlesize": 11,
            "lines.linewidth": 1.2,
            "figure.facecolor": "white",
        }
    )
    blue = (0.0, 0.447, 0.741)
    ranges = np.linspace(700000.0, 900000.0, 201)
    fig, axes = plt.subplots(2, 2, figsize=(10, 6.4), constrained_layout=True)
    axes[0, 0].plot(ranges / 1000, equivalent_velocity(ranges), color=blue)
    axes[0, 0].set(
        title="不同距离目标采用不同等效速度",
        xlabel="目标最近斜距 r（km）",
        ylabel="等效速度（m/s）",
    )
    axes[0, 1].plot(
        ranges / 1000,
        equivalent_velocity(ranges) ** 2 * np.cos(THETA) ** 3 / ranges,
        color=blue,
    )
    axes[0, 1].set(
        title="参考时刻斜距曲率随目标距离变化",
        xlabel="目标最近斜距 r（km）",
        ylabel="斜距二阶时间导数（m/s²）",
    )
    for index, style, label in [
        (0, "-", "近距目标：700 km"),
        (2, "--", "远距目标：900 km"),
    ]:
        axes[1, 0].plot(
            times_plot,
            phase_errors[index] / (4 * np.pi * FC / C_LIGHT),
            style,
            color=blue,
            label=label,
        )
        axes[1, 1].plot(times_plot, phase_errors[index], style, color=blue, label=label)
    axes[1, 0].set(
        title="误用全场景统一速度的斜距差",
        xlabel="方位向时间 η（s）",
        ylabel="目标模型减统一速度模型（m）",
    )
    axes[1, 1].set(
        title="对应载频传播相位差",
        xlabel="方位向时间 η（s）",
        ylabel="相位差 kΔR（rad）",
    )
    for ax in axes.flat:
        ax.grid(alpha=0.25)
    for ax in axes[1]:
        ax.legend(fontsize=9)
    fig.savefig(OUTPUT / "变等效速度几何与误差.png", dpi=180)
    plt.close(fig)
    print(json.dumps(metrics, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
