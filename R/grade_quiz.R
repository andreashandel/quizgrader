#' @title Grade a quiz
#'
#' @description This function takes a data frame containing student submissions
#' and a data frame containing the answers and evaluates/grades.
#' The specific grading depends on the type of question.
#'
#' @param submission The data frame containing the student submission
#' @param solution The data frame containing the solution
#' is to be created
#'
#' @return
#' If things went well, a data frame containing "Correct" or "Not correct" for each question.
#' Otherwise an error message is returned.
#' @export



grade_quiz <-  function(submission, solution)
  {

    #grade each question
    #set up data frame that will hold both the question number and the correct/not correct evaluation
    #start by labeling answer as not correct
    #then based on checks below, overwrite by declaring it correct
    grade_table = data.frame(Question = solution$Question, YourAnswer = "", Score = "Not correct", Feedback = solution$Feedback)

    #run through each row of submitted sheet, compare answer with solution
    #for this to work, the submitted and solution file need to have exactly the same structure
    for (n in 1:nrow(solution))
    {
      #browser()

      #save answer and submission in their own variables for easier processing
      true_answer = solution$Answer[n]
      submitted_answer = submission$Answer[n]

      #record their answer
      grade_table$YourAnswer[n] = submitted_answer

      #record type of answer, treat accordingly
      answertype = solution$Type[n]

      #these answer types are allowed. Throw an error message if it's not one of those.
      allowed_types = c("Character", "Text", "Logical", "Integer", "Fuzzy_Integer", "Numeric", "Rounded_Numeric")


      if (!(answertype %in% allowed_types))
      {
        grade_table <- "The solution sheet contains a non-allowed answer type. Please alert the instructor of this problem."
        return(grade_table)
      }

      #expect single letter, only evaluate 1st entry in submission
      if (answertype == "Character")
      {
        #convert any character to lower case
        #for submission, trim any white-space before and after
        #then keep only first character
        true_answer = tolower(true_answer)
        submitted_answer = substr(trimws(tolower(submitted_answer)),1,1)
        if (submitted_answer == true_answer) {grade_table$Score[n]="Correct"}
      }
      #expect some text
      #currently, match by requiring the submitted text contains the answer
      #so if the answer is "hello" and the student submits "this is hello world" it would be
      #grade as ok
      #could be changed
      if (answertype == "Text")
      {
        #convert any character to lower case
        #for submission, trim any white-space before and after
        true_answer = tolower(true_answer)
        submitted_answer = trimws(tolower(submitted_answer))
        #match for substring
        #if (grepl(true_answer, submitted_answer, fixed = TRUE)) {grade_table[n,2]="Correct"}
        #below is for exact match
        if (submitted_answer == true_answer) {grade_table$Score[n] = "Correct"}
      }

      #expect either Yes/No or True/False
      if (answertype == "Logical")
      {
        #convert to false/no to 0 and true/yes to 1 in both answer sheet and submission
        #convert any character to lower case
        answer_numeric = 99 #set to some 'wrong' value, which needs to be changed
        if (tolower(true_answer)=="yes" | tolower(true_answer)=="true" | true_answer=="1") {answer_numeric = 1}
        if (tolower(true_answer)=="no" | tolower(true_answer)=="false" | true_answer=="0") {answer_numeric = 0}
        #this means the solution file contains a wrong entry, an error message is triggered
        if (answer_numeric == 99)
        {
          grade_table <- paste0("The solution sheet contains a wrong entry for question ",solution$QuestionID[n],". Please alert the instructor of this problem.")
          return(grade_table)
        }
        submission_numeric = 99 #set to a 'wrong' value so if student enters neither y/t/1 or n/f/0 (as 1st letter) things evaluate to 'not correct'
        #for submission, convert to lower case, trim any white-space before and after
        #also only look at first letter, if it's y or t we assume student entered yes or true.
        submitted_answer = substr(trimws(tolower(submitted_answer)),1,1)
        if (submitted_answer == "y" | submitted_answer == "t" | submitted_answer=="1") {submission_numeric = 1}
        if (submitted_answer == "n" | submitted_answer == "f" | submitted_answer=="0") {submission_numeric = 0}
        if (submission_numeric == answer_numeric) {grade_table$Score[n] = "Correct"}
      }

      #expect integer
      #in case students don't provide an integer, round to nearest value, then do strict compare
      if (answertype == "Integer")
      {
        #make sure answer and submission can be converted to numeric
        #if not, this will produce NA and the rest of the if statement won't be evaluated
        #this means the original "Not Correct" score will remain.
        if ( !is.na(suppressWarnings(as.numeric(true_answer))) && !is.na(suppressWarnings(as.numeric(submitted_answer))) )
        {
          true_answer = as.numeric(true_answer)
          submitted_answer = round(as.numeric(submitted_answer),0)
          if (submitted_answer==true_answer) {grade_table$Score[n] = "Correct"}
        }
      }

      #expect rounded integer, allow +/-1 value in case students don't know how to round
      if (answertype == "Fuzzy_Integer")
      {
        #make sure answer and submission can be converted to numeric
        #if not, this will produce NA and the rest of the if statement won't be evaluated
        #this means the original "Not Correct" score will remain.
        if ( !is.na(suppressWarnings(as.numeric(true_answer))) && !is.na(suppressWarnings(as.numeric(submitted_answer))) )
        {
          true_answer = as.numeric(true_answer)
          submitted_answer = as.numeric(submitted_answer)
          #check that submitted value is either true_answer or true_answer-1 or true_answer+1
          if  (submitted_answer==true_answer | submitted_answer==(true_answer+1) | submitted_answer==(true_answer-1)) {grade_table$Score[n] = "Correct"}
        }
      }

      if (answertype == "Numeric")
      {
        #make sure answer and submission can be converted to numeric
        #if not, this will produce NA and the rest of the if statement won't be evaluated
        #this means the original "Not Correct" score will remain.
        if ( !is.na(suppressWarnings(as.numeric(true_answer))) && !is.na(suppressWarnings(as.numeric(submitted_answer))) )
        {
          true_answer = as.numeric(true_answer)
          submitted_answer = as.numeric(submitted_answer)
          if (submitted_answer == true_answer) {grade_table$Score[n] = "Correct"}
        }
      }
      #expect rounded to the same digits as in the answer
      #do the rounding as needed

      if (answertype == "Rounded_Numeric")
      {
        #make sure answer and submission can be converted to numeric
        #if not, this will produce NA and the rest of the if statement won't be evaluated
        #this means the original "Not Correct" score will remain.
        if ( !is.na(suppressWarnings(as.numeric(true_answer))) && !is.na(suppressWarnings(as.numeric(submitted_answer))) )
        {
          digits = nchar(strsplit(true_answer, "\\.")[[1]][2]) #get the number of digits after the period in answer, so we can round solution to same
          true_answer = as.numeric(true_answer)*10^digits #convert to integer
          submitted_answer = round(as.numeric(submitted_answer)*10^digits,0) #convert to what should be an integer if given with the right digits, then round
          #allow mistake in student rounding
          if  (abs(submitted_answer-true_answer) < 2) {grade_table$Score[n] = "Correct"}
        }
      }
    } #end loop over all answers

    return(grade_table)

} #end main function




