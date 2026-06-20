# ==============================================================================
# Script: R/ui_text.R
# Author: Alan Brookhart (alan.brookhart@duke.edu)
# Date: June 2026
# Version: 1.0.0
#
# Description:
#   Small static HTML strings used by the UI, kept out of app.R so they are
#   testable and the app file stays focused on wiring. Provides the DAG color
#   legend and the MathJax "Methods & formulas" content.
#
# Core Architecture:
#   - dag_legend_html(): the color key for the DAG; colors are kept in sync with
#     EDGE_COLORS / PALETTE in R/theme.R.
#   - methods_html(): the formula/methods write-up rendered with MathJax.
#
# Usage:
#   Sourced automatically by Shiny at runtime; not run directly.
# ==============================================================================

dag_legend_html <- function() {
  paste0(
    "<div class='dag-legend'>",
    "<span><i style='background:", PALETTE$navy, "'></i>&tau; — true effect A&rarr;Y</span>",
    "<span><i style='background:", PALETTE$steel, "'></i>structural paths</span>",
    "<span><i style='background:", PALETTE$gold, "'></i>&delta; — residual confounding (breaks standard adjustment)</span>",
    "<span><i style='background:", PALETTE$firebrick, "'></i>&lambda; — proxy invalidity (breaks proximal)</span>",
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
