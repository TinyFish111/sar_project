function options = rd_baseline_config()
% 所有正式处理使用完整10km斜距带；图像导出裁剪只是显示和存储选择。
options.range_fft_block_rows = 64;
options.range_processing_half_width_m = 5000;
options.range_output_half_width_m = 200;
options.azimuth_output_half_width_m = 100;
options.rcmc_sinc_taps = 16;
options.azimuth_fft_padding_factor = 2;
options.metrics_oversampling = 32;
options.db_floor = -40; % 全项目默认显示范围见docs/plotting_conventions.md
options.window = 'rectangular';
end
