# Functions for initializing the input data.

# Input Initializers
#
# These methods deal with converting the input coordinates or distances
# into the structures required by different embedding methods. For instance,
# probability-based embedding methods require the construction of a probability
# matrix from the input distances.
#
# @seealso Input initializers should be passed to the
# \code{init_inp} parameter of embedding functions such as
# \code{embed_prob} or \code{embed_dist}.
#
# @examples
#
# \dontrun{
# # initializer that uses bisection search to create input probability
# # distribution with a perplexity of 50
# # pass result to init_inp parameter of an embedding function
# embed_prob(method = tsne(), init_inp = inp_from_perp(perplexity = 50), ...)
# }
# @keywords internal
# @name input_initializers
# @family sneer input initializers
NULL

# Input Probability Initialization By Bisection Search on Perplexity
#
# An initialization method for creating input probabilities.
#
# Function to generate a row probability matrix by optimizing a one-parameter
# weighting function. This is used to create input probabilities from the
# input distances, such that each row of the matrix is a probability
# distribution with the specified perplexity.
#
# This is the method described in the original SNE paper, and few methods
# deviate very strongly from it, although they may do further processing
# on the resulting probability matrix. For example, SSNE and t-SNE convert
# this matrix into a single joint probability distribution.
#
# The parameter \code{modify_kernel_fn} can be used to modify the output kernel
# based on the results of the perplexity calculation. If provided, then the
# signature of \code{modify_kernel_fn} must be:
#
# \code{modify_kernel_fn(inp, out, method)}
#
# where \code{inp} is the input data, \code{out} is the current output data,
# \code{method} is the embedding method.
#
# This function will be called once for each perplexity, and an updated
# kernel should be returned.
#
# @section Exported data:
# Data generated by this initializer can be exported from the embedding
# function by passing \code{"inp"} to the embedding function's
# \code{export} list parameter. The return value of the embedding function is a
# list, which will contain a member called \code{"inp"}. In turn, this is a list
# containing the input data. If this initializer is used, the list will contain
# the following data:
# \describe{
#  \item{\code{pm}}{Input probabilities.}
#  \item{\code{beta}}{Input weighting parameters that produced the
#     probabilities. Only provided if \code{keep_all_results} is \code{TRUE}.}
# }
#
# @param perplexity Target perplexity value for the probability distributions.
# @param input_weight_fn Weighting function for distances. It should have the
#   signature \code{input_weight_fn(d2m, beta)}, where \code{d2m} is a matrix
#   of squared distances and \code{beta} is a real-valued scalar parameter
#   which will be varied as part of the search to produce the desired
#   \code{perplexity}. The function should return a matrix of weights
#   corresponding to the transformed squared distances passed in as arguments.
# @param modify_kernel_fn Function to create a new similarity kernel based
#  on the perplexity.
# @param keep_all_results If \code{true} then the list returned by the callback
#   will also contain a vector of \code{beta} parameters that generated the
#   probability matrix. Otherwise, only the probability matrix is returned.
# @param verbose If \code{TRUE} display messages about progress of
#   initialization.
# @return Input initializer for use by an embedding function.
# @seealso \code{embed_prob} and \code{embed_dist} for more
#   information on exporting initializer data.
# @examples
# # Set target perplexity of each probability distribution to 30
# inp_from_perp(perplexity = 30)
#
# # Set target perplexity of each probability distribution to 30 but use
# # a different weighting function.
# inp_from_perp(perplexity = 30, input_weight_fn = sqrt_exp_weight)
#
# # Perplexity of 50, and keep the values of the exponential parameter for
# # later processing or reporting.
# inp_from_perp(perplexity = 50, keep_all_results = TRUE)
#
# \dontrun{
# # Should be passed to the init_inp argument of an embedding function
# # To access input data, use the export parameter to export the "inp"
# # input data.
# embed_prob(init_inp = inp_from_perp(perplexity = 30,
#  input_weight_fn = exp_weight), export = c("inp"))
# }
# @family sneer input initializers
inp_from_perp <- function(perplexity = 30,
                          input_weight_fn = exp_weight,
                          modify_kernel_fn = NULL,
                          keep_all_results = TRUE,
                          verbose = TRUE) {
  inp_prob(
    function(inp, method, opt, iter, out) {

      if (!is.null(modify_kernel_fn)) {
        method <- on_inp_updated(method, function(inp, out, method) {
          method$kernel <- modify_kernel_fn(inp, out, method)
          list(method = method)
        })$method
      }

      inp <- single_perplexity(inp, perplexity = perplexity,
                        input_weight_fn = input_weight_fn,
                        keep_all_results = keep_all_results,
                        verbose = verbose)$inp

      inp$d_hat <- stats::median(inp$dims)

      list(inp = inp, method = method)

    }
  )
}

# Wrap Input Probability Initializer
#
# Takes an input initializer which creates a probability, and
# wraps it so that it is invoked at the correct time, the probability matrix
# is handled in the correct way (e.g. converting from conditional to joint
# probability), and other matrices are updated if needed.
#
# @param input_initializer Input initializer which creates a probability.
# @param init_only, if \code{TRUE}, then this initializer is only called once,
#  when the iteration number is zero.
# @param call_inp_updated, if \code{TRUE}, then the \code{inp_updated}
#  function will be called by this wrapper if \code{inp$dirty} is \code{TRUE}.
#  As this deals with calling the function and reassigning any changed data
#  for you, there's no reason to change this from its default value
#  (\code{TRUE}), unless your input initializer changes the input probability
#  more than once per invocation. In which case, you should set this to
#  \code{FALSE} and deal with calling \code{inp_updated} yourself inside the
#  initializer.
# @return Wrapped initializer with the correct signature for use by an
#  embedding function.
# @seealso \code{probability_matrices} describe the type of probability
#   matrix used by sneer.
inp_prob <- function(input_initializer, init_only = TRUE,
                     call_inp_updated = TRUE) {
  function(inp, method, opt, iter, out) {
    if (!init_only || iter == 0) {
      res <- input_initializer(inp, method, opt, iter, out)
      inp <- res$inp
      if (!is.null(res$method)) {
        method <- res$method
      }
      if (!is.null(res$opt)) {
        opt <- res$opt
      }
      if (!is.null(res$out)) {
        out <- res$out
      }
      if (inp$dirty) {
        inp$pm <- handle_prob(inp$pm, method)

        if (call_inp_updated) {
          update_res <- inp_updated(inp, out, method)
          inp <- update_res$inp
          out <- update_res$out
          method <- update_res$method
        }

        out$dirty <- TRUE
        utils::flush.console()
        # invalidate cached data (e.g. old costs) in optimizer
        opt$old_cost_dirty <- TRUE
        inp$dirty <- FALSE
      }
    }
    list(inp = inp, method = method, opt = opt, out = out)
  }
}

# Calculates a probability matrix for a given perplexity.
# See the inp_from_perp function for a fuller description.
single_perplexity <- function(inp, perplexity = 30,
                              input_weight_fn = exp_weight,
                              keep_all_results = TRUE,
                              verbose = TRUE) {
  if (verbose) {
    message("Parameter search for perplexity = ", formatC(perplexity))
  }
  d_to_p_result <- d_to_p_perp_bisect(inp$dm, perplexity = perplexity,
                                      weight_fn = input_weight_fn,
                                      verbose = verbose)

  if (keep_all_results) {
    for (name in names(d_to_p_result)) {
      inp[[name]] <- d_to_p_result[[name]]
    }
  }
  else {
    inp$pm <- d_to_p_result$pm
  }
  inp$perp <- perplexity
  inp$dirty <- TRUE
  list(inp = inp)
}


# Update Embedding Internals When Input Data Changes
#
# Called when the input data changes, normally when the input probability
# matrix is calculated. Some embedding method's output has an explicit
# dependency on such data: for example, the JSE (\code{jse}) cost
# function uses a mixture matrix of the input and output probability matrices.
#
# Normally this will only be called once when the input data is first
# initialized, but is using a technique where the input probabilities change,
# such as multiscaling, then this should be called every time such a change
# occurs.
#
# @param inp Input data.
# @param out Output data.
# @param method Embedding method.
# @return a list containing:
# \item{inp}{Updated input data.}
# \item{out}{Updated output data.}
# \item{method}{Updated embedding method.}
inp_updated <- function(inp, out, method) {
  if (!is.null(method$num_inp_updated_fn)) {
    for (i in 1:method$num_inp_updated_fn) {
      if (!is.null(method$inp_updated_fns[[i]])) {
        update_result <- method$inp_updated_fns[[i]](inp, out, method)
        if (!is.null(update_result$inp)) {
          inp <- update_result$inp
        }
        if (!is.null(update_result$out)) {
          out <- update_result$out
        }
        if (!is.null(update_result$method)) {
          method <- update_result$method
        }
      }
    }
  }
  list(inp = inp, out = out, method = method)
}

# Register a Function to Run When Input Data Changes
#
# Call this function to register a callback to run when the input data changes.
#
# For example, in \code{nerv}, the output kernel precisions are the
# same as those of the input kernel. Hence, it registers a function to transfer
# those value from the input data to the output kernel. This may be called
# multiple times if the probability is recalculated (e.g. due to multiple
# perplexity calculations).
#
# Similarly, the importance-weighted modifications of an embedding uses the
# input probability to generate a further weighting of the output kernels.
#
# The above two examples, although they both modify the kernel, can co-exist
# peacefully, because they affect two different parameters. However, the
# approach suggested in the multiscaling approach involves choosing a single
# precision value for the output kernel which is scaled compared to those
# used with the input kernel. This is in direct conflict with the NeRV
# approach.
#
# Ideally, we would be able to detect which update functions interfere with
# each other, and then ensure that only the most recently registered function
# was retained in the list of callbacks. But that sounds horrifically complex.
# Instead, when a function is registered here, it runs after previously
# registered callbacks. So if NeRV is modified to use multiscaling, the
# multiscale approach will "win" because it will run after the NeRV update
# function, and then overwrite the precision argument set by the NeRV update
# with its own value. This is only practical because pointlessly running
# the original NeRV update isn't very time consuming relative to the rest of
# the embedding.
#
# The function to register should have the signature
# \code{fn(inp, out, method)} and return a list containing any of the modified
# arguments.
#
# @param method Embedding method to register the function with.
# @param fn Function to run when the input data changes.
# @return List containing the updated method.
on_inp_updated <- function(method, fn) {
  if (!is.null(fn)) {
    if (is.null(method$num_inp_updated_fn)) {
      method$num_inp_updated_fn <- 0
      method$inp_updated_fns <- list()
    }
    method$num_inp_updated_fn <- method$num_inp_updated_fn + 1

    method$inp_updated_fns[[method$num_inp_updated_fn]] <- fn
  }

  list(method = method)
}
