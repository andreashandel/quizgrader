# Andreas comments

* Can one make it that user can only leave the "course Location" area if a course has been set, otherwise an error message shows up?

* Maybe create a .txt file inside a quiz folder (with the same name as the folder). Then the package functions look for that file as an indication that the chosen folder is a proper quiz folder and if not produce an error message. Or maybe just set up a new quiz as an R project with a .rproj file. This can be checked to make sure it's a quiz folder. And also if one clicks on an existing R project file, the quizmanager pops up with the current quiz selected? Not sure that's possible though.

* Analysis part not working. I removed creation of coursesummary.xlsx, now rest of code needs to be adjusted. Is that file really necessary? Prefer to not create extra files. 

* Add "due date" to log so one can sort quizzes easily "in order"?

# Main importance

* Analysis functionality
  + adapt old code for compiling gradelists (now logs) and re-grading all submissions
    - how to have a list of included students / quizzes (students via latest student list; figure out quiz deletion to solve quiz analysis)

* Get grading app to work using the self-hosted shiny server setup.
  + currently (01 July 2021) works (make note that permissions needed to be changed after initial deployment to allow write (maybe more) for app)
  + investigate ShinyApps server deployment

* Figure out and implement setup for quiz/course maintenance while course is running.
  + establish *idealized* workflow scenario (feeds into next)

* Keep updating vignettes.

* check_studentlist()
  + find where used / incorporate it in workflow




# Medium importance

* Get quiz deletion to work in quizmanager.
  + ignore.txt utility? or reference completequizzes directory? for to-date quiz list

* Add code that creates subfolders in studentsubmissions for each quiz. Should either happen when grade tracking list is created or during deployment package. 
  + Subfolders are created when grade tracking list is created. Also, submissions are placed into quizid subfolder when submitted. **Need to make sure this doesn't overwrite files once class is in session.**

* UI alterations
  + Friendlier UI with built-in walkthrough. May play with CSS for navbarPage().
  + Separation of "Creating Course", "Modifying Course", "Analysis"?



# Minor priority

* Allow adding multiple quizzes at a time through quizmanager shiny app

* Need to harmonize quizgrader and the solution files from DSAIDE and DSAIRM

* Regrade functionality?
  + could just be built into the quiz analysis section of quizmanager.R rather than updating log file (would be a pain)

* Course summaries (studentlist, quizlist, overview?)
  + print / download schedule document?



# General Notes

How to do data storage with shinyappsio
https://shiny.rstudio.com/articles/persistent-data-storage.html

Keeping a temporary "archive" of old scripts within auxilliary.


## 14 June 2021

New function read_studentlist.R; pretty much same as read_gradelist.R was.

Now, submissions are saved in two formats: raw submission excel file and an adaptation of the result table (referred to as submission logs). 

New function to process the submission logs (compile_submission_logs.R) seems to work well for a single studentid; need to test it on a batch of studentids as this will be used for the analysis tab of quizmanager.R app. These are saved as simple text files. 

Another new function generates a summary of the quizzes in the complete quizzes folder (summarize_course.R). A rather small function. Still undecided where to incorporate this into the workflow; likely it will have its own "page" on quiz manager app to review before deployment, but it does need to be generated automatically for downstream purposes. This could be potentially inefficient to do repeatedly as it does read each excel file separately (it may be possible to have some code to query the closed excel file? But would require VBA so not sure if feasible, needed.). Would be good basis for generating "schedule" that teachers could give students / include in syllabus.

Without the gradelist, the largest speedbump (so far) is the functionality of compute_student_stats.R to give a "progress report" upon submission. Without gradelist, there is no simple readfile and average scores. However, the above two functions that compile the submissions logs and generate a summary of quizzes will be used together to generate stats. I will merge submission logs to course summary to compute to-date statistics (avoiding problem of missing quizzes in calculations and no associated due dates). For now, the compute_student_stats.R output is omitted from app.R in place of the raw submissions log (to be fixed ASAP).

Due date and attempts road blocks in place. Reading solution file before submission file allows both. Due date checked first comparing system date to due date within solution file. Attempts then checked comparing attempt number in solution file to a count of "studentid-quizid-.xlsx" files saved in the submissions folder.

quizmanager.R app is paginated. Buttons work, but need better placement.


## 16 June 2021

Adapt to a single log file; 
generate shell during course creation and package with deployment; 
portion of log file can be printed during submission in the grading app;

public vs private functions: decide which (if any) should be private;

singly-directional flow of files (schematic?);


## 23 June 2021

course summary with final rechecking and status checklist just before deployment
play with workflow on server
- alternative to hadley/emo package?

remove the quizstats from app.R, just show table and let them calculate themselves
add time to the submissions log

look for implementation of check_studentlist.R

update docs for developers file with structure, descriptions, ...

useful to have packaging on server side?


## 30 June 2021

Delete quiz functionality during initial set-up versus post-doc

Update notes / documentation to be able to pick back up quickly
