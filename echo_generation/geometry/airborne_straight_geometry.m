function geometry = airborne_straight_geometry(cfg, slow_time_s)
% 局部平直地面坐标：x沿航迹，y横航迹，z向上；单位m。
assert(cfg.geometry.squint_deg == 0, '此几何入口目前只支持正侧视。');
eta = slow_time_s(:);
geometry.model = 'constant_speed_straight_track_flat_ground';
geometry.coordinate_system = 'local Cartesian: x along-track, y cross-track, z up; metres';
geometry.platform_position_m = [cfg.geometry.speed_mps*eta, zeros(size(eta)), cfg.geometry.height_m*ones(size(eta))];
geometry.platform_velocity_mps = repmat([cfg.geometry.speed_mps,0,0],numel(eta),1);
geometry.squint_deg = cfg.geometry.squint_deg;
geometry.squint_definition = 'angle from broadside, positive towards platform velocity';
geometry.speed_mps = cfg.geometry.speed_mps;
geometry.height_m = cfg.geometry.height_m;
geometry.reference_slant_range_m = cfg.scene.center_slant_range_m;
geometry.illumination_time_s = cfg.geometry.illumination_time_s;
geometry.antenna_length_m = cfg.geometry.antenna_length_m;
geometry.aperture_weight = cfg.geometry.aperture_weight;
end
