;;;; phone.lisp --- Like a phone dial tone

;;; Commentary:

;; References:
;; + Technical features of push-button telephone sets (ITU)
;;   https://www.itu.int/rec/T-REC-Q.23-198811-I/en

(in-package :lapork)


;;; Initialize

(boot!)
(start-osc-server)

;; Clear previous defined OSC def and free all the nodes
(oscdef-clear)


;;; Synthsizer

(defsynth phone-tone ((gate 1) (amp 0.5) (out 0) (low 350) (high 440))
  (out.ar out (* 0.5 amp
                 (+ (sin-osc.ar low)
                    (sin-osc.ar high))
                 (env-gen.kr (adsr 0.01 0.01 0.8 0.01) :gate gate))))

(defparameter phone
  (synth 'phone-tone :gate 0))


;;; OSCDef

;; see lapork-lecture/touchosc/lecture-03/phone-calling.tosc for
;; the TouchOSC control panel design

(let ((on/off 0))
  (oscdef :tone-switch (gate)
    (ctrl phone :gate (setf on/off gate)))

  (oscdef :tone-silent (gate)
    (if (zerop gate) ;; OFF
        (ctrl phone :gate on/off)
        (ctrl phone :gate 0))))

(macrolet ((tone* (high-freqs &rest tone-table)
             `(progn
                ,@(loop :for (low . tones) :in tone-table
                        :collect
                        (loop :for tone :in tones
                              :for high :in high-freqs
                              :collect
                              `(oscdef ,(format nil "tone~A" tone) (gate)
                                 (if (zerop gate)
                                     (ctrl phone :low 350  :high 440)
                                     (ctrl phone :low ,low :high ,high))))
                          :into defs
                        :finally (return (apply #'append defs))))))
  (tone* (        1209 1336 1477 1633)
         (697     1    2    3    A)
         (770     4    5    6    B)
         (852     7    8    9    C)
         (941     *    0    |#|  D)))

;;;; phone.lisp ends here
