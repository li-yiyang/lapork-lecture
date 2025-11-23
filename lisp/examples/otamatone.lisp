;;;; otamatone.lisp --- A synth like otamatone

;;; see: https://otamatone.jp

(in-package :lapork)


;;; Initialize

(boot!)
(start-osc-server)

;; Clear previous defined OSC def and free all the nodes
(oscdef-clear)


;;; Synthsizer

(defsynth otamatone ((out 0) (freq 700) (gate 1) (amp 0.9)
                      (wowf 2) (wowa 0.1) (wowb 0.5) (wow 0))
  (let* ((vib (sc::*~ wow (sin-osc.ar wowf 0
                                      (sc::*~ freq wowa)
                                      (sc::*~ freq wowb))))
         (sig (saw.ar (sc::+~ vib freq) amp)))
    (out.ar out (* (env-gen.ar (adsr 0.01 0.01 0.95 0.01 1.0 -0.5) :gate gate)
                   (hpf.ar (lpf.ar sig freq) (sc::*~ freq 2))
                   amp))))

(defparameter *otamatone*
  (synth 'otamatone :gate 0))


;;; OSCDef

;; see lapork-lecture/touchosc/otamatone.tosc

(oscdef :otamatone-gate (gate)
  (ctrl *otamatone* :gate gate))

(oscdef :otamatone-freq (freq)
  (ctrl *otamatone* :freq (+ 200 (* 1000 freq))))

(oscdef :otamatone-wow (wow)
  (ctrl *otamatone* :wow wow))

;;;; otamatone.lisp ends here
