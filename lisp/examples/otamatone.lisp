;;;; otamatone.lisp --- A synth like otamatone

;;; see: https://otamatone.jp

(in-package :lapork)

(defsynth otamatone ((out 0) (freq 700) (gate 1) (amp 0.9)
                      (wowf 2) (wowa 0.1) (wowb 0.5) (wow 0))
  (let* ((vib (sc::*~ wow (sin-osc.ar wowf 0
                                      (sc::*~ freq wowa)
                                      (sc::*~ freq wowb))))
         (sig (saw.ar (sc::+~ vib freq) amp)))
    (out.ar out (* (env-gen.ar (adsr 0.01 0.01 0.95 0.01 1.0 -0.5) :gate gate)
                   (hpf.ar (lpf.ar sig freq) (sc::*~ freq 2))
                   amp))))

;;;; otamatone.lisp ends here
