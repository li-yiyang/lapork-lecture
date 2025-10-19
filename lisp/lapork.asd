;;;; lapork.asd --- System definition of LapOrk

(defsystem #:lapork
  :author ("凉凉")
  :license "GPL"
  :version "0"
  :description "LapOrk"
  :depends-on (:cl-collider :lapork/oscdef)
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

;;;; lapork.asd ends here
