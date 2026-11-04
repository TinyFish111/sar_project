# 回波与成像数据约定（1.0）

首次实现为机载正侧视点目标，字段由 generate_echo.m 和 run_rd.m 明确定义。

echo.mat包含一个dataset结构体：
- schema_version：格式版本。
- id：唯一回波编号。
- echo：复数矩阵，慢时间×快时间。
- fast_time_s、slow_time_s：秒为单位的采样坐标。
- radar：载频Hz、带宽Hz、脉宽s、调频率Hz/s、采样率Hz、PRF Hz及波形说明。
- geometry：平台轨迹、坐标系、单位、几何模型、斜视角定义。
- targets：目标位置、散射系数及坐标系。
- processing_state：原始基带、距离压缩后等明确状态。
- configuration：完整生成配置，以SI单位存储，含用户表格的参考派生值。
- truth：点目标精确斜距历程、中心方位调频率、有效孔径长度及派生多普勒带宽。
- provenance：配置路径、生成时Git版本、未提交修改状态、随机种子、生成时间、MATLAB版本。

算法输出包括复数 image、slant_range_m、along_track_m、输入回波编号、处理参数、耗时及diagnostics。
PSLR/ISLR使用复数切片interpft插值、峰值两侧首个局部极小值划分主瓣；ISLR积分限于记录的切片窗口。
IRW为功率半高（-3.0103dB）宽度。无加窗；不能把理论矩形窗ISLR约-9.68dB误认作计算失败。

## 2.0_stripmap_probe（实验002新增，不更改1.0）

v7.3 echo.mat中保存meta和echo两个变量。echo仍为慢时间×快时间复数single，可用matfile按块读取。
meta包含fast_time_s、slow_time_s、radar、configuration、geometry、targets、processing_state、provenance和checks。
geometry明确记录实际平台轨迹、每点照射入口/出口、逐脉冲斜距、波束角与已知真实多普勒中心。
最近斜距与波束中心时刻的瞬时斜距分别记录，不可互换。天线为固定角宽的矩形有效3dB照射模型。

每个距离探测点独立激励，并非一份同时含九点的全幅矩阵。固定10km范围通过25/30/35km最近斜距位置检验；x平移的三个位置通过条带平移协变验证。局限见实验002记录。
处理输出最近斜距×剪切方位的native_image（复数），坐标映射x=a+xp_mid+r*tan(theta)、y=sqrt(r^2-H^2)；已经去除确定的快速空间载波。
正式保存的measured包含地面x/y局部复图、两向复数过采样剖面、坐标、判据和误差；meta与参数一并保存。幅度不受载波处理影响，相位恢复须按所记处理步骤进行。
BP独立解析PSF仅是验证数据，不是正式算法输入；正式BP只读取实际echo样本。
选定工况另保存<方法>/<工况>_roi.mat，focused.image为地面横航迹y×方位x的129×129复图，cross_track_m/along_track_m给出米制坐标，同时保存参数、雷达、耗时、输入编号和合格标志。算法失败的复图也保留，其合格标志为false。

## 2.1_stripmap_probe：清理基线配置中的未使用参照字段

2.0阶段的configuration继承了正侧视基线中的scene.center_slant_range_m=30000及geometry.illumination_time_s=3.4。这两个字段**没有参与条带回波计算**；2.0的实际瞬时斜距和照射区间以geometry.slant_range_m、geometry.entry_exit_s及checks.illumination_time_s为准，不能用这两个遗留值解释斜视采集。
2.1保留同一采样和回波模型，配置中center_slant_range_m明确写为场景中心波束轴瞬时斜距30km/cos(theta)，probe_beam_center_slant_range_m写该探测点的轴上瞬时斜距，geometry.illumination_time_s写该点实际几何照射时长；表中3.4s移至reference_table。targets明确附坐标系。
历史2.0原始回波保留，2.1不覆盖它；处理入口同时支持两者，均使用实际轨迹、采样轴和reference_closest_range_m。集合说明及sampling_geometry_checks.csv提供统一的实际几何摘要。

## 3.0_spaceborne_cs_teaching：距离空变等效速度教学数据

实验003的`echo.mat`保存单个`dataset`结构体，不更改1.0或2.x数据。`echo`仍为慢时间×快时间的复数single；`fast_time_s`为1×Nr绝对快时间，`slow_time_s`为Na×1慢时间。

- `radar`：载频、带宽、脉宽、调频率、采样率、PRF、波长及传播速度，全部SI单位。
- `geometry.velocity_range_m/equivalent_velocity_mps`：可供处理器使用的距离—速度标定表；每个距离的速度在孔径时间内不变。
- `geometry.platform_position_m/platform_velocity_mps`：地心XY圆轨道示意及速度，明确标注只用于轨道示意；原始回波距离按等效双曲式生成，不是这些轨迹与某组地面XYZ的欧氏距离。
- `targets`：最近斜距r、波束中心时刻eta_b、复散射系数及模型坐标说明；不伪造地面直角坐标。
- `truth.slant_range_m`：Na×Nt完整等效模型斜距；仅用于评价，不提供给CS滤波设计。
- `checks`：矩阵尺寸、有限值、速度范围、名义距离频带及有效孔径内的最大去中心多普勒与PRF余量。有限脉冲及孔径频谱尾部不严格限带。
- `configuration/provenance/processing_state`：完整生成配置、真实来源URL、生成前Git版本及dirty标志、实际MATLAB版本，原始复基带未距离压缩状态。

CS输出`result.image`为方位×最近斜距复数single，`slant_range_m`单位m；历史字段`along_track_m`在本模型明确表示方位标度vref*eta_b，单位m，不是经过地理编码的地面沿航迹坐标。`coordinate_system`保存该限定。`parameters`保存输出窗、参考距离段、真实频率约定、参考速度和消融开关，`processing_elapsed_s`只计处理时间。诊断幅度图行为去中心方位频率，列为相应距离轴，轴及单位同时保存。

三个距离段共用Dref=1和同一个最近斜距输出网格，无RCMC插值或拼接重采样。方位相位只补偿随去中心频率变化的部分，保留目标常相位，避免人为引入快速距离载波；因此其复相位约定不能直接与其他模型输出混用。
