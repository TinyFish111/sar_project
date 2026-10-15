function cfg = boundary_config()
% 固定全部物理系统参数；仅按波束/采样要求重算PRF和快慢时间窗。
cfg.angles_deg = unique([0,8,10:5:70]);
cfg.closest_ranges_m = [25000,30000,35000];
cfg.along_track_m = [-500,0,500];
cfg.methods = {'RD','CS','WK'};
cfg.threshold.irw_ratio_max = 1.15;
cfg.threshold.pslr_degradation_db = 2;
cfg.threshold.islr_degradation_db = 2;
cfg.threshold.position_resolution_fraction = 0.5;
cfg.bp_range_upsampling = 4;
cfg.cut_half_width_resolution_cells = 24;
cfg.cut_samples = 801;
cfg.figure_angles_deg = [0,8,70];
cfg.refinement_step_deg = 1;
end
