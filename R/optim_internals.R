# Optimizer internals documentation.

# Optimizer Gradient Methods
#
# Part of the optimizer that calculates the gradient at a position in the
# solution space.
#
# @section Interface:
# A gradient method is a list containing
# \describe{
#  \item{\code{calculate(opt, inp, out, method, iter)}}{Calculation function
#  with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data.}
#      \item{\code{method}}{Embedding method.}
#      \item{\code{iter}}{Iteration number.}
#    }
#    The function should calculate the gradient and return a list containing:
#    \describe{
#      \item{\code{gm}}{Gradient matrix.}
#    }
#  }
# }
# @section Documentation:
# Add the tag:
# \preformatted{@family sneer optimization gradient methods}
# to the documentation section of any implementing function.
# @keywords internal
# @name optimization_gradient_interface
NULL

# Optimizer Direction Method
#
# Part of the optimizer that finds the direction of descent.
#
# @section Interface:
# A direction method is a list containing:
# \describe{
#  \item{\code{value}}{The current direction. It should be a matrix with
#  the same dimensions as the gradient.}
#  \item{\code{calculate(opt, inp, out, method, iter)}}{Calculation function
#  with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data.}
#      \item{\code{method}}{Embedding method.}
#      \item{\code{iter}}{Iteration number.}
#    }
#    The function should set \code{opt$direction$value} with the current
#    direction of descent and return a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer containing updated \code{direction$value}.}
#    }
#  }
#  \item{\code{init(opt, inp, out, method)}}{Optional initialization function
#  with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should set any needed state on \code{opt$direction} and
#    return a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer containing initialized \code{direction}.}
#    }
#  }
#  \item{\code{validate(opt, inp, out, proposed_out, method)}}{Optional
#  validation function with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{proposed_out}}{Proposed updated output for this iteration.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should do any validation required by this method on the state
#    of \code{proposed_out}, e.g. check that the proposed solution reduces the
#    cost function. In addition it should update the state of any of the other
#    arguments passed to the validation function on the basis of the pass or
#    failure of the validation.
#    The return value of the function should be a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{proposed_out}}{Proposed updated output for this iteration.}
#      \item{\code{method}}{Embedding method.}
#      \item{\code{ok}}{Logical value, \code{TRUE} if \code{proposed_out}
#      passed validation, \code{FALSE} otherwise}
#    }
#    Note that if any validation functions fail the proposed solution by
#    setting \code{ok} to \code{FALSE} in their return value, the optimizer
#    will reject \code{proposed_out} and use \code{out} as the starting point
#    for the next iteration of the optimization process.
#  }
#  \item{\code{after_step(opt, inp, out, new_out, ok, iter)}}{Optional function
#  to invoke after the solution has been updated with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{new_out}}{Output data which will be the starting solution
#      for the next iteration of optimization. If the validation stage failed,
#      then this may be the same solution as \code{out}.}
#      \item{\code{ok}}{\code{TRUE} if the current iteration passed validation,
#      \code{FALSE} otherwise.}
#      \item{\code{iter}}{Current iteration number.}
#    }
#    The function should do any processing of this method's internal state to
#    prepare for the next iteration and call to \code{calculate}. The
#    return value of the function should be a list containing:
#    \describe{
#      \item{\code{opt}}{Updated optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{new_out}}{New output to be used in the next iteration.}
#    }
#  }
# }
# @section Documentation:
# Add the tag:
# \preformatted{@family sneer optimization direction methods}
# to the documentation section of any implementing function.
# @keywords internal
# @name optimization_direction_interface
NULL

# Optimizer Step Size Methods
#
# Part of the optimizer that finds the step size of the gradient descent.
#
# @section Interface:
# A step size method is a list containing:
# \describe{
#  \item{\code{value}}{The current step size. It should either be a scalar or
#  a matrix with the same dimensions as the gradient.}
#  \item{\code{calculate(opt, inp, out, method)}}{Calculation function
#  with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should set \code{opt$step_size$value} with the current
#    step size and return a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer containing updated \code{step_size$value}.}
#    }
#  }
#  \item{\code{init(opt, inp, out, method)}}{Optional initialization function
#  with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should set any needed state on \code{opt$step_size} and
#    return a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer containing initialized \code{step_size}
#      method.}
#    }
#  }
#  \item{\code{validate(opt, inp, out, proposed_out, method)}}{Optional
#  validation function with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{proposed_out}}{Proposed updated output for this iteration.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should do any validation required by this method on the state
#    of \code{proposed_out}, e.g. check that the proposed solution reduces the
#    cost function. In addition it should update the state of any of the other
#    arguments passed to the validation function on the basis of the pass or
#    failure of the validation.
#    The return value of the function should be a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{proposed_out}}{Proposed updated output for this iteration.}
#      \item{\code{method}}{Embedding method.}
#      \item{\code{ok}}{Logical value, \code{TRUE} if \code{proposed_out}
#      passed validation, \code{FALSE} otherwise}
#    }
#    Note that if any validation functions fail the proposed solution by
#    setting \code{ok} to \code{FALSE} in their return value, the optimizer
#    will reject \code{proposed_out} and use \code{out} as the starting point
#    for the next iteration of the optimization process.
#  }
#  \item{\code{after_step(opt, inp, out, new_out, ok, iter)}}{Optional function
#  to invoke after the solution has been updated with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{new_out}}{Output data which will be the starting solution
#      for the next iteration of optimization. If the validation stage failed,
#      then this may be the same solution as \code{out}.}
#      \item{\code{ok}}{\code{TRUE} if the current iteration passed validation,
#      \code{FALSE} otherwise.}
#      \item{\code{iter}}{Current iteration number.}
#    }
#    The function should do any processing of this method's internal state to
#    prepare for the next iteration and call to \code{calculate}. The
#    return value of the function should be a list containing:
#    \describe{
#      \item{\code{opt}}{Updated optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{new_out}}{New output to be used in the next iteration.}
#    }
#  }
# }
# @section Documentation:
# Add the tag:
# \preformatted{@family sneer optimization step size methods}
# to the documentation section of any implementing function.
# @keywords internal
# @name optimization_step_size_interface
NULL

# Optimizer Update Method Interface
#
# Part of the optimizer that generates the update step.
#
# @section Interface:
# An update method is a list containing:
# \describe{
#  \item{\code{value}}{The current update. It should either be a scalar or
#  a matrix with the same dimensions as the gradient.}
#  \item{\code{calculate(opt, inp, out, method)}}{Calculation function
#  with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should set \code{opt$update$value} with the current
#    step size and return a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer containing updated \code{update$value}.}
#    }
#  }
#  \item{\code{init(opt, inp, out, method)}}{Optional initialization function
#  with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should set any needed state on \code{opt$update} and
#    return a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer containing initialized \code{update}
#      method.}
#    }
#  }
#  \item{\code{validate(opt, inp, out, proposed_out, method)}}{Optional
#  validation function with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{proposed_out}}{Proposed updated output for this iteration.}
#      \item{\code{method}}{Embedding method.}
#    }
#    The function should do any validation required by this method on the state
#    of \code{proposed_out}, e.g. check that the proposed solution reduces the
#    cost function. In addition it should update the state of any of the other
#    arguments passed to the validation function on the basis of the pass or
#    failure of the validation.
#    The return value of the function should be a list containing:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{proposed_out}}{Proposed updated output for this iteration.}
#      \item{\code{method}}{Embedding method.}
#      \item{\code{ok}}{Logical value, \code{TRUE} if \code{proposed_out}
#      passed validation, \code{FALSE} otherwise}
#    }
#    Note that if any validation functions fail the proposed solution by
#    setting \code{ok} to \code{FALSE} in their return value, the optimizer
#    will reject \code{proposed_out} and use \code{out} as the starting point
#    for the next iteration of the optimization process.
#  }
#  \item{\code{after_step(opt, inp, out, new_out, ok, iter)}}{Optional function
#  to invoke after the solution has been updated with the following arguments:
#    \describe{
#      \item{\code{opt}}{Optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{new_out}}{Output data which will be the starting solution
#      for the next iteration of optimization. If the validation stage failed,
#      then this may be the same solution as \code{out}.}
#      \item{\code{ok}}{\code{TRUE} if the current iteration passed validation,
#      \code{FALSE} otherwise.}
#      \item{\code{iter}}{Current iteration number.}
#    }
#    The function should do any processing of this method's internal state to
#    prepare for the next iteration and call to \code{calculate}. The
#    return value of the function should be a list containing:
#    \describe{
#      \item{\code{opt}}{Updated optimizer.}
#      \item{\code{inp}}{Input data.}
#      \item{\code{out}}{Output data from the start of the iteration.}
#      \item{\code{new_out}}{New output to be used in the next iteration.}
#    }
#  }
# }
# @section Documentation:
# Add the tag:
# \preformatted{@family sneer optimization update methods}
# to the documentation section of any implementing function.
# @keywords internal
# @name optimization_update_interface
NULL
