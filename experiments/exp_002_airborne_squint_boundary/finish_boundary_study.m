function finish_boundary_study(run_id)
root = boundary_setup(); cfg = boundary_config();
out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
for angle = cfg.angles_deg
 for range = cfg.closest_ranges_m
    assert(exist(fullfile(out,sprintf('sq%02d_r%05d_complete.mat',angle,range)),'file')==2,'粗扫描未完成。');
 end
end
refine_boundary_scan(run_id);
verify_boundary_sampling(run_id);
verify_boundary_numerics(run_id,[0,8,70]);
verify_wk_numerics(run_id);
verify_translated_probe(run_id);
verify_saved_reproduction(run_id);
write_phase_diagnostics(run_id);
write_boundary_report(run_id);
render_boundary_figures(run_id);
s = summarize_boundary(run_id); rd = sortrows(s(strcmp(s.method,'RD'),:),'angle_deg');
fail = find(~rd.all_probes_pass,1);
if ~isempty(fail) && fail>1
    render_boundary_figures(run_id,rd.angle_deg(fail-1:fail)',25000);
end
compare_roi_images(run_id);
organize_boundary_results(run_id);
audit_boundary_outputs(run_id);
write_dataset_description(run_id);
write_source_manifest(run_id);
fprintf('STUDY_COMPLETE %s\n',run_id);
end
