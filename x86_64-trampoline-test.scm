(import expect)
(import x86_64-trampoline)

(let ((t (make-trampoline)))
  (trampoline-gp-set! t 0 78)
  (expect (= 78 (trampoline-gp-ref t 0))))

(let ((t (make-trampoline)))
  (trampoline-sse-set! t 2 2.0)
  (expect (= 2.0 (trampoline-sse-ref t 2))))

(let ((t (make-trampoline)))
  (trampoline-imp-set! t 978654321)
  (expect (= 978654321 (trampoline-imp-ref t))))

(c-declare #<<END_OF_CODE

static unsigned long the_passed_ulongs[6] = {};
static void six_integers(
    unsigned long i0, unsigned long i1, unsigned long i2,
    unsigned long i3, unsigned long i4, unsigned long i5
    )
{
  the_passed_ulongs[0] = i0;
  the_passed_ulongs[1] = i1;
  the_passed_ulongs[2] = i2;
  the_passed_ulongs[3] = i3;
  the_passed_ulongs[4] = i4;
  the_passed_ulongs[5] = i5;
}

static double the_passed_doubles[8] = {};
static void eight_doubles(
    double i0, double i1, double i2, double i3,
    double i4, double i5, double i6, double i7
    )
{
  the_passed_doubles[0] = i0;
  the_passed_doubles[1] = i1;
  the_passed_doubles[2] = i2;
  the_passed_doubles[3] = i3;
  the_passed_doubles[4] = i4;
  the_passed_doubles[5] = i5;
  the_passed_doubles[6] = i6;
  the_passed_doubles[7] = i7;
}

static unsigned long returns_a_ulong()
{
  return 0xDEADBEEFDEADBEEFUL;
}

struct sixteenbyte
{
  unsigned long a,b;
};

static struct sixteenbyte returns_a_sixteenbyte()
{
  struct sixteenbyte sb;
  sb.a = 0xDEADBEEFDEADBEEFUL;
  sb.b = 0xFDFDFDFDFDFDFDFDUL;
  return sb;
}

END_OF_CODE
)

(define *six_integers-address*
  ((c-lambda () unsigned-int64 "___result = (unsigned long)six_integers;")))
(define *eight_doubles-address*
  ((c-lambda () unsigned-int64 "___result = (unsigned long)eight_doubles;")))
(define *returns_a_ulong-address*
  ((c-lambda () unsigned-int64 "___result = (unsigned long)returns_a_ulong;")))
(define *returns_a_sixteenbyte-address*
  ((c-lambda () unsigned-int64 "___result = (unsigned long)returns_a_sixteenbyte;")))

(define gp-parameter-received
  (c-lambda (int)
	    unsigned-int64
    "___result = the_passed_ulongs[___arg1];"))

(define sse-parameter-received
  (c-lambda (int)
	    double
    "___result = the_passed_doubles[___arg1];"))

(define (correctly-passes-gp? n)
  (let ((t (make-trampoline)))
    (trampoline-imp-set! t *six_integers-address*)
    (trampoline-gp-set! t n 42)
    (trampoline-invoke t)
    (= 42 (gp-parameter-received n))))

(expect (correctly-passes-gp? 0))
(expect (correctly-passes-gp? 1))
(expect (correctly-passes-gp? 2))
(expect (correctly-passes-gp? 3))
(expect (correctly-passes-gp? 4))
(expect (correctly-passes-gp? 5))

(define (correctly-passes-sse? n)
  (let ((t (make-trampoline)))
    (trampoline-imp-set! t *eight_doubles-address*)
    (trampoline-sse-set! t n 12.8)
    (trampoline-invoke t)
    (= 12.8 (sse-parameter-received n))))

(expect (correctly-passes-sse? 0))
(expect (correctly-passes-sse? 1))
(expect (correctly-passes-sse? 2))
(expect (correctly-passes-sse? 3))
(expect (correctly-passes-sse? 4))
(expect (correctly-passes-sse? 5))
(expect (correctly-passes-sse? 6))
(expect (correctly-passes-sse? 7))

(let ((t (make-trampoline)))
  (trampoline-imp-set! t *returns_a_ulong-address*)
  (trampoline-invoke t)
  (expect (= #xDEADBEEFDEADBEEF (trampoline-gp-ref t 0))))

(let ((t (make-trampoline)))
  (trampoline-imp-set! t *returns_a_sixteenbyte-address*)
  (trampoline-invoke t)
  (expect (= #xDEADBEEFDEADBEEF (trampoline-gp-ref t 0)))
  (expect (= #xFDFDFDFDFDFDFDFD (trampoline-gp-ref t 1))))

(display-expect-results)