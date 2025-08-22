# morphingwing/
This practical implementation pack adds hands-on workflows, runnable scripts, and automation templates aligned with your Handbook sections (Design Optimisation Framework, Methodologies, Algorithms, Testing, Validation).

# Recommended Project Structure
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
