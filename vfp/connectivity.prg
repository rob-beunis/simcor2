* CONNECTIVITY - Dr. R. Beunis, Visual FoxPro 9.0
* The CONNECTIVITY form of the author's article reader CEREBREADER.PRG, as a stand-alone program.
* It accompanies the Addendum 'Random connectivity examined' of
*   Beunis R. (2022) The electrosensory lateral line lobe in mormyrid fish : a stepping stone to the
*   understanding of the cerebellum ? (Part 2/2 : the cerebellum). Zenodo, doi:10.5281/zenodo.17613147
*
* Left half of the form (demo-4-1, Fig. 16): each timeslice of the A-path is fed by 256 granule cells with a
* random input permutation in which up to NOLI inputs may be lacking (replaced by a redundant one); a granule
* cell with a lacking input fires at a 'wrong address'. Decorrelation runs of 50 iterations allowing 0, 1, 2,
* ... lacking inputs. The buttons '3/4/5 inputs' start the runs in 3, 4 or 5 dimensions.
* Right half (not used in the article): the 'ordered' input combinations, with the timeslices that a chosen
* combination affects; the buttons '3/4/5 inputs' of the right half first show these lists, then do the runs
* of the left half, using the results stored in CONNECT.DBF when they exist. Click a combination in one of
* these lists to see which timeslices it affects.
*
* Usage:  DO connectivity                    the whole form; maximize it to see its right half (stand-alone
*                                            the form is the subclass CONNECTIVITYSA: maximizable)
*         DO connectivity WITH .T.,"1*I"     demo-4-1 as in the article reader: the left half, and the run
*                                            with 4 inputs starts at once (with '*' the stored results of a
*                                            former run in CONNECT.DBF are shown, when they exist)
* The program creates the table CONNECT.DBF in the current directory.
*
* The classes are copied verbatim from CEREBREADER.PRG; changes for this stand-alone version are marked
* with '&& GitHub version:'. MIT license, see LICENSE.

PARAMETERS plCalled,pcCMD

IF NOT plCalled
	CLEAR ALL
	CLOSE ALL
	PUBLIC plCalled,pcCMD
	STORE .F. TO plCalled
	STORE '' TO pcCMD
ENDIF

PUBLIC pcSAFETY,pcCOMPATIBLE,pcTALK
pcSAFETY=SET('SAFETY')
pcCOMPATIBLE=SET('COMPATIBLE')
pcTALK=SET('TALK')
SET SAFETY OFF
SET UDFPARMS TO REFERENCE
SET COMPATIBLE ON
SET TALK OFF

&& Colours as constants
PUBLIC pnZwart,pnLichtGrijs,pnGrijs,pnDonkerGrijs,pnWit,;
		 pnLichtRood,pnRood,pnDonkerRood,pnLichtGroen,pnGroen,pnDonkerGroen,;
		 pnLichtBlauw,pnBlauw,pnDonkerBlauw,pnGeel,pnLichtGeel,pnHalfDonkerGeel,pnDonkerGeel,;
		 pnCyaan,pnLichtCyaan,pnHalfDonkerCyaan,pnDonkerCyaan,pnMagenta,pnLichtMagenta
DO INITCOLOR

&& The public variables of the form (as in CEREBREADER.PRG)
PUBLIC oConnectivity,plCMD,pnH,pnW,pnWObj,pnD,pnP,pnConSteps,pnInputs,pnITs,pcRCOR,pnList,pnCVC,pcWAF,pnCMD
STORE '' TO pcRCOR,pcWAF
STORE 0 TO pnH,pnW,pnWObj,pnD,pnP,pnInputs,pnConSteps,pnITs,pnList,pnCVC,pnCMD
STORE .F. TO plCMD
&& Two globals of the article reader used by S2BASE / WANDERINGLINE (their values at start-up)
PUBLIC pnHMem,pnR
pnHMem=30
pnR=1

&& demo-4-1: the form as in the article reader; stand-alone: the same form, but maximizable (CONNECTIVITYSA)
oConnectivity=CREATEOBJECT(IIF(plCalled,'CONNECTIVITY','CONNECTIVITYSA'),plCalled,pcCMD,.F.,IIF(plCalled,"demo-4-"+pcCMD,"CONNECTIVITY"))
oConnectivity.Show(1)

&& Restore the settings and quit
RELEASE oConnectivity
SET SAFETY &pcSAFETY
SET COMPATIBLE &pcCOMPATIBLE
SET TALK &pcTALK
CLOSE TABLES
RETURN

&& Class definitions ---------------------------------------------------------------------------------------

&& GitHub version: the CONNECTIVITY form for the stand-alone start. In the article reader the form opens
&& maximized and has no maximize button; stand-alone it opens small, and only when it is maximized does its
&& right half appear (the 'ordered' combination lists, in which a combination can be clicked). Without themes,
&& as in the author's stand-alone connectivity.prg (with themes the form did not maximize in the tests).
DEFINE CLASS CONNECTIVITYSA AS CONNECTIVITY
	MaxButton			= .T.
	MinButton			= .T.
	Themes				= .F.
ENDDEFINE

&& BASEFORM (of CEREBREADER.PRG): only its properties and Init, which the CONNECTIVITY form uses
DEFINE CLASS BASEFORM AS FORM
	WindowState				= 2
	ShowTips				= .T.
	FontSize				= 8
	KeyPreview				= .T.
	
	lBaseForm				= .F.

	PROCEDURE Init(lCalled,cCMD,lReport,cLI,	lIA)
	plCalled=lCalled
	pcCMD=cCMD
	plReport=lReport
	IF plCalled
		plCMD= ( "*"$pcCMD )
		lIA= ( 'I'$pcCMD )
		pcCMD=CHRTRAN(pcCMD,'*I','')
	ENDIF
	thisform.Caption=cLI+IIF(lIA," (Interactive ! Close window to exit and regain control in main program)",'')
	RETURN

ENDDEFINE

&& COMP CONNECTIVITY
DEFINE CLASS CONNECTIVITY AS BASEFORM
	WindowState			= 2
	ShowTips				= .T.
	AlwaysOnTop			= .T.
	BackColor			= pnZwart
	FontSize				= 8
	FontBold				= .T.
	ScrollBars			= 3
	ContinuousScroll	= .T.
	KeyPreview			= .T.
	MaxButton			= .F.
	MinButton			= .F.

	lConnectivity	= .F.
	
	ADD OBJECT DUMMY AS LABEL WITH Left=2000, Height=5, Width=5
	&& For SetViewPort to work, this dummy must HERE get a Left far to the right of the screen; it may be set to another value afterwards, no difference

	PROCEDURE Activate(nX,cX,nNOLI,nTS)
	IF thisform.lConnectivity
		RETURN
	ENDIF
	IF NOT FILE("CONNECT.DBF")
		CREATE TABLE CONNECT (INPUTS i(4), NOLI i(4), TS i(4), TSVAL i(4), LISTOR1 c(240), LISTOR2 c(240), LISTAG1 c(240), LISTAG2 c(240))
		FOR nX=1 TO 12
			nNOLI=IIF(INLIST(nX,1,4,8),0,nNOLI+1)
			FOR nTS=1 TO ICASE(nX<4,216,nX>7,243,256)
				APPEND BLANK
				REPLACE INPUTS WITH ICASE(nX<4,3,nX>7,5,4),NOLI WITH nNOLI, TS WITH nTS
			ENDFOR
		ENDFOR
		USE IN CONNECT
	ENDIF
	USE CONNECT IN SELECT(1)
	SELECT CONNECT
	thisform.lConnectivity=.T.
	pnH=thisform.Height
	pnW=1264 &&thisform.Width
	pnW=thisform.Width
	pnWObj=pnW/12
	pnD=.01 && D-factor
	pnP=.01 && P-factor

	IF plCalled
		thisform.Left=pnW/2
		thisform.Width=pnW/2
		IF TYPE('oCerebreader')='O' && GitHub version: only within the article reader
		IF pnW>oCerebreader.Width
			thisform.Left=oCerebReader.Width-1264/2
		ENDIF
		ENDIF && GitHub version
		pnInputs=4
		pnCMD=VAL(pcCMD)
	ENDIF
	
	thisform.AddObject("PITSP","ISP")
	thisform.AddObject("PTSSP","ISP")
	thisform.AddObject("PITCB","ICB")
	thisform.AddObject("PTSCB","ICB")
	thisform.AddObject("CITSP","ISP")
	thisform.AddObject("CTSSP","ISP")
	thisform.AddObject("CITCB","ICB")
	thisform.AddObject("CTSCB","ICB")
	thisform.AddObject("PORCB","ICB")
	thisform.AddObject("CORCB","ICB")

	FOR nX=3 TO 5
		cX=LTRIM(STR(nX))
		thisform.AddObject("PCON"+cX,"CONCB")
	ENDFOR

	FOR nX=3 TO 5
		cX=LTRIM(STR(nX))
		thisform.AddObject("CCON"+cX,"CONCB")
	ENDFOR

	FOR nX=0 TO 4
		cX=LTRIM(STR(nX))
		thisform.AddObject("PLIST"+cX,"PLIST")
	ENDFOR
	FOR nX=0 TO 4
		cX=LTRIM(STR(nX))
		thisform.AddObject("CLIST"+cX,"CLIST")
	ENDFOR
	pnITs=50
	pnConSteps=256
	PUBLIC ARRAY S1[pnConSteps],S4[pnConSteps],S4M[pnConSteps],TSALIST[pnConSteps],PLISTOR[pnITs*5,pnConSteps],PLISTAG[pnITs*5,pnConSteps],CAT[6,6],COMBLIST[6] && 20*5
	thisform.MAKE_S1
	SET COMPATIBLE OFF
	STORE '' TO TSALIST,PLISTOR,PLISTAG
	SET COMPATIBLE ON

	thisform.DUMMY.Left=-1000
	thisform.Width=pnW/2
&&   thisform.DIMS('form')
&&   thisform.REDIMS(.T.)

	IF plCalled
		IF pnCMD=1
			thisform.PCON4.Click
		ELSE
			thisform.SetViewPort(pnW/2,0)
			thisform.CCON4.Click
			DO CASE
			CASE pnCMD=2
				thisform.Cls
			CASE pnCMD=3
				thisform.CLIST0.SelStart=AT(CHR(13),thisform.CLIST0.Value,1)+2
				thisform.CLIST0.Click(.T.)
			CASE pnCMD=4
				thisform.CLIST1.SelStart=AT(CHR(13),thisform.CLIST1.Value,1)+2
				thisform.CLIST1.Click(.T.)
			CASE pnCMD=5
				thisform.CLIST2.SelStart=AT(CHR(13),thisform.CLIST2.Value,1)+2
				thisform.CLIST2.Click(.T.)
			CASE pnCMD=6
				thisform.CLIST3.SelStart=AT(CHR(13),thisform.CLIST3.Value,1)+2
				thisform.CLIST3.Click(.T.)
			CASE pnCMD=7
				thisform.CLIST2.SelStart=AT(CHR(13),thisform.CLIST2.Value,1)+2+9*(pnInputs+1)
				thisform.CLIST2.Click(.T.)
			CASE pnCMD=8
				thisform.CLIST0.SelStart=AT(CHR(13),thisform.CLIST0.Value,1)+2
				thisform.CLIST0.Click
			ENDCASE
		ENDIF
&&		thisform.SCREENCAPT && GitHub version: (a screen capture made by the article reader)
	ENDIF
	IF plCalled
		SET COMPATIBLE ON && Must be set ON !! or pnDoc becomes a variable 'not found' on return to the main program !!
		RETURN && !! NOT 'CANCEL' - otherwise windowtype error when restarted, and also remaining interactivity !!
	ENDIF
	RETURN
	
	PROCEDURE Destroy
	USE IN CONNECT
	RELEASE S1,S4,S4M,PLISTOR,PLISTAG
	IF TYPE('oCerebreader')='O' && GitHub version: only within the article reader
		pnW=oCerebreader.Width
	ENDIF && GitHub version
	RETURN
	
	PROCEDURE Scrolled
	LPARAMETERS nDirection
	thisform.SetAll("Visible",.T.,"CONCB")
	thisform.Refresh
	RETURN

	PROCEDURE PREP
	DO CASE
	&& pnCVC will be chosen to have pnCVC^pnInputs to be as close as possible but not exceeding 256, the max nr of timeslices to be displayed
	CASE pnInputs=3
		pnCVC=6 && The number (count) of 'coordinate values' for all coordinate axes (dimensions) when 3 inputs are used
		&& pnCVC^pnInputs=216
		pcWAF="(nAA-1)*36+(nBB-1)*6+(nCC-1)*1+1" && The 'wrong addressing' formula for 3 inputs
		&& This 'formula' computes the specific location (address) of a timeslice in a string of 216 timeslices
		&& CVs normally 'belong' to a specific coordinate axis and then the formula computes the 'right' address
		&& However, when a CV from a particular axis is lacking, and is replaced by a (redundant) CV of another axis
		&& then a 'wrong address' will be the result
	CASE pnInputs=4
		pnCVC=4
		&& pnCVC^pnInputs=256
		pcWAF="(nAA-1)*64+(nBB-1)*16+(nCC-1)*4+(nDD-1)*1+1"
	CASE pnInputs=5
		pnCVC=3
		&& pnCVC^pnInputs=243
		pcWAF="(nAA-1)*81+(nBB-1)*27+(nCC-1)*9+(nDD-1)*3+(nEE-1)*1+1"
	ENDCASE
	thisform.PITSP.SpinnerHighValue=pnITs
	thisform.PITSP.Value=1
	thisform.PTSSP.SpinnerHighValue=pnCVC^pnInputs
	thisform.PTSSP.Value=1
	thisform.CITSP.SpinnerHighValue=pnITs
	thisform.CITSP.Value=1
	thisform.CTSSP.SpinnerHighValue=pnCVC^pnInputs
	thisform.CTSSP.Value=1
	RETURN
	
	PROCEDURE FCOLOR(nX,	nColor)
	nColor=ICASE(nX=0,pnGroen,nX=1,pnLichtRood,nX=2,pnCyaan,nX=3,pnGeel,nX=4,pnLichtMagenta)
	RETURN(nColor)

	PROCEDURE DORUN(nX,lMemCMD,nNOLI,cNOLI,nCLTop,nITC,nTSC,cORCL,cAGCL,nA,nB,nC,nD,nE,;
							 nCOMB,nCOMBs,cRCAG,cRCOR,nT,cT,cS,nAA,nBB,nCC,nDD,nEE,nTSWA,nFC,nSH,nS1,nS0)
	thisform.PREP
	thisform.ForeColor=pnZwart
	FOR nX=1 TO pnH
		thisform.Line(0,nX,pnW/2,nX)
	ENDFOR

	SET COMPATIBLE OFF
	STORE '' TO CLISTOR,CLISTAG && Empty the combination list arrays
	SET COMPATIBLE ON
	thisform.SetAll("Value",'',"PLIST")
	thisform.SetAll("Visible",.F.,"PLIST")

	lMemCMD=plCMD
	nSH=90
	nCOMBs=256
	FOR nNOLI=0 TO pnInputs-1 && The number of 'lacking inputs' (NOLI) that is allowed
		IF plCMD
			LOCATE FOR INPUTS=pnInputs AND NOLI=nNOLI
			IF EMPTY(LISTOR1)
				plCMD=.F.
			ENDIF
		ENDIF
		cNOLI=LTRIM(STR(nNOLI))
		nCLTop=thisform.PLIST&cNOLI..Top
		thisform.PLIST&cNOLI..Visible=.T.
		thisform.ForeColor=thisform.FCOLOR(nNOLI)
		nFC=thisform.FCOLOR(nNOLI)
		SET COMPATIBLE OFF
		STORE 0 TO S4,S4M && (S4) Arrays to contain averages of the CC of S1+S2
		SET COMPATIBLE ON
		nS0=thisform.S1BASE((1))
		DIMENSION RCAG[pnCVC^pnInputs,nCombs],RCOR[pnCVC^pnInputs,nCombs]
		FOR nITC=1 TO IIF(plCMD,1,pnITs) &&pnCVC^pnInputs && Iteration counter
			IF nITC=1 && Start with S4=S3=S1+S2 or with S4=0
				FOR nA=1 TO 256
					S4(nA)=0 &&thisform.S1BASE((nA))+thisform.S2BASE(nA)
					S4M(nA)=0
				ENDFOR
			ENDIF
			nTSC=0 && Timeslicecounter
			&&	=RAND(100.001) && IMPORTANT ! : after this 'seed' the following RAND()s will always generate the same series of random numbers
			&&	Replaced by using 'memory' arrays RCAG and RCOR
			&& This is to guarantee that WAs are always the same for the same timeslice at each iteration
			FOR nA=1 TO pnCVC && For 'Coordinate value of dimension(1) is 1 to Coordinate value count of dimension(1)'  
				FOR nB=1 TO pnCVC && for simplicity's sake all pnCVCs are the same 
					FOR nC=1 TO pnCVC
						FOR nD=1 TO pnCVC
							FOR nE=1 TO pnCVC
								nTSC=nTSC+1 && Increment the timeslicecounter
								&&	Actually nTSC=EVALUATE(pcWAF) when filled in with nCVD1 ... would give the same result
								&& but the pcWAF formula will be necessary to calculate the 'wrong addressings'
								IF NOT plCMD
									cORCL=LTRIM(STR(nCombs))+" parallel ordered combinations"+CHR(13)+"Iteration "+LTRIM(STR(nITC))+" Timeslice "+LTRIM(STR(nTSC))
									cAGCL=LTRIM(STR(nCombs))+" parallel input permutations as generated at random"+CHR(13)+"Iteration "+LTRIM(STR(nITC))+" Timeslice "+LTRIM(STR(nTSC))
									cORCL=cORCL+CHR(13)
									cAGCL=cAGCL+CHR(13)
									&& Strings to contain the 'ordered' and 'as generated' combination lists to be displayed 
								
									IF nITC=1
&&										S4(nTSC)=thisform.S1BASE((nTSC))+thisform.S2BASE(nTSC)
&&										S4M(nTSC)=0
									ENDIF

									FOR nCOMB=1 TO nCombs  && We generate nCombs combinations
										IF nITC=1
											cRCAG=thisform.RANDCOMB(nNOLI)
											&& a random combination 'as generated' on the basis of the number of 'lacking inputs' 
											RCAG(nTSC,nCOMB)=cRCAG
											cRCOR=thisform.COMBOR((cRCAG)) && place the inputs 'in order of dimension' and fill in the gaps with the redundant ones
											RCOR(nTSC,nCOMB)=cRCOR
										ELSE
											cRCAG=RCAG(nTSC,nCOMB)
											cRCOR=RCOR(nTSC,nCOMB)
										ENDIF

										FOR nT=1 TO pnInputs && loop through the dimensions
											cT=REPLICATE(SUBSTR("ABCDE",nT,1),2) && AA or BB or CC or DD or EE
											cS=SUBSTR(cRCOR,nT,1) && A or B or C or D or E from cRCOR !
											&& The place number nT in cRCOR is the target dimension, the value in this place (cS) is the source dimension 
											n&cT=n&cS && Put the actual value of the source dimension into the variable of the target dimension
											&& e.g. IF cRCOR='12335' then 4 is the lacking input and 3 is the redundant input
											&& hence nDD will get the actual value of nC and with this combination the wrong address will be computed
											&& for all others nXX=nX
										ENDFOR

										nTSWA=EVALUATE(pcWAF) && compute the wrong address (the location in the string of timeslices)

										S4M(nTSWA)=S4(nTSWA) && remember the actual AVG value
										S4(nTSWA)=S4(nTSWA) - S4(nTSWA)*pnD + (S1(nTSC)+thisform.S2BASE(nITC))*pnP && compute the next AVG value
										IF nITC=1 OR INT(S4M(nTSWA))#INT(S4(nTSWA)) && redraw the line only when discretely different
											thisform.ForeColor=pnZwart
											thisform.Line(nTSWA+35,nCLTop+nSH,nTSWA+35,nCLTop+nSH-55) && Draw black line first to erase the former one
											thisform.ForeColor=nFC
											thisform.Line(nTSWA+35,nCLTop+nSH,nTSWA+35,nCLTop+nSH-S4(nTSWA)) && display the result graphically
											&& vertical line from nCLTop+90 to nCLTop+90-S4(nTSWA) at horizontal position nTWSA+35
										ENDIF
										cORCL=cORCL+cRCOR+' ' && add the 'ordered' combination to the list which is to be displayed
										cAGCL=cAGCL+cRCAG+' ' && add the 'as generated' combination to the list which is to be displayed
									ENDFOR
								
									PLISTOR(nNOLI*pnITs+nITC,nTSC)=cORCL
									&& put the ordered combination list (nCombs combs) for the actual iteration and timeslice in a specific array
									PLISTAG(nNOLI*pnITs+nITC,nTSC)=cAGCL && same for 'as generated'
								ELSE
									cORCL=RTRIM(LISTOR1+LISTOR2)
									cAGCL=RTRIM(LISTAG1+LISTAG2)
									thisform.Line(nTSC+35,nCLTop+nSH,nTSC+35,nCLTop+nSH-TSVAL) && display the result graphically
									SKIP
								ENDIF
								IF nITC=1 AND nTSC=1 && display only the list for the first timeslice in the first iteration
								&& the rest can be viewed on demand with the buttons on top
									cNOLI=LTRIM(STR(nNOLI))
									thisform.PLIST&cNOLI..Visible=.T.
									IF "Ordered"$thisform.PORCB.Caption
										thisform.PLIST&cNOLI..Value=cORCL
									ELSE
										thisform.PLIST&cNOLI..Value=cAGCL
									ENDIF
								ENDIF
								IF pnInputs<5 && then execute this loop but once
									EXIT
								ENDIF
							ENDFOR
							IF pnInputs<4 && then execute this loop but once
								EXIT
							ENDIF
						ENDFOR
					ENDFOR
				ENDFOR
			ENDFOR
			IF nNOLI=0
				thisform.Print("No inputs lacking",10,nCLTop)
			ELSE
				thisform.Print(LTRIM(STR(nNOLI))+" input"+IIF(nNOLI=1,'','s')+" may be lacking",10,nCLTop)
			ENDIF
			IF nNOLI=0
				thisform.Print("All dendrites receive distinct inputs",10,nCLTop+20)
			ELSE
				thisform.Print("Same input on "+LTRIM(STR(nNOLI+1))+" dendrites allowed",10,nCLTop+20)
			ENDIF
			thisform.Print(LTRIM(STR(IIF(plCMD,pnITs,nITC))),10,nCLTop+50)
		ENDFOR
		nTSC=0
		IF NOT plCMD
			SCAN FOR INPUTS=pnInputs AND NOLI=nNOLI
				nTSC=nTSC+1
				REPLACE TSVAL WITH S4(nTSC), LISTOR1 WITH LEFT(PLISTOR(nNOLI*pnITs+1,nTSC),240),LISTOR2 WITH SUBSTR(PLISTOR(nNOLI*pnITs+1,nTSC),241),;
														LISTAG1 WITH LEFT(PLISTAG(nNOLI*pnITs+1,nTSC),240),LISTAG2 WITH SUBSTR(PLISTAG(nNOLI*pnITs+1,nTSC),241)
			ENDSCAN
		ENDIF
	ENDFOR
	plCMD=lMemCMD
	?? CHR(7)
	RETURN

	PROCEDURE S2BASE(nL)
	RETURN(MIN(30,MAX(10,ABS(pnHMem)+thisform.WANDERINGLINE(nL)*(ABS(MOD(nL,10)-5)/40)*50))) &&+IIF(MEM.S2JIT=1,(RAND()-.5)*10,0))))

	PROCEDURE WANDERINGLINE(nX,nR)
	nR=RAND()
	pnR=IIF(MOD(nX,5)=0,nR,pnR)
	RETURN(pnR-.5)
	
	PROCEDURE DORUN2(nL,nNOLI,cTSALIST,nX,nCLTop,nITC,nTSC,nA,nB,nW,nMemColor,nC,nD,nE,nT,cT,cS,nAA,nBB,nCC,nDD,nEE,nZ,nTSWA,nAT)
	nL=pnW/2+(pnW/2-2*pnCVC^pnInputs)/2
	nNOLI=pnList
	thisform.DrawWidth=2
	cTSALIST=''
	thisform.ForeColor=pnZwart
	nP=thisform.CLIST4.Top+thisform.CLIST4.Height-(5-pnInputs)*5
	FOR nX=nP TO pnH
		thisform.Line(pnW/2,nX,pnW,nX)
	ENDFOR

	nCLTop=pnH-30
	SET COMPATIBLE OFF
	STORE 1 TO S4,S4M && Arrays to contain averages
	STORE '' TO TSALIST,COMBLIST
	SET COMPATIBLE ON
	FOR nITC=1 TO 1 &&pnITs &&pnCVC^pnInputs && Iteration counter
		nTSC=0 && Timeslicecounter
		FOR nA=1 TO pnCVC && For 'Coordinate value of dimension(1) is 1 to Coordinate value count of dimension(1)'  
			FOR nB=1 TO pnCVC && for simplicity's sake all pnCVCs are the same 
				nW=INT(nB*192/pnCVC)
				nMemColor=0
				thisform.ForeColor=ICASE(nA=1,RGB(255,nW,nW),nA=2,RGB(nW,255,nW),nA=3,RGB(nW,nW,255),;
													 nA=4,RGB(196,196,nW),nA=5,RGB(196,nW,196),nA=6,RGB(nW,196,196))
				FOR nC=1 TO pnCVC
					FOR nD=1 TO pnCVC
						FOR nE=1 TO pnCVC
							nTSC=nTSC+1 && Increment the timeslicecounter
							&&	Actually nTSC=EVALUATE(pcWAF) when filled in with nAA ... would give the same result
							&& but the pcWAF formula will be necessary to calculate the 'wrong addressings'

							FOR nT=1 TO pnInputs && loop through the dimensions
								cT=REPLICATE(SUBSTR("ABCDE",nT,1),2) && AA or BB or CC or DD or EE
								cS=SUBSTR(pcRCOR,nT,1) && A or B or C or D or E from pcRCOR !
								&& The place number nT in pcRCOR is the target dimension, the value in this place (cS) is the source dimension 
								n&cT=n&cS && Put the actual value of the source dimension into the variable of the target dimension
								&& e.g. IF pcRCOR='12335' then 4 is the lacking input and 3 is the redundant input
								&& hence nDD will get the actual value of nC and with this combination the wrong address will be computed
								&& for all others nXX=nX
							ENDFOR
							nTSWA=EVALUATE(pcWAF) && compute the wrong address (the location in the string of timeslices)
							TSALIST(nTSWA)=TSALIST(nTSWA)+LTRIM(STR(nTSC))+' '
							S4M(nTSWA)=S4(nTSWA) && remember the actual AVG value
							S4(nTSWA)=S4(nTSWA)+2

							IF nNOLI=pnList
								thisform.DrawWidth=2	
								thisform.Line(nTSWA*2+nL,nCLTop-S4M(nTSWA)*2,nTSWA*2+nL,nCLTop-S4(nTSWA)*2) && Affected timeslices
								thisform.Line(nTSC*2+nL,nCLTop+9,nTSC*2+nL,nCLTop+5) && Timeline
								IF nMemColor#thisform.ForeColor && only print nTSC when the colour changes
									nMemColor=thisform.ForeColor
									nZ=thisform.FontSize
									thisform.FontSize=5
									thisform.Print(LTRIM(STR(nTSC)),nTSC*2+nL-thisform.TextWidth(LTRIM(STR(nTSC)))/2,nCLTop+9+5)
									thisform.FontSize=nZ
								ENDIF
							ENDIF
							&& Overlay of S1
							thisform.DrawWidth=1
							thisform.PSet(nTSC*2+nL,nCLTop-S1(nTSC)-50)
							IF pnInputs<5 && then execute this loop but once
								EXIT
							ENDIF
						ENDFOR
						IF pnInputs<4 && then execute this loop but once
							EXIT
						ENDIF
					ENDFOR
				ENDFOR
			ENDFOR
		ENDFOR
	ENDFOR
	thisform.Print(LTRIM(STR(nTSC)),nTSC*2+nL-thisform.TextWidth(LTRIM(STR(nTSC)))/2,nCLTop+9+5) && TS count at end of TS line

	thisform.ForeColor=thisform.FCOLOR(nNOLI)
	thisform.CTSSP.Tag=LTRIM(STR(thisform.ForeColor))
	thisform.TSALIST
	?? CHR(7)
	RETURN

	PROCEDURE TSALIST(nTSC,nTSWA,nL,cTSALIST,nAT,nP)
	nTSC=pnCVC^pnInputs
	nP=1
	thisform.PRTXT(pcRCOR,nP)
	nP=nP+1

	thisform.PRTXT(pcRCOR+" permutation count : "+LTRIM(STR(thisform.PERMREP(pcRCOR))),nP)
	nP=nP+1

	thisform.PRTXT("Timeslices (TS) total : "+LTRIM(STR(nTSC))+;
						"   Color division : ("+LTRIM(STR(nTSC/(pnCVC*pnCVC)))+')*'+LTRIM(STR(pnCVC))+'*'+LTRIM(STR(pnCVC)),nP)
	nP=nP+1
	nTSWA=thisform.CTSSP.Value
	nL=OCCURS(' ',TSALIST(nTSWA))
	thisform.PRTXT("TSs compounded with TS("+LTRIM(STR(nTSWA))+") : "+LTRIM(STR(nL)),nP)
	nP=nP+1

	cTSALIST=LEFT(TSALIST(nTSWA),LEN(TSALIST(nTSWA))-1)
	nAT=AT(' ',cTSALIST,20)
	IF nL<20
		IF nL=0
			thisform.PRTXT("...",nP)
		ELSE
			thisform.PRTXT(cTSALIST,nP)
		ENDIF
	ELSE
		thisform.PRTXT(LEFT(cTSALIST,nAT)+" ...",nP)
	ENDIF
	nP=nP+1

	IF nL=0
		thisform.PRTXT("No affected TSs",nP)
	ELSE
		thisform.PRTXT("Affected TSs : "+LTRIM(STR(nTSC/nL))+" / "+LTRIM(STR(nTSC)),nP)
	ENDIF
	nP=nP+1
	RETURN

	PROCEDURE PRTXT(cT,nV,	nFC,nHor,nVer,nX)
	nFC=thisform.ForeColor
	thisform.ForeColor=pnZwart
	nVer=pnH-(pnH-thisform.CLIST4.Top-thisform.CLIST4.Height)/2-(5-nV)*15+7
	nHor=pnW*3/4-thisform.TextWidth(SPACE(154))/2
	thisform.Print(SPACE(154),nHor,nVer)
	nHor=pnW*3/4-thisform.TextWidth(' '+cT+' ')/2
	IF nVer>1000
		nVer=nV
	ENDIF
	thisform.ForeColor=nFC
	thisform.Print(cT,nHor,nVer)
	RETURN
	
	PROCEDURE PERMLIST(cCC,c1,c2,c3,c4,c5,cPermList,nA,nB,nC,nD,nE,cC,nX,cX,nY,cY,nPermut,nZ,cZ)
	thisform.PREP
	cCC=LEFT("abcde",pnInputs)
	STORE '' TO c1,c2,c3,c4,c5,cPermList
	FOR nA=1 TO pnInputs
		c1=SUBSTR(cCC,nA,1)
		FOR nB=1 TO pnInputs
			c2=SUBSTR(cCC,nB,1)
			FOR nC=1 TO pnInputs
				c3=SUBSTR(cCC,nC,1)
				FOR nD=1 TO IIF(pnInputs<4,1,pnInputs)
					IF pnInputs=>4
						c4=SUBSTR(cCC,nD,1)
					ENDIF
					FOR nE=1 TO IIF(pnInputs<5,1,pnInputs)
						IF pnInputs=5
							c5=SUBSTR(cCC,nE,1)
						ENDIF
						cPermList=cPermList+c1+c2+c3+c4+c5+','
					ENDFOR
				ENDFOR
			ENDFOR
		ENDFOR
	ENDFOR
	pcPERMLIST=cPermList
	COMBLIST(6)=thisform.COMBLIST(cPermList)
	cC=COMBLIST(6)
	thisform.SetAll("Visible",.F.,"CLIST")
	nC=LEN(cC)/(pnInputs+1)
	SET COMPATIBLE OFF
	STORE 0 TO CAT
	SET COMPATIBLE ON
	FOR nX=pnInputs TO 1 STEP -1
		cX=LTRIM(STR(nX-1))
		COMBLIST(nX)=''
		FOR nY=1 TO nC
			cY=SUBSTR(cC,(nY-1)*(pnInputs+1)+1,pnInputs+1)
			IF IIF("a"$cY,1,0)+IIF("b"$cY,1,0)+IIF("c"$cY,1,0)+IIF("d"$cY,1,0)+IIF("e"$cY,1,0)=pnInputs-nX+1
				COMBLIST(nX)=COMBLIST(nX)+cY
				cC=STRTRAN(cC,cY,SPACE(pnInputs+1))
			ENDIF
		ENDFOR
		nY=OCCURS(' ',COMBLIST(nX))
		FOR nZ=1 TO pnInputs
			CAT(nX,nZ)=thisform.GROUPPC(COMBLIST(nX),LEFT('abcde',pnInputs-nZ+1))
		 	&& all permutations of the combination group with nX lacking inputs, starting with LEFT('abcde',pnInputs) 
		ENDFOR
		CAT(nX,nZ)=thisform.GROUPPC(COMBLIST(nX),LEFT('abcde',pnInputs-nZ+1))
		nPermut=pnInputs^pnInputs
		cZ=''
		nP=0
		FOR nZ=1 TO pnInputs+1
			IF CAT(nX,nZ)>0
				cZ=cZ+"Sp"+LTRIM(STR(pnCVC^(nZ-1)))+":"+LTRIM(STR(CAT(nX,nZ)))+", "
			ENDIF
			nP=nP+CAT(nX,nZ)
			CAT(6,nZ)=CAT(6,nZ)+CAT(nX,nZ)
		ENDFOR
		cValue="Ordered connectivity possibilities with "+LTRIM(STR(nX-1))+" input"+IIF((nX-1)#1,'s','')+" lacking : "+;
				 "C "+LTRIM(STR(nY))+"/"+LTRIM(STR(nC))+", "+;
				 "(P "+LTRIM(STR(nP))+"/"+LTRIM(STR(nPermut))+"), "+cZ
		thisform.CLIST&cX..Value=cValue+CHR(13)+COMBLIST(nX)
		thisform.CLIST&cX..Visible=.T.
	ENDFOR
	RETURN(cC)
	
	PROCEDURE COMPOUNDINGS(cFont,nP,nPermut,cA,nIncl,nLen,nZ,nAT)
	cFont=thisform.FontName
	thisform.FontName="Courier New"
	nP=thisform.CLIST4.Top+thisform.CLIST4.Height
	nPermut=pnInputs^pnInputs
	thisform.ForeColor=pnWit
	cA="abcde"
	nIncl=0
	nLen=0
	DIMENSION TXT[pnInputs+1]
	FOR nZ=1 TO pnInputs+1
		nIncl=nIncl+CAT(6,nZ)
		TXT(nZ)="Group "+LEFT(cA,pnInputs+1-nZ)+;
				" S"+LTRIM(STR(pnCVC^(nZ-1)))+;
				IIF(nZ>1," excl "+LEFT(cA,pnInputs+2-nZ),'')+;
				" : "+STR(CAT(6,nZ),4)+" ("+STR(ROUND(CAT(6,nZ)*100/nPermut,0),2)+"%)"+;
				IIF(nZ>1," - incl "+LEFT(cA,pnInputs+2-nZ)+;
				" : "+LTRIM(STR(nIncl))+" ("+STR(ROUND(nIncl*100/nPermut,0),3)+"%)",SPACE(16+4+pnInputs*1)+'.')
		nAT=AT(":",TXT(nZ))
		nLen=MAX(nLen,LEN(LEFT(TXT(nZ),nAT)))
	ENDFOR
	
	FOR nZ=1 TO pnInputs+1
		nAT=AT(":",TXT(nZ))
		TXT(nZ)=STUFF(TXT(nZ),nAT-1,0,SPACE(nLen-nAT))
		TXT(nZ)=STUFF(TXT(nZ),RAT(":",TXT(nZ))-1,0,SPACE(LEN(TXT(1))-LEN(TXT(nZ))))
		thisform.PRTXT(TXT(nZ),nP+(nZ-1)*15)
	ENDFOR
	thisform.FontName=cFont
	RETURN

	PROCEDURE KeyPress
	LPARAMETERS nKey, nShiftAltCtrl,	nL,nX,cL
	nL=0
	
	FOR nX=1 TO LEN(pcRCOR)
		IF CHR(96+nX)$pcRCOR
			nL=nL+1
		ENDIF
	ENDFOR
	nL=pnInputs-nL
	cL=LTRIM(STR(nL))

	DO CASE
	CASE nKey=5 && UA
		IF nL>0
			nL=nL-1
		ENDIF
		cL=LTRIM(STR(nL))
		thisform.CLIST&cL..SelStart=AT(CHR(13),thisform.CLIST&cL..Value,1)+1
	CASE nKey=24 && DA
		IF nL<pnInputs-1
			nL=nL+1
		ENDIF
		cL=LTRIM(STR(nL))
		thisform.CLIST&cL..SelStart=AT(CHR(13),thisform.CLIST&cL..Value,1)+2
	CASE nKey=4 && RA
		IF LEN(thisform.CLIST&cL..Value)>thisform.CLIST&cL..SelStart+pnInputs+1
			thisform.CLIST&cL..SelStart=thisform.CLIST&cL..SelStart+pnInputs+1
		ENDIF
	CASE nKey=19 && LA
		IF AT(CHR(13),thisform.CLIST0.Value,1)+3<thisform.CLIST&cL..SelStart-(pnInputs+1)
			thisform.CLIST&cL..SelStart=thisform.CLIST&cL..SelStart-(pnInputs+1)
		ENDIF
	OTHERWISE
		RETURN
	ENDCASE
	thisform.CLIST&cL..Click
	RETURN

	PROCEDURE COMBLIST(cC,	nC,cY,nX,cX,cRCOR)
	nC=LEN(cC)/(pnInputs+1)
	cY=''
	FOR nX=1 TO nC
		cX=SUBSTR(cC,(nX-1)*(pnInputs+1)+1,pnInputs)
		cRCOR=thisform.COMBOR(cX)
		IF NOT cRCOR$cY
			cY=cY+cRCOR+' '
		ENDIF
	ENDFOR
	RETURN(cY)
	
	PROCEDURE COMBOR(cRCAG,	cRCOR,nI,cPI,nRI,cRI)
	cRCOR=SPACE(pnInputs) && list of 'open' places
	FOR nI=1 TO pnInputs
	&& loop through the inputs
		cPI=CHR(nI+96)
		IF cPI$cRCAG && the input is present in the produced combination of inputs ?
			cRCOR=STUFF(cRCOR,nI,1,cPI) && place it where it belongs (xth input at xth place) in cRCOR
			cRCAG=STUFF(cRCAG,AT(cPI,cRCAG),1,'') && remove this input from cRCAG
		ENDIF
	ENDFOR

	cRCAG=thisform.ALFABETIC(cRCAG)
	FOR nRI=1 TO LEN(cRCAG)
	&& what is left in cRCAG are redundant inputs : their number should equal the leftover open places in cRCOR
	&& loop through them
		cRI=SUBSTR(cRCAG,nRI,1) && a redundant input
		&& place the redundant input in a leftover open place in cRCOR
		cRCOR=STUFF(cRCOR,AT(' ',cRCOR),1,cRI)
	ENDFOR
	&& cRCOR is 'ordered' in function of the nested loops of dimensions
	RETURN(cRCOR)
	
	PROCEDURE ALFABETIC(cIn,	cOut,nX,cX,nY)
	cOut=' '
	FOR nX=1 TO LEN(cIn)
		cX=SUBSTR(cIn,nX,1)
		FOR nY=1 TO LEN(cOut)
			IF cX>SUBSTR(cOut,nY,1)
				LOOP
			ENDIF
			cOut=STUFF(cOut,nY,0,cX)
			cX=''
		ENDFOR
		cOut=cOut+cX
	ENDFOR
	cOut=CHRTRAN(cOut,' ','')
	RETURN(cOut)
								
	PROCEDURE GROUPPC(cCLIST,cCat,	nPC,nX,cX))
	cCLIST=' '+cCLIST
	nPC=0
	FOR nX=1 TO OCCURS(' ',cCLIST)
		cX=STREXTRACT(cCLIST,' ',' ',nX)
		IF cX=cCat AND NOT cX=LEFT("abcdef",LEN(cCat)+1)
			nPC=nPC+thisform.PERMREP(cX)
		ENDIF
	ENDFOR
	RETURN(nPC)
	
	PROCEDURE PERMREP(cC,	nPR)
	IF EMPTY(cC)
		RETURN(0)
	ENDIF
	nPR=thisform.FT(LEN(cC))/;
		(thisform.FT(OCCURS('a',cC))*thisform.FT(OCCURS('b',cC))*thisform.FT(OCCURS('c',cC))*thisform.FT(OCCURS('d',cC))*thisform.FT(OCCURS('e',cC)))
	RETURN(nPR)

	PROCEDURE FT(nN,	nF,nX)
	nF=1
	FOR nX=1 TO nN
		nF=nF*nX
	ENDFOR	
	RETURN(nF)

	PROCEDURE RANDCOMB(nNOLI,lOnly,	nX,cX,lFlag,nFlag,nR,cR)
	DO WHILE .T.
		cX=''
		IF lOnly
			IF nNOLI=pnInputs-1
				FOR nX=1 TO pnInputs
					cX=cX+REPLICATE(CHR(96+nX),pnInputs)+' '
				ENDFOR
				cX=SUBSTR(cX,(pnInputs+1)*INT(RAND()*LEN(cX)/(pnInputs+1))+1,pnInputs)
				RETURN(cX)
			ENDIF
		ENDIF
		lFlag=.F.
		FOR nX=1 TO pnInputs && generate a string pnInputs long 
			cX=cX+CHR(96+INT(RAND()*pnInputs)+1) && give each character randomly a number between 1 and pnInputs
		ENDFOR
		nFlag=0
		FOR nR=1 TO pnInputs && check if a number is redundant
			cR=CHR(nR+96)
			IF lOnly && Will only accept combinations with nNOLI lacking inputs
				IF NOT cR$cX
					nFlag=nFlag+1
				ENDIF
			ELSE
				IF OCCURS(cR,cX)>nNOLI && If a number occurs x times then there are also x-1 lacking inputs
				&& Reject the combination (and make another one) if nX-1>nNOLI (the number of lacking inputs that is allowed)
					nFlag=nFlag+OCCURS(cR,cX)-1
				ENDIF
			ENDIF
		ENDFOR
		IF nFlag>nNOLI OR (lOnly AND NOT nFlag=nNOLI)
			lFlag=.T.
		ENDIF
		
		IF NOT lFlag
			EXIT
		ENDIF
	ENDDO
	RETURN(cX)

	PROCEDURE MAKE_S1(nTS)
	FOR nTS=1 TO pnConSteps
		S1(nTS)=thisform.S1BASE((nTS))
		S4(nTS)=S1(nTS)
	ENDFOR
	RETURN

	PROCEDURE S1BASE(nTS)
	nTS=nTS/(1.5*(257-nTS)/257+.5)
&&	nTS=nTS/ICASE(nTS<50,2,nTS<150,1,.5)
	RETURN(MAX(1,(ABS(MOD(nTS,10)-5)/40)*50+2+((SIN(DTOR(nTS*13-90))+1)/4)*25))

ENDDEFINE

DEFINE CLASS CONCB AS COMMANDBUTTON
	Height		= 30
	FontBold		= .T.
	Visible		= .T.
	WordWrap		= .T.
	
	PROCEDURE Init(nX)
	nX=VAL(SUBSTR(this.Name,5,1))
	this.Left=(nX-3)*pnWObj
	IF LEFT(this.Name,1)="C"
		this.Left=this.Left+pnW/2
	ENDIF
	this.Width=pnWObj
	this.Caption=LTRIM(STR(nX))+" inputs"
	RETURN
	
	PROCEDURE Click(nX,cX,cPC)
	cPC=LEFT(this.Name,1)
	FOR nX=3 TO 5
		cX=LTRIM(STR(nX))
		thisform.&cPC.CON&cX..ForeColor=pnZwart
		thisform.PCON&cX..ForeColor=pnZwart
	ENDFOR
	pnInputs=VAL(SUBSTR(this.Name,5,1))
	cX=LTRIM(STR(pnInputs))
	this.ForeColor=pnRood
	IF cPC='P'
		thisform.DORUN
	ELSE
		thisform.PERMLIST
		thisform.CLIST0.SelStart=AT(CHR(13),thisform.CLIST0.Value,1)+2
		thisform.CLIST0.Click(.T.)
		thisform.COMPOUNDINGS
		plCMD=.T.
		thisform.PCON&cX..ForeColor=pnRood
		thisform.DORUN
	ENDIF
	RETURN

ENDDEFINE

DEFINE CLASS PCLIST AS EDITBOX
	FontName				= "Arial"
	FontSize				= 7
	FontBold				= .T.
	BackColor			= pnZwart
	DisabledBackColor	= pnZwart
	ScrollBars			= 2
	ReadOnly				= .T.
	
	PROCEDURE Init(nX,cX)
	cX=LEFT(this.Name,1)
	nX=VAL(RIGHT(this.Name,1))
	IF cX="P"
		this.Left=pnWObj*3
		this.Width=pnWObj*3
		this.Height=(pnH-thisform.PCON3.Height)/5
	ELSE
		this.Left=pnW/2
		this.Width=this.Left
		this.Height=40
	ENDIF
	this.Top=thisform.&cX.CON3.Height+nX*this.Height
	this.ForeColor=thisform.FCOLOR(nX)
	RETURN
	
	PROCEDURE Click(lnoCPs,nS,cV,nAT,cS,nO,cA)
	IF this.Name='P'
		RETURN
	ENDIF
	nS=this.SelStart
	cV=this.Value
	nAT=AT(CHR(13),cV,1)
	cV=CHRTRAN(cV,CHR(13),' ')
	IF nS>nAT
		cS=SUBSTR(cV,nS-pnInputs+1,pnInputs*2)
		nO=OCCURS(' ',cS)
		IF nO=>2
			cA=STREXTRACT(cS,' ',' ',nO-1)
		ENDIF
	ENDIF
	IF NOT EMPTY(cA)
		pcRCOR=cA
		pnList=VAL(RIGHT(this.Name,1))
		thisform.DORUN2
		IF NOT lnoCPS
			thisform.COMPOUNDINGS
		ENDIF
	ENDIF
	RETURN
	
ENDDEFINE

DEFINE CLASS PLIST AS PCLIST
ENDDEFINE

DEFINE CLASS CLIST AS PCLIST
ENDDEFINE

DEFINE CLASS ISP AS SPINNER
	FontBold				= .T.
	Visible				= .T.
	SpinnerLowValue	= 1
	Increment			= 1
	Value					= 1
	Height				= 30
	FontSize				= 7
	
	PROCEDURE Init
	DO CASE
	CASE this.Name="PIT" OR this.Name="CIT"
		this.Left=pnWobj*3+pnWObj*1/2
		this.Enabled=IIF(this.Name='P',.T.,.F.)
	CASE this.Name="PTS" OR this.Name="CTS"
		this.Left=pnWObj*4+pnWObj*1/2
	ENDCASE
	IF this.Name='C'
		this.Left=this.Left+pnW/2
	ENDIF
	this.Width=pnWobj*1/2
	RETURN
	
	PROCEDURE UpClick
	this.Click
	RETURN
	
	PROCEDURE DownClick
	this.Click
	RETURN
	
	PROCEDURE Click(nX,cX,cVal)
	IF this.Name='P'
		FOR nX=0 TO pnInputs-1
			cX=LTRIM(STR(nX))
			IF 'Ordered'$thisform.PORCB.Caption
				IF plCMD
					LOCATE FOR INPUTS=pnINPUTS AND NOLI=nX AND TS=thisform.PTSSP.Value
					cVal=RTRIM(LISTOR1+LISTOR2)
					cVal=STRTRAN(cVal,"Iteration 1","Iteration "+LTRIM(STR(thisform.PITSP.Value)))
					thisform.PLIST&cX..Value=cVal
				ELSE
					thisform.PLIST&cX..Value=PLISTOR(nX*pnITs+thisform.PITSP.Value,thisform.PTSSP.Value)
				ENDIF
			ELSE
				IF plCMD
					LOCATE FOR INPUTS=pnINPUTS AND NOLI=nX AND TS=thisform.PTSSP.Value
					cVal=RTRIM(LISTAG1+LISTAG2)
					cVal=STRTRAN(cVal,"Iteration 1","Iteration "+LTRIM(STR(thisform.PITSP.Value)))
					thisform.PLIST&cX..Value=cVal
				ELSE
					thisform.PLIST&cX..Value=PLISTAG(nX*pnITs+thisform.PITSP.Value,thisform.PTSSP.Value)
				ENDIF
			ENDIF
		ENDFOR
	ELSE
		IF this.Name='CTS'
			thisform.ForeColor=VAL(this.Tag)
			thisform.TSALIST
		ENDIF
	ENDIF
	RETURN
	
ENDDEFINE

DEFINE CLASS ICB AS COMMANDBUTTON
	FontBold		= .T.
	Visible		= .T.
	WordWrap		= .T.
	Height		= 30
	FontSize		= 7
	
	PROCEDURE Init
	DO CASE
	CASE this.Name="PIT" OR this.Name="CIT"
		this.Left=pnWobj*3
		this.Width=pnWObj-pnWObj*1/2
		this.Caption="Iteration"
		this.Enabled=IIF(this.Name='PIT',.T.,.F.)
	CASE this.Name="PTS" OR this.Name="CTS"
		this.Left=pnWObj*4
		this.Width=pnWObj-pnWObj*1/2
		this.Caption="Timeslice"
	CASE this.Name="POR" OR this.Name="COR"
		this.Left=pnWobj*5
		this.Width=pnWObj
		this.Caption=IIF(this.Name="POR","Input permutations","Ordered combinations")
	ENDCASE
	IF this.Name='C'
		this.Left=this.Left+pnW/2
	ENDIF
	RETURN
	
	PROCEDURE Click
	DO CASE
	CASE this.Name='POR'
		IF this.Caption="Ordered combinations"
			this.Caption="Input permutations"
		ELSE
			this.Caption="Ordered combinations"
		ENDIF
		thisform.PITSP.Click
		thisform.PTSSP.Click
	ENDCASE
	RETURN
	
ENDDEFINE

PROCEDURE INITCOLOR
pnZwart=				RGB(0,0,0)
pnLichtGrijs=		RGB(192,192,192)
pnGrijs=				RGB(128,128,128)
pnDonkerGrijs=		RGB(32,32,32)
pnWit=				RGB(255,255,255)

pnLichtRood=		RGB(255,128,128)
pnRood=				RGB(255,0,0)
pnDonkerRood=		RGB(128,0,0)
pnLichtGroen=		RGB(128,255,128)
pnGroen=				RGB(0,255,0)
pnDonkerGroen=		RGB(0,128,0)

pnLichtBlauw=		RGB(192,192,255)
pnBlauw=				RGB(0,0,255)
pnDonkerBlauw=		RGB(0,0,128)
pnGeel=				RGB(255,255,0)
pnLichtGeel=		RGB(255,255,128)
pnHalfDonkerGeel=	RGB(255,128,0)
pnDonkerGeel=		RGB(128,128,0)

pnCyaan=				RGB(0,255,255)
pnLichtCyaan=		RGB(128,255,255)
pnHalfDonkerCyaan=RGB(0,128,255)
pnDonkerCyaan=		RGB(0,128,128)
pnMagenta=			RGB(255,0,255)
pnLichtMagenta=	RGB(255,128,255)

pnGoud=				RGB(255,223,0) &&RGB(212,175,55)

RETURN
