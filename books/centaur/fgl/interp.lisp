; GL - A Symbolic Simulation Framework for ACL2
; Copyright (C) 2019 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; License: (An MIT/X11-style license)
;
;   Permission is hereby granted, free of charge, to any person obtaining a
;   copy of this software and associated documentation files (the "Software"),
;   to deal in the Software without restriction, including without limitation
;   the rights to use, copy, modify, merge, publish, distribute, sublicense,
;   and/or sell copies of the Software, and to permit persons to whom the
;   Software is furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in
;   all copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;   DEALINGS IN THE SOFTWARE.
;
; Original author: Sol Swords <sswords@centtech.com>

(in-package "FGL")

(include-book "interp-st")
(include-book "bvar-db-equivs")
(include-book "bfr-arithmetic")
(include-book "glcp-unify-defs")
(include-book "centaur/meta/bindinglist" :dir :system)
(include-book "syntax-bind")
(include-book "rewrite-tables")
(include-book "system/f-put-global" :dir :system)
(include-book "std/util/defret-mutual-generate" :dir :system)
(local (include-book "tools/trivial-ancestors-check" :dir :system))

(local (std::add-default-post-define-hook :fix))

(def-updater-independence-thm bfr-listp$-of-interp-st->logicman-extension
  (implies (and (logicman-extension-p (interp-st->logicman new)
                                      (interp-st->logicman old))
                (lbfr-listp x (interp-st->logicman old)))
           (lbfr-listp x (interp-st->logicman new))))

(def-updater-independence-thm logicman-pathcond-p-of-interp-st->logicman-extension
  (implies (and (logicman-extension-p (interp-st->logicman new)
                                      (interp-st->logicman old))
                (logicman-pathcond-p x (interp-st->logicman old)))
           (logicman-pathcond-p x (interp-st->logicman new))))

;; (def-updater-independence-thm logicman-extension-p-transitive-interp-st
;;   (implies (and (logicman-extension-p (interp-st->logicman new)
;;                                       (interp-st->logicman old))
;;                 (equal (interp-st->logicman )
;;            (logicman-extension-p (interp-st->logicman new) prev)))



(define interp-st-bfrs-ok (interp-st)
  (b* ((constraint-db (interp-st->constraint-db interp-st)))
    (stobj-let ((logicman (interp-st->logicman interp-st))
                (bvar-db (interp-st->bvar-db interp-st))
                (stack (interp-st->stack interp-st))
                (pathcond (interp-st->pathcond interp-st))
                (constraint-pathcond (interp-st->constraint interp-st)))
               (ok)
               (b* ((bfrstate (logicman->bfrstate)))
                 (and (bfr-listp (major-stack-bfrlist (stack-extract stack)))
                      (bfr-listp (constraint-db-bfrlist constraint-db))
                      (ec-call (logicman-pathcond-p-fn pathcond logicman))
                      (ec-call (logicman-pathcond-p-fn constraint-pathcond logicman))
                      (not (consp (bvar-db-bfrlist bvar-db)))
                      (logicman-check-nvars (next-bvar bvar-db) logicman)))
               ok))
  ///
  (defthm interp-st-bfrs-ok-implies
    (implies (interp-st-bfrs-ok interp-st)
             (let* ((logicman (interp-st->logicman interp-st))
                    (bfrstate (logicman->bfrstate)))
               (and (bfr-listp (major-stack-bfrlist (interp-st->stack interp-st)))
                    (bfr-listp (constraint-db-bfrlist (interp-st->constraint-db interp-st)))
                    (logicman-pathcond-p (interp-st->pathcond interp-st))
                    (logicman-pathcond-p (interp-st->constraint interp-st))
                    (not (bvar-db-bfrlist (interp-st->bvar-db interp-st)))
                    (interp-st-nvars-ok interp-st)
                    (logicman-check-nvars (next-bvar$a (interp-st->bvar-db interp-st))
                                          (interp-st->logicman interp-st)))))
    :hints(("Goal" :in-theory (enable interp-st-nvars-ok))))

  (acl2::def-updater-independence-thm interp-st-bfrs-ok-updater-independence
    (implies (and (equal (interp-st-get :logicman new)
                         (interp-st-get :logicman old))
                  (equal (interp-st-get :stack new)
                         (interp-st-get :stack old))
                  (equal (interp-st-get :constraint-db new)
                         (interp-st-get :constraint-db old))
                  (equal (interp-st-get :pathcond new)
                         (interp-st-get :pathcond old))
                  (equal (interp-st-get :constraint new)
                         (interp-st-get :constraint old))
                  (equal (interp-st-get :bvar-db new)
                         (interp-st-get :bvar-db old)))
             (equal (interp-st-bfrs-ok new)
                    (interp-st-bfrs-ok old))))


  (defthm interp-st-bfrs-ok-of-logicman-extension
    (implies (and (interp-st-bfrs-ok interp-st)
                  (logicman-extension-p new-logicman (interp-st->logicman interp-st))
                  (equal (bfr-nvars new-logicman) (bfr-nvars (interp-st->logicman interp-st))))
             (interp-st-bfrs-ok (update-interp-st->logicman new-logicman interp-st)))
    :hints(("Goal" :in-theory (enable logicman-check-nvars))))

  (defthm interp-st-bfrs-ok-of-update-stack
    (implies (And (interp-st-bfrs-ok interp-st)
                  (bfr-listp (major-stack-bfrlist new-stack) (logicman->bfrstate (interp-st->logicman interp-st))))
             (interp-st-bfrs-ok (update-interp-st->stack new-stack interp-st))))

  (defthm interp-st-bfrs-ok-of-update-constraint-db
    (implies (And (interp-st-bfrs-ok interp-st)
                  (bfr-listp (constraint-db-bfrlist new-constraint-db) (logicman->bfrstate (interp-st->logicman interp-st))))
             (interp-st-bfrs-ok (update-interp-st->constraint-db new-constraint-db interp-st))))

  (defthm interp-st-bfrs-ok-of-update-pathcond
    (implies (And (interp-st-bfrs-ok interp-st)
                  (logicman-pathcond-p-fn new-pathcond (interp-st->logicman interp-st)))
             (interp-st-bfrs-ok (update-interp-st->pathcond new-pathcond interp-st))))

  (defthm interp-st-bfrs-ok-of-update-constraint
    (implies (And (interp-st-bfrs-ok interp-st)
                  (logicman-pathcond-p-fn new-constraint (interp-st->logicman interp-st)))
             (interp-st-bfrs-ok (update-interp-st->constraint new-constraint interp-st))))

  (defthm interp-st-bfrs-ok-of-update-bvar-db
    (implies (And (interp-st-bfrs-ok interp-st)
                  (not (bvar-db-bfrlist new-bvar-db))
                  (logicman-check-nvars (next-bvar new-bvar-db) (interp-st->logicman interp-st)))
             (interp-st-bfrs-ok (update-interp-st->bvar-db new-bvar-db interp-st))))

  (defthm interp-st-bfrs-ok-of-interp-st-add-term-bvar
    (implies (and (interp-st-bfrs-ok interp-st)
                  (not (consp (gl-object-bfrlist x))))
             (interp-st-bfrs-ok (mv-nth 1 (interp-st-add-term-bvar x interp-st state))))
    ;; :hints (("goal" :use ((:instance logicman-extension-p-of-interp-st-add-term-bvar))
    ;;          :in-theory (disable logicman-extension-p-of-interp-st-add-term-bvar)))
    )

  (defthm interp-st-bfrs-ok-of-interp-st-add-term-bvar-unique
    (implies (and (interp-st-bfrs-ok interp-st)
                  (not (consp (gl-object-bfrlist x))))
             (interp-st-bfrs-ok (mv-nth 1 (interp-st-add-term-bvar-unique x interp-st state))))
    ;; :hints (("goal" :use ((:instance logicman-extension-p-of-interp-st-add-term-bvar-unique))
    ;;          :in-theory (disable logicman-extension-p-of-interp-st-add-term-bvar-unique)))
    )

)




;; (define glcp-unify-alist-bfrlist ((x glcp-unify-alist-p))
;;   :measure (len (glcp-unify-alist-fix x))
;;   (b* ((x (glcp-unify-alist-fix x))
;;        ((when (atom x)) nil)
;;        ((cons key val) (car x)))
;;     (append (gl-object-bfrlist val)
;;             (glcp-unify-alist-bfrlist (cdr x))))
;;   ///
;;   (defthm member-bfrlist-of-glcp-unify-alist-lookup
;;     (implies (and (not (member bfr (glcp-unify-alist-bfrlist x)))
;;                   (acl2::pseudo-var-p v))
;;              (not (member bfr (cdr (hons-assoc-equal v x))))))
  
;;   (defthm member-glcp-unify-alist-bfrlist-of-cons
;;     (implies (and (not (member bfr (glcp-unify-alist-bfrlist x)))
;;                   (not (member bfr (gl-object-bfrlist val))))
;;              (not (member bfr (glcp-unify-alist-bfrlist (cons (cons key val) x)))))))

;; Trace this!
(define glcp-interp-error-message ((str stringp)
                                   (arglist))
  :returns (error-message (or (consp error-message)
                              (stringp error-message))
                          :rule-classes :type-prescription)
  (if arglist
      (cons (str-fix str) arglist)
    (str-fix str)))

(defmacro gl-msg (str &rest args)
  `(glcp-interp-error-message ,str ,(make-fmt-bindings acl2::*base-10-chars* args)))


(define gl-interp-store-debug-info (msg obj interp-st state)
  :returns (mv new-interp-st new-state)
  (b* (((when (interp-st->errmsg interp-st))
        (mv interp-st state))
       (interp-st (update-interp-st->errmsg msg interp-st))
       (stack-obj (stobj-let ((stack (interp-st->stack interp-st)))
                             (obj)
                             (stack-extract stack)
                             obj))
       (state (f-put-global 'gl-interp-error-message msg state))
       (state (f-put-global 'gl-interp-error-debug-obj obj state))
       (state (f-put-global 'gl-interp-error-stack stack-obj state)))
    (mv interp-st state))
  ///
  (defret w-of-<fn>
    (equal (w new-state) (w state)))

  (defret interp-st-get-of-<fn>
    (implies (not (equal (interp-st-field-fix key) :errmsg))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st))))

  (defret <fn>-preserves-error
    (implies (interp-st->errmsg interp-st)
             (equal (interp-st->errmsg new-interp-st)
                    (interp-st->errmsg interp-st)))))

(defmacro gl-interp-error (&key msg debug-obj (nvals '1))
  `(b* ((msg ,msg)
        (debug-obj ,debug-obj)
        ((mv interp-st state) (gl-interp-store-debug-info msg debug-obj interp-st state)))
     (mv ,@(acl2::repeat nvals nil) interp-st state)))
  



(define interp-st-set-error (msg interp-st)
  :returns new-interp-st
  (if (interp-st->errmsg interp-st)
      interp-st
    (update-interp-st->errmsg msg interp-st))
  ///
  (defret interp-st-get-of-<fn>
    (implies (not (equal (interp-st-field-fix key) :errmsg))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st))))

  (defret <fn>-preserves-error
    (implies (interp-st->errmsg interp-st)
             (equal (interp-st->errmsg new-interp-st)
                    (interp-st->errmsg interp-st)))))

(define interp-st-cancel-error ((msg symbolp) interp-st)
  :returns new-interp-st
  :hooks nil
  (if (eq (interp-st->errmsg interp-st) msg)
      (update-interp-st->errmsg nil interp-st)
    interp-st)
  ///
  (defret interp-st-get-of-<fn>
    (implies (not (equal (interp-st-field-fix key) :errmsg))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st))))

  (defret <fn>-preserves-error
    (implies (not (equal (interp-st->errmsg interp-st) msg))
             (equal (interp-st->errmsg new-interp-st)
                    (interp-st->errmsg interp-st)))))

;; (define glcp-interp-error (msg &key (interp-st 'interp-st)
;;                                (state 'state))
;;   :returns (mv errmsg
;;                result
;;                new-interp-st
;;                new-state)
;;   (mv msg nil interp-st state))

;; (defmacro glcp-value (obj)
;;   `(mv nil ,obj interp-st state))


;; should we look for equivalence assumptions for this object?
(define glcp-term-obj-p ((x gl-object-p))
  (declare (xargs :guard t))
  (gl-object-case x
    :g-ite t
    :g-var t
    :g-apply t
    :otherwise nil))


(fty::defbitstruct gl-function-mode
  ((dont-concrete-exec booleanp)
   (dont-expand-def booleanp)
   (dont-rewrite booleanp)
   (dont-rewrite-under-if-test booleanp)
   (dont-primitive-exec booleanp)))

(define gl-function-mode-fix! (x)
  :guard-hints(("Goal" :in-theory (enable gl-function-mode-fix)))
  :enabled t
  (mbe :logic (gl-function-mode-fix x)
       :exec (loghead 5 (ifix x))))

(define g-concretelist-p ((x gl-objectlist-p))
  (if (atom x)
      t
    (and (gl-object-case (car x) :g-concrete)
         (g-concretelist-p (Cdr x)))))

(define g-concretelist-vals ((x gl-objectlist-p))
  :guard (g-concretelist-p x)
  :guard-hints (("goal" :in-theory (enable g-concretelist-p)))
  (if (atom x)
      nil
    (cons (g-concrete->val (car x))
          (g-concretelist-vals (cdr x)))))

(define fncall-try-concrete-eval ((fn pseudo-fn-p)
                                  (args gl-objectlist-p)
                                  (dont-concrete-exec)
                                  state)
  :returns (mv ok (ans gl-object-p))
  (b* (((gl-function-mode mode))
       ((when (or dont-concrete-exec
                  (not (g-concretelist-p args))))
        (mv nil nil))
       ((mv err ans)
        (magic-ev-fncall (pseudo-fn-fix fn) (g-concretelist-vals args) state t nil)))
    (mv (not err) (g-concrete ans)))
  ///
  (defret gl-object-bfrlist-of-<fn>
    (equal (gl-object-bfrlist ans) nil)))


(define interp-st-restore-reclimit ((reclimit natp)
                                    interp-st)
  :guard (acl2::nat-equiv reclimit (interp-st->reclimit interp-st))
  :inline t
  :enabled t
  (mbe :logic (update-interp-st->reclimit (lnfix reclimit) interp-st)
       :exec interp-st))

(def-b*-binder gl-interp-recursive-call
  :body
  `(b* ((interp-recursive-call-reclimit (lnfix (interp-st->reclimit interp-st)))
        ((mv . ,args) . ,forms)
        (interp-st (interp-st-restore-reclimit interp-recursive-call-reclimit interp-st)))
     ,rest-expr))


(define gl-interp-time$-arg ((arg gl-object-p) (x pseudo-termp))
  (b* ((arg (gl-object-case arg :g-concrete (and (true-listp arg.val) arg.val) :otherwise nil))
       (term-descrip (pseudo-term-case x :fncall x.fn :otherwise (pseudo-term-fix x))))
    (if arg
        (b* ((msg (nth 3 arg)))
          (if msg
              arg
            (append (take 3 arg)
                    (list "Gl-interp ~x0: ~st real, ~sc cpu, ~sa bytes~%"
                          (list term-descrip)))))
      (list 0 nil nil "Gl-interp ~x0: ~st real, ~sc cpu, ~sa bytes~%"
            (list term-descrip)))))

(local (defthm assoc-when-key
         (implies k
                  (equal (assoc k a)
                         (hons-assoc-equal k a)))))

(define match-syntax-bind-synp ((synp pseudo-termp))
  :returns (mv ok (form pseudo-termp) untrans)
  (b* (((mv ok alist) (cmr::pseudo-term-unify '(synp nil untrans-form trans-form)
                                              synp nil))
       ((unless ok) (mv nil nil nil))
       (untrans-form (cdr (assoc 'untrans-form alist)))
       (trans-form   (cdr (assoc 'trans-form alist)))
       ((unless (and (pseudo-term-case untrans-form :quote)
                     (pseudo-term-case trans-form :quote)))
        (mv nil nil nil))
       (val (acl2::pseudo-term-quote->val trans-form)))
    (if (pseudo-termp val)
        (mv t val untrans-form)
      (mv nil nil nil))))




(define gl-interp-match-synp ((x pseudo-termp))
  :returns (mv (synp-type symbolp) ;; nil if bad
               (untrans-form)
               (trans-term pseudo-termp)
               (vars))
  (b* (((unless (pseudo-term-case x :fncall))
        (mv nil nil nil nil))
       ((pseudo-term-fncall x))
       ((unless (and (eq x.fn 'synp)
                     (eql (len x.args) 3)))
        (mv nil nil nil nil))
       ((list vars untrans-form trans-form) x.args)
       ((unless (and (pseudo-term-case vars :quote)
                     (pseudo-term-case untrans-form :quote)
                     (pseudo-term-case trans-form :quote)))
        (mv nil nil nil nil))
       (vars (acl2::pseudo-term-quote->val vars))
       (trans-form (acl2::pseudo-term-quote->val trans-form))
       (untrans-form (acl2::pseudo-term-quote->val untrans-form))
       ((unless (and (consp untrans-form)
                     (symbolp (car untrans-form))
                     (pseudo-termp trans-form)))
        (mv nil nil nil nil)))
    (mv (car untrans-form)
        untrans-form
        trans-form
        vars))
  ///
  (defret gl-interp-match-synp-implies-eval
    (implies synp-type
             (equal (base-apply-ev x a) t))))



(define gl-interp-syntax-bind ((synp-arg pseudo-termp)
                               (x pseudo-termp)
                               interp-st
                               state)
  :returns (mv (ans gl-object-p)
               new-interp-st
               new-state)
  :prepwork ((local (defthm symbol-alistp-when-gl-object-alist-p
                      (implies (gl-object-alist-p x)
                               (symbol-alistp x))
                      :hints(("Goal" :in-theory (enable gl-object-alist-p))))))
  (b* (((mv synp-ok synp-term untrans) (match-syntax-bind-synp synp-arg))
       ((unless (and synp-ok (pseudo-term-case x :var)))
        ;; We could go ahead and simulate x anyway but this does seem like an error.
        (gl-interp-error :msg (gl-msg "Bad syntax-bind form: args ~x0, ~x1."
                                      (pseudo-term-fix synp-arg)
                                      (pseudo-term-fix x))))
       (varname (acl2::pseudo-term-var->name x))
       (bindings (append (interp-st-minor-bindings interp-st)
                         (interp-st-bindings interp-st)))
       ;; Consider allowing already-bound variables to be bound in the new
       ;; bindings, and just omitting them from the final bindings.  Might be
       ;; convenient in case we want to bind a variable in different places for
       ;; different cases.  
       ((when (assoc-eq varname bindings))
        (gl-interp-error
         :msg (gl-msg "Syntax-bind error: ~x0 was supposed to be bound in a ~
                       syntax-bind form but was already bound" varname)))
       ((mv ok val) (acl2::magic-ev synp-term bindings state t t))
       ((unless ok)
        (gl-interp-error
         :msg (gl-msg "Syntax-bind error: ~x0 failed to evaluate -- translated: ~x1" untrans synp-term)))
       ((unless (gl-bfr-object-p val (interp-st-bfr-state)))
        (gl-interp-error
         :msg (gl-msg "Syntax-bind error: ~x0 evaluted to an illformed symbolic object, saved in ~x1."
                      untrans '(@ gl-interp-error-debug-obj))
         :debug-obj val))
       ;; BOZO We might actually want to bind this to a non-concrete value
       (interp-st (interp-st-add-binding varname val interp-st)))
    (mv val interp-st state))
  ///
  (local (defthm bfrlist-of-interp-st-add-binding
           (implies (and (not (member v (major-stack-bfrlist stack)))
                         (not (member v (gl-object-bfrlist val))))
                    (not (member v (major-stack-bfrlist (stack$a-add-binding var val stack)))))
           :hints (("goal" :expand ((major-stack-bfrlist stack))
                    :in-theory (enable stack$a-add-binding major-frame-bfrlist
                                       major-stack-bfrlist)))))

  (local (in-theory (disable stack$a-add-binding)))
  (local (in-theory (enable bfr-listp-when-not-member-witness)))

  (local (Defthm gl-bfr-object-p-is-gl-object-p-and-bfr-listp
           (equal (gl-bfr-object-p x)
                  (and (gl-object-p x)
                       (bfr-listp (gl-object-bfrlist x))))))
  
  (defret interp-st-bfrs-ok-of-<fn>
    (implies (interp-st-bfrs-ok interp-st)
             (and (interp-st-bfrs-ok new-interp-st)
                  (lbfr-listp (gl-object-bfrlist ans)
                              (interp-st->logicman interp-st)))))

  (defret interp-st-get-of-<fn>
    (implies (And (not (equal (interp-st-field-fix key) :stack))
                  (not (equal (interp-st-field-fix key) :errmsg)))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st))))

  (defret multivalues-of-<fn>
    (equal (list . <values>) <call>))

  (defret <fn>-preserves-errmsg
    (implies (interp-st->errmsg interp-st)
             (equal (interp-st->errmsg new-interp-st)
                    (interp-st->errmsg interp-st)))))


(define gl-interp-or-test-equiv-contexts ((contexts equiv-contextsp))
  :returns (new-contexts equiv-contextsp)
  (and (equal (equiv-contexts-fix contexts) '(iff)) '(iff)))

;; (define interp-st-checkpoint-p (chp interp-st)
;;   :enabled t
;;   (stobj-let ((pathcond (interp-st->pathcond interp-st))
;;               (logicman (interp-st->logicman interp-st)))
;;              (ok)
;;              (pathcond-checkpoint-p chp (logicman->mode logicman) pathcond)
;;              ok))

(define interp-st-pathcond-assume ((test interp-st-bfr-p)
                                   interp-st)

  :returns (mv contra
               (new-interp-st))
  (stobj-let ((logicman (interp-st->logicman interp-st))
              (pathcond (interp-st->pathcond interp-st))
              (constraint-pathcond (interp-st->constraint interp-st)))
             (contra pathcond constraint-pathcond)
             ;; this is a bit weak... would be better to check against
             ;; both constraint and pathcond at once somehow
             (b* (((mv constraint-implies constraint-pathcond)
                   (logicman-pathcond-implies test constraint-pathcond))
                  ((when (eql constraint-implies 0))
                   (mv t pathcond constraint-pathcond))
                  ((mv contra pathcond) (logicman-pathcond-assume test pathcond)))
               (mv contra pathcond constraint-pathcond))
             (mv contra interp-st))
  ///
  (defret interp-st-get-of-interp-st-pathcond-assume
    (implies (and (not (equal (interp-st-field-fix key) :pathcond))
                  (not (equal (interp-st-field-fix key) :constraint)))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st))))

  (defret interp-st->constraint-of-interp-st-pathcond-assume
    (equal (interp-st->constraint new-interp-st)
           (pathcond-fix (interp-st->constraint interp-st))))

  (defret interp-st-bfrs-ok-of-<fn>
    (implies (and (interp-st-bfr-p test)
                  (interp-st-bfrs-ok interp-st))
             (interp-st-bfrs-ok new-interp-st)))

  (defret pathcond-rewind-of-<fn>
    (implies (and (not contra)
                  (equal mode (logicman->mode (interp-st->logicman interp-st))))
             (equal (pathcond-rewind mode (interp-st->pathcond new-interp-st))
                    (pathcond-fix (interp-st->pathcond interp-st)))))

  (defret pathcond-enabledp-of-<fn>
    (iff* (nth *pathcond-enabledp* (interp-st->pathcond new-interp-st))
          (nth *pathcond-enabledp* (interp-st->pathcond interp-st))))

  (defret <fn>-pathcond-when-contra
    (implies contra
             (pathcond-equiv (interp-st->pathcond new-interp-st)
                             (interp-st->pathcond interp-st)))))
             


(define interp-st-pathcond-rewind (interp-st)
  :guard (stobj-let ((pathcond (interp-st->pathcond interp-st))
                     (logicman (interp-st->logicman interp-st)))
                    (ok)
                    (pathcond-rewind-ok (lbfr-mode) pathcond)
                    ok)
  :returns new-interp-st
  :enabled t
  (stobj-let ((logicman (interp-st->logicman interp-st))
              (pathcond (interp-st->pathcond interp-st)))
             (pathcond)
             (pathcond-rewind (logicman->mode logicman) pathcond)
             interp-st))

(define gl-apply-match-not ((x gl-object-p))
  :guard (gl-object-case x :g-apply)
  :returns (mv ok
               (negated-arg gl-object-p))
  (b* (((unless (mbt (gl-object-case x :g-apply))) (mv nil nil))
       ((g-apply x))
       (fn x.fn)
       (args x.args)
       ((when (eq fn 'not))
        (cond ((eql (len args) 1)
               (mv t (gl-object-fix (car args))))
              (t (mv nil nil))))
       ((when (eq fn 'equal))
        (b* (((unless (eql (len args) 2))
              (mv nil nil))
             ((list arg1 arg2) args)
             ((when (gl-object-case arg1
                      :g-concrete (eq arg1.val nil)
                      :otherwise nil))
              (mv t (gl-object-fix arg2)))
             ((when (gl-object-case arg2
                      :g-concrete (eq arg2.val nil)
                      :otherwise nil))
              (mv t (gl-object-fix arg1))))
          (mv nil nil))))
    (mv nil nil))
  ///
  

  (defret gl-apply-match-not-correct
    (implies ok
             (iff (fgl-object-eval negated-arg env logicman)
                  (not (fgl-object-eval x env logicman))))
    :hints(("Goal" :expand ((fgl-objectlist-eval (g-apply->args x) env)
                            (fgl-objectlist-eval (cdr (g-apply->args x)) env)
                            (fgl-objectlist-eval (cddr (g-apply->args x)) env))
            :in-theory (enable base-apply))))

  (defret gl-object-count-of-g-apply-match-not
    (implies ok
             (< (gl-object-count negated-arg) (gl-object-count x)))
    :hints(("Goal" :expand ((gl-object-count x)
                            (gl-objectlist-count (g-apply->args x))
                            (gl-objectlist-count (cdr (g-apply->args x)))
                            (gl-objectlist-count (cddr (g-apply->args x))))))
    :rule-classes :linear)

  (defret bfrlist-of-gl-apply-match-not
    (implies (not (member v (gl-object-bfrlist x)))
             (not (member v (gl-object-bfrlist negated-arg))))))
  


(define gl-rewrite-relieve-hyp-synp ((synp-type symbolp)
                                     (form pseudo-termp)
                                     (vars)
                                     (untrans-form)
                                     interp-st
                                     state)
  :returns (mv successp
               new-interp-st
               new-state)
  :prepwork ((local (defthm alist-keys-of-gl-object-alist
                      (implies (gl-object-alist-p x)
                               (and (pseudo-var-list-p (alist-keys x))
                                    (symbol-listp (alist-keys x))))
                      :hints(("Goal" :in-theory (enable alist-keys)))))
             (local (defthm symbol-alistp-when-gl-object-alist-p
                      (implies (gl-object-alist-p x)
                               (symbol-alistp x))))
             
             (local (Defthm gl-bfr-object-alist-p-is-gl-object-alist-p-and-bfr-listp
                      (equal (gl-bfr-object-alist-p x)
                             (and (gl-object-alist-p x)
                                  (bfr-listp (gl-object-alist-bfrlist x))))
                      :hints(("Goal" :in-theory (enable gl-bfr-object-alist-p-implies-gl-object-alist-p))))))
  :hooks ((:fix :omit (synp-type)))
  (b* ((bindings (append (interp-st-minor-bindings interp-st)
                         (interp-st-bindings interp-st)))
       (form (pseudo-term-fix form))
       ((mv ok val) (acl2::magic-ev form bindings state t t))
       ((unless ok)
        (gl-interp-error
         :msg (gl-msg "Synp error: ~x0 failed to evaluate -- translated: ~x1" untrans-form form)))
       ((when (eq synp-type 'syntaxp))
        (mv val interp-st state))
       ;; bind-free...
       ((unless val)
        ;; No error -- bind-free evaluated to NIL which means just don't do the rewrite.
        (mv nil interp-st state))
       ((unless (gl-bfr-object-alist-p val (interp-st-bfr-state)))
        (gl-interp-error
         :msg (gl-msg "Bind-free error: ~x0 evaluated to a non-GL object alist: ~x1" untrans-form val)))
       (newly-bound-vars (alist-keys bindings))
       ((when (and (symbol-listp vars)
                   (not (subsetp-eq vars newly-bound-vars))))
        (gl-interp-error
         :msg (gl-msg "Bind-free error: ~x0 evaluated to an alist not ~
                     containing the required vars ~x1: ~x2" untrans-form val vars)))
       ;; Consider allowing already-bound variables to be bound in the new
       ;; bindings, and just omitting them from the final bindings.  Might be
       ;; convenient in case we want to bind a variable in different places for
       ;; different cases.  
       ((when (intersectp-eq (alist-keys val) newly-bound-vars))
        (gl-interp-error
         :msg (gl-msg "Bind-free error: ~x0 evaluated to a non-GL object alist: ~x1" untrans-form val)))
       
       (interp-st (interp-st-set-bindings (append val (interp-st-bindings interp-st)) interp-st)))
    (mv t interp-st state))
  ///
  (local
   (defthm major-stack-bfrlist-of-stack$a-set-bindings
     (implies (and (not (member v (major-stack-bfrlist stack)))
                   (not (member v (gl-object-alist-bfrlist bindings))))
              (not (member v (major-stack-bfrlist (stack$a-set-bindings bindings stack)))))
     :hints(("Goal" :in-theory (enable stack$a-set-bindings
                                       major-stack-bfrlist
                                       major-frame-bfrlist
                                       minor-frame-bfrlist
                                       minor-stack-bfrlist)
             :do-not-induct t))))

  (local
   (defthm gl-object-alist-bfrlist-of-stack$a-bindings-bindings
     (implies (not (member v (major-stack-bfrlist stack)))
              (not (member v (gl-object-alist-bfrlist (stack$a-bindings stack)))))
     :hints(("Goal" :in-theory (enable stack$a-bindings
                                       major-stack-bfrlist
                                       major-frame-bfrlist)
             :do-not-induct t))))

  (local (in-theory (disable stack$a-set-bindings
                             stack$a-bindings
                             stack$a-minor-bindings)))

  (local (in-theory (enable bfr-listp-when-not-member-witness)))
  (defret interp-st-bfrs-ok-of-<fn>
    (implies (interp-st-bfrs-ok interp-st)
             (interp-st-bfrs-ok new-interp-st)))
  
  (defret interp-st-get-of-<fn>
    (implies (and (not (equal (interp-st-field-fix key) :stack))
                  (not (equal (interp-st-field-fix key) :errmsg)))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st))))

  (defret multivalues-of-<fn>
    (equal (list . <values>)
           <call>))

  (defret <fn>-preserves-errmsg
    (implies (interp-st->errmsg interp-st)
             (equal (interp-st->errmsg new-interp-st)
                    (interp-st->errmsg interp-st)))))



;; Used in merge-branches to recognize a branch on which we can unify some
;; function.  BOZO We might want to try more than one function for some objects
;; -- e.g. for :g-integer we could do both int and intcons, for concrete values
;; that are conses we could do both concrete and bool, etc.  Ideally we'd try
;; all the functions that the argument could unify with.
(define gl-fncall-object->fn ((x gl-object-p))
  :returns (fn pseudo-fnsym-p) ;; nil if didn't match
  (gl-object-case x
    :g-boolean 'bool
    :g-integer 'int
    :g-concrete 'concrete
    :g-apply x.fn
    :g-cons 'cons
    :otherwise nil))


(defthm base-apply-ev-lst-of-kwote-lst
  (equal (base-apply-ev-lst (kwote-lst x) a)
         (true-list-fix x)))

(defthm not-quote-when-pseudo-fnsym-p
  (implies (pseudo-fnsym-p x)
           (not (equal x 'quote))))

(define gl-object-recognize-merge-fncall ((x gl-object-p))
  ;; Note: This is used when we want to merge two calls of the same function,
  ;; e.g.  (if test (foo x y) (foo w z)).  We don't want to match a g-boolean
  ;; to (bool x), for example, because that would lead to an infinite loop where we
  ;; match (if test (g-boolean b) (g-boolean c)) as
  ;; (if test (bool (g-boolean b)) (bool (g-boolean c)))
  ;; then merge the args, i.e. (list (g-boolean b)) (list (g-boolean c))
  ;; in which when we merge the first arg we get back to
  ;; (if test (g-boolean b) (g-boolean c)) and get stuck in an infinite loop.
  :returns (mv (fn pseudo-fnsym-p :rule-classes (:rewrite (:type-prescription :typed-term fn)))
               (args gl-objectlist-p))
  (gl-object-case x
    ;; :g-boolean (mv 'bool (list (gl-object-fix x)))
    ;; :g-integer (mv 'int (list (gl-object-fix x)))
    ;; :g-concrete (mv 'concrete (list (gl-object-fix x)))
    :g-apply (mv x.fn x.args)
    :g-cons (mv 'cons (list x.car x.cdr))
    :otherwise (mv nil nil))
  ///

  (defret eval-when-gl-object-recognize-merge-fncall
    (implies fn
             (equal (base-apply-ev (cons fn
                                         (kwote-lst (fgl-objectlist-eval args env)))
                                   a)
                    (fgl-object-eval x env)))
    :hints(("Goal" :in-theory (enable base-apply fgl-objectlist-eval
                                      base-apply-ev-of-fncall-args))))

  (defret gl-objectlist-count-of-recognize-merge-fncall
    (implies fn
             (<= (gl-objectlist-count args) (gl-object-count x)))
    :hints(("Goal" :in-theory (enable gl-objectlist-count))
           (and stable-under-simplificationp
                '(:expand ((gl-object-count x)))))
    :rule-classes :linear)

  ;; (defret gl-bfr-objectlist-p-of-<fn>
  ;;   (implies (gl-bfr-object-p x)
  ;;            (gl-bfr-objectlist-p args)))

  (defret bfr-listp-gl-objectlist-bfrlist-of-<fn>
    (implies (bfr-listp (gl-object-bfrlist x))
             (bfr-listp (gl-objectlist-bfrlist args)))
    :hints (("goal" :Expand ((gl-object-bfrlist x))))))

;; (define gl-object-recognize-fncall ((x gl-object-p))
;;   :prepwork ((local (in-theory (enable gl-fncall-object->fn))))
;;   :returns (mv (fn (equal fn (gl-fncall-object->fn x)))
;;                (args gl-objectlist-p))
;;   (gl-object-case x
;;     :g-boolean (mv 'bool (list (gl-object-fix x)))
;;     :g-integer (mv 'int (list (gl-object-fix x)))
;;     :g-concrete (mv 'concrete (list (gl-object-fix x)))
;;     :g-apply (mv x.fn x.args)
;;     :g-cons (mv 'cons (list x.car x.cdr))
;;     :otherwise (mv nil nil))
;;   ///
;;   (defret eval-when-gl-object-recognize-fncall
;;     (implies (gl-fncall-object->fn x)
;;              (equal (fgl-object-eval x env)
;;                     (base-apply (gl-fncall-object->fn x)
;;                                 (fgl-objectlist-eval args env))))
;;     :hints(("Goal" :in-theory (enable base-apply fgl-objectlist-eval)))))

;; (defthm-fgl-object-eval-flag
;;   (defthm fgl-object-eval-of-gl-bfr-object-fix
;;     (equal (fgl-object-eval (gl-bfr-object-fix x (logicman->bfrstate logicman))
;;                                 env logicman)
;;            (fgl-object-eval x env logicman))
;;     :hints ('(:expand ((fgl-object-eval x env logicman)
;;                        (gl-bfr-object-fix x (logicman->bfrstate logicman)))))
;;     :flag fgl-object-eval)
;;   (defthm fgl-objectlist-eval-of-gl-bfr-object-fix
;;     (equal (fgl-objectlist-eval (gl-bfr-objectlist-fix x (logicman->bfrstate logicman))
;;                                 env logicman)
;;            (fgl-objectlist-eval x env logicman))
;;     :hints ('(:expand ((fgl-objectlist-eval x env logicman)
;;                        (gl-bfr-objectlist-fix x (logicman->bfrstate logicman)))))
;;     :flag fgl-objectlist-eval))

;; BOZO move



(define gl-object-basic-merge ((test lbfr-p)
                               (then gl-object-p)
                               (else gl-object-p)
                               &optional
                               (logicman 'logicman))
  :returns (mv (obj gl-object-p)
               new-logicman)
  :guard-hints (("goal" :in-theory (enable bfr-ite-bss-fn)))
  :guard (and (gl-bfr-object-p then (logicman->bfrstate))
              (gl-bfr-object-p else (logicman->bfrstate)))
  (b* ((bfrstate (logicman->bfrstate)))
    (gl-object-case then
      :g-boolean (gl-object-case else
                   :g-boolean (b* (((mv bfr logicman) (bfr-ite (bfr-fix test)
                                                               (bfr-fix then.bool)
                                                               (bfr-fix else.bool))))
                                (mv (g-boolean bfr) logicman))
                   :otherwise (mv (gl-bfr-object-fix (g-ite (g-boolean test) then else)) logicman))
      :g-integer (gl-object-case else
                   :g-integer (b* (((mv bits logicman) (bfr-ite-bss (bfr-fix test)
                                                                    (bfr-list-fix then.bits)
                                                                    (bfr-list-fix else.bits)
                                                                    logicman)))
                                (mv (g-integer bits) logicman))
                   :otherwise (mv (gl-bfr-object-fix (g-ite (g-boolean test) then else)) logicman))
      :otherwise (mv (gl-bfr-object-fix (g-ite (g-boolean test) then else)) logicman)))
  ///
  ;; (defret gl-bfr-object-p-of-<fn>
  ;;   (gl-bfr-object-p obj (logicman->bfrstate new-logicman)))

  (defret eval-of-gl-object-basic-merge
    (equal (fgl-object-eval obj env new-logicman)
           (if (gobj-bfr-eval test env)
               (fgl-object-eval then env logicman)
             (fgl-object-eval else env logicman)))
    :hints(("Goal" 
            :in-theory (enable gobj-bfr-eval gobj-bfr-list-eval-is-bfr-list-eval))))

  (defret logicman-extension-p-of-<fn>
    (logicman-extension-p new-logicman logicman))
  
  (defret bfr-nvars-of-<fn>
    (equal (bfr-nvars new-logicman)
           (bfr-nvars logicman)))
  
  (local (defthm gl-bfr-objectlist-of-gl-bfr-object-fix
           (bfr-listp (gl-object-bfrlist (gl-bfr-object-fix x bfrstate)) bfrstate)
           :hints (("goal" :use ((:instance gl-bfr-object-p-when-gl-object-p
                                  (x (gl-bfr-object-fix x bfrstate))))))))

  (defret bfr-listp-of-gl-object-basic-merge
    ;; (implies (and (lbfr-p test)
    ;;               (lbfr-listp (gl-object-bfrlist thenval))
    ;;               (lbfr-listp (gl-object-bfrlist elseval)))
             (bfr-listp (gl-object-bfrlist obj) (logicman->bfrstate new-logicman))))


(define gl-int-primitive ((args gl-objectlist-p) interp-st state)
  :returns (mv successp
               (ans gl-object-p)
               interp-st
               state)
  (if (eql (len args) 1)
      (let ((x (car args)))
        (gl-object-case x
          :g-integer (mv t (gl-object-fix x) interp-st state)
          :otherwise (mv nil nil interp-st state)))
    (mv nil nil interp-st state)))

(define gl-endint-primitive ((args gl-objectlist-p) interp-st state)
  :returns (mv successp
               (ans gl-object-p)
               interp-st
               state)
  (if (eql (len args) 1)
      (let ((x (car args)))
        (gl-object-case x
          :g-boolean (mv t (g-integer (list x.bool)) interp-st state)
          :otherwise (mv nil nil interp-st state)))
    (mv nil nil interp-st state)))

(define gl-intcons-primitive ((args gl-objectlist-p) interp-st state)
  :returns (mv successp
               (ans gl-object-p)
               interp-st
               state)
  (if (eql (len args) 2)
      (b* (((list car cdr) args))
        (gl-object-case car
          :g-boolean (gl-object-case cdr
                       :g-integer (mv t (g-integer (cons car.bool cdr.bits)) interp-st state)
                       :otherwise (mv nil nil interp-st state))
          :otherwise (mv nil nil interp-st state)))
    (mv nil nil interp-st state)))

(define gl-intcar-primitive ((args gl-objectlist-p) interp-st state)
  :returns (mv successp
               (ans gl-object-p)
               interp-st
               state)
  (if (eql (len args) 1)
      (let ((x (car args)))
        (gl-object-case x
          :g-integer (mv t (g-boolean (car x.bits)) interp-st state)
          :otherwise (mv nil nil interp-st state)))
    (mv nil nil interp-st state)))

(define gl-intcdr-primitive ((args gl-objectlist-p) interp-st state)
  :returns (mv successp
               (ans gl-object-p)
               interp-st
               state)
  (if (eql (len args) 1)
      (let ((x (car args)))
        (gl-object-case x
          :g-integer (mv t (g-integer (cdr x.bits)) interp-st state)
          :otherwise (mv nil nil interp-st state)))
    (mv nil nil interp-st state)))

(define gl-bool-primitive ((args gl-objectlist-p) interp-st state)
  :returns (mv successp
               (ans gl-object-p)
               interp-st
               state)
  (if (eql (len args) 1)
      (let ((x (car args)))
        (gl-object-case x
          :g-boolean (mv t (gl-object-fix x) interp-st state)
          :otherwise (mv nil nil interp-st state)))
    (mv nil nil interp-st state)))

(define gl-primitive-fncall ((fn pseudo-fnsym-p)
                             (args gl-objectlist-p)
                             (dont)
                             interp-st
                             state)
  :returns (mv successp
               (ans gl-object-p)
               new-interp-st
               state)
  (if dont
      (mv nil nil interp-st state)
    (case (pseudo-fnsym-fix fn)
      (int (gl-int-primitive args interp-st state))
      ((intcons intcons*) (gl-intcons-primitive args interp-st state))
      (endint (gl-endint-primitive args interp-st state))
      (intcar (gl-intcar-primitive args interp-st state))
      (intcdr (gl-intcdr-primitive args interp-st state))
      (bool (gl-bool-primitive args interp-st state))
      (otherwise (mv nil nil interp-st state))))
  ///
  (defret interp-st-bfrs-ok-of-<fn>
    (implies (and (interp-st-bfrs-ok interp-st)
                  ;; (lbfr-listp (gl-objectlist-bfrlist args)
                  ;;             (interp-st->logicman interp-st))
                  )
             (interp-st-bfrs-ok new-interp-st))
    :hints(("Goal" :in-theory (enable gl-int-primitive
                                      gl-intcons-primitive
                                      gl-endint-primitive
                                      gl-intcar-primitive
                                      gl-intcdr-primitive
                                      gl-bool-primitive))))

  (defret bfr-listp-of-<fn>
    (implies (and ;;(interp-st-bfrs-ok interp-st)
              (lbfr-listp (gl-objectlist-bfrlist args)
                          (interp-st->logicman interp-st))
                  )
             (lbfr-listp (gl-object-bfrlist ans)
                         (interp-st->logicman new-interp-st)))
    :hints(("Goal" :in-theory (enable gl-int-primitive
                                      gl-intcons-primitive
                                      gl-endint-primitive
                                      gl-intcar-primitive
                                      gl-intcdr-primitive
                                      gl-bool-primitive
                                      gl-objectlist-bfrlist
                                      bfr-listp-when-not-member-witness))))

  (defret interp-st-get-of-gl-primitive-fncall
    (implies (not (equal (interp-st-field-fix key) :logicman))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st)))
    :hints(("Goal" :in-theory (enable gl-int-primitive
                                      gl-intcons-primitive
                                      gl-endint-primitive
                                      gl-intcar-primitive
                                      gl-intcdr-primitive
                                      gl-bool-primitive))))

  (defret logicman-extension-of-<fn>
    (implies (equal old (interp-st->logicman interp-st))
             (logicman-extension-p (interp-st->logicman new-interp-st) old))
    :hints(("Goal" :in-theory (enable gl-int-primitive
                                      gl-intcons-primitive
                                      gl-endint-primitive
                                      gl-intcar-primitive
                                      gl-intcdr-primitive
                                      gl-bool-primitive)))))
                                      
      



;; (define glcp-unify-term/gobj-list-prefix ((pat pseudo-term-listp)
;;                                         (x gl-objectlist-p)
;;                                         (alist gl-object-alist-p))
;;   ;; Same as glcp-unify-term/gobj-list but doesn't complain about extra or missing elements of x.
;;   ;; Equivalent to (glcp-unify-term/gobj-list pat (take (len pat) x) alist).
;;   (b* (((when (atom pat)) (mv t (gl-object-alist-fix alist)))
;;        ((mv ok alist) (glcp-unify-term/gobj (car pat) (car x) alist))
;;        ((unless ok) (mv nil nil)))
;;     (glcp-unify-term/gobj-list-prefix (cdr pat) (cdr x) alist))
;;   ///
;;   (defthm glcp-unify-term/gobj-list-prefix-elim
;;     (equal (glcp-unify-term/gobj-list-prefix pat x alist)
;;            (glcp-unify-term/gobj-list pat (take (len pat) x) alist))
;;     :hints(("Goal" :induct (glcp-unify-term/gobj-list-prefix pat x alist)
;;             :expand ((:free (x) (glcp-unify-term/gobj-list pat x alist))
;;                      (take (len pat) x))))))





(define gl-interp-finish-simplify-if-test-ite ((test-bfr interp-st-bfr-p)
                                               (then-bfr interp-st-bfr-p)
                                               (else-bfr interp-st-bfr-p)
                                               (then-unreachable)
                                               (else-unreachable)
                                               interp-st)
  :returns (mv (ite (interp-st-bfr-p ite new-interp-st))
               new-interp-st)
  (b* (((when then-unreachable)
        (if else-unreachable
            (b* ((interp-st (interp-st-set-error :unreachable interp-st)))
              (mv nil interp-st))
          (mv (interp-st-bfr-fix else-bfr) interp-st)))
       ((when else-unreachable)
        (mv (interp-st-bfr-fix then-bfr) interp-st)))
    (stobj-let ((logicman (interp-st->logicman interp-st)))
               (ite logicman)
               (bfr-ite test-bfr then-bfr else-bfr)
               (mv ite interp-st)))
  ///
  (defret interp-st-bfrs-ok-of-<fn>
    (implies (interp-st-bfrs-ok interp-st)
             (interp-st-bfrs-ok new-interp-st)))

  (defret lbfr-p-of-<fn>
    (lbfr-p ite (interp-st->logicman new-interp-st)))

  (defret interp-st-get-of-<fn>
    (implies (and (not (equal (interp-st-field-fix key) :logicman))
                  (not (equal (interp-st-field-fix key) :errmsg)))
             (equal (interp-st-get key new-interp-st)
                    (interp-st-get key interp-st))))

  (defret logicman-extension-p-of-<fn>
    (implies (equal old-logicman (interp-st->logicman interp-st))
             (logicman-extension-p (interp-st->logicman new-interp-st) old-logicman)))
  

  (defret <fn>-preserves-errmsg
    (implies (interp-st->errmsg interp-st)
             (equal (interp-st->errmsg new-interp-st)
                    (interp-st->errmsg interp-st)))))

















(local (defthm len-equal-0
         (equal (equal (len x) 0)
                (not (consp x)))))

(local
 (defthm pseudo-term-bindinglist-count-when-consp
   (implies (consp x)
            (< (+ (pseudo-term-binding-count (car x))
                  (pseudo-term-list-binding-count (cdr x)))
               (pseudo-term-list-binding-count x)))
    :rule-classes :linear))

(local (defthm len-of-cons
         (equal (len (cons a b))
                (+ 1 (len b)))))

(local (defthm and*-hyp
         (implies (acl2::rewriting-negative-literal `(acl2::binary-and* ,a ,b))
                  (iff (and* a b) (and a b)))))

(local (defun len-is (x n)
         (if (zp n)
             (and (eql n 0) (atom x))
           (and (consp x)
                (len-is (cdr x) (1- n))))))

(local (defthm open-len-is
         (implies (syntaxp (quotep n))
                  (equal (len-is x n)
                         (if (zp n)
                             (and (eql n 0) (atom x))
                           (and (consp x)
                                (len-is (cdr x) (1- n))))))))
                         

(local (defthm equal-len-hyp
         (implies (syntaxp (and (or (acl2::rewriting-negative-literal-fn `(equal (len ,x) ,n) mfc state)
                                    (acl2::rewriting-negative-literal-fn `(equal ,n (len ,x)) mfc state))
                                (quotep n)))
                  (equal (equal (len x) n)
                         (len-is x n)))))

(local (defthm gl-object-count-of-car-weak
         (<= (gl-object-count (car x)) (gl-objectlist-count x))
         :hints (("goal" :cases ((consp x))))
         :rule-classes :linear))

(local (defthm gl-objectlist-count-of-cdr-weak
         (<= (gl-objectlist-count (cdr x)) (gl-objectlist-count x))
         :hints (("goal" :cases ((consp x))))
         :rule-classes :linear))

(local (defthm mv-nth-of-cons
         (equal (mv-nth n (cons a b))
                (if (zp n) a (mv-nth (1- n) b)))
         :hints(("Goal" :in-theory (enable mv-nth)))))


(local (defthm len-cdr-less-when-consp
         (implies (consp x)
                  (< (len (cdr x)) (len x)))
         :rule-classes :linear))

(local (defthm stack$a-open-nth-scratch
         (implies (syntaxp (quotep n))
                  (equal (stack$a-nth-scratch n stack)
                         (if (zp n)
                             (stack$a-top-scratch stack)
                           (stack$a-nth-scratch (1- n)
                                                (stack$a-pop-scratch stack)))))
         :hints(("Goal" :in-theory (enable stack$a-top-scratch stack$a-pop-scratch stack$a-nth-scratch)))))


(local (in-theory (disable (tau-system) len default-car default-cdr
                           pseudo-termp
                           pseudo-term-listp
                           fgetprop
                           not
                           acl2::nfix-when-not-natp
                           equal-of-booleans-rewrite
                           mv-nth-cons-meta
                           acl2::take-redefinition
                           acl2::take-of-too-many
                           acl2::take-of-len-free
                           acl2::take-when-atom
                           acl2::lower-bound-of-len-when-sublistp
                           append)))


(define gl-interp-check-reclimit (interp-st)
  :inline t
  (or (zp (interp-st->reclimit interp-st))
      (interp-st->errmsg interp-st))
  ///
  (defthm not-check-reclimit-implies-posp-reclimit
    (implies (not (gl-interp-check-reclimit interp-st))
             (posp (interp-st->reclimit interp-st)))
    :rule-classes :forward-chaining)

  (def-updater-independence-thm gl-interp-check-reclimit-of-update
    (implies (and (equal (interp-st->reclimit new) (interp-st->reclimit old))
                  (equal (interp-st->errmsg new) (interp-st->errmsg old)))
             (equal (gl-interp-check-reclimit new) (gl-interp-check-reclimit old)))))
      

(set-state-ok t)



(progn
  (with-output
    :off (event prove)
    (defines gl-interp
      :flag-local nil
      (define gl-interp-test ((x pseudo-termp)
                              (interp-st interp-st-bfrs-ok)
                              state)
        ;; Translate a term to a GL object under the given alist substitution, preserving IFF.
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020 (pseudo-term-binding-count x) 60)
        :well-founded-relation acl2::nat-list-<
        :verify-guards nil
        :measure-debug t
        ;; :guard (bfr-listp (gl-object-alist-bfrlist alist) (interp-st->bfrstate interp-st))
        :returns (mv xbfr
                     new-interp-st
                     new-state)
        (b* (((interp-st-bind
               (equiv-contexts '(iff)))
              ((gl-interp-recursive-call xobj interp-st state)
               (gl-interp-term-equivs x interp-st state))))
          (gl-interp-simplify-if-test xobj interp-st state)))

      (define gl-interp-term-equivs ((x pseudo-termp)
                                     (interp-st interp-st-bfrs-ok)
                                     state)
        :measure (list (nfix (interp-st->reclimit interp-st)) 2020 (pseudo-term-binding-count x) 40)
        :returns (mv
                  (xobj gl-object-p)
                  new-interp-st
                  new-state)
        (b* (((mv xobj interp-st state)
              (gl-interp-term x interp-st state))
             ;; ((when err) (mv nil interp-st state))
             ((unless (glcp-term-obj-p xobj))
              (mv xobj interp-st state))
             (contexts (interp-st->equiv-contexts interp-st)))
          (stobj-let ((pathcond (interp-st->pathcond interp-st))
                      (logicman (interp-st->logicman interp-st))
                      (bvar-db (interp-st->bvar-db interp-st)))
                     (replacedp val pathcond)
                     (try-equivalences-loop
                      xobj contexts 100 ;; bozo, configure reclimit for try-equivalences-loop?
                      pathcond bvar-db logicman state)
                     (mv val interp-st state))))

      (define gl-interp-term ((x pseudo-termp)
                              (interp-st interp-st-bfrs-ok)
                              state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020 (pseudo-term-binding-count x) 20)
        :returns (mv
                  (xobj gl-object-p)
                  new-interp-st
                  new-state)
        (pseudo-term-case x
          :const (mv (g-concrete x.val) interp-st state)
          :var (b* ((minor-look (assoc-eq x.name (interp-st-minor-bindings interp-st)))
                    ((when minor-look)
                     (mv (cdr minor-look) interp-st state)))
                 (mv (cdr (assoc-eq x.name (interp-st-bindings interp-st))) interp-st state))
          :lambda
          (b* (((mv x-bindings body) (lambda-nest-to-bindinglist x))
               (interp-st (interp-st-push-minor-frame interp-st))
               (interp-st (interp-st-set-minor-debug x interp-st))
               ((interp-st-bind
                 (equiv-contexts nil))
                ((gl-interp-recursive-call interp-st state)
                 ;; replaces the top of stack with the bindings
                 (gl-interp-bindinglist x-bindings interp-st state)))

               ;; ((when err)
               ;;  (b* ((interp-st (interp-st-pop-minor-frame interp-st)))
               ;;    (mv nil interp-st state)))
               ((mv val interp-st state)
                (gl-interp-term-equivs body interp-st state))
               (interp-st (interp-st-pop-minor-frame interp-st)))
            (mv val interp-st state))
          :fncall 
          (b* (((when (and** (eq x.fn 'if) (eql (len x.args) 3)))
                (gl-interp-if/or (first x.args)
                                 (second x.args)
                                 (third x.args)
                                 interp-st state))
               ((when (and** (eq x.fn 'return-last) (eql (len x.args) 3)))
                (gl-interp-return-last (first x.args)
                                       (second x.args)
                                       (third x.args)
                                       interp-st state))

               ((interp-st-bind
                 (equiv-contexts nil))
                ((gl-interp-recursive-call args interp-st state)
                 (gl-interp-arglist x.args interp-st state)))

               ;; ((when err)
               ;;  (mv nil interp-st state))
               )
            (gl-interp-fncall x.fn args interp-st state))))

      (define gl-interp-arglist ((args pseudo-term-listp)
                                 (interp-st interp-st-bfrs-ok)
                                 state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020 (pseudo-term-list-binding-count args) 20)
        :returns (mv
                  (arg-objs gl-objectlist-p)
                  new-interp-st
                  new-state)
        (b* (((when (atom args)) (mv nil interp-st state))
             ((gl-interp-recursive-call arg1 interp-st state)
              (gl-interp-term-equivs (car args) interp-st state))
             ;; ((when err) (mv nil interp-st state))
             (interp-st (interp-st-push-scratch-gl-obj arg1 interp-st))
             ((mv rest interp-st state)
              (gl-interp-arglist (cdr args) interp-st state))
             ((mv arg interp-st) (interp-st-pop-scratch-gl-obj interp-st)))
          (mv (cons arg rest) interp-st state)))

      (define gl-interp-bindinglist ((bindings cmr::bindinglist-p)
                                     (interp-st interp-st-bfrs-ok)
                                     state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020
                       (cmr::bindinglist-count bindings)
                       20)
        :returns (mv
                  new-interp-st
                  new-state)
        (b* (((when (atom bindings)) (mv interp-st state))
             ((cmr::binding x1) (car bindings))
             ((gl-interp-recursive-call args interp-st state)
              (gl-interp-arglist x1.args interp-st state))
             ;; ((when err) (mv interp-st state))
             (interp-st (interp-st-add-minor-bindings (pairlis$ x1.formals args) interp-st)))
          (gl-interp-bindinglist (cdr bindings) interp-st state)))
      
      (define gl-interp-fncall ((fn pseudo-fnsym-p)
                                (args gl-objectlist-p)
                                (interp-st interp-st-bfrs-ok)
                                state)
        :guard (interp-st-bfr-listp (gl-objectlist-bfrlist args))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       0 0 1)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* (((gl-function-mode fn-mode)
              (gl-function-mode-fix!
               (cdr (hons-assoc-equal fn (table-alist 'gl-fn-modes (w state))))))
             ((mv successp ans)
              (fncall-try-concrete-eval fn args fn-mode.dont-concrete-exec state))
             ((when successp)
              (mv ans interp-st state))
             (reclimit (interp-st->reclimit interp-st))
             ((when (gl-interp-check-reclimit interp-st))
              (gl-interp-error
               :msg (gl-msg "The recursion limit ran out.")))
             (interp-st (interp-st-push-scratch-gl-objlist args interp-st))
             ((interp-st-bind
               (reclimit (1- reclimit) reclimit))
              ((gl-interp-recursive-call successp ans interp-st state)
               (gl-rewrite-fncall fn args fn-mode.dont-rewrite interp-st state)))
             ;; ((when err)
             ;;  (b* ((interp-st (interp-st-pop-scratch interp-st)))
             ;;    (mv nil interp-st state)))
             ((when successp)
              (b* ((interp-st (interp-st-pop-scratch interp-st)))
                (mv ans interp-st state)))
             (args (interp-st-top-scratch-gl-objlist interp-st))
             ((mv successp ans interp-st state)
              (gl-primitive-fncall fn args fn-mode.dont-primitive-exec interp-st state))
             ((when successp)
              (b* ((interp-st (interp-st-pop-scratch interp-st)))
                (mv ans interp-st state)))
             (args (interp-st-top-scratch-gl-objlist interp-st))
             ((interp-st-bind
               (reclimit (1- reclimit) reclimit))
              ((mv successp ans interp-st state)
               (gl-interp-fn-definition fn args fn-mode.dont-expand-def interp-st state)))
             ((mv args interp-st) (interp-st-pop-scratch-gl-objlist interp-st))
             ;; ((when err)
             ;;  (mv nil interp-st state))
             ((when successp)
              (mv ans interp-st state)))
          (mv (g-apply fn args) interp-st state)))

      (define gl-interp-fn-definition ((fn pseudo-fnsym-p)
                                       (args gl-objectlist-p)
                                       (dont)
                                       (interp-st interp-st-bfrs-ok)
                                       state)
        :guard (interp-st-bfr-listp (gl-objectlist-bfrlist args))
        :measure (list (nfix (interp-st->reclimit interp-st)) 20000 0 0)
        :returns (mv successp
                     (ans gl-object-p)
                     new-interp-st
                     new-state)
        (b* (((when dont)
              (mv nil nil interp-st state))
             (rules (fn-definition-rules fn (glcp-config->definition-table
                                             (interp-st->config interp-st))
                                         (w state)))
             ((unless rules)
              (mv nil nil interp-st state))
             (interp-st (interp-st-push-scratch-gl-objlist args interp-st))
             ((mv successp ans interp-st state)
              (gl-rewrite-try-rules rules fn interp-st state))
             (interp-st (interp-st-pop-scratch interp-st)))
          (mv successp ans interp-st state)))


      (define gl-rewrite-fncall ((fn pseudo-fnsym-p)
                                 (args gl-objectlist-p)
                                 (dont)
                                 (interp-st interp-st-bfrs-ok)
                                 state)
        :guard (interp-st-bfr-listp (gl-objectlist-bfrlist args))
        :measure (list (nfix (interp-st->reclimit interp-st)) 20000 0 0)
        :returns (mv successp
                     (ans gl-object-p)
                     new-interp-st
                     new-state)
        (b* (((when dont)
              (mv nil nil interp-st state))
             (rules (fn-rewrite-rules fn (glcp-config->rewrite-rule-table
                                          (interp-st->config interp-st))
                                      (w state)))
             ((unless rules)
              (mv nil nil interp-st state))
             (interp-st (interp-st-push-scratch-gl-objlist args interp-st))
             ((mv successp ans interp-st state)
              (gl-rewrite-try-rules rules fn interp-st state))
             (interp-st (interp-st-pop-scratch interp-st)))
          (mv successp ans interp-st state)))
      

      (define gl-rewrite-try-rules ((rules pseudo-rewrite-rule-listp)
                                    (fn pseudo-fnsym-p)
                                    (interp-st interp-st-bfrs-ok)
                                    state)
        :guard (and (< 0 (interp-st-scratch-len interp-st))
                    (scratchobj-case (interp-st-top-scratch interp-st) :gl-objlist))
        ;; :guard (interp-st-bfr-listp (gl-objectlist-bfrlist args))
        :measure (list (nfix (interp-st->reclimit interp-st)) 10000 (len rules) 0)
        :returns (mv successp
                     (ans gl-object-p)
                     new-interp-st
                     new-state)
        (b* (((when (atom rules))
              (mv nil nil interp-st state))
             (args (interp-st-top-scratch-gl-objlist interp-st))
             ((gl-interp-recursive-call successp ans interp-st state)
              (gl-rewrite-try-rule (car rules) fn args interp-st state))
             ((when successp)
              (mv successp ans interp-st state)))
          (gl-rewrite-try-rules (cdr rules) fn interp-st state)))

      (define gl-rewrite-try-rule ((rule pseudo-rewrite-rule-p)
                                   (fn pseudo-fnsym-p)
                                   (args gl-objectlist-p)
                                   (interp-st interp-st-bfrs-ok)
                                   state)
        :guard (interp-st-bfr-listp (gl-objectlist-bfrlist args))
        :measure (list (nfix (interp-st->reclimit interp-st)) 10000 0 0)
        :returns (mv successp
                     (ans gl-object-p)
                     new-interp-st
                     new-state)
        (b* (((acl2::rewrite-rule rule))
             ((unless (and** (mbt (and* (symbolp rule.equiv)
                                        (not (eq rule.equiv 'quote))
                                        ;; (ensure-equiv-relationp rule.equiv (w state))
                                        (not (eq rule.subclass 'acl2::meta))
                                        (pseudo-termp rule.lhs)))
                             (pseudo-term-case rule.lhs
                               :fncall (and (eq rule.lhs.fn (pseudo-fnsym-fix fn))
                                            ;; (eql (len rule.lhs.args) (len args))
                                            )
                               :otherwise nil)))
              (gl-interp-error
               :msg (gl-msg "Malformed rewrite rule: ~x0~%" rule)
               :nvals 2))
             ((unless (or (eq rule.equiv 'equal)
                          ;; bozo check refinements
                          (member rule.equiv (interp-st->equiv-contexts interp-st))))
              (mv nil nil interp-st state))
             (rule.lhs.args (pseudo-term-call->args rule.lhs))
             ((mv unify-ok bindings) (glcp-unify-term/gobj-list rule.lhs.args
                                                                args
                                                                nil))
             ((unless unify-ok) (mv nil nil interp-st state))
             ((unless (mbt (pseudo-term-listp rule.hyps)))
              (gl-interp-error
               :msg (gl-msg "Malformed rewrite rule: ~x0~%" rule)
               :nvals 2))
             (backchain-limit (interp-st->backchain-limit interp-st))
             ((when (and** rule.hyps (eql 0 backchain-limit)))
              (mv nil nil interp-st state))
             (flags (interp-st->flags interp-st))
             (hyps-flags  (!interp-flags->intro-synvars
                           t
                           (!interp-flags->intro-bvars
                            nil
                            (!interp-flags->simplify-logic nil flags))))
             (interp-st (interp-st-push-frame bindings interp-st))
             (interp-st (interp-st-set-debug rule interp-st))
             ((interp-st-bind
               (flags hyps-flags flags)
               (equiv-contexts '(iff))
               (backchain-limit (1- backchain-limit) backchain-limit))
              ((gl-interp-recursive-call successp interp-st state)
               (gl-rewrite-relieve-hyps rule.hyps interp-st state)))

             ((unless (and** successp (not (interp-st->errmsg interp-st))))
              (b* ((interp-st (interp-st-pop-frame interp-st))
                   (interp-st (interp-st-cancel-error :intro-bvars-fail interp-st)))
                (mv nil nil interp-st state)))

             (concl-flags (!interp-flags->intro-synvars t flags))
             ((interp-st-bind
               (flags concl-flags flags))
              ((mv val interp-st state)
               (gl-interp-term-equivs rule.rhs interp-st state)))

             (interp-st (interp-st-pop-frame interp-st)))

          (mv t val interp-st state)))
      
      (define gl-rewrite-relieve-hyps ((hyps pseudo-term-listp)
                                       (interp-st interp-st-bfrs-ok)
                                       state)
        :measure (list (nfix (interp-st->reclimit interp-st)) 9000
                       (pseudo-term-list-binding-count hyps) 0)
        :returns (mv successp
                     new-interp-st
                     new-state)
        (b* (((when (atom hyps))
              (mv t interp-st state))
             ((gl-interp-recursive-call ok interp-st state)
              (gl-rewrite-relieve-hyp (car hyps) interp-st state))
             ((when (not ok))
              (mv ok interp-st state)))
          (gl-rewrite-relieve-hyps (cdr hyps) interp-st state)))
      
      (define gl-rewrite-relieve-hyp ((hyp pseudo-termp)
                                      (interp-st interp-st-bfrs-ok)
                                      state)
        :measure (list (nfix (interp-st->reclimit interp-st)) 9000
                       (pseudo-term-binding-count hyp) 0)
        :returns (mv successp
                     new-interp-st
                     new-state)
        (b* (((mv synp-type untrans-form trans-term vars)
              (gl-interp-match-synp hyp))
             ((when synp-type)
              (gl-rewrite-relieve-hyp-synp synp-type trans-term vars untrans-form interp-st state))
             ((mv test-bfr interp-st state)
              (gl-interp-test hyp interp-st state)))
          (mv (eq test-bfr t) interp-st state)))

      (define gl-interp-time$ ((timing-arg pseudo-termp)
                               (x pseudo-termp)
                               (interp-st interp-st-bfrs-ok)
                               state)
        :measure (list (nfix (interp-st->reclimit interp-st)) 2020
                       (+ (pseudo-term-binding-count timing-arg)
                          (pseudo-term-binding-count x))
                       30)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* (((interp-st-bind
               (equiv-contexts nil))
              ((gl-interp-recursive-call time$-arg interp-st state)
               (gl-interp-term-equivs timing-arg interp-st state)))
             ;; ((when err)
             ;;  (mv nil interp-st state))
             (time$-arg (gl-interp-time$-arg time$-arg x)))
          (acl2::time$1 time$-arg
                        (gl-interp-term-equivs x interp-st state))))
      
      (define gl-interp-return-last ((return-last-fnname pseudo-termp)
                                     (first-arg pseudo-termp)
                                     (last-arg pseudo-termp)
                                     (interp-st interp-st-bfrs-ok)
                                     state)
        :measure (list (nfix (interp-st->reclimit interp-st)) 2020
                       (+ (pseudo-term-binding-count first-arg)
                          (pseudo-term-binding-count last-arg))
                       40)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* (((when (equal return-last-fnname ''time$1-raw))
              (gl-interp-time$ first-arg last-arg interp-st state))
             ((when (equal return-last-fnname ''(syntax-bind)))
              (gl-interp-syntax-bind first-arg last-arg interp-st state)))
          ;; Otherwise just evaluate the last-arg.
          (gl-interp-term-equivs last-arg interp-st state)))
      
      

      (define gl-interp-if/or ((test pseudo-termp)
                               (then pseudo-termp)
                               (else pseudo-termp)
                               (interp-st interp-st-bfrs-ok)
                               state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020
                       (+ (pseudo-term-binding-count test)
                          (pseudo-term-binding-count then)
                          (pseudo-term-binding-count else))
                       60)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (if (hons-equal test then)
            (gl-interp-or test else interp-st state)
          (gl-interp-if test then else interp-st state)))

      
      (define gl-interp-if ((test pseudo-termp)
                            (then pseudo-termp)
                            (else pseudo-termp)
                            (interp-st interp-st-bfrs-ok)
                            state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020
                       (+ (pseudo-term-binding-count test)
                          (pseudo-term-binding-count then)
                          (pseudo-term-binding-count else))
                       40)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        ;; Tricky because we have to keep the test/thenval on the stack while we
        ;; run the then/else branches, because we might simplify the logicman while
        ;; running them.
        (b* (((gl-interp-recursive-call testbfr interp-st state)
              (gl-interp-test test interp-st state))
             ;; ((when err) (mv nil interp-st state))
             (interp-st (interp-st-push-scratch-bfr testbfr interp-st))
             ((gl-interp-recursive-call then-unreachable thenval interp-st state)
              ;; pushes val onto scratch if not unreachable
              (gl-maybe-interp testbfr then interp-st state))
             ;; ((when err)
             ;;  (b* ((interp-st (interp-st-pop-scratch interp-st)))
             ;;    (mv nil interp-st state)))
             (testbfr (interp-st-top-scratch-bfr interp-st))
             (interp-st (interp-st-push-scratch-gl-obj thenval interp-st))
             ((gl-interp-recursive-call else-unreachable elseval interp-st state)
              ;; pushes val onto scratch if not unreachable
              (gl-maybe-interp (interp-st-bfr-not testbfr) else interp-st state))
             ;; ((when err)
             ;;  (b* ((interp-st (interp-st-pop-scratch interp-st))
             ;;       (interp-st (interp-st-pop-scratch interp-st)))
             ;;    (mv nil interp-st state)))
             ((mv thenval interp-st) (interp-st-pop-scratch-gl-obj interp-st))
             ((mv testbfr interp-st) (interp-st-pop-scratch-bfr interp-st))
             ((when then-unreachable)
              (if else-unreachable
                  (b* ((interp-st (interp-st-set-error :unreachable interp-st)))
                    (mv nil interp-st state))
                (mv elseval interp-st state)))
             ((when else-unreachable)
              (mv thenval interp-st state)))
          (gl-interp-merge-branches testbfr thenval elseval interp-st state)))

      (define gl-interp-or ((test pseudo-termp)
                            (else pseudo-termp)
                            (interp-st interp-st-bfrs-ok)
                            state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020
                       (+ (pseudo-term-binding-count test)
                          (pseudo-term-binding-count else))
                       40)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* ((equiv-contexts (interp-st->equiv-contexts interp-st))
             (or-test-equiv-contexts (gl-interp-or-test-equiv-contexts equiv-contexts))
             ((interp-st-bind
               (equiv-contexts or-test-equiv-contexts equiv-contexts))
              ((gl-interp-recursive-call testval interp-st state)
               (gl-interp-term-equivs test interp-st state)))
             ;; ((when err) (mv nil interp-st state))
             (interp-st (interp-st-push-scratch-gl-obj testval interp-st))
             ((gl-interp-recursive-call testbfr interp-st state)
              (gl-interp-simplify-if-test testval interp-st state))
             ;; ((when err)
             ;;  (b* ((interp-st (interp-st-pop-scratch interp-st)))
             ;;    (mv nil interp-st state)))
             (interp-st (interp-st-push-scratch-bfr testbfr interp-st))
             ((gl-interp-recursive-call else-unreachable elseval interp-st state)
              (gl-maybe-interp (interp-st-bfr-not testbfr) else interp-st state))
             ((mv testbfr interp-st) (interp-st-pop-scratch-bfr interp-st))
             ((mv testval interp-st) (interp-st-pop-scratch-gl-obj interp-st))
             ;; ((when err)
             ;;  (mv nil interp-st state))
             ((when else-unreachable)
              (mv testval interp-st state)))
          (gl-interp-merge-branches testbfr testval elseval interp-st state)))


      (define gl-maybe-interp ((test interp-st-bfr-p)
                               (x pseudo-termp)
                               (interp-st interp-st-bfrs-ok)
                               state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2020
                       (pseudo-term-binding-count x)
                       60)
        :returns (mv
                  unreachable
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* (((mv contra interp-st)
              (interp-st-pathcond-assume test interp-st))
             ((when contra)
              (mv t nil interp-st state))
             ((mv ans interp-st state)
              (gl-interp-term-equivs x interp-st state))
             (interp-st (interp-st-pathcond-rewind interp-st))
             ((when (eq (interp-st->errmsg interp-st) :unreachable))
              (b* ((interp-st (update-interp-st->errmsg nil interp-st)))
                (mv t nil interp-st state))))
          (mv nil ans interp-st state)))

      (define gl-interp-maybe-simplify-if-test ((test interp-st-bfr-p)
                                                (xobj gl-object-p)
                                                (interp-st interp-st-bfrs-ok)
                                                state)
        :guard (interp-st-bfr-listp (gl-object-bfrlist xobj))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       0
                       (gl-object-count xobj)
                       60)
        :returns (mv
                  unreachable
                  xbfr
                  new-interp-st
                  new-state)
        (b* (((mv contra interp-st)
              (interp-st-pathcond-assume test interp-st))
             ((when contra)
              (mv t nil interp-st state))
             (reclimit (interp-st->reclimit interp-st))
             ((when (gl-interp-check-reclimit interp-st))
              (b* ((interp-st (interp-st-pathcond-rewind interp-st)))
                (gl-interp-error :msg (gl-msg "The recursion limit ran out.") :nvals 2)))
             ((interp-st-bind
               (reclimit (1- reclimit) reclimit))
              ((mv ans interp-st state)
               (gl-interp-simplify-if-test xobj interp-st state)))
             (interp-st (interp-st-pathcond-rewind interp-st))
             ((when (eq (interp-st->errmsg interp-st) :unreachable))
              (b* ((interp-st (update-interp-st->errmsg nil interp-st)))
                (mv t nil interp-st state))))
          (mv nil ans interp-st state)))

      (define gl-interp-simplify-if-test ((xobj gl-object-p)
                                          (interp-st interp-st-bfrs-ok)
                                          state)
        :guard (interp-st-bfr-listp (gl-object-bfrlist xobj))
        :returns (mv
                  xbfr
                  new-interp-st
                  new-state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2000
                       (gl-object-count xobj)
                       40)
        (gl-object-case xobj
          :g-concrete (mv (bool-fix xobj.val) interp-st state)
          :g-boolean (mv xobj.bool interp-st state)
          :g-integer (mv t interp-st state)
          :g-cons (mv t interp-st state)
          :g-var (b* (((mv bfr interp-st)
                       (interp-st-add-term-bvar-unique xobj interp-st state)))
                   (mv bfr interp-st state))
          :g-ite (gl-interp-simplify-if-test-ite xobj interp-st state)
          :g-apply (gl-interp-simplify-if-test-fncall xobj interp-st state)))

      ;; BOZO should we have a version of this for OR?
      (define gl-interp-simplify-if-test-ite ((xobj gl-object-p)
                                              (interp-st interp-st-bfrs-ok)
                                              state)
        :guard (and (gl-object-case xobj :g-ite)
                    (interp-st-bfr-listp (gl-object-bfrlist xobj)))
        :returns (mv
                  xbfr
                  new-interp-st
                  new-state)
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2000
                       (gl-object-count xobj)
                       30)
        (b* (((unless (mbt (gl-object-case xobj :g-ite)))
              (gl-interp-error :msg (gl-msg "Impossible case")))
             ((g-ite xobj))
             (interp-st (interp-st-push-scratch-gl-obj xobj.else interp-st))
             (interp-st (interp-st-push-scratch-gl-obj xobj.then interp-st))
             ;; scratch: xobj.then, xobj.else
             ((gl-interp-recursive-call test-bfr interp-st state)
              (gl-interp-simplify-if-test xobj.test interp-st state))
             ;; ((when err)
             ;;  (b* ((interp-st (interp-st-pop-scratch interp-st))
             ;;       (interp-st (interp-st-pop-scratch interp-st)))
             ;;    (mv nil interp-st state)))
             (xobj.then (interp-st-top-scratch-gl-obj interp-st))
             (interp-st (interp-st-update-scratch-bfr 0 test-bfr interp-st))
             ;; scratch: test-bfr, xobj.else
             ((gl-interp-recursive-call then-unreachable then-bfr interp-st state)
              (gl-interp-maybe-simplify-if-test test-bfr xobj.then interp-st state))
             ;; ((when err)
             ;;  (b* ((interp-st (interp-st-pop-scratch interp-st))
             ;;       (interp-st (interp-st-pop-scratch interp-st)))
             ;;    (mv nil interp-st state)))
             (test-bfr (interp-st-top-scratch-bfr interp-st))
             (xobj.else (interp-st-nth-scratch-gl-obj 1 interp-st))
             (interp-st (interp-st-update-scratch-bfr 1 then-bfr interp-st))
             ;; scratch: test-bfr, then-bfr
             ((mv else-unreachable else-bfr interp-st state)
              (gl-interp-maybe-simplify-if-test test-bfr xobj.else interp-st state))
             ;; ((when err)
             ;;  (b* ((interp-st (interp-st-pop-scratch interp-st))
             ;;       (interp-st (interp-st-pop-scratch interp-st)))
             ;;    (mv nil interp-st state)))
             ((mv test-bfr interp-st) (interp-st-pop-scratch-bfr interp-st))
             ((mv then-bfr interp-st) (interp-st-pop-scratch-bfr interp-st))
             ((mv bfr interp-st)
              (gl-interp-finish-simplify-if-test-ite
               test-bfr then-bfr else-bfr then-unreachable else-unreachable interp-st)))
          (mv bfr interp-st state)))
      ;;    ((when then-unreachable)
      ;;     (if else-unreachable
      ;;         (mv :unreachable nil interp-st state)
      ;;       (mv nil else-bfr interp-st state)))
      ;;    ((when else-unreachable)
      ;;     (mv nil then-bfr interp-st state))
      ;;    ((mv ite interp-st) (stobj-let ((logicman (interp-st->logicman interp-st)))
      ;;                                   (ite logicman)
      ;;                                   (bfr-ite test-bfr then-bfr else-bfr)
      ;;                                   (mv ite interp-st))))
      ;; (mv nil ite interp-st state)))

      (define gl-interp-simplify-if-test-fncall ((xobj gl-object-p)
                                                 (interp-st interp-st-bfrs-ok)
                                                 state)
        :guard (and (gl-object-case xobj :g-apply)
                    (interp-st-bfr-listp (gl-object-bfrlist xobj)))

        :measure (list (nfix (interp-st->reclimit interp-st))
                       2000
                       (gl-object-count xobj)
                       20)
        :returns (mv
                  xbfr
                  new-interp-st
                  new-state)
        (b* (((unless (mbt (gl-object-case xobj :g-apply)))
              (gl-interp-error :msg (gl-msg "Impossible")))
             ((mv not-matched neg-arg)
              (gl-apply-match-not xobj))
             ((when not-matched)
              (b* (((mv bfr interp-st state)
                    (gl-interp-simplify-if-test neg-arg interp-st state))
                   ;; ((when err)
                   ;;  (mv nil interp-st state))
                   )
                (mv (interp-st-bfr-not bfr) interp-st state)))
             ((g-apply xobj))
             ((gl-function-mode fn-mode)
              (gl-function-mode-fix!
               (cdr (hons-assoc-equal xobj.fn (table-alist 'gl-fn-modes (w state))))))

             ;; BOZO support gl-interp-force-check.

             ;; We rewrite this fncall again because it presumably might not have
             ;; been done in IFF context before.  E.g.
             ;; (let ((a (foo x)))
             ;;   (if a y z))
             ;; Note we wouldn't do this fully "right" even if we had perfect
             ;; knowledge of congruences because our test term might be bound to a
             ;; variable that is used in both Boolean and non-Boolean contexts.
             (reclimit (interp-st->reclimit interp-st))
             ((when (gl-interp-check-reclimit interp-st))
              (gl-interp-error
               :msg (gl-msg "The recursion limit ran out.")))
             ((interp-st-bind
               (reclimit (1- reclimit) reclimit)
               (equiv-contexts '(iff)))
              ((gl-interp-recursive-call successp ans interp-st state)
               (gl-rewrite-fncall xobj.fn xobj.args fn-mode.dont-rewrite-under-if-test interp-st state)))
             ;; ((when err)
             ;;  (mv nil interp-st state))
             ((when successp)
              (b* (((interp-st-bind
                     (reclimit (1- reclimit) reclimit))
                    ((mv ans interp-st state)
                     (gl-interp-simplify-if-test ans interp-st state))))
                (mv ans interp-st state)))

             (look (stobj-let ((bvar-db (interp-st->bvar-db interp-st)))
                              (look)
                              (get-term->bvar xobj bvar-db)
                              look))
             ((when look)
              (b* ((bfr (stobj-let ((logicman (interp-st->logicman interp-st)))
                                   (bfr)
                                   (bfr-var look)
                                   bfr)))
                (mv bfr interp-st state)))

             ((unless (interp-flags->intro-bvars (interp-st->flags interp-st)))
              ;; Note: we only return intro-bvars-fail when this flag is set to
              ;; false, which it is not at the top level.  So when we set the flag
              ;; to true (as we do in relieve-hyp and add-bvar-constraint-substs,
              ;; e.g.) we check for this error specifically and catch it.
              ;; Otherwise we expect callers not to set intro-bvars to nil and then
              ;; they won't have to deal with this error specially.
              (b* ((interp-st (interp-st-set-error :intro-bvars-fail interp-st)))
                (mv nil interp-st state)))

             ((unless (gl-object-symbolic-boolean-free xobj))
              (gl-interp-error
               :msg (gl-msg "An object used as an IF test was not reduced to ~
                             either a term-like object or a symbolic Boolean, ~
                             i.e. it had both function calls and symbolic ~
                             Boolean parts.  This isn't currently allowed.  ~
                             The state global variable (~x0 ~x1) holds the object."
                            '@ 'gl-interp-error-debug-obj)
               :debug-obj xobj))

             ((mv bfr interp-st)
              (interp-st-add-term-bvar xobj interp-st state))

             (interp-st (interp-st-push-scratch-bfr bfr interp-st))

             ((mv interp-st state)
              (gl-interp-add-constraints xobj interp-st state))

             ((mv bfr interp-st) (interp-st-pop-scratch-bfr interp-st))

             ;; ((when err)
             ;;  (mv nil interp-st state))
             )
          (mv bfr interp-st state)))


      (define gl-interp-add-constraints ((xobj gl-object-p)
                                         (interp-st interp-st-bfrs-ok)
                                         state)
        :guard (and (gl-object-case xobj :g-apply)
                    (interp-st-bfr-listp (gl-object-bfrlist xobj)))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2000
                       (gl-object-count xobj)
                       15)
        :returns (mv
                  new-interp-st
                  new-state)
        (b* ((constraint-db (interp-st->constraint-db interp-st))
             ((mv constraint-substs constraint-db)
              (gbc-process-new-lit xobj constraint-db state))
             (interp-st (update-interp-st->constraint-db constraint-db interp-st))
             ((unless constraint-substs)
              (mv interp-st state))
             (reclimit (interp-st->reclimit interp-st))
             ((when (gl-interp-check-reclimit interp-st))
              (gl-interp-error :msg (gl-msg "The recursion limit ran out.") :nvals 0))
             ;; Disable the pathcond so that constraint thms are simulated in an empty (universal) context.
             ((mv pathcond-enabledp interp-st) (stobj-let ((pathcond (interp-st->pathcond interp-st)))
                                                          (enabledp pathcond)
                                                          (b* ((enabledp (pathcond-enabledp pathcond))
                                                               (pathcond (update-pathcond-enabledp nil pathcond)))
                                                            (mv enabledp pathcond))
                                                          (mv enabledp interp-st)))

             (flags (interp-st->flags interp-st))
             (new-flags  (!interp-flags->intro-synvars
                          t
                          (!interp-flags->intro-bvars
                           nil
                           (!interp-flags->simplify-logic nil flags))))
             ((interp-st-bind
               (flags new-flags flags)
               (reclimit (1- reclimit) reclimit))
              ((mv interp-st state)
               (gl-interp-add-constraints-for-substs constraint-substs interp-st state)))

             (interp-st (stobj-let ((pathcond (interp-st->pathcond interp-st)))
                                   (pathcond)
                                   (update-pathcond-enabledp pathcond-enabledp pathcond)
                                   interp-st)))
          (mv interp-st state)))
      


      (define gl-interp-add-constraints-for-substs ((substs constraint-instancelist-p)
                                                    (interp-st interp-st-bfrs-ok)
                                                    state)
        :guard (interp-st-bfr-listp (constraint-instancelist-bfrlist substs))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       10000
                       (len substs)
                       10)
        :returns (mv
                  new-interp-st
                  new-state)
        (b* (((when (atom substs)) (mv interp-st state))
             ((constraint-instance sub1) (car substs))
             (thm-body (meta-extract-formula sub1.thmname state))
             ((unless (pseudo-termp thm-body))
              (gl-interp-add-constraints-for-substs (cdr substs) interp-st state))
             (interp-st (interp-st-push-scratch-cinstlist (cdr substs) interp-st))
             (interp-st (interp-st-push-frame sub1.subst interp-st))
             ((gl-interp-recursive-call bfr interp-st state)
              (gl-interp-test thm-body interp-st state))
             (interp-st (interp-st-pop-frame interp-st))
             ((mv rest interp-st) (interp-st-pop-scratch-cinstlist interp-st))
             ((unless (mbt (eql (len rest) (len (cdr substs)))))
              ;; impossible case
              (mv interp-st state))
             
             ((when (interp-st->errmsg interp-st))
              (b* ((interp-st (interp-st-cancel-error :intro-bvars-fail interp-st)))
                (gl-interp-add-constraints-for-substs rest interp-st state)))
             ;; ((when err)
             ;;  (mv interp-st state))
             ((mv contra interp-st) (stobj-let ((constraint-pathcond (interp-st->constraint interp-st))
                                                (logicman (interp-st->logicman interp-st)))
                                               (contra constraint-pathcond)
                                               (logicman-pathcond-assume bfr constraint-pathcond)
                                               (mv contra interp-st)))
             ((when contra)
              (gl-interp-error
               :msg (gl-msg "A contradiction has been noted in the ~
                             constraints.  This is likely due to a bug in GL ~
                             or an unsound fact stored in ACL2 (e.g., via ~
                             TTAG, skip-proofs, defaxiom, or soundness bug). ~
                             The constraint instance that led to the ~
                             contradiction is stored in the state global (~x0 ~
                             ~x1), but note that a previous constraint ~
                             instance might have caused the unsoundness."
                            '@ 'gl-interp-error-debug-obj)
               :debug-obj sub1
               :nvals 0)))
          (gl-interp-add-constraints-for-substs rest interp-st state)))
      

      (define gl-interp-merge-branches ((testbfr interp-st-bfr-p)
                                        (thenval gl-object-p)
                                        (elseval gl-object-p)
                                        (interp-st interp-st-bfrs-ok)
                                        state)
        :guard (and (interp-st-bfr-listp (gl-object-bfrlist thenval))
                    (interp-st-bfr-listp (gl-object-bfrlist elseval)))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       2000 0 0)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* ((thenval (gl-object-fix thenval))
             (elseval (gl-object-fix elseval))
             ((when (eq testbfr t)) (mv thenval interp-st state))
             ((when (eq testbfr nil)) (mv elseval interp-st state))
             ((when (hons-equal thenval elseval)) (mv thenval interp-st state)))
          (gl-interp-merge-branches-rewrite testbfr thenval elseval nil interp-st state)))

      (define gl-interp-merge-branches-rewrite ((testbfr interp-st-bfr-p)
                                                (thenval gl-object-p)
                                                (elseval gl-object-p)
                                                switchedp
                                                (interp-st interp-st-bfrs-ok)
                                                state)
        :guard (and (interp-st-bfr-listp (gl-object-bfrlist thenval))
                    (interp-st-bfr-listp (gl-object-bfrlist elseval)))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       1900 0 (if switchedp 20 30))
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* ((thenval (gl-object-fix thenval))
             (elseval (gl-object-fix elseval))
             (fn (gl-fncall-object->fn thenval))
             (rules (and** fn (fn-branch-merge-rules fn 
                                                     (glcp-config->branch-merge-rules
                                                      (interp-st->config interp-st))
                                                     (w state))))
             ((unless rules)
              ;; Note: we try to apply if-merge rules based on the leading function
              ;; symbol of the then or else objects.  We try then first
              ;; (switchedp=nil), then else (switchedp=t), and if both fail we move
              ;; on to merge-branches-subterms.
              (if switchedp
                  (gl-interp-merge-branch-subterms
                   (interp-st-bfr-not testbfr)
                   elseval thenval interp-st state)
                (gl-interp-merge-branches-rewrite
                 (interp-st-bfr-not testbfr)
                 elseval thenval t interp-st state)))

             (reclimit (interp-st->reclimit interp-st))
             ((when (gl-interp-check-reclimit interp-st))
              (gl-interp-error :msg (gl-msg "The recursion limit ran out.")))
             (interp-st (interp-st-push-scratch-gl-obj elseval interp-st))
             (interp-st (interp-st-push-scratch-gl-obj thenval interp-st))
             (interp-st (interp-st-push-scratch-bfr testbfr interp-st))
             (interp-st (interp-st-push-scratch-gl-objlist
                         (list (g-boolean testbfr) thenval elseval)
                         interp-st))
             ((interp-st-bind
               (reclimit (1- reclimit) reclimit))
              ((mv successp ans interp-st state)
               (gl-rewrite-try-rules rules 'if interp-st state)))
             (interp-st (interp-st-pop-scratch interp-st))
             ((mv testbfr interp-st) (interp-st-pop-scratch-bfr interp-st))
             ((mv thenval interp-st) (interp-st-pop-scratch-gl-obj interp-st))
             ((mv elseval interp-st) (interp-st-pop-scratch-gl-obj interp-st))
             ;; ((when err)
             ;;  (mv nil interp-st state))
             ((when successp)
              (mv ans interp-st state)))
          (if switchedp
              (gl-interp-merge-branch-subterms
               (interp-st-bfr-not testbfr)
               elseval thenval interp-st state)
            (gl-interp-merge-branches-rewrite
             (interp-st-bfr-not testbfr)
             elseval thenval t interp-st state))))

      (define gl-interp-merge-branch-subterms ((testbfr interp-st-bfr-p)
                                               (thenval gl-object-p)
                                               (elseval gl-object-p)
                                               (interp-st interp-st-bfrs-ok)
                                               state)
        :guard (and (interp-st-bfr-listp (gl-object-bfrlist thenval))
                    (interp-st-bfr-listp (gl-object-bfrlist elseval)))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       1800 0 0)
        :returns (mv
                  (ans gl-object-p)
                  new-interp-st
                  new-state)
        (b* (((mv thenfn thenargs) (gl-object-recognize-merge-fncall thenval))
             ((mv elsefn elseargs) (gl-object-recognize-merge-fncall elseval))
             ((unless (and** thenfn
                             (eq thenfn elsefn)
                             (eql (len thenargs) (len elseargs))))
              (stobj-let ((logicman (interp-st->logicman interp-st)))
                         (obj logicman)
                         (gl-object-basic-merge testbfr thenval elseval)
                         (mv obj interp-st state)))
             ;; BOZO sad:
             (reclimit (interp-st->reclimit interp-st))
             ((when (gl-interp-check-reclimit interp-st))
              (gl-interp-error :msg (gl-msg "The recursion limit ran out.")))

             ;; (scratch (interp-st-scratch interp-st))
             ;; (thenval-stack (interp-st->thenval-stack interp-st))
             ;; (elseval-stack (interp-st->elseval-stack interp-st))
             ;; (interp-st (update-interp-st->thenval-stack (append thenargs thenval-stack) interp-st))
             ;; (interp-st (update-interp-st->elseval-stack (append elseargs elseval-stack) interp-st))
             ;; (interp-st (interp-st-push-bool-scratch testbfr interp-st))
             ;; ;; pops args off thenval/elseval-stack, pushes onto scratch

             
             ((interp-st-bind
               (reclimit (1- reclimit) reclimit))
              ((gl-interp-recursive-call args interp-st state)
               (gl-interp-merge-branch-args testbfr thenargs elseargs interp-st state)))

             ;; ((when err)
             ;;  ;; pop off any args pushed on before error
             ;;  (b* (;; (interp-st (interp-st-pop-scratch (- (len (interp-st-scratch interp-st))
             ;;       ;;                                      (len scratch))
             ;;       ;;                                   interp-st))
             ;;       ;; (new-thenval-stack (interp-st->thenval-stack interp-st))
             ;;       ;; (interp-st (update-interp-st->thenval-stack
             ;;       ;;             (nthcdr (- (len new-thenval-stack)
             ;;       ;;                        (len thenval-stack))
             ;;       ;;                     new-thenval-stack)
             ;;       ;;             interp-st))
             ;;       ;; (new-elseval-stack (interp-st->elseval-stack interp-st))
             ;;       ;; (interp-st (update-interp-st->elseval-stack
             ;;       ;;             (nthcdr (- (len new-elseval-stack)
             ;;       ;;                        (len elseval-stack))
             ;;       ;;                     new-elseval-stack)
             ;;       ;;             interp-st))
             ;;       )
             ;;    (mv nil interp-st state)))
             )
          (gl-interp-fncall thenfn args interp-st state)))

      (define gl-interp-merge-branch-args ((testbfr interp-st-bfr-p)
                                           (thenargs gl-objectlist-p)
                                           (elseargs gl-objectlist-p)
                                           (interp-st interp-st-bfrs-ok)
                                           state)
        :guard (and (eql (len thenargs) (len elseargs))
                    (interp-st-bfr-listp (gl-objectlist-bfrlist thenargs))
                    (interp-st-bfr-listp (gl-objectlist-bfrlist elseargs)))
        :measure (list (nfix (interp-st->reclimit interp-st))
                       3000 (len thenargs) 0)
        :returns (mv
                  (args gl-objectlist-p)
                  new-interp-st
                  new-state)
        (b* (((when (atom thenargs))
              (mv nil interp-st state))
             ;; (thenstack (interp-st->thenval-stack interp-st))
             ;; (thenval (car thenstack))
             ;; (interp-st (update-interp-st->thenval-stack (cdr thenstack) interp-st))
             ;; (elsestack (interp-st->elseval-stack interp-st))
             ;; (elseval (car elsestack))
             ;; (interp-st (update-interp-st->elseval-stack (cdr elsestack) interp-st))
             (interp-st (interp-st-push-scratch-gl-objlist (cdr thenargs) interp-st))
             (interp-st (interp-st-push-scratch-gl-objlist (cdr elseargs) interp-st))
             (interp-st (interp-st-push-scratch-bfr testbfr interp-st))
             ((gl-interp-recursive-call ans interp-st state)
              (gl-interp-merge-branches testbfr (car thenargs) (car elseargs) interp-st state))
             ((mv testbfr interp-st) (interp-st-pop-scratch-bfr interp-st))
             ((mv rest-elseargs interp-st) (interp-st-pop-scratch-gl-objlist interp-st))
             ((mv rest-thenargs interp-st) (interp-st-pop-scratch-gl-objlist interp-st))
             
             ((unless (mbt (eql (len (cdr thenargs)) (len rest-thenargs))))
              (mv nil interp-st state))
             ;; ((when err)
             ;;  (mv nil interp-st state))
             (interp-st (interp-st-push-scratch-gl-obj ans interp-st))
             ((mv args interp-st state)
              (gl-interp-merge-branch-args testbfr rest-thenargs rest-elseargs interp-st state))
             ((mv arg1 interp-st) (interp-st-pop-scratch-gl-obj interp-st)))
          (mv (cons arg1 args) interp-st state))))))


(local (defun find-flag-is-hyp (clause)
         (if (atom clause)
             nil
           (let ((lit (car clause)))
             (case-match lit
               (('not ('acl2::flag-is ('quote val))) val)
               (& (find-flag-is-hyp (cdr clause))))))))


(defsection stack-isomorphic-of-gl-interp

  (define scratchobj-isomorphic ((x scratchobj-p) (y scratchobj-p))
    (and (eq (scratchobj-kind x) (scratchobj-kind y))
         (scratchobj-case x
           :gl-objlist (eql (len x.val) (len (scratchobj-gl-objlist->val y)))
           :bfrlist (eql (len x.val) (len (scratchobj-bfrlist->val y)))
           :cinstlist (eql (len x.val) (len (scratchobj-cinstlist->val y)))
           :otherwise t))
    ///
    (defequiv scratchobj-isomorphic)

    (defcong scratchobj-isomorphic equal (scratchobj-kind x) 1)

    (defthm len-gl-objlist-when-scratchobj-isomorphic
      (implies (and (scratchobj-isomorphic x y)
                    (scratchobj-case x :gl-objlist))
               (= (len (scratchobj-gl-objlist->val x))
                  (len (scratchobj-gl-objlist->val y))))
      :rule-classes :linear)

    (defthm len-bfrlist-when-scratchobj-isomorphic
      (implies (and (scratchobj-isomorphic x y)
                    (scratchobj-case x :bfrlist))
               (= (len (scratchobj-bfrlist->val x))
                  (len (scratchobj-bfrlist->val y))))
      :rule-classes :linear)

    (defthm len-cinstlist-when-scratchobj-isomorphic
      (implies (and (scratchobj-isomorphic x y)
                    (scratchobj-case x :cinstlist))
               (= (len (scratchobj-cinstlist->val x))
                  (len (scratchobj-cinstlist->val y))))
      :rule-classes :linear))

  (define scratchlist-isomorphic ((x scratchlist-p) (y scratchlist-p))
    (if (atom x)
        (atom y)
      (and (consp y)
           (scratchobj-isomorphic (car x) (car y))
           (scratchlist-isomorphic (cdr x) (cdr y))))
    ///
    (defequiv scratchlist-isomorphic)

    (defcong scratchlist-isomorphic scratchobj-isomorphic (car x) 1
      :hints(("Goal" :in-theory (enable default-car))))
    (defcong scratchlist-isomorphic scratchlist-isomorphic (cdr x) 1)
    
    (defcong scratchobj-isomorphic scratchlist-isomorphic (cons x y) 1)
    (defcong scratchlist-isomorphic scratchlist-isomorphic (cons x y) 2)

    (defcong scratchlist-isomorphic equal (len x) 1
      :hints(("Goal" :in-theory (enable len)))))

  (define minor-frame-scratch-isomorphic ((x minor-frame-p) (y minor-frame-p))
    (scratchlist-isomorphic (minor-frame->scratch x) (minor-frame->scratch y))
    ///
    (defequiv minor-frame-scratch-isomorphic)

    (defcong minor-frame-scratch-isomorphic scratchlist-isomorphic (minor-frame->scratch x) 1)

    (defcong scratchlist-isomorphic minor-frame-scratch-isomorphic (minor-frame bindings scratch debug) 2)

    (defthm minor-frame-scratch-isomorphic-normalize-minor-frame
      (implies (syntaxp (not (and (Equal bindings ''nil)
                                  (equal debug ''nil))))
               (minor-frame-scratch-isomorphic (minor-frame bindings scratch debug)
                                               (minor-frame nil scratch nil)))))

  (define minor-stack-scratch-isomorphic ((x minor-stack-p) (y minor-stack-p))
    (and (minor-frame-scratch-isomorphic (car x) (car y))
         (if (atom (cdr x))
             (atom (cdr y))
           (and (consp (cdr y))
                (minor-stack-scratch-isomorphic (cdr x) (cdr y)))))
    ///
    (defequiv minor-stack-scratch-isomorphic)

    (defcong minor-stack-scratch-isomorphic minor-frame-scratch-isomorphic (car x) 1
      :hints(("Goal" :in-theory (enable default-car))))
    (defcong minor-stack-scratch-isomorphic minor-stack-scratch-isomorphic (cdr x) 1
      :hints(("Goal" :in-theory (enable default-car))))
    
    (defcong minor-frame-scratch-isomorphic minor-stack-scratch-isomorphic (cons x y) 1)

    (defthm minor-stack-scratch-isomorphic-cons-cdr-congruence
      (implies (minor-stack-scratch-isomorphic x y)
               (minor-stack-scratch-isomorphic (cons frame (cdr x))
                                               (cons frame (cdr y))))
      :rule-classes :congruence)

    (defcong minor-stack-scratch-isomorphic acl2::pos-equiv (len x) 1
      :hints(("Goal" :in-theory (enable len pos-fix)))))


  (define major-frame-scratch-isomorphic ((x major-frame-p) (y major-frame-p))
    (minor-stack-scratch-isomorphic (major-frame->minor-stack x) (major-frame->minor-stack y))
    ///
    (defequiv major-frame-scratch-isomorphic)

    (defcong major-frame-scratch-isomorphic minor-stack-scratch-isomorphic (major-frame->minor-stack x) 1)

    (defcong minor-stack-scratch-isomorphic major-frame-scratch-isomorphic (major-frame bindings debug minor-stack) 3)

    (defthm major-frame-scratch-isomorphic-normalize-major-frame
      (implies (syntaxp (not (and (Equal bindings ''nil)
                                  (equal debug ''nil))))
               (major-frame-scratch-isomorphic (major-frame bindings debug minor-stack)
                                               (major-frame nil nil minor-stack)))))

  (define major-stack-scratch-isomorphic ((x major-stack-p) (y major-stack-p))
    (and (major-frame-scratch-isomorphic (car x) (car y))
         (if (atom (cdr x))
             (atom (cdr y))
           (and (consp (cdr y))
                (major-stack-scratch-isomorphic (cdr x) (cdr y)))))
    ///
    (defequiv major-stack-scratch-isomorphic)

    (defcong major-stack-scratch-isomorphic major-frame-scratch-isomorphic (car x) 1
      :hints(("Goal" :in-theory (enable default-car))))
    (defcong major-stack-scratch-isomorphic major-stack-scratch-isomorphic (cdr x) 1
      :hints(("Goal" :in-theory (enable default-car))))
    
    (defcong major-frame-scratch-isomorphic major-stack-scratch-isomorphic (cons x y) 1)

    (defthm major-stack-scratch-isomorphic-cons-cdr-congruence
      (implies (major-stack-scratch-isomorphic x y)
               (major-stack-scratch-isomorphic (cons frame (cdr x))
                                               (cons frame (cdr y))))
      :rule-classes :congruence)

    (defcong major-stack-scratch-isomorphic acl2::pos-equiv (len x) 1
      :hints(("Goal" :in-theory (enable len pos-fix)))))


  (define interp-st-scratch-isomorphic (x y)
    :non-executable t
    :verify-guards nil
    (major-stack-scratch-isomorphic (interp-st->stack x) (interp-st->stack y))
    ///
    (defequiv interp-st-scratch-isomorphic)

    (defcong interp-st-scratch-isomorphic major-stack-scratch-isomorphic (interp-st->stack x) 1)

    (defcong major-stack-scratch-isomorphic interp-st-scratch-isomorphic (update-interp-st->stack stack x) 1)

    (defthm update-interp-st->stack-norm-under-interp-st-scratch-isomorphic
      (implies (syntaxp (not (equal x ''nil)))
               (interp-st-scratch-isomorphic
                (update-interp-st->stack stack x)
                (update-interp-st->stack stack nil))))

    (defthm interp-st-scratch-isomorphic-of-update-interp-st->stack-identity
      (interp-st-scratch-isomorphic
       (update-interp-st->stack (major-stack-fix (interp-st->stack interp-st)) x)
       interp-st))

    (defthm interp-st-scratch-isomorphic-of-update-interp-st->stack-identity2
      (interp-st-scratch-isomorphic
       (update-interp-st->stack (interp-st->stack interp-st) x)
       interp-st))

    (def-updater-independence-thm interp-st-scratch-isomorphic-identity
      (implies (major-stack-equiv (interp-st->stack new) (interp-st->stack old))
               (equal (interp-st-scratch-isomorphic new x)
                      (interp-st-scratch-isomorphic old x)))))
  

  (defcong major-stack-scratch-isomorphic
    major-stack-scratch-isomorphic (stack$a-pop-scratch stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-scratch))))

  (defcong major-stack-scratch-isomorphic
    major-stack-scratch-isomorphic (stack$a-pop-frame stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-frame))))

  (defcong major-stack-scratch-isomorphic
    major-stack-scratch-isomorphic (stack$a-pop-minor-frame stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame))))

  (defcong major-stack-scratch-isomorphic
    major-stack-scratch-isomorphic (stack$a-set-bindings bindings stack) 2
    :hints(("Goal" :in-theory (enable stack$a-set-bindings))))

  (defcong scratchlist-isomorphic scratchlist-isomorphic (update-nth n obj x) 3
    :hints(("Goal" :in-theory (enable update-nth))))

  (defcong major-stack-scratch-isomorphic
    major-stack-scratch-isomorphic (stack$a-update-scratch n obj stack) 3
    :hints(("Goal" :in-theory (enable stack$a-update-scratch))))

  (defthm stack$a-pop-scratch-of-stack$a-push-scratch
    (equal (stack$a-pop-scratch (stack$a-push-scratch obj stack))
           (major-stack-fix stack))
    :hints(("Goal" :in-theory (enable stack$a-push-scratch stack$a-pop-scratch default-car)
            :expand ((major-stack-fix stack)))))


  (defthm stack$a-pop-frame-of-stack$a-set-bindings
    (equal (stack$a-pop-frame (stack$a-set-bindings bindings stack))
           (stack$a-pop-frame stack))
    :hints(("Goal" :in-theory (enable stack$a-pop-frame stack$a-set-bindings))))

  (defthm stack$a-pop-frame-of-stack$a-set-debug
    (equal (stack$a-pop-frame (stack$a-set-debug obj stack))
           (stack$a-pop-frame stack))
    :hints(("Goal" :in-theory (enable stack$a-pop-frame stack$a-set-debug))))

  (defthm stack$a-pop-frame-of-stack$a-push-frame
    (equal (stack$a-pop-frame (stack$a-push-frame stack))
           (major-stack-fix stack))
    :hints(("Goal" :in-theory (enable stack$a-pop-frame stack$a-push-frame))))

  (defthm stack$a-pop-minor-frame-of-stack$a-set-minor-bindings
    (equal (stack$a-pop-minor-frame (stack$a-set-minor-bindings bindings stack))
           (stack$a-pop-minor-frame stack))
    :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame stack$a-set-minor-bindings))))

  (defthm stack$a-pop-minor-frame-of-stack$a-set-minor-debug
    (equal (stack$a-pop-minor-frame (stack$a-set-minor-debug obj stack))
           (stack$a-pop-minor-frame stack))
    :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame stack$a-set-minor-debug))))

  (defthm stack$a-pop-minor-frame-of-stack$a-push-minor-frame
    (equal (stack$a-pop-minor-frame (stack$a-push-minor-frame stack))
           (major-stack-fix stack))
    :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame stack$a-push-minor-frame
                                      major-stack-fix default-car))))


  (defthm major-stack-scratch-isomorphic-of-add-binding
    (major-stack-scratch-isomorphic (stack$a-add-binding var val stack) stack)
    :hints(("Goal" :in-theory (enable stack$a-add-binding major-stack-scratch-isomorphic
                                      major-frame-scratch-isomorphic))))

  (defthm major-stack-scratch-isomorphic-of-set-bindings
    (major-stack-scratch-isomorphic (stack$a-set-bindings bindings stack) stack)
    :hints(("Goal" :in-theory (enable stack$a-set-bindings major-stack-scratch-isomorphic
                                      major-frame-scratch-isomorphic))))

  (defthm major-stack-scratch-isomorphic-of-add-minor-bindings
    (major-stack-scratch-isomorphic (stack$a-add-minor-bindings bindings stack) stack)
    :hints(("Goal" :in-theory (enable stack$a-add-minor-bindings
                                      major-stack-scratch-isomorphic
                                      major-frame-scratch-isomorphic
                                      minor-stack-scratch-isomorphic
                                      minor-frame-scratch-isomorphic))))

  (defret major-stack-scratch-isomorphic-of-syntax-bind
    (interp-st-scratch-isomorphic new-interp-st interp-st)
    :hints(("Goal" :in-theory (enable gl-interp-syntax-bind)))
    :fn gl-interp-syntax-bind)

  (defret major-stack-scratch-isomorphic-of-relieve-hyp-synp
    (interp-st-scratch-isomorphic new-interp-st
      interp-st)
    :hints(("Goal" :in-theory (enable gl-rewrite-relieve-hyp-synp)))
    :fn gl-rewrite-relieve-hyp-synp)
  
  (defthm major-stack-scratch-isomorphic-of-gl-primitive-fncall
    (interp-st-scratch-isomorphic
     (mv-nth 2 (gl-primitive-fncall fn args dont interp-st state))
     interp-st)
    :hints(("Goal" :in-theory (enable gl-primitive-fncall
                                      gl-int-primitive
                                      gl-intcons-primitive
                                      gl-endint-primitive
                                      gl-intcar-primitive
                                      gl-intcdr-primitive
                                      gl-bool-primitive))))


  (defthmd stack$a-update-scratch-in-terms-of-push-pop
    (implies (syntaxp (quotep n))
             (equal (stack$a-update-scratch n obj stack)
                    (if (zp n)
                        (stack$a-push-scratch obj (stack$a-pop-scratch stack))
                      (stack$a-push-scratch (stack$a-top-scratch stack)
                                            (stack$a-update-scratch
                                             (1- n) obj (stack$a-pop-scratch stack))))))
    :hints(("Goal" :in-theory (enable stack$a-update-scratch
                                      stack$a-push-scratch
                                      stack$a-pop-scratch
                                      stack$a-top-scratch))))

  (encapsulate nil
    (local (in-theory (enable stack$a-update-scratch-in-terms-of-push-pop)))
    (with-output
      :off (event)
      :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
      (std::defret-mutual-generate interp-st-scratch-isomorphic-of-<fn>
        :return-concls ((new-interp-st               (interp-st-scratch-isomorphic new-interp-st
                                                                                   (double-rewrite interp-st))))
        :rules ((t (:add-keyword :hints ('(:do-not-induct t)
                                         (let ((flag (find-flag-is-hyp clause)))
                                           (and flag
                                                (prog2$ (cw "flag: ~x0~%" flag)
                                                        '(:no-op t))))))))
        :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world))))))



(local
 (defthm major-stack-bfrlist-of-atom
   (implies (atom x)
            (equal (major-stack-bfrlist x) nil))
   :hints(("Goal" :in-theory (enable major-stack-bfrlist
                                     default-car)))
   :rule-classes ((:rewrite :backchain-limit-lst 0))))

(local
 (defthm major-stack-bfrlist-of-stack$a-push-scratch
   (set-equiv (major-stack-bfrlist (stack$a-push-scratch obj stack))
              (append (scratchobj->bfrlist obj)
                      (major-stack-bfrlist stack)))
   :hints(("Goal" :in-theory (enable ;; major-stack-bfrlist
                                     major-frame-bfrlist
                                     ;; minor-stack-bfrlist
                                      minor-frame-bfrlist
                                     stack$a-push-scratch
                                     ;; acl2::set-unequal-witness-rw
                                     )
           :expand ((major-stack-bfrlist stack)
                    (minor-stack-bfrlist (major-frame->minor-stack (car stack))))
           :do-not-induct t))))

(local
 (defthm scratchlist-bfrlist-of-update-nth
   (implies (and (not (member v (scratchobj->bfrlist obj)))
                 (not (member v (scratchlist-bfrlist x))))
            (not (member v (scratchlist-bfrlist (update-nth n obj x)))))
   :hints(("Goal" :in-theory (enable update-nth)))))

(local
 (defthm bfrlist-of-stack$a-update-scratch
   (implies (and (not (member v (scratchobj->bfrlist obj)))
                 (not (member v (major-stack-bfrlist stack))))
            (not (member v (major-stack-bfrlist (stack$a-update-scratch n obj stack)))))
   :hints(("Goal" :in-theory (enable ;; major-stack-bfrlist
                                     major-frame-bfrlist
                                     ;; minor-stack-bfrlist
                                      minor-frame-bfrlist
                                     stack$a-update-scratch
                                     ;; acl2::set-unequal-witness-rw
                                     )
           :expand ((major-stack-bfrlist stack)
                    (minor-stack-bfrlist (major-frame->minor-stack (car stack))))
           :do-not-induct t))))


(local (defthm gl-objectlist-bfrlist-of-append
         (equal (gl-objectlist-bfrlist (append x y))
                (append (gl-objectlist-bfrlist x)
                        (gl-objectlist-bfrlist y)))
         :hints(("Goal" :in-theory (enable gl-objectlist-bfrlist append)))))

(local (defthm member-nthcdr
         (implies (not (member v x))
                  (not (member v (nthcdr n x))))))



(local (defthm member-gl-objectlist-bfrlist-of-nthcdr
         (implies (not (member v (gl-objectlist-bfrlist x)))
                  (not (member v (gl-objectlist-bfrlist (nthcdr n x)))))
         :hints(("Goal" :in-theory (enable nthcdr)))))

(local
 (defthm major-stack-bfrlist-of-stack$a-pop-scratch
   (implies (not (member v (major-stack-bfrlist stack)))
            (not (member v (major-stack-bfrlist (stack$a-pop-scratch stack)))))
   :hints(("Goal" :in-theory (enable stack$a-pop-scratch
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist)
           :expand ((major-stack-bfrlist stack)
                    (minor-stack-bfrlist (major-frame->minor-stack (car stack))))
           :do-not-induct t))))

(local
 (defthm major-stack-bfrlist-of-stack$a-set-bindings
   (implies (and (not (member v (major-stack-bfrlist stack)))
                 (not (member v (gl-object-alist-bfrlist bindings))))
            (not (member v (major-stack-bfrlist (stack$a-set-bindings bindings stack)))))
   :hints(("Goal" :in-theory (enable stack$a-set-bindings
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist)
           :do-not-induct t))))

(local
 (defthm major-stack-bfrlist-of-stack$a-set-minor-bindings
   (implies (and (not (member v (major-stack-bfrlist stack)))
                 (not (member v (gl-object-alist-bfrlist bindings))))
            (not (member v (major-stack-bfrlist (stack$a-set-minor-bindings bindings stack)))))
   :hints(("Goal" :in-theory (enable stack$a-set-minor-bindings
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist)
           :expand ((major-stack-bfrlist stack)
                    (minor-stack-bfrlist (major-frame->minor-stack (car stack))))
           :do-not-induct t))))

(local
 (defthm major-stack-bfrlist-of-stack$a-add-minor-bindings
   (set-equiv (major-stack-bfrlist (stack$a-add-minor-bindings bindings stack))
              (append (gl-object-alist-bfrlist bindings)
                      (major-stack-bfrlist stack)))
   :hints(("Goal" :in-theory (enable stack$a-add-minor-bindings
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist)
           :do-not-induct t))))

(local
 (defthm major-stack-bfrlist-of-stack$a-push-frame
   (equal (major-stack-bfrlist (stack$a-push-frame stack))
          (major-stack-bfrlist stack))
   :hints(("Goal" :in-theory (enable stack$a-push-frame
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist)
           :do-not-induct t))))

(local
 (defthm major-stack-bfrlist-of-stack$a-push-minor-frame
   (equal (major-stack-bfrlist (stack$a-push-minor-frame stack))
          (major-stack-bfrlist stack))
   :hints(("Goal" :in-theory (enable stack$a-push-minor-frame
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist)
           :do-not-induct t))))

(local
 (defthm major-stack-bfrlist-of-stack$a-pop-frame
   (implies (not (member v (major-stack-bfrlist stack)))
            (not (member v (major-stack-bfrlist (stack$a-pop-frame stack)))))
   :hints(("Goal" :in-theory (enable stack$a-pop-frame
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist
                                     default-car)
           :do-not-induct t))))

(local
 (defthm major-stack-bfrlist-of-stack$a-pop-minor-frame
   (implies (not (member v (major-stack-bfrlist stack)))
            (not (member v (major-stack-bfrlist (stack$a-pop-minor-frame stack)))))
   :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-frame-bfrlist
                                     minor-stack-bfrlist
                                     default-car)
           :do-not-induct t))))

(local
   (defthm gl-object-alist-bfrlist-of-stack$a-bindings
     (implies (not (member v (major-stack-bfrlist stack)))
              (not (member v (gl-object-alist-bfrlist (stack$a-bindings stack)))))
     :hints(("Goal" :in-theory (enable stack$a-bindings
                                       major-frame-bfrlist)
             :expand ((major-stack-bfrlist stack))
             :do-not-induct t))))

(local
 (defthm gl-object-alist-bfrlist-of-stack$a-minor-bindings
   (implies (not (member v (major-stack-bfrlist stack)))
            (not (member v (gl-object-alist-bfrlist (stack$a-minor-bindings stack)))))
   :hints(("Goal" :in-theory (enable stack$a-minor-bindings
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-stack-bfrlist
                                     minor-frame-bfrlist)
           :expand ((major-stack-bfrlist stack)
                    (minor-stack-bfrlist (major-frame->minor-stack (car stack))))
           :do-not-induct t))))


(local
 (defthm scratchobj->bfrlist-of-stack$a-top-scratch
     (implies (not (member v (major-stack-bfrlist stack)))
              (not (member v (scratchobj->bfrlist (stack$a-top-scratch stack)))))
     :hints(("Goal" :in-theory (enable stack$a-top-scratch
                                       major-frame-bfrlist
                                       minor-frame-bfrlist)
             :expand ((major-stack-bfrlist stack)
                      (minor-stack-bfrlist (major-frame->minor-stack (car stack))))
             :do-not-induct t))))



(local
 (defthm major-stack-bfrlist-of-stack$a-set-debug
   (equal (major-stack-bfrlist (stack$a-set-debug obj stack))
          (major-stack-bfrlist stack))
   :hints(("Goal" :in-theory (enable stack$a-set-debug
                                     major-stack-bfrlist
                                     major-frame-bfrlist)))))

(local
 (defthm major-stack-bfrlist-of-stack$a-set-minor-debug
   (equal (major-stack-bfrlist (stack$a-set-minor-debug obj stack))
          (major-stack-bfrlist stack))
   :hints(("Goal" :in-theory (enable stack$a-set-minor-debug
                                     major-stack-bfrlist
                                     major-frame-bfrlist
                                     minor-stack-bfrlist
                                     minor-frame-bfrlist))))) 


(local (defthm bfr-listp-of-gl-objectlist-bfrlist-cdr
         (implies (bfr-listp (gl-objectlist-bfrlist x))
                  (bfr-listp (gl-objectlist-bfrlist (cdr x))))
         :hints(("Goal" :in-theory (enable gl-objectlist-bfrlist)))))

(local (defthm bfr-listp-of-gl-objectlist-bfrlist-nthcdr
         (implies (bfr-listp (gl-objectlist-bfrlist x))
                  (bfr-listp (gl-objectlist-bfrlist (nthcdr n x))))
         :hints(("Goal" :in-theory (enable nthcdr)))))

(local (defthm bfr-listp-of-gl-object-bfrlist-car
         (implies (bfr-listp (gl-objectlist-bfrlist x))
                  (bfr-listp (gl-object-bfrlist (car x))))
         :hints(("Goal" :expand ((gl-objectlist-bfrlist x))
                 :in-theory (enable default-car)))))

(local (defthm bfr-listp-of-gl-objectlist-bfrlist-take
         (implies (bfr-listp (gl-objectlist-bfrlist x))
                  (bfr-listp (gl-objectlist-bfrlist (take n x))))
         :hints(("Goal" :in-theory (enable acl2::take-redefinition)))))

(local (defthm gl-objectlist-bfrlist-of-rev
         (set-equiv (gl-objectlist-bfrlist (rev x))
                          (gl-objectlist-bfrlist x))
         :hints(("Goal" :in-theory (enable rev gl-objectlist-bfrlist)))))

(local (defthm bfr-listp-of-constraint-instancelist-bfrlist-cdr
         (implies (bfr-listp (constraint-instancelist-bfrlist x))
                  (bfr-listp (constraint-instancelist-bfrlist (cdr x))))
         :hints(("Goal" :expand ((constraint-instancelist-bfrlist x))
                 :in-theory (enable default-cdr)))))

(local (defthm bfr-listp-of-constraint-instancelist-bfrlist-car
         (implies (bfr-listp (constraint-instancelist-bfrlist x))
                  (bfr-listp (constraint-instance-bfrlist (car x))))
         :hints(("Goal" :expand ((constraint-instancelist-bfrlist x))
                 :in-theory (enable default-car)))))

(local (defthm gl-object-alist-bfrlist-of-constraint-instance->subst
         (equal (gl-object-alist-bfrlist (constraint-instance->subst x))
                (constraint-instance-bfrlist x))
         :hints(("Goal" :expand ((constraint-instance-bfrlist x))))))

(local (defthm bfr-p-car-of-bfr-list
         (implies (bfr-listp x)
                  (bfr-p (car x)))
         :hints(("Goal" :in-theory (enable default-car bfr-listp)))))


;; (local (in-theory (disable bfr-listp-of-gl-objectlist-bfrlist
;;                            bfr-listp-of-gl-object-bfrlist)))

(defthm update-interp-st->stack-of-update-interp-st->stack
  (equal (update-interp-st->stack x (update-interp-st->stack x1 interp-st))
         (update-interp-st->stack x interp-st))
  :hints(("Goal" :in-theory (enable update-interp-st->stack))))

(local (in-theory (enable bfr-listp-when-not-member-witness)))

(defthm bfr-p-of-g-boolean->bool-when-bfr-listp
  (implies (and (gl-object-case x :g-boolean)
                (bfr-listp (gl-object-bfrlist x)))
           (b* (((g-boolean x)))
             (bfr-p x.bool)))
  :hints(("Goal" :in-theory (enable gl-object-bfrlist))))

(defthm bfr-p-of-bool-fix
  (bfr-p (bool-fix x))
  :hints(("Goal" :in-theory (enable bfr-p aig-p acl2::ubddp))))


(local (in-theory (disable member-equal)))



(encapsulate nil
  (local (defthm pseudo-var-listp-when-nonnil-symbol-listp
           (implies (and (symbol-listp x)
                         (not (member nil x)))
                    (pseudo-var-list-p x))
           :hints(("Goal" :in-theory (enable member)))))
  
  (defthm pseudo-var-listp-of-fn-get-def-formals
    (pseudo-var-list-p (mv-nth 1 (acl2::fn-get-def fn state)))
    :hints(("Goal" :in-theory (enable acl2::fn-get-def)))))

(defthm gl-object-alist-bfrlist-of-pairlis$
  (implies (and (pseudo-var-list-p vars)
                (equal (len vars) (len vals)))
           (equal (gl-object-alist-bfrlist (pairlis$ vars vals))
                  (gl-objectlist-bfrlist vals)))
  :hints(("Goal" :in-theory (enable gl-objectlist-bfrlist gl-object-alist-bfrlist pairlis$
                                    pseudo-var-list-p len))))


(defcong major-stack-scratch-isomorphic
  scratchobj-isomorphic
  (stack$a-top-scratch stack) 1
  :hints(("Goal" :in-theory (enable stack$a-top-scratch))))

(defthm stack$a-top-scratch-of-stack$a-push-scratch
  (equal (stack$a-top-scratch (stack$a-push-scratch obj stack))
         (scratchobj-fix obj))
  :hints(("Goal" :in-theory (enable stack$a-push-scratch stack$a-top-scratch))))

(local (defthm bfr-p-of-scratchobj-bfr->val
         (implies (double-rewrite (scratchobj-case x :bfr))
                  (equal (bfr-p (scratchobj-bfr->val x))
                         (bfr-listp (scratchobj->bfrlist x))))
         :hints(("Goal" :in-theory (enable scratchobj->bfrlist)))))


(local
 (encapsulate nil
   
   (local (include-book "scratchobj"))

   (make-event
    (cons 'progn
          (acl2::template-proj
           '(defthm bfrlist-of-scratchobj-<kind>->val-double-rewrite
              (implies (double-rewrite (scratchobj-case x :<kind>))
                       (equal (<prefix>-bfrlist (scratchobj-<kind>->val x))
                              (scratchobj->bfrlist x))))
           (scratchobj-tmplsubsts (acl2::remove-assoc
                                   :bfr (acl2::remove-assoc :bfrlist *scratchobj-types*))))))))




(defcong interp-st-scratch-isomorphic interp-st-scratch-isomorphic
  (update-interp-st->reclimit reclimit interp-st) 2
  :hints(("Goal" :in-theory (enable interp-st-scratch-isomorphic))))

(Defcong major-stack-scratch-isomorphic major-stack-scratch-isomorphic
  (stack$a-push-scratch obj stack) 2
  :hints(("Goal" :in-theory (enable stack$a-push-scratch))))

(Defcong major-stack-scratch-isomorphic major-stack-scratch-isomorphic
  (stack$a-pop-scratch stack) 1
  :hints(("Goal" :in-theory (enable stack$a-pop-scratch))))

(defthm major-stack-scratch-isomorphic-of-gl-primitive-fncall-double
    (interp-st-scratch-isomorphic
     (mv-nth 2 (gl-primitive-fncall fn args dont interp-st state))
     (Double-rewrite interp-st))
    :hints(("Goal" :in-theory (enable gl-primitive-fncall
                                      gl-int-primitive
                                      gl-intcons-primitive
                                      gl-endint-primitive
                                      gl-intcar-primitive
                                      gl-intcdr-primitive
                                      gl-bool-primitive))))

(with-output
  :off (event)
  :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
  (std::defret-mutual len-of-gl-interp-arglist
    (defret len-of-gl-interp-arglist
      (equal (len arg-objs) (len args))
      :fn gl-interp-arglist)
    :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world))
    :skip-others t))

(with-output
  :off (event)
  :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
  (std::defret-mutual true-listp-of-gl-interp-arglist
    (defret true-listp-of-gl-interp-arglist
      (true-listp arg-objs)
      :fn gl-interp-arglist
      :rule-classes :type-prescription)
    :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world))
    :skip-others t))


(defthm stack$a-pop-scratch-of-stack$a-update-0
  (equal (stack$a-pop-scratch (stack$a-update-scratch 0 obj stack))
         (stack$a-pop-scratch stack))
  :hints(("Goal" :in-theory (enable stack$a-pop-scratch stack$a-update-scratch))))

(defthm stack$a-top-scratch-of-stack$a-update-0
  (equal (stack$a-top-scratch (stack$a-update-scratch 0 obj stack))
         (scratchobj-fix obj))
  :hints(("Goal" :in-theory (enable stack$a-top-scratch stack$a-update-scratch))))

(local (in-theory (disable BFR-LISTP$-WHEN-SUBSETP-EQUAL
                           acl2::subsetp-append1
                           acl2::subsetp-of-cons
                           acl2::subsetp-trans2)))

(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate interp-st-bfrs-ok-of-<fn>
      :formal-hyps
      (((interp-st-bfr-p x)           (lbfr-p x (interp-st->logicman interp-st)))
       ((gl-object-p x)               (lbfr-listp (gl-object-bfrlist x) (interp-st->logicman interp-st)))
       ((gl-objectlist-p x)           (lbfr-listp (gl-objectlist-bfrlist x) (interp-st->logicman interp-st)))
       (interp-st                     (interp-st-bfrs-ok interp-st))
       ((constraint-instancelist-p x) (lbfr-listp (constraint-instancelist-bfrlist x) (interp-st->logicman interp-st))))
      :return-concls
      ((xbfr                        (lbfr-p xbfr (interp-st->logicman new-interp-st)))
       ((gl-object-p x)             (lbfr-listp (gl-object-bfrlist x) (interp-st->logicman new-interp-st)))
       ((gl-objectlist-p x)         (lbfr-listp (gl-objectlist-bfrlist x) (interp-st->logicman new-interp-st)))
       (new-interp-st               (interp-st-bfrs-ok new-interp-st)))
      :rules
      ((t (:add-keyword :hints ('(:do-not-induct t)
                                (let ((flag (find-flag-is-hyp clause)))
                                  (and flag
                                       (prog2$ (cw "flag: ~x0~%" flag)
                                               '(:no-op t)))))))
       ((:fnname gl-rewrite-try-rules)
        (:add-hyp (scratchobj-case (stack$a-top-scratch (interp-st->stack interp-st)) :gl-objlist))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))



;; (define logicman-pathcond-eval! (env pathcond &optional (logicman 'logicman))
;;   (declare (Xargs :non-executable t))
;;   :no-function t
;;   :verify-guards nil
;;   (prog2$ (acl2::throw-nonexec-error 'logicman-pathcond-eval!-fn (list env pathcond logicman))
;;           (logicman-pathcond-eval env (update-nth *pathcond-enabledp* t (pathcond-fix pathcond)) logicman))
;;   ///
;;   (local (defthm update-nth-of-update-nth
;;            (equal (update-nth n a (update-nth n b x))
;;                   (update-nth n a x))
;;            :hints(("Goal" :in-theory (enable update-nth)))))

;;   (defthm logicman-pathcond-eval!-of-update-pathcond-enabledp
;;     (equal (logicman-pathcond-eval! env (update-nth *pathcond-enabledp* v pathcond) logicman)
;;            (logicman-pathcond-eval! env pathcond logicman))
;;     :hints(("Goal" :in-theory (enable pathcond-fix))))

;;   (defthm logicman-pathcond-eval!-of-logicman-extension
;;     (implies (and (bind-logicman-extension new old)
;;                   (logicman-pathcond-p pathcond old))
;;              (equal (logicman-pathcond-eval! env pathcond new)
;;                     (logicman-pathcond-eval! env pathcond old))))

;;   (def-updater-independence-thm logicman-pathcond-eval!-of-interp-st-logicman-extension
;;     (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
;;                   (logicman-pathcond-p pathcond (interp-st->logicman old)))
;;              (equal (logicman-pathcond-eval! env pathcond (interp-st->logicman new))
;;                     (logicman-pathcond-eval! env pathcond (interp-st->logicman old)))))

;;   ;; (defthm logicman-pathcond-eval!-of-logicman-pathcond-assume
;;   ;;   (implies (not contradictionp)
;;   ;;            (equal (logicman-pathcond-eval! env new-pathcond)
;;   ;;                   (and (logicman-pathcond-eval! env pathcond)
;;   ;;                        (or (not (pathcond-enabledp pathcond))
;;   ;;                            (bfr-eval x env))))))
;;   )


(define gl-interp-real-errorp (err)
  (and err (not (eq err :unreachable))))

(defthm pathcond-enabledp-of-pathcond-rewind
  (iff (nth *pathcond-enabledp* (pathcond-rewind mode pathcond))
       (nth *pathcond-enabledp* pathcond))
  :hints(("Goal" :in-theory (e/d (pathcond-rewind) (nth-add1 nth update-nth)))))

(defthm pathcond-enabledp-of-interp-st-pathcond-rewind
  (iff (nth *pathcond-enabledp* (pathcond-rewind mode pathcond))
       (nth *pathcond-enabledp* pathcond))
  :hints(("Goal" :in-theory (e/d (pathcond-rewind) (nth-add1 nth update-nth)))))



(local (in-theory (disable nth update-nth)))

(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-pathcond-enabledp
      :rules ((t (:add-concl ;; (implies t ;; (not (gl-interp-real-errorp err))
                                      (iff* (nth *pathcond-enabledp* (interp-st->pathcond new-interp-st))
                                            (nth *pathcond-enabledp* (interp-st->pathcond interp-st))))
                 (:add-keyword :hints ('(:do-not-induct t :expand :lambdas)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '( :expand :lambdas))))))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))


(define maybe-cons (do-it val lst)
  :verify-guards nil
  (if do-it (cons val lst) lst)
  ///
  (defcong iff equal (maybe-cons do-it val lst) 1))

(define maybe-cdr (do-it lst)
  :verify-guards nil
  (if do-it (cdr lst) lst)
  ///
  (defcong iff equal (maybe-cdr do-it lst) 1)
  (defthm maybe-cdr-of-maybe-cons
    (equal (maybe-cdr do-it (maybe-cons do-it val lst))
           lst)
    :hints(("Goal" :in-theory (enable maybe-cons)))))

(define maybe-incr (do-it x)
  :verify-guards nil
  (if do-it (+ 1 (nfix x)) (nfix x))
  ///
  (defcong iff equal (maybe-incr do-it x) 1))

(define maybe-decr (do-it x)
  :verify-guards nil
  (if do-it (nfix (+ -1 (nfix x))) (nfix x))
  ///
  (defcong iff equal (maybe-decr do-it x) 1)

  (defthm maybe-decr-of-maybe-incr
    (equal (maybe-decr do-it (maybe-incr do-it x))
           (nfix x))
    :hints(("Goal" :in-theory (enable maybe-incr)))))



(define logicman-pathcond-eval-checkpoints (env pathcond logicman)
  :non-executable t
  :no-function t
  :verify-guards nil
  :measure (pathcond-rewind-stack-len (lbfr-mode) pathcond)
  (if (or (zp (pathcond-rewind-stack-len (lbfr-mode) pathcond))
          (not (pathcond-enabledp pathcond)))
      nil
    (b* ((pathcond (pathcond-rewind (lbfr-mode) pathcond))
         (eval (logicman-pathcond-eval env pathcond logicman)))
      (cons eval (logicman-pathcond-eval-checkpoints env pathcond logicman))))
  ///
  (deffixequiv logicman-pathcond-eval-checkpoints)

  (defthm logicman-pathcond-eval-checkpoints-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (logicman-pathcond-p pathcond old))
             (equal (logicman-pathcond-eval-checkpoints env pathcond new)
                    (logicman-pathcond-eval-checkpoints env pathcond old))))

  (def-updater-independence-thm logicman-pathcond-eval-checkpoints-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (logicman-pathcond-p pathcond (interp-st->logicman old)))
             (equal (logicman-pathcond-eval-checkpoints env pathcond (interp-st->logicman new))
                    (logicman-pathcond-eval-checkpoints env pathcond (interp-st->logicman old)))))

  (defret logicman-pathcond-eval-checkpoints-of-logicman-pathcond-assume
    (implies (and (not contradictionp)
                  (equal (logicman->mode logicman) (logicman->mode logicman1)))
             (equal (logicman-pathcond-eval-checkpoints env new-pathcond logicman1)
                    (maybe-cons (nth *pathcond-enabledp* pathcond)
                                (logicman-pathcond-eval env pathcond logicman1)
                                (logicman-pathcond-eval-checkpoints env pathcond logicman1))))
    :hints(("Goal" :in-theory (enable maybe-cons)))
    :fn logicman-pathcond-assume)

  (defret logicman-pathcond-eval-checkpoints-of-pathcond-rewind
    (implies (equal bfr-mode (lbfr-mode))
             (equal (logicman-pathcond-eval-checkpoints env new-pathcond logicman)
                    (maybe-cdr (nth *pathcond-enabledp* pathcond)
                               (logicman-pathcond-eval-checkpoints env pathcond logicman))))
    :hints(("Goal" :in-theory (enable maybe-cdr)
            :expand ((logicman-pathcond-eval-checkpoints env pathcond logicman)
                     (logicman-pathcond-eval-checkpoints env (pathcond-rewind (lbfr-mode) pathcond) logicman))))
    :fn pathcond-rewind)

  (defthm len-of-logicman-pathcond-eval-checkpoints
    (implies (nth *pathcond-enabledp* pathcond)
             (equal (len (logicman-pathcond-eval-checkpoints env pathcond logicman))
                    (pathcond-rewind-stack-len (lbfr-mode) pathcond)))))


(define logicman-pathcond-eval-checkpoints! (env pathcond logicman)
  :non-executable t
  :no-function t
  :verify-guards nil
  (b* ((pathcond (update-nth *pathcond-enabledp* t pathcond)))
    (cons (logicman-pathcond-eval env pathcond logicman)
          (logicman-pathcond-eval-checkpoints env pathcond logicman)))
  ///
  (deffixequiv logicman-pathcond-eval-checkpoints)

  (defthm update-pathcond-enabledp-under-pathcond-equiv
    (implies (iff* enabledp (pathcond-enabledp pathcond))
             (pathcond-equiv (update-nth *pathcond-enabledp* enabledp pathcond)
                             pathcond))
    :hints(("Goal" :in-theory (enable pathcond-fix))))

  (fty::deffixcong pathcond-equiv pathcond-equiv (update-nth n v x) x
    :hints(("Goal" :in-theory (enable pathcond-fix))))

  ;; (local (defthm logicman-pathcond-eval-checkpoints-of-update-pathcond-enabledp
  ;;          (implies (nth *pathcond-enabledp* pathcond)
  ;;                   (equal (logicman-pathcond-eval-checkpoints
  ;;                           env (update-nth *pathcond-enabledp* t pathcond) logicman)
  ;;                          (logicman-pathcond-eval-checkpoints
  ;;                           env pathcond logicman)))
  ;;          :hints(("Goal" :in-theory (e/d (logicman-pathcond-eval-checkpoints)
  ;;                                         (LOGICMAN-PATHCOND-EVAL-CHECKPOINTS-OF-PATHCOND-REWIND)))
  ;;                 (and (equal id (acl2::parse-clause-id "Subgoal *1/3'10'"))
  ;;                      '(:error t)))))

  (defthm logicman-pathcond-eval-checkpoints!-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (logicman-pathcond-p pathcond old))
             (equal (logicman-pathcond-eval-checkpoints! env pathcond new)
                    (logicman-pathcond-eval-checkpoints! env pathcond old))))

  (def-updater-independence-thm logicman-pathcond-eval-checkpoints!-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (logicman-pathcond-p pathcond (interp-st->logicman old)))
             (equal (logicman-pathcond-eval-checkpoints! env pathcond (interp-st->logicman new))
                    (logicman-pathcond-eval-checkpoints! env pathcond (interp-st->logicman old)))))

  (defret logicman-pathcond-eval-checkpoints!-of-logicman-pathcond-assume
    (implies (and (not contradictionp)
                  (equal (logicman->mode logicman) (logicman->mode logicman1)))
             (equal (logicman-pathcond-eval-checkpoints! env new-pathcond logicman1)
                    (maybe-cons (nth *pathcond-enabledp* pathcond)
                                (logicman-pathcond-eval env new-pathcond logicman1)
                                (logicman-pathcond-eval-checkpoints! env pathcond logicman1))))
    :hints(("Goal" :in-theory (enable maybe-cons))
           (and stable-under-simplificationp
                '(:in-theory (enable logicman-pathcond-assume))))
    :fn logicman-pathcond-assume)

  (defret logicman-pathcond-eval-checkpoints!-of-interp-st-pathcond-assume
    (implies (and (not contra)
                  (equal (logicman->mode (interp-st->logicman interp-st)) (logicman->mode logicman1)))
             (equal (logicman-pathcond-eval-checkpoints! env (interp-st->pathcond new-interp-st) logicman1)
                    (maybe-cons (nth *pathcond-enabledp* (interp-st->pathcond interp-st))
                                (logicman-pathcond-eval env (interp-st->pathcond new-interp-st) logicman1)
                                (logicman-pathcond-eval-checkpoints! env (interp-st->pathcond interp-st) logicman1))))
    :hints(("Goal" :in-theory (e/d (interp-st-pathcond-assume)
                                   (logicman-pathcond-eval-checkpoints!))))
    :fn interp-st-pathcond-assume)

  (defret logicman-pathcond-eval-checkpoints!-of-pathcond-rewind
    (implies (and (equal bfr-mode (lbfr-mode))
                  (pathcond-rewind-ok bfr-mode pathcond))
             (equal (logicman-pathcond-eval-checkpoints! env new-pathcond logicman)
                    (maybe-cdr (nth *pathcond-enabledp* pathcond)
                               (logicman-pathcond-eval-checkpoints! env pathcond logicman))))
    :hints(("Goal" :in-theory (enable maybe-cdr)
            :expand ((logicman-pathcond-eval-checkpoints env pathcond logicman)))
           (and stable-under-simplificationp
                '(:in-theory (enable pathcond-rewind pathcond-rewind-ok)))
           )
    :fn pathcond-rewind)

  (local (defthm update-nth-of-update-nth
           (equal (update-nth n a (update-nth n b x))
                  (update-nth n a x))
           :hints(("Goal" :in-theory (enable update-nth)))))

  (defthm logicman-pathcond-eval-checkpoints!-of-update-pathcond-enabledp
    (equal (logicman-pathcond-eval-checkpoints! env (update-nth *pathcond-enabledp* v pathcond) logicman)
           (logicman-pathcond-eval-checkpoints! env pathcond logicman)))

  (defthm pathcond-rewind-stack-len-of-update-pathcond-enabledp
    (equal (pathcond-rewind-stack-len mode (update-nth *pathcond-enabledp* v pathcond))
           (pathcond-rewind-stack-len mode pathcond))
    :hints(("Goal" :in-theory (enable pathcond-rewind-stack-len))))

  (defthm len-of-logicman-pathcond-eval-checkpoints!
    (equal (len (logicman-pathcond-eval-checkpoints! env pathcond logicman))
           (+ 1 (pathcond-rewind-stack-len (lbfr-mode) pathcond)))))





(def-updater-independence-thm logicman->mode-of-interp-st-logicman-extension
  (implies (logicman-extension-p (interp-st->logicman new)
                                 (interp-st->logicman old))
           (equal (logicman->mode (interp-st->logicman new))
                  (logicman->mode (interp-st->logicman old)))))

(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-logicman->mode
      :rules ((t (:add-concl (equal (logicman->mode (interp-st->logicman new-interp-st))
                                    (logicman->mode (interp-st->logicman interp-st))))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t))))))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))



(defthm pathcond-rewind-stack-len-of-pathcond-rewind
  (equal (pathcond-rewind-stack-len mode (pathcond-rewind mode pathcond))
         (maybe-decr (nth *pathcond-enabledp* pathcond)
                     (pathcond-rewind-stack-len mode pathcond)))
  :hints(("Goal" :in-theory (enable maybe-decr pos-fix nfix))
         (and stable-under-simplificationp
              '(:in-theory (enable pathcond-rewind)))))

(defret pathcond-rewind-stack-len-of-logicman-pathcond-assume-maybe
  (implies (and (equal mode (logicman->mode logicman))
                (not contradictionp))
           (equal (pathcond-rewind-stack-len mode new-pathcond)
                  (maybe-incr (nth *pathcond-enabledp* pathcond)
                              (pathcond-rewind-stack-len mode pathcond))))
  :hints(("Goal" :in-theory (enable maybe-incr pos-fix nfix))
         (and stable-under-simplificationp
              '(:in-theory (enable logicman-pathcond-assume))))
  :fn logicman-pathcond-assume)

(defret pathcond-rewind-stack-len-of-interp-st-pathcond-assume-maybe
  (implies (and (equal mode (interp-st-bfr-mode interp-st))
                (not contra))
           (equal (pathcond-rewind-stack-len mode (interp-st->pathcond new-interp-st))
                  (maybe-incr (nth *pathcond-enabledp* (interp-st->pathcond interp-st))
                              (pathcond-rewind-stack-len mode (interp-st->pathcond interp-st)))))
  :hints(("Goal" :in-theory (enable interp-st-pathcond-assume)))
  :fn interp-st-pathcond-assume)




(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-pathcond-stack-length
      :rules ((t (:add-concl (implies (and ;; (not (gl-interp-real-errorp err))
                                           (equal mode (logicman->mode (interp-st->logicman interp-st))))
                                      (equal (pathcond-rewind-stack-len
                                              mode
                                              (interp-st->pathcond new-interp-st))
                                             (pathcond-rewind-stack-len
                                              mode (interp-st->pathcond interp-st)))))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t))))))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))


(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-pathcond-rewind-ok
      :rules ((t (:add-concl (implies (equal mode (logicman->mode (interp-st->logicman interp-st)))
                                      (iff (pathcond-rewind-ok mode (interp-st->pathcond new-interp-st))
                                           (pathcond-rewind-ok mode (interp-st->pathcond interp-st)))))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t))))))))
      :hints (("goal" :do-not-induct t :in-theory (enable pathcond-rewind-ok)))
      :no-induction-hint t)))



(local (defret pathcond-rewind-ok-of-interp-st-pathcond-assume
         (implies (and (not contra)
                       (equal bfr-mode (logicman->mode (interp-st->logicman interp-st))))
                  (pathcond-rewind-ok bfr-mode (interp-st->pathcond new-interp-st)))
         :hints(("Goal" :in-theory (enable interp-st-pathcond-assume pathcond-rewind-ok
                                           maybe-incr)))
         :fn interp-st-pathcond-assume))

(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-pathcond
      :formal-hyps (((interp-st-bfr-p x)           (interp-st-bfr-p x))
                    ((gl-object-p x)               (interp-st-bfr-listp (gl-object-bfrlist x)))
                    ((gl-objectlist-p x)           (interp-st-bfr-listp (gl-objectlist-bfrlist x)))
                    (interp-st                     (interp-st-bfrs-ok interp-st))
                    ((constraint-instancelist-p x) (interp-st-bfr-listp (constraint-instancelist-bfrlist x))))
      :rules ((t (:add-concl ;;(implies (not (gl-interp-real-errorp err))
                  (equal (logicman-pathcond-eval-checkpoints!
                          env
                          (interp-st->pathcond new-interp-st)
                          (interp-st->logicman new-interp-st))
                         (logicman-pathcond-eval-checkpoints!
                          env
                          (interp-st->pathcond interp-st)
                          (interp-st->logicman interp-st))))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t)))))))
              ((:fnname gl-rewrite-try-rules)
               (:add-hyp (scratchobj-case (stack$a-top-scratch (interp-st->stack interp-st)) :gl-objlist))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))

(defsection pathcond-eval-preserved

  (local
   (defthm pathcond-eval-equal-when-eval-checkpoints!-equal
     (implies (and (equal evals (logicman-pathcond-eval-checkpoints! env pathcond logicman))
                   (bind-free (case-match evals
                                (('logicman-pathcond-eval-checkpoints! prev-env prev-pathcond prev-logicman)
                                 (and (equal prev-env env)
                                      (not (equal pathcond prev-pathcond))
                                      `((prev-pathcond . ,prev-pathcond)
                                        (prev-logicman . ,prev-logicman))))
                                (& nil)))
                   (equal evals (logicman-pathcond-eval-checkpoints! env prev-pathcond prev-logicman))
                   (iff* (pathcond-enabledp pathcond) (pathcond-enabledp prev-pathcond)))
              (equal (logicman-pathcond-eval env pathcond logicman)
                     (logicman-pathcond-eval env prev-pathcond prev-logicman)))
     :hints (("Goal" :in-theory (enable logicman-pathcond-eval-checkpoints! iff*)))))
     
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-pathcond-eval
      :formal-hyps (((interp-st-bfr-p x)           (interp-st-bfr-p x))
                    ((gl-object-p x)               (interp-st-bfr-listp (gl-object-bfrlist x)))
                    ((gl-objectlist-p x)           (interp-st-bfr-listp (gl-objectlist-bfrlist x)))
                    (interp-st                     (interp-st-bfrs-ok interp-st))
                    ((constraint-instancelist-p x) (interp-st-bfr-listp (constraint-instancelist-bfrlist x))))
      :rules ((t (:add-concl ;;(implies (not (gl-interp-real-errorp err))
                  (equal (logicman-pathcond-eval
                          env
                          (interp-st->pathcond new-interp-st)
                          (interp-st->logicman new-interp-st))
                         (logicman-pathcond-eval
                          env
                          (interp-st->pathcond interp-st)
                          (interp-st->logicman interp-st))))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t)))))))
              ((:fnname gl-rewrite-try-rules)
               (:add-hyp (scratchobj-case (stack$a-top-scratch (interp-st->stack interp-st)) :gl-objlist))))
      :hints (("goal" :do-not-induct t))
      :no-induction-hint t)))

(defsection constraint-eval-tightens

  (local (defret logicman-pathcond-eval-of-assume-tightens
           (implies (not (logicman-pathcond-eval env pathcond logicman))
                    (not (logicman-pathcond-eval env new-pathcond logicman)))
           :hints (("goal" :cases (contradictionp))
                   (and stable-under-simplificationp
                        '(:cases ((pathcond-enabledp pathcond)))))
           :fn logicman-pathcond-assume))

  (local (def-updater-independence-thm logicman-pathcond-eval-of-interp-st-logicman-extension
           (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                         (logicman-pathcond-p pathcond (interp-st->logicman old)))
                    (equal (logicman-pathcond-eval env pathcond (interp-st->logicman new))
                           (logicman-pathcond-eval env pathcond (interp-st->logicman old))))))
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-constraint-eval-tightens
      :formal-hyps (((interp-st-bfr-p x)           (interp-st-bfr-p x))
                    ((gl-object-p x)               (interp-st-bfr-listp (gl-object-bfrlist x)))
                    ((gl-objectlist-p x)           (interp-st-bfr-listp (gl-objectlist-bfrlist x)))
                    (interp-st                     (interp-st-bfrs-ok interp-st))
                    ((constraint-instancelist-p x) (interp-st-bfr-listp (constraint-instancelist-bfrlist x))))
      :rules ((t (:add-concl ;;(implies (not (gl-interp-real-errorp err))
                  (iff (logicman-pathcond-eval
                        env
                        (interp-st->constraint new-interp-st)
                        (interp-st->logicman new-interp-st))
                       (and* (logicman-pathcond-eval
                              env
                              (interp-st->constraint interp-st)
                              (interp-st->logicman interp-st))
                             (hide (logicman-pathcond-eval
                                    env
                                    (interp-st->constraint new-interp-st)
                                    (interp-st->logicman new-interp-st))))))
                 (:add-keyword :hints ('(:do-not-induct t :expand ((:free (x) (hide x))))
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t)))))))
              ((:fnname gl-rewrite-try-rules)
               (:add-hyp (scratchobj-case (stack$a-top-scratch (interp-st->stack interp-st)) :gl-objlist))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))



(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-reclimit
      :rules ((t (:add-concl (acl2::nat-equiv
                              (interp-st->reclimit new-interp-st)
                              (interp-st->reclimit interp-st)))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t))))))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))

(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-preserves-reclimit-natp
      :rules ((t (:add-concl (implies (natp (interp-st->reclimit interp-st))
                                      (natp (interp-st->reclimit new-interp-st))))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t))))))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))


;; (local (defthmd redundant-update-nth
;;          (implies (< (nfix n) (len x))
;;                   (equal (update-nth n (nth n x) x)
;;                          x))
;;          :hints(("Goal" :in-theory (enable update-nth nth len)))))

;; (local (defthm interp-st-redundant-update-reclimit
;;          (implies (and (interp-stp interp-st)
;;                        (equal reclimit (double-rewrite (ifix (interp-st->reclimit interp-st)))))
;;                   (equal (update-interp-st->reclimit reclimit interp-st)
;;                          interp-st))
;;          :hints(("Goal" :in-theory (e/d (update-interp-st->reclimit interp-st->reclimit
;;                                            interp-stp
;;                                            redundant-update-nth)
;;                                         (equal-len-hyp))))))

(local (defthm alistp-when-gl-object-alist-p-rw
         (implies (gl-object-alist-p x)
                  (alistp x))
         :hints(("Goal" :in-theory (enable gl-object-alist-p)))))


(local (Defthm stack$a-scratch-len-of-set-minor-debug
         (equal (stack$a-scratch-len (stack$a-set-minor-debug obj stack))
                (stack$a-scratch-len stack))
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-set-minor-debug)))))

(local (Defthm stack$a-scratch-len-of-set-minor-bindings
         (equal (stack$a-scratch-len (stack$a-set-minor-bindings obj stack))
                (stack$a-scratch-len stack))
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-set-minor-bindings)))))

(local (Defthm stack$a-scratch-len-of-push-minor-frame
         (equal (stack$a-scratch-len (stack$a-push-minor-frame stack))
                0)
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-push-minor-frame)))))

(defcong major-stack-scratch-isomorphic equal (stack$a-scratch-len x) 1
  :hints(("Goal" :in-theory (enable stack$a-scratch-len))))

(defcong major-stack-scratch-isomorphic equal (stack$a-minor-frames x) 1
  :hints(("Goal" :in-theory (e/d (stack$a-minor-frames pos-fix)
                                 (minor-stack-scratch-isomorphic-implies-pos-equiv-len-1))
          :use ((:instance minor-stack-scratch-isomorphic-implies-pos-equiv-len-1
                 (x (major-frame->minor-stack (car x)))
                 (x-equiv (major-frame->minor-stack (car x-equiv))))))))

(defcong major-stack-scratch-isomorphic equal (stack$a-frames x) 1
  :hints(("Goal" :in-theory (e/d (stack$a-frames pos-fix)
                                 (major-stack-scratch-isomorphic-implies-pos-equiv-len-1))
          :use ((:instance major-stack-scratch-isomorphic-implies-pos-equiv-len-1)))))

(local (Defthm stack$a-minor-frames-of-set-minor-debug
         (equal (stack$a-minor-frames (stack$a-set-minor-debug obj stack))
                (stack$a-minor-frames stack))
         :hints(("Goal" :in-theory (enable stack$a-minor-frames
                                           stack$a-set-minor-debug
                                           len)))))

(local (Defthm stack$a-minor-frames-of-set-minor-bindings
         (equal (stack$a-minor-frames (stack$a-set-minor-bindings obj stack))
                (stack$a-minor-frames stack))
         :hints(("Goal" :in-theory (enable stack$a-minor-frames
                                           stack$a-set-minor-bindings
                                           len)))))

(local (Defthm stack$a-minor-frames-of-push-minor-frame
         (equal (stack$a-minor-frames (stack$a-push-minor-frame stack))
                (+ 1 (stack$a-minor-frames stack)))
         :hints(("Goal" :in-theory (enable stack$a-minor-frames
                                           stack$a-push-minor-frame)))))

(defthm posp-of-stack$a-minor-frames
  (posp (stack$a-minor-frames stack$c))
  :hints(("Goal" :in-theory (enable stack$a-minor-frames)))
  :rule-classes :type-prescription)

(defthm posp-of-stack$a-frames
  (posp (stack$a-frames stack$c))
  :hints(("Goal" :in-theory (enable stack$a-frames)))
  :rule-classes :type-prescription)


(local (defthm pathcond-rewind-ok-by-stack-len
         (implies (and (equal stack-len (pathcond-rewind-stack-len bfr-mode pathcond))
                       (bind-free (case-match stack-len
                                    (('maybe-incr cond x) `((cond . ,cond) (x . ,x)))))
                       (equal stack-len (maybe-incr cond x))
                       (iff* cond (nth *pathcond-enabledp* pathcond)))
                  (pathcond-rewind-ok bfr-mode pathcond))
         :hints(("Goal" :in-theory (enable pathcond-rewind-ok maybe-incr)))))

(defthm gl-object-alist-p-of-pairlis$
  (implies (and (gl-objectlist-p vals)
                (pseudo-var-list-p vars)
                (equal (len vars) (len vals)))
           (gl-object-alist-p (pairlis$ vars vals)))
  :hints(("Goal" :in-theory (enable pairlis$ gl-object-alist-p))))



(local (Defthm stack$a-scratch-len-of-push-scratch
         (equal (stack$a-scratch-len (stack$a-push-scratch obj stack))
                (+ 1 (stack$a-scratch-len stack)))
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-push-scratch)))))

(local (Defthm stack$a-scratch-len-of-pop-scratch
         (equal (stack$a-scratch-len (stack$a-pop-scratch stack))
                (nfix (+ -1 (stack$a-scratch-len stack))))
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-pop-scratch len)))))

(local (Defthm stack$a-scratch-len-of-update-scratch
         (implies (< (nfix n) (stack$a-scratch-len stack))
                  (equal (stack$a-scratch-len (stack$a-update-scratch n obj stack))
                         (stack$a-scratch-len stack)))
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-update-scratch len)))))

(local (Defthm stack$a-frames-of-push-frame
         (equal (stack$a-frames (stack$a-push-frame stack))
                (+ 1 (stack$a-frames stack)))
         :hints(("Goal" :in-theory (enable stack$a-frames
                                           stack$a-push-frame)))))

(local (Defthm stack$a-minor-frames-of-push-frame
         (equal (stack$a-minor-frames (stack$a-push-frame stack))
                1)
         :hints(("Goal" :in-theory (enable stack$a-minor-frames
                                           stack$a-push-frame)))))

(local (Defthm stack$a-minor-frames-of-set-debug
         (equal (stack$a-minor-frames (stack$a-set-debug obj stack))
                (stack$a-minor-frames stack))
         :hints(("Goal" :in-theory (enable stack$a-minor-frames
                                           stack$a-set-debug)))))

(local (Defthm stack$a-frames-of-set-debug
         (equal (stack$a-frames (stack$a-set-debug obj stack))
                (stack$a-frames stack))
         :hints(("Goal" :in-theory (enable stack$a-frames
                                           stack$a-set-debug len)))))

(local (Defthm stack$a-scratch-len-of-set-debug
         (equal (stack$a-scratch-len (stack$a-set-debug obj stack))
                (stack$a-scratch-len stack))
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-set-debug)))))

(local (Defthm stack$a-scratch-len-of-push-frame
         (equal (stack$a-scratch-len (stack$a-push-frame stack))
                0)
         :hints(("Goal" :in-theory (enable stack$a-scratch-len
                                           stack$a-push-frame)))))

(defcong scratchobj-isomorphic major-stack-scratch-isomorphic (stack$a-push-scratch obj stack) 1
  :hints(("Goal" :in-theory (enable stack$a-push-scratch))))




(progn
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-return-values-correct
      :rules ((t (:add-concl (equal (list . <values>)
                                    <call>))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t))))))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world)))))


(defsection gl-interp-term-guards
  (local (in-theory (enable stack$a-update-scratch-in-terms-of-push-pop)))

  (local (in-theory (disable w)))

  (local (defthm bfr-varname-p-of-get-term->bvar$a
           (b* ((bvar-db (interp-st->bvar-db interp-st))
                (logicman (interp-st->logicman interp-st))
                (bvar (get-term->bvar$a obj bvar-db)))
             (implies (and (interp-st-bfrs-ok interp-st)
                           bvar)
                      (bfr-varname-p bvar logicman)))
           :hints(("Goal" :in-theory (enable interp-st-bfrs-ok)))))

  (local
   (defthm len-cinstlist-when-scratchobj-isomorphic-rw
     (implies (and (scratchobj-isomorphic y (double-rewrite x))
                   (syntaxp (not (equal y x)))
                   (scratchobj-case y :cinstlist))
              (equal (len (scratchobj-cinstlist->val x))
                     (len (scratchobj-cinstlist->val y))))))

  (local
   (defthm len-gl-objlist-when-scratchobj-isomorphic-rw
     (implies (and (scratchobj-isomorphic y (double-rewrite x))
                   (syntaxp (not (equal y x)))
                   (scratchobj-case y :gl-objlist))
              (equal (len (scratchobj-gl-objlist->val x))
                     (len (scratchobj-gl-objlist->val y))))))


  (local (defthm eqlablep-of-rewrite-rule->equiv
           (implies (pseudo-rewrite-rule-p rule)
                    (eqlablep (acl2::rewrite-rule->equiv rule)))
           :hints(("Goal" :in-theory (enable pseudo-rewrite-rule-p)))))
  
  ;; ugh
  (local (defthm booleanp-of-interp-st-pathcond-enabledp
           (implies (interp-stp interp-st)
                    (booleanp (nth *pathcond-enabledp* (interp-st->pathcond interp-st))))
           :hints(("Goal" :in-theory (enable interp-stp pathcondp interp-st->pathcond)))
           :rule-classes :type-prescription))
  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (verify-guards gl-interp-term
      :guard-debug t)))







;; (fty::defmap eval-env :key-type pseudo-var :true-listp t)

;; (fty::defprod ev-constraint-instance
;;   ((thmname symbolp)
;;    (subst eval-env-p))
;;   :layout :tree)

;; (fty::deflist ev-constraint-instancelist :elt-type ev-constraint-instance :true-listp t)

;; (local
;;  (progn
;;    (include-book "scratchobj")
;;    (defconst *ev-scratchobj-type-mapping*
;;      '((:gl-obj . t)
;;        (:gl-objlist . true-listp)
;;        (:bfr . booleanp)
;;        (:bfrlist . boolean-listp)
;;        (:cinst . ev-constraint-instance-p)
;;        (:cinstlist . ev-constraint-instancelist-p)))
;;    (defun scratchobj-tmplsubst-add-evtypes (x)
;;      (declare (xargs :mode :program))
;;      (if (atom x)
;;          nil
;;        (b* (((acl2::tmplsubst x1) (car x))
;;             (kindlook (assoc :<kind> x1.atoms))
;;             ((unless kindlook) (er hard? 'scratchobj-tmplsubst-add-evtypes "failed to find :<kind>"))
;;             (kind (cdr kindlook))
;;             (evtype-look (assoc kind *ev-scratchobj-type-mapping*))
;;             ((unless evtype-look) (er hard? 'scratchobj-tmplsubst-add-evtypes "failed to find: ~x0" kind))
;;             (evtype (cdr evtype-look)))
;;          (cons (acl2::change-tmplsubst
;;                 x1 :atoms (cons `(<evtype> . ,evtype) x1.atoms))
;;                (scratchobj-tmplsubst-add-evtypes (cdr x))))))

;;    (defconst *scratchobj-evtypes-tmplsubsts*
;;      (scratchobj-tmplsubst-add-evtypes *scratchobj-tmplsubsts*))))
            
         
;; (make-event
;;  `(progn
;;     (fty::deftagsum ev-scratchobj
;;       :layout :tree
;;       . ,(acl2::template-proj '(:<kind> ((val <evtype>)))
;;                               *scratchobj-evtypes-tmplsubsts*))

;;     (defthm scratchobj-kind-p-of-ev-scratchobj-kind
;;       (scratchobj-kind-p (ev-scratchobj-kind x))
;;       :hints(("Goal" :in-theory (enable ev-scratchobj-kind))))))


;; (fty::deflist ev-scratchlist :elt-type ev-scratchobj :true-listp t)

;; (fty::defprod ev-minor-frame
;;   ((bindings eval-env-p)
;;    (scratch ev-scratchlist-p)
;;    (debug)))

;; (fty::deflist ev-minor-stack :elt-type ev-minor-frame :true-listp t :non-emptyp t
;;   ///
;;   (defthm ev-minor-stack-p-of-cons-cdr
;;     (implies (and (ev-minor-stack-p x)
;;                   (ev-minor-frame-p a))
;;              (ev-minor-stack-p (cons a (cdr x))))
;;     :hints(("Goal" :in-theory (enable ev-minor-stack-p)))))

;; (make-event
;;  `(fty::defprod ev-major-frame
;;     ((bindings eval-env-p)
;;      (debug)
;;      (minor-stack ev-minor-stack-p :default ',(list (make-ev-minor-frame))))))

;; (fty::deflist ev-major-stack :elt-type ev-major-frame :true-listp t :non-emptyp t
;;   ///
;;   (defthm ev-major-stack-p-of-cons-cdr
;;     (implies (and (ev-major-stack-p x)
;;                   (ev-major-frame-p a))
;;              (ev-major-stack-p (cons a (cdr x))))
;;     :hints(("Goal" :in-theory (enable ev-major-stack-p)))))

(define gl-object-ev ((x gl-object-p)
                      (env gl-env-p)
                      &optional (logicman 'logicman))
  :guard (lbfr-listp (gl-object-bfrlist x))
  :returns (new-x gl-object-p)
  (g-concrete (fgl-object-eval x env))
  ///

  (defthm gl-object-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (gl-object-bfrlist x) old))
             (equal (gl-object-ev x env new)
                    (gl-object-ev x env old)))
    :hints(("Goal" :in-theory (enable gl-object-bfrlist))))

  (def-updater-independence-thm gl-object-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (gl-object-bfrlist x) (interp-st->logicman old)))
             (equal (gl-object-ev x env (interp-st->logicman new))
                    (gl-object-ev x env (interp-st->logicman old))))))

(define gl-objectlist-ev ((x gl-objectlist-p)
                      (env gl-env-p)
                      &optional (logicman 'logicman))
  :guard (lbfr-listp (gl-objectlist-bfrlist x))
  :returns (new-x gl-objectlist-p)
  (if (atom x)
      nil
    (cons (gl-object-ev (car x) env)
          (gl-objectlist-ev (cdr x) env)))
  ///

  (defthm gl-objectlist-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (gl-objectlist-bfrlist x) old))
             (equal (gl-objectlist-ev x env new)
                    (gl-objectlist-ev x env old)))
    :hints(("Goal" :in-theory (enable gl-objectlist-bfrlist))))

  (def-updater-independence-thm gl-objectlist-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (gl-objectlist-bfrlist x) (interp-st->logicman old)))
             (equal (gl-objectlist-ev x env (interp-st->logicman new))
                    (gl-objectlist-ev x env (interp-st->logicman old))))))




(define gl-object-alist-ev ((x gl-object-alist-p)
                                   (env gl-env-p)
                                   &optional (logicman 'logicman))
  :guard (lbfr-listp (gl-object-alist-bfrlist x))
  :guard-hints (("goal" :in-theory (enable gl-object-alist-bfrlist)))
  :returns (ans gl-object-alist-p)
  (if (atom x)
      nil
    (if (mbt (and (consp (car x))
                  (pseudo-var-p (caar x))))
        (cons (cons (caar x)
                    (gl-object-ev (cdar x) env))
              (gl-object-alist-ev (cdr x) env))
      (gl-object-alist-ev (cdr x) env)))
  ///
  (local (in-theory (enable gl-object-alist-fix)))

  (defthm gl-object-alist-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (gl-object-alist-bfrlist x) old))
             (equal (gl-object-alist-ev x env new)
                    (gl-object-alist-ev x env old)))
    :hints(("Goal" :in-theory (enable gl-object-alist-bfrlist))))

  (def-updater-independence-thm gl-object-alist-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (gl-object-alist-bfrlist x) (interp-st->logicman old)))
             (equal (gl-object-alist-ev x env (interp-st->logicman new))
                    (gl-object-alist-ev x env (interp-st->logicman old))))))

(define constraint-instance-ev ((x constraint-instance-p)
                                       (env gl-env-p)
                                       &optional (logicman 'logicman))
  :guard (lbfr-listp (constraint-instance-bfrlist x))
  :returns (ev constraint-instance-p)
  (b* (((constraint-instance x)))
    (make-constraint-instance
     :thmname x.thmname
     :subst (gl-object-alist-ev x.subst env)))
  ///
  (defthm constraint-instance-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (constraint-instance-bfrlist x) old))
             (equal (constraint-instance-ev x env new)
                    (constraint-instance-ev x env old))))

  (def-updater-independence-thm constraint-instance-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (constraint-instance-bfrlist x) (interp-st->logicman old)))
             (equal (constraint-instance-ev x env (interp-st->logicman new))
                    (constraint-instance-ev x env (interp-st->logicman old))))))

(define constraint-instancelist-ev ((x constraint-instancelist-p)
                                           (env gl-env-p)
                                           &optional (logicman 'logicman))
  :guard (lbfr-listp (constraint-instancelist-bfrlist x))
  :returns (ev constraint-instancelist-p)
  (if (atom x)
      nil
    (cons (constraint-instance-ev (car x) env)
          (constraint-instancelist-ev (cdr x) env)))
  ///
  (defthm constraint-instancelist-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (constraint-instancelist-bfrlist x) old))
             (equal (constraint-instancelist-ev x env new)
                    (constraint-instancelist-ev x env old))))

  (def-updater-independence-thm constraint-instancelist-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (constraint-instancelist-bfrlist x) (interp-st->logicman old)))
             (equal (constraint-instancelist-ev x env (interp-st->logicman new))
                    (constraint-instancelist-ev x env (interp-st->logicman old))))))

(define scratchobj-ev ((x scratchobj-p)
                              (env gl-env-p)
                              &optional (logicman 'logicman))
  :guard (lbfr-listp (scratchobj->bfrlist x))
  :returns (ev scratchobj-p)
  (scratchobj-case x
    :gl-obj (scratchobj-gl-obj (gl-object-ev x.val env))
    :gl-objlist (scratchobj-gl-objlist (gl-objectlist-ev x.val env))
    :bfr (scratchobj-bfr (gobj-bfr-eval x.val env))
    :bfrlist (scratchobj-bfrlist (gobj-bfr-list-eval x.val env))
    :cinst (scratchobj-cinst (constraint-instance-ev x.val env))
    :cinstlist (scratchobj-cinstlist (constraint-instancelist-ev x.val env)))
  ///
  (defthm scratchobj-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (scratchobj->bfrlist x) old))
             (equal (scratchobj-ev x env new)
                    (scratchobj-ev x env old))))

  (def-updater-independence-thm scratchobj-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (scratchobj->bfrlist x) (interp-st->logicman old)))
             (equal (scratchobj-ev x env (interp-st->logicman new))
                    (scratchobj-ev x env (interp-st->logicman old))))))

(define scratchlist-ev ((x scratchlist-p)
                        (env gl-env-p)
                        &optional (logicman 'logicman))
  :guard (lbfr-listp (scratchlist-bfrlist x))
  :returns (ev scratchlist-p)
  (if (atom x)
      nil
    (cons (scratchobj-ev (car x) env)
          (scratchlist-ev (cdr x) env)))
  ///
  (defthm scratchlist-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (scratchlist-bfrlist x) old))
             (equal (scratchlist-ev x env new)
                    (scratchlist-ev x env old))))

  (def-updater-independence-thm scratchlist-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (scratchlist-bfrlist x) (interp-st->logicman old)))
             (equal (scratchlist-ev x env (interp-st->logicman new))
                    (scratchlist-ev x env (interp-st->logicman old))))))

(define minor-frame-ev ((x minor-frame-p)
                               (env gl-env-p)
                               &optional (logicman 'logicman))
  :guard (lbfr-listp (minor-frame-bfrlist x))
  :returns (ev minor-frame-p)
  (b* (((minor-frame x)))
    (make-minor-frame
     :bindings (gl-object-alist-ev x.bindings env)
     :debug x.debug
     :scratch (scratchlist-ev x.scratch env)))
  ///
  (defthm minor-frame-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (minor-frame-bfrlist x) old))
             (equal (minor-frame-ev x env new)
                    (minor-frame-ev x env old))))

  (def-updater-independence-thm minor-frame-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (minor-frame-bfrlist x) (interp-st->logicman old)))
             (equal (minor-frame-ev x env (interp-st->logicman new))
                    (minor-frame-ev x env (interp-st->logicman old))))))

(define minor-stack-ev ((x minor-stack-p)
                               (env gl-env-p)
                               &optional (logicman 'logicman))
  :guard (lbfr-listp (minor-stack-bfrlist x))
  :returns (ev minor-stack-p)
  :measure (len x)
  :ruler-extenders (cons)
  (cons (minor-frame-ev (car x) env)
        (and (consp (cdr x))
             (minor-stack-ev (cdr x) env)))
  ///
  (defthm minor-stack-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (minor-stack-bfrlist x) old))
             (equal (minor-stack-ev x env new)
                    (minor-stack-ev x env old))))

  (def-updater-independence-thm minor-stack-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (minor-stack-bfrlist x) (interp-st->logicman old)))
             (equal (minor-stack-ev x env (interp-st->logicman new))
                    (minor-stack-ev x env (interp-st->logicman old))))))



(define major-frame-ev ((x major-frame-p)
                               (env gl-env-p)
                               &optional (logicman 'logicman))
  :guard (lbfr-listp (major-frame-bfrlist x))
  :returns (ev major-frame-p)
  (b* (((major-frame x)))
    (make-major-frame
     :bindings (gl-object-alist-ev x.bindings env)
     :debug x.debug
     :minor-stack (minor-stack-ev x.minor-stack env)))
  ///
  (defthm major-frame-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (major-frame-bfrlist x) old))
             (equal (major-frame-ev x env new)
                    (major-frame-ev x env old))))

  (def-updater-independence-thm major-frame-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (major-frame-bfrlist x) (interp-st->logicman old)))
             (equal (major-frame-ev x env (interp-st->logicman new))
                    (major-frame-ev x env (interp-st->logicman old))))))

(define major-stack-ev ((x major-stack-p)
                               (env gl-env-p)
                               &optional (logicman 'logicman))
  :guard (lbfr-listp (major-stack-bfrlist x))
  :returns (ev major-stack-p)
  :measure (len x)
  :ruler-extenders (cons)
  (cons (major-frame-ev (car x) env)
        (and (consp (cdr x))
             (major-stack-ev (cdr x) env)))
  ///
  (defthm major-stack-ev-of-logicman-extension
    (implies (and (bind-logicman-extension new old)
                  (lbfr-listp (major-stack-bfrlist x) old))
             (equal (major-stack-ev x env new)
                    (major-stack-ev x env old))))

  (def-updater-independence-thm major-stack-ev-of-interp-st-logicman-extension
    (implies (and (logicman-extension-p (interp-st->logicman new) (interp-st->logicman old))
                  (lbfr-listp (major-stack-bfrlist x) (interp-st->logicman old)))
             (equal (major-stack-ev x env (interp-st->logicman new))
                    (major-stack-ev x env (interp-st->logicman old))))))


(defsection stack-semantics-preserved-lemmas
  (local (in-theory (enable major-stack-ev
                            minor-stack-ev
                            major-frame-ev
                            minor-frame-ev)))

  (defthm scratchlist-ev-of-cdr
    (equal (scratchlist-ev (cdr x) env)
           (cdr (scratchlist-ev x env)))
    :hints(("Goal" :in-theory (enable scratchlist-ev))))

  (defthm scratchlist-ev-of-cons
    (equal (scratchlist-ev (cons x y) env)
           (cons (scratchobj-ev x env)
                 (scratchlist-ev y env)))
    :hints(("Goal" :in-theory (enable scratchlist-ev))))

  (defthm scratchlist-ev-of-nil
    (equal (scratchlist-ev nil env) nil)
    :hints(("Goal" :in-theory (enable scratchlist-ev))))

  (defthm gl-object-alist-ev-of-nil
    (equal (gl-object-alist-ev nil env) nil)
    :hints(("Goal" :in-theory (enable gl-object-alist-ev))))

  (defthm major-stack-ev-of-stack$a-pop-scratch
    (equal (major-stack-ev (stack$a-pop-scratch stack) env)
           (stack$a-pop-scratch (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-pop-scratch))))

  (defthm major-stack-ev-of-stack$a-push-scratch
    (equal (major-stack-ev (stack$a-push-scratch obj stack) env)
           (stack$a-push-scratch
            (scratchobj-ev obj env)
            (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-push-scratch))))

  (defthm major-stack-ev-of-stack$a-pop-frame
    (equal (major-stack-ev (stack$a-pop-frame stack) env)
           (stack$a-pop-frame (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-pop-frame default-car))))

  (defthm major-stack-ev-of-stack$a-set-bindings
    (equal (major-stack-ev (stack$a-set-bindings bindings stack) env)
           (stack$a-set-bindings (gl-object-alist-ev bindings env)
                                 (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-set-bindings))))

  (defthm major-stack-ev-of-stack$a-push-frame
    (equal (major-stack-ev (stack$a-push-frame stack) env)
           (stack$a-push-frame (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-push-frame))))

  (defthm major-stack-ev-of-stack$a-set-debug
    (equal (major-stack-ev (stack$a-set-debug obj stack) env)
           (stack$a-set-debug obj (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-set-debug))))

  (defthm gl-object-alist-ev-of-append
    (equal (gl-object-alist-ev (append a b) env)
           (append (gl-object-alist-ev a env)
                   (gl-object-alist-ev b env)))
    :hints(("Goal" :in-theory (enable gl-object-alist-ev))))

  (defthm major-stack-ev-of-stack$a-add-minor-bindings
    (equal (major-stack-ev (stack$a-add-minor-bindings bindings stack) env)
           (stack$a-add-minor-bindings
            (gl-object-alist-ev bindings env)
            (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-add-minor-bindings))))

  (defthm major-stack-ev-of-stack$a-pop-minor-frame
    (equal (major-stack-ev (stack$a-pop-minor-frame stack) env)
           (stack$a-pop-minor-frame (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame))))

  (defthm major-stack-ev-of-stack$a-set-minor-debug
    (equal (major-stack-ev (stack$a-set-minor-debug obj stack) env)
           (stack$a-set-minor-debug obj (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-set-minor-debug))))

  (defthm major-stack-ev-of-stack$a-set-minor-bindings
    (equal (major-stack-ev (stack$a-set-minor-bindings bindings stack) env)
           (stack$a-set-minor-bindings
            (gl-object-alist-ev bindings env)
            (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-set-minor-bindings))))

  (defthm major-stack-ev-of-stack$a-push-minor-frame
    (equal (major-stack-ev (stack$a-push-minor-frame stack) env)
           (stack$a-push-minor-frame (major-stack-ev stack env)))
    :hints(("Goal" :in-theory (enable stack$a-push-minor-frame)))))


(define stack-equiv-except-top-bindings ((x major-stack-p)
                                         (y major-stack-p))

  (b* (((major-frame x1) (car x))
       ((major-frame y1) (car y)))
    (and ;;(ec-call (gl-bindings-extension-p x1.bindings y1.bindings))
     (equal x1.debug y1.debug)
     (minor-stack-equiv x1.minor-stack y1.minor-stack)
     (if (atom (cdr x))
         (atom (cdr y))
       (and (consp (cdr y))
            (major-stack-equiv (cdr x) (cdr y))))))
  ///
  (defequiv stack-equiv-except-top-bindings)

  (local (defthm len-equal-when-major-stack-fix
           (implies (and (equal (major-stack-fix x) (major-stack-fix y))
                         (consp x) (consp y))
                    (equal (equal (len x) (len y)) t))
           :hints (("Goal" :use ((:instance len-of-major-stack-fix)
                                 (:instance len-of-major-stack-fix (x y)))
                    :in-theory (disable len-of-major-stack-fix)))))

  (local (defthm equal-+-1
           (equal (equal (+ 1 x) (+ 1 y))
                  (equal (fix x) (fix y)))))
  
  (defcong stack-equiv-except-top-bindings equal (stack$a-frames x) 1
    :hints(("Goal" :in-theory (enable stack$a-frames len))))

  (defcong stack-equiv-except-top-bindings equal (stack$a-minor-frames x) 1
    :hints(("Goal" :in-theory (enable stack$a-minor-frames len))))

  (defcong stack-equiv-except-top-bindings
    stack-equiv-except-top-bindings
    (major-stack-ev stack env logicman) 1
    :hints(("Goal" :in-theory (enable major-stack-ev major-frame-ev))))

  (defcong stack-equiv-except-top-bindings
    stack-equiv-except-top-bindings
    (stack$a-pop-scratch stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-scratch))))

  (defcong stack-equiv-except-top-bindings
    stack-equiv-except-top-bindings
    (stack$a-pop-minor-frame stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame))))

  (defcong stack-equiv-except-top-bindings
    equal
    (stack$a-pop-frame stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-frame
                                      major-stack-fix default-car))))

  (defret stack-equiv-except-top-bindings-of-gl-interp-syntax-bind
    (implies (equal logicman (interp-st->logicman new-interp-st))
             (stack-equiv-except-top-bindings
              (major-stack-ev
               (interp-st->stack new-interp-st)
               env logicman)
              (major-stack-ev
               (interp-st->stack interp-st)
               env (interp-st->logicman interp-st))))
    :hints(("Goal" :in-theory (enable gl-interp-syntax-bind
                                      stack$a-add-binding
                                      major-stack-ev
                                      major-frame-ev)))
    :fn gl-interp-syntax-bind)

  (defret stack-equiv-except-top-bindings-of-gl-rewrite-relieve-hyp-synp
    (implies (equal logicman (interp-st->logicman new-interp-st))
             (stack-equiv-except-top-bindings
              (major-stack-ev
               (interp-st->stack new-interp-st)
               env logicman)
              (major-stack-ev
               (interp-st->stack interp-st)
               env (interp-st->logicman interp-st))))
    :hints(("Goal" :in-theory (enable gl-rewrite-relieve-hyp-synp
                                      stack$a-set-bindings
                                      major-stack-ev
                                      major-frame-ev)))
    :fn gl-rewrite-relieve-hyp-synp))


(define minor-stack-equiv-except-top-bindings ((x minor-stack-p)
                                               (y minor-stack-p))

  (b* (((minor-frame x1) (car x))
       ((minor-frame y1) (car y)))
    (and ;;(ec-call (gl-bindings-extension-p x1.bindings y1.bindings))
     (equal x1.debug y1.debug)
     (scratchlist-equiv x1.scratch y1.scratch)
     (if (atom (cdr x))
         (atom (cdr y))
       (and (consp (cdr y))
            (minor-stack-equiv (cdr x) (cdr y))))))
  ///
  (defequiv minor-stack-equiv-except-top-bindings))

(define stack-equiv-except-top-major/minor-bindings ((x major-stack-p)
                                                     (y major-stack-p))

  (b* (((major-frame x1) (car x))
       ((major-frame y1) (car y)))
    (and ;;(ec-call (gl-bindings-extension-p x1.bindings y1.bindings))
     (equal x1.debug y1.debug)
     (minor-stack-equiv-except-top-bindings x1.minor-stack y1.minor-stack)
     (if (atom (cdr x))
         (atom (cdr y))
       (and (consp (cdr y))
            (major-stack-equiv (cdr x) (cdr y))))))
  ///
  (defequiv stack-equiv-except-top-major/minor-bindings)
  (local (in-theory (enable minor-stack-equiv-except-top-bindings)))

  (local (defthm len-equal-when-major-stack-fix
           (implies (and (equal (major-stack-fix x) (major-stack-fix y))
                         (consp x) (consp y))
                    (equal (equal (len x) (len y)) t))
           :hints (("Goal" :use ((:instance len-of-major-stack-fix)
                                 (:instance len-of-major-stack-fix (x y)))
                    :in-theory (disable len-of-major-stack-fix)))))

  (local (defthm equal-+-1
           (equal (equal (+ 1 x) (+ 1 y))
                  (equal (fix x) (fix y)))))
  
  (defcong stack-equiv-except-top-major/minor-bindings equal (stack$a-frames x) 1
    :hints(("Goal" :in-theory (enable stack$a-frames len))))

  (defcong stack-equiv-except-top-major/minor-bindings equal (stack$a-minor-frames x) 1
    :hints(("Goal" :in-theory (enable stack$a-minor-frames len))))

  (defcong stack-equiv-except-top-major/minor-bindings
    stack-equiv-except-top-major/minor-bindings
    (major-stack-ev stack env logicman) 1
    :hints(("Goal" :in-theory (enable major-stack-ev major-frame-ev minor-stack-ev minor-frame-ev))))

  (defcong stack-equiv-except-top-major/minor-bindings
    stack-equiv-except-top-major/minor-bindings
    (stack$a-pop-scratch stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-scratch))))

  (defcong stack-equiv-except-top-major/minor-bindings
    equal
    (stack$a-pop-frame stack) 1
    :hints(("Goal" :in-theory (enable stack$a-pop-frame
                                      major-stack-fix default-car))))

  (defthm stack-equiv-except-top-major/minor-bindings-of-stack$a-add-minor-bindings
    (stack-equiv-except-top-major/minor-bindings
     (stack$a-add-minor-bindings bindings stack)
     stack)
  :hints(("Goal" :in-theory (enable stack$a-add-minor-bindings))))

  (defcong stack-equiv-except-top-major/minor-bindings
    stack-equiv-except-top-bindings
    (stack$a-pop-minor-frame stack)
    1
    :hints(("Goal" :in-theory (enable stack$a-pop-minor-frame
                                      stack-equiv-except-top-bindings))))

  (defrefinement stack-equiv-except-top-bindings
    stack-equiv-except-top-major/minor-bindings
    :hints(("Goal" :in-theory (enable stack-equiv-except-top-bindings)))))




(defsection gl-interp-stack-equiv-except-top-bindings
  (local (in-theory (enable stack$a-update-scratch-in-terms-of-push-pop)))

  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-stack-equiv-except-top-bindings
      :formal-hyps (((interp-st-bfr-p x)           (interp-st-bfr-p x))
                    ((gl-object-p x)               (interp-st-bfr-listp (gl-object-bfrlist x)))
                    ((gl-objectlist-p x)           (interp-st-bfr-listp (gl-objectlist-bfrlist x)))
                    (interp-st                     (interp-st-bfrs-ok interp-st))
                    ((constraint-instancelist-p x) (interp-st-bfr-listp (constraint-instancelist-bfrlist x))))
      :rules ((t (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t)))))))
              ((not (:fnname gl-interp-bindinglist))
               (:add-concl (stack-equiv-except-top-bindings
                            (major-stack-ev (interp-st->stack new-interp-st)
                                            env
                                            (interp-st->logicman new-interp-st))
                            (major-stack-ev (interp-st->stack interp-st)
                                            env
                                            (interp-st->logicman interp-st)))))
              ((:fnname gl-interp-bindinglist)
               (:add-concl (stack-equiv-except-top-major/minor-bindings
                            (major-stack-ev (interp-st->stack new-interp-st)
                                            env
                                            (interp-st->logicman new-interp-st))
                            (major-stack-ev (interp-st->stack interp-st)
                                            env
                                            (interp-st->logicman interp-st)))))
              ((:fnname gl-rewrite-try-rules)
               (:add-hyp (scratchobj-case (stack$a-top-scratch (interp-st->stack interp-st)) :gl-objlist))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world))
      :mutual-recursion gl-interp)))

(defsection stack-bindings-extension-p
  (define gl-bindings-extension-p ((x gl-object-alist-p)
                                   (y gl-object-alist-p))
    (or (gl-object-alist-equiv x y)
        (and (consp x)
             (gl-bindings-extension-p (cdr x) y)))
    ///

    (deffixequiv gl-bindings-extension-p
      :hints(("Goal" :in-theory (enable gl-object-alist-fix))))

    (defthm gl-bindings-extension-p-transitive
      (implies (and (gl-bindings-extension-p x y)
                    (gl-bindings-extension-p y z))
               (gl-bindings-extension-p x z))
      :hints (("Goal" :induct (gl-bindings-extension-p x y))))

    (defthm gl-bindings-extension-p-self
      (gl-bindings-extension-p x x)
      :hints (("goal" :expand ((gl-bindings-extension-p x x))))))


  (define stack-bindings-equiv ((x major-stack-p)
                                (y major-stack-p))
    (b* (((major-frame x1) (car x))
         ((major-frame y1) (car y)))
      (gl-object-alist-equiv x1.bindings y1.bindings))
    ///
    (defequiv stack-bindings-equiv)

    (defrefinement major-stack-equiv stack-bindings-equiv)

    ;; (defthm stack-bindings-equiv-major-frame->bindings-congruence
    ;;   (implies (stack-bindings-equiv x y)
    ;;            (gl-object-alist-equiv (major-frame->bindings (car x))
    ;;                                   (major-frame->bindings (car y))))
    ;;   :rule-classes :congruence)

    (defcong stack-bindings-equiv equal (stack$a-bindings x) 1
      :hints(("Goal" :in-theory (enable stack$a-bindings))))

    (defcong gl-object-alist-equiv stack-bindings-equiv (stack$a-set-bindings bindings x) 1
      :hints(("Goal" :in-theory (enable stack$a-set-bindings))))

    (local (defun def-stack-bindings-equiv-identity-fn (op)
             (let ((fn (car op)))
               `(progn (defthm ,(intern-in-package-of-symbol
                                 (concatenate 'string "STACK-BINDINGS-EQUIV-OF-" (symbol-name fn))
                                 fn)
                         (stack-bindings-equiv ,op stack)
                         :hints(("Goal" :in-theory (enable ,fn))))
                       (defcong stack-bindings-equiv stack-bindings-equiv ,op
                         ,(+ 1 (- (len (cdr op))
                                  (len (member 'stack (cdr op))))))))))

    (local (defmacro def-stack-bindings-equiv-identity (op)
             `(make-event (def-stack-bindings-equiv-identity-fn ',op))))

    (def-stack-bindings-equiv-identity (stack$a-push-minor-frame stack))

    (def-stack-bindings-equiv-identity (stack$a-pop-minor-frame stack))

    (def-stack-bindings-equiv-identity (stack$a-set-debug obj stack))

    (def-stack-bindings-equiv-identity (stack$a-set-minor-debug obj stack))

    (def-stack-bindings-equiv-identity (stack$a-set-minor-bindings bindings stack))

    (def-stack-bindings-equiv-identity (stack$a-add-minor-bindings bindings stack))

    (def-stack-bindings-equiv-identity (stack$a-pop-scratch stack))

    (def-stack-bindings-equiv-identity (stack$a-push-scratch obj stack))

    (def-stack-bindings-equiv-identity (stack$a-update-scratch n obj stack)))

  (define stack-bindings-extension-p ((x major-stack-p)
                                      (y major-stack-p))
    (b* (((major-frame x1) (car x))
         ((major-frame y1) (car y)))
      (gl-bindings-extension-p x1.bindings y1.bindings))
    ///
    (defthmd stack-bindings-extension-p-transitive
      (implies (and (stack-bindings-extension-p x y)
                    (stack-bindings-extension-p y z))
               (stack-bindings-extension-p x z)))

    (defthm stack-bindings-extension-p-self
      (stack-bindings-extension-p x x))

    (def-updater-independence-thm stack-bindings-extension-p-trans-rw
      (implies (and (syntaxp (not (equal old older)))
                    (stack-bindings-extension-p new old)
                    (stack-bindings-extension-p old older))
               (stack-bindings-extension-p new older)))

    (defthm stack-bindings-extension-p-of-stack$a-add-binding
      (stack-bindings-extension-p (stack$a-add-binding var val stack) stack)
      :hints(("Goal" :in-theory (enable stack$a-add-binding
                                        gl-bindings-extension-p))))

    (defcong stack-bindings-equiv equal (stack-bindings-extension-p x y) 1
      :hints(("Goal" :in-theory (enable stack-bindings-equiv))))
    (defcong stack-bindings-equiv equal (stack-bindings-extension-p x y) 2
      :hints(("Goal" :in-theory (enable stack-bindings-equiv))))

    (defret stack-bindings-extension-p-of-gl-interp-syntax-bind
      (implies (equal (major-stack-ev (interp-st->stack new-interp-st) env logicman)
                      (major-stack-ev (interp-st->stack new-interp-st) env (interp-st->logicman new-interp-st)))
               (stack-bindings-extension-p
                (major-stack-ev (interp-st->stack new-interp-st) env logicman)
                (major-stack-ev (interp-st->stack interp-st) env
                                (interp-st->logicman interp-st))))
      :hints(("Goal" :in-theory (enable gl-interp-syntax-bind
                                        stack$a-add-binding
                                        major-stack-ev
                                        major-frame-ev
                                        gl-object-alist-ev
                                        gl-bindings-extension-p)))
      :fn gl-interp-syntax-bind)

    (local (Defthm gl-bindings-extension-p-of-append
             (gl-bindings-extension-p (Append a b) b)
             :hints(("Goal" :in-theory (enable gl-bindings-extension-p append)))))

    (defret stack-bindings-extension-p-of-gl-rewrite-relieve-hyp-synp
      (implies (equal (major-stack-ev (interp-st->stack new-interp-st) env logicman)
                      (major-stack-ev (interp-st->stack new-interp-st) env (interp-st->logicman new-interp-st)))
               (stack-bindings-extension-p
                (major-stack-ev (interp-st->stack new-interp-st) env
                                logicman)
                (major-stack-ev (interp-st->stack interp-st) env
                                (interp-st->logicman interp-st))))
      :hints(("Goal" :in-theory (enable gl-rewrite-relieve-hyp-synp
                                        stack$a-set-bindings
                                        stack$a-bindings
                                        major-stack-ev
                                        major-frame-ev)))
      :fn gl-rewrite-relieve-hyp-synp)

    (def-updater-independence-thm ev-interp-st-stack-bindings-extension-p-trans-rw
      (implies (and (syntaxp (not (equal old older)))
                    (stack-bindings-extension-p
                     (major-stack-ev (interp-st->stack new) env logicman)
                     (major-stack-ev (interp-st->stack old) env
                                     (interp-st->logicman old)))
                    (stack-bindings-extension-p
                     (major-stack-ev (interp-st->stack old) env
                                     (interp-st->logicman old))
                     older))
               (stack-bindings-extension-p
                (major-stack-ev (interp-st->stack new) env logicman) older))
      :hints(("Goal" :in-theory (enable stack-bindings-extension-p-transitive))))))
                        


(defsection gl-interp-stack-bindings-extension
  (local (in-theory (enable stack$a-update-scratch-in-terms-of-push-pop)))

  

  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-stack-bindings-extended
      :formal-hyps (((interp-st-bfr-p x)           (interp-st-bfr-p x))
                    ((gl-object-p x)               (interp-st-bfr-listp (gl-object-bfrlist x)))
                    ((gl-objectlist-p x)           (interp-st-bfr-listp (gl-objectlist-bfrlist x)))
                    (interp-st                     (interp-st-bfrs-ok interp-st))
                    ((constraint-instancelist-p x) (interp-st-bfr-listp (constraint-instancelist-bfrlist x))))
      :rules ((t (:add-concl (stack-bindings-extension-p
                              (major-stack-ev (interp-st->stack new-interp-st)
                                              env
                                              (interp-st->logicman new-interp-st))
                              (major-stack-ev (interp-st->stack interp-st)
                                              env
                                              (interp-st->logicman interp-st))))
                 (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t)))))))
              ((:fnname gl-rewrite-try-rules)
               (:add-hyp (scratchobj-case (stack$a-top-scratch (interp-st->stack interp-st)) :gl-objlist))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world))
      :mutual-recursion gl-interp)))


(define gl-object-alist-eval ((x gl-object-alist-p)
                              (env gl-env-p)
                              &optional (logicman 'logicman))
  :guard (lbfr-listp (gl-object-alist-bfrlist x))
  :guard-hints (("goal" :in-theory (enable gl-object-alist-bfrlist)))
  (if (atom x)
      nil
    (if (mbt (and (consp (car x))
                  (pseudo-var-p (caar x))))
        (cons (cons (caar x) (fgl-object-eval (cdar x) env))
              (gl-object-alist-eval (cdr x) env))
      (gl-object-alist-eval (cdr x) env)))
  ///
  (local (in-theory (enable gl-object-alist-fix))))



(defsection gl-interp-correct
  (local (in-theory (enable stack$a-update-scratch-in-terms-of-push-pop)))

  

  (with-output
    :off (event)
    :evisc (:gag-mode (evisc-tuple 8 10 nil nil) :term nil)
    (std::defret-mutual-generate <fn>-correct
      :formal-hyps (((interp-st-bfr-p x)           (interp-st-bfr-p x))
                    ((gl-object-p x)               (interp-st-bfr-listp (gl-object-bfrlist x)))
                    ((gl-objectlist-p x)           (interp-st-bfr-listp (gl-objectlist-bfrlist x)))
                    (interp-st                     (interp-st-bfrs-ok interp-st))
                    ((constraint-instancelist-p x) (interp-st-bfr-listp (constraint-instancelist-bfrlist x))))
      :rules ((t
               (:add-keyword :hints ('(:do-not-induct t)
                                       (let ((flag (find-flag-is-hyp clause)))
                                         (and flag
                                              (prog2$ (cw "flag: ~x0~%" flag)
                                                      '(:no-op t))))))
               (:add-hyp (not (interp-st->errmsg interp-st)))
               (:add-bindings
                ((new-logicman (interp-st->logicman new-interp-st))
                 (logicman (interp-st->logicman interp-st))
                 (new-stack (interp-st->stack new-interp-st))
                 (stack (interp-st->stack interp-st))
                 (eval-alist (append (gl-object-alist-eval (stack$a-minor-bindings stack) env logicman)
                                     (gl-object-alist-eval (stack$a-bindings new-stack) env new-logicman))))))
              ((:fnname gl-interp-test)
               (iff* (gobj-bfr-eval xbfr env new-logicman)
                     (base-apply-ev x eval-alist)))
              ((or (:fnname gl-interp-term-equivs)
                   (:fnname gl-interp-term))
               (equal (fgl-object-eval xobj env new-logicman)
                      (base-apply-ev x eval-alist)))
              ((:fnname gl-interp-arglist)
               (equal (fgl-objectlist-eval arg-objs env new-logicman)
                      (base-apply-ev-lst x eval-alist)))
              ((:fnname gl-interp-bindinglist)
               (equal (gl-object-alist-eval (stack$a-minor-bindings new-stack) env new-logicman)
                      (append (base-gl-apply-ev-bindinglist bindings eval-alist)
                              (gl-object-alist-eval (stack$a-minor-bindings stack) env logicman))))
              ((:fnname gl-interp-fncall)
               (equal (fgl-object-eval ans env new-logicman)
                      (base-apply-ev (cons fn (kwote-lst
                                               (fgl-object-eval args env logicman)))
                                     nil)))
              ((or (:fnname gl-interp-fn-definition)
                   (:fnname gl-rewrite-fncall))
               (equal (fgl-object-eval ans env new-logicman)
                      (base-apply-ev (cons fn (kwote-lst
                                               (fgl-object-eval args env logicman)))
                                     nil)))
              ((:fnname gl-rewrite-try-rules)
               (:add-hyp (scratchobj-case (stack$a-top-scratch (interp-st->stack interp-st)) :gl-objlist))))
      :hints ((acl2::just-expand-mrec-default-hint 'gl-interp-term id nil world))
      :mutual-recursion gl-interp)))




