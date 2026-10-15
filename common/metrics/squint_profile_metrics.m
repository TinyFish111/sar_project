function [m,cut] = squint_profile_metrics(values, coordinate_m)
% 直接使用已过采样的物理坐标切片；不对带快速载波的原始复图作interpft。
x = coordinate_m(:); power = abs(values(:)).^2;
[peak,ip] = max(power); power = power/max(peak,realmin);
m.valid = false; m.irw_m = NaN; m.pslr_db = NaN; m.islr_db = NaN;
m.peak_m = x(ip); m.peak_power = peak;
cut.coordinate_m = x; cut.relative_db = 10*log10(max(power,1e-10));
cut.complex_profile = values(:);
if ip<=2 || ip>=numel(x)-1 || ~all(isfinite(power)) || peak==0, return; end
% 局部抛物线只用于定位，宽度用半功率交点线性插值。
den = power(ip-1)-2*power(ip)+power(ip+1);
if abs(den)>eps
    m.peak_m = x(ip)+0.5*(power(ip-1)-power(ip+1))/den*(x(2)-x(1));
end
mins = find(power(2:end-1)<=power(1:end-2) & power(2:end-1)<power(3:end))+1;
left = mins(find(mins<ip,1,'last')); right = mins(find(mins>ip,1,'first'));
il = find(power(1:ip)<0.5,1,'last'); ir = ip-1+find(power(ip:end)<0.5,1,'first');
if isempty(left)||isempty(right)||isempty(il)||isempty(ir), return; end
xl = x(il)+(0.5-power(il))*(x(il+1)-x(il))/(power(il+1)-power(il));
xr = x(ir-1)+(0.5-power(ir-1))*(x(ir)-x(ir-1))/(power(ir)-power(ir-1));
side = true(size(power)); side(left:right) = false;
main = trapz(x(left:right),power(left:right));
m.irw_m = xr-xl;
m.pslr_db = 10*log10(max(power(side)));
m.islr_db = 10*log10(max(trapz(x,power)-main,realmin)/main);
m.mainlobe_m = [x(left),x(right)];
m.integration_window_m = [x(1),x(end)];
m.valid = true;
end
