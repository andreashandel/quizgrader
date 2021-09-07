quizmanager("D:/Dropbox/2021-3-fall-MADA/quizzes/MADA2021")


# Andreas comments

### QUIZMANAGER

ANALYSIS

* Analysis part not working. I removed creation of coursesummary.xlsx, now rest of code needs to be adjusted. Is that file really necessary? Prefer to not create extra files. 
* Thought: Add "due date" to log so one can sort quizzes easily "in order"? 

MANAGEMENT
* Fix check for valid course when user opens existing course in quizmanager_app.

* Can we change look of disabled tabs?

* I'm leaning toward only allowing addition of one full quiz at a time. A bit less convenient, but seems more stable/error proof. Also, maybe we should do it that if 
1) a NEW complete quiz is added, a student quiz is created at the same time, as well as a submission folder.
2) an EXISTING complete quiz is added, a new student quiz is created, NO submission folder (since that might contain previous submissions.)
Then we disable the "create student quiz files" button, since that's automatic.
We can leave it as currently is, i.e. whenever a quiz is newly added, all student quizzes will be rebuilt using the create_studentquizzes function.

If a complete quiz is removed, it will also remove the student quiz AND the submission folder. We'll issue a warning message there before proceeding.

* Maybe move "course overview" to top of that panel and make it run automatically? (if tricky, we can keep the press-button setup).

* With new setup as described above, deployment should not re-create student quizzes (unneccesary).

GENERAL
* Thorough testing of all quizmanager functionality (changes were made).


### QUIZGRADER

* Idea: Instead/in addition to students seeing their past submissions when submitting a new one, maybe split it so that they can log in and press a "see submissions" and see their previous submissions, without having to submit a new one.

* Connected to above idea: Instructor can provide an additional sheet of grades for other things (e.g. exercises) that would be loaded and shown to students.



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



# Medium importance

* Get quiz deletion to work in quizmanager.
  + ignore.txt utility? or reference completequizzes directory? for to-date quiz list

* Add code that creates subfolders in studentsubmissions for each quiz. Should either happen when grade tracking list is created or during deployment package. 
  + Subfolders are created when grade tracking list is created. Also, submissions are placed into quizid subfolder when submitted. **Need to make sure this doesn't overwrite files once class is in session.**

* UI alterations
  + Friendlier UI with built-in walkthrough. May play with CSS for navbarPage().
  + Separation of "Creating Course", "Modifying Course", "Analysis"?



# Minor priority

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
