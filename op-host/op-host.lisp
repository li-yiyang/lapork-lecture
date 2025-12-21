;;;; op-host.lisp

;;; Usage:
;; for developer, use:
;;
;; sbcl --load op-host.lisp should work
;;
;; you may need:
;; + https://github.com/li-yiyang/func2exec
;;
;; or you could just use the binary (build on macOS M2)
;;
;; ./bin/op-host ../openprocessing/CattyDizi.js
;;
;; having fun...

(ql:quickload '(:cffi :shasht :func2exec :osc :usocket))

(defpackage #:lapork.op-host
  (:use :cl :cffi))

(in-package :lapork.op-host)

(eval-when (:load-toplevel :compile-toplevel :execute)
  (defun libwebview-path ()
    (merge-pathnames "lib/"
                     #+sbcl sb-ext:*runtime-pathname*
                     #-sbcl (uiop:getcwd)))
  (push '(libwebview-path) cffi:*foreign-library-directories*))

(define-foreign-library libwebview
  (t "libwebview.dylib"))

(defcfun (webview_create "webview_create") :pointer
  (debug  :int)
  (window :pointer))

(defcfun (webview_set_title "webview_set_title") :void
  (webview :pointer)
  (name    :string))

(defcenum webview_hint_t :none :min :max :fixed)

(defcfun (webview_set_size "webview_set_size") :void
  (webview :pointer)
  (width   :int)
  (height  :int)
  (hint    webview_hint_t))

(defcfun (webview_init "webview_init") :void
  (webview  :pointer)
  (js       :string))

(defcfun (webview_bind "webview_bind") :void
  (webview  :pointer)
  (name     :string)
  (callback :string)
  (arg      :pointer))

(defcfun (webview_dispatch "webview_dispatch") :void
  (webview  :pointer)
  (callback :pointer)
  (arg      :pointer))

(defcfun (webview_set_html "webview_set_html") :void
  (webview  :pointer)
  (html     :string))

(defcfun (webview_run "webview_run") :void
  (webview  :pointer))

(defcfun (webview_destroy "webview_destroy") :void
  (webview  :pointer))

(defcfun (webview_return "webview_return") :void
  (webview  :pointer)
  (seq      :string)
  (status   :int)
  (result   :string))

(defparameter *osc-host* "localhost")
(defparameter *osc-port* 2424)

;; (trace osc:encode-message)

(defcallback osc_sendmsg :void ((id :string) (req :string) (webview :pointer) (arg :pointer))
  (declare (ignore arg))
  (let ((s (usocket:socket-connect *osc-host* *osc-port*
                           :protocol :datagram
                           :element-type '(unsigned-byte 8)))
        (b (apply #'osc:encode-message (shasht:read-json* :stream       req
                                                          :array-format :list)))
        (status 1))
    (unwind-protect (progn (usocket:socket-send s b (length b))
                           (setf status 0))
      (when s (usocket:socket-close s)))
    (webview_return webview id status "{}")))

(defvar *js*)

(defparameter *html*
  "<head>
<script src=\"https://cdn.jsdelivr.net/npm/p5@1.11.7/lib/p5.js\"></script>
<script>
function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
}

~A
</script>
</head>
<body style='margin: 0;'>
</body>")

(defcallback op_host_reload :void ((id :string) (req :string) (webview :pointer) (arg :pointer))
  (declare (ignore arg req))
  (webview_return   webview id 0 "{}")
  (webview_set_html webview (format nil *html* (uiop:read-file-string *js*))))

(defun main (js &key (host *osc-host*) (port *osc-port*))
  "Host Openprocessing JS code. "
  (load-foreign-library 'libwebview)
  (setf *osc-host* host
        *osc-port* port
        *js*       js)
  (sb-int:set-floating-point-modes :traps nil)
  (let ((w  (webview_create 1 (null-pointer))))
    (webview_set_title w "OP-HOST")
    (webview_set_size  w 400 400 :none)
    (webview_bind      w "osc_msgsend"    (callback osc_sendmsg)    (null-pointer))
    (webview_bind      w "op_host_reload" (callback op_host_reload) (null-pointer))
    (webview_set_html  w (format nil *html* (uiop:read-file-string *js*)))
    (webview_run       w)
    (webview_destroy   w)
    (uiop:quit)))

(func2exec:f2e 'main
               :executable "op-host"
               :parse-hint '((js    . :plain)
                             (host  . :plain)
                             (port  . :read)
                             (debug . :flag)))
