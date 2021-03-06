#' Print estimates of difference and ratio effects obtained in the bootstrap computations of the g-computation
#'
#' @description Print results from bootstrap computations of the g-computation
#'
#' @param gComp.res an object of class\code{gComp} with R bootstrap iterations of a parameter estimate for difference and ratio.
#' @param 
#' 
#' @value the resulting point estimate and 95% confidence intervals of the difference and ratio estimates returned from R bootstrap iterations
#' @export
#'
#' @examples
#' ## Obtain the risk difference and risk ratio for cardiovascular disease or death 
#' ## between patients with and without diabetes, while controlling for 
#' ## age,
#' ## sex, 
#' ## BMI, 
#' ## whether the individual is currently a smoker, and 
#' ## if they have a history of hypertension. 
#' data(cvdd)
#' diabetes.result <- gComp(data = cvdd, Y = "cvd_dth", X = "DIABETES", 
#' Z = c("AGE", "SEX", "BMI", "CURSMOKE", "PREVHYP"), family = "binomial", R = 10)
#' print(diabetes.result)
#' 
#'
#' @keywords print.gComp




print.gComp <- function(gComp.res) {
  print(gComp.res$summary)
  
}
