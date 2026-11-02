"""核验推导中的代数关系、理想圆轨道示例和有限孔径振荡积分。

本脚本不生成正式回波或成像实验；所有数组以物理慢时间（s）为自变量。
轨道位置数组形状为 (时间点数, 3)，列依次为惯性系 x、y、z（m）。
运行路径相对项目根目录确定，临时指标及图片写入 scratch。
"""

from pathlib import Path
import json
import math

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy.integrate import quad, simpson
from scipy.optimize import brentq
from scipy.special import fresnel
import sympy as sp

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "scratch" / "spaceborne_squint_spectrum" / "verification"
OUTPUT.mkdir(parents=True, exist_ok=True)

C_LIGHT = 299792458.0
EARTH_RADIUS = 6378137.0
ORBIT_RADIUS = EARTH_RADIUS + 700000.0
MU = 3.986004418e14
EARTH_RATE = 7.2921150e-5
ORBIT_RATE = np.sqrt(MU / ORBIT_RADIUS**3)
INCLINATION = np.deg2rad(98.0)
DELTA = np.deg2rad(8.0)
FC = 5.3e9
HALF_APERTURE = 4.0


def orbit_state(eta, gamma):
    """返回位置、速度、加速度；eta 为一维慢时间坐标，单位 s。"""
    eta = np.atleast_1d(np.asarray(eta, dtype=float))
    ci, si = np.cos(INCLINATION), np.sin(INCLINATION)
    phase = ORBIT_RATE * eta
    satellite = ORBIT_RADIUS * np.column_stack(
        [np.cos(phase), ci * np.sin(phase), si * np.sin(phase)]
    )
    sat_velocity = ORBIT_RADIUS * ORBIT_RATE * np.column_stack(
        [-np.sin(phase), ci * np.cos(phase), si * np.cos(phase)]
    )
    sat_acceleration = -(ORBIT_RATE**2) * satellite
    ground_zero = EARTH_RADIUS * np.array([
        np.cos(DELTA),
        np.sin(DELTA) * (np.cos(gamma) * ci - np.sin(gamma) * si),
        np.sin(DELTA) * (np.cos(gamma) * si + np.sin(gamma) * ci),
    ])
    phase_g = EARTH_RATE * eta
    ground = np.column_stack([
        ground_zero[0] * np.cos(phase_g) - ground_zero[1] * np.sin(phase_g),
        ground_zero[0] * np.sin(phase_g) + ground_zero[1] * np.cos(phase_g),
        np.full(eta.size, ground_zero[2]),
    ])
    ground_velocity = EARTH_RATE * np.column_stack(
        [-ground[:, 1], ground[:, 0], np.zeros(eta.size)]
    )
    ground_acceleration = -(EARTH_RATE**2) * np.column_stack(
        [ground[:, 0], ground[:, 1], np.zeros(eta.size)]
    )
    return (satellite - ground, sat_velocity - ground_velocity,
            sat_acceleration - ground_acceleration, ground_zero)


def squint_residual(gamma):
    rho, velocity, _, _ = orbit_state([0.0], gamma)
    return -np.dot(rho[0], velocity[0]) / (
        np.linalg.norm(rho[0]) * np.linalg.norm(velocity[0])
    ) - np.sin(np.pi / 4)


GAMMA = brentq(squint_residual, 0.0, np.pi / 2, xtol=1e-14)


def range_state(eta):
    rho, velocity, acceleration, _ = orbit_state(eta, GAMMA)
    distance = np.linalg.norm(rho, axis=1)
    rate = np.sum(rho * velocity, axis=1) / distance
    curvature = (np.sum(velocity**2 + rho * acceleration, axis=1)
                 - rate**2) / distance
    return distance, rate, curvature


def range_coefficients(order=14):
    """以轨道导数构造 R 的泰勒系数，避免高阶有限差分的消减误差。"""
    ci, si = np.cos(INCLINATION), np.sin(INCLINATION)
    ground_zero = orbit_state([0.0], GAMMA)[3]
    rotation_generator = np.array([[0., -1., 0.], [1., 0., 0.], [0., 0., 0.]])
    rho_coeff = []
    for n in range(order + 1):
        # 导数值除以 n!；用 longdouble 降低卷积递推时的舍入误差。
        cosine_n = [1., 0., -1., 0.][n % 4]
        sine_n = [0., 1., 0., -1.][n % 4]
        sat_derivative = ORBIT_RADIUS * ORBIT_RATE**n * np.array(
            [cosine_n, ci * sine_n, si * sine_n]
        )
        ground_derivative = (EARTH_RATE**n) * (
            np.linalg.matrix_power(rotation_generator, n) @ ground_zero
        )
        rho_coeff.append(np.asarray(
            (sat_derivative - ground_derivative) / math.factorial(n),
            dtype=np.longdouble,
        ))
    q_coeff = np.array([
        sum(np.dot(rho_coeff[l], rho_coeff[n-l]) for l in range(n+1))
        for n in range(order+1)
    ], dtype=np.longdouble)
    r_coeff = np.zeros(order+1, dtype=np.longdouble)
    r_coeff[0] = np.sqrt(q_coeff[0])
    for n in range(1, order+1):
        r_coeff[n] = (q_coeff[n] - sum(
            r_coeff[l] * r_coeff[n-l] for l in range(1, n)
        )) / (2*r_coeff[0])
    # W = d2+d3 eta+...；同一个平方根递推得到等效速度系数。
    v_coeff = np.zeros(order-1, dtype=np.longdouble)
    v_coeff[0] = np.sqrt(q_coeff[2])
    for n in range(1, order-1):
        v_coeff[n] = (q_coeff[n+2] - sum(
            v_coeff[l] * v_coeff[n-l] for l in range(1, n)
        )) / (2*v_coeff[0])
    return r_coeff, v_coeff


def verify_symbolic():
    q, r2, r3, r4, r5 = sp.symbols("q r2 r3 r4 r5", nonzero=True)
    coefficients = [1/r2, -r3/(2*r2**3), (3*r3**2-r2*r4)/(6*r2**5),
                    (-15*r3**3+10*r2*r3*r4-r2**2*r5)/(24*r2**7)]
    inverse = sum(b*q**(n+1) for n, b in enumerate(coefficients))
    residual = sp.series(r2*inverse+r3*inverse**2/2+r4*inverse**3/6
                         +r5*inverse**4/24-q, q, 0, 5).removeO().expand()
    assert sp.simplify(residual) == 0
    h = -q**2/(2*r2)+r3*q**3/(6*r2**3) + (r2*r4-3*r3**2)*q**4/(24*r2**5)
    h += (15*r3**3-10*r2*r3*r4+r2**2*r5)*q**5/(120*r2**7)
    assert sp.simplify(sp.diff(h, q) + inverse) == 0
    # 对通用 V(eta) 的导数独立核验式（4.7）至式（4.9）。
    eta, r0, u0 = sp.symbols("eta r0 u0", real=True)
    velocity = sp.Function("V")(eta)
    q_range = r0**2-2*r0*u0*eta+velocity**2*eta**2
    n_value = -r0*u0+velocity**2*eta+velocity*sp.diff(velocity, eta)*eta**2
    n_prime = velocity**2+4*velocity*sp.diff(velocity, eta)*eta
    n_prime += (sp.diff(velocity, eta)**2+velocity*sp.diff(velocity, eta, 2))*eta**2
    assert sp.simplify(sp.diff(q_range, eta)-2*n_value) == 0
    assert sp.simplify(sp.diff(n_value, eta)-n_prime) == 0
    range_function = sp.sqrt(q_range)
    r_third = sp.diff(n_value, eta, 2)/range_function
    r_third -= 3*n_value*n_prime/range_function**3
    r_third += 3*n_value**3/range_function**5
    assert sp.simplify(sp.diff(range_function, eta, 3)-r_third) == 0
    return True


def verify_fresnel():
    errors = []
    # 将快时间缩放为 u/Tp 后求积，避免极小积分区间造成容差误判。
    pulse_width = 20e-6
    for chirp_rate in [2e11, -2e11]:
        for frequency in [-2e6, 0., 1.5e6, 3e6]:
            z_minus, z_plus = np.sqrt(2*abs(chirp_rate)) * (
                np.array([-pulse_width/2, pulse_width/2])-frequency/chirp_rate
            )
            s_minus, c_minus = fresnel(z_minus)
            s_plus, c_plus = fresnel(z_plus)
            analytic = np.exp(-1j*np.pi*frequency**2/chirp_rate) / np.sqrt(2*abs(chirp_rate))
            analytic *= c_plus-c_minus+1j*np.sign(chirp_rate)*(s_plus-s_minus)
            def integrand(t):
                u = t*pulse_width
                return np.exp(1j*np.pi*chirp_rate*u*u-2j*np.pi*frequency*u)
            numeric = pulse_width * (quad(lambda t: integrand(t).real, -.5, .5,
                                          epsabs=1e-12, epsrel=1e-12, limit=600)[0]
                                    +1j*quad(lambda t: integrand(t).imag, -.5, .5,
                                             epsabs=1e-12, epsrel=1e-12, limit=600)[0])
            errors.append(abs(analytic-numeric)/pulse_width)
    assert max(errors) < 1e-11
    return max(errors)


def main():
    symbolic_ok = verify_symbolic()
    fresnel_error = verify_fresnel()
    r_coeff, v_coeff = range_coefficients()
    r0 = float(r_coeff[0])
    u0 = -float(r_coeff[1])
    v0 = float(v_coeff[0])
    eta = np.linspace(-HALF_APERTURE, HALF_APERTURE, 1001)
    true_range, true_rate, _ = range_state(eta)
    poly_range = np.polynomial.polynomial.polyval(eta.astype(np.longdouble), r_coeff)
    geometric_error = float(np.max(np.abs(poly_range - true_range)))
    assert geometric_error < 2e-8
    constant_range = np.sqrt(r0**2-2*r0*u0*eta+v0**2*eta**2)
    delta_range = true_range-constant_range
    k = 4*np.pi*FC/C_LIGHT
    vr = np.asarray(np.polynomial.polynomial.polyval(eta, v_coeff), dtype=float)
    vr_prime = np.asarray(np.polynomial.polynomial.polyval(
        eta, np.arange(1, len(v_coeff))*v_coeff[1:]), dtype=float)
    derivative_rate = (-r0*u0+vr**2*eta+vr*vr_prime*eta**2) / true_range
    rate_error = float(np.max(abs(derivative_rate-true_rate)))
    assert rate_error < 2e-9

    # 对去除大常数距离相位的积分求值，防止无关的大相位影响舍入误差。
    integral_rows = []
    relative_derivatives = [r_coeff[n]*math.factorial(n) for n in range(6)]
    r2, r3, r4, r5 = map(float, relative_derivatives[2:6])
    b_values = [1/r2, -r3/(2*r2**3), (3*r3*r3-r2*r4)/(6*r2**5),
                (-15*r3**3+10*r2*r3*r4-r2*r2*r5)/(24*r2**7)]
    for stationary_time in [-3., 0., 3.]:
        r_s, rate_s, curvature_s = [float(arr[0]) for arr in range_state([stationary_time])]
        fa = -2*FC*rate_s/C_LIGHT
        integrals = []
        for count in [400001, 800001, 1600001]:
            times = np.linspace(-HALF_APERTURE, HALF_APERTURE, count)
            # 用14阶级数求变化距离，已另与直接轨道范数交叉检查。
            distance_change = np.polynomial.polynomial.polyval(times, r_coeff[1:]) * times
            amplitude = (1-(times/HALF_APERTURE)**2)**4
            phase = np.asarray(k*distance_change+2*np.pi*fa*times, dtype=float)
            integrals.append(simpson(amplitude*np.exp(-1j*phase), x=times))
        amplitude_s = (1-(stationary_time/HALF_APERTURE)**2)**4
        change_s = float(np.polynomial.polynomial.polyval(stationary_time, r_coeff[1:]) * stationary_time)
        spa = amplitude_s*np.sqrt(2*np.pi/(k*curvature_s)) * np.exp(
            -1j*(k*change_s+2*np.pi*fa*stationary_time)-1j*np.pi/4)
        q_value = rate_s-float(r_coeff[1])
        inverse_times = [sum(b_values[n]*q_value**(n+1) for n in range(order))
                         for order in range(1, 5)]
        root_time = brentq(lambda t: range_state([t])[1][0]-rate_s, -4., 4., xtol=1e-12)
        row = {
            "stationary_time_s": stationary_time, "azimuth_frequency_hz": fa,
            "integral_abs_s": float(abs(integrals[-1])),
            "relative_quadrature_change": float(abs(integrals[-1]-integrals[-2])/abs(integrals[-1])),
            "previous_relative_quadrature_change": float(abs(integrals[-2]-integrals[-3])/abs(integrals[-2])),
            "spa_relative_complex_error": float(abs(spa-integrals[-1])/abs(integrals[-1])),
            "spa_phase_error_rad": float(np.angle(spa/integrals[-1])),
            "inverse_errors_s": [float(value-stationary_time) for value in inverse_times],
            "root_error_s": float(root_time-stationary_time),
        }
        assert row["relative_quadrature_change"] < 2e-6
        assert abs(row["root_error_s"]) < 1e-9
        integral_rows.append(row)

    metrics = {
        "symbolic_identities_passed": symbolic_ok,
        "fresnel_max_absolute_error_divided_by_pulse_width": fresnel_error,
        "parameters": {
            "earth_radius_m": EARTH_RADIUS, "orbit_height_m": ORBIT_RADIUS-EARTH_RADIUS,
            "mu_m3_s2": MU, "earth_rate_rad_s": EARTH_RATE, "orbit_rate_rad_s": ORBIT_RATE,
            "inclination_deg": 98., "delta_deg": 8., "gamma_deg": np.rad2deg(GAMMA),
            "carrier_hz": FC, "half_aperture_s": HALF_APERTURE,
            "ground_position_at_zero_m": orbit_state([0.], GAMMA)[3].tolist(),
        },
        "range_derivatives": [float(x) for x in relative_derivatives],
        "vr_zero_m_s": v0, "vr_prime_zero_m_s2": float(v_coeff[1]),
        "vr_second_zero_m_s3": 2*float(v_coeff[2]),
        "u_zero_m_s": u0,
        "effective_squint_deg": float(np.rad2deg(np.arcsin(u0/v0))),
        "range_series_vs_vector_max_m": geometric_error,
        "vr_rate_vs_vector_max_m_s": rate_error,
        "constant_vr_max_range_error_m": float(max(abs(delta_range))),
        "constant_vr_max_phase_error_rad": float(k*max(abs(delta_range))),
        "pi_over_four_range_threshold_m": C_LIGHT/(16*FC),
        "integral_checks": integral_rows,
    }
    (OUTPUT / "metrics.json").write_text(json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8")

    plt.rcParams.update({"font.family": "Microsoft YaHei", "axes.unicode_minus": False,
                         "font.size": 10, "axes.labelsize": 10, "axes.titlesize": 11,
                         "lines.linewidth": 1.2, "figure.facecolor": "white"})
    blue = (0., .447, .741)
    fig, axes = plt.subplots(2, 2, figsize=(10, 6.4), constrained_layout=True)
    axes[0, 0].plot(eta, true_range/1000, color=blue)
    axes[0, 0].set(title="圆轨道与地球自转模型的斜距", ylabel="单程斜距（km）")
    axes[0, 1].plot(eta, vr-v0, color=blue)
    axes[0, 1].set(title="等效速度随慢时间的变化", ylabel="相对参考速度的变化（m/s）")
    axes[1, 0].plot(eta, delta_range*1000, color=blue)
    axes[1, 0].set(title="冻结参考等效速度的斜距误差", ylabel="精确斜距减常速度斜距（mm）")
    axes[1, 1].plot(eta, k*delta_range, color=blue)
    axes[1, 1].axhline(np.pi/4, color=".4", linestyle="--", label="±π/4 诊断线")
    axes[1, 1].axhline(-np.pi/4, color=".4", linestyle="--")
    axes[1, 1].set(title="载频处对应的传播相位差", ylabel="相位差 kΔR（rad）")
    axes[1, 1].legend(fontsize=9)
    for ax in axes.flat:
        ax.set_xlabel("方位向时间 eta（s）")
        ax.grid(alpha=.25)
    fig.savefig(OUTPUT / "变等效速度几何与误差.png", dpi=180)
    plt.close(fig)
    print(json.dumps(metrics, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
