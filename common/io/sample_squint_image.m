function values = sample_squint_image(result, xy_m)
% 16点Lanczos sinc取复数样本；输入图像已去除确定的快速空间载波。
% native_image维度：最近斜距 × 剪切方位a；x=a+xp_mid+r*tan(theta)。
r = hypot(xy_m(:,2),result.height_m);
a = xy_m(:,1)-result.platform_mid_along_m-r*tan(result.squint_rad);
u = (r-result.closest_range_m(1))/result.range_step_m;
w = (a-result.sheared_azimuth_m(1))/result.azimuth_step_m;
values = complex(zeros(size(u)));
normalizer = zeros(size(u));
nr = numel(result.closest_range_m); na = numel(result.sheared_azimuth_m);
for kr = -7:8
    ir = floor(u)+kr;
    dr = u-ir;
    wr = local_sinc(dr).*local_sinc(dr/8);
    for ka = -7:8
        ia = floor(w)+ka;
        da = w-ia;
        weight = wr.*local_sinc(da).*local_sinc(da/8);
        good = ir>=0 & ir<nr & ia>=0 & ia<na;
        index = 1+max(0,min(nr-1,ir))+nr*max(0,min(na-1,ia));
        values(good) = values(good)+double(result.native_image(index(good))).*weight(good);
        normalizer(good) = normalizer(good)+weight(good);
    end
end
values = values./max(normalizer,eps);
end
function z = local_sinc(x)
z = ones(size(x)); k = abs(x)>1e-12; z(k) = sin(pi*x(k))./(pi*x(k));
end
