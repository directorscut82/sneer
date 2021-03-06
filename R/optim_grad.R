# Optimization Gradient Methods
#
# The available gradient methods that can be used by the optimization routines
# in sneer.
#
# @examples
# make_opt(gradient = classical_gradient())
# make_opt(gradient = nesterov_gradient())
# @keywords internal
# @name optimization_gradient
# @family sneer optimization gradient methods
NULL

# Classical Gradient
#
# Factory function for creating an optimizer gradient method.
#
# Calculates the gradient at the current location of the solution.
# Can also provide the position at which the gradient is calculated, useful
# for some step length calculation methods.
#
# @seealso The return value of this function is intended for internal use of
# the sneer framework only. See \code{optimization_gradient_interface}
# for details on the functions and values defined for this method.
#
# @return Classical gradient calculation method.
# @examples
# # Use as part of the make_opt function for configuring an optimizer's
# # gradient method:
# make_opt(gradient = classical_gradient())
# @family sneer optimization gradient methods
classical_gradient <- function() {
  list(
    calculate_position = classical_position,
    calculate = calculate_gradient,
    is_dirty = function(opt, inp, out, method, iter) {
      TRUE
    }
  )
}


# Nesterov Accelerated Gradient
#
# Factory function for creating an optimizer gradient method.
#
# Calculates the gradient according to the Nesterov Accelerated Gradient
# method. Can also provide the position at which the gradient is calculated,
# useful for some step length calculation methods.
#
# @seealso The return value of this function is intended for internal use of
# the sneer framework only. See \code{optimization_gradient_interface}
# for details on the functions and values defined for this method.
#
# @return NAG method for gradient calculation.
# @examples
# # Use as part of the make_opt function for configuring an optimizer's
# # gradient method:
# make_opt(gradient = nesterov_gradient())
# @references
# Sutskever, I., Martens, J., Dahl, G., & Hinton, G. (2013).
# On the importance of initialization and momentum in deep learning.
# In \emph{Proceedings of the 30th international conference on machine learning (ICML-13)}
# (pp. 1139-1147).
# @family sneer optimization gradient methods
nesterov_gradient <- function() {
  list(
    calculate_position = nesterov_position,
    calculate = calculate_gradient,
    is_dirty = function(opt, inp, out, method, iter) {
      TRUE
    }
  )
}

# Gradient Calculation
#
# Calculate the gradient of the cost function for a specified position, and
# a given type of optimization.
#
# @param opt Optimizer.
# @param inp Input data.
# @param out Output data containing the desired position.
# @param method Embedding method.
# @param iter Iteration number.
# @return List containing:
# \item{\code{km}}{Stiffness matrix.}
# \item{\code{gm}}{Gradient matrix.}
calculate_gradient <- function(opt, inp, out, method, iter) {
  if (!is.null(opt$gradient$is_dirty) &&
      !opt$gradient$is_dirty(opt, inp, out, method, iter)) {
    return(list(gm = opt$gm, km = opt$km))
  }
  pos <- opt$gradient$calculate_position(opt, inp, out, method, iter)
  gradient(inp, pos, method, opt$mat_name)
}


# Classical Gradient Position
#
# Function for calculating the position to evaluate the gradient at.
#
# If the solution is currently at \code{out$ym}, this function returns that
# position. In standard gradient descent optimization, this is the location
# where the gradient would be calculated.
#
# @param opt Optimizer.
# @param inp Input data.
# @param out Output data.
# @param method Embedding method.
# @param iter Iteration number.
# @return List containing:
#  \item{\code{km}}{Stiffness matrix.}
#  \item{\code{gm}}{Gradient matrix.}
# @seealso \code{nesterov_position} for an alternative location to
# calculate the gradient at.
classical_position <- function(opt, inp, out, method, iter) {
  out
}

# Nesterov Accelerated Gradient Calculation Position (Toronto Formulation)
#
# Function for calculating the position to evaluate the gradient at.
#
# This function return the position of the current solution after the momentum
# update for this iteration has been applied. Sustkever and co-workers at
# Toronto demonstrated that calculating the gradient at this location was
# equivalent to Nesterov Accelerated Gradient (NAG).
#
# @param opt Optimizer.
# @param inp Input data.
# @param out Output data.
# @param method Embedding method.
# @param iter Iteration number.
# @return New output data.
# @references
# Sutskever, I., Martens, J., Dahl, G., & Hinton, G. (2013).
# On the importance of initialization and momentum in deep learning.
# In \emph{Proceedings of the 30th international conference on machine learning (ICML-13)}
# (pp. 1139-1147).
nesterov_position <- function(opt, inp, out, method, iter) {
  opt$update$value <- momentum_update_term(opt, inp, out, method, iter)
  update_solution(opt, inp, out, method)
}

# Gradient Calculation
#
# Calculate the gradient of the cost function for a specified position.
#
# @param inp Input data.
# @param out Output data containing the desired position.
# @param method Embedding method.
# @param mat_name Name of the matrix in the output data list that contains the
# embedded coordinates.
# @return List containing:
# \item{\code{km}}{Stiffness matrix.}
# \item{\code{gm}}{Gradient matrix.}
gradient <- function(inp, out, method, mat_name = "ym") {
  km <- method$stiffness_fn(method, inp, out)
  gm <- stiff_to_grads(out[[mat_name]], km)
  list(km = km, gm = gm)
}

# Finite Difference Gradient Calculation
#
# Calculate the gradient of the cost function for a specified position using
# a finite difference.
#
# Only intended for testing that analytical gradients have been calculated
# correctly.
#
# @param inp Input data.
# @param out Output data containing the desired position.
# @param method Embedding method.
# @param mat_name Name of the matrix in the output data list that contains the
# embedded coordinates.
# @param diff Step size to take in finite difference calculation.
# @return List containing:
# \item{\code{gm}}{Gradient matrix.}
gradient_fd <- function(inp, out, method, mat_name = "ym", diff = 1e-4) {
  ym <- out[[mat_name]]
  nr <- nrow(ym)
  nc <- ncol(ym)

  grad <- matrix(0, nrow = nr, ncol = nc)
  for (i in 1:nr) {
    for (j in 1:nc) {
      ymij_old <- ym[i, j]
      ym[i, j] <- ymij_old + diff
      out_fwd <- set_solution(inp, ym, method, mat_name, out)
      cost_fwd <- calculate_cost(method, inp, out_fwd)

      ym[i, j] <- ymij_old - diff
      out_back <- set_solution(inp, ym, method, mat_name, out)
      cost_back <- calculate_cost(method, inp, out_back)

      fd <- (cost_fwd - cost_back) / (2 * diff)
      grad[i, j] <- fd

      ym[i, j] <- ymij_old
      out <- set_solution(inp, ym, method, mat_name, out)
    }
  }

  list(gm = grad)
}

# Gradient Matrix from Stiffness Matrix
#
# Convert stiffness matrix to gradient matrix.
#
# @param ym Embedded coordinates.
# @param km Stiffness matrix.
# @return Gradient matrix.
stiff_to_grads <- function(ym, km) {
  gm <- matrix(0, nrow(ym), ncol(ym))
  for (i in 1:nrow(ym)) {
    disp <- sweep(-ym, 2, -ym[i, ]) #  matrix of y_ik - y_jk
    gm[i, ] <- apply(disp * km[, i], 2, sum) # row is sum_j (km_ji * disp)
  }
  gm
}
