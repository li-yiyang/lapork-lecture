;;;; motor-engine.lisp --- Just-like motor engine

(in-package :lapork)

;;; tututututtutu...

(start-osc-server)

(defsynth motor-engine ((freq 50) (amp 0.5) (out 0) (gate 1))
  (let* ((pulse    (pulse.ar freq))
         (saw      (saw.ar   freq))
         (sub      (pulse.ar (/ freq 2.0)))
         (noise    (white-noise.ar 0.1))
         (mix      (mix (list pulse saw sub noise)))
         (env      (env-gen.ar (adsr 0.05 0.1 1.0 0.5) :gate gate))
         (filtered (bpf.ar mix (* 10 freq) 0.1)))
    (out.ar out (* filtered env amp))))

(defparameter *motor* (synth 'motor-engine :gate 0))

(oscdef :motor-speed (x)
  (ctrl *motor* :freq (+ 12 (* (sqrt x) 50))))

(oscdef :motor-on (gate)
  (ctrl *motor* :gate (print gate)))

;;;; motor-engine.liep ends here
