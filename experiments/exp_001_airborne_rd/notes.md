# 实验001：典型机载参数的单点目标回波与RD成像

日期：2026-10-13。参数来源：用户提供的“表4.1 机载和星载SAR的典型参数”截图，本次只使用机载列。

## 目的
建立可复现的回波生成—独立RD处理—统一评价基线，验证参数单位、数据接口、距离徙动校正与基本聚焦质量。
本例验证机载正侧视，不能作为星载或大斜视能力的证据。

## 参数与建模选择
| 参数 | 本次采用值 |
|---|---|
| 场景中心斜距 | 30 km |
| 高度 | 10 km |
| 脉宽 | 10 us |
| 距离调频率 | 10 MHz/us = 1e13 Hz/s |
| 信号带宽 | 100 MHz |
| 距离采样率 | 120 MHz |
| 完整斜距带宽 | 10 km，25至35 km |
| 平台速度 | 250 m/s |
| 载频 | 9.4 GHz |
| 照射时间 | 3.4 s |
| PRF | 600 Hz |
| 天线长度 | 1 m（元数据；本例直接用3.4 s矩形有效照射包络） |
| 斜视角 | 0度；表中<8度是范围，本次明确取正侧视 |

采用真空光速299792458 m/s。表中0.032 m波长、131 Hz/s方位调频率、443 Hz多普勒带宽均为近似值；实际相位参数从载频和精确几何统一计算：
- 波长：0.0318928146808511 m。
- 中心方位调频率：-130.645937285943 Hz/s。表中131为幅值参考，本实现的负号与回波相位约定一致。
- 有效孔径长度：250×3.4=850 m。
- 二次近似多普勒带宽：444.196186772206 Hz，小于PRF 600 Hz。
- 最大斜距徙动：3.01026563834603 m。

局部坐标x沿航迹、y横航迹、z向上。平台位置[250*eta,0,10000] m；目标[0,sqrt(30000^2-10000^2),0] m，散射系数1。
R(eta)采用平台与目标之间的精确欧氏距离。原始基带回波包含LFM延迟相位和双程传播相位exp(-j4*pi*R/lambda)。
矩形有效照射、无噪声、无传播衰减、无真实天线方向图、stop-go、平地、匀速直线。1m天线长度没有再次用于计算另一套照射时间。

## 代码分工
- echo_generation/configs/airborne_point_baseline.m：表格参数与派生值参考。
- echo_generation/geometry/airborne_straight_geometry.m：平台几何。
- echo_generation/targets/point_target_scene.m：点目标。
- echo_generation/generate_echo.m：独立生成原始回波。
- signal_processing/rd/run_rd.m：只处理已有dataset的独立RD方法。
- signal_processing/rd/rd_baseline_config.m：处理参数。
- common/metrics/point_target_metrics.m：统一点目标指标。
- common/plotting/plot_airborne_rd_experiment.m：结果与RCMC诊断绘图。
- experiments/exp_001_airborne_rd/run_experiment.m：组织实验与保存，不在算法内部生成回波。

## 处理与评价口径
距离压缩使用1201点中心化有限LFM参考，线性卷积补零，明确校正群延迟；完整10km距离带参与RD处理。
方位FFT补零至4096点；RCMC采用16点截断sinc；双曲方位频谱匹配；无加窗、无SRC。
保存中心距离±200m、方位±100m复数图像以及完整场景幅度缩略图。
指标切片先对复数数据做32倍interpft插值，再取功率。主瓣为峰值两侧首个局部极小值之间；ISLR为有限切片窗口外主瓣能量比；IRW为半功率宽度。
不加窗的理想sinc PSLR约-13.26dB，ISLR约-9.68dB。因此本例ISLR约-9.8dB符合矩形窗基线，不能套用一个未经窗函数约定的-10dB门槛。

## 本次运行结果
运行编号：run_20261013_185533_990。
回波编号：echo_001_airborne_single_broadside_20261013_185533_990。
回波尺寸：2040（慢时间）×9686（快时间），复数single。完整采样窗包含脉宽和边界保护，故采样窗略宽于10km有效距离带。

| 方向 | 半功率宽度IRW / m | PSLR / dB | ISLR / dB |
|---|---:|---:|---:|
| 距离 | 1.328275 | -13.253762 | -9.790025 |
| 方位 | 0.498649 | -13.262141 | -9.758846 |

理论半功率宽度：距离1.327931m；方位0.498597m。峰值坐标：最近斜距30000m、方位0m。
回波生成0.866s，RD处理21.787s；CPU处理，未调用GPU。耗时为本机本次运行结果，不能据此直接比较其他机器或算法。
自动检查通过：回波有限性、尺寸与采样窗、理想sinc的PSLR/ISLR/IRW、峰值位置、IRW与理论相差小于15%、两向PSLR低于-12dB。
人工检查图片：中心点聚焦；距离压缩前后及RCMC历程合理；未加窗十字旁瓣可见。全场景存在低幅度边缘/截断伪影，不应宣称整个图像完全无误差。

实际检测到本机MATLAB为R2022b（9.13.0.2049777），与用户此前提供的R2021b信息不同。代码按R2021b兼容语法编写，未使用R2022a才引入的rangeDopplerImagerLFM；尚未在实际R2021b安装上运行验证。

## 文件与追溯
- 回波：data/simulated/echo_001_airborne_single_broadside_20261013_185533_990/echo.mat。
- 成像：results/exp_001_airborne_rd/run_20261013_185533_990/rd/rd_result.mat。
- 图片：同目录下rd_point_target.png、echo_and_rcmc.png、rd_full_scene.png。
- GitHub保存：本实验代码、records中的参数/指标/summary、本文和回波说明；MAT和运行图片不上传。
- 生成时HEAD为1754d7e且工作区有未提交代码；该旧提交不代表本实验实现。
- source_manifest.json保存本次实际执行的MATLAB源文件SHA256。完成后的版本绑定写入records的completion.md；Git提交记录保留完整来源。

## 复现
```matlab
addpath('D:/sar_project/experiments/exp_001_airborne_rd');
summary = run_experiment();
```
每次使用新编号，不覆盖本次数据。若只想重做成像，按signal_processing/rd/README.md加载原echo.mat并调用run_rd。

## 下一步
围绕本基线解释快慢时间、传播相位和匹配滤波，随后加入离中心点与多点目标。大斜视和星载模型作为独立新实验，不能只修改标题或载频。
