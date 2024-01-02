# Grades Summaries

## Find submission files

submissions.folder <- fs::path(courselocation, "studentsubmissions") # file.path("submissions")

submissions.files <- list.files(submissions.folder, full.names = TRUE, recursive = TRUE)
submissions.files <- submissions.files[which(!grepl("submissions_log.*?[.]xlsx$", submissions.files))]

## Decompose filenames

### Decompose filenames into directory components (2) and filenames

filenames.decomposed <- lapply(submissions.files,
                               function(x){
                                   filename <- gsub(paste0(fs::path(courselocation, "studentsubmissions"), "/"), "", x)
                                   filename <- strsplit(filename, split="/")
                                   filename <- as.data.frame(t(unlist(filename)))
                                   names(filename) <- c("QuizID", "Submission")
                                   return(filename)
                                 })
filenames.decomposed <- dplyr::bind_rows(filenames.decomposed)
filenames.decomposed$Full.Filename <- submissions.files


### Decompose filenames into metadata

decompose.Filename <- function(x){
  metadata <- strsplit(x, split="_")
  metadata <- as.data.frame(t(unlist(metadata)))
  metadata[,ncol(metadata)+1] <- as.POSIXct(paste(c(metadata[,2:7]), collapse = "_"), format = "%Y_%m_%d_%H_%M_%S")
  metadata <- setNames(metadata[,c(1,ncol(metadata))], nm = c("StudentID", "Submission Time"))
  return(metadata)
  }


filenames.decomposed2 <- lapply(filenames.decomposed$Submission, decompose.Filename)

##### Alternative approach to strsplit() use regex to extract chunks
###### like for Email
####### gsub("(.+?)_.*", "\\1", filenames.decomposed$Filename[1])
###### but regex is tougher to grab all dates and times together and ending
###### easier to grab all separate, then combine after

filenames.decomposed2 <- dplyr::bind_rows(filenames.decomposed2)



### Combine into dataframe
#### Contents = Submissions folder name, subfolder name, filename, email, submission time stamps, quiz id

submissions <- dplyr::bind_cols(filenames.decomposed, filenames.decomposed2)



## Convert to Tibble and store submission files within

submissions <- as_tibble(submissions)

submissions$Submission <- lapply(submissions$Full.Filename, readxl::read_xlsx, col_types = "text", col_names = TRUE)

submissions <- submissions %>% arrange(`Submission Time`) %>% group_by(StudentID, QuizID) %>% mutate(Attempt = row_number())

submissions <- submissions %>% group_by(StudentID, QuizID) %>% filter(Attempt == max(Attempt))

## Set-up for grading each submission

### Wrap function to import correct solution for each submission file

#### Set-up to take single row from previously made tibble

collect.Grades <- function(.record){
  .submission <- .record$Submission %>%
    dplyr::mutate_all(~ tidyr::replace_na(.x, "")) %>%
    data.frame()
  .solution <- readxl::read_xlsx(fs::path(courselocation, "completequizzes", paste0(.record$QuizID, "_complete.xlsx")))
  return(list(quizgrader::grade_quiz(.submission, .solution), .solution$DueDate[1]))
}


## Add grade tables to tibble

submissions$Grade.table <- apply(submissions, 1, FUN = function(x){return(collect.Grades(x)[[1]])})
submissions$DueDate <- apply(submissions, 1, FUN = function(x){return(collect.Grades(x)[[2]])})




## Create more readable dataframe

### Split data to lists according to quizID
submissions.list.by.quiz <- split(submissions, submissions$QuizID)

### Create variables for quiz responses (Correct/Not Correct)
#### number of variables could be different for each quiz, so previous split was necessary

#### Transpose the grade table and name the columns according to quizID and recordID
widen.Grades <- function(.single.record){
  gt <- .single.record$Grade.table
  gt[nrow(gt)+1,] <- c("n.questions", nrow(gt))
  gt[nrow(gt)+1,] <- c("n.correct", sum(gt$Score=="Correct"))
  gt <- gt %>% t() %>% as.data.frame()
  names(gt) <- gt[1,]
  gt <- gt[-1,]
  return(gt)
}





#### Wrap previous function to apply to all records of same quizID, prepare for join
wrapper.Widen.Grades <- function(.records){
  temp <- apply(.records, 1, widen.Grades)
  .records <- bind_cols(.records, bind_rows(temp))
  names(.records)[which(!names(.records)%in%"StudentID")] <- paste(.records$QuizID[1], names(.records)[which(!names(.records)%in%"StudentID")], sep = ".")
  return(.records)
}

#### create indicators of quiz responses within each quizID dataframe
submissions.list.by.quiz <- lapply(submissions.list.by.quiz, wrapper.Widen.Grades)


### Read in studentlist

studentlist <- quizgrader::read_studentlist(fs::path(courselocation, "studentlists"))


### Join class list with graded submissions
for(i in 1:length(submissions.list.by.quiz)){
  studentlist <- full_join(studentlist, submissions.list.by.quiz[[i]], by="StudentID")
}








