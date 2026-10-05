$title Eight-Process Synthesis - Algebraic MINLP for BARON

$onText
Algebraic MINLP reformulation of the classical eight-process
synthesis problem used in GAMS LOGMIP3.

Original references:
Duran, M.A. PhD thesis, Carnegie Mellon University, 1984.

Turkay, M.; Grossmann, I.E.
Logic-based MINLP algorithms for the optimal synthesis of process networks.
Computers & Chemical Engineering 20 (1996) 959-978.

Purpose of this version:
Deterministic global MINLP benchmark for comparison with CORAL-R1.

Revision note:
This publication-ready version removes the artificial blanket bound
X.up(I)=20 used in an earlier comparison model. Finite stream bounds are
instead derived analytically from the canonical LOGMIP3 equations, explicit
bounds, and active/off disjunctions. Unit-specific big-M constants are then
derived from those valid bounds.
$offText


Set
    I 'process streams' /1*25/
    J 'process units'   /1*8/;


Parameter CV(I) 'variable cost coefficients'
       /  3 = -10
          5 = -15
          9 = -40
         19 =  25
         21 =  35
         25 = -35
         17 =  80
         14 =  15
         10 =  15
          2 =   1
          4 =   1
         18 = -65
         20 = -60
         22 = -80 /;


Parameters
    UB(I) 'analytically valid upper bounds for process streams'
    BM(J) 'unit-specific big-M constants for disjunctive equations';

* Bounds below are implied by the canonical LOGMIP3 model.
* They replace the artificial blanket bound X.up(I)=20 used in an earlier
* comparison model. No feasible integer solution of the canonical model is
* excluded by these bounds.
UB('1')  = exp(2)-1 + exp(2/1.2)-1;
UB('2')  = exp(2)-1;
UB('3')  = 2;
UB('4')  = exp(2/1.2)-1;
UB('5')  = 2;
UB('6')  = 4;
UB('7')  = 4;
UB('8')  = 4;
UB('9')  = 2;
UB('10') = 1;
UB('11') = 4;
UB('12') = 4;
UB('13') = 4;
UB('14') = 1;
UB('15') = 4;
UB('16') = 2;
UB('17') = 2;
UB('18') = log(4);
UB('19') = 2;
UB('20') = 1.5*log(3);
UB('21') = 2;
UB('22') = log(3);
UB('23') = 1.5*log(3) + log(3);
UB('24') = 1.5*log(3) + log(3);
UB('25') = 3;

* Valid residual bounds over the variable box above. These constants are
* used only to deactivate the corresponding process equation when Y(j)=0.
BM('1') = exp(2)-1;
BM('2') = exp(2/1.2)-1;
BM('3') = 4;
BM('4') = 6.25;
BM('5') = 4;
BM('6') = 2;
BM('7') = 2;
BM('8') = 3;


Variable
    PROF 'objective';

Binary Variable
    Y(J) 'process-unit selection';

Positive Variable
    X(I)  'process streams'
    CF(J) 'fixed costs';


* ------------------------------------------------------------
* Bounds
* ------------------------------------------------------------

X.up(I) = UB(I);


Equation

* Common process equations
    MASSBAL1
    MASSBAL2
    MASSBAL3
    MASSBAL4
    MASSBAL5
    MASSBAL6
    MASSBAL7
    MASSBAL8

    SPECS1
    SPECS2
    SPECS3
    SPECS4

* Flow/unit activation
    LOGICAL1
    LOGICAL2
    LOGICAL3
    LOGICAL4
    LOGICAL5
    LOGICAL6
    LOGICAL7
    LOGICAL8

* Exclusive choices
    XOR12
    XOR45
    XOR67

* Logical implications
    IMP0
    IMP1
    IMP2
    IMP3
    IMP4
    IMP5
    IMP6
    IMP7
    IMP8
    IMP9

* Unit 1
    U1A
    U1B
    U1OFF2
    U1OFF3
    CF1

* Unit 2
    U2A
    U2B
    U2OFF4
    U2OFF5
    CF2

* Unit 3
    U3A
    U3B
    U3OFF9
    CF3

* Unit 4
    U4A
    U4B
    U4OFF12
    U4OFF13
    U4OFF14
    CF4

* Unit 5
    U5A
    U5B
    U5OFF15
    U5OFF16
    CF5

* Unit 6
    U6A
    U6B
    U6OFF19
    U6OFF20
    CF6

* Unit 7
    U7A
    U7B
    U7OFF21
    U7OFF22
    CF7

* Unit 8
    U8A
    U8B
    U8OFF10
    U8OFF17
    U8OFF18
    U8OFF25
    CF8

    OBJECTIVE;


* ------------------------------------------------------------
* Common process equations
* ------------------------------------------------------------

MASSBAL1..
    X('13') =e= X('19') + X('21');

MASSBAL2..
    X('17') =e= X('9') + X('16') + X('25');

MASSBAL3..
    X('11') =e= X('12') + X('15');

MASSBAL4..
    X('3') + X('5') =e= X('6') + X('11');

MASSBAL5..
    X('6') =e= X('7') + X('8');

MASSBAL6..
    X('23') =e= X('20') + X('22');

MASSBAL7..
    X('23') =e= X('14') + X('24');

MASSBAL8..
    X('1') =e= X('2') + X('4');


SPECS1..
    X('10') =l= 0.8*X('17');

SPECS2..
    X('10') =g= 0.4*X('17');

SPECS3..
    X('12') =l= 5*X('14');

SPECS4..
    X('12') =g= 2*X('14');


* ------------------------------------------------------------
* Flow permitted only when corresponding unit exists
* ------------------------------------------------------------

LOGICAL1..
    X('2') + X('3') =l= 10*Y('1');

LOGICAL2..
    X('4') + X('5') =l= 10*Y('2');

LOGICAL3..
    X('9') =l= 10*Y('3');

LOGICAL4..
    X('12') + X('14') =l= 10*Y('4');

LOGICAL5..
    X('15') =l= 10*Y('5');

LOGICAL6..
    X('19') =l= 10*Y('6');

LOGICAL7..
    X('21') =l= 10*Y('7');

LOGICAL8..
    X('10') + X('17') =l= 10*Y('8');


* ------------------------------------------------------------
* Logical structure
* ------------------------------------------------------------

XOR12..
    Y('1') + Y('2') =e= 1;

XOR45..
    Y('4') + Y('5') =e= 1;

XOR67..
    Y('6') + Y('7') =e= 1;


* y1 -> y3 or y4 or y5
IMP0..
    Y('1') =l= Y('3') + Y('4') + Y('5');

* y2 -> y3 or y4 or y5
IMP1..
    Y('2') =l= Y('3') + Y('4') + Y('5');

* y3 -> y8
IMP2..
    Y('3') =l= Y('8');

* y3 -> y1 or y2
IMP3..
    Y('3') =l= Y('1') + Y('2');

* y4 -> y1 or y2
IMP4..
    Y('4') =l= Y('1') + Y('2');

* y4 -> y6 or y7
IMP5..
    Y('4') =l= Y('6') + Y('7');

* y5 -> y1 or y2
IMP6..
    Y('5') =l= Y('1') + Y('2');

* y5 -> y8
IMP7..
    Y('5') =l= Y('8');

* y6 -> y4
IMP8..
    Y('6') =l= Y('4');

* y7 -> y4
IMP9..
    Y('7') =l= Y('4');


* ------------------------------------------------------------
* Unit 1
*
* If Y1 = 1:
*       exp(X3)-1 = X2
*
* If Y1 = 0:
*       X2 = X3 = 0
* ------------------------------------------------------------

U1A..
    exp(X('3')) - 1 - X('2') =l= BM('1')*(1-Y('1'));

U1B..
    exp(X('3')) - 1 - X('2') =g= -BM('1')*(1-Y('1'));

U1OFF2..
    X('2') =l= UB('2')*Y('1');

U1OFF3..
    X('3') =l= UB('3')*Y('1');

CF1..
    CF('1') =e= 5*Y('1');


* ------------------------------------------------------------
* Unit 2
* ------------------------------------------------------------

U2A..
    exp(X('5')/1.2) - 1 - X('4') =l= BM('2')*(1-Y('2'));

U2B..
    exp(X('5')/1.2) - 1 - X('4') =g= -BM('2')*(1-Y('2'));

U2OFF4..
    X('4') =l= UB('4')*Y('2');

U2OFF5..
    X('5') =l= UB('5')*Y('2');

CF2..
    CF('2') =e= 8*Y('2');


* ------------------------------------------------------------
* Unit 3
* ------------------------------------------------------------

U3A..
    1.5*X('9') + X('10') - X('8')
       =l= BM('3')*(1-Y('3'));

U3B..
    1.5*X('9') + X('10') - X('8')
       =g= -BM('3')*(1-Y('3'));

U3OFF9..
    X('9') =l= UB('9')*Y('3');

CF3..
    CF('3') =e= 6*Y('3');


* ------------------------------------------------------------
* Unit 4
* ------------------------------------------------------------

U4A..
    1.25*(X('12') + X('14')) - X('13')
       =l= BM('4')*(1-Y('4'));

U4B..
    1.25*(X('12') + X('14')) - X('13')
       =g= -BM('4')*(1-Y('4'));

U4OFF12..
    X('12') =l= UB('12')*Y('4');

U4OFF13..
    X('13') =l= UB('13')*Y('4');

U4OFF14..
    X('14') =l= UB('14')*Y('4');

CF4..
    CF('4') =e= 10*Y('4');


* ------------------------------------------------------------
* Unit 5
* ------------------------------------------------------------

U5A..
    X('15') - 2*X('16')
       =l= BM('5')*(1-Y('5'));

U5B..
    X('15') - 2*X('16')
       =g= -BM('5')*(1-Y('5'));

U5OFF15..
    X('15') =l= UB('15')*Y('5');

U5OFF16..
    X('16') =l= UB('16')*Y('5');

CF5..
    CF('5') =e= 6*Y('5');


* ------------------------------------------------------------
* Unit 6
* ------------------------------------------------------------

U6A..
    exp(X('20')/1.5) - 1 - X('19')
       =l= BM('6')*(1-Y('6'));

U6B..
    exp(X('20')/1.5) - 1 - X('19')
       =g= -BM('6')*(1-Y('6'));

U6OFF19..
    X('19') =l= UB('19')*Y('6');

U6OFF20..
    X('20') =l= UB('20')*Y('6');

CF6..
    CF('6') =e= 7*Y('6');


* ------------------------------------------------------------
* Unit 7
* ------------------------------------------------------------

U7A..
    exp(X('22')) - 1 - X('21')
       =l= BM('7')*(1-Y('7'));

U7B..
    exp(X('22')) - 1 - X('21')
       =g= -BM('7')*(1-Y('7'));

U7OFF21..
    X('21') =l= UB('21')*Y('7');

U7OFF22..
    X('22') =l= UB('22')*Y('7');

CF7..
    CF('7') =e= 4*Y('7');


* ------------------------------------------------------------
* Unit 8
* ------------------------------------------------------------

U8A..
    exp(X('18')) - 1 - X('10') - X('17')
       =l= BM('8')*(1-Y('8'));

U8B..
    exp(X('18')) - 1 - X('10') - X('17')
       =g= -BM('8')*(1-Y('8'));

U8OFF10..
    X('10') =l= UB('10')*Y('8');

U8OFF17..
    X('17') =l= UB('17')*Y('8');

U8OFF18..
    X('18') =l= UB('18')*Y('8');

U8OFF25..
    X('25') =l= UB('25')*Y('8');

CF8..
    CF('8') =e= 5*Y('8');


* ------------------------------------------------------------
* Objective
* ------------------------------------------------------------

OBJECTIVE..
    PROF =e=
       sum(J,CF(J))
     + sum(I,X(I)*CV(I))
     + 122;


* ------------------------------------------------------------
* Initial topology
* ------------------------------------------------------------

Y.l('1') = 1;
Y.l('2') = 0;
Y.l('3') = 1;
Y.l('4') = 0;
Y.l('5') = 0;
Y.l('6') = 0;
Y.l('7') = 0;
Y.l('8') = 1;


* ------------------------------------------------------------
* BARON
* ------------------------------------------------------------

option MINLP = BARON;
option optcr = 0;
option reslim = 300;

Model EIGHT_PROCESS_BARON /all/;

solve EIGHT_PROCESS_BARON using MINLP minimizing PROF;


* ------------------------------------------------------------
* Report
* ------------------------------------------------------------

display
    PROF.l,
    Y.l,
    X.l,
    EIGHT_PROCESS_BARON.modelstat,
    EIGHT_PROCESS_BARON.solvestat,
    EIGHT_PROCESS_BARON.resusd;