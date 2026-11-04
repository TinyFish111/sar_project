function options = spaceborne_cs_options() % 返回CS处理设置；与回波生成配置相互独立。
options.range_output_half_width_m = 2300; % 输出最近斜距半宽，单位m。
options.azimuth_output_half_width_m = 1000; % 输出方位标度vref*eta_b的半宽，单位m。
options.range_tile_centers_offset_m = [-1600,0,1600]; % 三个CS参考最近斜距偏移，单位m；不使用目标位置选参考。
options.azimuth_padding_factor = 2; % 慢时间两侧补零，减小循环相关卷绕。
options.block_rows = 64; % 每次计算64个方位频率的滤波相位，控制内存峰值。
options.disable_rcmc = false; % 教学消融开关；true时只压缩距离和方位，保留距离徙动。
end % 默认处理设置结束。
