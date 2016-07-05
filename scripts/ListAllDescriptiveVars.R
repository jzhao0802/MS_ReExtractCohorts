rm(list=ls())

inputDir <- "C:/Work/Projects/MultipleSclerosis/Results/2016-07-05/10am/Cohort_Lichao/"

allVars <- NULL

cohortNames <- c("Cmp", "BConti", "B2B", "B2Fir", "B2Sec")
na.representations<- c('', 'NA', 'unknown', 'ambiguous')
outcomes <- c("relapse_fu_any_01", "edssprog", "edssconf3",
              "relapse_or_prog", "relapse_and_prog", "relapse_or_conf")

for (cohortName in cohortNames)
{
  cohort <- read.csv(paste0(inputDir, cohortName, ".csv"), 
                     na.strings=na.representations, check.names=F)
  
  allVars <- c(allVars, colnames(cohort))
}

allVars <- sort(unique(allVars))
allVars <- c(outcomes, allVars[!(allVars %in% outcomes)])

timeStamp <- as.character(Sys.time())
timeStamp <- gsub(":", ".", timeStamp)  # replace ":" by "."
resultDir <- paste("./Results/", timeStamp, "/", sep = '')
dir.create(resultDir, showWarnings = TRUE, recursive = TRUE, mode = "0777")

write.table(allVars, paste0(resultDir, "allVars.csv"), sep=",", row.names=F,
            col.names=F)