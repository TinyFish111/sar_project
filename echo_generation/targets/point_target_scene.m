function targets = point_target_scene(cfg)
% 静止理想点目标，复散射系数为1；不模拟传播幅度损失。
targets.position_m = [cfg.targets.along_track_m(:), cfg.targets.cross_track_m(:), cfg.targets.height_m(:)];
targets.reflectivity = cfg.targets.reflectivity(:);
targets.coordinate_system = 'same local Cartesian frame as platform; metres';
assert(size(targets.position_m,1) == numel(targets.reflectivity));
end
