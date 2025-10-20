;;;; lapork.asd --- System definition of LapOrk

(defsystem #:lapork
  :author ("凉凉")
  :license "GPL"
  :version "0"
  :description "LapOrk"
  :depends-on (:cl-collider :lapork/oscdef :lapork/plot)
  :serial t
  :pathname "lapork"
  :components
  ((:file "lapork")))

(defsystem #:lapork/oscdef
  :author ("凉凉")
  :license "GPL"
  :version "0"
  :description "OscDef for cl-collider"
  :depends-on (:cl-collider :str)
  :serial t
  :pathname "oscdef"
  :components
  ((:file "oscdef")))

(defsystem #:lapork/plot
  :author ("凉凉")
  :license "GPL"
  :version "0"
  :description "Add plot ability to cl-collider. "
  :depends-on (:cl-collider :str)
  :serial t
  :pathname "plot"
  :components
  ((:file "package")
   (:file "gnuplot")
   (:file "plot")))


;;;; lapork.asd ends here
