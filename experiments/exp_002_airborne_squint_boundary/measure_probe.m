function measured = measure_probe(sampler, meta, bp_mode, cut_samples)
% sampler只接收待成像物理像素。目标真值用于选评价窗口，不参与参考匹配。
if nargin < 4, cut_samples = 801; end
cfg = meta.configuration; theta = deg2rad(cfg.geometry.squint_deg);
x0 = cfg.targets.along_track_m; y0 = cfg.targets.cross_track_m;
rho_x = cfg.geometry.antenna_length_m/(2*cos(theta));
rho_y = 0.886*cfg.c_mps/(2*cfg.radar.bandwidth_hz*cos(theta))*cfg.scene.probe_closest_range_m/y0;
if bp_mode
    offsets = linspace(-0.5,0.5,9);
else
    offsets = linspace(-4,4,33);
end
[xx,yy] = meshgrid(x0+offsets*rho_x,y0+offsets*rho_y);
coarse = reshape(sampler([xx(:),yy(:)]),size(xx));
[~,k] = max(abs(coarse(:))); [iy,ix] = ind2sub(size(coarse),k);
peak = [xx(k),yy(k)];
measured.search_boundary = iy==1||iy==size(coarse,1)||ix==1||ix==size(coarse,2);
if ~bp_mode
    for refine = 1:2
        step = (offsets(2)-offsets(1))/4^refine;
        [qx,qy] = meshgrid(peak(1)+(-4:4)*step*rho_x,peak(2)+(-4:4)*step*rho_y);
        z = sampler([qx(:),qy(:)]); [~,j] = max(abs(z)); peak = [qx(j),qy(j)];
    end
end
% 大斜视PSF倾斜使地面距离轴切片变窄；积分窗口保持一致，采样随之加密。
range_sampling_width = min(rho_y,rho_x/max(abs(tan(theta)),eps)*cfg.scene.probe_closest_range_m/y0);
ny = max(cut_samples,1+2*ceil(24*rho_y/(range_sampling_width/16)));
nx = cut_samples;
xcut = peak(1)+linspace(-24,24,nx)'*rho_x;
ycut = peak(2)+linspace(-24,24,ny)'*rho_y;
samples = sampler([xcut,repmat(peak(2),nx,1);repmat(peak(1),ny,1),ycut]);
[measured.azimuth,measured.cuts.azimuth] = squint_profile_metrics(samples(1:nx),xcut);
[measured.range,measured.cuts.range] = squint_profile_metrics(samples(nx+1:end),ycut);
measured.error_x_m = measured.azimuth.peak_m-x0;
measured.error_y_m = measured.range.peak_m-y0;
measured.image = coarse; measured.image_x_m = xx(1,:); measured.image_y_m = yy(:,1);
measured.truth_xy_m = [x0,y0]; measured.nominal_resolution_m = [rho_x,rho_y];
measured.metrics_definition = 'power samples; first-minimum mainlobe; finite +/-24 nominal resolution cells; common ground x/y axes';
end
