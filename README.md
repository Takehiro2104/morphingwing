# morphingwing
this practical implementation pack adds hands-on workflows, runnable scripts, and automation templates aligned with your Handbook sections (Design Optimisation Framework, Methodologies, Algorithms, Testing, Validation).

## Repo Project Structure
---
```
morphwing/
  README.md
  /matlab
    main_nsga2.m
    evalDesign.m
    buildAirfoil_bspline.m
    constraints.m
    runCFD_xfoil.m
    runCFD_fluent.m % stub calling Fluent via journal
    surrogate_fit_gp.m
    montecarlo_robustness.m
    postprocess_flightlog.m
  /ansys
    fluent_batch.jou
    wb_param_script.py % Workbench/IronPython parameter script
    apdl_simp_topopt.mac
  /dakota
    dakota_nsga2.in
  /embedded
    morph_ctrl_rtos_pseudocode.md
  /data
    airfoils/
    logs/
    meshes/
    results/
```
# 1) MATLAB: Surrogate-Assisted Multiobjective Optimisation (L/D ↑, Actuation Energy ↓)

  * Parameterise airfoil/wing section with B-splines (≈ 10–14 design variables).
  * Fast eval path with XFOIL (concept phase), heavy eval path with Fluent (detailed phase).
  * Surrogate (Gaussian Process) to accelerate NSGA-II.
  * Constraints: structural stress (from FEA summary), geometric smoothness, thickness and camber bounds, actuator torque limit.

## Common MATLAB pitfalls & quick fixes
---

* XFOIL hangs on certain geometries: add panel reset (```PPAR N 200```), limit AoA sweep, and detect non-convergence by timeouts (use ```parallel.pool.Constant``` + ```parfeval``` with timeout; replace design with penalised objectives).
* ```fitrgp``` memory demand with large DOE: downsample via MaxDatapoints or switch to rational quadratic kernel; cache models.
* ```gamultiobj``` stagnation: increase mutation rate: ```opts.MutationFcn=@mutationadaptfeasible;``` or seed diverse LHS.
* Invalid airfoil (self-intersecting): enforce monotonic x and ```yu>yl``` check; if violated, return large penalties.
* Parallel pool deadlocks: use ```parpool('threads')``` for license-light threading; guard CFD calls with file-unique temp names.

# 2) ANSYS Fluent Automation (batch journals + Workbench parameterisation)

## 2.1 ```fluent_batch.jou``` (2D Example Skeleton)Usage (Windows CLI)
```fluent 2d -g -i fluent_batch.jou > run.log```

> Hook this to ```runCFD_fluent.m``` by writing a case with the morphed profile via a parametric mesh (Pointwise/ICEM) or Workbench Geometry.

## 2.2 Workbench parameter drive (```wb_param_script.py```)
Typical failure modes:
  * Geometry fails to heal → add constraints to keep thickness > 0. Mitigation: pre-validate in MATLAB; if failed, skip WB update.
  * Fluent exits with negative volume error → remesh with boundary-layer growth limits; reduce morph step size (continuation strategy).

# 4)Python/OpenMDAO Alternative (if MATLAB licenses are constrained)

  * Use ```openmdao``` + ```pyoptsparse``` (NSGA2/SNOPT) with a ```Component``` that calls XFOIL or Fluent.
  
  * Provide analytic/FD gradients for SNOPT with geometry-to-mesh continuity checks.

Skeleton (pseudocode):
```python
class AeroEval(om.ExplicitComponent):
def setup(self):
self.add_input('dv', shape=(12,))
self.add_output('neg_L_over_D')
self.add_output('E_act')
def compute(self, inputs, outputs):
geom = build_bspline(inputs['dv'])
res = run_xfoil(geom)
outputs['neg_L_over_D'] = -res['L_over_D']
outputs['E_act'] = res['E']
```

# 5) Dakota Coupling (multiobjective, black-box friendly)

## 5.1 ```dakota_nsga2.in``` (refined)

> Notes
> * ```evaluation_concurrency``` matches cores; reduce if XFOIL or Fluent licensing is a bottleneck.
> * ```work_directory``` + ```directory_tag``` isolates each evaluation; avoids file clobbering.

## 5.3 CLI recipes
* Run (Windows / MATLAB ≥ R2020b):
```dakota -i dakota/dakota_nsga2.in -o dakota/dakota.log```
* Run (Linux):
```dakota -i dakota/dakota_nsga2.in -o dakota/dakota.log```
* Headless MATLAB alternative: Replace ```analysis_driver``` with a shell/Python wrapper that calls ```matlab -nodisplay -nosplash -batch "evalDesign_cli"```.

## 5.4 Output parsing & Pareto export (MATLAB helper)
```matlab
function pareto_from_dakota(outFile)
T = readtable(outFile, 'FileType','text');
% Assume columns: f1 f2 c x1..x12
f1 = T.Var1; f2 = T.Var2; c = T.Var3;
X = T{:,4:15};
feas = c<=0;
F = [f1, f2];
% Naive non-dominated sort
nd = true(height(T),1);
for i=1:height(T)
if ~feas(i), nd(i)=false; continue; end
nd(i) = all(~(F(:,1)<=F(i,1) & F(:,2)<=F(i,2) & any(F< F(i,:),2)) | (1:height(T))'==i);
end
XP = X(nd,:); FP = F(nd,:);
save('data/results/dakota_pareto.mat','XP','FP');
end
```

## 5.5 Common Dakota pitfalls & debugging
* Hanging evaluations: ensure each run directory has unique temp names; add timeouts inside ```evalDesign_cli``` for XFOIL/Fluent.
* Mismatched counts: if ```num_nonlinear_inequality_constraints``` ≠ rows written, Dakota aborts. Keep exactly one line for ```c```.
* Parallel license thrash: limit concurrency; for Fluent, set a queue script that checks out tokens before launching.

# 6) Flight-Test Data Post-Processing (MATLAB)

## 6.2 Sync & denoise tips
* Align IMU and pitot timestamps; resample at 100 Hz before derived metrics.
* Apply a Hampel or median filter to V and AoA to suppress spikes prior to L/D computation.
* Validate sign conventions (AoA increasing vs. CL_est sign).

# 7) Real-Time Morphing Control (RTOS-friendly pseudocode)
## 7.1 Control tasks
```
Task SENSOR (200 Hz): read IMU, airspeed, encoders; fuse; publish TelemetryState.
Task PLANNER (50 Hz): lookup optimal morph (surrogate map f: [V, AoA]→[camber, twist]); rate-limit.
Task CONTROLLER (200 Hz): PID on morph angle with feedforward torque map; enforce current/thermal limits.
Task SAFETY (200 Hz): stall margin, overcurrent, thermal; revert baseline on fault.
```
## 7.2 Torque/feedforward table (example CSV schema)
```
# morph_angle_deg, torque_Nm
-5, 0.20
 0, 0.35
 5, 0.55
10, 0.80
```
## 7.3 Safety interlocks

* Loss of airspeed → freeze morph at last safe setting.
* Vibration spike → hold morph, notify pilot.
* Brownout → spring-return or neutral-camber fallback.

# 8) Robustness & Uncertainty: Monte Carlo (MATLAB)

## 8.2 Robust-selection rule
Choose Pareto candidates with highest empirical feasibility ```p_feas``` (or Conditional-Value-at-Risk on objectives) before prototyping
