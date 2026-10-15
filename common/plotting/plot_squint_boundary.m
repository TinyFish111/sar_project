function plot_squint_boundary(measured,reference,xy_image,x_axis,y_axis,meta,method,path)
% 沿用旧五算法2x2布局和公共parula/dB/蓝线规范，全部中文标注。
style = sar_plot_style(); font = sar_chinese_font();
f = figure('Visible','off','Color','w','Position',[80,60,1250,780]);
clean = onCleanup(@() close(f)); %#ok<NASGU>
set(f,'DefaultAxesFontName',font,'DefaultTextFontName',font,'DefaultAxesFontSize',10);
theta = meta.configuration.geometry.squint_deg;
truth = measured.truth_xy_m;
subplot(2,2,1);
rs = [25000,30000,35000]; ys = sqrt(rs.^2-meta.configuration.geometry.height_m^2);
[xx,yy] = meshgrid([-500,0,500],ys/1000);
plot(xx(:),yy(:),'b+','LineWidth',1.3,'MarkerSize',9); hold on;
plot(truth(1),truth(2)/1000,'ro','MarkerSize',10,'LineWidth',1.3); grid on;
xlim([-650,650]); ylim([min(ys)/1000-1,max(ys)/1000+1]);
xlabel('方位位置（m）'); ylabel('地面横航迹距离（km）');
title(sprintf('固定地面场景：%g°条带观测',theta));
legend({'探测点位置','本图探测点'},'Location','best');
subplot(2,2,2);
power = abs(xy_image); db = 20*log10(max(power/max(max(power(:)),realmin),1e-10));
imagesc(x_axis-truth(1),y_axis-truth(2),db); axis xy;
colormap(gca,parula(style.colormap_size)); caxis(style.image_db_limits);
bar = colorbar; bar.Label.String = '峰值归一化幅度（dB）'; bar.Label.FontName = font;
xlabel('相对方位位置（m）'); ylabel('相对地面距离（m）');
title(sprintf('%s 局部复图像幅度',method));
for direction = 1:2
    if direction==1, name = 'azimuth'; label = '方位'; origin = truth(1); else, name = 'range'; label = '地面距离'; origin = truth(2); end
    subplot(2,2,2+direction);
    cut = measured.cuts.(name); ref = reference.cuts.(name);
    plot(cut.coordinate_m-origin,cut.relative_db,'Color',style.profile_color,'LineWidth',style.profile_line_width); hold on;
    plot(ref.coordinate_m-origin,ref.relative_db,'--','Color',[0.35,0.35,0.35],'LineWidth',1);
    grid on; ylim(style.profile_db_limits);
    span = 8*reference.(name).irw_m; xlim([-span,span]);
    xlabel([label,'偏移（m）']); ylabel('归一化幅度（dB）');
    title(sprintf('%s剖面：宽度 %.3f m，PSLR %.2f dB',label,measured.(name).irw_m,measured.(name).pslr_db));
    legend({method,'参照'},'Location','best');
end
exportgraphics(f,path,'Resolution',180);
end
