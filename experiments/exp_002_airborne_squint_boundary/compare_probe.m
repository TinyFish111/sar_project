function check = compare_probe(measured, reference, threshold)
% 所有阈值仅适用于本实验，无加窗、统一地面轴、固定切片积分窗口。
check.irw_ratio_x = measured.azimuth.irw_m/reference.azimuth.irw_m;
check.irw_ratio_y = measured.range.irw_m/reference.range.irw_m;
check.pslr_loss_x_db = measured.azimuth.pslr_db-reference.azimuth.pslr_db;
check.pslr_loss_y_db = measured.range.pslr_db-reference.range.pslr_db;
check.islr_loss_x_db = measured.azimuth.islr_db-reference.azimuth.islr_db;
check.islr_loss_y_db = measured.range.islr_db-reference.range.islr_db;
check.position_error_x_cells = abs(measured.error_x_m)/reference.azimuth.irw_m;
check.position_error_y_cells = abs(measured.error_y_m)/reference.range.irw_m;
check.valid = measured.azimuth.valid && measured.range.valid && ~measured.search_boundary;
check.pass = check.valid && max(abs([check.irw_ratio_x,check.irw_ratio_y]-1))<=threshold.irw_ratio_max-1 ...
    && max([check.pslr_loss_x_db,check.pslr_loss_y_db])<=threshold.pslr_degradation_db ...
    && max([check.islr_loss_x_db,check.islr_loss_y_db])<=threshold.islr_degradation_db ...
    && max([check.position_error_x_cells,check.position_error_y_cells])<=threshold.position_resolution_fraction;
end
