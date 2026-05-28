# Proximal Causal Inference Explorer — Design Spec

- **Date:** 2026-05-27
- **Status:** Approved (design); pending implementation plan
- **Author:** Alan Brookhart (with Claude)

## 1. Overview

An R/Shiny application that lets a user vary the strengths of the associations
in a proximal-causal-inference data-generating process (DGP), depicted as a DAG,
and observe how those choices affect the **bias** and **variance** of the
proximal causal estimator relative to standard alternatives. The pedagogical
goal is to make tangible *when proximal causal inference helps, when it does not,
and what it costs in efficiency.*

The theory is drawn from `./literature`: Miao, Geng & Tchetgen Tchetgen (2018);
Tchetgen Tchetgen et al. (2024); and Zivich et al. (2023). The DGP generalizes
the Zivich et al. simulation (abstract variable names, every coefficient tunable)
rather than reproducing its clinical cover story.

### Goals
- Interactively tune the DAG edge strengths and instantly see the DAG reflect them.
- Run Monte Carlo simulations comparing proximal g-computation against standard
  g-computation (two adjustment sets), an oracle, and a crude estimator.
- Show results two ways: a **Snapshot** at the current settings and a **Sweep**
  of one association across a range.
- Match the look-and-feel of the existing StudySizePlanning Shiny app
  (`sidebarLayout` + `tabsetPanel`), branded with the Headwater Science logo and
  color palette.
- Be deployable to shinyapps.io while also running locally.

### Non-goals
- Binary or time-to-event outcomes (continuous Y only; see §4).
- Time-varying treatments / longitudinal proximal g-formula.
- Doubly-robust / semiparametric / kernel / deep bridge-function estimators.
- Real-data analysis. The app is a simulation sandbox only.

## 2. The DAG

Nodes (observed unless noted):

- **X** — measured confounder
- **U** — *unmeasured* confounder (latent; drawn dashed)
- **Z** — treatment confounding proxy (negative-control exposure)
- **W** — outcome confounding proxy (negative-control outcome)
- **A** — binary treatment
- **Y** — continuous outcome

Edges (each carries a tunable coefficient):

| Edge | Coefficient | Role |
|------|-------------|------|
| X → U | `a_xu` | links measured & latent confounders |
| X → A | `alpha_x` | measured confounding (treatment side) |
| X → Y | `beta_x` | measured confounding (outcome side) |
| U → Z | `gamma_z` | treatment-proxy strength |
| U → W | `gamma_w` | outcome-proxy strength |
| Z → A | `alpha_z` | proxy → treatment link |
| W → Y | `beta_w` | proxy → outcome link |
| U → A | `delta` | **residual** unmeasured confounding (treatment side) |
| U → Y | `delta` | **residual** unmeasured confounding (outcome side) |
| Z → Y | `lambda` | **proxy invalidity** (exclusion-restriction violation) |
| A → Y | `tau` | **true causal effect (ACE)** — the estimand |

Color encoding in the rendered DAG: structural edges (Headwater Ocean
`#0888A8`); the ACE A→Y (Navy `#140298`, bold); residual confounding δ (Orange
`#FD8524`, dashed); proxy invalidity λ (Crimson `#A5052D`, dashed). Edge
*linewidth* is proportional to `|coefficient|`; an edge with coefficient 0 is
drawn faint/at minimum width.

## 3. Data-generating process

For each of `n` i.i.d. units (`logit⁻¹` is the inverse-logit / expit):

```
X  ~ Normal(0, 1)
U  = a_xu·X + Normal(0, sd_u)
Z  = gamma_z·U + Normal(0, sd_z)
W  = gamma_w·U + Normal(0, sd_w)
A  ~ Bernoulli( logit⁻¹( alpha0 + alpha_z·Z + alpha_x·X + delta·U ) )
Y  = tau·A + beta_w·W + beta_x·X + delta·U + lambda·Z + Normal(0, sd_y)
```

Because the outcome model has no A×covariate interactions, the average causal
effect E[Y¹] − E[Y⁰] equals **`tau`** exactly. This is the ground truth all
estimators are compared against.

### Parameters, defaults, and slider ranges

| Param | Meaning | Default | Range | Tier |
|-------|---------|---------|-------|------|
| `tau` | true ACE (A→Y) | 1.0 | [-3, 3] | primary |
| `gamma_z` | treatment-proxy strength (U→Z) | 1.0 | [0, 3] | primary |
| `gamma_w` | outcome-proxy strength (U→W) | 1.0 | [0, 3] | primary |
| `delta` | residual confounding (U→A, U→Y) | 1.0 | [0, 3] | primary |
| `lambda` | proxy invalidity (Z→Y) | 0.0 | [0, 3] | primary |
| `alpha_z` | Z→A | 1.0 | [0, 3] | advanced |
| `beta_w` | W→Y | 1.0 | [0, 3] | advanced |
| `alpha_x` | X→A | 0.5 | [-2, 2] | advanced |
| `beta_x` | X→Y | 0.5 | [-2, 2] | advanced |
| `a_xu` | X→U | 1.0 | [0, 3] | advanced |
| `alpha0` | treatment intercept | 0.0 | [-2, 2] | advanced |
| `sd_u`,`sd_z`,`sd_w`,`sd_y` | noise SDs | 1.0 | fixed (not exposed initially) | — |
| `n` | sample size per replicate | 500 | [100, 5000] | advanced |
| `M` | Monte Carlo replicates (Snapshot) | 1000 | [200, 5000] | advanced |

The app opens on the **Residual confounding present** preset (`delta=1`,
`lambda=0`) so the proximal advantage is visible immediately.

### Presets (generic names)

| Preset | Settings | Teaching point |
|--------|----------|----------------|
| Valid proxies, no residual confounding | δ=0, λ=0 | all estimators ≈ unbiased; minimal standard is most efficient |
| Residual confounding present | δ=1, λ=0 | standard biased; proximal & oracle unbiased |
| Invalid treatment proxy | δ=1, λ=1 | all biased — proximal is no defense against an invalid proxy |
| Weak proxies | γ_z=γ_w=0.3, δ=1, λ=0 | proximal unbiased but high variance (weak-instrument analog) |
| Custom | whatever the sliders say | — |

## 4. Estimators

All operate on the same simulated dataset per replicate. τ̂ is the coefficient on
`A`; for a linear outcome model with no A-interactions this coefficient equals
the standardized (g-computation) ACE estimate. SEs are model-based (`ivreg`'s
2SLS SE for proximal; `lm`'s SE otherwise), which are valid under this
homoskedastic, correctly-specified-where-applicable DGP.

| Estimator | Fit | Expected behavior |
|-----------|-----|-------------------|
| **Proximal g-computation (P2SLS)** | `ivreg(Y ~ A + X + W \| A + X + Z)` — W endogenous, instrumented by Z; A, X exogenous | consistent for τ when λ=0 (even if δ>0); biased when λ≠0 |
| **Standard g-comp, full {X,Z,W}** | `lm(Y ~ A + X + Z + W)` | unbiased only when δ=0; biased when δ>0 |
| **Standard g-comp, minimal {X,W}** | `lm(Y ~ A + X + W)` | unbiased & lowest-variance when δ=λ=0; most biased when δ>0 |
| **Oracle** | `lm(Y ~ A + X + Z + W + U)` | correctly-specified full model; unbiased for all settings, tightest SE |
| **Crude** | `lm(Y ~ A)` | fully confounded baseline |

**Why P2SLS = proximal g-computation:** with a linear outcome bridge
`h(W,A,X) = β₀ + τ·A + η_w·W + η_x·X`, parametric proximal g-computation reduces
to two-stage least squares with Z as the instrument for W (Tchetgen Tchetgen et
al. 2024, Remark on P2SLS). Stage 1 regresses W on (1, A, X, Z); stage 2
regresses Y on (1, A, X, Ŵ). `ivreg` implements exactly this and returns a valid
2SLS standard error. Z is excluded from the structural (stage-2) equation — that
exclusion *is* the proxy-validity assumption, violated when λ≠0.

**Why the oracle includes Z and W:** the backdoor paths from A to Y are blocked
by {X, U} except the path A ← Z → Y, which exists when λ≠0 and is blocked by Z.
Fitting the full correct outcome model `Y ~ A + X + Z + W + U` is therefore
unbiased for every parameter setting and has the smallest residual variance —
the honest "best you could do if U were observed."

These behaviors mirror the Zivich et al. (2023) Web Table 1 results and are the
basis for the regression tests in §8.

## 5. Performance metrics

Computed per estimator over the `M` replicates (true value τ):

- **Bias** = mean(τ̂) − τ
- **Empirical SE (ESE)** = sd(τ̂)
- **Mean estimated SE** and **SE ratio (SER)** = mean(ŜE) / ESE
- **RMSE** = sqrt(Bias² + ESE²)
- **Coverage** = proportion of Wald 95% CIs (τ̂ ± 1.96·ŜE) containing τ

## 6. Views

### Snapshot tab (default)
At the current slider settings, run `M` Monte Carlo replicates and display:
- **Overlaid density plot** of the M point estimates, one curve per estimator,
  with a vertical reference line at the true τ.
- **Metrics table** (DT): estimator | Bias | ESE | SER | RMSE | Coverage,
  colored to match the density curves.

### Sweep tab
- Inputs: which association to sweep (dropdown over `tau, gamma_z, gamma_w,
  delta, lambda, alpha_z, beta_w, alpha_x, beta_x, n`), min, max, grid size `K`
  (default 15), and replicates per grid point `M_sweep` (default 400).
- For each of the K grid values, hold all other parameters at their current
  values, run `M_sweep` replicates, summarize.
- Output: two stacked line charts sharing the x-axis (the swept value) — **Bias
  vs. parameter** (with a y=0 reference) and **Empirical SE vs. parameter** (a
  radio toggle switches the second chart between ESE and RMSE) — one line per
  estimator.

### Interaction model
- The **DAG re-renders live** on every slider change (cheap; no simulation).
- Monte Carlo runs only when the user presses **Run simulation** (`eventReactive`),
  shown with a `withProgress` bar. This keeps slider dragging responsive.

## 7. Architecture

Classic `sidebarLayout()` inside a `bslib::page` themed with the Headwater
palette. Main panel is a `tabsetPanel`: **About**, **Snapshot**, **Sweep**,
**Methods & formulas** (MathJax, mirroring StudySizePlanning's "Derivations" tab).

```
app.R                 # bslib page; sidebar (presets + grouped sliders) + tabset; wires modules
R/dgp.R               # simulate_data(n, params) -> data.frame(X,U,Z,W,A,Y)
R/estimators.R        # fit_all(data) -> tibble(estimator, estimate, se); one fit_* per estimator
R/simulation.R        # run_monte_carlo(params, n, M, seed) ; run_sweep(params, sweep_var, grid, M_sweep)
R/metrics.R           # summarise_estimates(estimates_df, truth) -> bias/ESE/SER/RMSE/coverage
R/dag.R               # render_dag(params) -> ggplot; fixed node layout, edge width ∝ |coef|, typed colors
R/theme.R             # headwater_theme() bslib theme; HEADWATER palette constants; ggplot theme
R/presets.R           # named list of preset parameter sets
www/headwater-logo.png   # extracted from "Headwater Science - RGB Color.pdf"
www/custom.css           # brand fonts (serif headings), fine-tuning
tests/testthat/          # see §8
renv.lock                # pinned deps for reproducible shinyapps.io deploy
```

### Key function contracts

- `simulate_data(n, params) -> data.frame` with columns `X, U, Z, W, A, Y`.
  `params` is a named list holding all coefficients/SDs from §3.
- `fit_all(data) -> tibble(estimator, estimate, se)` — five rows, one per
  estimator. Each `fit_*` is a small pure function taking `data`.
- `run_monte_carlo(params, n, M, seed) -> list(estimates = tibble(rep, estimator,
  estimate, se), metrics = tibble(estimator, bias, ese, ser, rmse, coverage),
  truth = tau)`.
- `run_sweep(params, sweep_var, grid, M_sweep, seed) -> tibble(value, estimator,
  bias, ese, rmse, coverage)`.
- `render_dag(params) -> ggplot` — pure function of params; no Shiny deps so it
  is independently testable/renderable.

### Reactivity
- `params()` reactive assembles the named list from the sliders/preset.
- Selecting a preset sets the slider values (and flips the preset label to
  "Custom" once a slider is touched).
- `render_dag(params())` drives the live DAG output.
- `eventReactive(input$run, run_monte_carlo(params(), n, M))` drives Snapshot.
- A separate `eventReactive(input$run_sweep, run_sweep(...))` drives Sweep.

### Dependencies
`shiny`, `bslib`, `ggplot2`, `ivreg` (or `AER`), `dplyr`, `tidyr`, `tibble`,
`DT`, `scales`. All install and deploy cleanly on shinyapps.io. Monte Carlo is
vectorized in base R (no `future`/parallel deps) — `M=1000` × 5 fits runs in
~1–2 s; the sweep (`K=15` × `M_sweep=400`) in ~10–20 s behind a progress bar.

## 8. Testing strategy (TDD)

Non-UI logic is fully unit-tested with `testthat`. UI/reactive wiring is verified
manually (optionally a smoke test that the app starts).

**`test-dgp.R`** — `simulate_data` returns the right columns/row count; with a
fixed seed the empirical means/correlations have the expected signs and rough
magnitudes (e.g., cor(Z, U) increases with `gamma_z`; A is ~Bernoulli).

**`test-estimators.R`** — `fit_all` returns five rows with finite estimates and
SEs; on a single large-n draw (`n = 2e5`, fixed seed) the **oracle** recovers τ
within a tight tolerance (|τ̂ − τ| < 0.03) for several parameter settings.

**`test-presets.R`** (the core regression tests, on large-n single draws so they
are fast and near-deterministic):

| Preset | Assertion |
|--------|-----------|
| Valid proxies (δ=0, λ=0) | proximal, standard-full, standard-minimal, oracle all within ±0.05 of τ; crude biased |
| Residual confounding (δ=1, λ=0) | proximal & oracle within ±0.05 of τ; standard-full and standard-minimal each biased by > 0.15 |
| Invalid proxy (δ=1, λ=1) | proximal biased by > 0.15 (no longer protective); oracle within ±0.05 |

**`test-metrics.R`** — `summarise_estimates` computes bias/ESE/RMSE/coverage
correctly on a hand-constructed input; SER ≈ 1 for the oracle over a modest MC
run.

Tolerances are set generously enough to avoid flakiness while still
distinguishing "unbiased" from "biased." Sweep is tested by checking monotone
trends (e.g., standard estimator's |bias| is non-decreasing in δ).

## 9. Branding

- Logo `Headwater Science - RGB Color.pdf` → `www/headwater-logo.png`, placed
  top-left of the title bar.
- Palette: Pedestal Blue `#73F0E9`, Aqua `#0FB5D2`, Ocean `#0888A8`, Azure
  `#4166FF`, Navy `#140298`; shades Pearl `#F0F0F0`, Silver `#ADADAD`, Graphite
  `#575757`; secondary Orange `#FD8524`, Crimson `#A5052D`, Forest `#495102`.
- Headings in a serif face echoing the wordmark; body in a clean sans. Ocean/Aqua
  for primary accents and buttons; Navy for emphasis and the ACE.

## 10. Open questions

None outstanding. Noise SDs are fixed at 1 initially; exposing them is a
straightforward later addition if desired.
