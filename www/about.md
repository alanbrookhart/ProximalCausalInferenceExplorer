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
