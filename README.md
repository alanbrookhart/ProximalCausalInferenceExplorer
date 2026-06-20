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

Files in `R/` are auto-sourced by Shiny. 
