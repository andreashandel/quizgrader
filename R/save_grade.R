#' @title Save the student grade to the gradelist file
#'
#' @description This function takes the data frame or tibble
#' that is supposed to contain a valid completed quiz
#' and checks that structure and content are valid
#'
#' @param score student score
#' @param studentid student id
#' @param quizid quiz id
#' @param gradelist gradelist data frame
#' @param gradelists_folder folder to save gradelists
#'
#' @return An error message if it's not a valid quiz data frame,
#' otherwise NULL
#' @export





#######################################################
#write grade to gradelist file
#append date, such that files don't overwrite each other
save_grade <- function(score, studentid, quizid, gradelist, gradelists_folder)
{
  studentrow = which(gradelist[,"StudentID"] == studentid)
  gradecol = which(colnames(gradelist) == paste0(quizid,"_Grade"))

  gradelist[studentrow,gradecol] <- as.character(score)

  submitcol = which(colnames(gradelist) == paste0(quizid,"_SubmitDate"))
  gradelist[studentrow,submitcol] <- as.character(Sys.time())

  attemptcol = which(colnames(gradelist) == paste0(quizid, "_Attempt"))

  if(is.na(gradelist[studentrow, attemptcol])){
    gradelist[studentrow, attemptcol] <- "1"
  }else{
    gradelist[studentrow, attemptcol] <- as.character(as.numeric(gradelist[studentrow, attemptcol])+1)
  }

  timestamp = gsub(" ","_",gsub("-","_", gsub(":", "_", Sys.time())))
  filename = paste0("gradelist_",timestamp,".xlsx")
  gradelistfile = paste0(gradelists_folder,"/",filename)

  writexl::write_xlsx(gradelist, gradelistfile, col_names = TRUE, format_headers = TRUE)
} #end function that writes to file

