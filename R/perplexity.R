# Perplexity Calculations. Used in creating the input probabilities in
# probability-based embedding.

# Summarize Parameter Search
#
# Provides summary of the distribution of the beta parameter used to
# generate input probabilities in SNE.
#
# Mainly useful for debugging. Also expresses beta as sigma, i.e. the
# Gaussian bandwidth \eqn{\frac{1}{\sqrt{2\beta}}}{1/sqrt(2*beta)}.
#
# @param betas Vector of parameters
summarize_betas <- function(betas) {
  summarize(prec_to_bandwidth(betas), "sigma")
  summarize(betas, "beta")
}

# Convert Precisions to Sigma (Bandwidths)
#
# Gaussian-type functions have a parameter associated with them
# that is either thought of as a "precision", i.e. how "tight" the distribution
# is, or its counterpart, the bandwidth, which measure how spread-out the
# distribution is. For gaussian functions, a direct comparison can be made
# with the standard deviation of the function. Exact definitions of the
# parameters differ in different discussions. In sneer, the gaussian function
# is defined as:
#
# \deqn{e(-\beta D^2)}{exp(-beta * D^2)}
#
# where \eqn{\beta}{beta} is the precision, or alternatively:
#
# \deqn{e^{-\frac{D^2}{2\sigma^2}}}{exp[-(D ^ 2)/(2 * sigma ^ 2)]}
#
# so that \eqn{\sigma = \frac{1}{\sqrt{2\beta}}}{sigma = 1/sqrt(2*beta)}
#
# This function performs the conversion of the parameter between precision and
# bandwidth.
#
# @param prec Precision (beta).
# @return Bandwidth (sigma).
prec_to_bandwidth <- function(prec) {
  1 / sqrt(2 * prec)
}

# Find Row Probabilities by Perplexity Bisection Search
#
# For each row, finds the value of beta which generates the probability
# with the desired perplexity.
#
# The intrinsic dimensionality is also calculated for each point. It is
# calculated as the derivative of the Shannon Entropy in bits with respect to
# the log2 of the beta parameter. The value reported is that of a finite
# difference estimate using the value of beta at the target perplexity and the
# values calculated at the previous step of the binary search.
#
# The intrinsic dimensionality is mainly used in multiscale embedding, e.g.
# \code{inp_from_perps_multi}, but may have some diagnostic value in
# other embeddings, if monitored with respect to different perplexity settings,
# for example. The calculation requires the \code{weight_fn} to be
# exponential in the squared distances (i.e. the usual Gaussian similarity
# kernel used in probability-based embeddings). If using a non-default
# \code{weight_fn}, be very suspicious over attaching any particular meaning
# to the dimensionality values.
#
# @param dm Distance matrix.
# @param perplexity Target perplexity value.
# @param weight_fn Function which maps squared distances to weights. Should
# have the following signature: \code{function(d2m, beta)}
# @param tol Convergence tolerance for perplexity.
# @param max_iters Maximum number of iterations to carry out the search.
# @param verbose If \code{TRUE}, logs information about the beta values.
# @return List with the following members:
#  \item{\code{pm}}{Row probability matrix. Each row is a probability
#  distribution with a perplexity within \code{tol} of \code{perplexity}.}
#  \item{\code{beta}}{Vector of beta parameters used with \code{weight_fn} that
#  generated \code{pm}.}
#  \item{\code{dims}}{Vector of intrinsic dimensionality values calculated
#  for each point using the beta value at the target perplexity.}
# @references
# Intrinsic dimensionality with a Gaussian similarity kernel was described in:
# Lee, J. A., Peluffo-Ordo'nez, D. H., & Verleysen, M. (2015).
# Multi-scale similarities in stochastic neighbour embedding: Reducing
# dimensionality while preserving both local and global structure.
#
# Note that the procedure described in this paper is slightly different from
# that done here. In the paper, the perplexity search is carried out for
# multiple target perplexities, and the finite different estimate of the
# intrisic dimensionality is carried out by using the \code{beta} values only
# at the target perplexities. The approach used here takes advantage of the
# fact that multiple beta/perplexity values are generated as part of the
# bisection search anyway, so are reported even when only single-scale
# embeddings are used. Comparison of intrinsic dimensionalities calculated
# on the simulation datasets \code{ball}, \code{helix}
# and \code{sphere} with those reported in the paper show similar
# values.
d_to_p_perp_bisect <- function(dm, perplexity = 15, weight_fn, tol = 1e-05,
                               max_iters = 50, verbose = TRUE) {
  d2m <- dm ^ 2
  n <- nrow(d2m)

  pm <- matrix(0, n, n)
  beta <- rep(1, n)
  dims <- rep(0, n)
  num_failures <- 0
  for (i in 1:n) {
    d2mi <- d2m[i, , drop = FALSE]
    result <- find_beta(d2mi, i, perplexity, beta[i], weight_fn, tol, max_iters)
    pm[i,] <- result$pr
    beta[i] <- result$beta
    dims[i] <- result$d_intr
    if (!result$ok) {
      num_failures <- num_failures + 1
    }
  }

  attr(pm, 'type') <- "row"
  if (verbose) {
    summarize_betas(beta)
    summarize(pm, "P")
    summarize(dims, "dims")
    if (num_failures > 0) {
      warning(paste0(num_failures, " failures to find the target perplexity ",
                     formatC(perplexity)))
    }
  }
  list(pm = pm, beta = beta, dims = dims)
}

# Find Beta Parameter for One Row of Matrix
#
# Find the value of beta that produces a specific perplexity when a row of
# a distance matrix is converted to probabilities.
#
# For each point the intrinsic dimensionality is calculated - this is a measure
# of the dimensionality local to the point. It is calculated as the derivative
# of the Shannon Entropy in bits with respect to the log2 of the beta parameter.
# The value reported is that of a finite difference estimate using the value
# of beta at the target perplexity and the values calculated at the previous
# step of the binary search. If by some miracle the binary search converged
# in one step, a second set of values are generated by increasing the converged
# beta value by one percent, or adding 1e-3 (whichever results in the smaller
# beta value). This procedure assumes a weight function which is exponential
# with respect to the squared distances (the usual Guassian similarity kernel
# used in most probability-based embeddings). Intrinsic dimensionalities
# reported for non-default \code{weight_fn}s should be treated with care.
#
# @param d2mi Row of a squared distance matrix.
# @param i Index of the row in the squared distance matrix.
# @param perplexity Target perplexity value.
# @param beta_init Initial guess for beta.
# @param weight_fn Function which maps squared distances to weights. Should
# have the following signature: \code{function(D2i, beta)}
# @param tol Convergence tolerance for perplexity.
# @param max_iters Maximum number of iterations to carry out the search.
# @return List with the following members:
#  \item{\code{pm}}{Matrix with one row containing a probability distribution
#  with a perplexity within \code{tol} of \code{perplexity}.}
#  \item{\code{beta}}{Beta parameter used with \code{weight_fn} that generated
#  \code{pm}.}
#  \item{\code{perp}}{Final perplexity of the probability, differing from
#  \code{perplexity} only if \code{max_iters} was exceeded.}
#  \item{\code{d_intr}}{The intrinsic dimensionality for this perplexity,
#  estimated using the final two guesses in the bisection procedure.}
find_beta <- function(d2mi, i, perplexity, beta_init = 1,
                      weight_fn, tol = 1e-05, max_iters = 50) {

  h_base <- 2
  fn <- make_objective_fn(d2mi, i, weight_fn = weight_fn,
                          perplexity = perplexity, h_base = h_base)

  result <- root_bisect(fn = fn, tol = tol, max_iters = max_iters,
                        x_lower = 0, x_upper = Inf, x_init = beta_init,
                        keep_search = TRUE)


  ok <- result$iter != max_iters

  d_intr <- initrinsic_dimensionality(result, fn)

  list(pr = result$best$pr, perplexity = h_base ^ result$best$h,
       beta = result$x, d_intr = d_intr, ok = ok)
}

# Find Root of Function by Bisection
#
#  Bisection method to find root of f(x) = 0 given two values which bracket
# the root.
#
# @param fn Function to optimize. Should take one scalar numeric value and
# return a list containing at least one element called \code{y}, which should
# contain the scalar numeric value. The list may contain other elements, so
# that other useful values can be returned from the search routine.
# @param tol Tolerance. If \eqn{abs(y_target - y) < tol} then the search will
# terminate.
# @param max_iters Maximum number of iterations to search for.
# @param x_lower Lower bracket of x.
# @param x_upper Upper bracket of x.
# @param x_init Initial value of x.
# @param keep_search If \code{TRUE}, then return all the values of \code{x}
#  and \code{y} that were tried during the search.
# @param verbose If \code{TRUE}, logs information about the bisection search.
# @return a list containing:
#  \item{\code{x}}{Optimized value of x.}
#  \item{\code{y}}{Value of y at convergence or \code{max_iters}}
#  \item{\code{iter}}{Number of iterations at which convergence was reached.}
#  \item{\code{best}}{Return value of calling \code{fn} with the optimized
#  value of \code{x}.}
root_bisect <- function(fn, tol = 1.e-5, max_iters = 50, x_lower,
                        x_upper, x_init = (x_lower + x_upper) / 2,
                        keep_search = FALSE, verbose = FALSE) {

  sign_lower <- sign(fn(x_lower)$value)

  result <- fn(x_init)
  value <- result$value

  bounds <- list(lower = min(x_lower, x_upper), upper = max(x_lower, x_upper),
                 mid = x_init)
  iter <- 0
  if (keep_search) {
    xs <- c(x_init)
    ys <- c(value)
  }

  while (abs(value) > tol && iter < max_iters) {
    bounds <- improve_guess(bounds, sign(value) == sign_lower)
    result <- fn(bounds$mid)
    value <- result$value
    iter <- iter + 1
    if (keep_search) {
      xs <- c(xs, bounds$mid)
      ys <- c(ys, value)
    }
    if (verbose) {
      message("iter ", iter, " x ", formatC(bounds$mid), " y ", formatC(value))
    }
  }

  result <- list(x = bounds$mid, y = value, best = result, iter = iter)
  if (keep_search) {
    result$xs <- xs
    result$ys <- ys
  }
  result
}

# Narrows Bisection Bracket Range
#
# @param bracket List representing the bounds of the parameter search.
# Contains three elements: \code{lower}: lower value, \code{upper}: upper
# value, \code{mid}: the midpoint.
# @param lower_equal_signs If \code{TRUE}, the sign of the value of the
#  function evaluted at \code{bracket$mid} is the same as that of
#  \code{bracket$lower}.
# @return Updated \code{bracket} list.
improve_guess <- function(bracket, lower_equal_signs) {
  mid <- bracket$mid
  if (lower_equal_signs) {
    bracket$lower <- mid
    if (is.infinite(bracket$upper)) {
      mid <- mid * 2
    } else {
      mid <- (mid + bracket$upper) / 2
    }
  } else {
    bracket$upper <- mid
    if (is.infinite(bracket$lower)) {
      mid <- mid / 2
    } else {
      mid <- (mid + bracket$lower) / 2
    }
  }
  bracket$mid <- mid
  bracket
}

# Objective Function for Parameter Search
#
# Create callback that can be used as an objective function for perplexity
# parameter search.
#
# @param d2r Row of a squared distance matrix.
# @param i Index of the row in the matrix.
# @param weight_fn Function that converts squared distances to weights. Should
# have the signature \code{function(D2, beta)}
# @param perplexity the target perplexity the probability generated by the
# weight function should produce.
# @param h_base the base of the logarithm to use for Shannon Entropy
# calculations.
# @return Callback function for use in parameter search routine. The callback
# has the signature \code{fn(beta)} where \code{beta} is the
# parameter being optimized, and returns a list
# containing:
#  \item{\code{value}}{Difference between the Shannon Entropy for the value
#   of beta passed as an argument and the target Shannon Entropy.}
#  \item{\code{h}}{Shannon Entropy for the value of beta passed as an
# argument.}
#  \item{\code{pm}}{Probabilities generated by the weighting function.}
make_objective_fn <- function(d2r, i, weight_fn, perplexity, h_base = exp(1)) {
  h_target <- log(perplexity, h_base)

  weight_fn_param <- function(beta) {
    wr <- weight_fn(d2r, beta)
    wr[1, i] <- 0
    wr
  }
  function(beta) {
    wr <- weight_fn_param(beta)
    pr <- weights_to_prow(wr)$pm
    h <- shannon_entropy_rows(pr, h_base)
    list(value = h - h_target, pr = pr, h = h)
  }
}

# Shannon Entropies for Row Probability Matrices
#
# Calculates the Shannon Entropy per row of a row probability matrix. Each row
# of the matrix should consist of probabilities summing to 1.
#
# @param pm Row probability matrix.
# @param base Base of the logarithm to use in the entropy calculation.
# @param eps Small floating point value used to avoid numerical problems.
# @return Vector of Shannon entropies, one per row of the matrix.
shannon_entropy_rows <- function(pm, base = 2, eps = .Machine$double.eps) {
  -apply(pm * log(pm + eps, base), 1, sum)
}

# Perplexity for Row Probability Matrices
#
# Calculates the perplexity (antilogarithm of the Shannon Entropy) per row of
# a row probability matrix. Each row of the matrix should consist of
# probabilities summing to 1.
#
# @param pm Row probability matrix.
# @param eps Small floating point value used to avoid numerical problems.
# @return Vector of perplexities, one per row of the matrix.
perplexity_rows <- function(pm, eps = .Machine$double.eps) {
  exp(shannon_entropy_rows(pm, base = exp(1), eps = eps))
}

# Intrinsic Dimensionality
initrinsic_dimensionality <- function(bisection_result, fn) {
  hs <- bisection_result$ys
  betas <- bisection_result$xs

  # if we got lucky guessing the parameter for the target perplexity immediately
  # generate another beta value close to the current value
  if (length(hs) == 1) {
    beta_fwd <- min(bisection_result$x * 1.01, bisection_result$x + 1e-3)
    h_fwd <- fn(beta_fwd)$h

    betas <- c(betas, beta_fwd)
    hs <- c(hs, h_fwd)
  }

  dh <- hs[length(hs)] - hs[length(hs) - 1]
  dlog2b <- log2(betas[length(betas)]) - log2(betas[length(betas) - 1])
  (-2 * dh) / dlog2b
}
