function render_cs_teaching(dataset,result,checks,folder,kind) % 根据实际MATLAB结果作图；不生成示意数据冒充成像。
style = sar_plot_style(); font = sar_chinese_font(); % 复用公共parula、蓝色剖面和中文字体规则。
rref = dataset.configuration.scene.reference_closest_range_m; % 用中心最近斜距作距离偏移原点，单位m。
fig = figure('Visible','off','Color','w','Position',[100,100,1200,530]); % 创建双栏实际成像图。
tiledlayout(1,2,'Padding','compact','TileSpacing','compact'); % 左边全场景，右边中心点放大。
nexttile; show_image(result.slant_range_m-rref,result.along_track_m,result.image,style,font); % 显示完整输出的峰值归一化dB幅度。
title('CS成像：各距离段使用各自的参考速度','FontName',font); % 标题说明距离空变处理方式。
xlabel('最近斜距偏移（m）','FontName',font); ylabel('方位标度 v_{ref}η_b（m）','FontName',font); % 标明真实输出坐标，不标为地距。
nexttile; keep_r = abs(result.slant_range_m-rref)<=65; keep_a = abs(result.along_track_m)<=65; % 选取中心点局部窗。
show_image(result.slant_range_m(keep_r)-rref,result.along_track_m(keep_a),result.image(keep_a,keep_r),style,font); % 展示中心点局部二维响应。
title('中心点放大：检查主瓣和旁瓣','FontName',font); xlabel('最近斜距偏移（m）','FontName',font); ylabel('方位标度（m）','FontName',font); % 中文标注坐标和教学用途。
exportgraphics(fig,fullfile(folder,[kind,'_成像.png']),'Resolution',170); close(fig); % 导出实际成像图并关闭隐藏窗口。
fig = figure('Visible','off','Color','w','Position',[100,100,1200,460]); % 创建单目标的两方向剖面图。
tiledlayout(1,2,'Padding','compact','TileSpacing','compact'); % 统一左右剖面排版。
fields = {'range','azimuth'}; labels = {'距离方向','方位方向'}; % 两个公共剖面字段及中文名称。
for index = 1:2 % 分别绘制距离和方位的复数插值剖面。
    nexttile; cut = checks.example_cuts.(fields{index}); % 取得公共指标函数实际计算的剖面。
    [~,peak] = max(cut.relative_db); coordinate = cut.coordinate_m-cut.coordinate_m(peak); % 以本方向峰值为绘图原点，单位m。
    plot(coordinate,cut.relative_db,'Color',style.profile_color,'LineWidth',style.profile_line_width); % 使用统一蓝色和线宽。
    grid on; xlim([-65,65]); ylim(style.profile_db_limits); set(gca,'FontName',font); % 固定显示范围，避免不同结果视觉尺度不一致。
    title([labels{index},'剖面：复数插值后取幅度'],'FontName',font); xlabel('相对峰值位置（m）','FontName',font); ylabel('归一化幅度（dB）','FontName',font); % 说明实际剖面方法。
end % 两条剖面绘制完成。
exportgraphics(fig,fullfile(folder,[kind,'_剖面.png']),'Resolution',170); close(fig); % 保存剖面图。
if numel(dataset.targets.reflectivity)==1 % 只有单点可以清楚展示同一目标的RCM轨迹。
    fig = figure('Visible','off','Color','w','Position',[100,100,1200,900]); % 创建四栏RCM与消融图。
    tiledlayout(2,2,'Padding','compact','TileSpacing','compact'); % 两行两列排列处理前后证据。
    nexttile; show_image(result.diagnostics.range_offset_m,result.diagnostics.doppler_baseband_hz,result.diagnostics.before_rcmc,style,font); % 校正前距离多普勒幅度图。
    xlim([2600,3900]); title('仅距离压缩：同一目标仍沿距离移动','FontName',font); xlabel('斜距偏移（m）','FontName',font); ylabel('去中心方位频率（Hz）','FontName',font); % 此轴仍是瞬时斜距，不误称最近斜距。
    nexttile; show_image(result.diagnostics.range_offset_m,result.diagnostics.doppler_baseband_hz,result.diagnostics.after_rcmc,style,font); % H2后校正图。
    xlim([-150,150]); title('CS校正后：峰值对齐到最近斜距','FontName',font); xlabel('最近斜距偏移（m）','FontName',font); ylabel('去中心方位频率（Hz）','FontName',font); % 明确前后图横轴放大尺度不同。
    nexttile; plot(result.diagnostics.doppler_baseband_hz,result.diagnostics.ridge_before_m-mean(result.diagnostics.ridge_before_m),'Color',style.profile_color,'LineWidth',1.2); hold on; % 去掉前轨迹常量偏置以比较迁移量。
    plot(result.diagnostics.doppler_baseband_hz,result.diagnostics.ridge_after_m-rref,'--','Color',[0.85,0.33,0.1],'LineWidth',1.2); grid on; % 叠加校正后相对真值轨迹。
    set(gca,'FontName',font); title('迁移量比较：前轨迹已去均值','FontName',font); xlabel('去中心方位频率（Hz）','FontName',font); ylabel('距离变化（m）','FontName',font); legend('校正前，已去均值','校正后，相对真值','Location','best'); % 标明前曲线去均值，避免常量偏置混淆。
    nexttile; show_image(result.diagnostics.no_rcmc_range_m-rref,result.diagnostics.no_rcmc_azimuth_m,result.diagnostics.no_rcmc_image,style,font); % 展示关闭RCMC的实际对照图。
    xlim([2600,3900]); title('关闭RCMC的对照：能量未压成正确位置的点','FontName',font); xlabel('斜距轴偏移（m）','FontName',font); ylabel('方位标度（m）','FontName',font); % 对照图不是正式校正后的最近斜距图。
    exportgraphics(fig,fullfile(folder,[kind,'_RCM校正.png']),'Resolution',170); close(fig); % 保存RCM证据及消融图。
end % 单点RCM诊断绘图结束。
end % 本组教学结果绘图结束。
function show_image(x,y,image,style,font) % 统一幅度显示，不修改参与指标计算的复数图像。
amplitude = double(abs(image)); peak = max(amplitude(:)); % 读取幅度与本图峰值，用于单图归一化。
db = 20*log10(max(amplitude/max(peak,realmin),10^(style.image_db_limits(1)/20))); % 按项目规范转换幅度dB并保护零值。
imagesc(x,y,db); axis xy; colormap(gca,parula(style.colormap_size)); caxis(style.image_db_limits); % 使用parula与[-40,0]dB色标。
bar = colorbar; bar.Label.String = '归一化幅度（dB）'; bar.Label.FontName = font; set(gca,'FontName',font); % 色条和坐标轴使用中文字体。
end % 公共绘图子函数结束。
