library(dplyr)
library(plyr)

rm(list=ls())

inputDir <- "F:/Lichao/work/Projects/MultipleSclerosis/Results/2016-07-05/cohortDt_jie_July06/"

main.cohortNames <- c("Cmp", "BConti", "B2B", "B2Fir", "B2Sec")

na.representations<- c('', 'NA', 'unknown', 'ambiguous')
main.outcomes <- c("relapse_fu_any_01", "edssprog", "edssconf3",
                   "relapse_or_prog", "relapse_and_prog", "relapse_or_conf")

binCateVars <- c(
  "avl_idx_alem", "avl_idx_fing", "avl_idx_tecf", "avl_idx_teri", 
  "pre1_edssconf3", "pre1_edssprog", "pre2_edssconf3", "pre2_edssprog", 
  "pre3_edssconf3", "pre3_edssprog", "relapse_pre_90_01", 
  "relapse_pre_91to180_01", "relapse_pre_181to360_01",
  "relapse_pre_1to2_01", "relapse_pre_2to3_01", 
  "relapse_pre_3to4_01"
)

varNames2Search_TransformedVars <- 
  c(
    "new_pat_id", "relapse_fu_any_01", "edssprog", "edssconf3", "relapse_or_prog", 
    "relapse_and_prog", "relapse_or_conf", "pre_dmts", "gender__F", "gender__M", 
    "age", "birth_region", "avl_idx_fing","avl_idx_teri","avl_idx_tecf",
    "avl_idx_alem", "pre1_edssprog", "pre2_edssprog", "pre3_edssprog", 
    "pre1_edssconf3", "pre2_edssconf3", "pre3_edssconf3", 
    "relapse_pre_90_01", "relapse_pre_91to180_01", 
    "relapse_pre_181to360_01", "relapse_pre_1to2_01", "relapse_pre_2to3_01", 
    "relapse_pre_3to4_01", "record_num"
  )

timeStamp <- as.character(Sys.time())
timeStamp <- gsub(":", ".", timeStamp)  # replace ":" by "."
resultDir <- paste("./Results/", timeStamp, "/", sep = '')
dir.create(resultDir, showWarnings = TRUE, recursive = TRUE, mode = "0777")

for (cohortName in main.cohortNames)
{
  print(paste0(cohortName, ".."))
  rawDataOrgVars <- 
    tbl_df(read.csv(paste0(inputDir, "dt_", cohortName, "_withoutTransf.csv"), 
                    na.strings=na.representations, check.names=F))
  rawDataTransformedVars <- 
    tbl_df(read.csv(paste0(inputDir, "dt_", cohortName, "_withTransf.csv"),
                    na.strings=na.representations, check.names=F))
  
  processed <- 
    rawDataTransformedVars %>%
    select(
      # matches("gender|new_pat_id")
      matches(paste(varNames2Search_TransformedVars, collapse="|"))
    ) %>%
    cbind(
      rawDataOrgVars %>%
      {
        if (cohortName == "Cmp")
          varNames2Search_OrgVars <- 
            c("switch_rx_dayssup", "precont_dayssup", "years_diag_idx", 
              "baseline_edss_score", "pre1_edss_score", "pre2_edss_score", "pre3_edss_score",
              "last_cranial_num", "last_spinal_num")
        else if (cohortName == "BConti")
          varNames2Search_OrgVars <- 
            c("precont_dayssup", "years_diag_idx", "baseline_edss_score",
              "pre1_edss_score", "pre2_edss_score", "pre3_edss_score",
              "last_cranial_num", "last_spinal_num")
        else
          varNames2Search_OrgVars <- 
            c("switch_rx_dayssup", "years_diag_idx", "baseline_edss_score",
              "pre1_edss_score", "pre2_edss_score", "pre3_edss_score",
              "last_cranial_num", "last_spinal_num")
        
        select(., matches(paste(varNames2Search_OrgVars, collapse="|")))
      } 
    ) %>%
    # dayssup
    {
      dataLastStep <- .
      if (cohortName == "Cmp")
      {
        vec <- rep(-1, nrow(dataLastStep))
        for (i in 1:length(vec))
        {
          if (is.na(dataLastStep$switch_rx_dayssup[i]))
            vec[i] <- dataLastStep$precont_dayssup[i]
          else
            vec[i] <- dataLastStep$switch_rx_dayssup[i]
        }
        dataLastStep$dayssup <- vec
        dataLastStep %>%
          select(-one_of(c("switch_rx_dayssup", "precont_dayssup")))
      }
      else if (cohortName == "BConti")
      {
        dataLastStep %>%
          mutate(dayssup=precont_dayssup) %>%
          select(-precont_dayssup)
      }
      else
      {
        dataLastStep %>%
          mutate(dayssup=switch_rx_dayssup) %>%
          select(-switch_rx_dayssup)
      }
    } %>%
    mutate(dayssup_le360=as.numeric(dayssup<=360)) %>%
    mutate(dayssup_gt360=as.numeric(dayssup>360)) %>%
    select(-dayssup) %>%
    # years_diag_idx
    mutate(
      years_diag_idx__le2=
        ifelse(is.na(years_diag_idx), 0, as.numeric(years_diag_idx<=2))
      ) %>%
    mutate(
      years_diag_idx__gt2_le5=
        ifelse(is.na(years_diag_idx), 0, as.numeric((years_diag_idx>2)&(years_diag_idx<=5)))
      ) %>%
    mutate(
      years_diag_idx__gt5=
        ifelse(is.na(years_diag_idx), 0, as.numeric(years_diag_idx>5))
      ) %>%
    mutate(years_diag_idx__missing=ifelse(is.na(years_diag_idx), 1, 0)) %>%
    select(-years_diag_idx) %>%
    # change some age category names
    select(age__le30=matches("^age.*30$"), everything()) %>%
    select(age__ge51=matches("age__51"), everything()) %>%
    select(age__31to40=matches("age__31_40"), everything()) %>%
    select(age__41to50=matches("age__41_50"), everything()) %>%
    # region name
    select(birth_region__others=matches("other"), everything()) %>%
    # baseline_edss
    mutate(baseline_edss_score__0=as.numeric(baseline_edss_score==0)) %>%
    mutate(baseline_edss_score__1_4=as.numeric((baseline_edss_score<=4)&(baseline_edss_score>=1))) %>%
    mutate(baseline_edss_score__gt4=as.numeric(baseline_edss_score>4)) %>%
    select(-baseline_edss_score) %>%
    # "pre1_edss_score", 
    mutate(
      pre1_edss_score__0=
        ifelse(is.na(pre1_edss_score), 0, as.numeric(pre1_edss_score==0))
      ) %>%
    mutate(
      pre1_edss_score__1_4=
        ifelse(is.na(pre1_edss_score), 0, as.numeric((pre1_edss_score<=4)&(pre1_edss_score>=1)))
      ) %>%
    mutate(
      pre1_edss_score__gt4=
        ifelse(is.na(pre1_edss_score), 0, as.numeric(pre1_edss_score>4))
      ) %>%
    mutate(
      pre1_edss_score__missing=
        ifelse(is.na(pre1_edss_score), 1, 0)
      ) %>%
    select(-pre1_edss_score) %>%
    
    {
      # QC
      var2QC <- grep("^pre1_edss_score__", names(.), value = T)
      lineSum <- apply(.[, var2QC], 1, sum)
      if(any(lineSum!=1)){
        stop('pre1_edss_score wrong bucketing!\n\n')
      }
      .
    } %>%
    # "pre2_edss_score", 
    mutate(
      pre2_edss_score__0=
        ifelse(is.na(pre2_edss_score), 0, as.numeric(pre2_edss_score==0))
    ) %>%
    mutate(
      pre2_edss_score__1_4=
        ifelse(is.na(pre2_edss_score), 0, as.numeric((pre2_edss_score<=4)&(pre2_edss_score>=1)))
    ) %>%
    mutate(
      pre2_edss_score__gt4=
        ifelse(is.na(pre2_edss_score), 0, as.numeric(pre2_edss_score>4))
    ) %>%
    mutate(
      pre2_edss_score__missing=
        ifelse(is.na(pre2_edss_score), 1, 0)
    ) %>%
    select(-pre2_edss_score) %>%
    {
      # QC
      var2QC <- grep("^pre2_edss_score__", names(.), value = T)
      lineSum <- apply(.[, var2QC], 1, sum)
      if(any(lineSum!=1)){
        stop('pre2_edss_score wrong bucketing!\n\n')
      }
      .
    } %>%
    # "pre3_edss_score", 
    mutate(
      pre3_edss_score__0=
        ifelse(is.na(pre3_edss_score), 0, as.numeric(pre3_edss_score==0))
    ) %>%
    mutate(
      pre3_edss_score__1_4=
        ifelse(is.na(pre3_edss_score), 0, as.numeric((pre3_edss_score<=4)&(pre3_edss_score>=1)))
    ) %>%
    mutate(
      pre3_edss_score__gt4=
        ifelse(is.na(pre3_edss_score), 0, as.numeric(pre3_edss_score>4))
    ) %>%
    mutate(
      pre3_edss_score__missing=
        ifelse(is.na(pre3_edss_score), 1, 0)
    ) %>%
    select(-pre3_edss_score) %>%
    {
      # QC
      var2QC <- grep("^pre3_edss_score__", names(.), value = T)
      lineSum <- apply(.[, var2QC], 1, sum)
      if(any(lineSum!=1)){
        stop('pre3_edss_score wrong bucketing!\n\n')
      }
      .
    } %>%
    # last_cranial_num
    {
      result <- .
      if (cohortName != "B2Sec")
        result$last_cranial_num__le8 <- as.numeric(
          result[, "last_cranial_num__0"] | result[, "last_cranial_num__1"] |
            result[, "last_cranial_num__2-5"] | result[, "last_cranial_num__6-8"]
        )
      else
        result$last_cranial_num__le8 <- as.numeric(
          result[, "last_cranial_num__1"] |
            result[, "last_cranial_num__2-5"] | result[, "last_cranial_num__6-8"]
        )
          
      result$last_cranial_num__gt8 <- result[, "last_cranial_num__>8"]
      result
    } %>%
    select(-matches("last_cranial_num__0|last_cranial_num__1|last_cranial_num__2|last_cranial_num__6|last_cranial_num__>")) %>%
    # last_spinal_num
    {
      result <- .
      result$last_spinal_num__le2 <- as.numeric(
        result[, "last_spinal_num__0"] | result[, "last_spinal_num__1"] |
          result[, "last_spinal_num__2"]
      )
        
      result$last_spinal_num__gt2 <- result[, "last_spinal_num__>2"]
      result
    } %>%
    select(-matches("last_spinal_num__0|last_spinal_num__1|last_spinal_num__2|last_spinal_num__>")) %>%
    # bin cate vars
    {
      .[is.na(.)] <- "missing"
      .
    } %>%
    {
      result <- .
      for (variable in binCateVars)
      {
        lvls <- unique(.[, variable])
        
        for (level in lvls)
        {
          result[, paste0(variable, "__", as.character(level))] <-
            as.numeric(result[, variable] == level)
        }
      }
      result <- result[, !(colnames(result) %in% binCateVars)]
    } %>%
    select(-new_pat_id)
  
  processed <- processed[,  order(colnames(processed))]
  orderedVars <- colnames(processed)
  processed <- processed[, c(main.outcomes, orderedVars[!orderedVars%in%main.outcomes])]
  
  write.table(processed, 
              paste0(resultDir, cohortName, ".csv"), 
              row.names=F, 
              sep=",", 
              na="")
}