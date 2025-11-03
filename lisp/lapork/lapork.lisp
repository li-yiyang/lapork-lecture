;;;; lapork.lisp --- Like `sc-user' for LapOrk lecture environment

(uiop:define-package #:lapork
  (:use
   :cl-collider
   :common-lisp
   :lapork.oscdef
   :lapork.plot))

(in-package :lapork)

(defparameter *supercollider-port* 2323
  "Port of external SuperCollider systh. ")

(defun boot! (&key (port *supercollider-port*) (host "localhost"))
  "Start the `*s*' external SuperCollider process. "
  (when (null *s*)
    (setf *s* (make-external-server "lapork" :port port :host host)))
  (unless (boot-p *s*)
    (server-boot *s*)))

(defun quit! ()
  "Quit `*s*'. "
  (when (boot-p *s*)
    (server-quit *s*)))

;;;; lapork.lisp ends here
