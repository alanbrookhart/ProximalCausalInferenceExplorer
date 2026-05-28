# Proximal Causal Inference Explorer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an R/Shiny app that lets a user tune the association strengths in a proximal-causal-inference DAG and see how bias and variance of the proximal estimator (vs. standard, oracle, and crude alternatives) respond, via a Monte Carlo "Snapshot" and a parameter "Sweep".

**Architecture:** A non-package Shiny app. Pure-logic functions live in `R/*.R` (auto-sourced by Shiny at runtime and by testthat helpers in tests). `app.R` wires the bslib sidebar/tabset UI to those functions. The DAG and all plots are pure functions of a `params` list, making them independently testable. Five estimators are fit per simulated dataset; their estimates are summarized into bias/ESE/SER/RMSE/coverage.

**Tech Stack:** R 4.3, shiny, bslib (Bootstrap 5), ggplot2, patchwork, ivreg (P2SLS), dplyr/tidyr/tibble, DT, scales, testthat (edition 3). Branding via Headwater palette + `www/custom.css`.

**Reference spec:** `docs/superpowers/specs/2026-05-27-proximal-ci-shiny-design.md`

---

## File Structure

| File | Responsibility |
|------|----------------|
| `R/theme.R` | `HEADWATER` palette, `ESTIMATOR_COLORS`, `EDGE_COLORS`, `headwater_bs_theme()`, `headwater_ggtheme()` |
| `R/dgp.R` | `default_params()`, `simulate_data(n, params)` |
| `R/estimators.R` | `fit_proximal/standard_full/standard_minimal/oracle/crude`, `fit_all(data)` |
| `R/metrics.R` | `summarise_estimates(estimates, truth)` |
| `R/simulation.R` | `run_monte_carlo(params, n, M, seed)`, `run_sweep(params, sweep_var, values, n, M_sweep, seed)` |
| `R/presets.R` | `presets()` named list of parameter sets |
| `R/dag.R` | `render_dag(params)` -> ggplot |
| `R/plots.R` | `plot_snapshot(mc)`, `plot_sweep(sweep_df, sweep_var, metric)` |
| `R/ui_text.R` | `dag_legend_html()`, `methods_html()` (static HTML/MathJax strings) |
| `app.R` | bslib UI + server; reactivity |
| `www/custom.css`, `www/headwater-logo.png`, `www/about.md` | branding + About copy |
| `tests/testthat/helper-load.R` | sources `R/*.R` before tests |
| `tests/testthat/test-*.R` | unit + regression tests |

**Estimator name strings are used verbatim across `theme.R`, `estimators.R`, `metrics.R`, and `plots.R`. They must match exactly:** `"Proximal (P2SLS)"`, `"Standard, full"`, `"Standard, minimal"`, `"Oracle"`, `"Crude"`.

**Test command (run from project root):** `Rscript -e 'testthat::test_dir("tests/testthat")'`. Filter to one file with `filter=`, e.g. `Rscript -e 'testthat::test_dir("tests/testthat", filter="dgp")'`.

---

## Task 1: Scaffolding, dependencies, test harness

**Files:**
- Create: `R/.gitkeep`, `www/.gitkeep`
- Create: `tests/testthat/helper-load.R`
- Create: `tests/testthat/test-smoke.R`

- [ ] **Step 1: Install the one missing dependency**

Run:
```bash
Rscript -e 'if (!requireNamespace("ivreg", quietly=TRUE)) install.packages("ivreg", repos="https://cloud.r-project.org")'
```
Expected: `ivreg` installs (or "already installed").

- [ ] **Step 2: Create directories and the test helper**

Create `R/.gitkeep` and `www/.gitkeep` (empty files).

Create `tests/testthat/helper-load.R`:
```r
# Sourced automatically by testthat::test_dir() before tests run.
# Loads all pure-logic functions from R/ (app.R is at the project root and is
# NOT sourced here).
r_files <- list.files(file.path("..", "..", "R"), pattern = "[.][Rr]$", full.names = TRUE)
invisible(lapply(r_files, source))
```

- [ ] **Step 3: Write a smoke test**

Create `tests/testthat/test-smoke.R`:
```r
test_that("test harness runs", {
  expect_true(TRUE)
})
```

- [ ] **Step 4: Run the suite to confirm the harness works**

Run: `Rscript -e 'testthat::test_dir("tests/testthat")'`
Expected: 1 passing test, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add R/.gitkeep www/.gitkeep tests/testthat/helper-load.R tests/testthat/test-smoke.R
git commit -m "chore: scaffold Shiny app dirs and testthat harness"
```

---

## Task 2: Brand palette and themes

**Files:**
- Create: `R/theme.R`
- Test: `tests/testthat/test-theme.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-theme.R`:
```r
test_that("palette and estimator colors are valid hex", {
  expect_type(HEADWATER, "list")
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", unlist(HEADWATER))))
  expect_setequal(
    names(ESTIMATOR_COLORS),
    c("Proximal (P2SLS)", "Standard, full", "Standard, minimal", "Oracle", "Crude")
  )
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", ESTIMATOR_COLORS)))
})

test_that("bslib theme builds", {
  expect_s3_class(headwater_bs_theme(), "bs_theme")
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="theme")'`
Expected: FAIL ("object 'HEADWATER' not found").

- [ ] **Step 3: Implement `R/theme.R`**

```r
# Headwater Science brand palette
HEADWATER <- list(
  pedestal = "#73F0E9", aqua = "#0FB5D2", ocean = "#0888A8",
  azure = "#4166FF", navy = "#140298", pearl = "#F0F0F0",
  silver = "#ADADAD", graphite = "#575757",
  orange = "#FD8524", crimson = "#A5052D", forest = "#495102"
)

# One color per estimator, reused across plots and the metrics table.
ESTIMATOR_COLORS <- c(
  "Proximal (P2SLS)"  = HEADWATER$navy,
  "Standard, full"    = HEADWATER$crimson,
  "Standard, minimal" = HEADWATER$orange,
  "Oracle"            = HEADWATER$forest,
  "Crude"             = HEADWATER$silver
)

# DAG edge colors by semantic type.
EDGE_COLORS <- c(
  structural = HEADWATER$ocean,
  ace        = HEADWATER$navy,
  residual   = HEADWATER$orange,
  invalid    = HEADWATER$crimson
)

# bslib Bootstrap 5 theme. Fonts are handled in www/custom.css to avoid a
# network dependency on Google Fonts.
headwater_bs_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = HEADWATER$ocean,
    secondary = HEADWATER$navy
  )
}

# Shared ggplot theme.
headwater_ggtheme <- function() {
  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", color = HEADWATER$graphite),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="theme")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/theme.R tests/testthat/test-theme.R
git commit -m "feat: add Headwater palette and bslib/ggplot themes"
```

---

## Task 3: Data-generating process

**Files:**
- Create: `R/dgp.R`
- Test: `tests/testthat/test-dgp.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-dgp.R`:
```r
test_that("default_params has all required fields", {
  p <- default_params()
  for (k in c("tau","gamma_z","gamma_w","delta","lambda","alpha_z","beta_w",
              "alpha_x","beta_x","a_xu","alpha0","sd_u","sd_z","sd_w","sd_y")) {
    expect_true(k %in% names(p), info = k)
  }
})

test_that("simulate_data returns correct shape and types", {
  set.seed(1)
  d <- simulate_data(500, default_params())
  expect_equal(nrow(d), 500)
  expect_setequal(names(d), c("X","U","Z","W","A","Y"))
  expect_true(all(d$A %in% c(0, 1)))
  expect_type(d$Y, "double")
})

test_that("simulate_data is reproducible under a fixed seed", {
  set.seed(7); d1 <- simulate_data(100, default_params())
  set.seed(7); d2 <- simulate_data(100, default_params())
  expect_identical(d1, d2)
})

test_that("stronger treatment-proxy strength increases cor(Z, U)", {
  set.seed(3)
  weak <- simulate_data(5000, modifyList(default_params(), list(gamma_z = 0.2)))
  strong <- simulate_data(5000, modifyList(default_params(), list(gamma_z = 3)))
  expect_lt(cor(weak$Z, weak$U), cor(strong$Z, strong$U))
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="dgp")'`
Expected: FAIL ("could not find function 'default_params'").

- [ ] **Step 3: Implement `R/dgp.R`**

```r
# Default parameter set. The app opens on "residual confounding" (delta = 1,
# lambda = 0) so the proximal advantage is visible immediately.
default_params <- function() {
  list(
    tau = 1.0,
    gamma_z = 1.0, gamma_w = 1.0,
    delta = 1.0, lambda = 0.0,
    alpha_z = 1.0, beta_w = 1.0,
    alpha_x = 0.5, beta_x = 0.5,
    a_xu = 1.0, alpha0 = 0.0,
    sd_u = 1.0, sd_z = 1.0, sd_w = 1.0, sd_y = 1.0
  )
}

# Simulate one dataset of n i.i.d. units from the proximal-CI DGP.
simulate_data <- function(n, params) {
  p <- params
  X <- rnorm(n, 0, 1)
  U <- p$a_xu * X + rnorm(n, 0, p$sd_u)
  Z <- p$gamma_z * U + rnorm(n, 0, p$sd_z)
  W <- p$gamma_w * U + rnorm(n, 0, p$sd_w)
  eta <- p$alpha0 + p$alpha_z * Z + p$alpha_x * X + p$delta * U
  A <- rbinom(n, 1, plogis(eta))
  Y <- p$tau * A + p$beta_w * W + p$beta_x * X + p$delta * U +
    p$lambda * Z + rnorm(n, 0, p$sd_y)
  data.frame(X = X, U = U, Z = Z, W = W, A = A, Y = Y)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="dgp")'`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add R/dgp.R tests/testthat/test-dgp.R
git commit -m "feat: add data-generating process"
```

---

## Task 4: Estimators

**Files:**
- Create: `R/estimators.R`
- Test: `tests/testthat/test-estimators.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-estimators.R`:
```r
test_that("fit_all returns five estimators with finite estimate and se", {
  set.seed(1)
  d <- simulate_data(2000, default_params())
  fa <- fit_all(d)
  expect_equal(nrow(fa), 5)
  expect_setequal(fa$estimator,
    c("Proximal (P2SLS)", "Standard, full", "Standard, minimal", "Oracle", "Crude"))
  expect_true(all(is.finite(fa$estimate)))
  expect_true(all(is.finite(fa$se) & fa$se > 0))
})

test_that("oracle recovers tau at large n", {
  set.seed(2)
  p <- modifyList(default_params(), list(tau = 1.3, delta = 1, lambda = 1))
  d <- simulate_data(2e5, p)
  fa <- fit_all(d)
  oracle <- fa$estimate[fa$estimator == "Oracle"]
  expect_lt(abs(oracle - p$tau), 0.03)
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="estimators")'`
Expected: FAIL ("could not find function 'fit_all'").

- [ ] **Step 3: Implement `R/estimators.R`**

```r
# Extract the coefficient and standard error for one term from a fitted model.
.coef_se <- function(model, term) {
  co <- summary(model)$coefficients
  c(estimate = unname(co[term, "Estimate"]),
    se = unname(co[term, "Std. Error"]))
}

fit_crude <- function(data) .coef_se(lm(Y ~ A, data = data), "A")
fit_standard_minimal <- function(data) .coef_se(lm(Y ~ A + X + W, data = data), "A")
fit_standard_full <- function(data) .coef_se(lm(Y ~ A + X + Z + W, data = data), "A")
fit_oracle <- function(data) .coef_se(lm(Y ~ A + X + Z + W + U, data = data), "A")

# Proximal g-computation as two-stage least squares: W is the endogenous
# regressor instrumented by the treatment proxy Z; A and X are exogenous.
# Z is excluded from the structural (outcome) equation -- that exclusion is the
# proxy-validity assumption.
fit_proximal <- function(data) .coef_se(ivreg::ivreg(Y ~ A + X + W | A + X + Z, data = data), "A")

fit_all <- function(data) {
  fits <- list(
    "Proximal (P2SLS)"  = fit_proximal(data),
    "Standard, full"    = fit_standard_full(data),
    "Standard, minimal" = fit_standard_minimal(data),
    "Oracle"            = fit_oracle(data),
    "Crude"             = fit_crude(data)
  )
  tibble::tibble(
    estimator = names(fits),
    estimate = vapply(fits, `[[`, numeric(1), "estimate"),
    se = vapply(fits, `[[`, numeric(1), "se")
  )
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="estimators")'`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add R/estimators.R tests/testthat/test-estimators.R
git commit -m "feat: add five estimators incl. proximal P2SLS"
```

---

## Task 5: Performance metrics

**Files:**
- Create: `R/metrics.R`
- Test: `tests/testthat/test-metrics.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-metrics.R`:
```r
test_that("summarise_estimates computes bias/ESE/RMSE/coverage correctly", {
  estimates <- tibble::tibble(
    estimator = rep("Crude", 4),
    estimate  = c(2, 4, 2, 4),   # mean 3
    se        = c(1, 1, 1, 1)
  )
  m <- summarise_estimates(estimates, truth = 2)  # bias = 1
  expect_equal(m$bias, 1)
  expect_equal(m$ese, sd(c(2,4,2,4)))
  expect_equal(m$rmse, sqrt(1^2 + sd(c(2,4,2,4))^2))
  # 95% CI half-width = 1.96; covers 2 when estimate in [0.04, 3.96] -> the 2's do, the 4's don't
  expect_equal(m$coverage, 0.5)
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="metrics")'`
Expected: FAIL ("could not find function 'summarise_estimates'").

- [ ] **Step 3: Implement `R/metrics.R`**

```r
# Summarize per-replicate estimates into performance metrics, by estimator.
# `estimates` has columns estimator, estimate, se (one row per rep x estimator).
summarise_estimates <- function(estimates, truth, level = 0.95) {
  z <- stats::qnorm(1 - (1 - level) / 2)
  dplyr::summarise(
    dplyr::group_by(estimates, estimator),
    bias = mean(estimate) - truth,
    ese = stats::sd(estimate),
    mean_se = mean(se),
    ser = mean(se) / stats::sd(estimate),
    rmse = sqrt((mean(estimate) - truth)^2 + stats::sd(estimate)^2),
    coverage = mean(abs(estimate - truth) <= z * se),
    .groups = "drop"
  )
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="metrics")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/metrics.R tests/testthat/test-metrics.R
git commit -m "feat: add performance-metric summaries"
```

---

## Task 6: Monte Carlo runner

**Files:**
- Create: `R/simulation.R` (adds `run_monte_carlo`; `run_sweep` added in Task 8)
- Test: `tests/testthat/test-simulation.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-simulation.R`:
```r
test_that("run_monte_carlo returns estimates, metrics, and truth", {
  res <- run_monte_carlo(default_params(), n = 300, M = 30, seed = 1)
  expect_setequal(names(res), c("estimates", "metrics", "truth"))
  expect_equal(res$truth, default_params()$tau)
  expect_equal(nrow(res$metrics), 5)
  expect_equal(nrow(res$estimates), 5 * 30)
  expect_true(all(c("bias","ese","ser","rmse","coverage") %in% names(res$metrics)))
})

test_that("run_monte_carlo is reproducible under a seed", {
  a <- run_monte_carlo(default_params(), n = 200, M = 20, seed = 5)
  b <- run_monte_carlo(default_params(), n = 200, M = 20, seed = 5)
  expect_equal(a$metrics, b$metrics)
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="simulation")'`
Expected: FAIL ("could not find function 'run_monte_carlo'").

- [ ] **Step 3: Implement `run_monte_carlo` in `R/simulation.R`**

```r
# Run M Monte Carlo replicates at sample size n for a fixed parameter set.
run_monte_carlo <- function(params, n, M, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  reps <- lapply(seq_len(M), function(i) {
    fa <- fit_all(simulate_data(n, params))
    fa$rep <- i
    fa
  })
  estimates <- dplyr::bind_rows(reps)
  list(
    estimates = estimates,
    metrics = summarise_estimates(estimates, truth = params$tau),
    truth = params$tau
  )
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="simulation")'`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add R/simulation.R tests/testthat/test-simulation.R
git commit -m "feat: add Monte Carlo runner"
```

---

## Task 7: Presets and preset-behavior regression tests

These are the scientific validation tests: they assert that each estimator behaves as the proximal-CI literature predicts. Run on a single large-n draw so they are fast and near-deterministic.

**Files:**
- Create: `R/presets.R`
- Test: `tests/testthat/test-presets.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-presets.R`:
```r
.est <- function(p, n = 2e5) {
  d <- simulate_data(n, p)
  fa <- fit_all(d)
  stats::setNames(fa$estimate, fa$estimator)
}

test_that("presets() exposes the four named scenarios", {
  expect_setequal(
    names(presets()),
    c("Valid proxies", "Residual confounding", "Invalid proxy", "Weak proxies")
  )
})

test_that("valid proxies: proximal/standard/oracle all unbiased, crude biased", {
  set.seed(11)
  p <- presets()[["Valid proxies"]]
  e <- .est(p)
  for (nm in c("Proximal (P2SLS)", "Standard, full", "Standard, minimal", "Oracle")) {
    expect_lt(abs(e[[nm]] - p$tau), 0.05)
  }
  expect_gt(abs(e[["Crude"]] - p$tau), 0.10)
})

test_that("residual confounding: standard biased, proximal & oracle unbiased", {
  set.seed(12)
  p <- presets()[["Residual confounding"]]
  e <- .est(p)
  expect_lt(abs(e[["Proximal (P2SLS)"]] - p$tau), 0.05)
  expect_lt(abs(e[["Oracle"]] - p$tau), 0.05)
  expect_gt(abs(e[["Standard, full"]] - p$tau), 0.15)
  expect_gt(abs(e[["Standard, minimal"]] - p$tau), 0.15)
})

test_that("invalid proxy: proximal biased, oracle still unbiased", {
  set.seed(13)
  p <- presets()[["Invalid proxy"]]
  e <- .est(p)
  expect_gt(abs(e[["Proximal (P2SLS)"]] - p$tau), 0.15)
  expect_lt(abs(e[["Oracle"]] - p$tau), 0.05)
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="presets")'`
Expected: FAIL ("could not find function 'presets'").

- [ ] **Step 3: Implement `R/presets.R`**

```r
# Named parameter sets for the scenario buttons. Each starts from defaults and
# overrides the "story" knobs.
presets <- function() {
  base <- default_params()
  list(
    "Valid proxies"        = modifyList(base, list(delta = 0, lambda = 0)),
    "Residual confounding" = modifyList(base, list(delta = 1, lambda = 0)),
    "Invalid proxy"        = modifyList(base, list(delta = 1, lambda = 1)),
    "Weak proxies"         = modifyList(base, list(gamma_z = 0.3, gamma_w = 0.3,
                                                   delta = 1, lambda = 0))
  )
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="presets")'`
Expected: PASS (4 tests). If a magnitude assertion is borderline, the DGP is still correct — widen the tolerance slightly (e.g., 0.15 -> 0.12) rather than changing the DGP.

- [ ] **Step 5: Commit**

```bash
git add R/presets.R tests/testthat/test-presets.R
git commit -m "feat: add presets and literature-behavior regression tests"
```

---

## Task 8: Sweep runner

**Files:**
- Modify: `R/simulation.R` (add `run_sweep`)
- Test: `tests/testthat/test-sweep.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-sweep.R`:
```r
test_that("run_sweep returns one row per (grid value x estimator)", {
  vals <- c(0, 1, 2)
  s <- run_sweep(default_params(), "delta", vals, n = 300, M_sweep = 20, seed = 1)
  expect_equal(nrow(s), length(vals) * 5)
  expect_true(all(c("value","estimator","bias","ese","rmse","coverage") %in% names(s)))
  expect_setequal(unique(s$value), vals)
})

test_that("standard estimator's |bias| grows with delta", {
  vals <- c(0, 1, 2)
  s <- run_sweep(default_params(), "delta", vals, n = 4000, M_sweep = 40, seed = 2)
  b <- s[s$estimator == "Standard, minimal", ]
  b <- b[order(b$value), ]
  expect_true(abs(b$bias[3]) > abs(b$bias[1]))
})

test_that("sweeping n changes sample size, not a parameter", {
  s <- run_sweep(default_params(), "n", c(200, 400), n = 999, M_sweep = 15, seed = 3)
  expect_setequal(unique(s$value), c(200, 400))
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="sweep")'`
Expected: FAIL ("could not find function 'run_sweep'").

- [ ] **Step 3: Add `run_sweep` to `R/simulation.R`**

```r
# Vary one association (or n) across a grid of values, holding all else at
# `params`, and return the metrics at each grid point. When sweep_var == "n",
# the grid values set the sample size; otherwise they set params[[sweep_var]].
run_sweep <- function(params, sweep_var, values, n, M_sweep, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  rows <- lapply(values, function(v) {
    p <- params
    nn <- n
    if (sweep_var == "n") nn <- v else p[[sweep_var]] <- v
    m <- run_monte_carlo(p, n = nn, M = M_sweep)$metrics
    m$value <- v
    m
  })
  dplyr::bind_rows(rows)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="sweep")'`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add R/simulation.R tests/testthat/test-sweep.R
git commit -m "feat: add parameter sweep runner"
```

---

## Task 9: DAG rendering

The DAG is a pure function of `params`; the test is a smoke test (returns a ggplot, no error for default and extreme params). Visual tuning is done by eye when the app runs (Task 12).

**Files:**
- Create: `R/dag.R`
- Test: `tests/testthat/test-dag.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-dag.R`:
```r
test_that("render_dag returns a ggplot for default and extreme params", {
  expect_s3_class(render_dag(default_params()), "ggplot")
  extreme <- modifyList(default_params(),
    list(tau = -3, gamma_z = 0, gamma_w = 3, delta = 3, lambda = 3))
  expect_s3_class(render_dag(extreme), "ggplot")
})

test_that("render_dag can be built without error", {
  p <- render_dag(default_params())
  expect_silent(ggplot2::ggplot_build(p))
})
```

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="dag")'`
Expected: FAIL ("could not find function 'render_dag'").

- [ ] **Step 3: Implement `R/dag.R`**

```r
# Render the proximal-CI DAG as a ggplot. Edge linewidth is proportional to
# |coefficient|; color encodes edge type; residual/invalid edges are dashed.
render_dag <- function(params) {
  nodes <- data.frame(
    name = c("U", "X", "Z", "W", "A", "Y"),
    x    = c(4.0, 4.0, 1.2, 6.8, 1.6, 6.4),
    y    = c(5.0, 3.3, 2.2, 2.2, 0.5, 0.5),
    latent = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )
  e <- function(from, to, param, type) data.frame(from, to, param, type, stringsAsFactors = FALSE)
  edges <- rbind(
    e("X", "U", "a_xu", "structural"),
    e("X", "A", "alpha_x", "structural"),
    e("X", "Y", "beta_x", "structural"),
    e("U", "Z", "gamma_z", "structural"),
    e("U", "W", "gamma_w", "structural"),
    e("Z", "A", "alpha_z", "structural"),
    e("W", "Y", "beta_w", "structural"),
    e("U", "A", "delta", "residual"),
    e("U", "Y", "delta", "residual"),
    e("Z", "Y", "lambda", "invalid"),
    e("A", "Y", "tau", "ace")
  )
  edges$coef <- vapply(edges$param, function(p) params[[p]], numeric(1))
  edges$x    <- nodes$x[match(edges$from, nodes$name)]
  edges$y    <- nodes$y[match(edges$from, nodes$name)]
  edges$xend <- nodes$x[match(edges$to, nodes$name)]
  edges$yend <- nodes$y[match(edges$to, nodes$name)]

  # Trim endpoints so arrowheads sit on the node boundary, not the center.
  r <- 0.34
  d <- sqrt((edges$xend - edges$x)^2 + (edges$yend - edges$y)^2)
  ux <- (edges$xend - edges$x) / d
  uy <- (edges$yend - edges$y) / d
  edges$x <- edges$x + r * ux; edges$y <- edges$y + r * uy
  edges$xend <- edges$xend - r * ux; edges$yend <- edges$yend - r * uy

  edges$lw  <- 0.4 + 1.8 * pmin(abs(edges$coef), 3) / 3
  edges$lty <- ifelse(edges$type %in% c("residual", "invalid"), "dashed", "solid")
  edges$col <- EDGE_COLORS[edges$type]
  edges$mx  <- (edges$x + edges$xend) / 2
  edges$my  <- (edges$y + edges$yend) / 2

  nodes$fill   <- ifelse(nodes$latent, "#F2F2F2", "#D8F3F9")
  nodes$stroke <- ifelse(nodes$latent, HEADWATER$graphite, HEADWATER$ocean)

  ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      arrow = ggplot2::arrow(length = grid::unit(0.18, "cm"), type = "closed"),
      linewidth = edges$lw, colour = edges$col, linetype = edges$lty
    ) +
    ggplot2::geom_text(
      data = edges, ggplot2::aes(x = mx, y = my, label = sprintf("%.2g", coef)),
      colour = edges$col, fontface = "bold", size = 3.1, vjust = -0.4
    ) +
    ggplot2::geom_point(
      data = nodes, ggplot2::aes(x = x, y = y),
      size = 17, shape = 21, fill = nodes$fill, colour = nodes$stroke, stroke = 1.3
    ) +
    ggplot2::geom_text(
      data = nodes, ggplot2::aes(x = x, y = y, label = name),
      fontface = "bold", size = 5, colour = HEADWATER$graphite
    ) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::scale_x_continuous(limits = c(0.2, 7.8), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(-0.2, 5.6), expand = c(0, 0)) +
    ggplot2::theme_void()
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="dag")'`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add R/dag.R tests/testthat/test-dag.R
git commit -m "feat: add parameter-driven DAG rendering"
```

---

## Task 10: Result plots

**Files:**
- Create: `R/plots.R`
- Test: `tests/testthat/test-plots.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-plots.R`:
```r
test_that("plot_snapshot returns a ggplot", {
  mc <- run_monte_carlo(default_params(), n = 200, M = 30, seed = 1)
  expect_s3_class(plot_snapshot(mc), "ggplot")
})

test_that("plot_sweep returns a patchwork/ggplot for both metric choices", {
  s <- run_sweep(default_params(), "delta", c(0, 1, 2), n = 200, M_sweep = 15, seed = 1)
  expect_s3_class(plot_sweep(s, "delta", metric = "ese"), "ggplot")
  expect_s3_class(plot_sweep(s, "delta", metric = "rmse"), "ggplot")
})
```
Note: a patchwork object also inherits from `"ggplot"`, so the `expect_s3_class(..., "ggplot")` check holds for the sweep plot.

- [ ] **Step 2: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="plots")'`
Expected: FAIL ("could not find function 'plot_snapshot'").

- [ ] **Step 3: Implement `R/plots.R`**

```r
# Overlaid sampling distributions of the per-replicate estimates, one curve per
# estimator, with a dashed line at the true effect.
plot_snapshot <- function(mc) {
  est <- mc$estimates
  est$estimator <- factor(est$estimator, levels = names(ESTIMATOR_COLORS))
  ggplot2::ggplot(est, ggplot2::aes(x = estimate, colour = estimator, fill = estimator)) +
    ggplot2::geom_density(alpha = 0.12, linewidth = 0.9) +
    ggplot2::geom_vline(xintercept = mc$truth, linetype = "dashed",
                        colour = HEADWATER$graphite) +
    ggplot2::annotate("text", x = mc$truth, y = Inf, label = "true τ",
                      vjust = 1.4, hjust = -0.1, colour = HEADWATER$graphite, size = 3.6) +
    ggplot2::scale_colour_manual(values = ESTIMATOR_COLORS, drop = FALSE) +
    ggplot2::scale_fill_manual(values = ESTIMATOR_COLORS, drop = FALSE) +
    ggplot2::labs(x = "estimated ACE", y = "density") +
    headwater_ggtheme()
}

# Two stacked panels: bias vs the swept value, and ESE (or RMSE) vs the swept
# value. One line per estimator.
plot_sweep <- function(sweep_df, sweep_var, metric = c("ese", "rmse")) {
  metric <- match.arg(metric)
  sweep_df$estimator <- factor(sweep_df$estimator, levels = names(ESTIMATOR_COLORS))
  common <- list(
    ggplot2::geom_line(linewidth = 1),
    ggplot2::geom_point(size = 1.6),
    ggplot2::scale_colour_manual(values = ESTIMATOR_COLORS, drop = FALSE),
    headwater_ggtheme()
  )
  p_bias <- ggplot2::ggplot(sweep_df, ggplot2::aes(value, bias, colour = estimator)) +
    ggplot2::geom_hline(yintercept = 0, colour = HEADWATER$silver) +
    common + ggplot2::labs(x = NULL, y = "Bias")
  p_var <- ggplot2::ggplot(sweep_df, ggplot2::aes(value, .data[[metric]], colour = estimator)) +
    common + ggplot2::labs(x = sweep_var, y = toupper(metric))
  patchwork::wrap_plots(p_bias, p_var, ncol = 1, guides = "collect") &
    ggplot2::theme(legend.position = "bottom")
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="plots")'`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add R/plots.R tests/testthat/test-plots.R
git commit -m "feat: add snapshot and sweep result plots"
```

---

## Task 11: Static assets — logo, CSS, About copy, UI text

**Files:**
- Create: `www/headwater-logo.png` (extracted from the root PDF)
- Create: `www/custom.css`
- Create: `www/about.md`
- Create: `R/ui_text.R`
- Test: `tests/testthat/test-ui-text.R`

- [ ] **Step 1: Extract the logo to PNG**

Run:
```bash
sips -s format png --out www/headwater-logo.png "Headwater Science - RGB Color.pdf"
```
Expected: `www/headwater-logo.png` created. Confirm with `ls -la www/headwater-logo.png`.

- [ ] **Step 2: Write `www/custom.css`**

```css
h1, h2, h3, h4, h5, .headwater-title, .nav-link {
  font-family: Georgia, "Times New Roman", serif;
}
.headwater-header {
  display: flex; align-items: center; gap: 14px;
  border-bottom: 3px solid #0888A8;
  padding-bottom: 10px; margin-bottom: 16px;
}
.headwater-header img { height: 46px; }
.headwater-title { color: #140298; margin: 0; }
.dag-legend { font-size: 12px; color: #575757; margin: 4px 0 10px; }
.dag-legend span { margin-right: 16px; white-space: nowrap; }
.dag-legend i { display: inline-block; width: 20px; height: 3px;
  vertical-align: middle; margin-right: 5px; }
.btn-outline-primary { --bs-btn-color: #0888A8; --bs-btn-border-color: #0888A8; }
```

- [ ] **Step 3: Write `www/about.md`**

```markdown
## What this app does

This is a simulation sandbox for **proximal causal inference**. You set the
strengths of the associations in the data-generating process below (shown as a
DAG), and the app shows how the **bias** and **variance** of a proximal
estimator compare with standard adjustment, an infeasible oracle, and a crude
estimator.

### The variables

- **A** — binary treatment, **Y** — continuous outcome. The true average causal
  effect (ACE) of A on Y is the slider **&tau;**.
- **U** — an *unmeasured* confounder of A and Y.
- **X** — a measured confounder.
- **Z** — a *treatment confounding proxy* (negative-control exposure): a
  correlate of treatment whose only link to Y (when valid) runs through U.
- **W** — an *outcome confounding proxy* (negative-control outcome): a correlate
  of the outcome whose only link to A runs through U.

### The story knobs

- **&delta;** raises the *residual* confounding U exerts directly on A and Y
  (beyond what the proxies capture). This is what breaks ordinary covariate
  adjustment and what proximal inference is designed to handle.
- **&lambda;** makes the treatment proxy Z *invalid* by letting it affect Y
  directly. This breaks the proximal estimator too.

### How to read the results

Use **Snapshot** to see, at the current settings, the sampling distribution and
bias/variance of each estimator. Use **Sweep** to vary one association across a
range and watch the bias and variance curves move. The **Methods** tab gives the
estimating equations.

*Method references: Miao, Geng & Tchetgen Tchetgen (2018); Tchetgen Tchetgen et
al. (2024); Zivich et al. (2023).*
```

- [ ] **Step 4: Write the failing test for UI text helpers**

Create `tests/testthat/test-ui-text.R`:
```r
test_that("ui text helpers return non-empty character strings", {
  expect_type(dag_legend_html(), "character")
  expect_true(nchar(dag_legend_html()) > 0)
  expect_type(methods_html(), "character")
  expect_match(methods_html(), "ivreg|bridge|proximal", ignore.case = TRUE)
})
```

- [ ] **Step 5: Run to verify it fails**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="ui-text")'`
Expected: FAIL ("could not find function 'dag_legend_html'").

- [ ] **Step 6: Implement `R/ui_text.R`**

```r
# Small static HTML strings used by the UI. Kept out of app.R so they are
# testable and the app file stays focused on wiring.

dag_legend_html <- function() {
  paste0(
    "<div class='dag-legend'>",
    "<span><i style='background:", HEADWATER$navy, "'></i>&tau; — true effect A&rarr;Y</span>",
    "<span><i style='background:", HEADWATER$ocean, "'></i>structural paths</span>",
    "<span><i style='background:", HEADWATER$orange, "'></i>&delta; — residual confounding (breaks standard adjustment)</span>",
    "<span><i style='background:", HEADWATER$crimson, "'></i>&lambda; — proxy invalidity (breaks proximal)</span>",
    "</div>"
  )
}

methods_html <- function() {
  paste0(
    "<h4>Proximal g-computation (P2SLS)</h4>",
    "<p>With a linear outcome bridge function ",
    "\\( h(W,A,X) = \\beta_0 + \\tau A + \\eta_w W + \\eta_x X \\), ",
    "parametric proximal g-computation is two-stage least squares with the ",
    "treatment proxy \\(Z\\) as the instrument for \\(W\\):</p>",
    "<p><b>Stage 1:</b> regress \\(W\\) on \\((1, A, X, Z)\\) to obtain \\(\\hat W\\).<br>",
    "<b>Stage 2:</b> regress \\(Y\\) on \\((1, A, X, \\hat W)\\); the coefficient on \\(A\\) estimates \\(\\tau\\).</p>",
    "<p>In R this is <code>ivreg(Y ~ A + X + W | A + X + Z)</code>. The exclusion of ",
    "\\(Z\\) from the stage-2 equation is the proxy-validity assumption, violated when \\(\\lambda \\ne 0\\).</p>",
    "<h4>Comparators</h4>",
    "<p><b>Standard, full</b> \\( = \\) OLS of \\(Y\\) on \\(A, X, Z, W\\); ",
    "<b>Standard, minimal</b> \\( = \\) OLS on \\(A, X, W\\); ",
    "<b>Oracle</b> \\( = \\) OLS on \\(A, X, Z, W, U\\) (the correctly specified model, ",
    "infeasible because \\(U\\) is unmeasured); <b>Crude</b> \\( = \\) OLS on \\(A\\) alone.</p>",
    "<h4>Data-generating process</h4>",
    "<p>\\( U = a_{xu}X + \\varepsilon_U,\\; Z = \\gamma_z U + \\varepsilon_Z,\\; W = \\gamma_w U + \\varepsilon_W \\)<br>",
    "\\( \\Pr(A=1) = \\mathrm{logit}^{-1}(\\alpha_0 + \\alpha_z Z + \\alpha_x X + \\delta U) \\)<br>",
    "\\( Y = \\tau A + \\beta_w W + \\beta_x X + \\delta U + \\lambda Z + \\varepsilon_Y \\)</p>"
  )
}
```

- [ ] **Step 7: Run to verify it passes**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="ui-text")'`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add www/headwater-logo.png www/custom.css www/about.md R/ui_text.R tests/testthat/test-ui-text.R
git commit -m "feat: add logo, CSS, About copy, and UI text helpers"
```

---

## Task 12: Shiny app (UI + server)

**Files:**
- Create: `app.R`
- Test: `tests/testthat/test-app.R`

- [ ] **Step 1: Implement `app.R`**

```r
library(shiny)
library(bslib)

# Pure-logic functions in R/*.R are auto-sourced by Shiny at runtime.

PARAM_LABELS <- c(
  tau     = "τ — true effect (A→Y)",
  gamma_z = "γz — treatment-proxy strength (U→Z)",
  gamma_w = "γw — outcome-proxy strength (U→W)",
  delta   = "δ — residual confounding (U→A, U→Y)",
  lambda  = "λ — proxy invalidity (Z→Y)",
  alpha_z = "αz — Z→A",
  beta_w  = "βw — W→Y",
  alpha_x = "αx — X→A",
  beta_x  = "βx — X→Y",
  a_xu    = "a_xu — X→U"
)

sidebar_controls <- function() {
  dp <- default_params()
  tagList(
    tags$div(class = "fw-bold mb-1", "Presets"),
    tags$div(
      class = "d-flex flex-wrap gap-1 mb-3",
      lapply(names(presets()), function(nm)
        actionButton(paste0("preset_", make.names(nm)), nm,
                     class = "btn btn-sm btn-outline-primary"))
    ),
    tags$h6("Primary controls"),
    sliderInput("tau", PARAM_LABELS[["tau"]], -3, 3, dp$tau, step = 0.1),
    sliderInput("gamma_z", PARAM_LABELS[["gamma_z"]], 0, 3, dp$gamma_z, step = 0.1),
    sliderInput("gamma_w", PARAM_LABELS[["gamma_w"]], 0, 3, dp$gamma_w, step = 0.1),
    sliderInput("delta", PARAM_LABELS[["delta"]], 0, 3, dp$delta, step = 0.1),
    sliderInput("lambda", PARAM_LABELS[["lambda"]], 0, 3, dp$lambda, step = 0.1),
    tags$details(
      tags$summary("Advanced (structural edges, sample size)"),
      sliderInput("alpha_z", PARAM_LABELS[["alpha_z"]], 0, 3, dp$alpha_z, step = 0.1),
      sliderInput("beta_w", PARAM_LABELS[["beta_w"]], 0, 3, dp$beta_w, step = 0.1),
      sliderInput("alpha_x", PARAM_LABELS[["alpha_x"]], -2, 2, dp$alpha_x, step = 0.1),
      sliderInput("beta_x", PARAM_LABELS[["beta_x"]], -2, 2, dp$beta_x, step = 0.1),
      sliderInput("a_xu", PARAM_LABELS[["a_xu"]], 0, 3, dp$a_xu, step = 0.1),
      sliderInput("n", "sample size n", 100, 5000, 500, step = 50),
      sliderInput("M", "Monte Carlo reps (Snapshot)", 200, 5000, 1000, step = 100)
    ),
    actionButton("run", "Run simulation", class = "btn btn-primary w-100 mt-2")
  )
}

ui <- page_fluid(
  theme = headwater_bs_theme(),
  tags$head(tags$link(rel = "stylesheet", href = "custom.css")),
  tags$div(
    class = "headwater-header",
    tags$img(src = "headwater-logo.png", alt = "Headwater Science"),
    tags$h2(class = "headwater-title", "Proximal Causal Inference Explorer")
  ),
  layout_sidebar(
    sidebar = sidebar(width = 350, sidebar_controls()),
    navset_tab(
      nav_panel("About", uiOutput("about")),
      nav_panel(
        "Snapshot",
        plotOutput("dag", height = "320px"),
        uiOutput("dag_legend"),
        plotOutput("snapshot_plot", height = "300px"),
        DT::DTOutput("metrics_table")
      ),
      nav_panel(
        "Sweep",
        layout_columns(
          col_widths = c(4, 2, 2, 2, 2),
          selectInput("sweep_var", "Sweep which association?",
                      choices = stats::setNames(names(PARAM_LABELS), PARAM_LABELS),
                      selected = "delta"),
          numericInput("sweep_min", "min", value = 0, step = 0.1),
          numericInput("sweep_max", "max", value = 3, step = 0.1),
          numericInput("sweep_k", "grid points", value = 13, min = 3, max = 40),
          radioButtons("sweep_metric", "2nd panel", c("ESE" = "ese", "RMSE" = "rmse"))
        ),
        actionButton("run_sweep", "Run sweep", class = "btn btn-primary mb-3"),
        plotOutput("sweep_plot", height = "470px")
      ),
      nav_panel("Methods & formulas", withMathJax(uiOutput("methods")))
    )
  )
)

server <- function(input, output, session) {
  params <- reactive({
    list(
      tau = input$tau, gamma_z = input$gamma_z, gamma_w = input$gamma_w,
      delta = input$delta, lambda = input$lambda, alpha_z = input$alpha_z,
      beta_w = input$beta_w, alpha_x = input$alpha_x, beta_x = input$beta_x,
      a_xu = input$a_xu, alpha0 = 0, sd_u = 1, sd_z = 1, sd_w = 1, sd_y = 1
    )
  })

  # Preset buttons update the sliders.
  lapply(names(presets()), function(nm) {
    observeEvent(input[[paste0("preset_", make.names(nm))]], {
      p <- presets()[[nm]]
      for (k in names(PARAM_LABELS)) updateSliderInput(session, k, value = p[[k]])
    })
  })

  output$dag <- renderPlot(render_dag(params()))
  output$dag_legend <- renderUI(HTML(dag_legend_html()))

  mc <- eventReactive(input$run, {
    withProgress(message = "Running Monte Carlo simulation...", value = 0.5, {
      run_monte_carlo(params(), n = input$n, M = input$M, seed = 1)
    })
  })

  output$snapshot_plot <- renderPlot({ req(mc()); plot_snapshot(mc()) })

  output$metrics_table <- DT::renderDT({
    req(mc())
    m <- mc()$metrics
    m <- m[match(names(ESTIMATOR_COLORS), m$estimator), ]
    disp <- data.frame(
      Estimator = m$estimator,
      Bias = round(m$bias, 3),
      `Empirical SE` = round(m$ese, 3),
      `SE ratio` = round(m$ser, 2),
      RMSE = round(m$rmse, 3),
      Coverage = scales::percent(m$coverage, accuracy = 1),
      check.names = FALSE
    )
    DT::datatable(disp, rownames = FALSE,
                  options = list(dom = "t", ordering = FALSE, paging = FALSE))
  })

  sweep_res <- eventReactive(input$run_sweep, {
    grid <- seq(input$sweep_min, input$sweep_max, length.out = input$sweep_k)
    withProgress(message = "Running sweep...", value = 0.5, {
      run_sweep(params(), input$sweep_var, grid, n = input$n, M_sweep = 400, seed = 1)
    })
  })

  output$sweep_plot <- renderPlot({
    req(sweep_res())
    plot_sweep(sweep_res(), input$sweep_var, metric = input$sweep_metric)
  })

  output$about <- renderUI(includeMarkdown("www/about.md"))
  output$methods <- renderUI(HTML(methods_html()))
}

shinyApp(ui, server)
```

- [ ] **Step 2: Write a server smoke test**

Create `tests/testthat/test-app.R`:
```r
test_that("server assembles params and runs a small Monte Carlo", {
  # Source app.R to define `ui` and `server`. The trailing shinyApp() call just
  # returns an (unlaunched) app object.
  source(file.path("..", "..", "app.R"), local = TRUE)
  shiny::testServer(server, {
    session$setInputs(
      tau = 1, gamma_z = 1, gamma_w = 1, delta = 1, lambda = 0,
      alpha_z = 1, beta_w = 1, alpha_x = 0.5, beta_x = 0.5, a_xu = 1,
      n = 200, M = 20
    )
    expect_equal(params()$tau, 1)
    session$setInputs(run = 1)
    expect_equal(nrow(mc()$metrics), 5)
  })
})
```

- [ ] **Step 3: Run the server smoke test**

Run: `Rscript -e 'testthat::test_dir("tests/testthat", filter="app")'`
Expected: PASS. If `testServer` errors on `withProgress`, that indicates a real wiring issue — confirm `shiny` >= 1.6 and that `mc` is an `eventReactive`.

- [ ] **Step 4: Launch the app and verify manually**

Run: `Rscript -e 'shiny::runApp(".", launch.browser = TRUE)'`

Manual checklist:
- Header shows the Headwater logo + title; serif headings; aqua accent bar.
- DAG renders; dragging δ and λ changes the orange/crimson edge widths live.
- Preset buttons move the sliders.
- "Run simulation" shows a progress bar, then the density plot + metrics table.
  Under the default (δ=1, λ=0): proximal & oracle bias ≈ 0, standard biased.
- Sweep tab: choose δ, min 0, max 3, Run sweep → bias curve for standard rises,
  proximal stays flat; toggling ESE/RMSE switches the lower panel.
- Methods tab renders the equations via MathJax.

Tune `render_dag` node size / label positions if anything overlaps.

- [ ] **Step 5: Commit**

```bash
git add app.R tests/testthat/test-app.R
git commit -m "feat: assemble Shiny UI and server"
```

---

## Task 13: Deployment readiness

**Files:**
- Create: `README.md`
- Modify: `.gitignore`
- Create: `renv.lock` (via renv)

- [ ] **Step 1: Run the full test suite**

Run: `Rscript -e 'testthat::test_dir("tests/testthat")'`
Expected: all tests pass (smoke, theme, dgp, estimators, metrics, simulation, presets, sweep, dag, plots, ui-text, app).

- [ ] **Step 2: Ignore renv library, write README**

Add to `.gitignore`:
```
renv/library/
renv/staging/
```

Create `README.md`:
```markdown
# Proximal Causal Inference Explorer

A Shiny app to explore how the strengths of associations in a proximal
causal-inference data-generating process affect the bias and variance of the
proximal (P2SLS) estimator versus standard, oracle, and crude comparators.

## Run locally

```r
shiny::runApp(".")
```

## Test

```bash
Rscript -e 'testthat::test_dir("tests/testthat")'
```

## Deploy to shinyapps.io

```r
rsconnect::deployApp(appName = "ProximalCausalInference")
```

Files in `R/` are auto-sourced by Shiny. See
`docs/superpowers/specs/2026-05-27-proximal-ci-shiny-design.md` for the design
and `docs/superpowers/plans/2026-05-27-proximal-ci-shiny.md` for the build plan.
```

- [ ] **Step 3: Snapshot dependencies with renv**

Run:
```bash
Rscript -e 'renv::init(bare = TRUE); renv::snapshot(prompt = FALSE)'
```
Expected: `renv.lock` created listing shiny, bslib, ggplot2, patchwork, ivreg, dplyr, tidyr, tibble, DT, scales. If renv prompts or misbehaves in non-interactive mode, instead run `Rscript -e 'renv::snapshot(prompt = FALSE)'` after `renv::init()`. (renv is optional for local use but recommended for reproducible deploys.)

- [ ] **Step 4: Verify the app still launches under the renv library**

Run: `Rscript -e 'shiny::runApp(".", launch.browser = FALSE, port = 8123)'` and confirm it starts without missing-package errors (Ctrl-C to stop).

- [ ] **Step 5: Commit**

```bash
git add README.md .gitignore renv.lock renv/activate.R .Rprofile
git commit -m "chore: add README and renv lockfile for deployment"
```

---

## Self-Review Notes (completed by plan author)

- **Spec coverage:** DGP (Task 3), all five estimators incl. oracle rationale (Task 4), metrics incl. coverage/SER (Task 5), Snapshot MC (Task 6, 10, 12), Sweep (Task 8, 10, 12), presets with generic names (Task 7), live DAG with edge widths (Task 9, 12), Headwater branding + logo + StudySizePlanning-style sidebar/tabs incl. About and Methods/MathJax tabs (Tasks 2, 11, 12), shinyapps.io packaging (Task 13). Preset-behavior regression tests mirror Zivich et al. (Task 7).
- **Estimator name strings** are identical across `theme.R`, `estimators.R`, `plots.R`, and the table reorder in `app.R`.
- **Param field names** (`tau, gamma_z, gamma_w, delta, lambda, alpha_z, beta_w, alpha_x, beta_x, a_xu, alpha0, sd_*`) are consistent across `dgp.R`, `presets.R`, `dag.R`, `PARAM_LABELS`, and `params()`.
- **No placeholders:** every code/test/command step contains complete content.
- **Noise SDs** fixed at 1 (per spec §10), set in `params()` and `default_params()`.
