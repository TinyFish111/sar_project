function summary = run_experiment()
% 在MATLAB中：进入本文件目录，执行 run_experiment。
% 本入口分离数据生成与算法处理；run_rd也可独立读取已存dataset运行。
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(project_root,'echo_generation'));
addpath(fullfile(project_root,'echo_generation','configs'));
addpath(fullfile(project_root,'echo_generation','geometry'));
addpath(fullfile(project_root,'echo_generation','targets'));
addpath(fullfile(project_root,'signal_processing','rd'));
addpath(fullfile(project_root,'common','io'));
addpath(fullfile(project_root,'common','metrics'));
addpath(fullfile(project_root,'common','plotting'));
cfg = airborne_point_baseline();
options = rd_baseline_config();
stamp = char(datetime('now','TimeZone','Asia/Shanghai','Format','yyyyMMdd_HHmmss_SSS'));
dataset_id = ['echo_001_airborne_single_broadside_' stamp];
run_id = ['run_' stamp];
data_dir = fullfile(project_root,'data','simulated',dataset_id);
result_dir = fullfile(project_root,'results','exp_001_airborne_rd',run_id,'rd');
record_dir = fullfile(project_root,'experiments','exp_001_airborne_rd','records',run_id);
assert(~exist(data_dir,'dir') && ~exist(result_dir,'dir') && ~exist(record_dir,'dir'),'编号已存在，不能覆盖。');
mkdir(data_dir); mkdir(result_dir); mkdir(record_dir);
fprintf('Generating dataset %s ...\n',dataset_id);
t = tic;
dataset = generate_echo(cfg,project_root,dataset_id);
generation_s = toc(t);
assert(all(isfinite(dataset.echo(:))));
assert(numel(dataset.slow_time_s)==size(dataset.echo,1));
assert(numel(dataset.fast_time_s)==size(dataset.echo,2));
assert(max(abs(dataset.geometry.platform_position_m(:,3)-cfg.geometry.height_m))<1e-8);
range_axis = dataset.fast_time_s*cfg.c_mps/2;
assert(range_axis(1)<25000-cfg.c_mps*cfg.radar.pulse_duration_s/4);
assert(range_axis(end)>35000+cfg.c_mps*cfg.radar.pulse_duration_s/4);
save(fullfile(data_dir,'echo.mat'),'dataset','-v7.3');
write_json(fullfile(data_dir,'configuration.json'),cfg);
fprintf('Echo saved, size %d x %d. Running RD ...\n',size(dataset.echo,1),size(dataset.echo,2));
result = run_rd(dataset,options);
[metrics,cuts] = point_target_metrics(result.image,result.slant_range_m,result.along_track_m,options.metrics_oversampling);
% 独立的理想sinc点扩散函数检查，验证指标计算口径。
x = -100:0.1:100;
s = ones(size(x)); nz = x~=0; s(nz)=sin(pi*x(nz))./(pi*x(nz));
[metricCheck,~] = point_target_metrics(s(:)*s,x,x,8);
assert(abs(metricCheck.range.pslr_db+13.2615)<0.1,'理想sinc PSLR检查失败。');
assert(abs(metricCheck.range.irw_3db_m-0.8859)<0.01,'理想sinc IRW检查失败。');
assert(abs(metricCheck.range.islr_db+9.68)<0.15,'理想sinc ISLR检查失败。');
assert(abs(metrics.peak_range_m-cfg.scene.center_slant_range_m)<cfg.c_mps/(2*cfg.radar.range_sample_rate_hz));
assert(abs(metrics.peak_azimuth_m)<cfg.geometry.speed_mps/cfg.radar.prf_hz);
expected_range_irw = 0.8859*cfg.c_mps/(2*cfg.radar.bandwidth_hz);
expected_az_irw = 0.8859*cfg.geometry.speed_mps/dataset.truth.doppler_bandwidth_hz;
assert(abs(metrics.range.irw_3db_m/expected_range_irw-1)<0.15,'距离IRW与理论差异超过15%%。');
assert(abs(metrics.azimuth.irw_3db_m/expected_az_irw-1)<0.15,'方位IRW与理论差异超过15%%。');
assert(metrics.range.pslr_db<-12 && metrics.azimuth.pslr_db<-12,'旁瓣水平异常，未通过基线检查。');
result.metrics = metrics;
result.provenance = dataset.provenance;
save(fullfile(result_dir,'rd_result.mat'),'result','cuts','-v7.3');
plot_airborne_rd_experiment(dataset,result,metrics,cuts,result_dir,options.db_floor);
direction = {'range';'azimuth'};
IRW_m = [metrics.range.irw_3db_m;metrics.azimuth.irw_3db_m];
PSLR_dB = [metrics.range.pslr_db;metrics.azimuth.pslr_db];
ISLR_dB = [metrics.range.islr_db;metrics.azimuth.islr_db];
metrics_table = table(direction,IRW_m,PSLR_dB,ISLR_dB);
writetable(metrics_table,fullfile(record_dir,'metrics.csv'));
writetable(metrics_table,fullfile(result_dir,'metrics.csv'));
summary.dataset_id = dataset_id;
summary.run_id = run_id;
summary.data_path = fullfile(data_dir,'echo.mat');
summary.result_path = result_dir;
summary.record_path = record_dir;
summary.echo_size = size(dataset.echo);
summary.generation_elapsed_s = generation_s;
summary.rd_elapsed_s = result.processing_elapsed_s;
summary.metrics = metrics;
summary.expected_range_irw_m = expected_range_irw;
summary.expected_azimuth_irw_m = expected_az_irw;
summary.derived_wavelength_m = cfg.radar.wavelength_m;
summary.derived_ka_hz_per_s = dataset.truth.center_azimuth_chirp_rate_hz_per_s;
summary.derived_doppler_bandwidth_hz = dataset.truth.doppler_bandwidth_hz;
summary.max_range_migration_m = max(dataset.truth.slant_range_m)-min(dataset.truth.slant_range_m);
summary.provenance = dataset.provenance;
summary.checks = 'finite echo, dimensions, sampling coverage, ideal sinc metrics, peak position, IRW within 15 percent, PSLR below -12 dB: passed';
write_json(fullfile(record_dir,'summary.json'),summary);
write_json(fullfile(record_dir,'generation_config.json'),cfg);
write_json(fullfile(record_dir,'processing_config.json'),options);
write_json(fullfile(project_root,'scratch','exp_001_latest_run.json'),summary);
fprintf('CHECKS PASSED\nRange IRW %.4f m / PSLR %.3f dB / ISLR %.3f dB\n',IRW_m(1),PSLR_dB(1),ISLR_dB(1));
fprintf('Azimuth IRW %.4f m / PSLR %.3f dB / ISLR %.3f dB\n',IRW_m(2),PSLR_dB(2),ISLR_dB(2));
fprintf('RD elapsed %.3f s\nResults: %s\n',result.processing_elapsed_s,result_dir);
end

function write_json(path, value)
fid = fopen(path,'w','n','UTF-8');
assert(fid>0,'无法写入文件。');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
