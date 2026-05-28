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
