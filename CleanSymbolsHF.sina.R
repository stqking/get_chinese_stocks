CleanSymbolsHF.sina <- function(x, savefile, dfname,
                                translate=TRUE, checktype=TRUE,
                                roundchg=FALSE, converttime=TRUE,
                                skipempty=TRUE) {
  # Clean the xls file of the intra-daily returns of a stock of Shanghai
  # or Shenzhen market.
  # The xls from sina is not an actual xls file; it is tab seperated
  # plain text file, with encoding gb18030 and "--" for zero price
  # change. It's sorted in reverse time order.
  #
  # Args:
  #   x: a data frame or path to a csv file. 
  #   savefile: a string, the path to save the cleaned dadta. The
  #       function will recognize "csv" and "RData" extensions. If it is
  #       not given (missing), overwrite the original file if x is a
  #       path or no file will be created. If is is "NA", no file will
  #       be created.
  #   dfname: a string, the data frame name if saved to RData. If it is
  #       not given (missing) or it is "NA", it is created from the
  #       savefile. If the savefile opens with a number, it is set to
  #       "intradailyprices".
  #   translate: a boolean. If TRUE, translate the column name to En.
  #   checktype: a boolean. If TRUE, check the type of each column.
  #   roundchg" a boolean. If TRUE, round the CHG column into 2 digits
  #       after dot.
  #   converttime: a boolean. If TRUE, convert TIME column into number
  #       of seconds over midnight.
  #   skipempty: a boolean. If TRUE, delete the file if it is empty.
  # Returns:
  #   the cleaned data, invisible.
  
  # Load the file
  if (is.data.frame(x)) {
    tempdf <- x
  } else if (is.character(x)){
    namesplit <- strsplit(basename(x), "\\.")[[1]]
    extname <- namesplit[length(namesplit)]
    if (extname %in% c("CSV", "csv")) {
      tempdf <- read.csv(x, stringsAsFactors=FALSE,
                         na.strings=c("None", "NA", ""),
                         fileEncoding="utf-8")
    } else if (extname %in% c("XLS", "xls")) {
      tempdf <- read.csv(x, sep="\t",
                         stringsAsFactors=FALSE,
                         na.strings=c("None", "NA", ""),
                         fileEncoding="gb18030")
    }
  }

  # skip the file if it is empty
  if (skipempty) {
    if (nrow(tempdf)==0) {
      return()
    }
  }

  # Translate column names
  if (translate) {
    colnames(tempdf)[colnames(tempdf)=="成交时间"] <- "TIME"
    colnames(tempdf)[colnames(tempdf)=="成交价"] <- "PRICE"
    colnames(tempdf)[colnames(tempdf)=="价格变动"] <- "CHG"
    colnames(tempdf)[colnames(tempdf)=="成交量.手."] <- "VOLUME"
    colnames(tempdf)[colnames(tempdf)=="成交额.元."] <- "RMBVOL"
    colnames(tempdf)[colnames(tempdf)=="性质"] <- "TYPE"
    tempdf$TYPE[tempdf$TYPE=="卖盘"] <- "Sell"
    tempdf$TYPE[tempdf$TYPE=="买盘"] <- "Buy"
    tempdf$TYPE[tempdf$TYPE=="中性盘"] <- "Neutral"
  }

  # Check types of columns
  if (checktype) {
    numcol <- which(colnames(tempdf) %in%
      c("成交价", "PRICE", "成交价", "PRICE", "价格变动", "CHG",
        "成交量.手.", "VOLUME", "成交额.元.", "RMBVOL"))
    tempdf[, numcol] <- sapply(tempdf[, numcol],
                               function(xyz) {
                                 xyz[grep("--", xyz)] <- "0"
                                 return(xyz)
                               })
    tempdf[, numcol] <- sapply(tempdf[, numcol], as.numeric)
    factorcol <- which(colnames(tempdf) %in% c("性质", "TYPE"))
    tempdf[, factorcol] <- as.factor(tempdf[, factorcol])
  }

  # Change TIME to POSIT format
  if (converttime) {
    timecol <- colnames(tempdf) %in% c("成交时间", "TIME")
    tempdf[, timecol] <-
      as.numeric(substr(tempdf[, timecol], 1, 2)) * 3600 +
      as.numeric(substr(tempdf[, timecol], 4, 5)) * 60 +
      as.numeric(substr(tempdf[, timecol], 7, 8))
    tempdf <- tempdf[order(tempdf[, timecol]), ]
    rownames(tempdf) <- NULL
  }
  if (roundchg) {
    chgcol <- which(colnames(tempdf) %in% c("价格变动", "CHG"))
    tempdf[, chgcol] <- round(tempdf[, chgcol], digits=2)
  }
  
  
  # Save or Return
  if (missing("savefile")) {
    if (is.character(x)) {
      savefile <- gsub(".xls", ".RData", x)
    } else {
      savefile <- NA
    }
  }
  
  if (!is.na(savefile)) {
    savefilesplit <- strsplit(basename(savefile), "\\.")[[1]]
    if (length(savefilesplit)==1) {
      savebext <- "RData"
      savebase <- savefilesplit
    } else if (length(savefilesplit)>1) {
      saveext <- savefilesplit[length(savefilesplit)]
      savebase <- paste(savefilesplit[-length(savefilesplit)],
                        collapse=".")
    }
    
    if (missing(dfname) || is.na(dfname)) {
      if (substr(savebase, 1, 1) %in% as.character(0:9)) {
        dfname <- "intradailyprices"
      } else {
        dfname <- savebase
      }
    }
    
    if (saveext %in% c("CSV", "csv")) {
      write.csv(tempdf, file=savefile, fileEncoding="utf-8")
    } else if (saveext %in% c("RData", "rdata", "RDATA")) {
      assign(dfname, tempdf)
      save(list=dfname, file=savefile)
    } else {
      stop(paste("Cannot save to", saveext, "format"))
    }
  }
  
  invisible(tempdf)
}
