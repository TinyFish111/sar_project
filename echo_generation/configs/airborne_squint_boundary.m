function cfg = airborne_squint_boundary(squint_deg, closest_range_m, along_track_m)
% 固定地面场景的条带式探测点。所有长度m、时间s、频率Hz、角度deg。
if nargin < 3, along_track_m = 0; end
cfg = airborne_point_baseline();
cfg.geometry.squint_deg = squint_deg;
cfg.scene.reference_closest_range_m = 30000;
cfg.scene.closest_range_limits_m = [25000,35000];
cfg.scene.along_track_limits_m = [-500,500];
cfg.scene.probe_closest_range_m = closest_range_m;
cfg.targets.along_track_m = along_track_m;
cfg.targets.cross_track_m = sqrt(closest_range_m^2-cfg.geometry.height_m^2);
cfg.geometry.beamwidth_rad = 0.886*cfg.radar.wavelength_m/cfg.geometry.antenna_length_m;
% 与旧代码相同的矩形有效照射；区间由固定波束的3dB角宽确定，不叠加窗。
cfg.geometry.aperture_weight = 'rectangular_within_3db_angular_beam';
theta = deg2rad(squint_deg);
halfbeam = cfg.geometry.beamwidth_rad/2;
assert(theta+halfbeam < pi/2);
% 覆盖基线配置里的正侧视别名，分别保存参考最近斜距和实际波束轴斜距。
cfg.scene.center_slant_range_m = cfg.scene.reference_closest_range_m/cos(theta);
cfg.scene.probe_beam_center_slant_range_m = closest_range_m/cos(theta);
cfg.reference_table.illumination_time_s = 3.4;
cfg.geometry.illumination_time_s = closest_range_m/cfg.geometry.speed_mps*(tan(theta+halfbeam)-tan(theta-halfbeam));
rf_edges = cfg.radar.carrier_hz+[-1,1]*cfg.radar.bandwidth_hz/2;
fd_corners = 2*cfg.geometry.speed_mps/cfg.c_mps*rf_edges(:).*sin(theta+[-halfbeam,halfbeam]);
% PRF必须覆盖整个二维谱：角域带宽之外，还包含B*sin(theta)造成的谱斜置。
% 只用载频处的方位带宽会在高斜视时误把采样混叠当成算法失效。
cfg.radar.prf_hz = max(250,50*ceil(1.35*(max(fd_corners(:))-min(fd_corners(:)))/50));
cfg.numerics.block_pulses = 64;
cfg.numerics.fast_time_guard_s = 2e-6;
end
