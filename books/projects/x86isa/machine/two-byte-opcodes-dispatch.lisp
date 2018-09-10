; X86ISA Library

; Note: The license below is based on the template at:
; http://opensource.org/licenses/BSD-3-Clause

; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/

; Copyright (C) 2018, Centaur Technology, Inc.
; All rights reserved.

; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are
; met:

; o Redistributions of source code must retain the above copyright
;   notice, this list of conditions and the following disclaimer.

; o Redistributions in binary form must reproduce the above copyright
;   notice, this list of conditions and the following disclaimer in the
;   documentation and/or other materials provided with the distribution.

; o Neither the name of the copyright holders nor the names of its
;   contributors may be used to endorse or promote products derived
;   from this software without specific prior written permission.

; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
; HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

; Original Author(s):
; Shilpi Goel         <shilpi@centtech.com>

(in-package "X86ISA")

(include-book "three-byte-opcodes-dispatch"
	      :ttags (:include-raw :syscall-exec :other-non-det :undef-flg))

(local (include-book "dispatch-utils"))
(local (include-book "centaur/bitops/ihs-extensions" :dir :system))
(local (include-book "centaur/bitops/signed-byte-p" :dir :system))

(local (in-theory (e/d ()
		       (app-view-rml08-no-error
			(:meta acl2::mv-nth-cons-meta)
			rme08-value-when-error
			member-equal))))

(local (xdoc::set-default-parents x86-decoder))

;; ----------------------------------------------------------------------


;; Increasing the rewrite stack limit to help the guard proof go through; note
;; that this is local to this book.
(set-rewrite-stack-limit (+ 6000 acl2::*default-rewrite-stack-limit*))

;; ----------------------------------------------------------------------

(local
 (defthm unsigned-byte-p-1-of-logbit
   (unsigned-byte-p 1 (logbit i x))))

(make-event
 (b* (((mv table-doc-string dispatch)
       (create-dispatch-from-opcode-map
	*two-byte-opcode-map-lst*
	(w state)
	:escape-bytes #ux0F_00)))

   `(progn
      (define two-byte-opcode-execute
	((proc-mode        :type (integer 0 #.*num-proc-modes-1*))
	 (start-rip        :type (signed-byte   #.*max-linear-address-size*))
	 (temp-rip         :type (signed-byte   #.*max-linear-address-size*))
	 (prefixes         :type (unsigned-byte #.*prefixes-width*))
	 (mandatory-prefix :type (unsigned-byte 8))
	 (rex-byte         :type (unsigned-byte 8))
	 (opcode           :type (unsigned-byte 8))
	 (modr/m           :type (unsigned-byte 8))
	 (sib              :type (unsigned-byte 8))
	 x86)

	:parents (x86-decoder)
	;; The following arg will avoid binding __function__ to
	;; two-byte-opcode-execute. The automatic __function__ binding that comes
	;; with define causes stack overflows during the guard proof of this
	;; function.
	:no-function t

	:short "Two-byte opcode dispatch function."
	:long "<p>@('two-byte-opcode-execute') is the doorway to the two-byte
     opcode map, and will lead to the three-byte opcode map if @('opcode') is
     either @('#x38') or @('#x3A').</p>"
	:guard (and (prefixes-p prefixes)
		    (modr/m-p modr/m)
		    (sib-p sib))
	:guard-hints (("Goal"
		       :do-not '(preprocess)
		       :in-theory (e/d (member-equal)
				       (logbit
					bitops::logbit-to-logbitp
					unsigned-byte-p
					(:t unsigned-byte-p)
					signed-byte-p))))

	(case opcode ,@dispatch)

	///

	(defthm x86p-two-byte-opcode-execute
	  (implies (and (x86p x86)
			(canonical-address-p temp-rip))
		   (x86p (two-byte-opcode-execute
			  proc-mode start-rip temp-rip prefixes mandatory-prefix
			  rex-byte opcode modr/m sib x86)))))

      (defsection two-byte-opcodes-table
	:parents (implemented-opcodes)
	:short "@('x86isa') Support for Opcodes in the Two-Byte Map (i.e.,
	first opcode byte is 0x0F); see @(see implemented-opcodes) for details."
	:long ,table-doc-string))))

(define two-byte-opcode-decode-and-execute
  ((proc-mode     :type (integer 0 #.*num-proc-modes-1*))
   (start-rip     :type (signed-byte #.*max-linear-address-size*))
   (temp-rip      :type (signed-byte #.*max-linear-address-size*))
   (prefixes      :type (unsigned-byte #.*prefixes-width*))
   (rex-byte      :type (unsigned-byte 8))
   (escape-byte   :type (unsigned-byte 8))
   x86)

  :ignore-ok t
  :guard (and (prefixes-p prefixes)
	      (equal escape-byte #x0F))
  :guard-hints (("Goal" :do-not '(preprocess)
		 :in-theory (e/d*
			     (add-to-*ip
			      modr/m-p
			      add-to-*ip-is-i48p-rewrite-rule)
			     (unsigned-byte-p
			      (:type-prescription bitops::logand-natp-type-2)
			      (:type-prescription bitops::ash-natp-type)
			      acl2::loghead-identity
			      not
			      tau-system
			      (tau-system)))))
  :parents (x86-decoder)
  :short "Decoder and dispatch function for two-byte opcodes"
  :long "<p>Source: Intel Manual, Volume 2, Appendix A-2</p>"

  (b* ((ctx 'two-byte-opcode-decode-and-execute)

       ((mv flg0 (the (unsigned-byte 8) opcode) x86)
	(rme08 proc-mode temp-rip #.*cs* :x x86))
       ((when flg0)
	(!!ms-fresh :opcode-byte-access-error flg0))

       ;; Possible values of opcode:

       ;; 1. #x38 and #x3A: These are escapes to the two three-byte opcode
       ;;    maps.  Function three-byte-opcode-decode-and-execute is called
       ;;    here, which also fetches the ModR/M and SIB bytes for these
       ;;    opcodes.

       ;; 2. All other values denote opcodes of the two-byte map.  The function
       ;;    two-byte-opcode-execute case-splits on this opcode byte and calls
       ;;    the appropriate instruction semantic function.

       ((mv flg temp-rip) (add-to-*ip proc-mode temp-rip 1 x86))
       ((when flg) (!!ms-fresh :increment-error flg))

       ((mv msg (the (unsigned-byte 8) mandatory-prefix))
	(compute-mandatory-prefix-for-two-byte-opcode
	 proc-mode opcode prefixes))
       ((when msg)
	(x86-illegal-instruction msg start-rip temp-rip x86))

       (modr/m?
	(two-byte-opcode-ModR/M-p
	 proc-mode mandatory-prefix opcode))
       ((mv flg1 (the (unsigned-byte 8) modr/m) x86)
	(if modr/m?
	    (rme08 proc-mode temp-rip #.*cs* :x x86)
	  (mv nil 0 x86)))
       ((when flg1) (!!ms-fresh :modr/m-byte-read-error flg1))

       ((mv flg temp-rip) (if modr/m?
			      (add-to-*ip proc-mode temp-rip 1 x86)
			    (mv nil temp-rip)))
       ((when flg) (!!ms-fresh :increment-error flg))

       (sib? (and modr/m?
		  (b* ((p4? (eql #.*addr-size-override*
				 (the (unsigned-byte 8) (prefixes->adr prefixes))))
		       (16-bit-addressp (eql 2 (select-address-size proc-mode p4? x86))))
		    (x86-decode-SIB-p modr/m 16-bit-addressp))))
       ((mv flg2 (the (unsigned-byte 8) sib) x86)
	(if sib?
	    (rme08 proc-mode temp-rip #.*cs* :x x86)
	  (mv nil 0 x86)))
       ((when flg2)
	(!!ms-fresh :sib-byte-read-error flg2))

       ((mv flg temp-rip) (if sib?
			      (add-to-*ip proc-mode temp-rip 1 x86)
			    (mv nil temp-rip)))
       ((when flg) (!!ms-fresh :increment-error flg)))

    (two-byte-opcode-execute
     proc-mode start-rip temp-rip prefixes mandatory-prefix
     rex-byte opcode modr/m sib x86))

  ///

  (defrule x86p-two-byte-opcode-decode-and-execute
    (implies (and (canonical-address-p temp-rip)
		  (x86p x86))
	     (x86p (two-byte-opcode-decode-and-execute
		    proc-mode start-rip temp-rip prefixes
		    rex-byte escape-byte x86)))
    :enable add-to-*ip-is-i48p-rewrite-rule
    :disable signed-byte-p))

;; ----------------------------------------------------------------------
