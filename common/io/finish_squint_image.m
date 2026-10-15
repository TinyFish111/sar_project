function [image,p] = finish_squint_image(spectrum,p)
% 方位IFFT逐距离块完成，只保留评价窗所需的剪切方位；与整矩阵IFFT等价。
% 70度时整幅空方位周期很长，保留全部周期会无谓占用数GB内存。
half_range = max(abs(p.range_output_m-p.probe_range_m));
if isfield(p,'nominal_azimuth_width_m'), width = p.nominal_azimuth_width_m; else, width = 0.5/p.dref; end
half_azimuth = half_range*abs(tan(p.theta_rad))+32*width+20;
keep = find(abs(p.azimuth_sheared_m)<=half_azimuth);
image = complex(zeros(size(spectrum,1),numel(keep),'single'));
for first = 1:32:size(spectrum,1)
    rows = first:min(first+31,size(spectrum,1));
    block = fftshift(ifft(ifftshift(spectrum(rows,:),2),[],2),2);
    image(rows,:) = block(:,keep);
end
p.azimuth_sheared_m = p.azimuth_sheared_m(keep);
end
