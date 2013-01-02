(import expect)
(import objc-x86_64)

;; Sizes of C types
(expect (= 1 (sizeof #\c)))
(expect (= 4 (sizeof #\i)))
(expect (= 2 (sizeof #\s)))
(expect (= 4 (sizeof #\l)))
(expect (= 8 (sizeof #\q)))
(expect (= 1 (sizeof #\C)))
(expect (= 4 (sizeof #\I)))
(expect (= 2 (sizeof #\S)))
(expect (= 4 (sizeof #\L)))
(expect (= 8 (sizeof #\Q)))
(expect (= 4 (sizeof #\f)))
(expect (= 8 (sizeof #\d)))
(expect (= 1 (sizeof #\B)))
(expect (= 8 (sizeof #\*)))
(expect (= 8 (sizeof #\@)))
(expect (= 8 (sizeof #\#)))
(expect (= 8 (sizeof #\:)))
(expect (= 8 (sizeof #\^)))
(expect (= 8 (sizeof #\?)))

;; Classifying C types
(expect (eq? 'INTEGER (classify #\c)))

(display-expect-results)
