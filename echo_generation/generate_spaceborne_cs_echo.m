function dataset = generate_spaceborne_cs_echo(cfg, project_root, dataset_id) % 独立生成原始LFM回波；不调用CS或其他成像算法。
assert(cfg.radar.range_sample_rate_hz>cfg.radar.bandwidth_hz,'快时间采样率不足。'); % 检查复基带距离带宽的采样条件。
eta = (-cfg.numerics.azimuth_samples/2:cfg.numerics.azimuth_samples/2-1)'/cfg.radar.prf_hz; % Na×1慢时间，单位s。
tau = 2*cfg.scene.reference_closest_range_m/cfg.c_mps+(-cfg.numerics.range_samples/2:cfg.numerics.range_samples/2-1)/cfg.radar.range_sample_rate_hz; % 1×Nr绝对快时间，单位s。
geometry = spaceborne_equivalent_geometry(cfg,eta); % 只查询几何标定，不借用处理滤波器。
targets = spaceborne_cs_targets(cfg); % 查询目标模型，支持单点和九点两种输入。
raw = complex(zeros(numel(eta),numel(tau),cfg.numerics.precision)); % Na×Nr原始复数回波；行慢时间、列快时间。
ranges = zeros(numel(eta),numel(targets.reflectivity)); % Na×Nt精确模型斜距真值，单位m。
max_baseband_doppler = 0; % 累计所有目标、照射时刻及名义距离频带边缘的去中心频率绝对值，单位Hz。
for target_index = 1:numel(targets.reflectivity) % 逐目标相干叠加，保留每个目标的不同Vr。
    r = targets.closest_range_m(target_index); % 读取当前目标最近斜距r，单位m。
    v = interp1(geometry.velocity_range_m,geometry.equivalent_velocity_mps,r,'pchip'); % 读取当前目标孔径内恒定的Vr(r)，单位m/s。
    beam_time = targets.beam_center_time_s(target_index); % 当前目标波束中心时刻eta_b，单位s。
    closest_time = beam_time+r*tand(cfg.geometry.squint_deg)/v; % eta_min=eta_b+r*tan(theta)/Vr，单位s。
    ranges(:,target_index) = sqrt(r^2+v^2*(eta-closest_time).^2); % 完整双曲斜距，不对eta截断到二阶，单位m。
    illuminated = find(abs(eta-beam_time)<=cfg.geometry.aperture_duration_s/2); % 矩形有效照射区间内的慢时间行号。
    assert(~isempty(illuminated) && illuminated(1)>1 && illuminated(end)<numel(eta),'孔径被记录边界截断。'); % 检查目标完整照射。
    range_rate = v^2*(eta(illuminated)-closest_time)./ranges(illuminated,target_index); % 有效孔径内逐脉冲斜距变化率，单位m/s。
    edge_frequency = cfg.radar.carrier_hz+[-1,1]*cfg.radar.bandwidth_hz/2; % 名义距离频带两端的真实载频，1×2，单位Hz。
    doppler_offset = -2/cfg.c_mps*range_rate.*edge_frequency-geometry.center_doppler_hz; % 有效孔径和频带边缘的去中心多普勒，Nillum×2，单位Hz。
    max_baseband_doppler = max(max_baseband_doppler,max(abs(doppler_offset(:)))); % 保存最坏频率偏移，检查采样余量。
    for row = illuminated' % 对有回波的每个脉冲生成距离波形；不混淆行号与eta。
        delay = 2*ranges(row,target_index)/cfg.c_mps; % 当前脉冲的双程传播时延，单位s。
        dt = tau-delay; % 相对接收脉冲中心的快时间，1×Nr，单位s。
        support = abs(dt)<=cfg.radar.pulse_duration_s/2; % 有限矩形脉冲的非零采样区间。
        assert(delay-cfg.radar.pulse_duration_s/2>tau(1) && delay+cfg.radar.pulse_duration_s/2<tau(end),'距离窗截断脉冲。'); % 检查完整距离支持。
        phase = pi*cfg.radar.chirp_rate_hz_per_s*dt(support).^2-4*pi*ranges(row,target_index)/cfg.radar.wavelength_m; % 距离调频相位加双程载频传播相位，单位rad。
        raw(row,support) = raw(row,support)+cast(targets.reflectivity(target_index)*exp(1i*phase),cfg.numerics.precision); % 先以double求相位，再存single并相干累加。
    end % 当前目标的所有有效脉冲生成结束。
end % 全部目标叠加结束。
dataset.schema_version = '3.0_spaceborne_cs_teaching'; % 新模型具有明确版本，不改写已有数据格式。
dataset.id = dataset_id; % 唯一数据编号由独立生成入口提供。
dataset.echo = raw; % 正式原始复数回波，不包含任何匹配滤波结果。
dataset.fast_time_s = tau; % 保存1×Nr绝对快时间坐标，单位s。
dataset.slow_time_s = eta; % 保存Na×1慢时间坐标，单位s。
dataset.radar = cfg.radar; % 保存完整雷达参数，单位由字段名约定。
dataset.radar.propagation_speed_mps = cfg.c_mps; % 保存传播速度以便处理器独立读取。
dataset.geometry = geometry; % 保存Vr标定曲线、已知多普勒中心及轨道示意。
dataset.targets = targets; % 保存Nt个目标的模型坐标和散射系数。
dataset.truth.slant_range_m = ranges; % 保存Na×Nt斜距真值；处理器不读取该字段。
dataset.processing_state = 'raw_complex_baseband_no_range_compression'; % 明确输入仍未距离压缩。
dataset.configuration = cfg; % 保存完整生成配置，支持离线复现。
dataset.provenance = get_project_provenance(project_root,'echo_generation/configs/spaceborne_cs_teaching.m',cfg.numerics.random_seed); % 记录实际MATLAB版本和生成前Git状态。
dataset.checks.finite_echo = all(isfinite(raw(:))); % 检查原始回波不存在NaN或Inf。
dataset.checks.shape = size(raw); % 记录Na×Nr尺寸作为数据校验依据。
dataset.checks.max_baseband_doppler_hz = max_baseband_doppler; % 记录名义有效带宽的最大去中心多普勒，单位Hz。
dataset.checks.doppler_guard_hz = cfg.radar.prf_hz/2-max_baseband_doppler; % 相对奈奎斯特半带宽的剩余余量，单位Hz；有限脉冲尾部不严格限带。
dataset.checks.velocity_span_mps = [min(geometry.equivalent_velocity_mps),max(geometry.equivalent_velocity_mps)]; % 记录标定范围内Vr上下界，单位m/s。
assert(dataset.checks.finite_echo,'回波包含非有限数。'); % 非有限回波立即停止，避免错误进入处理器。
assert(dataset.checks.doppler_guard_hz>0,'名义有效方位带宽超出PRF。'); % 禁止在主体频带已经混叠时声称得到可信成像。
end % 原始回波生成结束。
