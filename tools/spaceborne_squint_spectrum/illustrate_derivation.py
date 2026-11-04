"""为入门推导生成示意图；图像属于文档插图，不是正式成像实验。

示意图和曲线统一使用中文、微软雅黑、项目蓝色与 1.2 线宽。
有物理量的坐标轴明确标单位；无量纲示意图不冒充真实轨道尺寸。
"""

from pathlib import Path
import json
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Circle, Arc
import numpy as np
from scipy.signal import fftconvolve
from scipy.special import fresnel

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "docs/derivations/spaceborne_squint_variable_vr/figures"
OUTPUT.mkdir(parents=True, exist_ok=True)
BLUE, GRAY, ORANGE = "#0072bd", "#687b8a", "#c47524"
C = 299792458.0
plt.rcParams.update(
    {
        "font.family": "Microsoft YaHei",
        "axes.unicode_minus": False,
        "font.size": 10,
        "axes.titlesize": 11,
        "axes.labelsize": 10,
        "lines.linewidth": 1.2,
        "figure.facecolor": "white",
        "savefig.facecolor": "white",
        "mathtext.fontset": "dejavusans",
    }
)
manifest = []


def save(fig, name, meaning):
    file = OUTPUT / f"{name}.png"
    fig.savefig(file, dpi=180, bbox_inches="tight", pad_inches=0.12)
    plt.close(fig)
    manifest.append({"file": file.relative_to(ROOT).as_posix(), "meaning": meaning})


def box(ax, x, y, w, h, text, fill="#edf5fa"):
    ax.add_patch(
        FancyBboxPatch(
            (x, y), w, h, boxstyle="round,pad=0.015", fc=fill, ec=BLUE, lw=1.2
        )
    )
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", linespacing=1.7)


def arrow(ax, start, end, text=None, offset=(0, 0.03)):
    ax.annotate(
        "",
        xy=end,
        xytext=start,
        arrowprops={"arrowstyle": "->", "color": BLUE, "lw": 1.2},
    )
    if text:
        middle = (
            (start[0] + end[0]) / 2 + offset[0],
            (start[1] + end[1]) / 2 + offset[1],
        )
        ax.text(*middle, text, ha="center", va="center", color=GRAY, fontsize=9)


def grid(ax):
    ax.grid(alpha=0.2)


def roadmap():
    fig, ax = plt.subplots(figsize=(10, 2.7))
    ax.set(xlim=(0, 1), ylim=(0, 1))
    ax.axis("off")
    labels = [
        "① 几何\n斜距 R(η)",
        "② 时域回波\n时延与相位",
        "③ 混合域\n每次变换一维",
        "④ 二维频谱\n精确积分",
        "⑤ 驻相与处理\n近似和误差",
    ]
    for i, label in enumerate(labels):
        x = 0.01 + i * 0.2
        box(ax, x, 0.38, 0.17, 0.43, label)
        if i < 4:
            arrow(ax, (x + 0.17, 0.6), (x + 0.2, 0.6))
    ax.text(
        0.5,
        0.14,
        "每一步都沿用同一个目标、同一条斜距历程；先说明做什么，再推导怎样做。",
        ha="center",
        color=GRAY,
    )
    save(fig, "01_阅读路线", "从几何到频谱再到误差的阅读主线")


def phasor():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.2), layout="constrained")
    ax = axes[0]
    ax.add_patch(Circle((0, 0), 1, fill=False, ec="#ccd7df"))
    phase = np.pi / 3
    arrow(ax, (0, 0), (np.cos(phase), np.sin(phase)))
    ax.plot([np.cos(phase), np.cos(phase)], [0, np.sin(phase)], "--", color=GRAY)
    ax.add_patch(Arc((0, 0), 0.6, 0.6, theta1=0, theta2=60, ec=ORANGE))
    ax.text(0.35, 0.15, "相位 φ", color=ORANGE)
    ax.text(0.1, 0.85, "箭头长度＝幅度", color=BLUE)
    ax.axhline(0, color=GRAY, lw=0.7)
    ax.axvline(0, color=GRAY, lw=0.7)
    ax.set(
        xlim=(-1.15, 1.15),
        ylim=(-1.15, 1.15),
        xlabel="同相分量（实部）",
        ylabel="正交分量（虚部）",
        title="复数：一支有长度和方向的箭头",
    )
    ax.set_aspect("equal")
    ax = axes[1]
    ax.set(xlim=(0, 1), ylim=(0, 1))
    ax.axis("off")
    for y, angles, label in [
        (0.75, [0, 0.08, -0.08], "相位接近：箭头累加后较长"),
        (0.28, [0, 2 * np.pi / 3, 4 * np.pi / 3], "相位分散：箭头相互抵消"),
    ]:
        position = np.array([0.08, y])
        for angle in angles:
            end = position + 0.19 * np.array([np.cos(angle), np.sin(angle)])
            arrow(ax, tuple(position), tuple(end))
            position = end
        ax.text(0.08, y - 0.17, label, color=GRAY)
    save(fig, "02_复数与相干相加", "复指数和相干积分的几何含义")


def domains():
    fig, ax = plt.subplots(figsize=(9.5, 4.1))
    ax.set(xlim=(0, 1), ylim=(0, 1))
    ax.axis("off")
    for x, y, label in [
        (0.04, 0.66, "距离时域—方位时域\n$s(\\tau,\\eta)$"),
        (0.61, 0.66, "距离频域—方位时域\n$S_r(f_\\tau,\\eta)$"),
        (0.04, 0.09, "距离多普勒域\n$S_{\\mathrm{RD}}(\\tau,f_\\eta)$"),
        (0.61, 0.09, "二维频域\n$S(f_\\tau,f_\\eta)$"),
    ]:
        box(ax, x, y, 0.34, 0.24, label)
    arrow(ax, (0.38, 0.79), (0.61, 0.79), "距离正变换", (0, 0.065))
    arrow(ax, (0.38, 0.21), (0.61, 0.21), "距离正变换", (0, 0.065))
    arrow(ax, (0.21, 0.66), (0.21, 0.34))
    ax.text(0.22, 0.50, "方位正变换", fontsize=9, color=GRAY)
    arrow(ax, (0.78, 0.66), (0.78, 0.34))
    ax.text(0.79, 0.50, "方位正变换", fontsize=9, color=GRAY)
    ax.text(
        0.5,
        0.015,
        "沿箭头反向走时，对同一变量作逆变换。",
        ha="center",
        color=GRAY,
        fontsize=9,
    )
    save(fig, "03_四种表示域", "四个域的变量与两种一维傅里叶变换")


def geometry():
    fig, axes = plt.subplots(1, 2, figsize=(10, 3.6), layout="constrained")
    ax = axes[0]
    x = np.tan(np.pi / 6)
    ax.plot([-0.25, 1.0], [0, 0], color=GRAY)
    arrow(ax, (0.72, 0), (0.98, 0), "运动方向", (0, 0.12))
    ax.plot([0, x], [0, -1], color=BLUE)
    ax.plot([x, x], [0, -1], "--", color=ORANGE)
    ax.scatter([0, x, x], [0, 0, -1], color=[BLUE, ORANGE, GRAY], zorder=3)
    ax.plot([0, 0], [0, -0.48], ":", color=GRAY)
    ax.add_patch(Arc((0, 0), 0.55, 0.55, theta1=270, theta2=300, ec=BLUE))
    ax.text(0.10, -0.21, "θ", color=BLUE)
    ax.text(-0.12, 0.14, "波束中心时刻\nη＝0", ha="center", color=BLUE)
    ax.text(x, 0.14, "最近斜距时刻\nη＝ηmin", ha="center", color=ORANGE)
    ax.text(x + 0.04, -0.55, "最近斜距 r", color=ORANGE)
    ax.annotate(
        "波束中心斜距 Rb",
        xy=(x * 0.48, -0.48),
        xytext=(-0.28, -0.82),
        arrowprops={"arrowstyle": "->", "color": BLUE},
        color=BLUE,
        fontsize=9,
        bbox={"fc": "white", "ec": "none", "pad": 1},
    )
    ax.text(x, -1.12, "同一个目标", ha="center")
    ax.set(
        xlim=(-0.3, 1.05), ylim=(-1.25, 0.42), title="等效航迹平面：两个时刻的位置不同"
    )
    ax.set_aspect("equal", adjustable="box")
    ax.axis("off")
    r, v, theta = 30000.0, 250.0, np.pi / 6
    tm = r * np.tan(theta) / v
    eta = np.linspace(-15, 100, 600)
    distance = np.sqrt(r * r + v * v * (eta - tm) ** 2)
    ax = axes[1]
    ax.plot(eta, distance / 1000, color=BLUE)
    ax.axvspan(-4, 4, color=BLUE, alpha=0.12, label="示意照射孔径")
    ax.axvline(0, color=BLUE, ls=":")
    ax.axvline(tm, color=ORANGE, ls="--")
    ax.scatter([0, tm], [r / np.cos(theta) / 1000, r / 1000], color=[BLUE, ORANGE])
    ax.set(
        xlabel="方位向时间 η（s）",
        ylabel="单程斜距（km）",
        title="波束中心不必是距离曲线最低点",
    )
    ax.legend(fontsize=8, loc="upper right")
    grid(ax)
    save(fig, "04_波束中心与最近斜距", "波束中心为零时刻，最近距离可在照射孔径外")


def velocity():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.1), layout="constrained")
    r = np.linspace(700, 900, 150)
    axes[0].plot(r, 7100 + (r - 800), color=BLUE)
    axes[0].set(
        xlabel="不同目标的最近斜距（km）",
        ylabel="等效速度（m/s）",
        title="跨目标比较：速度随距离变化",
    )
    eta = np.linspace(-4, 4, 100)
    for v, style in [(7000, "-"), (7100, "--"), (7200, ":")]:
        axes[1].plot(
            eta, np.full_like(eta, v), style, color=BLUE, label=f"{v} m/s 的目标"
        )
    axes[1].set(
        xlabel="同一目标的方位向时间 η（s）",
        ylabel="等效速度（m/s）",
        title="沿单目标孔径：每条线都水平",
    )
    axes[1].legend(fontsize=8)
    for ax in axes:
        grid(ax)
    save(fig, "05_时间不变与距离空变", "时间导数与目标距离偏导的区别")


def delay_phase():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.2), layout="constrained")
    t = np.linspace(-3, 7, 1500)
    pulse = lambda z: np.exp(-((z / 0.8) ** 2))
    axes[0].plot(t, pulse(t), color=GRAY, label="发射包络（示意）")
    axes[0].plot(t, pulse(t - 3), color=BLUE, label="传播延迟后包络")
    axes[0].annotate(
        "往返时延 d＝2R/c",
        xy=(3, 0.65),
        xytext=(0.1, 0.65),
        arrowprops={"arrowstyle": "<->", "color": ORANGE},
        ha="left",
        color=ORANGE,
    )
    axes[0].set(
        xlabel="快时间 τ（μs，示意尺度）",
        ylabel="归一化包络",
        title="包络平移：记录目标距离",
    )
    axes[0].legend(fontsize=8)
    grid(axes[0])
    mm = np.linspace(0, 7, 120)
    phase = 4 * np.pi * 5.3e9 / C * mm / 1000
    axes[1].plot(mm, phase, color=BLUE)
    axes[1].axhline(np.pi / 4, color=ORANGE, ls="--", label="π/4 诊断线")
    threshold = C / (16 * 5.3e9) * 1000
    axes[1].scatter([threshold], [np.pi / 4], color=ORANGE)
    axes[1].annotate(
        f"约 {threshold:.2f} mm",
        (threshold, np.pi / 4),
        xytext=(0.7, 1.25),
        arrowprops={"arrowstyle": "->", "color": ORANGE},
        color=ORANGE,
    )
    axes[1].set(
        xlabel="斜距差 ΔR（mm）",
        ylabel="传播相位差幅值（rad）",
        title="相位旋转：决定相干叠加",
    )
    axes[1].legend(fontsize=8)
    grid(axes[1])
    save(fig, "06_时延与传播相位", "同一斜距分别控制包络位置和载频相位")


def shift_transform():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.1), layout="constrained")
    t = np.linspace(-2, 5, 700)
    axes[0].plot(t, np.exp(-t * t / 0.4), color=GRAY, label="p(τ)")
    axes[0].plot(t, np.exp(-((t - 2) ** 2) / 0.4), color=BLUE, label="p(τ－d)，d＝2 μs")
    axes[0].set(
        xlabel="快时间 τ（μs）", ylabel="包络（示意）", title="时间域：脉冲平移"
    )
    axes[0].legend(fontsize=8)
    f = np.linspace(-1, 1, 300)
    axes[1].plot(f, -2 * np.pi * f * 2, color=BLUE)
    axes[1].set(
        xlabel="距离频率（MHz）",
        ylabel="相对谱相位（rad）",
        title="频率域：乘上线性相位 exp(－j2πfd)",
    )
    for ax in axes:
        grid(ax)
    save(fig, "07_平移与线性相位", "傅里叶平移性质的直观图解")


def matched_filter():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.2), layout="constrained")
    dt = 5e-9
    t = np.arange(-6e-6, 6e-6, dt)
    tp = 10e-6
    kr = 1e12
    p = (abs(t) <= tp / 2) * np.exp(1j * np.pi * kr * t * t)
    correlation = fftconvolve(p, np.conj(p[::-1]), mode="full") * dt
    lag = np.arange(-p.size + 1, p.size) * dt
    axes[0].plot(t * 1e6, p.real, color=BLUE)
    axes[0].set(
        xlabel="快时间（μs）",
        ylabel="复包络的实部",
        title="原始线性调频脉冲：能量分布较长",
    )
    axes[1].plot(lag * 1e6, abs(correlation) / max(abs(correlation)), color=BLUE)
    axes[1].set(
        xlim=(-1, 1),
        xlabel="相关时移 v（μs）",
        ylabel="归一化相关幅度",
        title="与匹配波形相关：出现窄峰",
    )
    for ax in axes:
        grid(ax)
    save(fig, "08_距离匹配滤波", "共轭、相关与距离压缩脉冲的关系")


def stationary():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.2), layout="constrained")
    eta = np.linspace(-1.2, 1.2, 2000)
    r = 30000.0
    v = 250.0
    fc = 1e9
    tm = r * np.tan(np.pi / 6) / v
    rb = r / np.cos(np.pi / 6)
    R = np.sqrt(r * r + v * v * (eta - tm) ** 2)
    delta = (v * v * eta * eta - 2 * rb * v * 0.5 * eta) / (R + rb)
    fd = -2 * fc / C * v * v * (eta - tm) / R
    fa = 2 * fc / C * v * 0.5
    axes[0].plot(eta, fd - fa, color=BLUE)
    axes[0].axhline(0, color=ORANGE, ls="--", label="所选多普勒频率")
    axes[0].scatter([0], [0], color=ORANGE)
    axes[0].set(
        xlabel="方位向时间 η（s）",
        ylabel="相对多普勒频率（Hz）",
        title="驻相条件：瞬时多普勒与所选频率相等",
    )
    axes[0].legend(fontsize=8)
    phase = 4 * np.pi * fc / C * delta + 2 * np.pi * fa * eta
    axes[1].plot(eta, np.cos(phase), color=BLUE)
    axes[1].axvspan(-0.14, 0.14, color=ORANGE, alpha=0.15, label="驻相点附近")
    axes[1].set(
        xlabel="相对驻相点的时间（s）",
        ylabel="相位因子的实部 cos Φ",
        title="中心变化慢；远处正负振荡相互抵消",
    )
    axes[1].legend(fontsize=8)
    for ax in axes:
        grid(ax)
    save(fig, "09_驻相与相消", "驻相方程和相干积分的物理解释")


def finite_aperture():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.2), layout="constrained")
    eta = np.linspace(-0.7, 0.7, 500)
    axes[0].plot(eta, (abs(eta) < 0.5).astype(float), color=BLUE)
    axes[0].set(
        xlabel="方位向时间（s）",
        ylabel="孔径权",
        title="只积累有限时间内的回波",
        ylim=(-0.05, 1.15),
    )
    f = np.linspace(-45, 45, 1001)
    kr = -40.0
    zm = np.sqrt(2 * abs(kr)) * (-0.5 - f / kr)
    zp = np.sqrt(2 * abs(kr)) * (0.5 - f / kr)
    sm, cm = fresnel(zm)
    sp, cp = fresnel(zp)
    exact = (
        np.exp(-1j * np.pi * f * f / kr)
        / np.sqrt(2 * abs(kr))
        * (cp - cm + 1j * np.sign(kr) * (sp - sm))
    )
    axes[1].plot(f, abs(exact), color=BLUE, label="有限积分的精确幅度")
    axes[1].plot(
        f,
        np.where(abs(f) < 20, 1 / np.sqrt(abs(kr)), 0),
        "--",
        color=ORANGE,
        label="仅取内部驻相主项",
    )
    axes[1].set(
        xlabel="方位频率（Hz）",
        ylabel="积分幅度（s）",
        title="无内部驻相点时，端点仍可贡献频谱",
    )
    axes[1].legend(fontsize=8)
    for ax in axes:
        grid(ax)
    save(fig, "10_有限孔径与驻相近似", "用二次相位教学积分展示边缘误差和谱泄漏")


def migration():
    fig, axes = plt.subplots(1, 2, figsize=(9.5, 3.2), layout="constrained")
    mu = np.linspace(-0.8, 0.8, 500)
    d = np.sqrt(1 - mu * mu)
    axes[0].plot(mu, 1 / d, color=BLUE)
    axes[0].axhline(1, color=GRAY, ls=":")
    axes[0].set(
        xlabel="归一化方位频率 μ＝cfη/(2fcV)",
        ylabel="脉冲中心 τm / (2r/c)",
        title="距离徙动：脉冲中心随方位频率移动",
    )
    fc = 5.3e9
    r = 800000.0
    beta = fc / np.sqrt(2)
    d0 = 1 / np.sqrt(2)
    fr = np.linspace(-50e6, 50e6, 501)
    exact = np.sqrt((fc + fr) ** 2 - beta * beta)
    second = fc * d0 + fr / d0 - beta * beta * fr * fr / (2 * fc**3 * d0**3)
    third = second + beta * beta * fr**3 / (2 * fc**4 * d0**5)
    axes[1].plot(
        fr / 1e6,
        4 * np.pi * r / C * (second - exact),
        color=BLUE,
        label="距离频率保留至二阶",
    )
    axes[1].plot(
        fr / 1e6,
        4 * np.pi * r / C * (third - exact),
        "--",
        color=BLUE,
        label="距离频率保留至三阶",
    )
    axes[1].set(
        xlabel="距离频率（MHz）",
        ylabel="截断相位减完整相位（rad）",
        title="做了 SRC 仍需检查高阶相位",
    )
    axes[1].legend(fontsize=8)
    for ax in axes:
        grid(ax)
    save(fig, "11_距离徙动与高阶耦合", "距离脉冲移动和平方根相位截断的不同后果")


def error_layers():
    fig, ax = plt.subplots(figsize=(9.5, 3.2))
    ax.set(xlim=(0, 1), ylim=(0, 1))
    ax.axis("off")
    for y, label in [
        (0.72, "真实轨道斜距 → 等效双曲斜距：几何模型误差"),
        (0.43, "有限孔径精确积分 → 首阶驻相谱：积分近似误差"),
        (0.14, "完整平方根相位 → 有限阶多项式：截断误差"),
    ]:
        box(ax, 0.05, y, 0.90, 0.17, label)
    arrow(ax, (0.5, 0.72), (0.5, 0.61))
    arrow(ax, (0.5, 0.43), (0.5, 0.32))
    save(fig, "12_三层误差", "把几何误差、驻相误差和频率截断误差分别检查")


if __name__ == "__main__":
    for function in [
        roadmap,
        phasor,
        domains,
        geometry,
        velocity,
        delay_phase,
        shift_transform,
        matched_filter,
        stationary,
        finite_aperture,
        migration,
        error_layers,
    ]:
        function()
    out = ROOT / "scratch/spaceborne_squint_spectrum/illustration_manifest.json"
    out.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"已生成 {len(manifest)} 张教学插图。")
