(defpackage :cl-csv-test
  (:use :cl :cl-user :cl-csv :lisp-unit :iter))

(in-package :cl-csv-test)
(cl-interpol:enable-interpol-syntax)

(defmacro assert-length (exp it &rest them)
  `(assert-eql ,exp (length ,it) ,@them))

(defun run-all-tests (&optional (use-debugger t))
  (let ((lisp-unit:*print-failures* t)
        (lisp-unit:*print-errors* t)
        (lisp-unit::*use-debugger* use-debugger))
   (run-tests :all)))

(defparameter +test-csv-quoted-path+
  (asdf:system-relative-pathname :cl-csv "tests/test-csv-quoted.csv"))
(defparameter +test-csv-unquoted-path+
  (asdf:system-relative-pathname :cl-csv "tests/test-csv-unquoted.csv"))
(defparameter +test-csv-unquoted-no-trailing-path+
  (asdf:system-relative-pathname :cl-csv "tests/test-csv-unquoted-no-trailing.csv"))
(defparameter +test-multiline+
  (asdf:system-relative-pathname :cl-csv "tests/test-multiline-data.csv"))

(defparameter +test-files+
  (list
   +test-csv-quoted-path+
   +test-csv-unquoted-path+
   +test-csv-unquoted-no-trailing-path+) )

(defparameter *test-csv1-rows*
  '(("first name" "last name" "job \"title\"" "number of hours" "id")
    ("Russ" "Tyndall" "Software Developer's, \"Position\"" "26.2" "1")
    ("Adam" "Smith" "Economist" "37.5" "2")
    ("John" "Doe" "Anonymous Human" "42.1" "3")
    ("Chuck" "Darwin" "Natural Philosipher" "17.68" "4")
    ("Bill" "Shakespear" "Bard" "12.2" "5")
    ("James" "Kirk" "Starship Captain" "13.1" "6")
    ("Bob" "Anon" "" "13.1" "6")
    ("Mr" "Iñtërnâtiônàlizætiøn" "" "1.1" "0")))

(defparameter *test-csv1*
"\"first name\",\"last name\",\"job \"\"title\"\"\",\"number of hours\",\"id\"
\"Russ\",\"Tyndall\",\"Software Developer's, \"\"Position\"\"\",\"26.2\",\"1\"
\"Adam\",\"Smith\",\"Economist\",\"37.5\",\"2\"
\"John\",\"Doe\",\"Anonymous Human\",\"42.1\",\"3\"
\"Chuck\",\"Darwin\",\"Natural Philosipher\",\"17.68\",\"4\"
\"Bill\",\"Shakespear\",\"Bard\",\"12.2\",\"5\"
\"James\",\"Kirk\",\"Starship Captain\",\"13.1\",\"6\"
\"Bob\",\"Anon\",\"\",\"13.1\",\"6\"
\"Mr\",\"Iñtërnâtiônàlizætiøn\",\"\",\"1.1\",\"0\"
")

(defparameter *test-csv1-v2*
"first name,last name,\"job \"\"title\"\"\",number of hours,id
Russ,Tyndall,\"Software Developer's, \"\"Position\"\"\",26.2,1
Adam,Smith,Economist,37.5,2
John,Doe,Anonymous Human,42.1,3
Chuck,Darwin,Natural Philosipher,17.68,4
Bill,Shakespear,Bard,12.2,5
James,Kirk,Starship Captain,13.1,6
Bob,Anon,,13.1,6
Mr,Iñtërnâtiônàlizætiøn,,1.1,0
")

(defparameter *test-csv-no-trailing-newline*
  "first name,last name,\"job \"\"title\"\"\",number of hours,id
Russ,Tyndall,\"Software Developer's, \"\"Position\"\"\",26.2,1")

(defparameter *test-csv-data-with-newlines*
  "first name,last name,\"job \"\"title\"\"\",number of hours,id
Russ,Tyndall,\"Software Developer's,
 \"\"Position\"\"\",26.2,1")

(defparameter *test-csv-data-waiting-next-error*
  "\"Which of the following is an appropriate calming technique or statement:
A. \"\"I can help you.\"\"
B. \"\"Shut up.\"\"
C. \"\"If you don't calm down I'm not sending anyone.\"\"
D. \"\"Ma'am, ma'am\ ma'am!\"\"\",A")

(define-test parsing-1
  (assert-equal *test-csv1-rows* (read-csv *test-csv1*))
  (assert-equal *test-csv1-rows* (read-csv *test-csv1-v2*)))

(define-test writing-1
  (assert-equal *test-csv1* (write-csv *test-csv1-rows* :always-quote t)))

(define-test parsing-errors
  (assert-error 'csv-parse-error
      (read-csv-row
       "first name, a test\" broken quote, other stuff"))
  (assert-error 'csv-parse-error
      (read-csv-row
       "first name,\"a test broken quote\" what are these chars, other stuff"))
  (assert-error 'csv-parse-error
      (read-csv-row
       "first name,\"a test unfinished quote, other stuff"))
  (assert-eql 3 (length (read-csv-row "first name, \"a test broken quote\", other stuff")))
  )

(define-test no-trailing-parse
  (let* ((data (read-csv *test-csv-no-trailing-newline*))
         (str (write-csv data :always-quote t))
         (data2 (read-csv str)))
    (assert-equal 2 (length data))
    (assert-equal 5 (length (first data)))
    (assert-equal 5 (length (second data)))
    (assert-equal data data2)))

(define-test data-with-newlines
  (let* ((data (read-csv *test-csv-data-with-newlines*))
         (str (write-csv data :always-quote t))
         (data2 (read-csv str)))
    (assert-equal 2 (length data))
    (assert-equal 5 (length (first data)))
    (assert-equal 5 (length (second data)))
    (assert-equal
        "Software Developer's,
 \"Position\""
        (third (second data)))
    (assert-equal data data2)))

(define-test data-with-whitespace
  (let ((data (read-csv-row "  first    ,     last ,  \" other \"  ")))
    (assert-equal '("first" "last" " other ") data)))

(define-test files
  (iter (for csv in +test-files+)
    (for data = (read-csv csv))
    (assert-equal *test-csv1-rows* data csv)))

(define-test multi-line-file
  (let ((data (read-csv +test-multiline+)))
    (assert-equal 2 (length data) data)
    (assert-equal "test
of
multiline" (nth 3 (first data)) ))
  )

(define-test dont-always-quote-and-newline
  (let* ((row '("Russ" "Tyndall" "Software Developer's, \"Position\"" "26.2" "1" ","))
         (res (write-csv-row row :always-quote nil :newline #?"\n")))
    (assert-equal #?"Russ,Tyndall,\"Software Developer's, \"\"Position\"\"\",26.2,1,\",\"\n"
        res)))

(define-test dont-always-quote-and-newline-2
  (let* ((row '("," #?"a\r\nnewline\r\ntest\r\n"))
         (res (write-csv-row row :always-quote nil :newline #?"\n")))
    (assert-equal #?"\",\",\"a\r\nnewline\r\ntest\r\n\"\n"
        res)))

(define-test cause-error
  (let ((data (read-csv *test-csv-data-waiting-next-error*)))
    (assert-true data)))

(define-test chars-in-test
  (assert-true (cl-csv::chars-in "a" "abcdef"))
  (assert-false (cl-csv::chars-in "qu" "abcdef"))
  (assert-true (cl-csv::chars-in "qu" "asdfqasdf"))
  (assert-true (cl-csv::chars-in "qu" "asdfuasdf"))
  (assert-true (cl-csv::chars-in (list "q" "u") "asdfuasdf"))
  (assert-true (cl-csv::chars-in (list #\q #\u) "asdfuasdf"))
  (assert-true (cl-csv::chars-in (list "q" #\u) "asdfqasdf")))

(define-test iterate-clauses
  (iter
    (for (a b c) in-csv "1,2,3
4,5,6")
    (assert-equal (if (first-time-p) "1" "4") a)
    (assert-equal (if (first-time-p) "2" "5") b)
    (assert-equal (if (first-time-p) "3" "6") c)
    (for i from 0)
    (finally (assert-equal 1 i)))

  ;; test SKIPPING-HEADER option
  (iter
    (for (a b c) in-csv "1,2,3
4,5,6" SKIPPING-HEADER T)
    (assert-equal  "4" a)
    (assert-equal  "5" b)
    (assert-equal  "6" c)
    (for i from 0)
    (finally (assert-equal 0 i)))

  ;; test SEPARATOR
  (iter
    (for (a b c) in-csv "1|2|3
4|5|6" SKIPPING-HEADER T SEPARATOR #\|)
    (assert-equal  "4" a)
    (assert-equal  "5" b)
    (assert-equal  "6" c)
    (for i from 0)
    (finally (assert-equal 0 i))))

(define-test sampling-iterate
  (assert-length
   9 (iter (for row in-csv *test-csv1*)
       (cl-csv:sampling row)))
  (assert-length
   2 (iter (for row in-csv *test-csv1*)
       (cl-csv:sampling row into sample size 2)
       (finally (return sample))))
  (assert-length
   2 (read-csv-sample *test-csv1* 2))
  (assert-length
   3 (iter (for row in-csv *test-csv1* skipping-header t)
       (cl-csv::sampling row size 3)))
  (assert-length
   9 (iter (for row in-csv *test-csv1*)
       (cl-csv:sampling row into sample size 25)
       (finally (return sample)))))
