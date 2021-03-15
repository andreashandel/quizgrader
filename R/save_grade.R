#' @title Save the student grade to the gradelist file
#'
#' @description This function takes the data frame or tibble
#' that is supposed to contain a valid completed quiz
#' and checks that structure and content are valid
#'
#' @param score student score
#' @param gradelist_folder folder where gradelist is stored
#'
#' @return An error message if it's not a valid quiz data frame,
#' otherwise NULL
#' @export





#######################################################
#write grade to gradelist file
#append date, such that files don't overwrite each other
save_grade <- function(score, gradelist_folder)
{
  # gradelist = read_gradelist(gradelist_folder)
  # gradecol = which(colnames(gradelist) == paste0(quizid,"_grade"))
  # gradelist[studentid,gradecol] <- score
  # submitcol = which(colnames(gradelist) == paste0(quizid,"_submitdate"))
  # gradelist[studentid,submitcol] <- as.character(Sys.time())
  # timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
  # filename = paste0("gradelist_",timestamp,".tsv")
  # gradelistfile = paste0(gradelist_folder,"/",filename)
  # write.table(gradelist,gradelistfile, sep = '\t', col.names = TRUE, row.names = FALSE )
} #end function that writes to file

