# manifold alignment for linear case

manifold_linear <- function(X1, X2, W1, W2, W12, mu = 1, max_dim = 200, epsilon = 1e-8){
  library(Rcpp)
  #source('R/aliDif.R')
  #source('R/my_components.R')
  #source('R/createKnnGraph.R')
  #source('R/graph_laplacian.R')
  #source('R/L2_distance.R')
  #source('R/laplacian_eigen.R')
  #source('R/rowBdSlow.R')
  #sourceCpp('src/rowBd.cpp')
  #sourceCpp('src/knnsearch.cpp')
  # Feature-level Manifold Projections. Two domains.
  # X1: M1*P1 matrix, M1 examples in a P1 dimensional space.
  # X2: M2*P2 matrix
  # W1: M1*M1 matrix. weight matrix for each domain.
  # W2: M2*M2 matrix
  # W12: M1*M2 sparse matrix modeling the correspondence of X1 and X2.
  # mu: used to balance matching corresponding pairs and preserving manifold topology.
  # max_dim: max dimensionality of the new space. (default: 200)
  # epsilon: precision. (default: 1e-8)
  # get sizes for convenience later
  M1 = size(X1)[1]
  M2 = size(X2)[1]
  P1 = size(X1)[2]
  P2 = size(X2)[2]
  # Create weight matrix
  mu = mu * (sum(W1) + sum(W2))/(2 * sum(W12))
  W = rbind(cbind(W1, mu * W12), cbind(mu * t(W12), W2))
  L = graph_laplacian(W)
  rm(W1, W2, W12)
  # prepare for decomposition
  Z = cbind(rbind(X1, matrix(0, M2, P1)), rbind(matrix(0, M1, P2), X2))
  svd_Z = svd(crossprod(Z))
  Fplus = as.numeric( svd_Z$u %*% sqrt(diag(svd_Z$d)) )
  Fplus = matrix(Fplus, ncol = sqrt(length(Fplus)))
  Fplus = pinv(Fplus)
  TT = Fplus %*% t(Z) %*% L %*% Z %*% t(Fplus)
  rm(svd_Z, Z, W, L)
  # Eigen decomposition
  output = eigen( (TT + t(TT))/2, only.values = FALSE)
  vecs = output$vectors
  vals = output$values
  output2 = sort(vals, index.return = TRUE)
  vecs = t(Fplus) %*% vecs[, output2$ix]
  rm(TT, Fplus)
  # for (i in 1:ncol(vecs)){
  #   vecs[, i] = vecs[, i]/norm(vect[, i], 2)
  #}
  vecs = t( t(vecs)/sqrt(colSums(vecs^2)) )
  # filter out eigenvalues that are ~= 0
  for (i in 1:length(vals)){
    if (vals[i] > epsilon){
      break
    }
  }
  # Compute mappings
  start = i
  m = min(max_dim, ncol(vecs) - start +1)
  map1 = vecs[1:P1, start:(start+m-1)]
  map2 = vecs[(P1+1):(P1+P2), start:(start+m-1)]
  # output : map1 and map2
  return(list(map1 = map1, map2 = map2))
}
