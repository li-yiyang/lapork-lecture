;;;; package.lisp --- Package definition for lapork.plot

(uiop:define-package #:lapork.plot
  (:use :cl)
  (:export
   #:quit-plotter
   #:start-plotter
   #:scope
   #:freqscope
   #:envscope
   #:plot))

(in-package :lapork.plot)

;;;; package.lisp ends here
