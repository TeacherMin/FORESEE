#' Transform Drug Response Data
#'
#' The CellResponseProcessor transforms the response data of the TrainObject for prediction.
#'
#' @param TrainObject Object that contains all data needed to train a model, including molecular data (such as gene expression, mutation, copy number variation, methylation, cancer type, etc. ) and drug response data
#' @param DrugName Name of the drug whose efficacy is supposed to be predicted with the model
#' @param CellResponseType Format of the drug response data of the TrainObject, such as LN_IC50, AUC, GI50, etc., that is included in the TrainObject and to be used for prediction
#' @param CellResponseTransformation Method that is to be used to transform the drug response data of the TrainObject:
#' the function 'powertransform' power transforms the drug response data,
#' the function 'logarithm' returns the natural logarithm of the drug response data,
#' the function 'binarization_kmeans' returns a binarized drug response vector based on 2 kmeans clusters,
#' the function 'binarization_cutoff' returns a binarized drug response vector based on a cutoff at the median,
#' the function 'none' returns the unchanged drug response data.
#' The function 'listInputOptions("CellResponseProcessor")' returns a list of the possible options.
#' Instead of choosing one of the implemented options, a user-defined function can be used as an input.
#' @return \item{TrainObject}{The TrainObject with preprocessed drug response data.}
#' @examples
#' CellResponseProcessor(GDSC, "Docetaxel", "LN_IC50", "binarization_cutoff")
#' @export

#########################
# This file is part of the FORESEE R-package
# File authors: Lisa-Katrin Turnhoff <turnhoff@combine.rwth-aachen.de> and Ali Hadizadeh Esfahani <hadizadeh@combine.rwth-aachen.de>
# Distributed under the GNU General Public License v3.0.(http://www.gnu.org/licenses/gpl-3.0.html)
#########################

CellResponseProcessor <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){
  UseMethod("CellResponseProcessor", object = CellResponseTransformation)
  return(TrainObject)
}

#' @export
CellResponseProcessor.character <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){
  class(CellResponseTransformation) <- CellResponseTransformation;
  UseMethod("CellResponseProcessor", object = CellResponseTransformation)
}

#' @export
CellResponseProcessor.function <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){
  message("The used-defined function is applied")

  Object_withDrugResponse <- GetCellResponseData(TrainObject = TrainObject, DrugName = DrugName, CellResponseType = CellResponseType)

  # User-defined function:
  Object_withDrugResponse$DrugResponse <- CellResponseTransformation(Object_withDrugResponse$DrugResponse)

  # Prints the action
  message(paste0("CellResposeProcessor added the new matrix 'Drug Response' to the ForeseeCell Object, which includes transformed ",CellResponseType," response information about ",DrugName," by user-defined function."))

  # Returns the new TrainObj
  return(Object_withDrugResponse)
}

################################################################################
### Function "powertransform" to powertransform the chosen drug response data
#' @export
CellResponseProcessor.powertransform <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){

  # Load Package for Power Transform
  requireForesee(car)

  # Extract drug response of interest
  Object_withDrugResponse <- GetCellResponseData(TrainObject = TrainObject, DrugName = DrugName, CellResponseType = CellResponseType)

  # Powertransform needs all inputs to be positive
    if(min(Object_withDrugResponse$DrugResponse, na.rm = TRUE) < 0) {
      offset <- -min(Object_withDrugResponse$DrugResponse, na.rm = TRUE) + 1
      Object_withDrugResponse$DrugResponse <- Object_withDrugResponse$DrugResponse + offset
    }

  # Do powertransform of drug response data
  TransForm <- powerTransform(Object_withDrugResponse$DrugResponse)$lambda
  Object_withDrugResponse$DrugResponse <- Object_withDrugResponse$DrugResponse^TransForm

  # Prints the action
  message(paste0("CellResposeProcessor added the new matrix 'Drug Response' to the ForeseeCell Object, which includes power transformed ",CellResponseType," response information about ",DrugName,"."))

  # Returns the new TrainObj
  return(Object_withDrugResponse)
}


################################################################################
### Function "logarithm" to logarithm the chosen drug response data
#' @export
CellResponseProcessor.logarithm <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){

  # Extract drug response of interest
  Object_withDrugResponse <- GetCellResponseData(TrainObject = TrainObject, DrugName = DrugName, CellResponseType = CellResponseType)

  # Log needs all inputs to be positive, otherwise only NAs are returned
  if(min(Object_withDrugResponse$DrugResponse, na.rm = TRUE) < 0) {
    offset <- -min(Object_withDrugResponse$DrugResponse, na.rm = TRUE) + 1
    Object_withDrugResponse$DrugResponse <- Object_withDrugResponse$DrugResponse + offset
  }

  # Do logarithm of drug response data
  Object_withDrugResponse$DrugResponse <- log(Object_withDrugResponse$DrugResponse)

  # Prints the action
  message(paste0("CellResposeProcessor added the new matrix 'Drug Response' to the ForeseeCell Object, which includes natural logarithmic ",CellResponseType," response information about ",DrugName,"."))

  # Returns the new TrainObj
  return(Object_withDrugResponse)
}


################################################################################
### Function "binarization_kmeans" to binarization the chosen drug response data
### Uses the kmeans algorithm of the package Binarize to find two clusters in the data
#' @export
CellResponseProcessor.binarization_kmeans <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){

  requireForesee(Binarize)

  # Extract drug response of interest
  Object_withDrugResponse <- GetCellResponseData(TrainObject = TrainObject, DrugName = DrugName, CellResponseType = CellResponseType)

  # Do kmeans binarization of drug response data
  names_drugresponse <- names(Object_withDrugResponse$DrugResponse)
  Object_withDrugResponse$DrugResponse <- binarize.kMeans(Object_withDrugResponse$DrugResponse)@binarizedMeasurements
  names(Object_withDrugResponse$DrugResponse) <- names_drugresponse

  # Prints the action
  message(paste0("CellResposeProcessor added the new matrix 'Drug Response' to the ForeseeCell Object, which includes binarized ",CellResponseType," response information about ",DrugName,"."))

  # Returns the new TrainObj
  return(Object_withDrugResponse)
}

################################################################################
### Function "binarization_cutoff" to binarization the chosen drug response data
### Uses the kmeans algorithm of the package Binarize to find two clusters in the data
#' @export
CellResponseProcessor.binarization_cutoff <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){

  requireForesee(bootnet)

  # Extract drug response of interest
  Object_withDrugResponse <- GetCellResponseData(TrainObject = TrainObject, DrugName = DrugName, CellResponseType = CellResponseType)

  # Do binarization of drug response data with median as cutoff
  names_drugresponse <- names(Object_withDrugResponse$DrugResponse)
  Object_withDrugResponse$DrugResponse <- binarize(x=Object_withDrugResponse$DrugResponse, split = "median", removeNArows = FALSE)$x
  names(Object_withDrugResponse$DrugResponse) <- names_drugresponse

  # Prints the action
  message(paste0("CellResposeProcessor added the new matrix 'Drug Response' to the ForeseeCell Object, which includes binarized ",CellResponseType," response information about ",DrugName,"."))

  # Returns the new TrainObj
  return(Object_withDrugResponse)
}

################################################################################
### Function "none" to use the raw drug response data
#' @export
CellResponseProcessor.none <- function(TrainObject, DrugName, CellResponseType, CellResponseTransformation){

  # Extract drug response of interest
  Object_withDrugResponse <- GetCellResponseData(TrainObject = TrainObject, DrugName = DrugName, CellResponseType = CellResponseType)

  # Don't do anything to drug response data

  # Prints the action
  message(paste0("CellResposeProcessor added the new matrix 'Drug Response' to the ForeseeCell Object, which includes raw ",CellResponseType," response information about ",DrugName,"."))

  # Returns the new TrainObj
  return(Object_withDrugResponse)
}
