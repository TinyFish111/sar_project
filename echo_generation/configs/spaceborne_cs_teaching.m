function cfg = spaceborne_cs_teaching() % 返回独立的星载CS教学参数；全部物理量采用SI单位。
cfg.c_mps = 299792458; % 真空传播速度，单位m/s；同时用于时延和载频相位。
cfg.radar.carrier_hz = 5.3e9; % ERS量级C波段载频，单位Hz；参考ESA和NASA资料。
cfg.radar.bandwidth_hz = 15.50829e6; % ISCE2 ERS.py公开的距离调频带宽，单位Hz。
cfg.radar.range_sample_rate_hz = 18.962468e6; % ISCE2 ERS.py公开的快时间采样率，单位Hz。
cfg.radar.pulse_duration_s = 37.1e-6; % ERS量级脉宽，单位s；不是ESA页面误写的毫秒。
cfg.radar.chirp_rate_hz_per_s = cfg.radar.bandwidth_hz/cfg.radar.pulse_duration_s; % 正调频率Kr=B/T，单位Hz/s。
cfg.radar.prf_hz = 1700; % 教学选择的脉冲重复频率，单位Hz；不声称对应某一真实ERS产品。
cfg.radar.wavelength_m = cfg.c_mps/cfg.radar.carrier_hz; % 波长lambda=c/fc，单位m。
cfg.geometry.earth_radius_m = 6371000; % 球形地球半径，单位m；不模拟地形或椭球。
cfg.geometry.altitude_m = 785000; % ERS量级轨道高度，单位m。
cfg.geometry.gravitational_parameter = 3.986004418e14; % 地球引力常数mu，单位m^3/s^2。
cfg.geometry.squint_deg = 5; % 从正侧视方向向前偏转的教学斜视角，单位度。
cfg.geometry.aperture_duration_s = 0.6; % 每个目标的有效矩形照射时间，单位s；不是完整10m天线波束。
cfg.scene.reference_closest_range_m = 850000; % 中心目标最近斜距r，单位m；不同于波束中心斜距Rb。
cfg.targets.range_offset_m = [-1500,0,1500]; % 三个最近斜距相对中心的偏移，单位m。
cfg.targets.beam_center_time_s = [-0.08,0,0.08]; % 三个波束中心时刻，单位s；与三距离做笛卡尔积。
cfg.numerics.azimuth_samples = 2048; % 原始回波行数，行坐标为慢时间eta。
cfg.numerics.range_samples = 4096; % 原始回波列数，列坐标为快时间tau。
cfg.numerics.random_seed = 20261104; % 记录随机种子；本实验无噪声，不依赖随机数。
cfg.numerics.precision = 'single'; % 正式保存复数single矩阵；几何与相位先用double计算。
cfg.sources.isce = 'https://github.com/isce-framework/isce2/blob/b7702cfbd571681a133ebc5c3b23a10c78d52706/components/isceobj/Sensor/ERS.py'; % 带宽、采样率的开源来源；固定版本避免main分支后续变化。
cfg.sources.esa = 'https://www.esa.int/Enabling_Support/Space_Engineering_Technology/Onboard_Data_Processing/Introduction_to_a_SAR_System'; % 载频和轨道高度的官方来源。
cfg.sources.nasa = 'https://www.earthdata.nasa.gov/s3fs-public/2024-06/sci-sar-userguide.pdf'; % 脉宽微秒单位的交叉核对来源。
end % 配置函数结束；不生成回波、不调用成像方法。
