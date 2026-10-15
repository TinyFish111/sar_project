function cfg = probe_gallery_config()
% 九点图集只补充显示，不改变原边界实验的输入、算法或评价阈值。
cfg.source_run_id = 'run_20261015_squint_boundary';
cfg.run_id = 'run_20261015_nine_probe_gallery';
cfg.angles_deg = [0,8,9,70];
cfg.closest_ranges_m = [25000,30000,35000];
cfg.along_track_m = [-500,0,500];
cfg.methods = {'RD','CS','WK','BP'};
cfg.half_span_m = 8; % 全部角度/方法/位置统一地面米制窗口，不按峰值重新居中。
cfg.samples_per_axis = 257; % 0.0625 m；最窄实测主瓣仍有约8个采样间隔。
cfg.mosaic_spacing_m = 20; % 仅展示间距；真实x间隔500 m、真实y间隔约5 km。
cfg.resolution_dpi = 180;
end
