function g = stripmap_probe_geometry(cfg)
% 波束在一次采集中与航迹夹角固定。eta=0为该探测点经过波束轴的时刻。
% 每个探测点单独激励；场景参考最近斜距始终30km，处理时不改成探测点距离。
v = cfg.geometry.speed_mps;
r = cfg.scene.probe_closest_range_m;
theta = deg2rad(cfg.geometry.squint_deg);
b = cfg.geometry.beamwidth_rad/2;
g.entry_exit_s = r/v*(tan(theta)-tan(theta+[b,-b]));
half_span = max(abs(g.entry_exit_s))+4/cfg.radar.prf_hz;
na = 2*ceil(half_span*cfg.radar.prf_hz);
g.slow_time_s = (-na/2:na/2-1)'/cfg.radar.prf_hz;
g.platform_mid_along_m = cfg.targets.along_track_m-r*tan(theta);
g.platform_along_m = g.platform_mid_along_m+v*g.slow_time_s;
g.slant_range_m = hypot(g.platform_along_m-cfg.targets.along_track_m,r);
g.look_angle_rad = atan2(cfg.targets.along_track_m-g.platform_along_m,r);
g.illuminated = abs(g.look_angle_rad-theta)<=b;
g.center_doppler_hz = 2*v*sin(theta)/cfg.radar.wavelength_m;
g.model = 'flat_ground_constant_velocity_fixed_squint_stripmap';
g.coordinate_system = 'x along-track, y cross-track, z up; metres';
end
