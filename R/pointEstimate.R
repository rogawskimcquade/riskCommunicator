#' Perform g-computation to estimate difference and ratio effects of an outcome.type exposure
#'
#' @description Generate a point estimate of the outcome difference and ratio
#'
#' @param data (Required) A data.frame or tibble containing variables for \code{Y}, \code{X}, and \code{Z} or with variables matching the model variables specified in a user-supplied formula. Data set should also contain variables for the optinal \code{subgroup} and \code{offset}, if they are specified 
#' @param outcome.type (Required) Character argument to describe the outcome type. Acceptable responses, and the corresponding error distribution and link function used in the \code{glm}, include:
#'  \describe{
#'  \item{binary}{(Default) A binomial distribution with link = 'logit' is used.}
#'  \item{count}{A Poisson distribution with link = 'log' is used.}
#'  \item{rate}{A Poisson distribution with link = 'log' is used.}
#'  \item{continuous}{A gaussian distribution with link = 'identity' is used.} 
#' }
#' @param formula (Optional) Default NULL. An object of class "formula" (or one that can be coerced to that class) which provides the the complete model formula, similar to the formula for the glm function in R (e.g. `Y ~ X + Z1 + Z2 + Z3`). 
#' Can be supplied as a character or formula object. If no formula is provided, Y and X must be provided.
#' @param Y (Optional) Default NULL. Character argument which specifies the outcome variable. Can optionally provide a formula instead of \code{Y} and \code{X} variables.
#' @param X (Optional) Default NULL. Character argument which specifies the exposure variable (or treatment group assignment), which can be binary, categorical, or continuous. This variable can be supplied as a factor variable, a numeric variable coded 0 or 1, or a continuous variable. 
#' Preferrably, \code{X} is supplied as a factor with the lowest level set to the desired comparator. 
#' Numeric variables are accepted, and coerced to factor with lowest level being the smallest number. 
#' Character variables are not accepted and will throw an error.
#' Can optionally provide a formula instead of \code{Y} and \code{X} variables. 
#' @param Z (Optional) Default NULL. List or single character vector which specifies the names of covariates or other variables to adjust for in the \code{glm} function to be used internally. Does not allow interaction terms.
#' @param subgroup (Optional) Default NULL. Character argument that indicates subgroups for stratified analysis. Effects will be reported for each category of the subgroup variable. Variable will be automatically converted to a factor if not already.  
#' @param offset (Optional, only applicable for rate outcomes) Default NULL. Character argument which specifies the person-time denominator for rate outcomes to be included as an offset in the Poisson regression model. Numeric variable should be on the linear scale; function will take natural log before including in the model.
#' @param rate.multiplier (Optional, only applicable for rate outcomes) Default 1. Numeric value to multiply to the rate-based effect measures. This option facilitates reporting effects with interpretable person-time denominators. For example, if the person-time variable (offset) is in days, a multiplier of 365*100 would result in estimates of rate differences per 100 person-years.
#' 
#' @return A list containing the following:
#' \itemize{
#' \item{"parameter.estimates"} {point estimates for the risk difference, risk ratio, odds ratio, incidence rate difference, indicence rate ratio, mean difference and/or number needed to treat, depending on the outcome.type}
#' \item{"n} {number of observations provided to the model}
#' \item{"contrast"} {the contrast levels compared}
#' \item{"family"} {the error distribution used in the model}
#' \item{"formula"} {the model formula used to fit the \code{glm}}
#' \item{"Y"} {the response variable}
#' \item{"covariates"} {covariates used in the model}
#' \item{"predicted.data"} {a tibble with the predicted values for the naturnal course, and both treatment and no treatment counterfactual predicitions for each observation in the original dataset}
#' }
#'   
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
#' ptEstimate <- pointEstimate(data = cvdd, Y = "cvd_dth", X = "DIABETES", 
#' Z = c("AGE", "SEX", "BMI", "CURSMOKE", "PREVHYP"), outcome.type = "binary")
#' 
#' @importFrom tidyselect one_of contains all_of
#' @importFrom stats as.formula glm model.matrix contrasts binomial na.omit predict
#' @importFrom dplyr expr select mutate select_if select_at rowwise funs vars        
#' @importFrom tibble as_tibble tibble
#' @importFrom rlang sym .data
#' @importFrom magrittr %>%
#' @importFrom purrr negate
#'
#' @keywords pointEstimate



pointEstimate <- function(data, 
                          outcome.type = c("binary", "count","rate", "continuous"),
                          formula = NULL, 
                          Y = NULL, 
                          X = NULL, 
                          Z = NULL, 
                          subgroup = NULL,  
                          offset = NULL, 
                          rate.multiplier = 1) {
  # data = cvdd
  # Y = "cvd_dth"
  #  X = "DIABETES"
  #  Z = c("AGE", "SEX", "BMI", "CURSMOKE", "PREVHYP")
  # X = "bmicat"
  # Z = c("AGE", "SEX", "DIABETES", "CURSMOKE", "PREVHYP")
  # outcome.type = "binary"
  # offset = NULL
  # rate.multiplier = 1
  # subgroup = "SEX"
  # formula = NULL

  outcome.type <- match.arg(outcome.type)
  
  if (outcome.type %in% c("binary")) {
    family <- stats::binomial(link = 'logit')
  } else if (outcome.type %in% c("count", "rate")) {
    family <- stats::poisson(link = "log")
    if (is.null(offset) & outcome.type == "rate") stop("Offset must be provided for rate outcomes")
  } else if (outcome.type == "continuous") {
    family <- stats::gaussian(link = "identity")
  } else {
    stop("This package only supports binary/dichotomous, count/rate, or continuous outcome variable models")
  }

  if (!is.null(X)) X <- rlang::sym(X)
  if (is.null(formula)) {
    if (is.null(Y) | is.null(X)) {
      stop("No formula, or Y and X variables provided") 
    }
    if (is.null(Z)) {
      formula <- Y ~ X
    } else {
      formula <- stats::as.formula(paste(paste(Y,X, sep = " ~ "), paste(Z, collapse = " + "), sep = " + "))   
    }
  } else {
    formula = stats::as.formula(formula)
    if (any(unlist(sapply(formula[[3]], function(x) grepl(":", x)))) | any(unlist(sapply(formula[[3]], function(x) grepl("\\*", x))))) {
      stop("g-computation function not currently able to handle interaction terms")
    } 
    Y <- as.character(formula[[2]])
    X <- rlang::sym(all.vars(formula[[3]])[1])
    Z <- all.vars(formula[[3]])[-1]
  }
  
  if (!is.null(subgroup)) {
    interaction_term <- rlang::sym(paste(as.character(X), subgroup, sep = ":"))
    formula <- stats::as.formula(paste(paste(Y,X, sep = " ~ "), paste(Z, collapse = " + "), interaction_term, sep = " + "))
    
  }
  
  
  #Ensure all variables are in the dataset
  if (is.null(offset) & is.null(subgroup)) {
    allVars <- unlist(c(Y, as.character(X), Z))
  } else if (!is.null(offset)) {
    offset <- rlang::sym(offset)
    # data <- data %>%
    #   dplyr::mutate(!!offset := !!offset + 0.00001)
    if (!is.null(subgroup)){
      subgroup <- rlang::sym(subgroup)
      allVars <- unlist(c(Y, as.character(X), Z, offset, subgroup))
    } else {
      allVars <- unlist(c(Y, as.character(X), Z, offset))
    }
  } else {
    subgroup <- rlang::sym(subgroup)
    allVars <- unlist(c(Y, as.character(X), Z, subgroup))
  }
  
  if (!all(allVars %in% names(data))) stop("One or more of the supplied model variables, offset, or subgroup is not included in the data")
  
  if (!is.null(X)) {
    X_type <- ifelse(is.factor(data[[X]]), "categorical", ifelse(is.numeric(data[[X]]), "numeric", stop("X must be a factor or numeric variable")))
    if (X_type == "numeric") {
      message("Proceeding with X as a continuous variable, if it should be categorical, please reformat so that X is a factor variable")
      # if (nlevels(eval(dplyr::expr(`$`(data, !!X)))) != 2) {
      #   stop("Explanatory variable has more than 2 levels")
      # }
    } #else {
    #   # if (length(unique((eval(dplyr::expr(`$`(data, !!X)))))) == 2) {
    #     ### could write more code to throw an error if the different values are not 0 or 1
    #     data <- data %>% 
    #       dplyr::mutate(!!X := factor(!!X))
    #   # } else {
    #     # stop("Explanatory variable has more than 2 levels")
    #   #}
    # }
  }
  
  # Ensure Z covariates are NOT character variables in the dataset
  if (!is.null(Z)) {
    test_for_char_df <- sapply(data %>% 
      dplyr::select(tidyselect::all_of(Z)), is.character)
    if (any(test_for_char_df)) {
      stop("One of the covariates (Z) is a character variable in the dataset provided.  Please change to a factor or numeric.")
    }
  }
  
  if (!is.null(subgroup)) {
    data <- data %>% 
      dplyr::mutate(!!subgroup := factor(!!subgroup))
  }
  
  
  ## Run GLM
  if (!is.null(offset)) {
    data <- data %>%
      dplyr::mutate(offset2 = !!offset + 0.00001)
    glm_result <- stats::glm(formula = formula, data = data, family = family, na.action = stats::na.omit, offset = log(offset2))
  } else {
    glm_result <- stats::glm(formula = formula, data = data, family = family, na.action = stats::na.omit)
  }
  
  fn_output <- make_predict_df(glm.res = glm_result, df = data, X = X, subgroup = subgroup)
  results_tbl_all <- NULL
  exposure_list <- unique(unlist(stringr::str_split(names(fn_output), "_"))) %>%
    stringr::str_subset(pattern = as.character(X))
  
  if (!is.null(subgroup)) {
    subgroups_list <- unique(unlist(stringr::str_split(names(fn_output), "_"))) %>%
      stringr::str_subset(pattern = as.character(subgroup))
    if (length(exposure_list) > 2) {
      contrasts_list <- lapply(exposure_list[-1], function(x) paste0(x, "_v._", exposure_list[1]))
      subgroup_contrasts_res <- purrr::map_dfc(exposure_list[-1], function(e) {
        predict_df_e <- fn_output %>%
          dplyr::select(tidyselect::contains(exposure_list[1]), tidyselect::contains(e))
        subgroup_res <- purrr::map_dfc(subgroups_list, function(s) {
          predict_df_s = fn_output %>% 
            dplyr::select(tidyselect::contains(s))
          fn_results_tibble <- get_results_tibble(predict.df = predict_df_s, outcome.type = outcome.type, X = X, rate.multiplier = rate.multiplier)
          tbl_s <- fn_results_tibble[[1]]
          names(tbl_s) <- 
            x <- c(paste0("predicted risk with ", exposure_list[1], ", ", s), paste0("predicted risk with ", e, ", ", s), paste0("pred odds with ", exposure_list[1], ", ", s), paste0("pred odds with ", e, ", ", s))
          results_tbl_all <<- results_tbl_all %>%
            dplyr::bind_cols(tbl_s)
          return(fn_results_tibble[[2]])
        })
        subgp_results <- subgroup_res %>%
          as.data.frame()
        colnames(subgp_results) <- paste0(e, "_v._", exposure_list[1],"_", subgroups_list)
        return(subgp_results)
      })
      results <- subgroup_contrasts_res
    } else {
      subgroup_res <- purrr::map_dfc(subgroups_list, function(s) {
        # s <- subgroups_list[1]
        predict_df_s = fn_output %>% 
          dplyr::select(tidyselect::contains(s))
        fn_results_tibble <- get_results_tibble(predict.df = predict_df_s, outcome.type = outcome.type, X = X, rate.multiplier = rate.multiplier)
        tbl_s <- fn_results_tibble[[1]]
        pred_names <- c(sapply(exposure_list, function(x) paste0("predicted risk with ",x, ", ", s)), sapply(exposure_list, function(x) paste0("predicted odds with ",x, ", ", s)))
        names(tbl_s) <- pred_names
        results_tbl_all <<- results_tbl_all %>%
          dplyr::bind_cols(tbl_s)
        return(fn_results_tibble[[2]])
      })
      results <- subgroup_res %>%
        as.data.frame()
      colnames(results) <- subgroups_list
    }
  } else if (length(exposure_list) > 2) {
    contrasts_list <- lapply(exposure_list[-1], function(x) paste0(x, "_v._", exposure_list[1]))
    contrasts_res <- purrr::map_dfc(exposure_list[-1], function(e) {
      # e <- exposure_list[2]
      predict_df_e <- fn_output %>%
        dplyr::select(tidyselect::contains(exposure_list[1]), tidyselect::contains(e))
      fn_results_tibble <- get_results_tibble(predict.df = predict_df_e, outcome.type = outcome.type, X = X, rate.multiplier = rate.multiplier)
      tbl_e <- fn_results_tibble[[1]]
      pred_names <- c(paste0("predicted risk with ", exposure_list[1]), paste0("predicted risk with ", e), paste0("pred odds with ", exposure_list[1]), paste0("pred odds with ", e))
      names(tbl_e) <- pred_names
      results_tbl_all <<- results_tbl_all %>%
        dplyr::bind_cols(tbl_e)
      return(fn_results_tibble[[2]])
    })
    results <- contrasts_res %>%
      as.data.frame()
    colnames(results) <- contrasts_list
  } else {
    fn_results_tibble <- get_results_tibble(predict.df = fn_output, outcome.type = outcome.type, X = X, rate.multiplier = rate.multiplier)
    tbl <- fn_results_tibble[[1]]
    pred_names <- c(sapply(exposure_list, function(x) paste0("predicted risk with ",x)), sapply(exposure_list, function(x) paste0("pred odds with ",x)))
    names(tbl) <- pred_names
    results_tbl_all <- results_tbl_all %>%
      dplyr::bind_cols(tbl)
    results <- fn_results_tibble[[2]] %>%
      as.data.frame() %>%
      dplyr::rename(Estimate = ".") %>%
      dplyr::mutate_if(is.numeric, round, digits = 4)
  }
  rownames(results) <- c("Risk Difference", "Risk Ratio", "Odds Ratio", "Incidence Rate Difference", "Incidence Rate Ratio", "Mean Difference", "Number needed to treat")
  
  results_tbl_risk <- results_tbl_all %>%
    dplyr::select_at(dplyr::vars(tidyselect::contains("predicted risk")))
  
  
  res <- list(parameter.estimates = results,
              n = as.numeric(dplyr::summarise(data, n = dplyr::n())), 
              #counterFactuals = c(counterFactControl = counterFactControl, counterFactTrt = counterFactTrt), 
              contrast = paste(paste0(names(glm_result$xlevels[1]), rev(unlist(glm_result$xlevels[1]))), collapse = " v. "), 
              family = family,#paste0(glm_result$family$family, "(link = '", glm_result$family$link,"')"), 
              formula = formula, 
              Y = Y, 
              covariates = ifelse(length(attr(glm_result$terms , "term.labels")) > 1, do.call(paste,as.list(attr(glm_result$terms , "term.labels")[-1])), NA),
              predicted.data = results_tbl_risk)
  return(res)
}
