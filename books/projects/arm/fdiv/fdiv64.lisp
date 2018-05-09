(IN-PACKAGE "RTL")

(INCLUDE-BOOK "rtl/rel11/lib/rac" :DIR :SYSTEM)

(SET-IGNORE-OK T)

(SET-IRRELEVANT-FORMALS-OK T)

(DEFUN RMODENEAR NIL (BITS 0 1 0))

(DEFUN RMODEUP NIL (BITS 1 1 0))

(DEFUN RMODEDN NIL (BITS 2 1 0))

(DEFUN RMODEZERO NIL (BITS 3 1 0))

(DEFUN IDC NIL 7)

(DEFUN IXC NIL 4)

(DEFUN UFC NIL 3)

(DEFUN OFC NIL 2)

(DEFUN DZC NIL 1)

(DEFUN IOC NIL 0)

(DEFUN
 ANALYZE (OP FMT FZ FLAGS)
 (LET
  ((SIGN 0)
   (EXP 0)
   (MAN 0)
   (MANMSB 0)
   (EXPISMAX 0))
  (MV-LET
     (SIGN EXP EXPISMAX MAN MANMSB)
     (CASE FMT
           (2 (LET ((SIGN (BITN OP 63))
                    (EXP (BITS OP 62 52)))
                   (MV SIGN EXP (LOG= (SI EXP 13) 2047)
                       (BITS OP 51 0)
                       (BITS 2251799813685248 51 0))))
           (1 (LET ((SIGN (BITN OP 31))
                    (EXP (BITS OP 30 23)))
                   (MV SIGN EXP (LOG= (SI EXP 13) 255)
                       (BITS OP 22 0)
                       (BITS 4194304 51 0))))
           (0 (LET ((SIGN (BITN OP 15))
                    (EXP (BITS OP 14 10)))
                   (MV SIGN EXP (LOG= (SI EXP 13) 31)
                       (BITS OP 9 0)
                       (BITS 512 51 0))))
           (T (MV SIGN EXP EXPISMAX MAN MANMSB)))
     (LET ((C 0))
          (MV-LET (FLAGS C)
                  (IF1 EXPISMAX
                       (MV FLAGS
                           (IF1 (LOG= MAN 0)
                                1 (IF1 (LOGAND MAN MANMSB) 3 2)))
                       (IF1 (LOG= (SI EXP 13) 0)
                            (IF1 (LOG= MAN 0)
                                 (MV FLAGS 0)
                                 (MV-LET (C FLAGS)
                                         (IF1 FZ
                                              (MV 0
                                                  (IF1 (LOG<> FMT 0)
                                                       (SETBITN FLAGS 8 (IDC) 1)
                                                       FLAGS))
                                              (MV 5 FLAGS))
                                         (MV FLAGS C)))
                            (MV FLAGS 4)))
                  (MV SIGN (BITS (SI EXP 13) 10 0)
                      MAN C FLAGS))))))

(DEFUN CLZ53-LOOP-0 (I N K C Z)
       (DECLARE (XARGS :MEASURE (NFIX (- N I))))
       (IF (AND (INTEGERP I) (INTEGERP N) (< I N))
           (LET* ((C (AS I
                         (BITS (IF1 (AG (+ (* 2 I) 1) Z)
                                    (AG (* 2 I) C)
                                    (AG (+ (* 2 I) 1) C))
                               5 0)
                         C))
                  (C (AS I
                         (SETBITN (AG I C)
                                  6 K (AG (+ (* 2 I) 1) Z))
                         C))
                  (Z (AS I
                         (LOGAND1 (AG (+ (* 2 I) 1) Z)
                                  (AG (* 2 I) Z))
                         Z)))
                 (CLZ53-LOOP-0 (+ I 1) N K C Z))
           (MV C Z)))

(DEFUN CLZ53-LOOP-1 (K N C Z)
       (DECLARE (XARGS :MEASURE (NFIX (- 6 K))))
       (IF (AND (INTEGERP K) (INTEGERP 6) (< K 6))
           (LET ((N (FLOOR N 2)))
                (MV-LET (C Z)
                        (CLZ53-LOOP-0 0 N K C Z)
                        (CLZ53-LOOP-1 (+ K 1) N C Z)))
           (MV N C Z)))

(DEFUN CLZ53-LOOP-2 (I X Z C)
       (DECLARE (XARGS :MEASURE (NFIX (- 64 I))))
       (IF (AND (INTEGERP I)
                (INTEGERP 64)
                (< I 64))
           (LET ((Z (AS I (LOGNOT1 (BITN X I)) Z))
                 (C (AS I (BITS 0 5 0) C)))
                (CLZ53-LOOP-2 (+ I 1) X Z C))
           (MV Z C)))

(DEFUN CLZ53 (S)
       (LET* ((X (BITS 0 63 0))
              (X (SETBITS X 64 63 11 S))
              (Z NIL)
              (C NIL))
             (MV-LET (Z C)
                     (CLZ53-LOOP-2 0 X Z C)
                     (LET ((N 64))
                          (MV-LET (N C Z)
                                  (CLZ53-LOOP-1 0 N C Z)
                                  (AG 0 C))))))

(DEFUN
   COMPUTEQ (QP QN RP RN FMT ISSQRT)
   (LET* ((REM (BITS (+ (+ RP (LOGNOT RN)) 1) 58 0))
          (REMSIGN (BITN REM 58))
          (REMZERO (LOG= (LOGXOR RP RN) 0))
          (CIN (LOGNOT1 REMSIGN))
          (LSBIS2 (LOG= ISSQRT (LOG= FMT 1)))
          (INC (BITS (IF1 LSBIS2 4 2) 2 0))
          (Q0 (BITS (+ QP (LOGNOT QN)) 53 0))
          (QN1INC (BITS (LOGXOR (LOGXOR QP (BITS (LOGNOT QN) 53 0))
                                INC)
                        53 0))
          (QP1INC (BITS (ASH (LOGIOR (LOGAND QP (BITS (LOGNOT QN) 53 0))
                                     (LOGAND (LOGIOR QP (BITS (LOGNOT QN) 53 0))
                                             INC))
                             1)
                        53 0))
          (Q1INC (BITS (+ (+ QP1INC QN1INC) 1) 53 0))
          (Q1LOW (BITS (+ (+ (BITS QP 2 0) (LOGNOT (BITS QN 2 0)))
                          1)
                       2 0))
          (Q0INCLOW (BITS (+ (BITS QP1INC 2 0) (BITS QN1INC 2 0))
                          2 0))
          (Q1 Q1LOW)
          (Q0INC Q0INCLOW)
          (Q1 (IF1 (LOG= Q1 0)
                   (SETBITS Q1 54 53 3 (BITS Q1INC 53 3))
                   (SETBITS Q1 54 53 3 (BITS Q0 53 3))))
          (Q0INC (IF1 (LOGIOR1 (LOG<= Q0INC 1)
                               (LOGAND1 (LOG<= Q0INC 3) LSBIS2))
                      (SETBITS Q0INC 54 53 3 (BITS Q1INC 53 3))
                      (SETBITS Q0INC 54 53 3 (BITS Q0 53 3))))
          (Q01 (BITS (IF1 CIN Q1 Q0) 53 0))
          (Q01INC (BITS (IF1 CIN Q1INC Q0INC) 53 0)))
         (MV (BITS (IF1 LSBIS2 (ASH Q01 (- 1)) Q01)
                   52 0)
             (BITS (IF1 LSBIS2 (ASH Q01INC (- 1)) Q01INC)
                   52 0)
             (LOGNOT1 REMZERO))))

(DEFUN RSHFT64 (X S)
       (LET ((XS (BITS (ASH X (- S)) 63 0)))
            (MV XS (LOG<> X (ASH XS S)))))

(DEFUN
 ROUNDER
 (QTRUNC QINC STK SIGN EXPQ RMODE FMT)
 (LET*
  ((LSB (BITN QTRUNC 1))
   (GRD (BITN QTRUNC 0))
   (QRND 0)
   (QRND (IF1 (LOGIOR1 (LOGIOR1 (LOGAND1 (LOGAND1 (LOG= RMODE (RMODENEAR)) GRD)
                                         (LOGIOR1 LSB STK))
                                (LOGAND1 (LOGAND1 (LOG= RMODE (RMODEUP))
                                                  (LOGNOT1 SIGN))
                                         (LOGIOR1 GRD STK)))
                       (LOGAND1 (LOGAND1 (LOG= RMODE (RMODEDN)) SIGN)
                                (LOGIOR1 GRD STK)))
              (BITS QINC 53 1)
              (BITS QTRUNC 53 1)))
   (INX (LOGIOR1 GRD STK))
   (QDEN (BITS 0 63 0))
   (QDEN (CASE FMT
               (2 (LET ((QDEN (SETBITN QDEN 64 53 1)))
                       (SETBITS QDEN 64 52 0 (BITS QTRUNC 52 0))))
               (1 (LET ((QDEN (SETBITN QDEN 64 24 1)))
                       (SETBITS QDEN 64 23 0 (BITS QTRUNC 23 0))))
               (0 (LET ((QDEN (SETBITN QDEN 64 11 1)))
                       (SETBITS QDEN 64 10 0 (BITS QTRUNC 10 0))))
               (T QDEN)))
   (SHFT12 (BITS (- 1 (SI EXPQ 13)) 11 0))
   (SHFT (BITS (IF1 (LOG>= SHFT12 64) 63 SHFT12)
               5 0))
   (LSBDEN 0)
   (GRDDEN 0)
   (STKDEN 0)
   (QSHFT 0))
  (MV-LET
   (QSHFT STKDEN)
   (RSHFT64 QDEN SHFT)
   (LET
     ((LSBDEN (BITN QSHFT 1))
      (GRDDEN (BITN QSHFT 0))
      (STKDEN (LOGIOR1 STKDEN STK))
      (QRNDDEN 0))
     (MV QRND INX
         (BITS (IF1 (LOGIOR1 (LOGIOR1 (LOGAND1 (LOGAND1 (LOG= RMODE (RMODENEAR))
                                                        GRDDEN)
                                               (LOGIOR1 LSBDEN STKDEN))
                                      (LOGAND1 (LOGAND1 (LOG= RMODE (RMODEUP))
                                                        (LOGNOT1 SIGN))
                                               (LOGIOR1 GRDDEN STKDEN)))
                             (LOGAND1 (LOGAND1 (LOG= RMODE (RMODEDN)) SIGN)
                                      (LOGIOR1 GRDDEN STKDEN)))
                    (BITS (+ (BITS QSHFT 53 1) 1) 53 0)
                    (BITS QSHFT 53 1))
               52 0)
         (LOGIOR1 GRDDEN STKDEN))))))

(DEFUN
 FINAL
 (QRND INX QRNDDEN
       INXDEN SIGN EXPQ RMODE FZ FMT FLAGS)
 (LET
  ((SELMAXNORM (LOGIOR1 (LOGIOR1 (LOGAND1 (LOG= RMODE (RMODEDN))
                                          (LOGNOT1 SIGN))
                                 (LOGAND1 (LOG= RMODE (RMODEUP)) SIGN))
                        (LOG= RMODE (RMODEZERO))))
   (D (BITS 0 63 0)))
  (CASE
   FMT
   (2
    (LET
     ((D (SETBITN D 64 63 SIGN)))
     (IF1
         (LOG>= (SI EXPQ 13) 2047)
         (MV (IF1 SELMAXNORM
                  (LET ((D (SETBITS D 64 62 52 2046)))
                       (SETBITS D 64 51 0 4503599627370495))
                  (LET ((D (SETBITS D 64 62 52 2047)))
                       (SETBITS D 64 51 0 0)))
             (SETBITN (SETBITN FLAGS 8 (OFC) 1)
                      8 (IXC)
                      1))
         (IF1 (LOG<= (SI EXPQ 13) 0)
              (IF1 FZ (MV D (SETBITN FLAGS 8 (UFC) 1))
                   (LET* ((EXP (BITN QRNDDEN 52))
                          (D (SETBITS D 64 62 52 EXP))
                          (D (SETBITS D 64 51 0 (BITS QRNDDEN 51 0)))
                          (FLAGS (SETBITN FLAGS 8 (IXC)
                                          (LOGIOR1 (BITN FLAGS (IXC)) INXDEN))))
                         (MV D
                             (SETBITN FLAGS 8 (UFC)
                                      (LOGIOR1 (BITN FLAGS (UFC)) INXDEN)))))
              (MV (SETBITS (SETBITS D 64 62 52 (SI EXPQ 13))
                           64 51 0 (BITS QRND 51 0))
                  (SETBITN FLAGS 8 (IXC)
                           (LOGIOR1 (BITN FLAGS (IXC)) INX)))))))
   (1
    (LET
     ((D (SETBITN D 64 31 SIGN)))
     (IF1
         (LOG>= (SI EXPQ 13) 255)
         (MV (IF1 SELMAXNORM
                  (LET ((D (SETBITS D 64 30 23 254)))
                       (SETBITS D 64 22 0 8388607))
                  (LET ((D (SETBITS D 64 30 23 255)))
                       (SETBITS D 64 22 0 0)))
             (SETBITN (SETBITN FLAGS 8 (OFC) 1)
                      8 (IXC)
                      1))
         (IF1 (LOG<= (SI EXPQ 13) 0)
              (IF1 FZ (MV D (SETBITN FLAGS 8 (UFC) 1))
                   (LET* ((EXP (BITN QRNDDEN 23))
                          (D (SETBITS D 64 30 23 EXP))
                          (D (SETBITS D 64 22 0 (BITS QRNDDEN 22 0)))
                          (FLAGS (SETBITN FLAGS 8 (IXC)
                                          (LOGIOR1 (BITN FLAGS (IXC)) INXDEN))))
                         (MV D
                             (SETBITN FLAGS 8 (UFC)
                                      (LOGIOR1 (BITN FLAGS (UFC)) INXDEN)))))
              (MV (SETBITS (SETBITS D 64 30 23 (SI EXPQ 13))
                           64 22 0 (BITS QRND 22 0))
                  (SETBITN FLAGS 8 (IXC)
                           (LOGIOR1 (BITN FLAGS (IXC)) INX)))))))
   (0
    (LET
     ((D (SETBITN D 64 15 SIGN)))
     (IF1
         (LOG>= (SI EXPQ 13) 31)
         (MV (IF1 SELMAXNORM
                  (LET ((D (SETBITS D 64 14 10 30)))
                       (SETBITS D 64 9 0 1023))
                  (LET ((D (SETBITS D 64 14 10 31)))
                       (SETBITS D 64 9 0 0)))
             (SETBITN (SETBITN FLAGS 8 (OFC) 1)
                      8 (IXC)
                      1))
         (IF1 (LOG<= (SI EXPQ 13) 0)
              (IF1 FZ (MV D (SETBITN FLAGS 8 (UFC) 1))
                   (LET* ((EXP (BITN QRNDDEN 10))
                          (D (SETBITS D 64 14 10 EXP))
                          (D (SETBITS D 64 9 0 (BITS QRNDDEN 9 0)))
                          (FLAGS (SETBITN FLAGS 8 (IXC)
                                          (LOGIOR1 (BITN FLAGS (IXC)) INXDEN))))
                         (MV D
                             (SETBITN FLAGS 8 (UFC)
                                      (LOGIOR1 (BITN FLAGS (UFC)) INXDEN)))))
              (MV (SETBITS (SETBITS D 64 14 10 (SI EXPQ 13))
                           64 9 0 (BITS QRND 9 0))
                  (SETBITN FLAGS 8 (IXC)
                           (LOGIOR1 (BITN FLAGS (IXC)) INX)))))))
   (T (MV D FLAGS)))))

(DEFUN
 SPECIALCASE
 (SIGN OPA OPB CLASSA CLASSB FMT DN FLAGS)
 (LET
  ((ISSPECIAL (FALSE$))
   (D (BITS 0 63 0))
   (ANAN 0)
   (BNAN 0)
   (MANMSB 0)
   (INFINITY 0)
   (DEFNAN 0)
   (ZERO (BITS 0 63 0)))
  (MV-LET
   (ANAN BNAN ZERO INFINITY MANMSB)
   (CASE FMT
         (2 (MV (BITS OPA 63 0)
                (BITS OPB 63 0)
                (SETBITN ZERO 64 63 SIGN)
                (BITS 9218868437227405312 63 0)
                (BITS 2251799813685248 63 0)))
         (1 (MV (BITS OPA 31 0)
                (BITS OPB 31 0)
                (SETBITN ZERO 64 31 SIGN)
                (BITS 2139095040 63 0)
                (BITS 4194304 63 0)))
         (0 (MV (BITS OPA 15 0)
                (BITS OPB 15 0)
                (SETBITN ZERO 64 15 SIGN)
                (BITS 31744 63 0)
                (BITS 512 63 0)))
         (T (MV ANAN BNAN ZERO INFINITY MANMSB)))
   (LET
    ((DEFNAN (LOGIOR INFINITY MANMSB)))
    (IF1
     (LOG= CLASSA 2)
     (MV (BITS (IF1 DN DEFNAN (LOGIOR ANAN MANMSB))
               63 0)
         (SETBITN FLAGS 8 (IOC) 1))
     (IF1
      (LOG= CLASSB 2)
      (MV (BITS (IF1 DN DEFNAN (LOGIOR BNAN MANMSB))
                63 0)
          (SETBITN FLAGS 8 (IOC) 1))
      (MV-LET
       (FLAGS D)
       (IF1
        (LOG= CLASSA 3)
        (MV FLAGS (BITS (IF1 DN DEFNAN ANAN) 63 0))
        (IF1
         (LOG= CLASSB 3)
         (MV FLAGS (BITS (IF1 DN DEFNAN BNAN) 63 0))
         (MV-LET
          (D FLAGS)
          (IF1
            (LOG= CLASSA 1)
            (IF1 (LOG= CLASSB 1)
                 (MV DEFNAN (SETBITN FLAGS 8 (IOC) 1))
                 (MV (LOGIOR INFINITY ZERO) FLAGS))
            (MV-LET (FLAGS D)
                    (IF1 (LOG= CLASSB 1)
                         (MV FLAGS ZERO)
                         (MV-LET (D FLAGS)
                                 (IF1 (LOG= CLASSA 0)
                                      (IF1 (LOG= CLASSB 0)
                                           (MV DEFNAN (SETBITN FLAGS 8 (IOC) 1))
                                           (MV ZERO FLAGS))
                                      (IF1 (LOG= CLASSB 0)
                                           (MV (LOGIOR INFINITY ZERO)
                                               (SETBITN FLAGS 8 (DZC) 1))
                                           (MV D FLAGS)))
                                 (MV FLAGS D)))
                    (MV D FLAGS)))
          (MV FLAGS D))))
       (MV D FLAGS))))))))

(DEFUN
 NORMALIZE (EXPA EXPB MANA MANB FMT)
 (LET
    ((SIGA (BITS 0 52 0))
     (SIGB (BITS 0 52 0))
     (BIAS 0))
    (MV-LET
         (SIGA SIGB BIAS)
         (CASE FMT (2 (MV MANA MANB 1023))
               (1 (MV (SETBITS SIGA 53 51 29 MANA)
                      (SETBITS SIGB 53 51 29 MANB)
                      127))
               (0 (MV (SETBITS SIGA 53 51 42 MANA)
                      (SETBITS SIGB 53 51 42 MANB)
                      15))
               (T (MV SIGA SIGB BIAS)))
         (LET ((EXPASHFT 0) (EXPBSHFT 0))
              (MV-LET (SIGA EXPASHFT)
                      (IF1 (LOG= EXPA 0)
                           (LET ((CLZ (BITS (CLZ53 SIGA) 5 0)))
                                (MV (BITS (ASH SIGA CLZ) 52 0)
                                    (BITS (- 1 CLZ) 12 0)))
                           (MV (SETBITN SIGA 53 52 1) EXPA))
                      (MV-LET (SIGB EXPBSHFT)
                              (IF1 (LOG= EXPB 0)
                                   (LET ((CLZ (BITS (CLZ53 SIGB) 5 0)))
                                        (MV (BITS (ASH SIGB CLZ) 52 0)
                                            (BITS (- 1 CLZ) 12 0)))
                                   (MV (SETBITN SIGB 53 52 1) EXPB))
                              (MV SIGA SIGB
                                  (BITS (+ (- (SI EXPASHFT 13) (SI EXPBSHFT 13))
                                           BIAS)
                                        12 0))))))))

(DEFUN
 PRESCALE (SIGA SIGB EXPDIFF)
 (LET*
    ((DIV1 0)
     (DIV2 0)
     (DIV3 0)
     (DIVSUM 0)
     (DIVCAR 0)
     (DIV1 (IF1 (LOGAND1 (LOGNOT1 (BITN SIGB 51))
                         (LOGIOR1 (BITN SIGB 50)
                                  (LOGNOT1 (BITN SIGB 49))))
                (BITS (ASH SIGB 2) 55 0)
                (IF1 (LOGAND1 (LOGNOT1 (BITN SIGB 50))
                              (LOGIOR1 (BITN SIGB 51) (BITN SIGB 49)))
                     (BITS (ASH SIGB 1) 55 0)
                     (BITS 0 55 0))))
     (DIV2 (IF1 (LOGAND1 (LOGNOT1 (BITN SIGB 51))
                         (LOGNOT1 (BITN SIGB 50)))
                (BITS (ASH SIGB 2) 55 0)
                (IF1 (LOGIOR1 (LOGAND1 (LOGIOR1 (BITN SIGB 51) (BITN SIGB 50))
                                       (LOGNOT1 (BITN SIGB 49)))
                              (LOGAND1 (BITN SIGB 51) (BITN SIGB 50)))
                     SIGB (BITS 0 55 0))))
     (DIV3 (BITS (ASH SIGB 3) 55 0))
     (DIVSUM (LOGXOR (LOGXOR DIV1 DIV2) DIV3))
     (DIVCAR (BITS (ASH (LOGIOR (LOGIOR (LOGAND DIV1 DIV2)
                                        (LOGAND DIV1 DIV3))
                                (LOGAND DIV2 DIV3))
                        1)
                   55 0))
     (DIV (BITS (+ DIVSUM DIVCAR) 56 0))
     (REM1 0)
     (REM2 0)
     (REM3 0)
     (REMSUM 0)
     (REMCAR 0)
     (REM1 (IF1 (LOGAND1 (LOGNOT1 (BITN SIGB 51))
                         (LOGIOR1 (BITN SIGB 50)
                                  (LOGNOT1 (BITN SIGB 49))))
                (BITS (ASH SIGA 2) 55 0)
                (IF1 (LOGAND1 (LOGNOT1 (BITN SIGB 50))
                              (LOGIOR1 (BITN SIGB 51) (BITN SIGB 49)))
                     (BITS (ASH SIGA 1) 55 0)
                     (BITS 0 55 0))))
     (REM2 (IF1 (LOGAND1 (LOGNOT1 (BITN SIGB 51))
                         (LOGNOT1 (BITN SIGB 50)))
                (BITS (ASH SIGA 2) 55 0)
                (IF1 (LOGIOR1 (LOGAND1 (LOGIOR1 (BITN SIGB 51) (BITN SIGB 50))
                                       (LOGNOT1 (BITN SIGB 49)))
                              (LOGAND1 (BITN SIGB 51) (BITN SIGB 50)))
                     SIGA (BITS 0 55 0))))
     (REM3 (BITS (ASH SIGA 3) 55 0))
     (REMSUM (LOGXOR (LOGXOR REM1 REM2) REM3))
     (REMCAR (BITS (ASH (LOGIOR (LOGIOR (LOGAND REM1 REM2)
                                        (LOGAND REM1 REM3))
                                (LOGAND REM2 REM3))
                        1)
                   55 0))
     (SIGABAR (BITS (LOGNOT SIGA) 52 0))
     (SIGCMP (BITS (+ SIGB SIGABAR) 53 0))
     (SIGALTSIGB (BITN SIGCMP 53))
     (REMCARBITS 0)
     (REMSUMBITS 0)
     (REMCIN 0))
    (MV-LET
         (REMCARBITS REMSUMBITS REMCIN)
         (IF1 SIGALTSIGB
              (MV (BITS REMCAR 55 52)
                  (BITS REMSUM 55 52)
                  (LOGIOR1 (BITN REMCAR 51)
                           (BITN REMSUM 51)))
              (MV (BITS REMCAR 55 53)
                  (BITS REMSUM 55 53)
                  (LOGIOR1 (BITN REMCAR 52)
                           (BITN REMSUM 52))))
         (LET* ((REMBITS (BITS (+ (+ REMCARBITS REMSUMBITS) REMCIN)
                               4 0))
                (Q1 (IF1 (LOGIOR1 (BITN REMBITS 4)
                                  (LOGAND1 (BITN REMBITS 3)
                                           (LOGAND (BITN REMBITS 2)
                                                   (LOGIOR1 (BITN REMBITS 1)
                                                            (BITN REMBITS 0)))))
                         2 1))
                (RP (BITS (+ REMSUM REMCAR) 58 0)))
               (MV-LET (RP EXPDIFF)
                       (IF1 SIGALTSIGB
                            (MV (BITS (ASH RP 1) 58 0)
                                (BITS (- (SI EXPDIFF 13) 1) 12 0))
                            (MV RP EXPDIFF))
                       (LET ((RN (BITS 0 58 0)))
                            (MV DIV RP
                                (IF1 (LOG= Q1 2)
                                     (SETBITS RN 59 57 1 DIV)
                                     (SETBITS RN 59 56 0 DIV))
                                EXPDIFF Q1)))))))

(DEFUN
 NEXTDIGIT (REMS6)
 (IF1
  (LOGAND1 (LOGNOT1 (BITN REMS6 5))
           (LOGIOR1 (BITN REMS6 4)
                    (LOGAND1 (LOGAND1 (BITN REMS6 3) (BITN REMS6 2))
                             (LOGIOR1 (BITN REMS6 1)
                                      (BITN REMS6 0)))))
  2
  (IF1
   (LOGAND1 (LOGNOT1 (BITN REMS6 5))
            (LOGIOR1 (BITN REMS6 3) (BITN REMS6 2)))
   1
   (IF1
     (LOGIOR1 (LOGNOT1 (BITN REMS6 5))
              (LOGAND1 (LOGAND1 (LOGAND1 (LOGAND1 (BITN REMS6 5) (BITN REMS6 4))
                                         (BITN REMS6 3))
                                (BITN REMS6 2))
                       (LOGIOR1 (BITN REMS6 1)
                                (BITN REMS6 0))))
     0
     (IF1 (LOGAND1 (BITN REMS6 4)
                   (LOGIOR1 (BITN REMS6 3) (BITN REMS6 2)))
          -1 -2)))))

(DEFUN NEXTREM (RP RN DIV Q FMT)
       (LET* ((DIVMULT DIV)
              (DIVMULT (CASE Q
                             (2 (LET ((DIVMULT (BITS (ASH DIVMULT 1) 58 0)))
                                     (BITS (LOGNOT DIVMULT) 58 0)))
                             (1 (BITS (LOGNOT DIVMULT) 58 0))
                             (0 (BITS 0 58 0))
                             (-1 DIVMULT)
                             (-2 (BITS (ASH DIVMULT 1) 58 0))
                             (T DIVMULT)))
              (RP4 (BITS (ASH RP 2) 58 0))
              (RN4 (BITS (ASH RN 2) 58 0))
              (SUM (LOGXOR (LOGXOR RN4 RP4) DIVMULT))
              (CARRY (LOGIOR (LOGAND (BITS (LOGNOT RN4) 58 0) RP4)
                             (LOGAND (LOGIOR (BITS (LOGNOT RN4) 58 0) RP4)
                                     DIVMULT)))
              (CARRY (BITS (ASH CARRY 1) 58 0)))
             (CASE FMT
                   (2 (MV (SETBITN CARRY 59 0 (LOG> Q 0))
                          SUM))
                   (1 (MV (SETBITN (SETBITS RP 59 58 29 (BITS CARRY 58 29))
                                   59 29 (LOG> Q 0))
                          (SETBITS RN 59 58 29 (BITS SUM 58 29))))
                   (0 (MV (SETBITN (SETBITS RP 59 58 42 (BITS CARRY 58 42))
                                   59 42 (LOG> Q 0))
                          (SETBITS RN 59 58 42 (BITS SUM 58 42))))
                   (T (MV RP RN)))))

(DEFUN NEXTQUOT (QP QN Q)
       (LET ((QP (BITS (ASH QP 2) 53 0))
             (QN (BITS (ASH QN 2) 53 0)))
            (MV-LET (QN QP)
                    (IF1 (LOG>= Q 0)
                         (MV QN (SETBITS QP 54 1 0 Q))
                         (MV (SETBITS QN 54 1 0 (- Q)) QP))
                    (MV QP QN))))

(DEFUN ITER1 (RPI RNI DIV FMT)
       (LET* ((RIS6 (BITS (+ (+ (BITS RPI 56 51)
                                (LOGNOT (BITS RNI 56 51)))
                             1)
                          5 0))
              (QI1 (NEXTDIGIT RIS6))
              (RPI1 0)
              (RNI1 0))
             (MV-LET (RPI1 RNI1)
                     (NEXTREM RPI RNI DIV QI1 FMT)
                     (MV QI1 RPI1 RNI1
                         (BITS (+ (+ (BITS RPI1 56 51)
                                     (LOGNOT (BITS RNI1 56 51)))
                                  1)
                               5 0)
                         (BITS (+ (+ (BITS RPI1 56 48)
                                     (LOGNOT (BITS RNI1 56 48)))
                                  1)
                               8 0)))))

(DEFUN
     ITER2 (RPI1 RNI1 RI1S6 RI1S9 DIV FMT)
     (LET ((QI2 (NEXTDIGIT RI1S6))
           (RPI2 0)
           (RNI2 0))
          (MV-LET (RPI2 RNI2)
                  (NEXTREM RPI1 RNI1 DIV QI2 FMT)
                  (MV QI2 RPI2 RNI2
                      (BITS (+ (+ (BITS RI1S9 6 0)
                                  (CASE QI2
                                        (2 (BITS (LOGNOT (BITS DIV 55 49)) 6 0))
                                        (1 (BITS (LOGNOT (BITS DIV 56 50)) 6 0))
                                        (0 (BITS 0 6 0))
                                        (-1 (BITS DIV 56 50))
                                        (-2 (BITS DIV 55 49))
                                        (T 0)))
                               1)
                            6 0)))))

(DEFUN ITER3 (RPI2 RNI2 RI2S7 DIV FMT)
       (LET ((QI3 (NEXTDIGIT (BITS RI2S7 6 1)))
             (RPI3 0)
             (RNI3 0))
            (MV-LET (RPI3 RNI3)
                    (NEXTREM RPI2 RNI2 DIV QI3 FMT)
                    (MV QI3 RPI3 RNI3))))

(DEFUN
 EXECUTE-LOOP-0
 (I N DIV FMT Q RP RN QP QN)
 (DECLARE (XARGS :MEASURE (NFIX (- N I))))
 (IF
  (AND (INTEGERP I) (INTEGERP N) (< I N))
  (LET
   ((RS6 0) (RS9 0))
   (MV-LET
    (Q RP RN RS6 RS9)
    (ITER1 RP RN DIV FMT)
    (MV-LET
     (QP QN)
     (NEXTQUOT QP QN Q)
     (LET
      ((RS7 0))
      (MV-LET
        (Q RP RN RS7)
        (ITER2 RP RN RS6 RS9 DIV FMT)
        (MV-LET (QP QN)
                (NEXTQUOT QP QN Q)
                (MV-LET (Q RP RN)
                        (ITER3 RP RN RS7 DIV FMT)
                        (MV-LET (QP QN)
                                (NEXTQUOT QP QN Q)
                                (EXECUTE-LOOP-0 (+ I 1)
                                                N DIV FMT Q RP RN QP QN)))))))))
  (MV Q RP RN QP QN)))

(DEFUN
 EXECUTE (OPA OPB FMT FZ DN RMODE)
 (LET
  ((SIGNA 0)
   (SIGNB 0)
   (EXPA 0)
   (EXPB 0)
   (MANA 0)
   (MANB 0)
   (CLASSA 0)
   (CLASSB 0)
   (FLAGS (BITS 0 7 0)))
  (MV-LET
   (SIGNA EXPA MANA CLASSA FLAGS)
   (ANALYZE OPA FMT FZ FLAGS)
   (MV-LET
    (SIGNB EXPB MANB CLASSB FLAGS)
    (ANALYZE OPB FMT FZ FLAGS)
    (LET
     ((SIGN (LOGXOR SIGNA SIGNB)))
     (IF1
      (LOGIOR1
          (LOGIOR1 (LOGIOR1 (LOGIOR1 (LOGIOR1 (LOGIOR1 (LOGIOR1 (LOG= CLASSA 0)
                                                                (LOG= CLASSA 1))
                                                       (LOG= CLASSA 2))
                                              (LOG= CLASSA 3))
                                     (LOG= CLASSB 0))
                            (LOG= CLASSB 1))
                   (LOG= CLASSB 2))
          (LOG= CLASSB 3))
      (SPECIALCASE SIGN OPA OPB CLASSA CLASSB FMT DN FLAGS)
      (LET
       ((DIVPOW2 (LOGAND1 (LOGAND1 (LOG= CLASSA 4)
                                   (LOG= CLASSB 4))
                          (LOG= MANB 0)))
        (SIGA 0)
        (SIGB 0)
        (EXPDIFF 0))
       (MV-LET
        (SIGA SIGB EXPDIFF)
        (NORMALIZE EXPA EXPB MANA MANB FMT)
        (LET
         ((DIV 0)
          (RP 0)
          (RN 0)
          (QP (BITS 0 53 0))
          (QN (BITS 0 53 0))
          (EXPQ 0)
          (Q 0))
         (MV-LET
          (DIV RP RN EXPQ Q)
          (PRESCALE SIGA SIGB EXPDIFF)
          (LET*
           ((N 0)
            (N (IF1 DIVPOW2 (BITS 0 4 0)
                    (CASE FMT (2 (BITS 9 4 0))
                          (1 (BITS 4 4 0))
                          (0 (BITS 2 4 0))
                          (T N)))))
           (MV-LET
            (Q RP RN QP QN)
            (EXECUTE-LOOP-0 0 N DIV FMT Q RP RN QP QN)
            (LET
               ((QTRUNC 0) (QINC 0) (STK 0))
               (MV-LET
                    (QINC QTRUNC STK)
                    (IF1 DIVPOW2
                         (MV QINC (BITS (ASH MANA 1) 52 0) 0)
                         (MV-LET (QTRUNC QINC STK)
                                 (COMPUTEQ QP QN RP RN FMT (FALSE$))
                                 (MV QINC QTRUNC STK)))
                    (LET ((QRND 0)
                          (QRNDDEN 0)
                          (INX 0)
                          (INXDEN 0))
                         (MV-LET (QRND INX QRNDDEN INXDEN)
                                 (ROUNDER QTRUNC QINC STK SIGN EXPQ RMODE FMT)
                                 (FINAL QRND INX QRNDDEN INXDEN SIGN
                                        EXPQ RMODE FZ FMT FLAGS)))))))))))))))))

