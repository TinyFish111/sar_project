function geometry = spaceborne_equivalent_geometry(cfg, eta) % 构建标定用速度曲线和轨道示意；不依赖成像算法。
radius = cfg.geometry.earth_radius_m+cfg.geometry.altitude_m; % 圆轨道地心半径Rs，单位m。
omega = sqrt(cfg.geometry.gravitational_parameter/radius^3); % 无地球自转的轨道角速度，单位rad/s。
range_grid = cfg.scene.reference_closest_range_m+(-10000:100:10000); % 201个最近斜距标定节点，单位m。
speed_grid = sqrt(cfg.geometry.gravitational_parameter*(radius^2+cfg.geometry.earth_radius_m^2-range_grid.^2)/(2*radius^3)); % 由最近点距离曲率得到Vr(r)，单位m/s。
geometry.model = 'time_constant_range_variant_equivalent_hyperbola'; % 实际生成使用等效双曲模型；不冒充真实轨道精确距离。
geometry.velocity_range_m = range_grid; % 速度标定横坐标，1×201，单位m；供处理器查询，不使用目标真值。
geometry.equivalent_velocity_mps = speed_grid; % 各距离节点的Vr，1×201，单位m/s；孔径内不随eta变化。
geometry.reference_velocity_mps = interp1(range_grid,speed_grid,cfg.scene.reference_closest_range_m,'pchip'); % 中心参考等效速度，单位m/s。
geometry.orbital_velocity_mps = radius*omega; % 真实圆轨道切向速度，单位m/s；与Vr明确区分。
geometry.platform_position_m = [radius*cos(omega*eta),radius*sin(omega*eta),zeros(size(eta))]; % 圆轨道地心示意轨迹，Na×3，单位m。
geometry.platform_velocity_mps = [-radius*omega*sin(omega*eta),radius*omega*cos(omega*eta),zeros(size(eta))]; % 对应轨道示意速度，Na×3，单位m/s。
geometry.coordinate_system = 'orbit illustration: geocentric XY; image: closest range and vref*beam-center-time'; % 轨道与成像坐标的明确含义。
geometry.trajectory_role = 'illustrative circular orbit; echo ranges use calibrated hyperbolas, not Euclidean distances to this trajectory'; % 防止把模型近似误认成轨道级验证。
geometry.squint_deg = cfg.geometry.squint_deg; % 保存斜视角，单位度。
geometry.center_doppler_hz = 2*geometry.reference_velocity_mps*sind(cfg.geometry.squint_deg)/cfg.radar.wavelength_m; % 接近目标为正的已知真实多普勒中心，单位Hz。
end % 几何配置结束。
