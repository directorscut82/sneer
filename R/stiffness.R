# Stiffness functions. Generally only valid for a specific cost function
# (and for probability-based embeddings, a specific cost function/weighting
# function pair). However, some stiffness functions can be written in terms of
# others.

# ASNE Stiffness Function
#
# The precision parameter \code{beta} is normally a scalar, but it can also
# work with a vector, as long as the length of the vector is equal to the
# number of rows  in the probability matrices. The \code{nerv} method
# makes use of this property.
#
# @param pm Input probability matrix.
# @param qm Output probabilty matrix.
# @param beta The precision of the weighting function. Usually left at the
# default value of 1.
# @return Stiffness matrix.
asne_stiffness <- function(pm, qm, beta = 1) {
  km <- beta * (pm - qm)
  2 * (km + t(km))
}

# SSNE Stiffness Function
#
# The precision parameter \code{beta} is normally left at its default value of
# 1. Note that unlike the \code{asne_stiffness} function, a vector of
# precisions can not be used as input to \code{beta}: an incorrect gradient
# will result.
#
# @param pm Input joint probability matrix.
# @param qm Output joint probabilty matrix.
# @param beta The precision of the weighting function.
# @return Stiffness matrix.
ssne_stiffness <- function(pm, qm, beta = 1) {
  4 * beta * (pm - qm)
}

# t-SNE Stiffness Function
#
# @param pm Input joint probability matrix.
# @param qm Output joint probabilty matrix.
# @param wm Output weight probability matrix.
# @return Stiffness matrix.
tsne_stiffness <- function(pm, qm, wm) {
  ssne_stiffness(pm, qm, beta = 1) * wm
}

# t-ASNE Stiffness Function
#
# @param pm Input probability matrix.
# @param qm Output probabilty matrix.
# @param wm Output weight probability matrix.
# @return Stiffness matrix.
tasne_stiffness <- function(pm, qm, wm) {
  km <- (pm - qm) * wm
  2 * (km + t(km))
}

# HSSNE Stiffness Function
#
# Note that unlike the \code{asne_stiffness} function, a vector of
# precisions can not be used as input to \code{beta}: an incorrect gradient
# will result.
#
# @param pm Input joint probability matrix.
# @param qm Output joint probabilty matrix.
# @param wm Output weight probability matrix.
# @param alpha Tail heaviness of the weighting function.
# @param beta The precision of the weighting function.
# @return Stiffness matrix.
hssne_stiffness <- function(pm, qm, wm, alpha = 1.5e-8, beta = 1) {
  ssne_stiffness(pm, qm, beta = beta) * (wm ^ alpha)
}

# "Reverse" ASNE Stiffness Function
#
# Uses the exponential weighting function for similarities, but the
# "reverse" Kullback-Leibler divergence as the cost function.
#
# The precision parameter \code{beta} is normally a scalar, but it can also
# work with a vector, as long as the length of the vector is equal to the
# number of rows  in the probability matrices. The \code{nerv} method
# makes use of this property.
#
# @param pm Input probability matrix.
# @param qm Output probabilty matrix.
# @param rev_kl "Reverse" KL divergence between \code{pm} and \code{qm}.
# @param beta The precision of the weighting function.
# @param eps Small floating point value used to avoid numerical problems.
# @return Stiffness matrix.
reverse_asne_stiffness <- function(pm, qm, rev_kl, beta = 1,
                                   eps = .Machine$double.eps) {
  km <- beta * qm * (log((pm + eps) / (qm + eps)) + rev_kl)
  2 * (km + t(km))
}

# "Reverse" SSNE Stiffness Function
#
# Uses the exponential weighting function for similarities, but the
# "reverse" Kullback-Leibler divergence as the cost function.
#
# The precision parameter \code{beta} is normally left at its default value of
# 1. Note that unlike the \code{reverse_asne_stiffness} function, a
# vector of precisions can not be used as input to \code{beta}: an incorrect
# gradient will result.
#
# @param pm Input joint probability matrix.
# @param qm Output joint probabilty matrix.
# @param rev_kl "Reverse" KL divergence between \code{pm} and \code{qm}.
# @param beta The precision of the weighting function.
# @param eps Small floating point value used to avoid numerical problems.
# @return Stiffness matrix.
reverse_ssne_stiffness <- function(pm, qm, rev_kl, beta = 1,
                                   eps = .Machine$double.eps) {
  4 * beta * qm * (log((pm + eps) / (qm + eps)) + rev_kl)
}

# "Reverse" t-SNE Stiffness Function
#
# Uses the exponential weighting function for similarities, but the
# "reverse" Kullback-Leibler divergence as the cost function.
#
# @param pm Input joint probability matrix.
# @param qm Output joint probabilty matrix.
# @param wm Output weight probability matrix.
# @param rev_kl "Reverse" KL divergence between \code{pm} and \code{qm}.
# @param eps Small floating point value used to avoid numerical problems.
# @return Stiffness matrix.
reverse_tsne_stiffness <- function(pm, qm, wm, rev_kl,
                                   eps = .Machine$double.eps) {
  reverse_ssne_stiffness(pm, qm, rev_kl, beta = 1, eps) * wm
}

# "Reverse" HSSNE Stiffness Function
#
# The precision parameter \code{beta} is normally left at its default value of
# 1. Note that unlike the \code{reverse_asne_stiffness} function, a
# vector of precisions can not be used as input to \code{beta}: an incorrect
# gradient will result.
#
# @param pm Input joint probability matrix.
# @param qm Output joint probabilty matrix.
# @param wm Output weight probability matrix.
# @param rev_kl "Reverse" KL divergence between \code{pm} and \code{qm}.
# @param alpha Tail heaviness of the weighting function.
# @param beta The precision of the weighting function.
# @param eps Small floating point value used to avoid numerical problems.
# @return Stiffness matrix.
reverse_hssne_stiffness <- function(pm, qm, wm, rev_kl, alpha = 1.5e-8,
                                    beta = 1, eps = .Machine$double.eps) {
  reverse_ssne_stiffness(pm, qm, rev_kl, beta = beta, eps) * (wm ^ alpha)
}

