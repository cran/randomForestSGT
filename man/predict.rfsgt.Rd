\name{predict.rfsgt}
\alias{predict.rfsgt}
\title{Prediction on Test Data for Super Greedy Forests}

\description{
  Obtain predicted values on test data using a trained super greedy
  forest.
}

\usage{\method{predict}{rfsgt}(object, newdata,  get.tree = NULL,
     block.size = 10, seed = NULL, do.trace = FALSE,...)}

\arguments{
  
  \item{object}{rfsgt object obtained from previous training call using
    \code{rfsgt}.}
  
  \item{newdata}{Test data. If not provided the training data is used
  and the original training forest is restored.}

 
  \item{get.tree}{Vector of integer(s) identifying trees over which the
    ensemble is calculated over.  By default, uses all trees in the
    forest.}

  \item{block.size}{Determines how cumulative error rate is calculated.  To
    obtain the cumulative error rate on every nth tree, set the value to
    an integer between 1 and \code{ntree}.}

  \item{seed}{Negative integer specifying seed for the random number
    generator.}

  \item{do.trace}{Number of seconds between updates to the user on
    approximate time to completion.}

  
  \item{...}{Additional options.}

}

\details{

  Returns the predicted values for a super greedy forest.
  
}

\value{

  An object of class \code{c("rfsgt", "predict", family)} containing
  predictions and prediction-time summaries.  When \code{newdata} is
  omitted, the object corresponds to the restored training forest; when
  \code{newdata} is supplied, it corresponds to predictions on the new
  data.  The returned list contains:

  \describe{

    \item{\code{call}}{The matched prediction call.}

    \item{\code{family}}{Model family inherited from the fitted
      \code{rfsgt} object.}

    \item{\code{n}}{Number of observations predicted.}

    \item{\code{samptype}}{Sampling type inherited from the fitted
      forest.}

    \item{\code{sampsize}}{Tree sample size inherited from the fitted
      forest.}

    \item{\code{ntree}}{Number of trees in the fitted forest.}

    \item{\code{hcut}}{\code{hcut} value used by the fitted forest.}

    \item{\code{splitrule}}{Split rule used by the fitted forest.}

    \item{\code{yvar}}{Response values used for prediction-error
      calculation.  This is the training response in restore mode, the
      response from \code{newdata} when present, and \code{NULL} when
      \code{newdata} has no response column.}

    \item{\code{yvar.names}}{Response variable name from the fitted
      forest.}

    \item{\code{xvar}}{Predictor data used for prediction, after applying
      the same encoding and filtering as in training.}

    \item{\code{xvar.augment}}{Augmented base-learner data used for
      prediction, or \code{NULL} when no augmented terms are used.}

    \item{\code{xvar.names}}{Names of the retained predictor variables.}

    \item{\code{xvar.augment.names}}{Names of augmented base-learner
      terms, or \code{NULL} when no augmented terms are used.}

    \item{\code{xvar.info}}{Predictor-encoding metadata used to align
      new data with the training design.}

    \item{\code{term.map}}{Term map describing generated base-learner
      terms.}

    \item{\code{leaf.count}}{Number of terminal nodes in each tree.}

    \item{\code{forest}}{Stored forest object used to make the
      predictions.}

    \item{\code{membership}}{Matrix of terminal-node membership by
      observation and tree when membership output is requested; otherwise
      \code{NULL}.}

    \item{\code{inbag}}{Matrix of bootstrap membership counts in restore
      mode when membership output is requested; otherwise \code{NULL}.}

    \item{\code{block.size}}{Block size used for cumulative prediction
      error calculations.}

    \item{\code{perf.type}}{Internal performance-measure type used for
      prediction-error calculation.}

    \item{\code{predicted}}{Ensemble predicted values.}

    \item{\code{predicted.oob}}{Out-of-bag predictions in restore mode
      when available; otherwise \code{NULL}.}

    \item{\code{ambrOffset}}{Terminal-node offset matrix used internally
      to recover local terminal-node quantities for new observations;
      \code{NULL} in restore mode.}

    \item{\code{err.rate}}{Prediction error when response values are
      available; otherwise \code{NULL}.}

    \item{\code{ctime.internal}}{Timing information reported by the
      native prediction routine.}

    \item{\code{ctime.external}}{Elapsed R-side timing, computed from
      \code{proc.time()}.}

  }

}

\author{

  Hemant Ishwaran and Udaya B. Kogalur

}

\references{

 Ishwaran H. (2025).  Super greedy trees.  To appear in Artifical
 Intelligence Review.


}

\seealso{
  \command{\link{rfsgt}}
}

\examples{

## ------------------------------------------------------------
##
##  mtcars: for CRAN testing
##
## ------------------------------------------------------------

o <- rfsgt(mpg~., mtcars[1:20,], ntree=3, treesize=1)
p <- predict(o, mtcars[-(1:20),])
print(o)
print(p)



\donttest{
## ------------------------------------------------------------
##
## train/test using friedman 3
##
## ------------------------------------------------------------

if (requireNamespace("mlbench", quietly = TRUE)) {

  ## train/test using Friedman 3
  d.trn <- data.frame(mlbench::mlbench.friedman3(100))
  o <- rfsgt(y ~ ., d.trn, hcut = 1, ntree = 3, treesize = 1)
  print(o)

  d.tst <- data.frame(mlbench::mlbench.friedman3(200))
  y.tst <- d.tst$y
  x.tst <- d.tst[, colnames(d.tst) != "y"]
  yhat <- predict(o, x.tst)$predicted
  mean((yhat - y.tst)^2)

## train sgf on friedman 3
d.trn <- data.frame(mlbench::mlbench.friedman3(500))
o <- rfsgt(y~.,d.trn, hcut=1)
print(o)

## test sgf
d.tst <- data.frame(mlbench::mlbench.friedman3(1000))
y.tst <- d.tst$y
x.tst <- d.tst[, colnames(d.tst)!= "y"]
yhat <- predict(o, x.tst)$predicted
cat("test set mse:", mean((yhat - y.tst)^2), "\n")

## ------------------------------------------------------------
##
## restore a trained super greedy forest using boston
##
## ------------------------------------------------------------

## run sgf on boston
data(BostonHousing, package = "mlbench")
o <- rfsgt(medv~., BostonHousing)
print(o)

## restore the forest
print(predict(o))

## ------------------------------------------------------------
##
## coherence check using boston housing with factors
##
## ------------------------------------------------------------

## boston housing data: make factors
data(BostonHousing, package = "mlbench")
Boston <- BostonHousing[1:40,]
Boston$zn <- factor(Boston$zn)
Boston$chas <- factor(Boston$chas)
Boston$lstat <- factor(round(0.2 * Boston$lstat))
Boston$nox <- factor(round(20 * Boston$nox))
Boston$rm <- factor(round(Boston$rm))
     
## grow a single tree - save inbag information
o <- rfsgt(medv~., Boston, hcut=2, filter=FALSE, ntree=1, membership=TRUE, nodesize=3)

## coherence matrix
pred <- data.frame(
      inbag=o$inbag,
      pred.inb=o$predicted,
      pred.oob=o$predicted.oob,
      pred.inb.restore=predict(o)$predicted,
      pred.oob.restore=predict(o)$predicted.oob,
      pred.test=predict(o,Boston)$predicted)
print(pred)

## coherence check
cat("coherence for inbag data:", sum(pred$pred.inb-pred$pred.test,na.rm=TRUE)==0, "\n")
cat("  coherence for oob data:", sum(pred$pred.oob-pred$pred.test,na.rm=TRUE)==0, "\n")


## canonical example of train/test with prediction
trn <- sample(1:nrow(Boston), nrow(Boston)/2, replace=FALSE)
o.trn <- rfsgt(medv~., Boston[trn,], hcut=2)
predict(o.trn,Boston[-trn,])


## ------------------------------------------------------------
## prediction using tuning hcut and pre-filtering with tune.hcut 
## ------------------------------------------------------------

## fit the forest to the tuned hcut
dta <- data.frame(mlbench::mlbench.friedman3(500))
f <- tune.hcut(y~., dta, hcut=5, verbose=TRUE)
o <- rfsgt(y~., dta, filter=f)
print(o)

## test the tuned forest on new data
print(predict(o, data.frame(mlbench::mlbench.friedman3(25000))))

## over-ride the optimized hcut
o2 <- rfsgt(y~., dta, filter=use.tune.hcut(f, hcut=2))
print(o2)
print(predict(o2, data.frame(mlbench::mlbench.friedman3(25000))))

}
}
}

\keyword{predict rfsgt}
