function result = squint_result(cache, p, image, method, elapsed_s)
% 各方法独立计算，公共封装只统一结果坐标与追溯信息。
result.method = method;
result.input_dataset_id = cache.meta.id;
result.native_image = image;
result.closest_range_m = p.range_output_m;
result.sheared_azimuth_m = p.azimuth_sheared_m;
result.range_step_m = mean(diff(p.range_output_m));
result.azimuth_step_m = mean(diff(p.azimuth_sheared_m));
result.platform_mid_along_m = cache.meta.geometry.platform_mid_along_m;
result.height_m = cache.meta.configuration.geometry.height_m;
result.squint_rad = p.theta_rad;
result.reference_closest_range_m = p.reference_range_m;
result.processing_state = 'complex_image_with_deterministic_spatial_carrier_removed';
result.elapsed_s = elapsed_s;
end
