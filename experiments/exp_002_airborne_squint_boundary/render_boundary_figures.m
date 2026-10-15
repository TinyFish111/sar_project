function render_boundary_figures(run_id,angles,ranges)
root = boundary_setup(); cfg = boundary_config();
if nargin < 2, angles = cfg.figure_angles_deg; end
if nargin < 3, ranges = 30000; end
out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
figures = fullfile(out,'figures'); work = fullfile(root,'scratch','exp_002',run_id);
if ~exist(figures,'dir'), mkdir(figures); end
for angle = angles
 for range = ranges
    key = sprintf('sq%02d_r%05d',angle,range);
    expected = cellfun(@(name) boundary_figure_path(out,key,name),{'RD','CS','WK','BP'},'UniformOutput',false);
    if all(cellfun(@(path) exist(path,'file')==2,expected)), continue; end
    saved = load(boundary_result_path(out,key,'BP'),'bp','theory','meta','bpcheck');
    bp = saved.bp; meta = saved.meta; dataset_path = fullfile(root,'data','simulated',meta.id,'echo.mat');
    x = meta.targets.position_m(1)+linspace(-8,8,129)*bp.azimuth.irw_m;
    y = meta.targets.position_m(2)+linspace(-8,8,129)*bp.range.irw_m;
    [xx,yy] = meshgrid(x,y);
    if ~exist(boundary_figure_path(out,key,'BP'),'file')
        bp_image = run_bp_squint(dataset_path,[xx(:),yy(:)],4);
        image = reshape(bp_image.values,size(xx));
        save_focused_roi(out,key,'BP',image,x,y,meta,bp_image.parameters,bp_image.elapsed_s,saved.bpcheck.pass);
        plot_squint_boundary(bp,saved.theory,image,x,y,meta,'BP',boundary_figure_path(out,key,'BP'));
    end
    cache = prepare_squint_spectrum(dataset_path,fullfile(work,[key,'_plot_spectrum.mat']));
    for method = cfg.methods
        if exist(boundary_figure_path(out,key,method{1}),'file'), continue; end
        saved = load(boundary_result_path(out,key,method{1}),'measured','check');
        switch method{1}
            case 'RD', native = run_rd_squint(cache);
            case 'CS', native = run_cs_squint(cache);
            case 'WK', native = run_wk_squint(cache);
        end
        image = reshape(sample_squint_image(native,[xx(:),yy(:)]),size(xx));
        save_focused_roi(out,key,method{1},image,x,y,meta,native.parameters,native.elapsed_s,saved.check.pass);
        plot_squint_boundary(saved.measured,bp,image,x,y,meta,method{1},boundary_figure_path(out,key,method{1}));
        clear native
    end
    delete(cache.path);
 end
end
if ~exist(fullfile(records,'angle_summary.csv'),'file'), return; end
if exist(fullfile(figures,'worst_probe_metrics.png'),'file') && exist(fullfile(figures,'angle_pass_map.png'),'file'), return; end
s = readtable(fullfile(records,'angle_summary.csv'),'TextType','string');
font = sar_chinese_font();
methods = ["RD","CS","WK","BP"];
if ~exist(fullfile(figures,'worst_probe_metrics.png'),'file')
f = figure('Visible','off','Color','w','Position',[80,60,1250,430]);
set(f,'DefaultAxesFontName',font,'DefaultTextFontName',font,'DefaultAxesFontSize',10);
colors = lines(4);
fields = {'worst_width_deviation','worst_pslr_loss_db','worst_position_cells'};
labels = {'最大主瓣宽度偏差','最大PSLR恶化（dB）','最大定位误差（分辨率单元）'};
limits = [0.15,2,0.5];
for panel = 1:3
    subplot(1,3,panel); hold on;
    for k = 1:4
        t = sortrows(s(s.method==methods(k),:),'angle_deg');
        plot(t.angle_deg,t.(fields{panel}),'-o','Color',colors(k,:),'MarkerSize',3,'LineWidth',1.2);
    end
    yline(limits(panel),'k--','合格阈值','FontName',font); grid on;
    xlabel('斜视角（°）'); ylabel(labels{panel}); xlim([0,70]);
    if panel==1, legend(methods,'Location','northwest'); end
end
exportgraphics(f,fullfile(figures,'worst_probe_metrics.png'),'Resolution',180); close(f);
end
if exist(fullfile(figures,'angle_pass_map.png'),'file'), return; end
f = figure('Visible','off','Color','w','Position',[80,60,1250,400]);
set(f,'DefaultAxesFontName',font,'DefaultTextFontName',font,'DefaultAxesFontSize',10);
angles = unique(s.angle_deg); pass = zeros(4,numel(angles));
for k = 1:4
    for j = 1:numel(angles)
        t = s(s.method==methods(k) & s.angle_deg==angles(j),:);
        pass(k,j) = ~isempty(t) && t.all_probes_pass;
    end
end
imagesc(1:numel(angles),1:4,pass); colormap(parula(2)); caxis([0,1]);
set(gca,'YTick',1:4,'YTickLabel',cellstr(methods),'XTick',1:numel(angles),'XTickLabel',string(angles));
xlabel('斜视角（°）'); ylabel('成像方法');
title('中心及距离边缘探测点的统一判据（含方位平移位置）');
bar = colorbar; bar.Ticks = [0,1]; bar.TickLabels = {'不合格','合格'}; bar.FontName = font;
exportgraphics(f,fullfile(figures,'angle_pass_map.png'),'Resolution',180); close(f);
end
function save_focused_roi(output,key,method,image,x,y,meta,parameters,elapsed,pass)
figure_path = boundary_figure_path(output,key,method);
folder = fileparts(fileparts(figure_path)); path = fullfile(folder,[key,'_roi.mat']);
if exist(path,'file'), return; end
focused.image = image; % 地面y×方位x，复数；米制坐标分别如下。
focused.cross_track_m = y(:); focused.along_track_m = x;
focused.input_dataset_id = meta.id; focused.method = method;
focused.parameters = parameters; focused.radar = meta.radar;
focused.elapsed_s = elapsed; focused.passed_unified_criterion = pass;
focused.processing_state = 'complex_ground_roi_with_documented_deterministic_spatial_carrier_removed';
save(path,'focused','meta','-v7.3');
end
