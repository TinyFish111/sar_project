function cfg = wk_squint_config()
% 仅数值插值精度；不改变经典平方根模型和Stolt处理步骤。
cfg.range_upsampling = 8;
cfg.stolt_taps = 16;
cfg.zoom_fft_oversampling = 8;
cfg.frequency_grid_refinement = 1;
cfg.frequency_block_size = 32;
end
