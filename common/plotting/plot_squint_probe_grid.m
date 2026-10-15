function plot_squint_probe_grid(panels,heading,caption,path,dpi)
% panels为行×列cell；每格image是地面y行×x列复图。全部使用等比例米制坐标。
% 只显示幅度，不将各独立探测点复响应叠加成相干多目标场景。
style = sar_plot_style(); font = sar_chinese_font();
[nr,nc] = size(panels);
f = figure('Visible','off','Color','w','Position',[40,40,350*nc+100,350*nr+140]);
cleanup = onCleanup(@() close(f)); %#ok<NASGU>
set(f,'DefaultAxesFontName',font,'DefaultTextFontName',font,'DefaultAxesFontSize',10);
layout = tiledlayout(f,nr,nc,'TileSpacing','compact','Padding','compact');
for k = 1:numel(panels)
    [row,col] = ind2sub(size(panels),k); r = panels{row,col};
    ax = nexttile(layout,(row-1)*nc+col);
    amplitude = abs(r.image); db = 20*log10(max(amplitude/max(amplitude(:)),1e-10));
    imagesc(ax,r.offset_x_m,r.offset_y_m,db); axis(ax,'xy'); axis(ax,'image');
    colormap(ax,parula(style.colormap_size)); caxis(ax,style.image_db_limits);
    hold(ax,'on'); plot(ax,0,0,'ro','MarkerSize',5,'LineWidth',0.8);
    set(ax,'XTick',linspace(r.offset_x_m(1),r.offset_x_m(end),5), ...
        'YTick',linspace(r.offset_y_m(1),r.offset_y_m(end),5),'Layer','top');
    xlabel(ax,'相对方位位置（m）'); ylabel(ax,'相对地面横航迹位置（m）');
    if r.passed_unified_criterion, status = '合格'; color = [0.1,0.35,0.15]; else, status = '未通过'; color = [0.65,0.1,0.1]; end
    title(ax,{r.panel_title,sprintf('地距y=%.3f km；原判据%s',r.truth_xy_m(2)/1000,status)}, ...
        'FontWeight','normal','FontSize',10,'Color',color,'Interpreter','none');
end
bar = colorbar(ax); bar.Layout.Tile = 'east'; bar.Label.String = '各点峰值归一化幅度（dB）';
bar.FontName = font; bar.Label.FontName = font;
title(layout,heading,'FontName',font,'FontSize',15,'FontWeight','bold','Interpreter','none');
subtitle(layout,{caption,'格内为相对真值的局部地面坐标；同一米制比例；合格状态沿用原高密度剖面评价。'}, ...
    'FontName',font,'FontSize',10,'Interpreter','none');
exportgraphics(f,path,'Resolution',dpi);
end
