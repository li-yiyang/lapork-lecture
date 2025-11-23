;;;; plot.lisp ---- Plot using

;; The plotting code is ported from cl-collider issue #81:
;; https://github.com/byulparan/cl-collider/issues/81
;;

(in-package :lapork.plot)

(defmacro with-buffer ((buffer &key
                                 (channels 1)
                                 (duration 0.1 duration?)
                                 (sample-rate '(sc::sample-rate sc:*s*))
                                 (frames   100))
                       &body body)
  "Alloc a new BUFFER and free it after using. "
  `(let ((,buffer (sc:buffer-alloc
                   ,(if duration?
                        `(truncate (* ,duration ,sample-rate))
                        frames)
                   :chanls ,channels)))
     (unwind-protect (progn ,@body)
       (sc:buffer-free ,buffer))))

;; envolope
(defmethod plot ((env sc:env) &rest attrs &key (frames 100) &allow-other-keys)
  "Plot ENV as envelope. "
  (with-data dat
    (let ((data (sc:env-as-signal env frames)))
      (loop :for f :from 0
            :for d :in data
            :do (format *stream* "~D ~F~%" f d))
      (ensure-attrs attrs
                    (:with  *style*)
                    (:using '(1 2)))
      (push (cons dat attrs) *plots*))))

;; buffer
(defmethod plot ((buff sc::buffer) &rest attrs
                 &key
                   (start  0)
                   bin-width
                   (duration 100 duration?)
                   (frames   100 frames?)
                   (end      100 end?)
                   (sample-rate (sc::sr buff))
                   (channels '(0))
                 &allow-other-keys
                 &aux
                   (chns   (listfy channels))
                   (start! (etypecase start
                             (integer start)
                             (float   (truncate (* start sample-rate)))))
                   (end!   (truncate
                            (min (sc:frames buff)
                                 (cond (end?
                                        (etypecase end
                                          (integer end)
                                          (float   (* end sample-rate))))
                                       (duration?
                                        (etypecase duration
                                          (keyword
                                           (ecase duration
                                             ((:all :full) (sc:frames buff))
                                             (:half (/ (sc:frames buff) 2))))
                                          (integer
                                           (+ start! duration))
                                          (float
                                           (+ start! (* duration sample-rate)))))
                                       (frames?
                                        (+ start! (the integer frames)))
                                       (t 100))))))
  "Plot BUFFER. "
  (let ((buffer (sc:buffer-to-array buff
                                    :channels chns
                                    :start    start!
                                    :end      end!)))
    (loop :with frames := (array-dimension buffer 1)
          :with bins   := (or bin-width
                              (cond ((<= 0   frames 100)  1)
                                    ((<= 100 frames 500)  2)
                                    (t                   10)))
          :for chn :in chns
          :do (with-data dat
                (loop :for idx :below frames
                      :when (zerop (mod idx bins))
                        :do (format *stream*
                                    "~F ~F~%"
                                    (/ idx sample-rate)
                                    (aref buffer chn idx)))
                (ensure-attrs attrs
                              (:with *style*)
                              (:using '(1 2))
                              (:title (if (sc::path buff)
                                          (pathname-name (sc::path buff))
                                          dat)))
                (push (cons dat attrs) *plots*)))))

;; this cannot work, not sure why
;; (defmethod plot ((ugen sc::ugen) &rest attrs
;;                  &key (duration 0.1)
;;                  &allow-other-keys)
;;   (with-buffer (buffer :duration duration)
;;     (sc:proxy :plot
;;       (sc:buf-wr.ar ugen buffer (sc:line.ar 0 (sc:buf-frames.kr buffer) duration :act :free)))
;;     (ensure-attrs attrs (:end (sc:frames buffer)))
;;     (apply #'plot buffer attrs)))

;; TODO: #plot
;; duration
(defmacro scope (body &rest attrs
                 &key title color linewidth with bin-width
                   (frames 100)
                   (channels 1)
                 &allow-other-keys)
  "Plot signal scope. "
  (declare (ignorable title color linewidth with bin-width))
  (let ((b (gensym "BUFFER"))
        (f frames))
    (ensure-attrs attrs
                  (:with      :lines)
                  (:bin-width 1)
                  (:frames    f)
                  (:title     (format nil "~A" body)))
    `(with-buffer (,b
                   :channels ,channels
                   :frames   ,f)
       (sc:proxy :plot
         (sc:buf-wr.ar ,body ,b (sc:line.ar 0
                                            (sc:buf-frames.kr ,b)
                                            (/ ,f (sc:sr ,b))
                                            :act :free)))
       (plot ,b ,@attrs))))

(defmacro freqscope (body &rest attrs
                     &key title color linewidth
                     &allow-other-keys)
  )

;;;; plot.lisp end here
