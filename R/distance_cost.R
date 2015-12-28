# Cost functions used in distance-based embeddings.

#' Metric stress cost function, STRESS.
#'
#' A measure of embedding quality between input and output data.
#'
#' The metric stress, known in the MDS literature as STRESS, is the residual
#' sum of squares between the input and output distances:
#'
#' \deqn{STRESS = \sum_{i<j} (r_{ij} - d_{ij})^2}{STRESS = sum(rij-dij)^2}
#'
#' \eqn{r_{ij}}{rij} is the input distance between point \eqn{i} and point
#' \eqn{j} and \eqn{d_{ij}}{dij} is the corresponding output distance.
#'
#' This cost function requires the following matrices to be defined:
#' \describe{
#'  \item{\code{inp$dm}}{Input distances.}
#'  \item{\code{out$dm}}{Output distances.}
#' }
#'
#' @param inp Input data.
#' @param out Output data.
#' @param method Embedding method.
#' @return Metric stress.
#' @family sneer cost functions
#' @export
metric_stress_cost <- function(inp, out, method) {
  metric_stress(inp$dm, out$dm)
}
attr(metric_stress_cost, "sneer_cost_type") <- "dist"

#' Metric stress, STRESS.
#'
#' A measure of embedding quality between distance matrices.
#'
#' The metric stress, known in the MDS literature as STRESS, is the residual
#' sum of squares between two distance matrices.
#'
#' \deqn{STRESS = \sum_{i<j} (dx_{ij} - dy_{ij})^2}{STRESS = sum(dxij-dyij)^2}
#'
#' \eqn{dx_{ij}}{dxij} is the input distance between point \eqn{i} and point
#' \eqn{j} and \eqn{dy_{ij}}{dij} is the corresponding output distance.
#'
#' @param dxm Input distance matrix.
#' @param dym Embedded distance matrix.
#' @return Metric stress.
metric_stress <- function(dxm, dym) {
  sum(upper_tri((dxm - dym) ^ 2))
}


#' The SSTRESS cost function.
#'
#' A measure of embedding quality between input and output data.
#'
#' SSTRESS is a cost function used in metric MDS, related to the
#' \code{\link{metric_stress}}. It is defined as:
#'
#' \deqn{SSTRESS = \sum_{i<j} ((r_{ij}^2 - d_{ij})^2)^2}{SSTRESS = sum(rij^2-dij^2)^2}
#'
#' \eqn{r_{ij}}{rij} is the input distance between point \eqn{i} and point
#' \eqn{j} and \eqn{d_{ij}}{dij} is the corresponding output distance.
#' SSTRESS differs from STRESS in the distances being squared in the loss
#' function.
#'
#' This cost function requires the following matrices to be defined:
#' \describe{
#'  \item{\code{inp$dm}}{Input distances.}
#'  \item{\code{out$dm}}{Output distances.}
#' }
#'
#' @param inp Input data.
#' @param out Output data.
#' @param method Embedding method.
#' @return Metric stress.
#' @family sneer cost functions
#' @export
metric_sstress_cost <- function(inp, out, method) {
  metric_sstress(inp$dm, out$dm)
}
attr(metric_sstress_cost, "sneer_cost_type") <- "dist"

#' SSTRESS.
#'
#' A measure of embedding quality between distance matrices.
#'
#' SSTRESS is a cost function used in metric MDS, related to the
#' \code{\link{metric_stress}}. It is defined as:
#'
#' \deqn{SSTRESS = \sum_{i<j} ((dx_{ij}^2 - dy_{ij})^2)^2}{SSTRESS = sum(dxij^2-dyij^2)^2}
#'
#' \eqn{dx_{ij}}{dxij} is the input distance between point \eqn{i} and point
#' \eqn{j} and \eqn{dy_{ij}}{dij} is the corresponding output distance.
#' SSTRESS differs from STRESS in the distances being squared in the loss
#' function.
#'
#' @param dxm Input distance matrix.
#' @param dym Embedded distance matrix.
#' @return Metric stress.
metric_sstress <- function(dxm, dym) {
  sum(upper_tri((dxm ^ 2 - dym ^ 2) ^ 2))
}

#' Root mean square deviation of the metric stress.
#'
#' A measure of embedding quality between input and output data.
#'
#' The RMS stress is the square root of the normalized
#' \code{\link{metric_stress_cost}}:
#'
#' \deqn{STRESS_{RMS} = \sqrt{\frac{2\times STRESS}{n(n-1)}}}{stress_rms = sqrt[(2*STRESS)/(n*(n-1))]}
#'
#' The normalization divides the metric stress by
#' \eqn{0.5\times n(n-1)}{0.5*n*(n-1)}, where
#' \eqn{n} is the number of points in the distance matrix and hence the
#' normalization factor accounts for the number of unique distances (ignoring
#' self distances) in the matrix. The square root puts the units of the stress
#' back into that of the original distances.
#'
#' This cost function requires the following matrices to be defined:
#' \describe{
#'  \item{\code{inp$dm}}{Input distances.}
#'  \item{\code{out$dm}}{Output distances.}
#' }
#'
#' @param inp Input data.
#' @param out Output data.
#' @param method Embedding method.
#' @return RMS deviation of the input and output distances.
#' @family sneer cost functions
#' @export
rms_metric_stress_cost <- function(inp, out, method) {
  rms_metric_stress(inp$dm, out$dm)
}
attr(rms_metric_stress_cost, "sneer_cost_type") <- "dist"

#' Root mean square deviation of the metric stress.
#'
#' A measure of embedding quality between distance matrices.
#'
#' The RMS stress is the square root of the normalized
#' \code{\link{metric_stress}}:
#'
#' \deqn{STRESS_{RMS} = \sqrt{\frac{2\times STRESS}{n(n-1)}}}{stress_rms = sqrt[(2*STRESS)/(n*(n-1))]}
#'
#' The normalization divides the metric stress by
#' \eqn{0.5\times n(n-1)}{0.5*n*(n-1)}, where \eqn{n} is the number of points
#' in the distance matrix and hence the normalization factor accounts for the
#' number of unique distances (ignoring self distances) in the matrix. The
#' square root puts the units of the stress back into that of the original
#' distances.
#'
#' @param dxm Distance matrix.
#' @param dym Distance matrix, must be of the same dimensions as \code{dxm}.
#' @return RMS deviation of the input and output distances.
rms_metric_stress <- function(dxm, dym) {
  n <- nrow(dxm)
  sqrt(metric_stress(dxm, dym) / (0.5 * n * (n - 1)))
}

#' Normalized stress.
#'
#' A measure of embedding quality between input and output data.
#'
#' A normalized version of the \code{\link{metric_stress_cost}}:
#'
#' \deqn{STRESS_{RN} = \frac{STRESS}{\sum_{i<j} r_{ij}^2}}{STRESS/sum(rij^2)}
#'
#' where \eqn{r_{ij}}{rij} is the input distance between point \eqn{i} and point
#' \eqn{j} and \eqn{STRESS} is the \code{\link{metric_stress_cost}} between the
#' input and output distances. This gives a dimensionless value similar to the
#' \code{\link{kruskal_stress_cost}}, except the normalization uses the input
#' distances, not the output distances, much like the
#' \code{\link{sammon_stress_cost}}. It can be interpreted as the proportion of
#' the sum of squares of the input distances unaccounted for by the output
#' distances. Borg and Groenen defined this in their book on MDS.
#'
#' This cost function requires the following matrices to be defined:
#' \describe{
#'  \item{\code{inp$dm}}{Input distances.}
#'  \item{\code{out$dm}}{Output distances.}
#' }
#'
#' @param inp Input data.
#' @param out Output data.
#' @param method Embedding method.
#' @return Normalized stress.
#' @family sneer cost functions
#' @export
#' @references
#' Ingwer Borg, Patrick J. F. Groenen
#' Modern Multidimensional Scaling: Theory and Applications
#' Springer Science & Business Media, Aug 4, 2005
normalized_stress_cost <- function(inp, out, method) {
  normalized_stress(inp$dm, out$dm, method$eps)
}
attr(normalized_stress_cost, "sneer_cost_type") <- "dist"

#' Normalized stress.
#'
#' A measure of embedding quality between input and output distance matrices.
#'
#' A normalized version of the \code{\link{metric_stress}}:
#'
#' \deqn{STRESS_{RN} = \frac{STRESS}{\sum_{i<j} dxm_{ij}^2}}{STRESS/sum(dxm^2)}
#'
#' where \eqn{dxm} is the input distance matrix and \eqn{STRESS} is the
#' \code{\link{metric_stress}} between the input and output distances.
#' This gives a dimensionless value similar to the \code{\link{kruskal_stress}},
#' except the normalization uses the input distances, not the output distances,
#' much like the \code{\link{sammon_stress}}. It can be interpreted as the
#' proportion of the sum of squares of the input distances unaccounted for by
#' the output distances. Borg and Groenen defined this in their book on MDS.
#'
#' @param dxm Distance matrix.
#' @param dym Distance matrix, must be of the same dimensions as \code{dxm}.
#' @param eps Small floating point value to avoid numerical problems.
#' @return Normalized stress.
#' @references
#' Ingwer Borg, Patrick J. F. Groenen
#' Modern Multidimensional Scaling: Theory and Applications
#' Springer Science & Business Media, Aug 4, 2005
#' @export
normalized_stress <- function(dxm, dym, eps = .Machine$double.eps) {
  metric_stress(dxm, dym) / sum(upper_tri((dxm + eps) ^ 2))
}

#' Kruskal stress type-1 for metric embeddings.
#'
#' A measure of embedding quality between input and output data.
#'
#' The Kruskal stress is normally used in non-metric MDS applications, but can
#' be defined for metric embeddings:
#'
#' \deqn{K = \sqrt{\frac{STRESS}{\sum_{i<j} d_{ij}^2}}}{K = sqrt(STRESS/sum(dij^2))}
#'
#' where \eqn{d_{ij}}{dij} is the output distance between points \eqn{i} and
#' \eqn{j}, and \eqn{STRESS} is the \code{\link{metric_stress}} between the
#' input and output distance matrices. Unlike the raw STRESS, it is
#' dimensionless.
#'
#' This cost function requires the following matrices to be defined:
#' \describe{
#'  \item{\code{inp$dm}}{Input distances.}
#'  \item{\code{out$dm}}{Output distances.}
#' }
#'
#' @param inp Input data.
#' @param out Output data.
#' @param method Embedding method.
#' @return Kruskal stress.
#' @family sneer cost functions
#' @export
kruskal_stress_cost <- function(inp, out, method) {
  kruskal_stress(inp$dm, out$dm, method$eps)
}
attr(kruskal_stress_cost, "sneer_cost_type") <- "dist"

#' Kruskal stress type-1 for metric embeddings.
#'
#' A measure of embedding quality between input and output distance matrices.
#'
#' The Kruskal stress is normally used in non-metric MDS applications, but can
#' be defined for metric embeddings:
#'
#' \deqn{K = \sqrt{\frac{STRESS}{\sum_{i<j} dym_{ij}^2}}}{K = sqrt(STRESS/sum(dym^2))}
#'
#' where \eqn{dym} is the input distance matrix and \eqn{STRESS} is the
#' \code{\link{metric_stress_cost}} between the input and output distances. It
#' is dimensionless.
#'
#' @param dxm Distance matrix.
#' @param dym Distance matrix, must be of the same dimensions as \code{dxm}.
#' @param eps Small floating point value to avoid numerical problems.
#' @return Kruskal stress.
kruskal_stress <- function(dxm, dym, eps = .Machine$double.eps) {
  sqrt(metric_stress(dxm, dym) / sum(upper_tri((dym + eps) ^ 2)))
}

#' Mean Relative Error of an embedding.
#'
#' A measure of embedding quality between input and output data.
#'
#' The mean relative error of an embedding is defined as:
#'
#' \deqn{MRE=\frac{2}{n(n-1)}\sum_{i<j}\left|\frac{r_{ij} - d_{ij}}{r_{ij}}\right|}{MRE = (2/(n*(n-1)))*sum(abs((rij- dij)/rij))}
#'
#' where \eqn{r_{ij}}{rij} is the input distance between point \eqn{i} and point
#' \eqn{j}, \eqn{d_{ij}}{dij} is the corresponding output distance and \eqn{n}
#' is the number of points in the distance matrix. The constant pre-sum factor
#' is a normalization to account for the number of unique distances (ignoring
#' self-distances) in the matrix. You can treat the MRE as a percentage
#' by multiplying by 100.
#'
#' This cost function requires the following matrices to be defined:
#' \describe{
#'  \item{\code{inp$dm}}{Input distances.}
#'  \item{\code{out$dm}}{Output distances.}
#' }
#'
#' @param inp Input data.
#' @param out Output data.
#' @param method Embedding method.
#' @return Mean Relative Error.
#' @family sneer cost functions
#' @export
mean_relative_error_cost <- function(inp, out, method) {
  mean_relative_error(inp$dm, out$dm)
}
attr(mean_relative_error_cost, "sneer_cost_type") <- "dist"

#' Mean Relative Error of an embedding.
#'
#' A measure of embedding quality between input and output distance matrices.
#'
#' The mean relative error of an embedding is defined as:
#'
#' \deqn{MRE=\frac{2}{n(n-1)}\sum_{i<j}\left|\frac{dxm_{ij} - dym_{ij}}{r_{ij}}\right|}{MRE = (2/(n*(n-1)))*sum(abs((dxm - dym)/dxm))}
#'
#' where \eqn{dxm} is the input distance matrix, \eqn{dym} is the corresponding
#' output distance and \eqn{n} is the number of points in the distance matrix.
#' The constant pre-sum factor is a normalization to account for the number of
#' unique distances (ignoring self-distances) in the matrix. You can treat the
#' MRE as a percentage by multiplying by 100.
#' @param dxm Distance matrix.
#' @param dym Distance matrix, must be of the same dimensions as \code{dxm}.
#' @return Mean relative error.
#' @export
mean_relative_error <- function(dxm, dym) {
  n <- nrow(dxm)
  sum(upper_tri(abs((dxm - dym) / dxm))) / (0.5 * n * (n - 1))
}

#' Sammon stress.
#'
#' A measure of embedding quality between input and output distance data.
#'
#' The Sammon stress has a similar form to a normalized STRESS cost
#' function used in metric MDS:
#'
#' \deqn{S = \frac{\sum_{i<j}\frac{(r_{ij} - d_{ij})^2}{r_{ij}}}
#' {\sum_{i<j} r_{ij}}}{S = sum(((rij-dij)/rij)^2)/sum(rij)}
#'
#' where \eqn{r_{ij}}{rij} is the input distance between point \eqn{i} and point
#' \eqn{j} and \eqn{d_{ij}}{dij} is the corresponding output distance.
#'
#' Like the Kruskal stress, the Sammon stress is dimensionless. The main
#' difference is that the individual stresses are weighted by the reciprocal of
#' the input distance. Compared to MDS, this places a greater weight on
#' reproducing short distances over long distances.
#'
#' This cost function requires the following matrices to be defined:
#' \describe{
#'  \item{\code{inp$dm}}{Input distances.}
#'  \item{\code{out$dm}}{Output distances.}
#' }
#'
#' @param inp Input data.
#' @param out Output data.
#' @param method Embedding method.
#' @return Sammon Stress of the input and output distances.
#' @family sneer cost functions
#' @export
sammon_stress_cost <- function(inp, out, method) {
  sammon_stress(inp$dm, out$dm, method$eps)
}
attr(sammon_stress_cost, "sneer_cost_type") <- "dist"

#' Sammon stress.
#'
#' A measure of embedding quality between input and output distance data.
#'
#' The Sammon stress has a similar form to a normalized STRESS cost
#' function used in metric MDS:
#'
#' \deqn{S = \frac{\sum_{i<j}\frac{(r_{ij} - d_{ij})^2}{r_{ij}}}
#' {\sum_{i<j} r_{ij}}}{S = sum(((rij-dij)/rij)^2)/sum(rij)}
#'
#' where \eqn{r_{ij}}{rij} is the input distance between point \eqn{i} and point
#' \eqn{j} and \eqn{d_{ij}}{dij} is the corresponding output distance.
#'
#' Like the Kruskal stress, the Sammon stress is dimensionless. The main
#' difference is that the individual stresses are weighted by the reciprocal of
#' the input distance. Compared to MDS, this places a greater weight on
#' reproducing short distances over long distances.
#'
#' @param dxm Distance matrix.
#' @param dym Distance matrix, must be of the same dimensions as \code{dxm}.
#' @param eps Small floating point value used to avoid numerical problems.
#' @return the Sammon stress between the input and output distances.
sammon_stress <- function(dxm, dym, eps = .Machine$double.eps) {
  sum(upper_tri((dxm - dym) ^ 2 / (dxm + eps))) / sum(upper_tri(dxm + eps))
}

#' Null model for distance-based costs.
#'
#' Calculates a distance matrix that represents a "null" model, i.e. one
#' where no information from the input distances has been used. In this case,
#' the null model would mean all distances equal, which can only be achieved
#' if there is more than one distance by setting all distances to zero.
#'
#' @param dm Distance matrix, the dimensions of which will be used to create
#' the null matrix.
#' @return Matrix of zeros of the same dimensions as \code{dm}.
null_model_dist <- function(dm) {
  matrix(0, nrow = nrow(dm), ncol = ncol(dm))
}