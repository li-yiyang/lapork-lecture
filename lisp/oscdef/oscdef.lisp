;;;; oscdef.lisp --- Create a OSC server and handles OSC control signals

;;; Dependency:

;; (ql:quickload '(:cl-collider :str))

(uiop:define-package #:lapork.oscdef
  (:use :cl :osc :usocket)
  (:export
   #:*osc-server-running-p*
   #:*osc-server-port*
   #:start-osc-server
   #:stop-osc-server
   #:oscdef
   #:oscdef+
   #:oscdef-clear))

(in-package :lapork.oscdef)

(defparameter *oscdef-table* (make-hash-table :test 'equal)
  "Like OSCDef, define osc method tables.

+ key: osc commands
+ val: list of functions ")

(declaim (type (integer 0 65535) *osc-server-port*))
(defparameter *osc-server-port* 2424
  "OSC control server port. ")

(declaim (type (or null bt:thread) *osc-server-thread*))
(defparameter *osc-server-thread* nil
  "Thread of OSC control server. ")

(defun osc-server-running-p ()
  "Status/Control OSC server. "
  (and *osc-server-thread* (bt:thread-alive-p *osc-server-thread*)))

(defun (setf osc-server-running-p) (status)
  (if status
      (start-osc-server)
      (stop-osc-server)))

(define-symbol-macro *osc-server-running-p* (osc-server-running-p))

(defun stop-osc-server ()
  "Stop OSC server. "
  (when (osc-server-running-p)
    (bt:destroy-thread *osc-server-thread*)))

(defun osc-apply (name args)
  "Apply ARGS to OSC methods of NAME. "
  (ignore-errors
   (dolist (ctrl (gethash name *oscdef-table*))
     (apply ctrl args))))

(defun start-osc-server (&key (port *osc-server-port*) (buffer 1024) force restart
                         &aux (restart? (or force restart (= port *osc-server-port*))))
  "Start OSC server. "
  (declare (type (integer 0 65535) port)
           (type (integer 0) buffer))
  (when restart? (stop-osc-server))
  (setf *osc-server-port* port)
  (setf *osc-server-thread*
        (bt:make-thread
         (lambda ()
           (let ((server (socket-connect nil nil
                                         :local-port port
                                         :local-host #(127 0 0 1)
                                         :protocol   :datagram
                                         :element-type '(unsigned-byte 8)))
                 (buff   (make-sequence '(vector (unsigned-byte 8)) buffer)))
             (unwind-protect
                  (loop :for (timetag . msgs)
                          := (progn (socket-receive server buff buffer)
                                    (sc-osc::decode-bundle buff))
                        :do (dolist (msg msgs)
                              (apply #'osc-apply msg)))
               (when server (socket-close server)))))
         :name "osc-server")))

(flet ((ensure-name (name)
         (str:concat "/" (etypecase name
                           (symbol (str:camel-case name))
                           (string name)))))
  (defmacro oscdef (name lambda-list &body body)
    "Define OSC method of NAME, taking LAMBDA-LIST.
This would overwrite previous NAME method definition. "
    `(setf (gethash ,(ensure-name name) *oscdef-table*)
           (list (lambda ,lambda-list ,@body))))

  (defmacro oscdef+ (name lambda-list &body body)
    "Define OSC method of NAME, taking LAMBDA-LIST.
This would append to previous NAME method definition. "
    `(push (lambda ,lambda-list ,@body)
           (gethash ,(ensure-name name) *oscdef-table*))))

(defun oscdef-clear (&rest names)
  "Clear all the previous OSC method of NAME.

Parameters:
+ NAMES: names of methods to be cleared
  if not given, will clear all the previous defined methods "
  (if (endp names)
      (clrhash *oscdef-table*)
      (dolist (name names)
        (setf (gethash name *oscdef-table*) ()))))

;;;; oscdef.lisp ends here
