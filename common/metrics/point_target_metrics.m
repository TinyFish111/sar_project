function [metrics, cuts] = point_target_metrics(image, range_m, azimuth_m, oversampling)
% 复数切片先interpft再取幅度；主瓣定义为峰值两侧第一个局部极小值。
% ISLR是给定切片窗口内主瓣外能量/主瓣能量，不是无限场景积分。
[~,linearIndex] = max(abs(image(:)));
[ia,ir] = ind2sub(size(image),linearIndex);
[rangeMetrics,rangeCut] = profile_metrics(image(ia,:),range_m,oversampling);
[azMetrics,azCut] = profile_metrics(image(:,ir).',azimuth_m(:).',oversampling);
metrics.peak_range_m = range_m(ir);
metrics.peak_azimuth_m = azimuth_m(ia);
metrics.peak_amplitude = double(abs(image(ia,ir)));
metrics.range = rangeMetrics;
metrics.azimuth = azMetrics;
metrics.definition = 'complex interpft; first-minimum mainlobe; finite-window energy; -3.0103 dB width';
cuts.range = rangeCut;
cuts.azimuth = azCut;
end

function [m,cut] = profile_metrics(profile, x, factor)
profile = double(profile(:).');
x = double(x(:).');
assert(numel(profile)==numel(x) && numel(x)>16);
dx = mean(diff(x));
assert(max(abs(diff(x)-dx))<abs(dx)*1e-6);
fine = interpft(profile,numel(profile)*factor);
xf = x(1)+(0:numel(fine)-1)*dx/factor;
p = abs(fine).^2;
[peakPower,ip] = max(p);
p = p/peakPower;
localMin = find(p(2:end-1)<=p(1:end-2) & p(2:end-1)<p(3:end))+1;
left = localMin(find(localMin<ip,1,'last'));
right = localMin(find(localMin>ip,1,'first'));
assert(~isempty(left) && ~isempty(right),'切片范围内找不到主瓣边界。');
side = true(size(p)); side(left:right) = false;
m.pslr_db = 10*log10(max(p(side)));
mainEnergy = trapz(xf(left:right),p(left:right));
totalEnergy = trapz(xf,p);
m.islr_db = 10*log10(max(totalEnergy-mainEnergy,realmin)/mainEnergy);
il = find(p(1:ip)<0.5,1,'last');
ir = ip-1+find(p(ip:end)<0.5,1,'first');
assert(~isempty(il) && ~isempty(ir));
xl = xf(il)+(0.5-p(il))*(xf(il+1)-xf(il))/(p(il+1)-p(il));
xr = xf(ir-1)+(0.5-p(ir-1))*(xf(ir)-xf(ir-1))/(p(ir)-p(ir-1));
m.irw_3db_m = xr-xl;
m.interpolated_peak_coordinate_m = xf(ip);
m.mainlobe_bounds_m = [xf(left),xf(right)];
m.integration_window_m = [xf(1),xf(end)];
m.oversampling = factor;
cut.coordinate_m = xf;
cut.relative_db = 10*log10(max(p,1e-10));
cut.mainlobe_bounds_m = m.mainlobe_bounds_m;
end
