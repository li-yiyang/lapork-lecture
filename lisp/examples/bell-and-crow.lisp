;;;; bell-and-crow.lisp --- A synth using bell and crow sound

(in-package :lapork)


;;; Initialize

(boot!)
(start-osc-server)

;; Clear previous defined OSC def and free all the nodes
(oscdef-clear)


;;; Synthsizer

(defsynth crow ((buf 0) (out 0) (freq 0.1) (pan-freq 0.1)
                (amp 0.5) (gate 1))
  (let* ((trig (impulse.kr freq))
         (pan  (sin-osc.kr pan-freq))
         (env  (env-gen.kr (adsr 0.01 0.01 1.0 1) :gate gate))
         (sig  (grain-buf.ar 2
                             trig
                             1.0
                             buf
                             1
                             0
                             2
                             pan
                             -1)))
    (out.ar out (* amp sig env))))

(defparameter *crow*
  (let ((buf (buffer-read-channel
              (asdf:system-relative-pathname :lapork "../samples/crow.wav")
              :channels '(0))))
    (synth 'crow :buf buf)))

(let ((buf (buffer-read-channel
            (asdf:system-relative-pathname :lapork "../samples/churchbell.flac")
            :channels '(0))))
  (oscdef :bell (gate)
    (unless (zerop gate)
      (play (play-buf.ar 1 buf)))))


;;; OSCDef

(oscdef :crow-on (gate)
  (ctrl *crow* :gate gate))

(oscdef :crow-amp-freq (amp freq)
  (ctrl *crow* :freq (+ 0.2 (* 0.5 freq)))
  (ctrl *crow* :amp  (+ 0.6 (* 0.7 amp))))

;;;; bell-and-crow.lisp ends here
