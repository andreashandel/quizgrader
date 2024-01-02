#' @title Check that information submitted by students through UI is correct
#'
#' @description This function takes the metadata submitted by a student
#' (Name, ID, Password) and checks it against information
#' in the grade tracking list to ensure that student is present
#' and the submitted information valid
#'
#' @param metadata list containing elements StudentID and Password
#' @param gradelist Data frame containing the grade list
#'
#' @return An error message if user input is not valid
#' otherwise NULL
#' @export


#######################################################
#check that metadata students are entering are correct
#######################################################
check_metadata <- function(metadata, gradelist)
{
  metaerror = NULL

  #look for the provided user ID
  studentnr = which(metadata$StudentID == gradelist$StudentID)
  if ( length(studentnr) == 0)  #student could not be found
  {
    metaerror <- "The provided Student ID could not be found"
    return(metaerror)
  }

  #find the row for this user, check that they have a Password set
  if ( nchar(gradelist$Password[studentnr])==0)
  {
    metaerror <- "It seems like you have not provided a Password, please do so."
    return(metaerror)
  }

  #check that Password matches
  #this can prevent anyone submitting for someone else (unless that person shared their Password)
  #ignore capitalization for Password
  if ( metadata$Password != tolower(gradelist$Password[studentnr]))
  {
    metaerror <- "Password does not match"
    return(metaerror)
  }

} #end function that checks student submitted metadata






