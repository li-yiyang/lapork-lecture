;;;; heart-beats.lisp

(in-package :lapork)

(defsynth heart ((out 0) (buf 0) (freq 0.8) (d-freq 0.01) (pan-freq 0.01)
                 (amp 0.5) (gate 1) (dur 1.0) (rate 1) (pos 0))
  (let* ((trig (impulse.kr (sc::+~ freq (white-noise.kr d-freq))))
         (pan  (sin-osc.kr pan-freq))
         (env  (env-gen.kr (adsr 0.01 0.01 1.0 3) :gate gate))
         (sig  (grain-buf.ar 2          ; channel
                             trig       ;
                             dur        ; dur
                             buf        ; buf
                             rate       ; rate
                             pos        ; pos
                             2          ; interp
                             pan        ; pan
                             -1)))      ; envbuf
    (out.ar out (* sig (white-noise.kr d-freq amp) env))))

;; Don't have breath sound, maybe i should record my own...
(defparameter *heart*
  (let ((buf (buffer-read-channel
              (asdf:system-relative-pathname :lapork "../samples/heartbeat.wav")
              :channels '(0))))
    (synth 'heart :buf buf)))

;;;; heart-beats.lisp
