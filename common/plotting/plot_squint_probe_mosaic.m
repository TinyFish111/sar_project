function plot_squint_probe_mosaic(panels,method,angle,spacing_m,path,dpi)
% 单坐标九点局部幅度拼图。仅平移互不重叠的局部块，不作复数相干相加。
% 每块的局部长度仍为真实米；块中心间距是人为展示参数，不能当真实位置。
style = sar_plot_style(); font = sar_chinese_font();
sample = panels{1,1}; offset = sample.offset_x_m;
step = offset(2)-offset(1); half_span = max(abs(offset));
assert(spacing_m>2*half_span && abs(spacing_m/step-round(spacing_m/step))<1e-8);
axis_m = -(spacing_m+half_span):step:(spacing_m+half_span);
db_image = repmat(style.image_db_limits(1),numel(axis_m),numel(axis_m));
for row = 1:3
    for col = 1:3
        response = panels{row,col}; amplitude = abs(response.image);
        db = 20*log10(max(amplitude/max(amplitude(:)),1e-10));
        cx = (col-2)*spacing_m; cy = (2-row)*spacing_m;
        ix = round((cx+offset-axis_m(1))/step)+1;
        iy = round((cy+response.offset_y_m-axis_m(1))/step)+1;
        db_image(iy,ix) = max(style.image_db_limits(1),db);
    end
end
f = figure('Visible','off','Color','w','Position',[50,40,1000,1020]);
cleanup = onCleanup(@() close(f)); %#ok<NASGU>
set(f,'DefaultAxesFontName',font,'DefaultTextFontName',font,'DefaultAxesFontSize',11);
ax = axes(f,'Position',[0.10,0.13,0.75,0.74]);
imagesc(ax,axis_m,axis_m,db_image); axis(ax,'xy'); axis(ax,'image');
colormap(ax,parula(style.colormap_size)); caxis(ax,style.image_db_limits); hold(ax,'on');
xlim(ax,[-spacing_m-half_span-2,spacing_m+half_span+2]);
ylim(ax,[-spacing_m-half_span-2,spacing_m+half_span+3]);
for row = 1:3
    for col = 1:3
        r = panels{row,col}; cx = (col-2)*spacing_m; cy = (2-row)*spacing_m;
        plot(ax,cx,cy,'ro','MarkerSize',5,'LineWidth',0.8);
        text(ax,cx,cy+half_span+0.9,sprintf('点%d：%g m / %g km',(3-row)*3+col, ...
            r.truth_xy_m(1),r.closest_range_m/1000),'HorizontalAlignment','center', ...
            'FontSize',9,'Color',[0.1,0.1,0.1],'BackgroundColor','w','Margin',1,'Interpreter','none');
    end
end
set(ax,'XTick',[-spacing_m,0,spacing_m],'YTick',[-spacing_m,0,spacing_m]);
xlabel(ax,'方位展示坐标（m；块中心间距已压缩）');
ylabel(ax,'横航迹展示坐标（m；块中心间距已压缩）');
bar = colorbar(ax); bar.Label.String = '各点峰值归一化幅度（dB）';
bar.FontName = font; bar.Label.FontName = font;
title(ax,{sprintf('%s · %g° · 九点局部响应拼图（间距压缩显示）',method,angle), ...
    '每块16 m × 16 m；内部米制尺度不变；红圈为目标真值'},'FontSize',14,'Interpreter','none');
annotation(f,'textbox',[0.06,0.025,0.90,0.065],'String', ...
    {'标签依次为真实方位位置 / 最近斜距；九点不是本展示坐标中的真实地面位置。', ...
     '三距离分别成像，同距方位点按平移关系展示；独立幅度拼接，非九目标相干整幅成像。'}, ...
    'FontName',font,'FontSize',10,'EdgeColor','none','HorizontalAlignment','center','Interpreter','none');
exportgraphics(f,path,'Resolution',dpi);
end
