# morphingwing/
This practical implementation pack adds hands-on workflows, runnable scripts, and automation templates aligned with your Handbook sections (Design Optimisation Framework, Methodologies, Algorithms, Testing, Validation).

Recommended Project Structure
---
```python
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
