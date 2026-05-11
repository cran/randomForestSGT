get.beta <- function(o, bag = c("inbag", "oob", "all")[1], papply = lapply) {
  ## pull the native array and get beta and related values
  nativeArray <- o$forest$nativeArray
  betaNative <- as.matrix(nativeArray[, !(colnames(nativeArray) %in%
       c("treeID", "nodeID", "nodeSZ", "brnodeID", "yStar", "yBar", "prnodeID")), drop = FALSE])
  ybar <- nativeArray[, "yBar"]
  ystar <- nativeArray[, "yStar"]
  ## embedded split information for CART terminal nodes
  betaZNative <- betaNative[, -1, drop = FALSE]
  betaZ.pt <- nativeArray$brnodeID == 0 & is.na(ystar) & !is.na(ybar)
  betaZNative[!betaZ.pt, ] <- NA
  betaZNative[betaZ.pt, ] <- ybar[betaZ.pt] * (betaZNative[betaZ.pt, ] != 0)
  ## pull the terminal node offsets by case id
  ## depends on grow/predict mode
  if (isTRUE(inherits(o, "grow"))) {
    idx <- o$forest$ambrOffset
  }
  else if (isTRUE(inherits(o, "predict"))) {
    idx <- o$ambrOffset
  }
  else {
    stop("class structure is wrong in get.beta:", class(o), "\n")
  }
  ## set the bag type
  if (is.null(o$membership)) {
    bag <- "all"
  }
  ## helper used when a non-default papply is supplied
  pull.tree.beta <- function(b) {
    tree.idx <- idx[, b]
    tree.ybar <- ybar[tree.idx]
    cart <- !is.na(tree.ybar)    ## yBar != NA --> CART split
    beta <- betaNative[tree.idx, , drop = FALSE]
    betaZ <- betaZNative[tree.idx, , drop = FALSE]
    if (any(cart)) {
      beta[cart, ] <- 0
      beta[cart, 1] <- tree.ybar[cart]
    }
    if (bag == "all") {
      ## no bag filtering
    }
    else if (bag == "inbag") {
      omit <- o$inbag[, b] == 0
      if (any(omit)) {
        beta[omit, ] <- NA
        betaZ[omit, ] <- NA
      }
    }
    else { ## oob
      omit <- o$inbag[, b] != 0
      if (any(omit)) {
        beta[omit, ] <- NA
        betaZ[omit, ] <- NA
      }
    }
    list(beta = beta, betaZ = betaZ)
  }
  if (identical(papply, lapply)) {
    ## Default path: accumulate elementwise sums and non-NA counts directly.
    ## This avoids forked parallelism, avoids storing one matrix per tree, and is usually
    ## faster/more memory efficient than building blist and reducing it later.
    beta.sum <- matrix(0, nrow = nrow(idx), ncol = ncol(betaNative))
    beta.n <- matrix(0L, nrow = nrow(idx), ncol = ncol(betaNative))
    betaZ.sum <- matrix(0, nrow = nrow(idx), ncol = ncol(betaZNative))
    betaZ.n <- matrix(0L, nrow = nrow(idx), ncol = ncol(betaZNative))
    for (b in seq_len(o$ntree)) {
      tree.idx <- idx[, b]
      tree.ybar <- ybar[tree.idx]
      cart <- !is.na(tree.ybar)    ## yBar != NA --> CART split
      beta <- betaNative[tree.idx, , drop = FALSE]
      betaZ <- betaZNative[tree.idx, , drop = FALSE]
      if (any(cart)) {
        beta[cart, ] <- 0
        beta[cart, 1] <- tree.ybar[cart]
      }
      if (bag == "all") {
        ## no bag filtering
      }
      else if (bag == "inbag") {
        omit <- o$inbag[, b] == 0
        if (any(omit)) {
          beta[omit, ] <- NA
          betaZ[omit, ] <- NA
        }
      }
      else { ## oob
        omit <- o$inbag[, b] != 0
        if (any(omit)) {
          beta[omit, ] <- NA
          betaZ[omit, ] <- NA
        }
      }
      beta.ok <- !is.na(beta)
      if (all(beta.ok)) {
        beta.sum <- beta.sum + beta
        beta.n <- beta.n + 1L
      }
      else if (any(beta.ok)) {
        beta.sum[beta.ok] <- beta.sum[beta.ok] + beta[beta.ok]
        beta.n[beta.ok] <- beta.n[beta.ok] + 1L
      }
      betaZ.ok <- !is.na(betaZ)
      if (all(betaZ.ok)) {
        betaZ.sum <- betaZ.sum + betaZ
        betaZ.n <- betaZ.n + 1L
      }
      else if (any(betaZ.ok)) {
        betaZ.sum[betaZ.ok] <- betaZ.sum[betaZ.ok] + betaZ[betaZ.ok]
        betaZ.n[betaZ.ok] <- betaZ.n[betaZ.ok] + 1L
      }
    }
    beta <- beta.sum / beta.n
    betaZ <- betaZ.sum / betaZ.n
  }
  else {
    ## Backward-compatible path for callers that pass a custom papply.
    ## matrixMeans is now serial and CRAN-safe. Users can still opt into
    ## their own parallel papply.
    blist <- papply(seq_len(o$ntree), pull.tree.beta)
    beta <- matrixMeans(lapply(blist, "[[", "beta"))
    betaZ <- matrixMeans(lapply(blist, "[[", "betaZ"))
  }
  colnames(beta) <- c("betaZ", o$xvar.names, o$xvar.augment.names)
  colnames(betaZ) <- c(o$xvar.names, o$xvar.augment.names) 
  rownames(beta) <- rownames(betaZ) <- NULL
  ## build the x design matrix
  x <- cbind(1, as.matrix(o$xvar))
  if (!is.null(o$xvar.augment.names)) {
    x <- cbind(x, as.matrix(o$xvar.augment))
  }
  ## add useful attributes
  lasso.percent <- 100 * mean(is.na(ystar[nativeArray$brnodeID == 0]) & is.na(ybar[nativeArray$brnodeID == 0]))
  predicted <- rowSums(x * beta, na.rm = TRUE)
  partial <- x * beta
  ## return the goodies
  list(beta = beta,
       betaZ = betaZ,
       lasso.percent = lasso.percent,
       predicted = predicted,
       partial = partial)
}
## calculates elementwise mean of a list of matrices with NA's ignored
matrixMeans <- function(mm) {
  if (!is.list(mm) || length(mm) == 0L) {
    stop("mm must be a non-empty list of matrices")
  }
  first <- as.matrix(mm[[1L]])
  d <- dim(first)
  if (length(d) != 2L) {
    stop("all elements of mm must be two-dimensional")
  }
  total <- matrix(0, nrow = d[1L], ncol = d[2L], dimnames = dimnames(first))
  count <- matrix(0L, nrow = d[1L], ncol = d[2L], dimnames = dimnames(first))
  for (i in seq_along(mm)) {
    x <- if (i == 1L) first else as.matrix(mm[[i]])
    if (!identical(dim(x), d)) {
      stop("all matrices in mm must have the same dimensions")
    }
    ok <- !is.na(x)
    if (all(ok)) {
      total <- total + x
      count <- count + 1L
    }
    else if (any(ok)) {
      total[ok] <- total[ok] + x[ok]
      count[ok] <- count[ok] + 1L
    }
  }
  total / count
}
