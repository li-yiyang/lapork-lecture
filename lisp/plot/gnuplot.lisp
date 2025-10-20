;;;; gnuplot.lisp --- A trivial bindings to Gnuplot

(in-package :lapork.plot)

(deftype gnuplot-term ()
  "Gnuplot terminal. "
  '(member :qt :png))

(deftype gnuplot-style ()
  "Gnuplot style. "
  '(member :lines :points))

(declaim (type (or null uiop:process-info) *plotter*)
         (type (or null gnuplot-term)      *term*)
         (type gnuplot-style               *style*))

(defparameter *plotter* nil
  "External process to gnuplot. ")

(defparameter *term* nil
  "Current Gnuplot terminal. ")

(defparameter *style* :lines
  "Default Gnuplot style. ")

(defparameter *plots* ()
  "Use this to plot. ")

(defparameter *stream* nil
  "Gnuplot stream. ")

(defparameter *gnuplot-debug* nil
  "Set to non nil would print Gnuplot code for debug. ")

(defparameter *gnuplot-env* ()
  "Gnuplot environments. ")

;;; External process management

(defun plotter-alive-p ()
  "Test if `lapork.plot::*plotter*' is running. "
  (and *plotter* (uiop:process-alive-p *plotter*)))

(defun start-plotter ()
  "Start external gnuplot `lapork.plot::*plotter*'. "
  (unless (plotter-alive-p)
    (setf *plotter* (uiop:launch-program
                     "gnuplot"
                     :input  :stream
                     :output :stream))
    (let ((*stream* (uiop:process-info-input *plotter*)))
      (%init :term :qt))
    t))

(defun quit-plotter ()
  "Quit external gnuplot `lapork.plot::*plotter*'. "
  (when (plotter-alive-p)
    (uiop:terminate-process *plotter*)
    (setf *plotter* nil)
    t))

;; The gnuplot code is a simplified subset code of my physics data processing
;; code, which is messy right now.

(defun listfy (elem)
  "Ensure ELEM as list. "
  (if (listp elem) elem (list elem)))

(defun %init-term (term output)
  (ecase term
    (:qt
     (write-line "unset term"  *stream*)
     (write-line "set term qt" *stream*)
     (setf *term* :qt))
    (:png
     (assert (typep output '(or string pathname)))
     (write-line "unset term"        *stream*)
     (write-line "set term png" *stream*)
     (format *stream* "set output ~S~%" (uiop:native-namestring output))
     (setf *term* :png))))

(defun %init (&key title term output &allow-other-keys)
  "Write gnuplot initial code to STREAM. "
  (when title (write-line "unset title" *stream*))
  (when term  (%init-term term output)))

(defun %plot (data &key xrange yrange &allow-other-keys)
  "plot [xrange] [yrange] ~{data with color linewidth linecolor~^, ~}"
  (declare (type (or null (cons number number)) xrange yrange))
  (cond (data
         (unless xrange
           (write-line "set autoscale x" *stream*))
         (unless yrange
           (write-line "set autoscale y" *stream*))
         (write-string "plot " *stream*)
         (when xrange
           (format *stream* "[x=~F:~F] " (car xrange) (cdr xrange)))
         (when yrange
           (format *stream* "[y=~F:~F] " (car yrange) (cdr yrange)))
         (flet ((write-data (dat)
                  (destructuring-bind
                      (data &key with color title linewidth using &allow-other-keys)
                      dat
                    (format *stream* "~A " data)
                    (when using     (format *stream* "using ~{~A~^:~} " using))
                    (when with      (format *stream* "with ~A "         with))
                    (when color     (format *stream* "linecolor ~A "    color))
                    (when linewidth (format *stream* "linewidth ~A "    linewidth))
                    (when title     (format *stream* "title ~S "        title)))))
           (write-data (first data))
           (dolist (dat (rest data))
             (write-string ", " *stream*)
             (write-data   dat))
           (format *stream* "~%")))
        (t (write-line "replot" *stream*))))

(defmacro with-plot ((&rest attrs
                      &key title term output (debug '*gnuplot-debug*)
                      &allow-other-keys)
                     &body body)
  "Create an Gnuplot plotting environment. "
  (declare (ignore title term output))
  (let ((msg (gensym "MSG"))
        (res (gensym "RES")))
    `(let ((*gnuplot-debug* ,debug)
           (*gnuplot-env* (list ,@attrs))
           ,msg ,res)
       (unwind-protect
            (progn
              (setf ,msg (with-output-to-string (*stream*)
                           (let ((*plots* ()))
                             (apply #'%init *gnuplot-env*)
                             (setf ,res (progn ,@body))
                             (apply #'%plot *plots* *gnuplot-env*))))
              ,res)
         (when (if *gnuplot-debug* (print ,msg) ,msg)
           (start-plotter)
           (let ((stream (uiop:process-info-input *plotter*)))
             (write-line ,msg stream)
             (force-output    stream)))))))

(defmacro with-data (data &body body)
  "Bind DATA and BODY. "
  `(let ((,data (format nil "$~A" (gensym "DATA"))))
     (format *stream* "~A << EOD~%" ,data)
     ,@body
     (format *stream* "~&EOD~%")
     ,data))

(defmacro ensure-attrs (attrs &rest key-values)
  `(progn ,@(loop :for (key value) :in key-values
                  :collect `(unless (getf ,attrs ,key)
                              (push ,value ,attrs)
                              (push ,key   ,attrs)))))

(defgeneric plot (data &key title with color linewidth using
                  &allow-other-keys)
  (:documentation
   "Prepare to plot DATA. ")
  (:method :around (data &rest attrs &key term output)
    (declare (ignorable data attrs))
    (if *gnuplot-env*
        (call-next-method)
        (with-plot (:within-gnuplot-env t :term term :output output)
          (call-next-method))))
  (:method ((data string) &rest attrs)
    (ensure-attrs attrs (:with *style*))
    (push (cons data attrs) *plots*)
    data)
  (:method ((data symbol) &rest attrs)
    (let ((dat (format nil "$~A" data)))
      (ensure-attrs attrs (:with *style*))
      (push (cons dat attrs) *plots*)
      dat))
  (:method ((data list) &rest attrs)
    (with-data dat
      (cond ((atom (first data))
             (let ((idx -1))
               (flet ((listfy (elem) (list (incf idx) elem)))
                 (format *stream* "~{~{~A~^ ~}~%~}"
                         (mapcar #'listfy data)))))
            (t (format *stream* "~{~A~%~}" data)))
      (ensure-attrs attrs
                    (:with *style*)
                    (:using '(1 2)))
      (push (cons dat attrs) *plots*))))

;;;; gnuplot.lisp ends here
