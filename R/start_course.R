#' @title Set up structure for a new course
#'
#' @description This function creates a new course/project
#' and creates template folders and files for quizzes
#' to be filled by the teacher
#'
#' @param coursename Name of course to be created
#' this will be the main folder name
#' and will contain sub-folders for all the materials
#' @param courselocation The location where the new course folder
#' is to be created
#'
#' @return The script creates folders.
#' If things went well, a message is returned stating where the new course was created.
#' Otherwise an error message is returned.
#' @export



start_course <- function(coursename, courselocation ="./")
{

  #make directories for course and sub-folders
  newfolder = paste0(courselocation,coursename)
  if dir.exists(newfolder)
  {
    errormsg = "Folder already exists! Please delete the existing folder or choose a different course name."
    return(errormsg) #stop rest of function/script
  }
  else
  {
    dir.create(newfolder)
    dir.create(file.path(newfolder,'courselists'))
    dir.create(file.path(newfolder,'student_solution_sheets'))
    dir.create(file.path(newfolder,'complete_solution_sheets'))
    dir.create(file.path(newfolder,'student_submissions'))
  }

  #copy templates of files into folders


  #if no errors occured above (which would lead to early return)
  #write and return a success message here
  errormsg = paste0("The new course folder and its subfolders have been created at: ",newfolder)
  return(errormsg)

} #end main function




