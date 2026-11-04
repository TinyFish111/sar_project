function checks = evaluate_cs_teaching(dataset, result) % 独立评价器；只在处理结束后使用目标真值。
rref = dataset.configuration.scene.reference_closest_range_m; % 参考最近斜距，单位m。
vref = dataset.geometry.reference_velocity_mps; % 方位标度参考速度，单位m/s。
c = dataset.radar.propagation_speed_mps; % 传播速度，单位m/s。
lambda = dataset.radar.wavelength_m; % 雷达波长，单位m。
theta = deg2rad(dataset.geometry.squint_deg); % 斜视角，单位rad。
aperture = dataset.configuration.geometry.aperture_duration_s; % 有效矩形孔径时间，单位s。
checks.definition = 'complex interpft profiles, first minima, finite-window ISLR; 0.886 rectangular-bandwidth IRW reference'; % 指标定义及理论近似的边界。
checks.finite_image = all(isfinite(result.image(:))); % 检查图像无NaN或Inf。
checks.shape = size(result.image); % 记录方位×距离图像维度。
checks.elapsed_s = result.processing_elapsed_s; % 记录实际CS处理耗时。
checks.matlab_version = version; % 保存实际运行的MATLAB版本，不声称已运行R2021b。
checks.reference_velocity_mps = vref; % 保存Vr中心值，单位m/s。
checks.true_doppler_center_hz = dataset.geometry.center_doppler_hz; % 保存真实多普勒中心，单位Hz。
for target = 1:numel(dataset.targets.reflectivity) % 对所有目标分别选局部窗，避免只评价全图最高点。
    truth_r = dataset.targets.closest_range_m(target); % 当前目标真值最近斜距，单位m。
    truth_x = vref*dataset.targets.beam_center_time_s(target); % 当前目标真值方位标度，单位m。
    keep_r = find(abs(result.slant_range_m-truth_r)<=110); % 当前目标独立距离剖面窗，避免跨入相邻目标。
    keep_a = find(abs(result.along_track_m-truth_x)<=110); % 当前目标独立方位剖面窗。
    [metrics,cuts] = point_target_metrics(result.image(keep_a,keep_r),result.slant_range_m(keep_r),result.along_track_m(keep_a),32); % 复用公共指标，复数插值32倍。
    v = interp1(dataset.geometry.velocity_range_m,dataset.geometry.equivalent_velocity_mps,truth_r,'pchip'); % 当前目标真值等效速度，用于独立理论宽度。
    s = [-aperture/2,aperture/2]-truth_r*tan(theta)/v; % 两个照射端点相对最近点的时间，单位s。
    fd = -2*v^2*s./(lambda*sqrt(truth_r^2+v^2*s.^2)); % 完整双曲模型的端点多普勒，单位Hz。
    bandwidth_a = abs(diff(fd)); % 当前目标实际照射多普勒带宽，单位Hz。
    metrics.truth_range_m = truth_r; metrics.truth_azimuth_scale_m = truth_x; % 保存真值位置，单位m。
    metrics.theory_range_irw_m = 0.886*c/(2*dataset.radar.bandwidth_hz); % 矩形频带距离半功率宽度近似，单位m。
    metrics.theory_azimuth_irw_m = 0.886*vref/bandwidth_a; % 矩形孔径频带方位半功率宽度近似，单位m。
    metrics.range_error_m = metrics.range.interpolated_peak_coordinate_m-truth_r; % 距离亚采样峰值位置误差，单位m。
    metrics.azimuth_error_m = metrics.azimuth.interpolated_peak_coordinate_m-truth_x; % 方位亚采样峰值位置误差，单位m。
    metrics.range_width_ratio = metrics.range.irw_3db_m/metrics.theory_range_irw_m; % 测量距离宽度与理论近似的比值。
    metrics.azimuth_width_ratio = metrics.azimuth.irw_3db_m/metrics.theory_azimuth_irw_m; % 测量方位宽度与理论近似的比值。
    metrics.passed = abs(metrics.range_error_m)<c/(2*dataset.radar.range_sample_rate_hz) && abs(metrics.azimuth_error_m)<vref/dataset.radar.prf_hz && abs(metrics.range_width_ratio-1)<0.25 && abs(metrics.azimuth_width_ratio-1)<0.25 && metrics.range.pslr_db<-10 && metrics.azimuth.pslr_db<-10; % 预设判据：位置小于一采样、宽度误差25%内、旁瓣低于-10dB。
    checks.targets(target) = metrics; % 保存当前目标完整指标；不把失败目标从汇总排除。
    if target==ceil(numel(dataset.targets.reflectivity)/2), checks.example_cuts = cuts; end % 保存中心附近目标的两条复数插值剖面用于图文说明。
end % 全部目标评价完成。
checks.rcmc_measured = numel(dataset.targets.reflectivity)==1; % 多目标混合脊线不能当作某一个目标的RCM轨迹。
if checks.rcmc_measured % 仅对单点使用每个方位频率的峰值轨迹测量校正。
    valid = abs(result.diagnostics.doppler_baseband_hz)<=0.4*bandwidth_a; % 排除照射频带端点的有限孔径影响。
    before = subpixel_ridge(result.diagnostics.before_rcmc,result.diagnostics.range_offset_m)+rref; % 三点对数幅度抛物线估计校正前距离脊线，单位m。
    after = subpixel_ridge(result.diagnostics.after_rcmc,result.diagnostics.range_offset_m)+rref; % 同一方法估计校正后脊线，单位m。
    checks.rcm_before_span_m = max(before(valid))-min(before(valid)); % 校正前有效频带内的峰值位置跨度，单位m。
    checks.rcm_after_span_m = max(after(valid))-min(after(valid)); % 校正后有效频带内的峰值位置跨度，单位m。
    checks.rcm_after_max_abs_error_m = max(abs(after(valid)-rref)); % 校正后距离脊线偏离最近斜距的最大值，单位m。
    checks.rcm_check_passed = checks.rcm_before_span_m>50 && checks.rcm_after_span_m<5 && checks.rcm_after_max_abs_error_m<5; % 预设校正证据：明显迁移压至5m以内。
else % 九点用于验证多距离聚焦和定位，不能直接提取全图一条峰值轨迹。
    checks.rcm_check_passed = true; % 此字段仅表示本组不实施单点脊线检查；rcmc_measured=false防止误读。
end % RCM检查结束。
checks.passed = checks.finite_image && all([checks.targets.passed]) && checks.rcm_check_passed; % 综合所有目标和单点RCM的预设判据。
end % 独立评价结束。
function ridge = subpixel_ridge(amplitude, coordinate) % 从每行三个峰值邻点估计亚采样距离；只评价，不参与CS处理。
[~,peak] = max(amplitude,[],2); % 每个方位频率行的整数峰值列号。
peak = max(2,min(size(amplitude,2)-1,peak)); % 保证峰值左右各有一个可用邻点。
rows = (1:size(amplitude,1))'; % 列向量行号，避免与物理频率混淆。
left = log(max(double(amplitude(sub2ind(size(amplitude),rows,peak-1))),realmin)); % 左邻点对数幅度。
middle = log(max(double(amplitude(sub2ind(size(amplitude),rows,peak))),realmin)); % 中心对数幅度。
right = log(max(double(amplitude(sub2ind(size(amplitude),rows,peak+1))),realmin)); % 右邻点对数幅度。
fraction = 0.5*(left-right)./(left-2*middle+right); % 三点抛物线顶点相对整数峰的偏移，单位采样间隔。
fraction = max(-0.5,min(0.5,fraction)); % 将估计限制在整数峰对应的半个采样间隔内。
ridge = coordinate(peak)'+fraction*mean(diff(coordinate)); % 返回每行距离坐标，单位m。
end % 亚采样脊线评价结束。
