"""核验CS恒等式、参考参数误差、逐行注释和MATLAB正式指标。"""
import json
from pathlib import Path
import re
import numpy as np
import sympy as sp

ROOT = Path(__file__).resolve().parents[2]
RECORD = ROOT / 'experiments/exp_003_spaceborne_cs_teaching/records/run_20261104_223510_663'
OUT = ROOT / 'docs/derivations/spaceborne_cs_teaching'
OUT.mkdir(parents=True, exist_ok=True)
u, a, b, t = sp.symbols('u a b t', real=True)
center = (u+a*b)/(1+a)
square_residual = sp.simplify((t-u)**2+a*(t-b)**2-((1+a)*(t-center)**2+a/(1+a)*(u-b)**2))
assert square_residual == 0
r, rr, c, d = sp.symbols('r rr c d', positive=True)
new_center = sp.simplify((2*r/(c*d)+(1/d-1)*2*rr/(c*d))/(1/d))
assert sp.simplify(new_center-(2*r/c+2*rr/c*(1/d-1))) == 0
dtrue = sp.symbols('dtrue', positive=True)
mismatched_center = d*(2*r/(c*dtrue)+(1/d-1)*2*rr/(c*d))
mismatched_output = sp.simplify(mismatched_center-2*rr/c*(1/d-1))
assert sp.simplify(mismatched_output-2*r*d/(c*dtrue)) == 0
f, k, t0 = sp.symbols('f k t0', real=True, nonzero=True)
assert sp.expand(k*(t-t0-f/k)**2-k*(t-t0)**2+2*f*(t-t0)-f*f/k) == 0
fc, beta = sp.symbols('fc beta', positive=True)
g = sp.sqrt((fc+f)**2-beta**2)
assert sp.simplify(sp.diff(g,f,2)+beta**2/g**3)==0

# 本次数值参数固定为MATLAB已运行配置；不使用Python替代MATLAB成像。
c0=299792458.; fc0=5.3e9; kr=15.50829e6/37.1e-6
rs=6371000.+785000.; earth_radius=6371000.; mu=3.986004418e14
speed=lambda x: np.sqrt(mu*(rs*rs+earth_radius*earth_radius-np.asarray(x)**2)/(2*rs**3))
vref=float(speed(850000.)); fdc=2*vref*np.sin(np.deg2rad(5))*fc0/c0
fa=np.linspace(fdc-850,fdc+850,501)
fr=np.linspace(-15.50829e6/2,15.50829e6/2,161)
max_range=0.; max_kphase=0.; max_high=0.
for range_value in np.linspace(847700,852300,231):
    tile=850000+np.array([-1600.,0,1600])[np.argmin(abs(range_value-850000-np.array([-1600.,0,1600])))]
    vr=speed(range_value); vt=speed(tile)
    dt=np.sqrt(1-(c0*fa/(2*vt*fc0))**2)
    dr=np.sqrt(1-(c0*fa/(2*vr*fc0))**2)
    max_range=max(max_range,float(max(abs(range_value*(dt/dr-1)))))
    invkm=1/kr-c0*range_value*fa**2/(2*vr**2*fc0**3*dr**3)
    invkm0=1/kr-c0*tile*fa**2/(2*vt**2*fc0**3*dt**3)
    max_kphase=max(max_kphase,float(np.pi*max(fr**2)*max(abs(invkm-invkm0))))
    beta0=c0*fa[:,None]/(2*vr)
    exact=np.sqrt((fc0+fr)**2-beta0**2)
    poly=fc0*dr[:,None]+fr/dr[:,None]-beta0**2*fr**2/(2*fc0**3*dr[:,None]**3)
    max_high=max(max_high,float(4*np.pi*range_value/c0*np.max(abs(exact-poly))))

files=[ROOT/'echo_generation/configs/spaceborne_cs_teaching.m', ROOT/'echo_generation/geometry/spaceborne_equivalent_geometry.m', ROOT/'echo_generation/targets/spaceborne_cs_targets.m', ROOT/'echo_generation/generate_spaceborne_cs_echo.m', ROOT/'signal_processing/cs/spaceborne_cs_options.m', ROOT/'signal_processing/cs/run_spaceborne_cs.m']+list((ROOT/'experiments/exp_003_spaceborne_cs_teaching').glob('*.m'))
line_count=0
for path in files:
    for number,line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(),1):
        if line.strip() and not line.lstrip().startswith('%'):
            assert '%' in line, f'{path}:{number} 缺少逐行注释'
            line_count+=1
processor=(ROOT/'signal_processing/cs/run_spaceborne_cs.m').read_text(encoding='utf-8')
assert not re.search(r'dataset\.(?:targets|truth)',processor)
assert 'interp1(tau' not in processor
single=json.loads((RECORD/'scene_1_checks.json').read_text(encoding='utf-8'))
nine=json.loads((RECORD/'scene_9_checks.json').read_text(encoding='utf-8'))
assert single['passed'] and nine['passed']
targets=nine['targets']
report={'symbolic_square_identity':True,'symbolic_rcm_center_identity':True,'symbolic_mismatched_velocity_center':True,'symbolic_chirp_transform_sign':True,'symbolic_spectrum_second_derivative':True,'matlab_code_files':len(files),'commented_executable_lines':line_count,'processor_uses_target_truth':False,'rcmc_uses_interpolation':False,'velocity_at_target_ranges_mps':[float(speed(x)) for x in [848500,850000,851500]],'full_output_band_max_tile_migration_error_m':max_range,'full_output_band_max_inverse_km_phase_error_rad':max_kphase,'full_output_band_max_quadratic_spectrum_remainder_rad':max_high,'evaluated_band':'grid maxima across output ranges +/-2300 m, fb +/-850 Hz, fr +/-B/2; exclude finite-aperture and model errors; not rigorous continuous bounds','rcm_before_span_m':single['rcm_before_span_m'],'rcm_after_span_m':single['rcm_after_span_m'],'rcm_after_max_error_m':single['rcm_after_max_abs_error_m'],'nine_max_range_error_m':max(abs(x['range_error_m']) for x in targets),'nine_max_azimuth_error_m':max(abs(x['azimuth_error_m']) for x in targets),'nine_range_width_m':[min(x['range']['irw_3db_m'] for x in targets),max(x['range']['irw_3db_m'] for x in targets)],'nine_azimuth_width_m':[min(x['azimuth']['irw_3db_m'] for x in targets),max(x['azimuth']['irw_3db_m'] for x in targets)],'matlab_records':str(RECORD.relative_to(ROOT)),'all_matlab_targets_passed':True}
(OUT/'filter_checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
