;;;; dizi.lisp

(in-package :lapork)

(defsynth dizi ((freq 440) (out 0) (amp 0.5) (gate 1) (pressure 0.8) (buzz 0.95))
  (let* ((env     (env-gen.kr (adsr 0.05 0.3 pressure 0.5) :gate gate))
         (exciter (bpf.ar (white-noise.ar 1.0)
                          2000 0.5))
         (pipe    (comb-l.ar (* exciter (- 1.0 buzz))
                             0.02
                             (/ freq)
                             1.5))
         (buzzsig (distort (var-saw.ar (* freq 2.001)
                                       0.0
                                       (range (sin-osc.kr 0.1) 0.1 0.4)
                                       0.2)))
         (sig     (+ (* pipe (- 1.0 buzz)) (* buzz buzzsig))))
    (out.ar out (pan2.ar (* sig env amp) 0.0 1))))

(defparameter *dizi* (synth 'dizi :gate 0))

(oscdef :dizi-gate (gate)
  (ctrl *dizi* :gate gate))

(oscdef :dizi-freq (freq)
  (ctrl *dizi* :freq freq))

;;;; dizi.lisp ends here
