# MiniProject Assessment for Zhiquan Kang

## Computing

### A1 — Project Organisation

The project has the expected top-level structure with `code/`, `data/`, and `results/`, and the analysis files are grouped in a way that makes the workflow easy to inspect. The main weakness is repository readiness for reproduction: there is no `README`, so language versions, dependencies, package purposes, and run instructions are undocumented, and `results/` contains committed outputs including `model_results.csv`, `model_coefficients.csv`, `best_model_summary.csv`, `final_analysis/`, and `final_plots/`. The `.gitignore` is present, which helps, but it has not prevented a large number of generated files from being tracked, and the repository also includes a large binary workspace file, `code/mini_plot.RData`. Future submissions would benefit from a short but complete `README` and a clean separation between source files and generated outputs so that another user can rebuild the project from scratch rather than inherit prior results.

### A2 — Single-Script Reproducibility

#### Workflow & Solution Quality

No correctly named `run_MiniProject.*` script was found (it was incorrectly named `run_script.sh`), so the end-to-end pipeline could not be executed under the required submission convention. There is still substantial workflow logic in `code/run-miniproject-script.sh`, which calls `Data preparation.R`, `Model fitting.R`, and `fitting_results_analysis.R`, then attempts LaTeX compilation, and `code/run_script.sh`, which calls `mini_prep.R`, `mini_fit.R`, and `mini_plot.R`; however, these are not the required entry-point filenames and the first shell script also references script names that do not match the detected R files. Reproducibility is weakened further by package installation commands embedded in the code context, including `install.packages("minpack.lm")` and `install.packages("patchwork")`, which make runs environment-dependent and harder to validate on a clean system. A next step would be to provide one root-level `run_MiniProject.sh` that uses the actual script names, checks dependencies up front, writes outputs into `results/`, and compiles `code/main.tex` consistently from the project root.

### A3 — Code Quality & Style

#### Script-level Technical Feedback

The R code is meaningfully modularised, `code/mini_fit.R` is a good example: functions such as `calc_model_stats`, `extract_stats`, `extract_coefs`, and `fit_logistic_model` separate statistics, coefficient extraction, and nonlinear fitting into reusable units. `code/mini_plot.R` extends that structure with `get_predictions_for_plot`, `safe_filename`, and `make_single_plot`, which keeps plotting logic clearer than a single monolithic script would. Comment density is 0.086 with 66 comment lines, which is adequate rather than generous, and naming is usually informative, although the shell layer is less tidy because `code/run-miniproject-script.sh` mixes two different workflows and includes commands that do not belong in a run script. Refactor `code/run-miniproject-script.sh` into one clean orchestration script and move package installation and workspace-clearing commands out of analysis scripts so that the codebase has a single, predictable execution path.

### A4 — Model Fitting & Statistical Analysis

#### NLLS

The fitting work goes beyond the minimum requirement by comparing at least two models and implementing nonlinear least squares through `nlsLM` for the logistic model alongside a quadratic baseline. In `code/mini_fit.R`, `fit_logistic_model` uses multi-start fitting with randomised starting values for `r`, `K`, and `N0`, lower bounds, `maxiter = 500`, and `tryCatch`, which is a sound way to handle the fragility of nonlinear optimisation; model summaries then include pseudo-\(R^2\), AIC, AICc, and BIC, and outputs are written to CSV for downstream use. The main technical inconsistency is that the code context shows `AICc(m)` being used while `MuMIn` is commented out, so the AICc-based model selection path is not fully robust as written, and the evidence bundle’s approximate model count of 4 likely overstates the actual fitted set, which is clearly quadratic plus logistic in the report and code. A next step would be to make the AICc calculation fully self-contained and document the starting-value heuristic and failed-fit counts explicitly in the saved results.

### A5 — Version Control & Workflow Discipline

The repository has 28 commits in total, but the automated history check reports 0 commits touching `MiniProject/`, so there is little visible evidence of iterative MiniProject development in the expected location. That makes it difficult to reward workflow discipline highly, even though the project itself contains substantial work. Future submissions would benefit from smaller, descriptively named commits tied to distinct stages such as data cleaning, model fitting, plotting, and report drafting.

## Report

### B1 — Report Format & Presentation

The report is within the word limit at about 2462 words and includes a title page with author, affiliation, date, and word count. Several required LaTeX presentation elements are missing from `code/main.tex`: the automated checks did not find `11pt`, 1.5 spacing, line numbering, a bibliography command, or a compiled PDF, and only two packages (`graphicx`, `float`) were detected. The report also contains only three display items, below the target range of four to six, although all three have captions. Future submissions would benefit from bringing the LaTeX setup into full compliance and ensuring the bibliography is compiled and the final PDF is generated as part of the workflow.

### B2 — Introduction & Objectives

The Introduction gives a clear biological starting point by framing microbial population growth curves, S-shaped trajectories, and the trade-off between phenomenological and mechanistic models. The two research questions are stated explicitly and the expected circumstances favouring logistic versus quadratic fits emerge reasonably naturally from the preceding context. The main gap is course-specific grounding: the automated checks found the required temperature/single-population growth framing but no clear reference to the two relevant MQB chapter themes, and the objectives are not sharply separated into biological versus methodological aims. A stronger version would connect the study more directly to temperature-dependent metabolism and population growth theory from the course and distinguish more clearly between the biological question and the model-comparison procedure.

### B3 — Methods (including Computing Tools)

The Methods section covers data provenance, cleaning, ID construction, log transformation, model equations, fitting strategy, and comparison metrics in a way that is generally reproducible and easy to follow. The `Computational Tools` subsection is present and names R, bash, Python, LaTeX, and key packages such as `tidyverse`, `minpack.lm`, `MuMIn`, and `ggplot2`, with brief justification for their use. One mismatch between report and code weakens confidence in the computational description: the report says AICc calculations used `MuMIn`, while the code context comments out `MuMIn` and mixes manual information-criterion calculations with `AICc(m)` calls. A next step would be to align the written methods exactly with the implemented code and state the fitting details—especially starting-value generation and convergence handling—with the same precision used in the scripts.

### B4 — Results & Display Items

The Results section follows the project objectives in a sensible order, moving from overall model comparison to representative fitted curves and then goodness-of-fit summaries. The section includes three display items—two figures and one table—and all three have informative captions, but this is still below the expected 4–6 item range and limits how much of the story can be carried visually. There is also some interpretive language in the Results, such as discussion of biological interpretability and when logistic models are “most effective,” which would sit more cleanly in the Discussion. Future work could include a dedicated model-comparison table by criterion and one additional figure summarising convergence or fit-quality variation across curve types.

### B5 — Discussion, Conclusions & Abstract

The Discussion returns to the central comparison and gives a biologically sensible interpretation of when logistic models are more informative and when quadratic models are practically useful. Limitations and future directions are present, including incomplete trajectories, alternative nonlinear models, and the effect of log transformation, and the separate Conclusion provides a clear take-home message. The main mark cap here comes from the required advanced-methods engagement: there is no substantive discussion of MLE, Bayesian inference, or machine learning as future analytical directions, so this section cannot reach the distinction band under the rubric. A stronger discussion would explain, for example, how Bayesian hierarchical modelling could borrow strength across the 285 growth curves or how likelihood-based approaches could improve uncertainty quantification for poorly identified carrying capacities.

## Summary

Final classification (student-facing):

- Part A (Computing): Pass
- Part B (Report): Merit
- Overall: Pass
