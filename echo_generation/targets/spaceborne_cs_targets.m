function targets = spaceborne_cs_targets(cfg) % 生成九点教学场景，或由入口配置生成单点诊断场景。
[offset,beam_time] = meshgrid(cfg.targets.range_offset_m,cfg.targets.beam_center_time_s); % 建立方位时刻×距离偏移网格。
targets.closest_range_m = cfg.scene.reference_closest_range_m+offset(:); % Nt×1最近斜距，单位m。
targets.beam_center_time_s = beam_time(:); % Nt×1波束中心时刻，单位s；中心点为0。
targets.reflectivity = ones(numel(offset),1); % Nt×1相同复散射系数；无随机相位和幅度衰减。
targets.coordinate_system = 'closest slant range r (m), beam-center time eta_b (s)'; % 此处采用等效模型参数坐标，不伪造地面XYZ坐标。
end % 目标模型结束。
