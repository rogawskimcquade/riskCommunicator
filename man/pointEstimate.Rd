% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pointEstimate.R
\name{pointEstimate}
\alias{pointEstimate}
\title{Perform g-computation to estimate difference and ratio effects of an outcome.type exposure}
\usage{
pointEstimate(
  data,
  formula = NULL,
  Y = NULL,
  X = NULL,
  Z = NULL,
  outcome.type = c("binary", "count", "rate", "continuous"),
  offset = NULL,
  rate.multiplier = 1,
  subgroup = NULL
)
}
\arguments{
\item{data}{the data as a data.frame or tibble containing variables for \code{Y}, \code{X}, and \code{Z} or with variables matching the model variables specified in a user-supplied formula.}

\item{formula}{optional argument which provides the model formula for the \code{glm} function to be used internally. The first predictor (after the "~") is assumed to be the exposure variable.
Can be supplied as a character or formula object, the function will internally convert it to a formula if not supplied as such. 
If no formula is provided, Y and X must be provided.}

\item{Y}{optional character argument which provides the response variable that will be supplied to the \code{glm} function internally.
Must also provide \code{X} in order for the function to work.  Can optionally provide a formula instead of \code{Y} and \code{X} variables.}

\item{X}{optional character argument which provides the binary exposure/treatment group assignment that will be supplied to the \code{glm} function internally.
This variable can be supplied as a factor variable or as a numeric of 0 or 1. Must also provide \code{Y} in order for the function to work.  
Can optinoally provide a formula instead of \code{Y} and \code{X} variables.}

\item{Z}{optional argument which provides the covariates or other variables to adjust for in the \code{glm} function to be used internally.
Can be either a single character expression or vector of quoted variable names.}

\item{outcome.type}{required argument to describe the outcome type. Acceptable responses include "binary", "count", "rate", and "continuous". 
This argument is used to determine the error distribution and link function to be used in the model when calling the \code{glm} function internally. Default is "binary'
For "binary" a binomial distribution with link = 'logit' is used, 
for "count" or "rate" a Poisson distribution with link = 'log' is used, 
for "continuous" a gaussian distribution with link = 'identity' is used.}

\item{offset}{character argument which identifies the variable to use for offset. Required if using outcome.type of "rate". Default is NULL. 
Internal functions automatically convert offset to log scale, so should be provided in original units.}

\item{rate.multiplier}{optional numeric argument to identify the multiplier to provide rate outcome in desired units. Only used if outcome.type == "rate." 
For example, the rate for an offset provided in days could be converted to years by supplying rate.multiplier = 365. 
#' @return a list containing the following:
\itemize{
\item{"Risk Difference"} {point estimate of the risk difference for binary outcomes, will be NA for other outcome types}
\item{"Risk Ratio"} {point estimate of the risk ratio for binary outcomes, will be NA for other outcome types}
\item{"Odds Ratio"} {point estimate of the odds ratio for binary outcomes, will be NA for other outcome types}
\item{"Incidence Rate Difference"} {point estimate of the rate difference for rate outcomes, will be NA for other outcome types}
\item{"Incidence Rate Ratio"} {point estimate of the rate ratio for rate outcomes, will be NA for other outcome types}
\item{"Marginal Difference"} {point estimate of the marginal difference for continuous or count outcomes, will be NA for other outcome types}
\item{"Number needed to treat"} {1/(Risk Difference) for binary outcomes, 1/(Incidence Rate Difference) for rate outcomes, will be NA for other outcome types}
\item{"n} {number of observations provided to the model}
\item{"contrast"} {the contrast levels compared}
\item{"family"} {the error distribution used in the model}
\item{"formula"} {the model formula used to fit the \code{glm}}
\item{"Y"} {the response variable}
\item{"covariates"} {covariates used in the model}
\item{"predictedData"} {a tibble with the predicted values for the naturnal course, and both treatment and no treatment counterfactual predicitions for each observation in the original dataset}
}}
}
\description{
Generate a point estimate of the outcome difference and ratio
}
\examples{
## Obtain the risk difference and risk ratio for cardiovascular disease or death 
## between patients with and without diabetes, while controlling for
## age, 
## sex, 
## BMI, 
## whether the individual is currently a smoker, and
## if they have a history of hypertension. 
data(cvdd)
ptEstimate <- pointEstimate(data = cvdd, Y = "cvd_dth", X = "DIABETES", 
Z = c("AGE", "SEX", "BMI", "CURSMOKE", "PREVHYP"), outcome.type = "binary")

}
\keyword{pointEstimate}
