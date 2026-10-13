function plot_airborne_rd_experiment(dataset,result,metrics,cuts,output_dir,db_floor)
% 所有图保存到本次运行目录，不改变原始回波。
set(groot,'defaultAxesFontName','Microsoft YaHei','defaultTextFontName','Microsoft YaHei');
r0 = result.geometry.reference_slant_range_m;
f = figure('Visible','off','Color','w','Position',[100,100,1250,850]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
nexttile;
normalized = abs(result.image)/max(abs(result.image(:)));
imagesc(result.slant_range_m-r0,result.along_track_m,20*log10(max(normalized,10^(db_floor/20))));
axis xy; axis([-15,15,-15,15]); caxis([db_floor,0]); colormap(turbo); colorbar;
xlabel('最近斜距偏移 / m'); ylabel('方位位置 / m'); title('RD点目标成像（峰值归一化，dB）');
nexttile;
contour(result.slant_range_m-r0,result.along_track_m,20*log10(max(normalized,1e-5)),[-30,-20,-13,-6,-3], 'LineWidth',1);
axis equal; axis([-6,6,-6,6]); grid on;
xlabel('最近斜距偏移 / m'); ylabel('方位位置 / m'); title('点扩散函数等高线');
nexttile;
plot(cuts.range.coordinate_m-r0,cuts.range.relative_db,'LineWidth',1.2); grid on;
xlim([-12,12]); ylim([db_floor,2]); yline(-3.0103,'--');
xlabel('最近斜距偏移 / m'); ylabel('归一化幅度 / dB');
title(sprintf('距离：IRW %.3f m，PSLR %.2f dB，ISLR %.2f dB',metrics.range.irw_3db_m,metrics.range.pslr_db,metrics.range.islr_db));
nexttile;
plot(cuts.azimuth.coordinate_m,cuts.azimuth.relative_db,'LineWidth',1.2); grid on;
xlim([-5,5]); ylim([db_floor,2]); yline(-3.0103,'--');
xlabel('方位位置 / m'); ylabel('归一化幅度 / dB');
title(sprintf('方位：IRW %.3f m，PSLR %.2f dB，ISLR %.2f dB',metrics.azimuth.irw_3db_m,metrics.azimuth.pslr_db,metrics.azimuth.islr_db));
sgtitle('典型机载参数：9.4 GHz | 100 MHz | 30 km | 250 m/s | 正侧视');
exportgraphics(f,fullfile(output_dir,'rd_point_target.png'),'Resolution',180); close(f);

f = figure('Visible','off','Color','w','Position',[100,100,1200,700]);
tiledlayout(2,2,'Padding','compact');
nexttile;
rows = unique(round(linspace(1,size(dataset.echo,1),350)));
cols = 1:8:size(dataset.echo,2);
imagesc((dataset.fast_time_s(cols)*dataset.radar.propagation_speed_mps/2-r0)/1000,dataset.slow_time_s(rows),abs(dataset.echo(rows,cols)));
axis xy; xlabel('瞬时斜距偏移 / km'); ylabel('慢时间 / s'); title('原始回波幅度（完整采样窗）'); colorbar;
nexttile;
plot(dataset.slow_time_s,dataset.truth.slant_range_m-r0,'LineWidth',1.3);
grid on; xlabel('慢时间 / s'); ylabel('斜距徙动 / m'); title('精确几何斜距历程');
nexttile;
imagesc(result.diagnostics.range_offset_m,result.diagnostics.slow_time_s,to_db(result.diagnostics.range_compressed_before_rcmc,db_floor));
axis xy; caxis([db_floor,0]); xlabel('斜距偏移 / m'); ylabel('慢时间 / s'); title('距离压缩后、RCMC前（dB）'); colorbar;
nexttile;
imagesc(result.diagnostics.range_offset_m,result.diagnostics.slow_time_s,to_db(result.diagnostics.range_compressed_after_rcmc,db_floor));
axis xy; caxis([db_floor,0]); xlabel('斜距偏移 / m'); ylabel('慢时间 / s'); title('RCMC后（dB）'); colorbar;
colormap(turbo);
exportgraphics(f,fullfile(output_dir,'echo_and_rcmc.png'),'Resolution',160); close(f);

f = figure('Visible','off','Color','w','Position',[100,100,1100,550]);
imagesc((result.diagnostics.full_scene_slant_range_m-r0)/1000,result.diagnostics.full_scene_along_track_m,to_db(result.diagnostics.full_scene_amplitude,db_floor));
axis xy; caxis([db_floor,0]); colormap(turbo); colorbar;
xlabel('最近斜距偏移 / km'); ylabel('方位位置 / m'); title('完整10 km距离带成像幅度缩略图（用于检查鬼影）');
exportgraphics(f,fullfile(output_dir,'rd_full_scene.png'),'Resolution',160); close(f);
end

function db = to_db(amplitude,floor_db)
db = 20*log10(max(double(amplitude)/max(double(amplitude(:))),10^(floor_db/20)));
end
