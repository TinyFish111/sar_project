# 实验002：机载条带式大斜视点目标成像边界

## 研究问题与约定

比较旧代码改进程度的RD+SRC、CS（中心精确方位参考）、omega-k（Stolt频带搬移）和常规BP。
只研究无噪声、静止点目标、stop-go、平地、匀速直线航迹。所测边界是**本参数、本场景和具体实现的经验边界**，不能称作某算法共有的最大斜视角。
用户确认：固定地面场景和最近斜距30km；每次采集波束指向与航迹夹角不变；最大斜视角70deg；允许重算PRF及采样窗；要求中心和边缘均合格。

系统参数沿用表4.1机载列：H=10km，v=250m/s，f0=9.4GHz，B=100MHz，Tr=10us，Kr=1e13Hz/s，Fr=120MHz，天线有效长度1m。
天线采用旧实验的矩形有效照射约定，角宽为0.886*lambda/La，随波束整体转向，不模拟电子扫描增益损失、扫描展宽或真实旁瓣。1m为该理想模型的有效方位孔径长度。俯仰向假定覆盖全部场景，不加入幅度衰减。

## 固定场景与条带几何

坐标x沿航迹、y横航迹、z向上，单位m。地面点的最近斜距r=sqrt(y^2+H^2)。
最近斜距取25/30/35km，对应地面y约22.913/28.284/33.541km；方位x取-500/0/500m。
因此10km是固定的**最近斜距带宽**，对应地面横向宽度约10.628km；它不是各斜视角下不变的瞬时斜距窗。

对每个点，波束轴经过该点时取局部eta=0：xp(eta)=x_target-r*tan(theta)+v*eta。
R(eta)=sqrt((xp-x_target)^2+r^2)，瞬时斜视角atan2(x_target-xp,r)。
照射判据abs(theta_inst-theta)<=beamwidth/2；快时间窗容纳整个照射期间的全部LFM脉冲，不截去距离走动。
theta=70deg时场景中心波束轴斜距为30/cos(70deg)=87.714km，不能继续写成30km。
早期2.0数据配置中继承的30km/3.4s字段未参与新几何计算，实际轨迹、时延及entry_exit_s始终正确。2.1清理这些配置别名，不改变回波模型；两格式的具体字段解释见docs/data_contract.md，旧回波不覆盖。

各点**分别激励、分别测冲激响应**，同一份实际原始LFM回波供四算法读取。采样原始回波保存为MAT，未用解析PSF替代正式回波。
这避免多点旁瓣污染局部ISLR并降低空场景存储。它检验10km范围内探测点的空间变化，不等同于完整分布式场景、强弱目标串扰或连续全幅成像验证。
直线匀速、固定波束的条带系统沿x平移不变，x和平台轨迹同时平移500m时回波不变。三个方位位置通过严格平移得到，并另作数值检查；三种距离各有独立原始回波，不能把三次计算宣称为九次独立随机试验。

## 采样与算法

PRF覆盖(f0+-B/2,theta+-beamwidth/2)四角形成的二维多普勒支撑，留35%余量并向上取50Hz整数倍。使用已知真实多普勒中心，已知模糊数；不研究多普勒中心估计误差。
多普勒中心超出PRF/2本身不判失败。所有频率相关传播项使用真实频率；去中心后的频率用于基带坐标剪切，防止重新引入快速空间载波。
每个距离位置独立完整采集，快慢时间窗按精确几何确定。另核查三点全幅采集时段、时延窗与PRF的兼容性。

- RD：中心参考二次距离压缩；逐输出距离的R/D常规RCMC；8倍距离加密后插值；精确中心方位参考的相位部分，加标准距离相关差分相位。
- CS：保留旧H1/H2/H3，Km取中心参考；精确中心方位参考相位，加标准距离相关方位相位；不加入非线性CS、子孔径高阶RCMC等新方法。
- WK：经典平方根二维匹配、Stolt插值、搬移后的完整频带。线性Stolt改成16点截断sinc以降低插值误差。局部输出窗口的频域坐标平移与全幅Stolt后裁剪等价；没有增加参考目标的真值相位补偿。
- BP：距离匹配滤波后，按精确平台轨迹逐像素反投影；4倍距离加密+四点Lagrange插值，另用8倍结果做收敛检查。

处理算法不依赖目标散射真值；真值只用于指定评价窗口、输出ROI与计算误差。RD/CS的近似参考始终固定30km。WK的显示原点是纯坐标变换，其精确平方根参考项可解析地平移，不产生新的近似。

## 判据与搜索

粗扫描0、8、10:5:70deg；首次合格/不合格区间细化到1deg。对非单调通过区间分别报告，不把偶然再次通过当作连续边界。
输出统一地面x/y坐标的复数图像，测地面轴切片；大斜视PSF可倾斜，地面轴宽度不能套用正侧视0.5m/1.4m常数。

频域方法对同角同位置BP参考，九点全部满足：
1. 两向半功率宽度与BP相差不超过15%，异常变窄也需排查。
2. PSLR、ISLR分别比BP恶化不超过2dB。
3. 定位误差不超过对应BP半功率宽度的0.5倍。
4. 峰值不在搜索窗边界，主瓣边界可测，输出有限。

BP另对**独立连续有限LFM自相关+精确几何相干求和PSF**验证，不将BP自身当作其正确性的证据。
主瓣以峰值两侧首个局部极小值定义；半功率宽度为-3.0103dB；ISLR积分限于+-24个名义分辨率单元。固定窗口与定义随指标保存。
各方法的切片经过自身测得的峰值，积分窗相对峰值取上述固定宽度；定位误差另外相对真实坐标计算，不通过峰值重定心消除定位误差。
70deg仍通过的结论写“已验证至70deg”，没有测到上限。阈值敏感性另列，不能只给没有判据的角度。
CS另保存H1变标后频带的保守采样界。该界超过Nyquist只表示数值采样风险，并不证明实际频谱必然混叠；这类高角度失败不单独用来推导算法内在极限。首次低角度失效区间须确认该采样界仍有余量。

## 已修正的旧实现问题

旧目录sar_params中的swath=10km仅作元数据，实际快时间窗更窄；已改为各探测点全照射区间的精确时延窗，并覆盖25至35km最近斜距位置。
旧simulate_echo对所有目标使用同一慢时间区间、未作逐目标固定波束判定；已改为真实条带角域照射。
旧固定R0同时移动地面场景；本实验固定r/y，孔径中心斜距随角度增大。
旧RD固定中心迁移不能直接用于宽幅；已用标准逐距离RCMC。旧RD/CS中心方位匹配未补距离相关项；已补常规项并保持中心参考SRC/CS近似。
旧“精确中心一维相位等价于精确二维匹配、任意斜视严格成立”不成立；中心匹配不消除离中心的高阶耦合。
旧WK频带只由最大多普勒的一条切线确定、线性插值且快时间原点易混淆；现按每条Stolt映射保留完整带宽、明确中心FFT原点。
旧“五法均在10%内”等文字与原CSV（例如8deg WK距离宽度约15%偏差）不一致；不沿用其结论。
快速空间载波先作确定性处理再插值，指标不对欠采样载波直接interpft。

## 运行与输出

```matlab
addpath('D:/sar_project/experiments/exp_002_airborne_squint_boundary');
run_id = run_boundary_scan();
finish_boundary_study(run_id); % 整数角细化、数值检查、图像、说明及版本清单
% 中断后恢复同一任务（不覆盖已完成回波与结果）
run_boundary_scan(run_id);
finish_boundary_study(run_id);
```

同一run_id用于恢复同一输入/处理配置的未完成任务；改变研究配置时使用新的run_id，保留旧回波和结果。

本机实际MATLAB为R2022b；代码使用R2021b兼容语法、基础FFT/插值/HDF5，不调用MATLAB新版本SAR成像函数，也不依赖GPU。
原始回波：data/simulated/echo_002_*/echo.mat。
正式输出：results/exp_002_airborne_squint_boundary/<run_id>/。
可提交的配置、指标、采样检查、版本清单和结论：本目录records/<run_id>/。
临时方位频谱：scratch/exp_002/<run_id>/，分块不压缩，仅作I/O优化；正式回波不被算法修改。
elapsed_s仅为本机工程日志：BP包含所请求像素的分块处理，频域方法的公共缓存准备另计，不同工况像素与切片数也不同。因此本实验不据这些列排列算法速度。

## 资料来源

- 参数图与用户指定旧目录：C:/Users/29344/Desktop/class matierial/class matierial/本科/毕设/实验代码/。
- DLR F-SAR官方：幅宽12.5km，说明10km量级机载实验有设备参照，但不表示本机载参数就是F-SAR。[技术参数](https://www.dlr.de/en/hr/research-transfer/research-infrastructure/f-sar/details-of-the-f-sar)
- NASA UAVSAR-Ka官方：标称距离幅宽10km。[技术参数](https://uavdb.jpl.nasa.gov/technology/ka-band.html)
- Raney等，1994，Precision SAR Processing Using Chirp Scaling。[DLR原始文献记录](https://elib.dlr.de/205/)，DOI 10.1109/36.298008。
- Cafforio、Prati、Rocca，1991，SAR Data Focusing Using Seismic Migration Techniques。[作者所在机构记录](https://re.public.polimi.it/handle/11311/524809)，DOI 10.1109/7.78293。
- MathWorks斜视SAR几何及波数域示例仅作概念核对，不调用其实现。[官方示例](https://www.mathworks.com/help/radar/ug/squinted-spotlight-sar-image-formation.html)

以下给出本次实测结果；数值检查及最终提交绑定以records中的验证表和completion.md为准。

## 本次实测记录

运行编号：run_20261015_squint_boundary。角网格为0:1:10和15:5:70deg，共23个角度、69种角度/距离工况；三距离冲激响应与三方位平移位置共同对应九点判据。

| 方法 | 全部判据的最大连续已测合格角 | 首次不合格角 | 结论范围 |
|---|---:|---:|---|
| RD+中心参考SRC | 8deg | 9deg | 10km最近斜距范围内的三距离位置联合判定 |
| 中心参考相位CS | 8deg | 9deg | 同上 |
| omega-k | 70deg | 未观察到 | 所测网格均合格，未测出上限 |
| BP | 70deg | 未观察到 | 同角度独立解析PSF校验，不是无条件真值 |

9deg首先由25km近距点触发：RD/CS距离PSLR相对BP分别恶化约2.24/2.34dB，主瓣宽度仍接近BP。把该工况Fr提高至240MHz后分类不变，旁瓣恶化量的变化分别约0.031/0.004dB。
因此8–9deg是**本场景、参考距离及严格联合判据的边界**，不是“9deg以上完全不能成像”。仅按主瓣宽度或定位判据，粗网格首次不合格均在20deg，前一个已测角为15deg；该单项区间未进一步细化。中心点单独评价也不能代替全探测点评价。

详细记录在records/run_20261015_squint_boundary/：conclusions.md、metrics.csv、angle_summary.csv、boundary_and_sensitivity.csv、criterion_failure_brackets.csv、各validation.csv及src_phase_diagnostic.csv。
局部复图与PNG按results/exp_002_airborne_squint_boundary/run_20261015_squint_boundary/<方法>/保存；跨方法汇总图在该运行的figures/。原始回波逐份路径见docs/datasets中的本集合说明。
最终可复现源文件校验见source_manifest.json，最终实现提交号与GitHub同步状态见completion.md。
