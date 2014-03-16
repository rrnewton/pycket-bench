;INSERTCODE
;------------------------------------------------------------------------------
(error-handler 
 (lambda l 
   (decode-error l)
   (display "bench DIED!") (newline) (exit 118)))

(define (run-bench name count ok? run)
  (let loop ((i 0) (result (list 'undefined)))
    (if (< i count)
      (loop (+ i 1) (run))
      result)))

(define (run-benchmark name count ok? run-maker . args)
  (newline)
  (let* ((run (apply run-maker args))
         (result (time (run-bench name count ok? run))))
    (if (not (ok? result))
      (begin
        (display "*** wrong result ***")
        (newline)
        (display "*** got: ")
        (write result)
        (newline))))
  (exit 0))

(define (fatal-error . args)
  (apply error #f args))

(define (call-with-output-file/truncate filename proc)
  (call-with-output-file filename proc))

; Bitwise operations on exact integers.
; From the draft reference implementation of R6RS generic arithmetic.

(define (bitwise-or i j)
  (if (and (fixnum? i) (fixnum? j))
      (fxlogior i j)
      (if (and (exact? i)
               (integer? i)
               (exact? j)
               (integer? j))
          (cond ((or (= i -1) (= j -1))
                 -1)
                ((= i 0)
                 j)
                ((= j 0)
                 i)
                (else
                 (let* ((i0 (if (odd? i) 1 0))
                        (j0 (if (odd? j) 1 0))
                        (i1 (- i i0))
                        (j1 (- j j0))
                        (i/2 (quotient i1 2))
                        (j/2 (quotient j1 2))
                        (hi (* 2 (bitwise-or i/2 j/2)))
                        (lo (if (= 0 (+ i0 j0)) 0 1)))
                   (+ hi lo))))
          (error "illegal argument to bitwise-or" i j))))

(define (bitwise-and i j)
  (if (and (fixnum? i) (fixnum? j))
      (fxlogand i j)
      (if (and (exact? i)
               (integer? i)
               (exact? j)
               (integer? j))
          (cond ((or (= i 0) (= j 0))
                 0)
                ((= i -1)
                 j)
                ((= j -1)
                 i)
                (else
                 (let* ((i0 (if (odd? i) 1 0))
                        (j0 (if (odd? j) 1 0))
                        (i1 (- i i0))
                        (j1 (- j j0))
                        (i/2 (quotient i1 2))
                        (j/2 (quotient j1 2))
                        (hi (* 2 (bitwise-and i/2 j/2)))
                        (lo (* i0 j0)))
                   (+ hi lo))))
          (error "illegal argument to bitwise-and" i j))))

(define (bitwise-not i)
  (if (fixnum? i)
      (fxlognot i)
      (if (and (exact? i)
               (integer? i))
          (cond ((= i -1)
                 0)
                ((= i 0)
                 -1)
                (else
                 (let* ((i0 (if (odd? i) 1 0))
                        (i1 (- i i0))
                        (i/2 (quotient i1 2))
                        (hi (* 2 (bitwise-not i/2)))
                        (lo (- 1 i0)))
                   (+ hi lo))))
          (error "illegal argument to bitwise-not" i j))))