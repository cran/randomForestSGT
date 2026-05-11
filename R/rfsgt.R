rfsgt <- function(formula,
                  data,
                  ntree = if (hcut==0) 500 else 100,
                  hcut = 1,
                  treesize = NULL,
                  nodesize = NULL,
                  filter = (hcut > 1),
                  bsf = if (hcut > 0) "oob" else "inbag",
                  keep.only = NULL,
                  fast = TRUE,
                  pure.lasso = FALSE,
                  eps = .005,
                  maxit = 500,
                  nfolds = 10,
                  block.size = 10,
                  bootstrap = c("by.root", "none", "by.user"),
                  samptype = c("swor", "swr"),  samp = NULL, membership = TRUE,
                  sampsize = if (samptype == "swor") function(x){x * .632} else function(x){x},
                  seed = NULL,
                  do.trace = FALSE,
                  ...
                  )
{
  bootstrap <- match.arg(bootstrap, c("by.root", "none", "by.user"))
  samptype <- match.arg(samptype, c("swor", "swr"))
  ## default bsf depends on the effective hcut, which can be supplied
  ## indirectly when filter is of type "tune.hcut"
  if (missing(bsf)) {
    if (inherits(filter, "tune.hcut") && !is.null(attr(filter, "bsf"))) {
      bsf <- attr(filter, "bsf")
    }
    else {
      hcut.bsf <- hcut
      if (inherits(filter, "tune.hcut") && !is.null(attr(filter, "hcut"))) {
        hcut.bsf <- attr(filter, "hcut")
      }
      bsf <- if (hcut.bsf > 0) "oob" else "inbag"
    }
  }
  bsf <- get.bsf(bsf, default = if (hcut > 0) "oob" else "inbag", warn = TRUE)
  rO <- do.call("rfsgt.workhorse", c(list(
                  formula=formula,
                  data=data,
                  ntree = ntree,
                  hcut = hcut,
                  treesize = treesize,
                  nodesize = nodesize,
                  filter = filter,
                  bsf = bsf,
                  keep.only = keep.only,
                  fast = fast,
                  pure.lasso = pure.lasso,
                  eps = eps,
                  maxit = maxit,
                  nfolds = nfolds,
                  block.size = block.size,
                  bootstrap = bootstrap,
                  samptype = samptype,
                  samp = samp,
                  membership = membership,
                  sampsize = sampsize,
                  seed = seed,
                  do.trace = do.trace),
                  list(...)))
  ## save xvar information needed later by predict.rfsgt
  if (!is.null(attr(rO$xvar, "hotencode"))) {
    if (!is.null(rO$term.map)) {
      xvar.info.names <- get.term.map.parents(rO$term.map, type = "xvar.org.names")
    }
    else {
      xvar.info.names <- get.hotencode.filter(rO$xvar,
                                              unique(c(rO$xvar.names, rO$xvar.augment.names)))
    }
    if (length(xvar.info.names) == 0) {
      xvar.info.names <- get.hotencode.filter(rO$xvar,
                                              unique(c(rO$xvar.names, rO$xvar.augment.names)))
    }
    rO$xvar.info <- get.hotencode.info(rO$xvar, xvar.info.names)
  }
  ## restore xvar quantities that are over-ridden during filtering
  if ((is.logical(filter) && filter == TRUE) || inherits(filter, "tune.hcut")) {
    rO$xvar.names <- colnames(rO$xvar)
    rO$xvar.types <- rep("R", ncol(rO$xvar))
    rO$xvar.nlevels <- rep(0, ncol(rO$xvar))
  }
  ## return the goodies
  rO
}
