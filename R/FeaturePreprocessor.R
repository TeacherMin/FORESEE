#' Preprocess the Gene Expression Inputs of both TrainObject and TestObject for Modeling Drug Response
#'
#' The FeaturePreprocessor converts the original gene expression features into predictive features with a function defined by FeaturePreprocessing.
#'
#' @param TrainObject Object that contains all data needed to train a model, including molecular data (such as gene expression, mutation, copy number variation, methylation, cancer type, etc. ) and drug response data
#' @param TestObject Object that contains all data that the model is to be tested on, including molecular data (such as gene expression, mutation, copy number variation, methylation, cancer type, etc. ) and drug response data
#' @param FeaturePreprocessing Method for preprocessing the inputs of the model:
#' The function 'zscore_genewise' calculates the zscore normalizing each gene over all samples,
#' The function 'zscore_samplewise' calculates the zscore normalizing each sample over all genes,
#' The function 'pca' does principal component analysis,
#' The function 'physio' does physiospace analysis with the samples using cell line gene expression of the gdsc data base as physiological references,
#' The function 'none' keeps the gene expression values unchanged,
#' The function 'listInputOptions("FeaturePreprocessor")' returns a list of the possible options.
#' Instead of chosing one of the implemented options, a user-defined function can be used as an input.
#' @return \item{TrainObject}{The TrainObject with preprocessed features.}
#'         \item{TestObject}{The TestObject with preprocessed features.}
#' @examples
#' FeaturePreprocessor(GDSC,GSE6434,"zscore_genewise")
#' @export

#########################
# This file is part of the FORESEE R-package
# File authors: Lisa-Katrin Turnhoff <turnhoff@combine.rwth-aachen.de> and Ali Hadizadeh Esfahani <hadizadeh@combine.rwth-aachen.de>
# Distributed under the GNU General Public License v3.0.(http://www.gnu.org/licenses/gpl-3.0.html)
#########################

FeaturePreprocessor <- function(TrainObject, TestObject, FeaturePreprocessing){
  UseMethod("FeaturePreprocessor", object = FeaturePreprocessing)
}

#' @export
FeaturePreprocessor.character <- function(TrainObject, TestObject, FeaturePreprocessing){
  class(FeaturePreprocessing) <- FeaturePreprocessing;
  UseMethod("FeaturePreprocessor", object = FeaturePreprocessing)
}

#' @export
FeaturePreprocessor.function <- function(TrainObject, TestObject, FeaturePreprocessing){

  TrainObject_processedfeatures <- TrainObject
  TestObject_processedfeatures <- TestObject

  TrainObject_processedfeatures$GeneExpression <-
    FeaturePreprocessing(TrainObject_processedfeatures$GeneExpression)
  TestObject_processedfeatures$GeneExpression <-
    FeaturePreprocessing(TestObject_processedfeatures$GeneExpression)

  # Update Objects in the Environment
  assign("TrainObject", value = TrainObject_processedfeatures, envir = parent.frame())
  assign("TestObject", value = TestObject_processedfeatures, envir = parent.frame())

}

################################################################################
### Function "zscore_genewise" to calculate the zscore normalizing each gene over all samples
#' @export
FeaturePreprocessor.zscore_genewise <- function(TrainObject, TestObject, FeaturePreprocessing){

  TrainObject_processedfeatures <- TrainObject
  TestObject_processedfeatures <- TestObject

  # Calculate gene-wise zscore for TrainObject
  for (i in 1:dim(TrainObject_processedfeatures$GeneExpression)[1]){
    TrainObject_processedfeatures$GeneExpression[i,]<-(TrainObject_processedfeatures$GeneExpression[i,]-mean(TrainObject_processedfeatures$GeneExpression[i,]))/sd(TrainObject_processedfeatures$GeneExpression[i,])
  }

  # Calculate gene-wise zscore for TrainObject
  for (i in 1:dim(TestObject_processedfeatures$GeneExpression)[1]){
    TestObject_processedfeatures$GeneExpression[i,]<-(TestObject_processedfeatures$GeneExpression[i,]-mean(TestObject_processedfeatures$GeneExpression[i,]))/sd(TestObject_processedfeatures$GeneExpression[i,])
  }

  # Update Objects in the Environment
  assign("TrainObject", value = TrainObject_processedfeatures, envir = parent.frame())
  assign("TestObject", value = TestObject_processedfeatures, envir = parent.frame())

}

################################################################################
### Function "zscore_samplewise" to calculate the zscore normalizing each gene over all samples
#' @export
FeaturePreprocessor.zscore_samplewise <- function(TrainObject, TestObject, FeaturePreprocessing){

  TrainObject_processedfeatures <- TrainObject
  TestObject_processedfeatures <- TestObject

  # Calculate sample-wise zscore for TrainObject
  for (i in 1:dim(TrainObject_processedfeatures$GeneExpression)[2]){
    TrainObject_processedfeatures$GeneExpression[,i]<-(TrainObject_processedfeatures$GeneExpression[,i]-mean(TrainObject_processedfeatures$GeneExpression[,i]))/sd(TrainObject_processedfeatures$GeneExpression[,i])
  }

  # Calculate sample-wise zscore for TrainObject
  for (i in 1:dim(TestObject_processedfeatures$GeneExpression)[2]){
    TestObject_processedfeatures$GeneExpression[,i]<-(TestObject_processedfeatures$GeneExpression[,i]-mean(TestObject_processedfeatures$GeneExpression[,i]))/sd(TestObject_processedfeatures$GeneExpression[,i])
  }

  # Update Objects in the Environment
  assign("TrainObject", value = TrainObject_processedfeatures, envir = parent.frame())
  assign("TestObject", value = TestObject_processedfeatures, envir = parent.frame())
}


################################################################################
### Function "pca" for principal component analysis
#' @export
FeaturePreprocessor.pca <- function(TrainObject, TestObject, FeaturePreprocessing){

  TrainObject_processedfeatures <- TrainObject
  TestObject_processedfeatures <- TestObject

  # Number of how many PCs should be used for the projection
  number_pcs <- 10

  # PCA for the Train Object
  TrainObject_pca <- prcomp(t(TrainObject_processedfeatures$GeneExpression))

  # Rotated training data

  TrainObject_x <- scale(t(TrainObject_processedfeatures$GeneExpression), TrainObject_pca$center, TrainObject_pca$scale) %*% TrainObject_pca$rotation
  # TrainObject_x <- TrainObject_pca$x should be the same as: TrainObject_x <- scale(t(TrainObject_processedfeatures$GeneExpression), TrainObject_pca$center, TrainObject_pca$scale) %*% TrainObject_pca$rotation
  TrainObject_x_nPCs<- TrainObject_x[,1:number_pcs]

  # Rotate test data (project new data onto the PCA space)
  TestObject_x <- scale(t(TestObject_processedfeatures$GeneExpression), TrainObject_pca$center, TrainObject_pca$scale) %*% TrainObject_pca$rotation
  TestObject_x_nPCs<-TestObject_x[,1:number_pcs]

  # Update Gene Expression values with the projected data
  TrainObject_processedfeatures$GeneExpression <- t(TrainObject_x_nPCs)
  TestObject_processedfeatures$GeneExpression <- t(TestObject_x_nPCs)

  # Update Objects in the Environment
  assign("TrainObject", value = TrainObject_processedfeatures, envir = parent.frame())
  assign("TestObject", value = TestObject_processedfeatures, envir = parent.frame())
}


################################################################################
### Function "physio" to calculate the physiospace similarities
#' @export
FeaturePreprocessor.physio <- function(TrainObject, TestObject, FeaturePreprocessing){

  TrainObject_processedfeatures <- TrainObject
  TestObject_processedfeatures <- TestObject

  requireForesee(PhysioSpaceMethods)
  Similarities <- calculatePhysioMap(InputData = cbind(TrainObject_processedfeatures$GeneExpression,
                                        TestObject_processedfeatures$GeneExpression),
                     Space = TrainObject_processedfeatures$GeneExpression, PARALLEL = TRUE)
  TrainObject_processedfeatures$GeneExpression <- Similarities[,1:ncol(TrainObject$GeneExpression)]
  diag(TrainObject_processedfeatures$GeneExpression)<- 0

  TestObject_processedfeatures$GeneExpression <- Similarities[,(ncol(TrainObject$GeneExpression)+1):(ncol(TrainObject$GeneExpression)+ncol(TestObject$GeneExpression))]

  # Update Objects in the Environment
  assign("TrainObject", value = TrainObject_processedfeatures, envir = parent.frame())
  assign("TestObject", value = TestObject_processedfeatures, envir = parent.frame())
}

################################################################################
### Function "none" to keep original format of the data
#' @export
FeaturePreprocessor.none <- function(TrainObject, TestObject, FeaturePreprocessing){

  TrainObject_processedfeatures <- TrainObject
  TestObject_processedfeatures <- TestObject

  # Don't do anything

  # Update Objects in the Environment
  assign("TrainObject", value = TrainObject_processedfeatures, envir = parent.frame())
  assign("TestObject", value = TestObject_processedfeatures, envir = parent.frame())
}
