* DECORRELATOR - stand-alone version of the DECORRELATOR form of CEREBREADER.PRG
* Dr. R. BEUNIS - Visual FoxPro 9.0
*
* Added for the publication on GitHub (2026): this start-up part, the timer WAITCLOSE and the minimal class
* BASEFORM. The classes DECORRELATOR, DASHBOARD and their helper classes are copied from the author's article
* reader CEREBREADER.PRG (the version with which the figures and videos of the article were made); BASEFORM
* keeps only the methods these forms use. Changes for this version, marked '&& GitHub version:' :
*  - a run starts at once (no 'Press any key to continue');
*  - in the interactive mode the dashboard is open at once, on the right half of the screen (BASEFORM has
*    WindowState 0 instead of 2), and both forms are not modal, so that the dashboard stays open during a run;
*    during a run, Reset also stops the run, and the Execute buttons and 'Load values of demo' do nothing;
*  - the dashboard is laid out faster at the start.
*
* Usage:  DO decorrelator              interactive mode (dashboard)
*         DO decorrelator WITH "80"    demo 80 (video "demo-1-80" of the article, Part 2)
*
* Articles: Beunis R. (2022) The electrosensory lateral line lobe (ELL) in mormyrid fish : a stepping stone
*           to the understanding of the cerebellum ? Part 1 (the ELL), Zenodo, doi:10.5281/zenodo.17602438
*           (demos 5-49), and Part 2 (the cerebellum), doi:10.5281/zenodo.17613147 (demos 80-83).

PARAMETERS cDemo

IF NOT VERSION(2)=2
	lcPath = JUSTPATH(SET('RESOURCE',1))
	SET RESOURCE OFF
	ERASE ('&lcPath.\FOXUSER.*')
ENDIF
CLOSE ALL

PUBLIC pcSAFETY,pcSTRICTDATE,pcROOT,plTESTVERSION0,pcCR_DBaseDir,plScreenCapt,plNOCancel,plCalled,pcCMD,plReport
STORE .F. TO plTESTVERSION0,plScreenCapt,plNOCancel,plCalled,plReport
STORE '' TO pcCR_DBaseDir,pcCMD
SET DELETED ON
pcSAFETY=SET('SAFETY')
SET SAFETY OFF
pcSTRICTDATE=SET('STRICTDATE')
SET STRICTDATE TO 0
SET DATE TO DMY
SET HOURS TO 24
SET UDFPARMS TO REFERENCE
SET COMPATIBLE ON
SET MEMOWIDTH TO 250
SET CENTURY ON
SET TALK OFF

pcROOT=SYS(16)
pcROOT=LEFT(pcROOT,RAT('\',pcROOT)-1)
CD (pcRoot)

PUBLIC pnZwart,pnLichtGrijs,pnGrijs,pnDonkerGrijs,pnWit,;
		 pnLichtRood,pnRood,pnDonkerRood,pnLichtGroen,pnGroen,pnDonkerGroen,;
		 pnLichtBlauw,pnBlauw,pnDonkerBlauw,pnGeel,pnLichtGeel,pnHalfDonkerGeel,pnDonkerGeel,;
		 pnCyaan,pnLichtCyaan,pnHalfDonkerCyaan,pnDonkerCyaan,pnMagenta,pnLichtMagenta,pnGoud
DO INITCOLOR

* The variables of the DECORRELATOR form, as in the main program of CEREBREADER.PRG (unchanged)

PUBLIC oDecorrelator,oDashBoard,pnH,pnSteps,pnCycles,pnR,pnL,pnHMem,pnIC,pnTop1,pnTop2,pnTop3,pnTop4,pnTop5,pnTop6,pnTop7,pnTop8,;
		 pnAVMinS1,pnAVMinS4,pnAVMinS2,pnAVMaxS2,pnAVMinS5,pnAVMinS3,pnAVMaxS5,pnBShift,pnLift,pnLift1,pnLift2,pnLift3,pnLift4,pnLiftM1,pnLiftM2,pnLiftM3,pnMRS2,pnMRMAXS2,pnLiftS1,pnLiftS2,;
		 plBreak,pnSpeed,pnSS,pnSecs,pnW,pnLeft1,pnLeft2,pnLeft3,pnLeft4,pnMaxLFITH,pnDivMax,;
		 pnDivS1,pnDivS2,pcScAM,pcScA,pnTop,pcWA,pcILF,pnILF,pcGFDUR,pcYBlok,plBox,plFlag,plEBR,;
		 plCon,pnMeanS1,pnMeanS2,pnF,pnWDB,pnBC,pcFields,pcObjects,pnP,pnD,pnPv,pnDv,pnHI,pnMaxFit,pcSpecs,plCMD,plPause,plQuit,;
		 pnAVG1,pnAVG2,pnAVG3,pnAVG4,pnAVG5,pnAVG6,pnValueSet,pcTxt,pnAVG,pnMEMS1,pnMemS5,pcGFD_CWA,pcGFT_CWA,pnStart1,pnStart2,pnStart3,pnStart4,plScreenShow
		 
pnSteps=250
STORE 99999 TO pnAVMinS1,pnAVMinS4, pnAVMinS2,pnAVMinS5, pnAVMinS3
pnSpeed=3
STORE 0 TO pnSS,pnSecs,pnW,pnTop,pnMaxLFITH,pnIC,pnTop1,pnTop2,pnTop3,pnTop4,pnTop5,pnTop6,pnTop7,pnTop8,pnL,pnMeanS1,pnMeanS2,pnF,pnWDB,pnBC,pnP,pnD,pnPv,pnDv,;
		   pnLeft3,pnLeft4,pnMaxFit,pnLift1,pnLift2,pnLift3,pnLift4,pnLiftM1,pnLiftM2,pnLiftM3,pnAVG1,pnAVG2,pnAVG3,pnAVG4,pnAVG5,pnAVG6,pnAVG,;
		   pnMEMS1,pnMemS5,pnAVMaxS2,pnAVMaxS5,pnBShift,pnLift,pnMRS2,pnMRMAXS2,pnLiftS1,pnLiftS2,pnCycles
STORE 1 TO pnDivS1,pnDivS2,pnDivMax,pnR,pnValueSet,pnILF,pnStart1,pnStart2,pnStart3,pnStart4

pnLeft1=30
pnLeft2=330
pnLeft3=(_SCREEN.Width-8*2)/2+30
pnLeft4=(_SCREEN.Width-8*2)/2+330

pnHI=95

pnHMem=30
STORE '' TO pcScAM,pcScA,pcWA,pcILF,pcGFDUR,pcYBlok,pcFields,pcObjects,pcSpecs,pcTxt,pcGFD_CWA,pcGFT_CWA
STORE .F. TO plBox,plBreak,plCon,plCMD,plPause,plQuit,plFlag,plEBR,plScreenShow

* In CEREBREADER the form is shown next to the main window oCerebreader (width 1264)
PUBLIC oCerebreader
oCerebreader=CREATEOBJECT("Empty")
ADDPROPERTY(oCerebreader,"Width",1264)

* The settings table MEM.DBF is created empty (all zeros) at the first start; in CEREBREADER it always existed.
* An empty record would make a run loop endlessly (DLW, the step of the loops, is 0), so that at the first start
* the values of demo 5 are loaded (as with 'Load values of demo 5'), in both value sets.
LOCAL lFreshMem
lFreshMem=NOT FILE("MEM.DBF")
IF EMPTY(cDemo)
	oDecorrelator=CREATEOBJECT('DECORRELATOR',.F.,'',.F.,'Decorrelator')
ELSE
	oDecorrelator=CREATEOBJECT('DECORRELATOR',.T.,cDemo,.F.,'demo-1-'+cDemo)
ENDIF
oDecorrelator.Show()
IF lFreshMem AND EMPTY(cDemo)
	LOCAL lcAlias
	lcAlias=ALIAS()
	oDecorrelator.DEMO(.T.,5)
	SELECT MEM
	GO 1
	SCATTER MEMVAR
	GO 2
	GATHER MEMVAR
	GO 1
	SELECT (lcAlias)		&& the run procedures work in the current work area (SIMCOR1)
ENDIF
IF EMPTY(cDemo) AND TYPE("oDashBoard")="O" AND NOT ISNULL(oDashBoard)
	oDashBoard.AlwaysOnTop=.T.	&& above the DECORRELATOR form, which is AlwaysOnTop
	oDashBoard.Show()		&& the dashboard is open at once (in a demo it would cover the demo: "Show dashboard")
ENDIF
* both forms are not modal: wait until the DECORRELATOR form is closed
PUBLIC oWaitClose
oWaitClose=CREATEOBJECT("WAITCLOSE")
READ EVENTS
oWaitClose=.NULL.

SET STRICTDATE TO &pcSTRICTDATE
SET SAFETY &pcSAFETY
SET TALK ON
RELEASE ALL
CLEAR ALL
CLOSE ALL
RETURN

* .T. while a run is in progress (ALLCYCLES or ONECYCLE active): the dashboard stays open during a run
FUNCTION RUNNING_NOW(nX)
FOR nX=1 TO PROGRAM(-1)
	IF "ALLCYCLES"$UPPER(PROGRAM(nX)) OR "ONECYCLE"$UPPER(PROGRAM(nX))
		RETURN .T.
	ENDIF
ENDFOR
RETURN .F.

* Ends READ EVENTS when the DECORRELATOR form has been closed (and closes the dashboard)
DEFINE CLASS WAITCLOSE AS TIMER
	Interval = 300

	PROCEDURE Timer
	IF TYPE("oDecorrelator")#"O" OR ISNULL(oDecorrelator)
		this.Enabled=.F.
		IF TYPE("oDashBoard")="O" AND NOT ISNULL(oDashBoard)
			oDashBoard.Release
		ENDIF
		CLEAR EVENTS
	ENDIF
	RETURN

ENDDEFINE

* ------------------------------------------------------------------------------------------------------
* BASEFORM of CEREBREADER.PRG: only the properties and the methods used by the forms below
* ------------------------------------------------------------------------------------------------------
DEFINE CLASS BASEFORM AS FORM
	WindowState				= 0		&& 2 in CEREBREADER.PRG; 0 so that the dashboard appears on the right half of the screen
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

	PROCEDURE Activate
	IF NOT thisform.lBaseForm
		thisform.lBaseForm=.T.
	ENDIF
	RETURN

PROCEDURE GETSPECIAL()
&& Returns the path to one of Windows' 'special folders' such as My Documents, Application Data, Program Files, etc.

&& Parameters:
&& - The folder's CSIDL;
&& - A flag to say the folder should be created if it doesn't already exist.

&& Returns the path to the specified folder.
&& If the CLSID is invalid, or the folder doesn't exist (and the second parameter is .F.), returns an empty string.

LPARAMETERS tnFolder, tlCreate
LOCAL lcPath, lnPidl, lnPidlOK, lnFolderOK
#DEFINE MAX_PATH 260
#DEFINE CREATE_FLAG 32768 
&& Declare the API functions
DECLARE LONG SHGetSpecialFolderLocation IN shell32 LONG Hwnd, LONG lnFolder, LONG @pPidl
DECLARE LONG SHGetPathFromIDList IN shell32 LONG pPidl, STRING @pszPath
DECLARE CoTaskMemFree IN ole32 LONG pVoid

lcPath = SPACE(MAX_PATH)
lnPidl = 0

IF tlCreate && If .T. is passed as second param, we want to create the folder if it doesn't already exist.
	tnFolder = tnFolder + CREATE_FLAG
ENDIF 
	
lnPidlOK = SHGetSpecialFolderLocation(0, tnFolder, @lnPidl) && Get the PIDL

IF lnPidlOK = 0 && Pidl found OK; get the folder
  lnFolderOK = SHGetPathFromIDList(lnPidl, @lcPath)
  IF lnFolderOK = 1 && Folder found OK; trim the string at the null terminator
    lcPath = LEFT(lcPath, AT(CHR(0), lcPath) - 1)
  ENDIF 
ENDIF 

CoTaskMemFree(lnPidl) && Free the ID List
RETURN ALLTRIM(lcPath)

	PROCEDURE SCREENCAPT
	IF NOT plScreenCapt
		RETURN
	ENDIF
	CLEAR TYPEAHEAD
	WAIT '' TIMEOUT .5

	&& Equivalent of pressing PrintScreen
	DECLARE INTEGER keybd_event IN Win32API ;
			  INTEGER, INTEGER, INTEGER, INTEGER
	VK_SNAPSHOT = 44
	VK_LMENU = 164
	KEYEVENTF_KEYUP = 2
	KEYEVENTF_EXTENDEDKEY = 1

	IF .F.
		DOEVENTS
		keybd_event(VK_SNAPSHOT, 1, 0, 0 )
		keybd_event(VK_SNAPSHOT, 1, KEYEVENTF_KEYUP, 0 )
		DOEVENTS
	ENDIF
			
	IF .T.
		DOEVENTS
		keybd_event( VK_LMENU,    0, KEYEVENTF_EXTENDEDKEY, 0 )  && key down
		keybd_event( VK_SNAPSHOT, 0, KEYEVENTF_EXTENDEDKEY, 0 )
		keybd_event( VK_SNAPSHOT, 0, KEYEVENTF_EXTENDEDKEY + KEYEVENTF_KEYUP, 0 )
		keybd_event( VK_LMENU,    0, KEYEVENTF_EXTENDEDKEY + KEYEVENTF_KEYUP, 0 )
		DOEVENTS
	ENDIF
				
	WAIT '' TIMEOUT .5
	RETURN

ENDDEFINE

* ------------------------------------------------------------------------------------------------------
* The forms DECORRELATOR and DASHBOARD of CEREBREADER.PRG (changes marked with && GitHub version:)
* ------------------------------------------------------------------------------------------------------

DEFINE CLASS DECORRELATOR AS BASEFORM
	WindowState		= 2
	ShowTips		= .T.
	AlwaysOnTop		= .T.
	BackColor		= pnGrijs
	ControlBox			= .T.
	MaxButton			= .F.
	MinButton			= .F.
	
	nH					= 0
	nW					= 0
	lDecorrelator	= .F.

	ADD OBJECT FIT1 AS LABEL WITH Left=pnLeft2, Height=30, Width=pnSteps, Alignment=2, Caption=''
	ADD OBJECT EB AS EDITBOX WITH ReadOnly=.F., Enabled=.T., IntegralHeight=.T., FontSize=8
	ADD OBJECT HLTXT AS LABEL WITH Visible=.F.
	
	ADD OBJECT LB01 AS LABEL WITH Left=pnLeft2+1, Width=pnSteps, Height=5, Visible=.F., Caption='', BackStyle=1 , BackColor=pnLichtRood
	ADD OBJECT LB011 AS LABEL WITH Left=pnLeft2+1, Width=pnSteps, Height=5, Visible=.F., Caption='', BackStyle=1 , BackColor=pnWit
	&& Label that replaces a piece of the lines in S4 when S4 gets too high
	ADD OBJECT LB02 AS LABEL WITH Left=pnLeft2+1, Width=pnSteps, Height=5, Visible=.F., Caption='', BackStyle=1 , BackColor=pnCyaan
	ADD OBJECT LB022 AS LABEL WITH Left=pnLeft2+1, Width=pnSteps, Height=5, Visible=.F., Caption='', BackStyle=1 , BackColor=pnWit
	&& Label that replaces a piece of the lines in S4 when S4 gets too high
	ADD OBJECT LBP AS EDITBOX WITH Left=pnLeft1, Width=pnSteps, Height=180, BackColor=pnLichtGrijs, FontSize=8,;
								   Value='Decorrelating algorithm', Alignment=2, ReadOnly=.T., ScrollBars=0
	ADD OBJECT LBS1 AS LB WITH Left=pnLeft1
	ADD OBJECT LBS2 AS LB WITH Left=pnLeft1
	ADD OBJECT LBS3 AS LB WITH Left=pnLeft1
	ADD OBJECT LBS4 AS LB WITH Left=pnLeft2
	ADD OBJECT LBS5 AS LB WITH Left=pnLeft2
	ADD OBJECT LBS6 AS LB WITH Left=pnLeft2
	ADD OBJECT LBS7 AS LB WITH Left=pnLeft2
	ADD OBJECT LBS8 AS LB WITH Left=pnLeft2

	ADD OBJECT LBMGC AS LBE WITH Top=10, Caption="MG1C"+CHR(13)+"Iterations :   0", Visible=.F.
	ADD OBJECT LBFUC AS LBE WITH Top=10, Caption="FuC", Visible=.F.
	
	ADD OBJECT CBDB AS COMMANDBUTTON WITH Width=100, Height=25, Caption="Show dashboard", BackColor=pnCyaan, WordWrap=.T., FontSize=8, FontBold=.T.

	ADD OBJECT US0 AS LINE WITH BorderColor=pnCyaan, Width=0, Visible=.F., BorderWidth=3
	ADD OBJECT US1 AS LINE WITH BorderColor=pnRood, Width=0, Visible=.F., BorderWidth=3
	ADD OBJECT US2 AS LINE WITH BorderColor=pnRood, Width=0, Visible=.F., BorderWidth=3

	ADD OBJECT US0LB AS LABEL WITH BackColor=pnCyaan, Width=30, Height=10, Caption='', FontSize=6, FontBold=.T., Alignment=2, Visible=.F.
	ADD OBJECT US1LB AS LABEL WITH BackColor=pnRood, Width=30, Height=10, Caption='', FontSize=6, FontBold=.T., Alignment=2, Visible=.F.

	ADD OBJECT CR1 AS LINE WITH BorderColor=pnLichtRood, Width=0, Visible=.F. &&, BorderWidth=3
	ADD OBJECT CR2 AS LINE WITH BorderColor=pnCyaan, Width=0, Visible=.F. &&, BorderWidth=3
	ADD OBJECT PEAKTL1 AS LINE WITH BorderColor=pnLichtrood, Width=0, Visible=.F., BorderWidth=3
	ADD OBJECT PEAKTL2 AS LINE WITH BorderColor=pnCyaan, Width=0, Visible=.F., BorderWidth=3
	ADD OBJECT PEAKT AS LINE WITH BorderColor=pnLichtrood, Width=0, Visible=.F., BorderWidth=3
	ADD OBJECT PEAKL AS LINE WITH BorderColor=pnCyaan, Width=0, Visible=.F., BorderWidth=3
	ADD OBJECT S5HALT AS LT WITH BorderColor=pnGeel, Left=pnLeft2-10, Width=270, Visible=.F. &&, BorderWidth=3
	
	ADD OBJECT DIAGRAM AS IMAGE WITH Height=255, Width=250, Visible=.F., Stretch=1
	ADD OBJECT OVERLAY AS COMMANDBUTTON WITH Height=30, Width=250, Visible=.F., Caption="Overlay diagram on/off"
	ADD OBJECT TRIAL AS COMMANDBUTTON WITH Height=25, Width=105, Visible=.T., Caption="> Test mode", Visualeffect=1

	PROCEDURE Init(lCalled,cCMD,lReport,cLI,	lIA)
	DODEFAULT(lCalled,cCMD,lReport,cLI,	lIA)
	thisform.nW=_SCREEN.Width-8*2
	RETURN
	
	PROCEDURE Activate(nX,cAlias)
	IF thisform.lDecorrelator
		RETURN
	ENDIF
	
&& Initialising again at every call of the program is necessary !
pnSteps=250
&&pnCycles=1000
STORE 99999 TO pnAVMinS1,pnAVMinS4, pnAVMinS2,pnAVMinS5
pnSpeed=3
STORE 0 TO pnSS,pnSecs,pnTop,pnMaxLFITH,pnIC,pnTop1,pnTop2,pnTop3,pnTop4,pnTop5,pnTop6,pnTop7,pnTop8,pnL,pnMeanS1,pnMeanS2,pnF,pnWDB,pnBC,pnP,pnD,pnPv,pnDv,;
		   pnLeft3,pnLeft4,pnMaxFit,pnLift1,pnLift2,pnAVG1,pnAVG2,pnAVG4,pnAVG5,pnCycles,pnAVG,;
		   pnMEMS1,pnAVMaxS2,pnAVMaxS5,pnBShift,pnLift,pnMRS2,pnMRMAXS2,pnLiftS1,pnLiftS2
STORE 1 TO pnDivS1,pnDivS2,pnDivMax,pnR,pnValueSet,pnStart1,pnStart2,pnStart3,pnStart4

pnLeft1=30
pnLeft2=330
pnLeft3=(_SCREEN.Width-8*2)/2+30
pnLeft4=(_SCREEN.Width-8*2)/2+330

pnHI=95

pnHMem=30
STORE '' TO pcScAM,pcScA,pcWA,pcILF,pcGFDUR,pcYBlok,pcFields,pcObjects,pcSpecs,pcTxt,pcGFDIS
STORE .F. TO plBox,plBreak,plCon,plPause,plQuit

	
	thisform.lDecorrelator=.T.
	PUBLIC ARRAY LBS[9,8],SVAL[pnSteps]
	SET COMPATIBLE OFF
	STORE '' TO LBS
	STORE 0 TO SVAL
	SET COMPATIBLE ON
	thisform.nW=_SCREEN.Width-8*2
	pnW=thisform.Width
	pnW=1264 &&thisform.Width
&&	pnW=thisform.Width

	thisform.Left=pnW
	thisform.Left=thisform.nW
	pnH=thisform.Height && +300
	thisform.nH=thisform.Height
	pcFields="S1 i(4),S1JIT i(4),S1LIFT i(4),S2 i(4),S2JIT i(4),S2LIFT i(4),ISI i(4),USDUR i(4),USFORCE i(4),S4START i(4),AUTOLIFT i(4),ILFMAX i(4),"+;
			 "F3_13 i(4),F3_4 i(4),F3_5 i(4),F3_6 i(4),F3_7 i(4),IBCM i(4),CAP n(5,1),"+;
			 "P n(5,1),D n(5,1),P0 n(6,3),D0 n(5,2),CWA i(4),WA i(4),GFDUR i(4),GFDMODE i(4),GFTRIG i(4),GFTMODE i(4),"+;
			 "MODE i(4),VARIANT i(4),DEMO i(4),PEN i(4),CA i(4),B i(4),N i(4),MGCFUC i(4),DISPLAY c(16),"+;
			 "TIMES i(4),DLW i(4),STOP i(4),SLOW i(4)" && Last row is for parameters that do not appear on the dashboard
	pcObjects=",SP1_1,OP1_2,SP1_3,SP2_1,OP2_2,SP2_3,SP2_4,SP2_5,SP2_6,SP1_8,OP2_7,SP2_8,"+;
			  "SP3_1,SP3_4,SP3_5,SP3_6,SP3_7,SP3_8,SP3_9,"+;
			  "SP4_1,SP4_2,SP4_3,SP4_4,OP4_5,SP4_6,SP4_7,SP4_8,SP4_9,SP5_9,"+;
			  "SP5_1,SP5_2,SP5_3,OP5_4,SP5_5,SP5_6,SP5_7,SP5_8,TX6_9,"
	IF NOT FILE("MEM.DBF")
		CREATE TABLE MEM (&pcFields)
		APPEND BLANK
		APPEND BLANK
		USE IN MEM
	ENDIF
	pcFields=",S1,S1JIT,S1LIFT,S2,S2JIT,S2LIFT,ISI,USDUR,USFORCE,S4START,AUTOLIFT,ILFMAX,F3_13,F3_4,F3_5,F3_6,F3_7,IBCM,CAP,"+;
			 "P,D,P0,D0,CWA,WA,GFDUR,GFDMODE,GFTRIG,GFTMODE,MODE,VARIANT,DEMO,PEN,CA,B,N,MGCFUC,DISPLAY,"+;
			 "TIMES,DLW,STOP,SLOW," && Last row is for parameters that do not appear on the dashboard
	USE MEM IN SELECT(1)

	IF NOT FILE("SCENARIOS.DBF")  && DO NOT REMOVE !!!
		CREATE TABLE SCENARIOS (NAME c(10), BUTTON i(4), SCENARIO m(4))
		APPEND BLANK
		REPLACE SCENARIO WITH "Scenario 1"
		USE IN SCENARIOS
	ENDIF
	USE SCENARIOS IN SELECT(1) EXCLUSIVE
	SELECT SCENARIOS
	DELETE ALL FOR EMPTY(SCENARIO)
	PACK
	SORT TO TEMP ON NAME,BUTTON
	ZAP
	APPEND FROM TEMP
	
	CREATE TABLE SIMCOR1 (SUMTS n(8,2),AVGTS n(10,4),LFITH25 n(10,2),;
						 S1VAL n(7,2),S2VAL n(7,2),S3VAL n(7,2),S4VAL n(7,2),S5VAL n(7,2),S6VAL n(7,2))
	FOR nX=1 TO pnSteps
		APPEND BLANK
	ENDFOR
	USE IN SIMCOR1
	USE SIMCOR1 IN SELECT(1)

	CREATE TABLE SIMCOR2 (SUMTS n(8,2),AVGTS n(10,4),LFITH25 n(10,2),;
						 S1VAL n(7,2),S2VAL n(7,2),S3VAL n(7,2),S4VAL n(7,2),S5VAL n(7,2),S6VAL n(7,2))
	FOR nX=1 TO pnSteps
		APPEND BLANK
	ENDFOR
	USE IN SIMCOR2
	USE SIMCOR2 IN SELECT(1)

	CREATE TABLE SIMCOR3 (SUMTS n(8,2),AVGTS n(10,4),LFITH25 n(10,2),;
						 S1VAL n(7,2),S2VAL n(7,2),S3VAL n(7,2),S4VAL n(7,2),S5VAL n(7,2),S6VAL n(7,2))
	FOR nX=1 TO pnSteps
		APPEND BLANK
	ENDFOR
	USE IN SIMCOR3
	USE SIMCOR3 IN SELECT(1)

	CREATE TABLE SIMCOR4 (SUMTS n(8,2),AVGTS n(10,4),LFITH25 n(10,2),;
						 S1VAL n(7,2),S2VAL n(7,2),S3VAL n(7,2),S4VAL n(7,2),S5VAL n(7,2),S6VAL n(7,2))
	FOR nX=1 TO pnSteps
		APPEND BLANK
	ENDFOR
	USE IN SIMCOR4
	USE SIMCOR4 IN SELECT(1)

	IF NOT FILE("SCREENMEM.DBF")
		CREATE TABLE SCREENMEM (SPECS c(240),SIMCOR i(4),LFITH25 n(10,2),;
								S1VAL n(7,2),S2VAL n(7,2),S3VAL n(7,2),S4VAL n(7,2),S5VAL n(7,2),S6VAL n(7,2),BSHIFT n(7,2),LIFT n(7,2))
		USE IN SCREENMEM
	ENDIF

	IF NOT FILE("DEMOPROC.DBF")
		CREATE TABLE DEMOPROC (DEMO i(4),PROC m(4))
		USE IN DEMOPROC
	ENDIF
	
	CREATE TABLE MATRIX (SYNAPS c(pnSteps), SYNAVG n(10,4), DPC n(10,4), PPC n(10,4), DCS n(10,4), PCS n(10,4))
	USE IN MATRIX
	USE MATRIX IN SELECT(1)
	SELECT MATRIX
	FOR nX=1 TO pnSteps
		APPEND BLANK
	ENDFOR

	SELECT SIMCOR1
	thisform.ADDLINES

	oDashBoard=CREATEOBJECT('DASHBOARD')
	oDashBoard.PNTOP
	oDashBoard.Activate
	
	IF plCalled
		thisform.SPECSCALLED(.F.)
	ENDIF

	thisform.EB.Left=pnW/2
	thisform.EB.Width=pnW/2
	thisform.EB.Left=thisform.nW/2
	thisform.EB.Width=thisform.nW/2
	thisform.EB.ControlSource="SCENARIOS.SCENARIO"
	thisform.EB_AUTOSIZE(thisform.EB.Value,thisform.EB.Name)
	thisform.CBDB.Top=pnH-thisform.CBDB.Height
	thisform.CBDB.Left=pnW-thisform.CBDB.Width
	thisform.CBDB.Top=thisform.nH-thisform.CBDB.Height
	thisform.CBDB.Left=thisform.nW-thisform.CBDB.Width

	thisform.LBP.Top=pnH-thisform.LBP.Height-2
	thisform.LBP.Top=thisform.nH-thisform.LBP.Height-2
	thisform.OVERLAY.Left=pnLeft1
	thisform.OVERLAY.Top=thisform.LBP.Top-thisform.OVERLAY.Height
	thisform.TRIAL.Left=pnLeft2+250-thisform.TRIAL.Width
	thisform.FIT1.Top=thisform.Height-15

	pnTop=thisform.FIT1.Top
	oDashBoard.DASHBOARDCOHERENCE && includes LBSIGNALTEXT too
&&	   thisform.DIMS('form')
&&	   thisform.REDIMS(.T.)
	IF plCalled
		thisform.Left=pnW/2
		thisform.Left=thisform.nW/2
		IF pnW>oCerebreader.Width
			thisform.Left=oCerebReader.Width-1264/2
		ENDIF
		thisform.DEMO
		IF plReport
			thisform.Release
			RETURN
		ENDIF
		IF plCalled
			SET COMPATIBLE ON && Must be set ON !! or pnDoc becomes a variable 'not found' on return to the main program !!
			RETURN && !! NOT 'CANCEL' - otherwise windowtype error when restarted, and also remaining interactivity !!
		ENDIF
		RETURN && !! NOT 'CANCEL' - otherwise windowtype error when restarted, and also remaining interactivity !!
	ENDIF
	thisform.Left=0
	oDashBoard.MGCFUC
	RETURN
	
	PROCEDURE ADDLINES(nX,cX)
	&& Line objects
	FOR nX=1 TO pnSteps
		cX=LTRIM(STR(nX))
		thisform.AddObject("L1"+cX,"L1",nX+pnLeft1)
		thisform.AddObject("L2"+cX,"L2",nX+pnLeft1)
		thisform.AddObject("L3"+cX,"L3",nX+pnLeft1)
		thisform.AddObject("L4"+cX,"L4",nX+pnLeft2)
		thisform.AddObject("L5"+cX,"L5",nX+pnLeft2)
		thisform.AddObject("L6"+cX,"L6",nX+pnLeft1)
		thisform.AddObject("L7"+cX,"L7",nX+pnLeft2)
		thisform.AddObject("L8"+cX,"L8",nX+pnLeft1)

		thisform.AddObject("LR41"+cX,"LR41",nX+pnLeft1)
		thisform.AddObject("LR52"+cX,"LR52",nX+pnLeft1)
		thisform.AddObject("LR63"+cX,"LR63",nX+pnLeft1)
		thisform.AddObject("LR14"+cX,"LR14",nX+pnLeft2)
		thisform.AddObject("LR25"+cX,"LR25",nX+pnLeft2)
		thisform.AddObject("LR36"+cX,"LR36",nX+pnLeft2)

		thisform.AddObject("LFIT25"+cX,"LFIT",nX+pnLeft2)
	ENDFOR
	FOR nX=1 TO 8
		cX=LTRIM(STR(nX))
		DO CASE
		CASE nX=3
			thisform.AddObject("LTC"+cX,"LT")
			thisform.AddObject("LTCL"+cX,"LTL")
			thisform.AddObject("LTB"+cX,"LT")
			thisform.AddObject("LTBL"+cX,"LTL")
			thisform.AddObject("LTN"+cX,"LT")
			thisform.AddObject("LTNL"+cX,"LTL")
		CASE nX=5
			thisform.AddObject("LTC"+cX,"LT")
			thisform.AddObject("LTCL"+cX,"LTL")
		ENDCASE
		thisform.AddObject("LTA"+cX,"LTA")
	ENDFOR
	RETURN
	
	PROCEDURE Destroy
	USE IN SCENARIOS
	USE IN SIMCOR1
	USE IN SIMCOR2
	USE IN SIMCOR3
	USE IN SIMCOR4
	USE IN MEM
	USE IN MATRIX	
	pnW=oCerebreader.Width
	RETURN
	
	PROCEDURE DblClick
	IF VERSION(2)=0 OR plTESTVERSION0
		RETURN
	ENDIF
	IF thisform.WindowState=0
		thisform.SPECSCALLED(.T.)
	ELSE
		thisform.SPECSCALLED(.F.)
	ENDIF
	RETURN
	
	PROCEDURE OVERLAY.Click
	IF thisform.DIAGRAM.Visible
		thisform.DIAGRAM.Visible=.F.
		oDecorrelator.LBS4.ZOrder(0)
		oDecorrelator.LTA4.ZOrder(0)
	ELSE
		thisform.DIAGRAM.Visible=.T.
		oDecorrelator.LBS4.ZOrder(1)
		oDecorrelator.LTA4.ZOrder(1)
	ENDIF
	RETURN
	
	PROCEDURE LBP.Click
	plPause=NOT plPause
	thisform.LBP.Value=STRTRAN(thisform.LBP.Value,IIF(plPause,"interrupt","resume"),IIF(plPause,"resume","interrupt"))
	RETURN
	
	PROCEDURE LBP.RightClick(lNoBreak)
	IF plBreak
		thisform.Visible=.F.
		thisform.Release
	ELSE
		plBreak=NOT lNoBreak
		plPause=.F.
	ENDIF
	RETURN
	
	PROCEDURE CBDB.Click
	oDashBoard.AlwaysOnTop=.T. && GitHub version: above the DECORRELATOR form (which is AlwaysOnTop),
	oDashBoard.Show() && GitHub version: and not modal (in CEREBREADER.PRG: Show(1))
	RETURN
	
	PROCEDURE SPECSCALLED(lV)
	thisform.Left=pnW/2
	thisform.Left=thisform.nW/2
	IF pnW>oCerebreader.Width
		thisform.Left=oCerebReader.Width-1264/2
	ENDIF
	thisform.Width=pnW/2
	thisform.WindowState=IIF(lV,2,0)
	thisform.EB.Visible=lV
	RETURN
	
	PROCEDURE STEP(nX,nAVGTS,nGFDUR,nAS,nStart,nY,nTimes,nISI,nRec,nSynSum,nSynCount,nMemS4VAL)
	nTimes=ICASE(MEM.MODE=3,1,MEM.MODE=4,2,MEM.MODE=5,4,1) &&MEM.MODE=6,4,MEM.MODE=5,4,MEM.MODE=5,4,1)
	SELECT SIMCOR1
&&	IF (pnIC=0 AND pnL=0) OR (pnL=0 AND MEM.S1JIT=1) OR (pnL=0 AND pnMEMS1#MEM.S1) OR (pnL=0 AND MEM.AUTOLIFT=1)
	IF pnL=0 AND (pnIC=0 OR MEM.S1JIT=1 OR MEM.AUTOLIFT=1) &&  OR pnMEMS1#MEM.S1 OR VAL(pcCMD)=74)
	&& Make a ('standard') S1 signal once, or at the start of every cycle when random jitter is to be added
		thisform.MAKE_S1("SIMCOR1")
		IF INLIST(MEM.MODE,4,5,6) &&,7,8)
			thisform.MAKE_S1("SIMCOR2")
		ENDIF
		IF MEM.MODE=5
			thisform.MAKE_S1("SIMCOR3")
			thisform.MAKE_S1("SIMCOR4")
		ENDIF
IF .T.
		pcGFD_CWA=''
		pcGFT_CWA=REPLICATE('0',pnSteps) && erase pcGFT_CWA ?
		&& Fixing all RAND values at the first cycle
&&		IF MEM.CWA=1 && not needed when it is specified below which modes use prolonged firing
			IF INLIST(MEM.MODE,3,4,5,6,7)
				cGFTMODE0=REPLICATE("0",250)
				SELECT MATRIX
				REPLACE ALL SYNAPS WITH REPLICATE('0',pnSteps) &&, SYNAVG WITH 0
				SCAN && for 250 synapses we determine how long they are activated and at how many moments they are
					FOR nX=1 TO ICASE(MEM.GFTMODE=1,MEM.GFTRIG,MEM.GFTMODE=2,RAND()*MEM.GFTRIG+1,MEM.GFTMODE=3,RAND()^2*MEM.GFTRIG+1,1)
					&& at so many moments
						nGFDUR=ICASE(MEM.GFDMODE=1,MEM.GFDUR,MEM.GFDMODE=2,RAND()*MEM.GFDUR+1,MEM.GFDMODE=3,RAND()*MEM.ISI+1,MEM.GFDMODE=4,RAND()*250+1,+;
									 MEM.GFDMODE=5,RAND()^2*MEM.GFDUR+1,MEM.GFDMODE=6,RAND()^2*MEM.ISI+1,MEM.GFDMODE=7,RAND()^2*250+1,MEM.GFDUR)
						&& Determines the duration
						IF MEM.GFTMODE=0 && (default) GrC firing covers all timeslices
								REPLACE SYNAPS WITH STUFF(SYNAPS,RECNO(),nGFDUR,REPLICATE("1",nGFDUR)) && GrC fires nGFDUR times at nMoment
								LOOP
							nY=0
							nMoment=INT(RAND()*(pnSteps-1))+1 && Determines which moment
							nMemMoment=nMoment
							DO WHILE SUBSTR(cGFTMODE0,nMoment,1)="1" AND nY<=250 && Look for a free place as long as there are
								nY=nY+1
								nMoment=IIF(nMoment=250,1,nMoment+1)
							ENDDO
							IF nY<=250
								REPLACE SYNAPS WITH STUFF(SYNAPS,nMoment,nGFDUR,REPLICATE("1",nGFDUR)) && GrC fires nGFDUR times at nMoment
								cGFTMODE0=STUFF(cGFTMODE0,nMoment,1,"1")
							ELSE
								REPLACE SYNAPS WITH STUFF(SYNAPS,nMemMoment,nGFDUR,REPLICATE("1",nGFDUR)) && GrC fires nGFDUR times at nMoment
							ENDIF
						ELSE
							FOR nY=1 TO 10
								nMoment=INT(RAND()*(pnSteps-1))+1 && Determines which moment
								IF NOT '1'$SUBSTR(SYNAPS,nMoment,nGFDUR) && if there is still room at that moment for that duration, otherwise choose another moment
									REPLACE SYNAPS WITH STUFF(SYNAPS,nMoment,nGFDUR,REPLICATE("1",nGFDUR)) && GrC fires nGFDUR times at nMoment
									EXIT
								ENDIF
							ENDFOR
						ENDIF
					ENDFOR
				ENDSCAN
			ENDIF
			SELECT SIMCOR1
&&		ENDIF
ENDIF
	ENDIF
&&	IF pnIC=0 OR (pnL=0 AND MEM.MODE<3) && Make a new random S2 signal at the start of every cycle, but not for EBR: then once
	IF pnL=0 AND (pnIC=0 OR (INLIST(MEM.MODE,1,2,6) AND NOT MEM.S2=6))
	&& Make a new random S2 signal at the start of every cycle, but not for EBR: then once, as also in case of 'unchanging S2' MEM.S2=6
		thisform.MAKE_S2("SIMCOR1")
		IF INLIST(MEM.MODE,4)
			GO TOP
			LOCATE FOR S2VAL>1
			pnStart1=RECNO()
			thisform.MAKE_S2("SIMCOR2")
			SELECT SIMCOR2
			GO TOP
			LOCATE FOR S2VAL>1
			pnStart2=RECNO()
			SELECT SIMCOR1
		ENDIF
		IF MEM.MODE=5
			thisform.MAKE_S2("SIMCOR2")
			thisform.MAKE_S2("SIMCOR3")
			STORE 1 TO pnStart1,pnStart2,pnStart3
			pnStart4=MEM.ISI/2
			thisform.MAKE_S2("SIMCOR4")
		ENDIF
		SELECT SIMCOR1
		REPLACE ALL S3VAL WITH S1VAL+S2VAL
	ENDIF
	SELECT SIMCOR1
	pnL=pnL+1
	GO pnL
	DO CASE
	CASE MEM.ILFMAX=1 && No variable input load
		pnILF=1
	CASE MEM.ILFMAX>1
		pnILF=ASC(SUBSTR(pcILF,pnL,1))/10
&&		pnILF=ASC(SUBSTR(pcILF,RAND()*pnSteps,1))/10
&&		pnILF=MEM.ILFMAX
	CASE MEM.ILFMAX=0 && Special arrangement
		IF pnL<125
			pnILF=2
		ELSE
			pnILF=1
		ENDIF
	ENDCASE

&&	REPLACE S3VAL WITH S1VAL+S2VAL
	IF INLIST(MEM.MODE,4,5)
		SELECT SIMCOR2
		GO pnL
		REPLACE S3VAL WITH S1VAL+S2VAL
		SELECT SIMCOR1
	ENDIF
	IF MEM.MODE=5
		SELECT SIMCOR3
		GO pnL
		REPLACE S3VAL WITH S1VAL+S2VAL
		SELECT SIMCOR4
		GO pnL
		REPLACE S3VAL WITH S1VAL+S2VAL
		SELECT SIMCOR1
	ENDIF
	&& At every timeslice we will look for the average of the signal at that moment
	&& We start with summing the signal values at every passage
	&& The cycle count is incremented after the cycle and will be the divisor to calculate the average further on
	IF pnIC=0
		GO pnL
		REPLACE AVGTS WITH IIF(MEM.S4START=-1,S3VAL,MEM.S4START)
		IF INLIST(MEM.MODE,4,5)
			SELECT SIMCOR2
			GO pnL
			REPLACE AVGTS WITH IIF(MEM.S4START=-1,S3VAL,MEM.S4START)
			SELECT SIMCOR1
			GO pnL
		ENDIF
		IF MEM.MODE=5
			SELECT SIMCOR3
			GO pnL
			REPLACE AVGTS WITH IIF(MEM.S4START=-1,S3VAL,MEM.S4START)
			SELECT SIMCOR4
			GO pnL
			REPLACE AVGTS WITH IIF(MEM.S4START=-1,S3VAL,MEM.S4START)
			SELECT SIMCOR1
			GO pnL
		ENDIF
	ELSE
		DO CASE
		CASE MEM.MODE=1 && Basic formulae, P and D in parallel
			DO CASE
			CASE MEM.F3_13=1 && SUM and AVG
				REPLACE SUMTS WITH SUMTS+S3VAL, AVGTS WITH SUMTS/(pnIC)
				&& was pnIC+1 ! until 13/11/2018
			CASE MEM.F3_13=2 && AVG derived
				&& 1) (X) = X/1
				&& 2) (X+Y)/2 = (X/1+Y/1)*(1/2)
				&& 3) (X+Y+Z)/3 = [(X/1+Y/1)*(1/2)+Z/2]*(2/3)
				&& 4) (X+Y+Z+Q)/4 = {[(X/1+Y/1)*(1/2)+Z/2]*(2/3)+Q/3}*(3/4)
				&& ...              = (AVG+S3/pnIC)*(pnIC/(pnIC+1))
	
				&& REPLACE AVGTS WITH					    (AVGTS+S3VAL*(1/pnIC)   ) * ((pnIC)/(pnIC+1)) && is OK
				&& Can be converted further as follows :	(AVGTS + S3VAL * (1/pnIC)   ) / ((pnIC+1)/pnIC)
				&&										=	(AVGTS * pnIC + S3VAL) / (pnIC+1)
				&&										=	(AVGTS * pnIC + AVGTS + S3VAL - AVGTS) / (pnIC+1)
				&&										=	(AVGTS * (pnIC+1) + S3VAL - AVGTS) / (pnIC+1)
				&&										=	 AVGTS + (S3VAL - AVGTS) / (pnIC+1)
				&&										=	 AVGTS + (S3VAL - AVGTS) * (1/(pnIC+1))
				&&										=	 AVGTS - AVGTS * (1/(pnIC+1)) + S3VAL * (1/(pnIC+1))
				REPLACE AVGTS WITH AVGTS - AVGTS*(1/(pnIC+1)) + S3VAL*(1/(pnIC+1))

				IF pnL=pnSteps && NOCOV
					pnPv=100*(1/pnIC)
					pnDv=100-100*(pnIC/(pnIC+1))
				ENDIF
			CASE MEM.F3_13=3 && CASE Fixed P and D
			&& In 'Basic' P and D are assumed to be regulated separately (no subtraction beforehand)
			&& where P is a function of the postsynaptic signal and D a function of the synapse strength (and possibly of the presynaptic signal)
				REPLACE AVGTS WITH AVGTS - AVGTS*pnILF*pnD + S3VAL*pnP
				&& Here P and D are still assumed to be regulated separately (no subtraction beforehand)
				IF MEM.WA>0
					thisform.SCATTERADDRESS(pnP,pnD,S3VAL)
				ENDIF
			ENDCASE

		CASE MEM.MODE=2 && ELL : here we provide no 'longer duration GrC firing' 
			&& In the ELL only the B-spike can bring in the DS signal (and then only in 'subtraction')
			&& hence P and D in association with B depend on a Ca-threshold
			&& and na-P / (naD ?) must then be a function of the synapse strength (and presynaptic signal) and not of the postsynaptic signal
			
			nAVGTS=0
			nAS=AVGTS*pnILF+S3VAL && The 'algebraic summing'
			IF MEM.F3_4<5
				nAVGTS=nAVGTS+thisform.NONASSOCP(MEM.F3_4)
			ELSE && NEGASSOC
				IF nAS<MEM.B
					&& the plasticity itself does not depend on nAS, but it only happens when nAS<MEMB (when the B-spike does not occur)
					nAVGTS=nAVGTS+thisform.NONASSOCP(MEM.F3_4-4)
				ENDIF
			ENDIF

			IF MEM.F3_5<5
				nAVGTS=nAVGTS+thisform.NONASSOCD(MEM.F3_5)
			ELSE && NEGASSOC
				IF nAS<MEM.B
					&& the plasticity itself does not depend on nAS, but it only happens when nAS<MEMB (when the B-spike does not occur)
					nAVGTS=nAVGTS+thisform.NONASSOCD(MEM.F3_5-4)
				ENDIF
			ENDIF

			IF MEM.F3_6=1 && BSa-P%
				IF nAS=>MEM.B+pnBShift
					IF nAS<MEM.CA+pnBShift && a Ca-threshold that is to be adjusted for B-threshold adaptation 
						nAVGTS=nAVGTS + (MEM.CA+pnBShift - nAS)*pnP
					ENDIF
				ENDIF
			ENDIF

			IF MEM.F3_7=1 && BSa-D%
				IF nAS=>MEM.B+pnBShift
					IF nAS=>MEM.CA+pnBShift
						nAVGTS=nAVGTS + (MEM.CA+pnBShift - nAS)*pnD
					ENDIF
				ENDIF
			ENDIF

			IF MEM.WA>0
				thisform.SCATTERADDRESS_ELL(pnP,pnD,S3VAL)
			ELSE
				REPLACE AVGTS WITH MAX(0,AVGTS + nAVGTS)
			ENDIF

		CASE MEM.MODE=6 && PuC : here we DO provide 'longer duration GrC firing' for the simulation of EBR
			&& In the PuC 'standard' CF firing is assumed to be ALWAYS present
			&& In the cerebellum the DS is brought in by AFs and the subtraction happens in loco
			&& hence P and D, in association with C or not, also depend on a Ca-threshold here.
			&& and na-P / (na-D ?) are also a function of the synapse strength (and presynaptic signal) and not only of the postsynaptic signal
			
			&& In MATRIX the number of times a GrC fires is already fixed at the first cycle for every GrC / synapse, see above
			&& Done at each step (each timeslice)
&&			plEBR=.T.
			nS3VAL=S3VAL && value of timeslice pnL
			SELECT MATRIX
			SCAN FOR SUBSTR(SYNAPS,pnL,1)="1"
				SELECT SIMCOR1
				GO RECNO("MATRIX")
				nAS=AVGTS*pnILF+nS3VAL && The 'algebraic summing' based on S3VAL of timeslice pnL
				nAVGTS=0
				IF BETWEEN(pnL,MEM.ISI,MEM.ISI+MEM.USDUR)
					nAS=nAS+MEM.USFORCE
				ENDIF

				IF MEM.IBCM=1 && iBCM rule : normally used
					nAVGTS=nAVGTS + (MEM.CA - nAS)*IIF(nAS<MEM.CA,pnP,pnD)
				ELSE
					IF MEM.F3_6=1 && Used ?? CFa-P% : P only when there is a CF spike, assumes D and P in parallel, not with a Ca-threshold
						IF nAS<MEM.CA
							nAVGTS=nAVGTS + (MEM.CA - nAS)*pnP
						ENDIF
					ENDIF
	
					IF MEM.F3_7=1 && Used ?? CFa-D% : D only when there is a CF spike, assumes D and P in parallel, not with a Ca-threshold
						IF nAS=>MEM.CA
							nAVGTS=nAVGTS + (MEM.CA - nAS)*pnD
						ENDIF
					ENDIF
				ENDIF

				REPLACE AVGTS WITH MAX(0,AVGTS+nAVGTS)
				SELECT MATRIX
			ENDSCAN
			SELECT SIMCOR1
			GO pnL

			IF pnL=250
			&& It is important to realize that the relation between AVGTS and S4VAL is no more simply S4VAL=AVGTS*pnILF
			&& S4VAL must now be calculated out of the AVGTSs of all the co-activated synapses (as laid out in MATRIX)
			&& Simply adding the contributions is too sensitive to differences in numbers of co-activated synapses between timeslices
			&& We will presume that GoCs by FBI reduce these differences
			&& Consequently we will calculate an average of the contributing synapses and not a sum
			&& We must take care of storing the AVGTSs (the SS's) into AVGTS while storing the computed averages of the AVGTSs into S4VAL
			&& The program line REPLACE S4VAL WITH AVGTS (or AVGTS*pnILF) later on is NO MORE to be used here, since the storage is done here
				
			&& Best is to set S4VAL=S3VAL IN THE BEGINNING ONLY, but setting S3VAL itself as wished by S1, S2 and LIFT
			&& since S4VAL becomes SUM(ApO) which can be different from S3VAL when ILF or prolonged firing come into play
				FOR nX=1 TO pnSteps && for each timeslice
					nSynCount=0 && will count the number of contributing synapses
					nSynSum=0 && will contain the sum of the actual synaps (average) values 
					SELECT MATRIX
					SCAN FOR SUBSTR(SYNAPS,nX,1)="1" && scan for contributing synapses (co-firing at timeslice nX)
						SELECT SIMCOR1
						GO RECNO("MATRIX") && go to the record of this particular synaps contributing for timeslice nX
						nSynSum=nSynSum+MIN(IIF(MEM.F3_4=8,MEM.CAP,300),AVGTS) && add to the sum of SS's
						nSynCount=nSynCount+1 && increment the counter of contributing synapses
						SELECT MATRIX
					ENDSCAN
					SELECT SIMCOR1
					GO nX
					nMemS4VAL=S4VAL
&&					REPLACE S4VAL WITH IIF(nSynSum=0,S4VAL,nSynSum/MAX(1,nSynCount)) && do NOT fill in the original S4VAL afterwards !
					REPLACE S4VAL WITH nSynSum/MAX(1,nSynCount)



					IF ROUND(nMemS4VAL,1)#ROUND(S4VAL,1)
						plFlag=.T.
					ENDIF
					SELECT MATRIX
				ENDFOR && nX (timeslices)
				SELECT SIMCOR1
			ENDIF
			GO pnL

		CASE MEM.MODE=6 && DON'T TOUCH !
			&& PuC : here we DO provide 'longer duration GrC firing' for the simulation of EBR
			&& In the PuC 'standard' CF firing is assumed to be ALWAYS present
			&& In the cerebellum the DS is brought in by AFs and the subtraction happens in loco
			&& hence P and D, in association with C or not, also depend on a Ca-threshold here.
			&& and na-P / (naD ?) are also a function of the synapse strength (and presynaptic signal) and not of the postsynaptic signal

			IF MEM.CWA=1 && RAND() values taken at the first loop and then reused at all subsequent loops
				nGFDUR=ASC(SUBSTR(pcGFD_CWA,pnL,1))
			ELSE && RAND() values retaken at every loop
				nGFDUR=ICASE(MEM.GFDMODE=1,MEM.GFDUR,MEM.GFDMODE=2,RAND()*MEM.GFDUR+1,MEM.GFDMODE=3,RAND()*MEM.ISI+1,MEM.GFDMODE=4,RAND()*250+1,+;
							 MEM.GFDMODE=5,RAND()^2*MEM.GFDUR+1,MEM.GFDMODE=6,RAND()^2*MEM.ISI+1,MEM.GFDMODE=7,RAND()^2*250+1)
			ENDIF
&&			nS3VAL=S3VAL
			&& Every pnL is linked to one specific GrC that has its own GFDUR when CWA=1, otherwise a fixed or random GFDUR according to GFDMODE
			FOR nX=pnL TO MIN(pnSteps,pnL-1+nGFDUR) && The same SS is adjusted nGFDUR times (in one run here) as counted over the entire cycle.
			&& the distribution is not relevant : in a row or 'stuttering' : only the count matters. 
			&& The small difference between setting nGFDUR=x when ILF=1 and setting nGFDUR=1 when ILF=x (both in random mode)
			&& is due to 'accumulating interest' when using nGFDUR (going x times through the loop) while when using ILF it is calculated at once.
				nAVGTS=0
				nAS=AVGTS*pnILF+S3VAL && The 'algebraic summing' based on timeslice pnL
				IF MEM.F3_4<5
					nAVGTS=nAVGTS+thisform.NONASSOCP(MEM.F3_4)
				ELSE && NEGASSOC
					IF NOT BETWEEN(pnL,MEM.ISI,MEM.ISI-1+MEM.GFDUR)
						&& 
						nAVGTS=nAVGTS+thisform.NONASSOCP(MEM.F3_4-4)
					ENDIF
				ENDIF

				IF MEM.F3_5<5
					nAVGTS=nAVGTS+thisform.NONASSOCD(MEM.F3_5)
				ELSE && NEGASSOC
					IF NOT BETWEEN(pnL,MEM.ISI,MEM.ISI-1+MEM.GFDUR)
						&& 
						nAVGTS=nAVGTS+thisform.NONASSOCD(MEM.F3_5-4)
					ENDIF
				ENDIF

				IF MEM.F3_6=1 && CFa-P% : P only when there is a CF spike, and when below Ca-threshold separating P from D
					IF nAS<MEM.CA
						nAVGTS=nAVGTS + (MEM.CA - nAS)*pnP
					ENDIF
				ENDIF

				IF MEM.F3_7=1 && CFa-D% :  D only when there is a CF spike, and when above Ca-threshold separating P from D
					IF nAS=>MEM.CA
						nAVGTS=nAVGTS + (MEM.CA - nAS)*pnD
					ENDIF
				ENDIF

&&				IF MEM.WA>0
&&					thisform.SCATTERADDRESS_ELL(pnP,pnD,S3VAL)
&&				ELSE
					REPLACE AVGTS WITH MAX(0,AVGTS + nAVGTS)
&&				ENDIF
			ENDFOR
			SELECT SIMCOR1
			
&&			IF MEM.GFDUR>0
&&				thisform.GFDUR_EBR(S3VAL)
&&			ELSE
&&				REPLACE AVGTS WITH AVGTS - AVGTS*nILF*pnD + S3VAL*pnP
&&			ENDIF
	
&&			ENDCASE
			IF MEM.WA>0 
				thisform.SCATTERADDRESS_ELL(pnP,pnD,S3VAL)
			ELSE
&&				REPLACE AVGTS WITH MAX(0,AVGTS + nAVGTS)
				&& not AVGTS + MAX(0,AVGTS + nAVGTS) !!
			ENDIF
			
IF .F.
			IF MEM.GFDUR=1
				IF nAS=>MEM.B
					thisform.TIMESLICEOVL(nAS)
				ELSE
					nAVGTS=nAVGTS + AVGTS*nILF*MEM.P0/100
&&					REPLACE AVGTS WITH AVGTS + nAVGTS
				ENDIF
			ELSE
				REPLACE AVGTS WITH MAX(0,AVGTS + nAVGTS)
&&				REPLACE AVGTS WITH AVGTS + nAVGTS
			ENDIF
ENDIF

		CASE INLIST(MEM.MODE,3,4,5) && EBR
			plEBR=.T.
		&& Here there is no 'standard CF firing', but an explicit US-triggered CF firing period
		&& In MATRIX the number of times a GrC fires is already fixed at the first cycle for every GrC / synapse, see above
			FOR nY=1 TO nTimes && Why ? cf. Kehoe : up to 4 histograms of the same function
				IF pnIC=1 AND pnL=1 && needs to be done only once because the intermediate results don't depend on S3VAL (the DS)
					SELECT SIMCOR1
&&					REPLACE ALL S4VAL WITH S3VAL
					SELECT MATRIX
					REPLACE ALL DPC WITH 1,PPC WITH 1,DCS WITH 0,PCS WITH 0
					SCAN
						IF MEM.F3_4=7 OR MEM.F3_4=8 && neg-CFa-P constant - eventual capping is done at the end of the cycle see below
							FOR nX=1 TO pnSteps
								IF SUBSTR(SYNAPS,nX,1)="1" AND NOT BETWEEN(nX,MEM.ISI,MEM.ISI+MEM.USDUR-1)
									REPLACE PCS WITH PCS+MEM.P0
								ENDIF
							ENDFOR
						ENDIF

						IF MEM.F3_5=2 && na-D %
							FOR nX=1 TO pnSteps
								IF SUBSTR(SYNAPS,nX,1)="1" && AND NOT BETWEEN(nX,MEM.ISI,MEM.ISI+MEM.USDUR-1)
									REPLACE DPC WITH DPC/(1+MEM.D0*pnILF) && nAVGTS=nAVGTS - MAX(1,AVGTS)*MEM.D0*pnILF/100
								ENDIF
							ENDFOR
						ENDIF

						IF MEM.F3_6=1 && CFa-P%
							FOR nX=1 TO pnSteps
								IF SUBSTR(SYNAPS,nX,1)="1" AND BETWEEN(nX,MEM.ISI,MEM.ISI+MEM.USDUR-1)
									REPLACE PPC WITH PPC*(1+pnP)
								ENDIF
							ENDFOR
						ENDIF

						IF MEM.F3_7=1 && CFa-D%
							FOR nX=1 TO pnSteps
								IF SUBSTR(SYNAPS,nX,1)="1" AND BETWEEN(nX,MEM.ISI,MEM.ISI+MEM.USDUR-1)
									REPLACE DPC WITH DPC/(1+pnD)
								ENDIF
							ENDFOR
						ENDIF
					ENDSCAN
				ENDIF

				IF pnL=250
				&& It is important to realize that the relation between AVGTS and S4VAL is no more simply S4VAL=AVGTS*pnILF
				&& S4VAL must now be calculated out of the AVGTSs of all the co-activated synapses (as laid out in MATRIX)
				&& Simply adding the contributions is too sensitive to differences in numbers of co-activated synapses between timeslices
				&& We will presume that GoCs by FBI reduce these differences
				&& Consequently we will calculate an average of the contributing synapses and not a sum
				&& We must take care of storing the AVGTSs (the SS's) into AVGTS while storing the computed averages of the AVGTSs into S4VAL
				&& The program line REPLACE S4VAL WITH AVGTS (or AVGTS*pnILF) later on is NO MORE to be used here, since the storage is done here
					FOR nX=1 TO pnSteps && for each timeslice
						nSynCount=0 && will count the number of contributing synapses
						nSynSum=0 && will contain the sum of the actual synaps (average) values
						SELECT MATRIX
						SCAN FOR SUBSTR(SYNAPS,nX,1)="1" && scan for contributing synapses (co-firing at timeslice nX)
							SELECT SIMCOR1
							GO RECNO("MATRIX") && go to the record of this particular synaps contributing for timeslice nX
							nAVGTS=AVGTS && remember it's actual SS
							SELECT MATRIX
							IF MEM.CAP=>0
								nAVGTS=MIN(IIF(MEM.F3_4=8,MEM.CAP,5000),nAVGTS*DPC*PPC+DCS+PCS) && calculate the new value of the SS, cap if necessary
							ELSE && negative value means that ABS(MEM.CAP) is the PuC-cap and then we use ABS(MEM.CAP)*2 for the synaps-cap
								nAVGTS=MIN(IIF(MEM.F3_4=8,ABS(MEM.CAP)*2,5000),nAVGTS*DPC*PPC+DCS+PCS) && calculate the new value of the SS, cap if necessary
							ENDIF
							SELECT SIMCOR1
							REPLACE AVGTS WITH MAX(0,nAVGTS) && store the new SS value
							nSynSum=nSynSum+AVGTS && add to the sum of SS's
							nSynCount=nSynCount+1 && increment the counter of contributing synapses
							SELECT MATRIX
						ENDSCAN
						SELECT SIMCOR1
						GO nX
						nMemS4VAL=S4VAL
						&& store the AVERAGE (not the SUM) of the SS's in S4VAL (the sum nSynSum divided by the counter nSynCount)
						IF MEM.CAP=>0
							REPLACE S4VAL WITH IIF(nSynSum=0,S4VAL,nSynSum/MAX(1,nSynCount))
						ELSE
							REPLACE S4VAL WITH IIF(nSynSum=0,S4VAL,MIN(-MEM.CAP,nSynSum/MAX(1,nSynCount)))
						ENDIF
						
						IF ROUND(nMemS4VAL,1)#ROUND(S4VAL,1)
							plFlag=.T.
						ENDIF
					ENDFOR && nX (timeslices)
					SELECT SIMCOR1
				ENDIF		
			ENDFOR && nTimes
			
&&			IF MEM.GFDUR>0
&&				thisform.GFDUR_EBR(S3VAL)
&&			ELSE
&&				REPLACE AVGTS WITH AVGTS - AVGTS*nILF*pnD + S3VAL*pnP
&&			ENDIF
		CASE INLIST(MEM.MODE,3,4,5) && EBR DONT TOUCH !!!!
		&& In EBR the DS (in the PuC) is also present postsynaptically without the CF, hence na-P and na-D are a function of the postsynaptic signal
			nRec=RECNO()
			IF MEM.CWA=1
&&				nGFDUR=ASC(SUBSTR(pcGFD_CWA,pnL,1))
				nGFDUR=ASC(SUBSTR(pcGFDUR,pnL,1))
			ELSE
				nGFDUR=ICASE(MEM.GFDMODE=1,MEM.GFDUR,MEM.GFDMODE=2,RAND()*MEM.GFDUR+1,MEM.GFDMODE=3,RAND()*MEM.ISI+1,MEM.GFDMODE=4,RAND()*250+1,+;
							 MEM.GFDMODE=5,RAND()^2*MEM.GFDUR+1,MEM.GFDMODE=6,RAND()^2*MEM.ISI+1,MEM.GFDMODE=7,RAND()^2*250+1)
			ENDIF
			FOR nY=1 TO nTimes
				cY=LTRIM(STR(nY))
				nStart=pnStart&cY && 1 when nY=1
				nISI=MEM.ISI
				IF nY=3
					nISI=MEM.ISI/2
				ENDIF
				SELECT SIMCOR&cY
				GO pnL
				IF MEM.GFDMODE=3
					nGFDUR=RAND()*(nISI-nStart+1)+1
				ENDIF
				IF MEM.GFDMODE=6
					nGFDUR=RAND()^2*(nISI-nStart+1)+1
				ENDIF
				IF MEM.GFDMODE=4
					nGFDUR=RAND()*(pnL-nStart+1)+1
				ENDIF
				IF MEM.GFDMODE=7
					nGFDUR=RAND()^2*(pnL-nStart+1)+1
				ENDIF
				nS3VAL=S3VAL
				lInUS=BETWEEN(nRec,nISI,nISI+MEM.USDUR-1)
				FOR nX=nStart TO pnL STEP MEM.DLW && STEP RAND()*3+1 && 1 TO pnL when nY=1 && runs from the start to the current value of the timeslice counter 
				&& no difference with pnSteps !
					nAVGTS=0
					GO nX
					IF BETWEEN(pnL,nX,nX-1+nGFDUR) && AND pnL<=MEM.ISI+MEM.USDUR && When the current timeslice counter falls in the period in which the GrC fires
						IF MEM.F3_4+MEM.F3_5>0
							nAVGTS=thisform.NONASSOC(MEM.F3_4,MEM.F3_5,nAVGTS,pnILF)
							IF NOT lInUS
								nAVGTS=thisform.NEGASSOC(MEM.F3_4,MEM.F3_5,nAVGTS,pnILF)
							ENDIF
						ENDIF

						IF MEM.F3_6=1 && CFa-P% :  P only when there is a CF spike, assumes D and P in parallel, not with a Ca-threshold
							IF lInUS &&BETWEEN(nRec,nISI,nISI+MEM.USDUR) && additional condition : the timeslice counter falls IN the US period
								nAVGTS=nAVGTS + nS3VAL*pnP*pnILF
							ENDIF
						ENDIF

						IF MEM.F3_7=1 && CFa-D%  D only when there is a CF spike, assumes D and P in parallel, not with a Ca-threshold
							IF lInUS &&BETWEEN(nRec,nISI,nISI+MEM.USDUR)
								nAVGTS=nAVGTS - AVGTS*pnD*pnILF
							ENDIF
						ENDIF

						IF MEM.WA>0
							thisform.SCATTERADDRESS_ELL(pnP,pnD,S3VAL)
						ELSE
							REPLACE AVGTS WITH MAX(0,AVGTS + nAVGTS)
						ENDIF
						GO nRec
					ENDIF
				ENDFOR
			ENDFOR
			SELECT SIMCOR1
			
&&			IF MEM.GFDUR>0
&&				thisform.GFDUR_EBR(S3VAL)
&&			ELSE
&&				REPLACE AVGTS WITH AVGTS - AVGTS*nILF*pnD + S3VAL*pnP
&&			ENDIF

		ENDCASE
		SET COVERAGE TO
	ENDIF

	FOR nY=1 TO nTimes
		cY=LTRIM(STR(nY))
		nStart=pnStart&cY
		SELECT SIMCOR&cY
		GO pnL
		IF INLIST(MEM.MODE,1,2,6)
			IF MEM.ILFMAX=1
				REPLACE S4VAL WITH AVGTS
			ELSE && WITH variable input load
				REPLACE S4VAL WITH AVGTS*pnILF
			ENDIF
		ENDIF
		IF pnL=pnSteps
			thisform.SUBTRACT
&&			CALCULATE AVG(S3VAL) TO nAVG
&&			pnAVG=pnAVG+nAVG
			IF MEM.MODE<4 OR nY=nTimes
				pnIC=MAX(1,pnIC+1)
&&&				IF INLIST(MEM.MODE,1,3,4)
&&&					thisform.LBS4.Caption=LEFT(thisform.LBS4.Caption,RAT(CHR(13),thisform.LBS4.Caption))+"Iterations :"+STR(pnIC,4)
&&&				ENDIF
				thisform.LBMGC.Caption=LEFT(thisform.LBMGC.Caption,RAT(CHR(13),thisform.LBMGC.Caption,2))+"Iterations :"+STR(pnIC,4)+CHR(13)+STR(pnBShift,6,2)&&+STR(nAVG,5,1)
			ENDIF
		ENDIF
	ENDFOR
&&	IF pnL=pnSteps
&&		FOR nX=1 TO pnL
&&			SELECT SIMCOR1
&&			GO nX
&&			SELECT SIMCOR2
&&			GO nX
&&			SELECT SIMCOR3
&&			GO nX
&&			SELECT SIMCOR4
&&			GO nX
&&		ENDFOR
&&	ENDIF
	SELECT SIMCOR1
	RETURN
	
	PROCEDURE KEHOE(nX)
	FOR nX=1 TO 4
		cX=LTRIM(STR(nX))
		thisform.MAKE_EBR(cX)
&&		SELECT SIMCOR&cX
&&		ZAP
&&		APPEND FROM SIMCOREBR&cX
	ENDFOR
	RETURN
	
	PROCEDURE NONASSOCP(nF,nAVGTS)
	nAVGTS=0
	DO CASE
	CASE (nF=1 AND AVGTS<1000) OR (nF=2 AND AVGTS<MEM.CAP) && na-P % non-capped (but still with a limit against numeric overflow)
																		&& OR capped  && MEM.P0 is a % ! -> /100
		nAVGTS=MAX(1,AVGTS)*MEM.P0*pnILF/100
	CASE nF=3 OR (nF=4 AND AVGTS<MEM.CAP)  && na-P constant non capped OR capped
		nAVGTS=MEM.P0*pnILF
	ENDCASE
	RETURN(nAVGTS)

	PROCEDURE NONASSOCD(nF,nAVGTS)
	
	nAVGTS=0
	DO CASE && D needs no capping
	CASE nF=2 && na-D % non-capped
		nAVGTS=-MAX(1,AVGTS)*MEM.D0*pnILF/100
	CASE nF=4 && na-D constant non-capped
		nAVGTS=-MEM.D0*pnILF
	ENDCASE
	RETURN(nAVGTS)
	
	PROCEDURE NONASSOCEBR(nF3_4,nF3_5,nAVGTS,nILF)
	DO CASE
	CASE (nF3_4=1 AND SYNAVG<1000) OR (nF3_4=2 AND SYNAVG<MEM.CAP) && na-P % non-capped (but still with a limit against numeric overflow)
																		&& OR capped  && MEM.P0 is a % ! -> /100
		nAVGTS=nAVGTS + MAX(1,SYNAVG)*MEM.P0*nILF/100
	CASE nF3_4=3 OR (nF3_4=4 AND SYNAVG<MEM.CAP)  && na-P constant non capped OR capped
		nAVGTS=nAVGTS + MEM.P0*nILF
	ENDCASE

	DO CASE && D needs no capping
	CASE nF3_5=2 && na-D % non-capped
		nAVGTS=nAVGTS - MAX(1,SYNAVG)*MEM.D0*nILF/100
	CASE nF3_5=4 && na-D constant non-capped
		nAVGTS=nAVGTS - MEM.D0*nILF
	ENDCASE
	RETURN(nAVGTS)
	
	PROCEDURE NEGASSOCEBR(nF3_4,nF3_5,nAVGTS,nILF,nF)
	nF=nF3_4-4
	IF nF3_4>4
		&&	CASE nF3_4=5 && na-P % non-capped
		&&	CASE nF3_4=6 && na-P % capped
		&&	CASE nF3_4=7 && na-P constant non-capped
		&&	CASE nF3_4=8 && na-P constant capped
		nAVGTS=thisform.NONASSOCEBR(nF,0,nAVGTS,nILF)
	ENDIF
	nF=nF3_5-5
	IF nF3_5>4
		&&	CASE nF3_5=6 && na-D % non-capped
		&&	CASE nF3_5=8 && na-D constant non-capped
		nAVGTS=thisform.NONASSOCEBR(0,nF,nAVGTS,nILF)
	ENDIF
	RETURN(nAVGTS)

	PROCEDURE SCATTERADDRESS_ELL(pnP,pnD,nS3VAL,	nRec,nX,nRec2,nAVGTS,nAS) && Pure random addressing (RA)
	&& The program strategy is to deliver the signal of the right timeslice also to a wrong address
	&& and not to get the signal out of a wrong address to deliver it to the actual address as in type 3
	nRec=RECNO()
	FOR nX=1 TO MEM.WA
		GO RAND()*pnSteps+1
		nRec2=RECNO()
		nAVGTS=0
		IF MEM.F3_5=4
			IF MEM.ILFMAX>1
				nAS=AVGTS*ASC(SUBSTR(pcILF,nRec2,1))*pnP+nS3VAL
				IF nAS=>MEM.B+pnBShift AND nAS<MEM.CA+pnBShift
					nAVGTS=nAVGTS + (MEM.CA+pnBShift - nAS)*pnP
				ENDIF
			ELSE
				nAS=AVGTS*pnP+nS3VAL
				IF nAS=>MEM.B+pnBShift AND nAS<MEM.CA+pnBShift
					nAVGTS=nAVGTS + (MEM.CA+pnBShift - nAS)*pnP
				ENDIF
			ENDIF
		ENDIF
		IF MEM.F3_6=1
			IF MEM.ILFMAX>1
				nAS=AVGTS*ASC(SUBSTR(pcILF,nRec2,1))*pnD+nS3VAL
				IF nAS=>MEM.B+pnBShift AND nAS=>MEM.CA+pnBShift
					nAVGTS=nAVGTS + (MEM.CA+pnBShift - nAS)*pnD
				ENDIF
			ELSE
				nAS=AVGTS*pnD+nS3VAL
				IF nAS=>MEM.B+pnBShift AND nAS=>MEM.CA+pnBShift
					nAVGTS=nAVGTS + (MEM.CA+pnBShift - nAS)*pnD
				ENDIF
			ENDIF
		ENDIF
		REPLACE AVGTS WITH MAX(0,AVGTS + nAVGTS)
	ENDFOR
	GO nRec
	RETURN
	
	PROCEDURE GFDUR_EBR(nS3VAL,	nGFDUR,nRec,nX,nAVGTS,nY)
	nS3VAL=S3VAL
	nAVGTS=AVGTS
	nRec=RECNO()
	nY=1.5*pnHI
	nGFDUR=MEM.GFDUR
	nCount=0
	FOR nX=1 TO pnL && no difference with pnSteps !
		IF BETWEEN(pnL,nX,nX-1+nGFDUR)
		nCount=nCount+1
			GO nX
&&			DO CASE
&&			CASE MEM.MODE=3
&&				REPLACE AVGTS WITH AVGTS - AVGTS*pnD/(nGFDUR) + nS3VAL*pnP/nGFDUR
&&			CASE MEM.MODE=4 && Formula of M&M
				IF BETWEEN(nRec,MEM.ISI,MEM.ISI+10)
					REPLACE AVGTS WITH AVGTS - AVGTS*ASC(SUBSTR(pcILF,nX,1))*pnD/(nGFDUR*1) && + nS3VAL*pnP/(nGFDUR*1)
				ELSE
					REPLACE AVGTS WITH AVGTS + nS3VAL*pnP/(nGFDUR*1)
				ENDIF
&&			CASE MEM.MODE=5 && Formula of M&M supplemented with na-D
&&				IF BETWEEN(nRec,MEM.ISI,MEM.ISI+10)
&&					REPLACE AVGTS WITH AVGTS - AVGTS*ASC(SUBSTR(pcILF,nX,1))*pnD/(nGFDUR*1) && + nS3VAL*pnP/(nGFDUR*1)
&&				ELSE
&&					REPLACE AVGTS WITH AVGTS - AVGTS*pnD/(nGFDUR) + nS3VAL*pnP/(nGFDUR*1)
&&				ENDIF
&&			ENDCASE
			nY=nY+1
		ENDIF
	ENDFOR
	GO nRec
	RETURN
	
	PROCEDURE TIMESLICEOVL(nS3VAL,	nRec,nX,nGFDUR,nAVGTS)
	nS3VAL=S3VAL
	nAVGTS=AVGTS
	nRec=RECNO()
	nGFDUR=MEM.GFDUR
	FOR nX=-nGFDUR TO nGFDUR
		IF BETWEEN(nRec+nX,1,pnSteps)
			GO nRec+nX
&&			nAVGTS=ICASE(ABS(nX)=3,-nS3VAL*pnP,ABS(nX)=1,nS3VAL*pnD*.5,ABS(nX)=0,nS3VAL*pnD,0)
&&			nAVGTS=ICASE(ABS(nX)>25,-nS3VAL*pnP,ABS(nX)>12,nS3VAL*pnD*.5,ABS(nX)>5,nS3VAL*pnD,0)
&&			nAVGTS=nS3VAL*pnP/(nGFDUR*2*5)
&&			REPLACE AVGTS WITH AVGTS - (nAVGTS*ASC(SUBSTR(pcILF,nRec+nX,1))*pnD + nS3VAL*pnP)/(nGFDUR*2*5)
			IF nRec>125
				REPLACE AVGTS WITH AVGTS - nAVGTS*ASC(SUBSTR(pcILF,nRec+nX,1))*pnD/(nGFDUR*2*5)
			ELSE
				REPLACE AVGTS WITH AVGTS + nS3VAL*pnP/(nGFDUR*2*5)
			ENDIF
&&			REPLACE AVGTS WITH AVGTS - nAVGTS*ASC(SUBSTR(pcILF,nRec+nX,1))
		ENDIF
	ENDFOR
	GO nRec
	RETURN
	
	PROCEDURE MAKE_S1(cAlias,nL,nS)
	SELECT (cAlias)
	FOR nL=1 TO pnSteps
		DO CASE
		CASE MEM.S1=1 OR MEM.S1=4
			nS=thisform.S1BASE(nL)
		CASE MEM.S1=2
			nS=0
		CASE MEM.S1=3
			nS=-thisform.S1BASE(nL)
		CASE MEM.S1=5 AND MEM.MODE=6
			nS=20
			IF BETWEEN(nL,MEM.ISI,MEM.ISI+MEM.USDUR)
				nS=40
			ENDIF
		CASE MEM.S1=5 AND MEM.MODE=3
			nS=40
			IF BETWEEN(nL,MEM.ISI,MEM.ISI+MEM.USDUR)
				nS=80
			ENDIF
		ENDCASE
		GO nL
		REPLACE S1VAL WITH nS + MEM.S1LIFT + IIF(MEM.AUTOLIFT=1,pnLiftS1,0)
	ENDFOR
	IF MEM.S1=4
		CALCULATE AVG(S1VAL) TO pnAVG1
		REPLACE ALL S1VAL WITH S1VAL-pnAVG1, S1VAL WITH -S1VAL, S1VAL WITH S1VAL+pnAVG1
	ENDIF
	REPLACE ALL S1VAL WITH S1VAL/pnDivS1
	pnAVG1=thisform.MEDIAN("1")
	RETURN

	PROCEDURE MAKE_S2(cAlias,nL,nS)
	SELECT (cAlias)
	FOR nL=1 TO pnSteps
		DO CASE
		CASE INLIST(MEM.S2,1,4,6)
			nS=thisform.S2BASE(nL)
		CASE MEM.S2=2 && flat
			nS=0
&&					IF pnIC>100
&&						nS=thisform.S2BASE(nL)
&&					ENDIF
		CASE MEM.S2=3
			nS=-thisform.S2BASE(nL)
		CASE MEM.S2=5
			DO CASE
			CASE MEM.MODE=3
				nS=40
				IF BETWEEN(nL,MEM.ISI,MEM.ISI+MEM.USDUR)
					nS=80
				ENDIF
			CASE MEM.MODE=5
				DO CASE
				CASE cAlias="SIMCOR1" OR cAlias="SIMCOR2"
					nS=75
				CASE cAlias="SIMCOR3"
					nS=75
					IF nL>MEM.ISI/2
						nS=0
					ENDIF
				CASE cAlias="SIMCOR4"
					nS=0
					IF nL>MEM.ISI/2
						nS=75
					ENDIF
				ENDCASE
				IF nL>MEM.ISI
					nS=0
				ENDIF
			ENDCASE
		ENDCASE
		GO nL
		REPLACE S2VAL WITH nS + MEM.S2LIFT + IIF(MEM.AUTOLIFT=1,pnLiftS2,0)
		pnHMem=nS
	ENDFOR
	IF MEM.S2=4
		CALCULATE AVG(S2VAL) TO pnAVG2
		REPLACE ALL S2VAL WITH S2VAL-pnAVG2, S2VAL WITH -S2VAL, S2VAL WITH S2VAL+pnAVG2
	ENDIF
	REPLACE ALL S2VAL WITH S2VAL/pnDivS2
	pnAVG2=thisform.MEDIAN("2")
	RETURN
	
	PROCEDURE MAKE_EBR(cAlias,nL,nS)
	SELECT ("SIMCOR"+cAlias)
	FOR nL=1 TO pnSteps
		DO CASE
		CASE cAlias="1"
			IF MEM.VARIANT=1
				nS=thisform.GAUSS(nL,2)
			ELSE
				nS=thisform.GAUSS(nL,1)
			ENDIF
		CASE cAlias="2"
			nS=thisform.GAUSS(nL,1)
		CASE cAlias="3"
			nS=thisform.GAUSS(nL+MEM.ISI/2,1) && We shift Peak 3 forward
		CASE cAlias="4"
			DO CASE
			CASE MEM.VARIANT=1
				nS=thisform.GAUSS(nL,2)
			CASE INLIST(MEM.VARIANT,2,6)
				nS=thisform.GAUSS(nL,1)
			CASE INLIST(MEM.VARIANT,3,5,7)
				nS=0
				IF nL=>MEM.ISI/2
					nS=thisform.GAUSS(nL,1)
				ENDIF
&&			CASE MEM.VARIANT=6
&&				nS=thisform.GAUSS(nL,1)
			ENDCASE
		ENDCASE
		GO nL
		REPLACE S5VAL WITH nS &&+IIF(cAlias='4',2,0)
	ENDFOR
	RETURN
	
	PROCEDURE GAUSS(nL,nH,	nS) && 20 is the width, INT(pnIC/7)+1 the height
		nS=INT(4+nH*(INT(pnIC/7)+1)*EXP(1)^(((-4*LOG(2))*(nL-MEM.ISI)^2)/20^2))
	RETURN(nS)

	PROCEDURE S1BASE(nL)
	RETURN(MAX(1,(ABS(MOD(nL,10)-5)/40)*50+2+((SIN(DTOR(nL*13-90))+1)/4)*25			+IIF(MEM.S1JIT=1,(RAND()-.5)*5,0)))
&&	RETURN((MOD(nL,10)-5)+((SIN(DTOR(nL*16-90)))/4)*25)

	PROCEDURE S2BASE(nL)
	RETURN(MIN(30,MAX(10,ABS(pnHMem)+thisform.WANDERINGLINE(nL)*(ABS(MOD(nL,10)-5)/40)*50+IIF(MEM.S2JIT=1,(RAND()-.5)*10,0))))
	
	PROCEDURE SINper100ts25_75(nX)
	&& Sin from -1 to +1 -> +1 -> from 0 to 2 -> /4 -> from 0 to .5 -> +.25 -> from .25 to .75
	RETURN((SIN(DTOR(nX*3.6-90))+1)/4+.25)
	
	PROCEDURE WANDERINGLINE(nX,nR)
	nR=RAND()
	pnR=IIF(MOD(nX,5)=0,nR,pnR)
	RETURN(pnR-.5)
	
	PROCEDURE SCATTERADDRESS(pnP,pnD,nS3VAL,	nRec,nX,nRec2,nRecRand,nAVGTS))
	DO CASE
	CASE MEM.CWA=0 && no correlation && Pure random addressing (RA)
	&& The program strategy is to deliver the signal of the right timeslice also to a wrong address
	&& and not to get the signal out of a wrong address to deliver it to the actual address as in type CWA=1
		nRec=RECNO()
		FOR nX=1 TO MEM.WA
			GO RAND()*pnSteps+1
			nRec2=RECNO()
			IF MEM.ILFMAX>1
				REPLACE AVGTS WITH AVGTS - AVGTS*ASC(SUBSTR(pcILF,nRec2,1))*pnD + nS3VAL*pnP
	&&				REPLACE AVGTS WITH AVGTS - (AVGTS*ASC(SUBSTR(pcILF,nRec2,1)) - nS3VAL)*pnP
			ELSE
				REPLACE AVGTS WITH AVGTS - AVGTS*pnD  + nS3VAL*pnP && Is OK
	&&				REPLACE AVGTS WITH AVGTS + 3*AVGTS*pnP  - ((AVGTS-S3VAL)*pnD + 3*AVGTS*pnP)
	&&				Next SS = aSS + aSS * x% - [ (aSS - aDS ) + aSS ] * x% F(3) .
	&&				REPLACE AVGTS WITH AVGTS + AVGTS*pnP
	&&				REPLACE AVGTS WITH AVGTS - (AVGTS - nS3VAL)*pnP
			ENDIF
	&&		REPLACE AVGTS WITH AVGTS - AVGTS*pnD  + nS3VAL*pnP && Is OK
		ENDFOR
	CASE MEM.CWA=1 && WA with structural correlation
		&& Random addressing but for every timeslice the same wrong addresses are used at every iteration.
		&& This comes closer to reality where a GS reproduces the same sequence at every iteration
		nRec=RECNO()
		FOR nX=1 TO MEM.WA
			nRecRand=ASC(SUBSTR(pcWA,(nRec-1)*MEM.WA+nX))
			GO nRecRand
			nS3VAL=S3VAL && get the signal value for the nXth member of the randomly chosen addresses for this timeslice 
			GO nRec
			REPLACE AVGTS WITH AVGTS - AVGTS*pnD  + nS3VAL*pnP && apply the plasticity rule
		ENDFOR
	ENDCASE
	GO nRec
	RETURN
	
	PROCEDURE SCATTERADDRESS2(pnP,pnD,nS3VAL,	nRec,nX,nR,nLen) && RA but ensuring that all 250 addresses get their share
	nRec=RECNO()
	FOR nX=1 TO MEM.WA
		nLen=LEN(pcScA)
		nR=RAND()*nLen+1
		GO ASC(SUBSTR(pcScA,nR,1))
		REPLACE AVGTS WITH AVGTS - AVGTS*pnD  + nS3VAL*pnP && Is OK
		pcScA=STUFF(pcScA,nR,1,'')
	ENDFOR
	GO nRec
	RETURN
	
	PROCEDURE SCATTERADDRESS3(pnP,pnD,	nS3VAL,nRec,nX,nRecRand,nAVGTS)
	&& Random addressing but for every timeslice the same wrong addresses are used at every iteration.
	&& This comes closer to reality where a GS reproduces the same sequence at every iteration
	nRec=RECNO()
	FOR nX=1 TO MEM.WA
		nRecRand=ASC(SUBSTR(pcWA,(nRec-1)*MEM.WA+nX))
		GO nRecRand
		nS3VAL=S3VAL && get the signal value for the nXth member of the randomly chosen addresses for this timeslice 
		GO nRec
		REPLACE AVGTS WITH AVGTS - AVGTS*pnD  + nS3VAL*pnP && apply the plasticity rule
	ENDFOR
	RETURN
	
	PROCEDURE SUBTRACT(nL,nFit1,nfS2VAL,nfS5VAL,nX,nMAX)
	STORE 0 TO nFit1
	&& Subtracting S4 from S3 gives S5 - to which we will add a constant for the display.
	&& S4 = 'unpredictable signal' and we also project it via S6 (red line) on S2 and the other way round on S7
	STORE 99999.00 TO pnAVMinS1,pnAVMinS4, pnAVMinS2,pnAVMinS5, pnAVMinS3
	STORE 0 TO pnAVMaxS5,pnMRS2
	
	&& At the same time look for the minima
	SCAN
		DO CASE
		CASE MEM.MODE=6 AND MEM.S2=6
			REPLACE S5VAL WITH S1VAL+S4VAL
			REPLACE S6VAL WITH S2VAL+S4VAL
		CASE INLIST(MEM.MODE,1,3,4) && The 'old' formula assumes a DS signal that is subtracted at the synapse
			REPLACE S5VAL WITH S3VAL-S4VAL && Check from which demo on MAX must be used !
		CASE MEM.MODE=5
			REPLACE S5VAL WITH MAX(0,S3VAL-S4VAL)
		OTHERWISE && In MGCs the apical and basilar output are summed algebraically
			REPLACE S5VAL WITH S3VAL+S4VAL
			pnAVMaxS2=MAX(pnAVMaxS2,S2VAL)
			pnAVMaxS5=MAX(pnAVMaxS5,S5VAL)
		ENDCASE
		pnAVMinS1=MIN(pnAVMinS1,S1VAL)
		pnAVMinS4=MIN(pnAVMinS4,S4VAL)
		pnAVMinS2=MIN(pnAVMinS2,S2VAL)
		pnAVMinS5=MIN(pnAVMinS5,S5VAL)
		pnAVMinS3=MIN(pnAVMinS3,S3VAL)
	ENDSCAN
	pnLiftM1=pnAVMinS4-pnAVMinS1
	pnLiftM2=pnAVMinS5-pnAVMinS2
	pnLiftM3=pnAVMinS4-pnAVMinS3
	pnLift1=pnAVG4-pnAVG1
	pnLift2=pnAVG5-pnAVG2
	pnLift3=pnAVG4-pnAVG3
	IF MEM.S2=6
		pnLift4=pnAVG6-pnAVG1
	ENDIF
	IF MEM.PEN=1
		pnBShift=MAX(0,pnBShift+IIF((pnAVMaxS5-pnAVMinS5)>3,.1,-.1))
		pnMRS2=MAX(pnMRS2,pnAVMaxS2-pnAVMinS2)
		pnMRMAXS2=MAX(pnMRS2,pnMRMAXS2)
&&		FOR nX=1 TO 10
&&			cX=LTRIM(STR(nX))
&&			nY=VAL(SUBSTR("1231212312",nX,1))
&&			thisform.LTC&cX..Top=nY*pnHI-oDashboard.SP5_5.Value-1-pnBShift
&&			thisform.LTB&cX..Top=nY*pnHI-oDashboard.SP5_6.Value-1-pnBShift
&&		ENDFOR
		thisform.LTC3.Top=pnTop3-oDashboard.SP5_5.Value-1-pnBShift
		thisform.LTCL3.Top=thisform.LTC3.Top-4
		thisform.LTB3.Top=pnTop3-oDashboard.SP5_6.Value-1-pnBShift
		thisform.LTBL3.Top=thisform.LTB3.Top-4
	ENDIF
	pnAVG3=thisform.MEDIAN("3")
	pnAVG4=thisform.MEDIAN("4")
	pnAVG5=thisform.MEDIAN("5")
	IF MEM.S2=6
		pnAVG6=thisform.MEDIAN("6")
	ENDIF
	FOR nL=1 TO pnSteps-1
		GO nL
		IF nL>1
			nFit1=nFit1+(((nfS2VAL-S2VAL)-(nfS5VAL-S5VAL))^2) &&/2
			IF MEM.AUTOLIFT=1
				IF MEM.VARIANT=>10 AND S5VAL<MEM.VARIANT && no output at all of the MGC
					pnLiftS1=pnLiftS1+.001
					pnLiftS2=pnLiftS2+.001
				ENDIF
			ENDIF
		ENDIF
		nfS2VAL=S2VAL
		nfS5VAL=S5VAL
	ENDFOR
	nIC=MOD(pnIC,250)
	IF INLIST(MEM.MODE,3,4,5) && 7?
&&	IF INLIST(MEM.MODE,3,4) && 7?
		IF plEBR AND NOT plFlag
			pnIC=pnCycles-1
		ENDIF
		thisform.FIT1.Caption="Iterations : "+STR(pnIC+1,4)
	ELSE
		thisform.FIT1.Caption="Iterations : "+STR(pnIC+1,4)+IIF(NOT 'f'$MEM.DISPLAY,"      "+"Fit S2-S5 : "+LTRIM(STR(nFit1,6,2)),'')
	ENDIF
	IF BETWEEN(nIC,2,pnSteps-1)
		GO nIC+1
		IF nFit1<10000000000
			REPLACE LFITH25 WITH nFit1
		ENDIF
	ENDIF
	
	IF MEM.MODE=4
		CALCULATE MAX(S4VAL) TO nMax
		SCAN
			IF S4VAL>0 AND nMAX-S4VAL>25
				IF ALIAS()="SIMCOR1"
					thisform.CR1.Left=pnLeft2+RECNO()
				ELSE
					thisform.CR2.Left=pnLeft2+RECNO()
				ENDIF
				EXIT
			ENDIF
		ENDSCAN
&&		SELECT SIMCOR2
&&		SCAN
&&			IF S4VAL>0 AND S4VAL<MEM.CA
&&				thisform.CR2.Left=pnLeft2+RECNO()
&&				EXIT
&&			ENDIF
&&		ENDSCAN
&&		SELECT SIMCOR1
	ENDIF
	RETURN(nFit1)
	
	PROCEDURE MEDIAN(c1)
	COPY ALL TO ARRAY SVAL FIELDS S&c1.VAL
	SELECT S&c1.VAL FROM SIMCOR1 INTO ARRAY SVAL
	ASORT(SVAL)
	RETURN(SVAL[125])

	PROCEDURE CB6_1 && Just one timeslice/step
	thisform.GETPDVALUES
	pnSpeed=1
	thisform.ONESTEP
	RETURN
		
	PROCEDURE CB6_2 && One cycle
	plBreak=.F.
	thisform.GETPDVALUES
	pnSpeed=1
	thisform.ONECYCLE
	thisform.DRAWALLLINES
	RETURN
	
	PROCEDURE CB6_3 && One cycle fast
	plBreak=.F.
	thisform.GETPDVALUES
	pnSpeed=2
	thisform.ONECYCLE
	RETURN
	
	PROCEDURE QueryUnload
	plBreak=.T.
	plQuit=.T.
	RETURN
	
	PROCEDURE CB6_4 && pnCycles cycles
	plBreak=.F.
	REPLACE ALL LFITH25 WITH 0
	thisform.SetAll("Height",0,"LFIT")
	pnCycles=pnCycles+pnSteps
	thisform.GETPDVALUES
	pnSpeed=2
	thisform.ALLCYCLES
	thisform.LBP.RightClick(.T.)
	IF plBreak
		thisform.Visible=.F.
		thisform.Release
	ENDIF
	RETURN
	
	PROCEDURE CB6_5 && pnCycles cycles
	REPLACE ALL LFITH25 WITH 0
	thisform.SetAll("Height",0,"LFIT")
	pnCycles=pnCycles+pnSteps
	thisform.GETPDVALUES
	pnSpeed=3
	thisform.ALLCYCLES
	thisform.DRAWALLLINES
	IF plBox
		CALCULATE MIN(S1VAL) TO nMin1
		thisform.Box(pnLeft1,pnTop1,pnLeft1+pnSteps+1,pnTop1-nMin1)
		CALCULATE MIN(S2VAL) TO nMin2
		thisform.Box(pnLeft1,pnTop2,pnLeft1+pnSteps+1,pnTop2-nMin2)
		CALCULATE MIN(S3VAL) TO nMin3
		thisform.Box(pnLeft1,pnTop3,pnLeft1+pnSteps+1,pnTop3-nMin3)
		CALCULATE MIN(S4VAL) TO nMin4
		thisform.Box(pnLeft2,pnTop1,pnLeft2+pnSteps+1,pnTop1-nMin4)
		plBox=.F.
	ENDIF
	RETURN
	
	PROCEDURE CB6_6
	thisform.RESET(NOT RUNNING_NOW()) && GitHub version: during a run, Reset also stops the run
	RETURN
	
	PROCEDURE RESET(lNoBreak,nX,cX,nY,cY)
	thisform.Cls
	thisform.SetAll("BorderWidth",1,"L3")
	thisform.SetAll("BorderWidth",1,"L4")
	thisform.LB01.Visible=.F.
	thisform.LB011.Visible=.F.
	thisform.LB02.Visible=.F.
	thisform.LB022.Visible=.F.
	pnIC=0
	pnL=0
	thisform.LBS4.Caption=LBS(IIF(MEM.MODE=2,2,1),4)
	thisform.FIT1.Caption= ''
	thisform.LBP.Value='Decorrelating algorithm'
	FOR nY=1 TO 4
		cY=LTRIM(STR(nY))
		SELECT SIMCOR&cY
		BLANK ALL
	ENDFOR
	SELECT SIMCOR1
	thisform.SetAll("Height",0,"LFIT")

	FOR nX=1 TO thisform.ControlCount
		IF INLIST(UPPER(thisform.Controls(nX).BaseClass),"LINE")
			thisform.Controls(nX).Height=0
		ENDIF
	ENDFOR
	IF NOT lNoBreak
		plBreak=.T.
	ELSE
		plBreak=.F.
	ENDIF
	STORE 0 TO pnCycles,pnBShift,pnMRMAXS2,pnLiftS1,pnLiftS2
	thisform.LBPCAPTION
	thisform.CR1.Left=-5
	thisform.CR2.Left=-5
	RETURN

	PROCEDURE GETPDVALUES(nX,nL)
	IF pnIC>0
		RETURN
	ENDIF
	pnD=MEM.D/100
	pnP=MEM.P/100
	pcILF=''
	FOR nX=1 TO pnSteps
		pcILF=pcILF+CHR(RAND()*(MEM.ILFMAX-1)*10+10)
	ENDFOR
	
	&& Still to be used ? see "pcGFD_CWA="
	pcGFDUR=''
	FOR nX=1 TO pnSteps
		pcGFDUR=pcGFDUR+CHR(RAND()*(MEM.GFDUR-1)+1)
	ENDFOR
	&&

	pcScAM=''
	FOR nX=1 TO pnSteps
		pcScAM=pcScAM+CHR(nX)
	ENDFOR
	pcScAM=REPLICATE(pcScAM,MEM.WA)
	RAND(-1)
	pcWA=''
	FOR nL=1 TO pnSteps
		FOR nX=1 TO MEM.WA
			pcWA=pcWA+CHR(RAND()*pnSteps+1)
		ENDFOR
	ENDFOR
	RETURN
	
	PROCEDURE ALLCYCLES(nX,nT)
	IF MEM.MODE=3
		thisform.SetAll("BorderWidth",MEM.DLW,"L3")
		thisform.SetAll("BorderWidth",MEM.DLW,"L4")
	ELSE
		thisform.SetAll("BorderWidth",1,"L3")
		thisform.SetAll("BorderWidth",1,"L4")
	ENDIF
	plEBR=.F.
	FOR nX=pnIC+1 TO pnCycles STEP MEM.DLW
		IF nX=1 &&INLIST(pcCMD,"26")
&&			IF INT((nX-1)/10)=(nX-1)/10
&&				WAIT '' && GitHub version: a run starts at once
&&			ENDIF
		ENDIF
		plFlag=.F.
		thisform.ONECYCLE
		DOEVENTS
		IF plBreak
			EXIT
		ENDIF
		DO WHILE plPause
			DOEVENTS
			IF plBreak
				EXIT
			ENDIF
		ENDDO
		IF nX=1
			thisform.LBPCAPTION
		ENDIF
		IF nX=MEM.STOP OR (plEBR AND NOT plFlag AND nX>5)
			EXIT
		ENDIF
	ENDFOR
&&	ENDIF
	IF NOT plQuit
		plBreak=.F.
		thisform.DRAWALLLINES
		thisform.LBPCAPTION
	ENDIF
	RETURN

	PROCEDURE ONECYCLE(nX) && One cycle
	pcScA=pcScAM
	DO WHILE .T.
		thisform.ONESTEP
		IF pnL=0 OR plBreak
			EXIT
		ENDIF
	ENDDO
&&	WAIT WINDOW STR(pnIC) NOWAIT
	IF pnSpeed=2 AND (pnIC=1 OR pnIC/10=INT(pnIC/10) OR pnIC<MEM.SLOW)
		FOR nX=1 TO MEM.SLOW*1000000 STEP pnIC*pnIC && Coverage : set to 1 TO 1 !
			IF pnIC<2
				EXIT
			ENDIF
		ENDFOR
		thisform.DRAWALLLINES
	ENDIF
	RETURN

	PROCEDURE ONESTEP
	IF MEM.MODE=5 && EBR3
		IF pnL=1
			thisform.KEHOE
		ENDIF
		pnL=pnL+1
		IF pnL=pnSteps
			thisform.FIT1.Caption="Iterations : "+STR(pnIC+1,4)
			pnIC=MAX(1,pnIC+1)
		ENDIF
	ELSE
		thisform.STEP
	ENDIF
	IF pnSpeed=1
		thisform.DRAWALLLINESOF1STEP(pnL)
		WAIT '' TIMEOUT .001
	ENDIF
	IF pnL=pnSteps
		pnL=0
	ENDIF
	RETURN

	PROCEDURE DRAWALLLINES(nL,cL,nMax4,nMax5,nLim4,nLim5)
&&	cMF="M"
	pnMaxFit=oDecorrelator.FIT1.Top-oDecorrelator.LBS5.Top-oDecorrelator.LBS5.Height-5
&&	IF pnIC<=250
		CALCULATE MAX(LFITH25) TO pnMaxLFITH
&&	ENDIF
	pnDivMax=INT(pnMaxLFITH/pnMaxFit)+1
	nMax4=0
	nMax5=0
	FOR nL=1 TO pnSteps STEP MEM.DLW
		thisform.DRAWALLLINESOF1STEP(nL)
&&		thisform.DRAWALLLINESOF1STEP2(nL,"F")
		IF (pnIC=pnCycles OR plScreenShow)
			cL=LTRIM(STR(nL))
			nMax4=MAX(nMax4,thisform.L4&cL..Height)
			nMax5=MAX(nMax5,thisform.L5&cL..Height)
		ENDIF
&&		WAIT WINDOW STR(nL) NOWAIT
	ENDFOR
&&	pnMEMS1=MEM.S1

	IF (pnIC=pnCycles OR plScreenShow) AND MEM.MODE<3
		nLim4=IIF(INLIST(MEM.MODE,3,4),pnTop4-2,90) && 7?
		IF nMax4>nLim4
			FOR nL=1 TO pnSteps
				cL=LTRIM(STR(nL))
				thisform.L4&cL..Height=MAX(0,thisform.L4&cL..Height-(nMax4-nLim4)-10)
				thisform.L4&cL..Top=pnTop4-thisform.L4&cL..Height-10
&&				IF MEM.MODE<3
				thisform.LR14&cL..Top=thisform.LR14&cL..Top+(nMax4-nLim4)
&&				ENDIF
			ENDFOR
		ENDIF
		thisform.LB01.Visible= ( nMax4>nLim4 )
		thisform.LB011.Visible= ( nMax4>nLim4 )
		nLim5=IIF(INLIST(MEM.MODE,3,4),180,80) && 7?
		IF nMax5>nLim5
			FOR nL=1 TO pnSteps
				cL=LTRIM(STR(nL))
				thisform.L5&cL..Height=MAX(0,thisform.L5&cL..Height-(nMax5-nLim5)-10)
				thisform.L5&cL..Top=pnTop5-thisform.L5&cL..Height-10
&&				IF MEM.MODE<3
				thisform.LR25&cL..Top=thisform.LR25&cL..Top+(nMax5-nLim5)
&&				ENDIF
			ENDFOR
		ENDIF
		thisform.LB02.Visible= ( nMax5>nLim5 )
		thisform.LB022.Visible= ( nMax5>nLim5 )
	ENDIF

	FOR nX=1 TO 5
		cX=LTRIM(STR(nX))
		thisform.LBS&cX..Top=LBS(8,nX)+LBS(9,nX)
		IF (nX=1 OR nX=2) AND oDashBoard.SP&cX._1.Value=3 AND oDashBoard.SP&cX._3.Value=0
			thisform.LBS&cX..Top=LBS(8,nX)-thisform.LBS&cX..Height-5
		ENDIF
		IF nX=3
			thisform.LBS3.Top=LBS(8,3)+MAX(IIF(MEM.S1=3,0,LBS(9,1)),LBS(9,3))
		ENDIF
		IF nX>1
			LBS(9,nX)=0
		ENDIF
	ENDFOR
	thisform.LBPCAPTION
	thisform.LBMGC.ZOrder(0)
	RETURN
		
	PROCEDURE DRAWALLLINESOF1STEP(nL,	cL,nT,nX,cX) &&,nLift1,nLift2)
	pnF=1
	GO nL
	IF MEM.MODE=3 OR MEM.MODE=7
		thisform.DRAWALLLINESOF1STEPEBR1(nL)
		RETURN
	ENDIF
	IF MEM.MODE=4
		thisform.DRAWALLLINESOF1STEPEBR2(nL)
		RETURN
	ENDIF
	IF MEM.MODE=5
		thisform.DRAWALLLINESOF1STEPEBR3(nL)
		RETURN
	ENDIF
	IF pnIC>0
		thisform.DRAWSPECIFICLINE(pnTop2, S2VAL,                          "2",   nL,pnCyaan)
		thisform.DRAWSPECIFICLINE(pnTop3, S3VAL,                          "3",   nL,pnCyaan)
		thisform.DRAWSPECIFICLINE(IIF(MEM.S2=6,pnTop6,pnTop4), S4VAL,                          "4",   nL,pnLichtRood)
&&		IF NOT MEM.S2=6
			thisform.DRAWSPECIFICLINE(pnTop5, S5VAL-IIF(MEM.MODE=1,pnLiftM2,0),"5",   nL,pnCyaan)
			&& NO constant added in ELL mode : S5 now modulates around the zero line !
&&		ENDIF

		IF pnIC=1 OR pnIC=pnCycles OR MEM.S1JIT=1 OR MEM.AUTOLIFT=1 OR plScreenShow && OR pnMEMS1#MEM.S1 OR VAL(pcCMD)=74
			thisform.DRAWSPECIFICLINE(pnTop1,S1VAL,"1",nL,pnLichtRood)
			IF SIGN(S1VAL)=SIGN(S2VAL) OR SIGN(S2VAL)=0 
				thisform.DRAWSPECIFICLINE(pnTop3,S1VAL,"6",nL,pnLichtRood)
			ENDIF
		ENDIF

		IF MEM.S2=6
			thisform.DRAWSPECIFICLINE(pnTop4, S6VAL,                        "7",   nL,pnLichtRood)

			thisform.DRAWSPECIFICLINE(pnTop4-(thisform.AP("1","6")-pnLift4),                  2,         "R36", nL,pnCyaan)
			&& Projection of 1 on 6
			thisform.DRAWSPECIFICLINE(pnTop1-(thisform.AP("6","1")+pnLift4),                  2,         "R63", nL,pnCyaan)
			&& Projection of 6 on 1
		ENDIF
&&		IF NOT INLIST(MEM.MODE,3,6,7)
		IF NOT INLIST(MEM.MODE,3,7)
			IF MEM.MODE=1
				thisform.DRAWSPECIFICLINE(pnTop4-(S1VAL+pnLiftM1),                                    2,         "R14", nL,pnCyaan)
				&& Projection of 1 on 4
				thisform.DRAWSPECIFICLINE(pnTop1-(S4VAL-pnLiftM1),                    2,         "R41", nL,pnCyaan)
				&& Projection of 4 on 1
			ELSE
				thisform.DRAWSPECIFICLINE(pnTop3+(-S3VAL-S4VAL),                                   2,         "8",   nL,pnGeel)
				IF MEM.S2=6 && S2 unchanging
					thisform.DRAWSPECIFICLINE(pnTop6-(thisform.AP("3","4")-pnLift3),                  2,         "R14", nL,pnCyaan)
					&& Projection of 3 on 4
					thisform.DRAWSPECIFICLINE(pnTop3-(thisform.AP("4","3")+pnLift3),  2,         "R41", nL,pnRood) && *pnDivS1+pnLift3*pnDivS1)
					&& Projection of 4 on 3
				ELSE
					thisform.DRAWSPECIFICLINE(pnTop4-(thisform.AP("1","4")-pnLiftM1),                  2,         "R14", nL,pnCyaan)
					&& Projection of 1 on 4
					thisform.DRAWSPECIFICLINE(pnTop1-(thisform.AP("4","1")+pnLiftM1),  2,         "R41", nL,pnCyaan)
					&& Projection of 4 on 1
				ENDIF
			ENDIF
			IF MEM.S2=6
				thisform.DRAWSPECIFICLINE(pnTop5-(thisform.AP("2","5")-pnLift2),                    2,         "R25", nL,pnRood)
				&& Projection of 2 on 5
				thisform.DRAWSPECIFICLINE(pnTop2-(thisform.AP("5","2")+pnLift2),                                    2,         "R52", nL,pnRood)
				&& Projection of 5 on 2
			ELSE
				thisform.DRAWSPECIFICLINE(pnTop5-(S2VAL+IIF(INLIST(MEM.MODE,2,6),pnLiftM2,0)),                    2,         "R25", nL,pnRood)
				&& Projection of 2 on 5
				thisform.DRAWSPECIFICLINE(pnTop2-(S5VAL-pnLiftM2),                                    2,         "R52", nL,pnRood)
				&& Projection of 5 on 2
			ENDIF
		ENDIF
&&pcTxt=pcTxt+STR(nL)+STR(pnIC)+CHR(13)
		IF MOD(pnIC,250)=1 AND nL=1
&&			REPLACE ALL LFITH25 WITH 0
&&			thisform.SetAll("Height",0,"LFIT")
		ENDIF
		IF NOT 'f'$MEM.DISPLAY &&MEM.S2=6
			IF INLIST(MEM.MODE,1,2,6) AND nL>1 && to avoid the first, mostly very high value -> less chance of a height reduction   
				nT=thisform.LBP.Top+thisform.LBP.Height-15
				thisform.DRAWSPECIFICLINE(nT,LFITH25/pnDivMax,"FIT25",nL,pnGeel)
			ENDIF
		ENDIF
	ENDIF
	RETURN
	
	PROCEDURE DRAWALLLINESOF1STEPEBR1(nL,	cL,nT,nX,cX)
	IF pnIC>0
&&		IF pnIC=1 OR NOT MEM.S1=2 && non flat S2
&&			thisform.DRAWSPECIFICLINE(pnTop3, S3VAL,                          "3",   nL,pnCyaan)
&&		ENDIF
		thisform.DRAWSPECIFICLINE(pnTop3, S4VAL,                          "4",   nL,pnLichtRood)
	ENDIF
	RETURN
	
	PROCEDURE DRAWALLLINESOF1STEPEBR2(nL,	cL,nT,nX,cX)
	IF pnIC>0
		thisform.DRAWSPECIFICLINE(pnTop1, S3VAL,                          "1",   nL,pnLichtRood)
		thisform.DRAWSPECIFICLINE(pnTop4, S4VAL,                          "4",   nL,pnLichtRood)

		SELECT SIMCOR2
		GO nL
		thisform.DRAWSPECIFICLINE(pnTop2, S3VAL,                          "2",   nL,pnCyaan)
		thisform.DRAWSPECIFICLINE(pnTop5, S4VAL,                          "5",   nL,pnCyaan)

		SELECT SIMCOR1
	ENDIF
	RETURN
	
	PROCEDURE DRAWALLLINESOF1STEPEBR3(nL,	cL,nT,nX,cX)
	IF pnIC>0
&&		IF INLIST(MEM.VARIANT,1,2,3,4,5)
		SELECT SIMCOR1
		GO nL
		thisform.DRAWSPECIFICLINE(pnTop4, S5VAL,                          "4",   nL,pnLichtRood) && "4" says which line array to use

		IF INLIST(MEM.VARIANT,3,4,5,6,7)
			SELECT SIMCOR2
			GO nL
			thisform.DRAWSPECIFICLINE(pnTop6, S5VAL,                          "5",   nL,pnLichtRood)

			SELECT SIMCOR3
			GO nL
			IF INLIST(MEM.VARIANT,3,4,5,6,7)
				IF nL>MEM.ISI/2
					GO nL-MEM.ISI/2
					GO nL-MEM.ISI/2 IN SIMCOR2 && Lifts SIMCOR3 above SIMCOR2 (4 pixels)
					thisform.DRAWSPECIFICLINE(pnTop6-SIMCOR2.S5VAL, S5VAL,                          "6",   nL-MEM.ISI/2,pnCyaan)
				ENDIF
				IF MEM.VARIANT=3
					IF pnIC=1
						FOR nX=1 TO 2000000 &&pnTop4+oDecorrelator.LBS4.Height,pnLeft2+400,
						ENDFOR
						IF nL=pnSteps
							thisform.US1.Visible=.T.
&&							thisform.US2.Visible=.T.
							oDashBoard.USEBR(pnTop6-10,pnLeft2+MEM.ISI-oDecorrelator.US1LB.Width/2,;
								   			 pnTop6-10,pnLeft2+MEM.ISI/2-oDecorrelator.US0LB.Width/2)
						ENDIF
					ELSE
						thisform.US1.Visible=.T.
&&						thisform.US2.Visible=.T.
						oDashBoard.USEBR(pnTop6-10,pnLeft2+MEM.ISI-oDecorrelator.US1LB.Width/2,;
							   			 pnTop6-10,pnLeft2+MEM.ISI/2-oDecorrelator.US0LB.Width/2)
					ENDIF
				ENDIF
			ELSE
				thisform.DRAWSPECIFICLINE(pnTop6-SIMCOR2.S5VAL, S5VAL,                          "6",   nL,pnCyaan)
			ENDIF
		ENDIF

		SELECT SIMCOR4
		GO nL
		DO CASE
		CASE INLIST(MEM.VARIANT,6) && Peak 4 must be shifted forward (400 ms starts at 0)
			IF nL>MEM.ISI/2
				thisform.DRAWSPECIFICLINE(pnTop8, S5VAL,                          "7",   nL-MEM.ISI/2,pnCyaan) && Half height !
			ENDIF
		CASE INLIST(MEM.VARIANT,2)
			thisform.DRAWSPECIFICLINE(pnTop8, S5VAL,                          "7",   nL,pnCyaan) && Half height !
		OTHERWISE
			thisform.DRAWSPECIFICLINE(pnTop8, S5VAL,                          "7",   nL,pnCyaan)
		ENDCASE

		SELECT SIMCOR1
	ENDIF
	RETURN
	
	PROCEDURE AP(c1,c2,	nVal)
	nVal=S&c1.VAL
	nVal=nVal-pnAVG&c2
	nVal=-nVal
	nVal=nVal+pnAVG&c2
	RETURN(nVal)
	
	PROCEDURE DRAWSPECIFICLINE(nTop,nSVAL,cT,nL,nColor,	cL,nT)
	nSVAL=pnF*nSVAL
	IF INLIST(MEM.VARIANT,2,3,4,5,6,7) AND (nL>MEM.ISI/2 AND NOT ALIAS()="SIMCOR3" AND NOT ALIAS()="SIMCOR4")
&&		nSVAL=4+INT((nSVAL-4)/2) && to keep the baseline at 4 and to halve only the peak above it
	ENDIF
&&	IF INLIST(MEM.VARIANT,6,7) AND ALIAS()="SIMCOR4"
&&		nSVAL=4+INT((nSVAL-4)/2) && to keep the baseline at 4 and to halve only the peak above it
&&	ENDIF
	IF INLIST(MEM.VARIANT,6) AND ALIAS()="SIMCOR1" && No Peak 1 with L only testing
		RETURN
	ENDIF
	IF INLIST(MEM.VARIANT,7) AND ALIAS()="SIMCOR4" && No Peak 4 with T only testing
		RETURN
	ENDIF
	cL=cT+LTRIM(STR(nL))
	thisform.L&cL..BorderColor=nColor
	IF nSVAL=>0
		thisform.L&cL..Height=nSVAL
		thisform.L&cL..Top=nTop-nSVAL
	ELSE
		thisform.L&cL..Top=nTop-1
		thisform.L&cL..Height=-nSVAL
	ENDIF
	nT=VAL(SUBSTR(CHRTRAN(cT,'R',''),1))
	IF INLIST(nT,1,2,3,4,5)
		LBS(9,nT)=MAX(LBS(9,nT),-MIN(0,nSVAL))
	ENDIF
	RETURN
	
	PROCEDURE DEMO(lDemo,nDemo,	cAlias,cLB) && erase CAP=0 ?
	cAlias=ALIAS()
	cLB=CHR(13)+CHR(13)
	IF lDemo
		pcCMD=LTRIM(STR(nDemo))
	ENDIF
	SELECT MEM
	GO pnValueSet
	&& Default values
	REPLACE TIMES WITH 0, AUTOLIFT WITH 0, PEN WITH 0, VARIANT WITH 0
	REPLACE S1JIT WITH 0, S2JIT WITH 0, S1LIFT WITH 0, S2LIFT WITH 0
	REPLACE WA WITH 0, CWA WITH 0, ILFMAX WITH 1
	REPLACE ISI WITH 0, USDUR WITH 0, USFORCE WITH 0, GFDUR WITH 1, GFDMODE WITH 1, GFTRIG WITH 1, GFTMODE WITH 0
	REPLACE DLW WITH 1, STOP WITH 0, CAP WITH 1000, SLOW WITH 0, IBCM WITH 0, DISPLAY WITH "12345000LF"
	
	REPLACE F3_4 WITH 0,F3_5 WITH 0,F3_6 WITH 0,F3_7 WITH 0,S1 WITH 1,S2 WITH 1
	SELECT (cAlias)
	plBox=.F.
	DO CASE
	CASE pcCMD=="4" && SUM and AVG one iteration
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=1,S1=1,S2=1,S4START=-1")
	CASE pcCMD=="5" && SUM and AVG 250 iterations
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=1,S1=1,S2=1,S4START=-1,DISPLAY='1234500LF'")
	CASE pcCMD=="6" && AVG derived
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=2,S1=1,S2=1,S4START=-1")

	CASE pcCMD=="7" && P=D=1
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=1,D=1")
	CASE pcCMD=="8" && P=D=2
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=2,D=2")
	CASE pcCMD=="9" && P=D=5
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=5,D=5")
	CASE pcCMD=="10" && P=D=10
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=10,D=10")

	CASE pcCMD=="11" && P=5 D=2
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=5,D=2")
	CASE pcCMD=="12" && P=2 D=5
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=2,D=5")
	CASE pcCMD=="13" && P=3 D=2
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=3,D=2")
	CASE pcCMD=="14" && P=2 D=3
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,P=2,D=3")

	CASE pcCMD=="15" && S2 with jitter
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S2JIT=1,S4START=-1,P=2,D=2")
	CASE pcCMD=="16" && S1 with jitter
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S1JIT=1,S4START=-1,P=2,D=2")

	CASE pcCMD=="17" && 1 wrong addressings - correlated !
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=1,CWA=1,P=2,D=2")
	CASE pcCMD=="18" && 2 wrong addressings - correlated !
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=2,CWA=1,P=2,D=2")
	CASE pcCMD=="19" && 5 wrong addressings - correlated !
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=5,CWA=1,P=2,D=2")

	CASE pcCMD=="21" && 1 wrong addressings - NOT correlated !
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=1,CWA=0,P=2,D=2")
	CASE pcCMD=="22" && 1 wrong addressings - NOT correlated ! P=4 D=2
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=1,CWA=0,P=4,D=2")
	CASE pcCMD=="23" && 2 wrong addressings - NOT correlated ! P=D=2
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=2,CWA=0,P=2,D=2")
	CASE pcCMD=="24" && 2 wrong addressings - NOT correlated ! P=6 D=2
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,WA=2,CWA=0,P=6,D=2")

	CASE pcCMD=="25" && Boxes added
		plBox=.T.
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=1,S1=1,S2=1,S4START=-1")
		IF NOT lDemo
			thisform.CB6_5
			plBox=.F.
		ENDIF
		RETURN

	CASE pcCMD=="26" && Variable input load factor !
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,ILFMAX=10,P=2,D=2,SLOW=20")
		
	&& ELL ! (MODE=2) S1 and S2 almost always inverted (sometimes flat)
	CASE pcCMD=="27" && na-P constant (1) non-capped, BSa-D 2%, ILFMAX=1 LIKE ROBERTS AND BELL
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=3,S4START=0,"+;
					 "P=0,D=2,P0=1,D0=1,B=20,N=10,CA=0")
	CASE pcCMD=="28" && na-P constant (1) non-capped, BSa-D 2%, ILFMAX=2
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,"+;
					 "P=0,D=2,P0=1,D0=1,B=20,N=10,CA=0")

	CASE pcCMD=="29" && na-P constant (1) capped at B-t, BSa-P 2%, BSa-D 2%, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,"+;
					 "P=2,D=2,P0=1,D0=1,CAP=20,B=20,N=10,CA=40")
	CASE pcCMD=="30" && na-P constant (1) capped at B-t + 20, BSa-P 2%, BSa-D 2%, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,"+;
					 "P=2,D=2,P0=1,D0=1,CAP=40,B=20,N=10,CA=40")
	CASE pcCMD=="31" && na-P constant (1) capped at B-t + 35, BSa-P 2%, BSa-D 2%, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,"+;
					 "P=2,D=2,P0=1,D0=1,CAP=55,B=20,N=10,CA=40")
	CASE pcCMD=="32" && na-P constant (1) capped at B-t + 35, BSa-P 2%, BSa-D 2%, ILFMAX=2, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=4,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,"+;
					 "P=2,D=2,P0=1,D0=1,CAP=55,B=20,N=10,CA=40")

	CASE pcCMD=="33" && na-P constant (.1) non-capped, BSa-P 2%, BSa-D 2%, ILFMAX=2, P0=.1,D0=.1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,"+;
					 "P=2,D=2,P0=.1,D0=.1,B=20,N=10,CA=40,TIMES=5")
	CASE pcCMD=="34" && na-P constant (.01) non-capped, BSa-P 2%, BSa-D 2%, ILFMAX=2, P0=.01,D0=.01, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,"+;
					 "P=2,D=2,P0=.01,D0=.01,B=20,N=10,CA=40,TIMES=25")

	&& REF !
	CASE pcCMD=="35" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=30, S2LIFT=30, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=30,S2LIFT=30,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="36" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=30, S2LIFT=30, ILFMAX=10, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=30,S2LIFT=30,S4START=0,ILFMAX=10,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")

	&& Seeking lower limit CC+UC, lift 62,60,58
	CASE pcCMD=="37" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=26, S2LIFT=26, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=26,S2LIFT=26,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="38" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=25, S2LIFT=25, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=25,S2LIFT=25,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="39" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=24, S2LIFT=24, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=24,S2LIFT=24,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")

	&& Seeking lower limit CC alone, lift 51,50
	CASE pcCMD=="40" && NO na-P, BSa-P 2%, BSa-D 2%, S1 inverted, S2 flat, S1LIFT=20, S2LIFT=21, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=20,S2LIFT=21,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="41" && NO na-P, BSa-P 2%, BSa-D 2%, S1 inverted, S2 flat, S1LIFT=20, S2LIFT=20, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=20,S2LIFT=20,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")

	&& Seeking upper limit CC+UC, lift 62,66,70
	CASE pcCMD=="42" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=31, S2LIFT=31, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=31,S2LIFT=31,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="43" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=33, S2LIFT=33, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=33,S2LIFT=33,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="44" && NO na-P, BSa-P 2%, BSa-D 2%, S1LIFT=35, S2LIFT=35, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=35,S2LIFT=35,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")

	&& Seeking upper limit CC alone, lift 43,45
	CASE pcCMD=="45" && NO na-P, BSa-P 2%, BSa-D 2%, S1 inverted, S2 flat, S1LIFT=43,  ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=43,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="46" && NO na-P, BSa-P 2%, BSa-D 2%, S1 inverted, S2 flat, S1LIFT=47,  ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=47,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")

	&& "45" but without BSa-D !
	CASE pcCMD=="47" && NO na-P, BSa-P 2%, NO BSa-D, S1 inverted, S2 flat, S1LIFT=43,  ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=0,S1=3,S2=2,S1LIFT=43,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")

	&& P and D may be different !!
	CASE pcCMD=="48" && NO na-P, BSa-P 6%, BSa-D 2%, S1LIFT=30, S2LIFT=30, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=30,S2LIFT=30,S4START=0,"+;
					 "P=6,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="49" && NO na-P, BSa-P 2%, BSa-D 6%, S1LIFT=29, S2LIFT=29, ILFMAX=1, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S1LIFT=29,S2LIFT=29,S4START=0,"+;
					 "P=2,D=6,P0=0,D0=0,B=20,N=10,CA=40")

	CASE pcCMD=="50" && Back in Basic mode ! Both ILFMAX=2 and WA=2 ! and P%=6
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=1,S4START=-1,ILFMAX=2,WA=2,CWA=0,P=6,D=2")

	CASE pcCMD=="51" && ELL mode : NO na-P, BSa-P 2%, BSa-D 2%, AUTOLIFT ON !, VARIANT=70 !! (used as lift cap), S2 flat !, CA=50 (to evade squeezing)
		thisform.MEM("MGCFUC=1,MODE=2,VARIANT=70,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=50,AUTOLIFT=1,PEN=0")
	CASE pcCMD=="52" && ELL mode : NO na-P, BSa-P 2%, BSa-D 2%, AUTOLIFT ON !, VARIANT=45 !!(used as lift cap), S2 flat !, CA=50
		thisform.MEM("MGCFUC=1,MODE=2,VARIANT=45,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=50,AUTOLIFT=1,PEN=0")
	CASE pcCMD=="53" && ELL mode : NO na-P, BSa-P 2%, BSa-D 2%, AUTOLIFT ON !, VARIANT=33 !!(used as lift cap), S2 flat !, CA=50
		thisform.MEM("MGCFUC=1,MODE=2,VARIANT=33,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=50,AUTOLIFT=1,PEN=0")
		
	CASE pcCMD=="54" && ELL mode : NO na-P, BSa-P 2%, BSa-D 2%, S2 flat, PEN OFF !, S1LIFT=29, S2LIFT=29, ILFMAX=1
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=29,S2LIFT=29,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="55" && ELL mode : NO na-P, BSa-P 2%, BSa-D 2%, S2 flat, PEN ON !, S1LIFT=29, S2LIFT=29, ILFMAX=1
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=29,S2LIFT=29,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40,PEN=1,TIMES=2")
	CASE pcCMD=="56" && ELL mode : NO na-P, BSa-P 2%, BSa-D 2%, S2 flat, PEN ON !, S1LIFT=29, S2LIFT=29, ILFMAX=2
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=2,S1LIFT=29,S2LIFT=29,S4START=0,ILFMAX=2,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40,PEN=1,TIMES=2")

	&& EBR
	CASE pcCMD=="60" && EBR Basic : CFa-D only, P 0%, D=.1%, S1 + S2 both flat, S1LIFT=50, ISI=160, GFDDUR=10, GFDMODE=1
		&& Only D, all GrCs 10
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=0,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=10,GFDMODE=1,ISI=160,USDUR=20,P=0,D=.1,P0=0,D0=0,CAP=300,B=20,N=10,CA=40,SLOW=30")
	CASE pcCMD=="61" && EBR Basic : CFa-D only, P 0%, D=.1%, S1 + S2 both flat, S1LIFT=50, ISI=160, GFDDUR=100, GFDMODE=1
		&& Only D, all GrCs 100
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=0,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=100,GFDMODE=1,ISI=160,USDUR=20,P=0,D=.1,P0=0,D0=0,B=20,N=10,CA=40,SLOW=30")
	CASE pcCMD=="62" && EBR Basic : CFa-D + neg-CFa-P con, D=.1%, P0 .001, S1 + S2 both flat, S1LIFT=50,  ISI=160, GFDDUR=100, GFDMODE=1
		&& D+P GrCs 100 noCap
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=7,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=100,GFDMODE=1,ISI=160,USDUR=20,P=0,D=.1,P0=.001,D0=0,B=20,N=10,CA=40,SLOW=30")
	CASE pcCMD=="63" && EBR Basic : CFa-D + neg-CFa-P con capped, D=.1%, P0 .001, S1 + S2 both flat, S1LIFT=50,  ISI=160, GFDDUR=100, GFDMODE=1, CAP=125
		&& D+P GrCs 100 Cap 125
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=8,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=100,GFDMODE=1,ISI=160,USDUR=20,P=0,D=.1,P0=.001,D0=0,CAP=125,B=20,N=10,CA=40,SLOW=30")
	CASE pcCMD=="64" && EBR Basic : CFa-D + neg-CFa-P con capped, D=.1%, P0 .001, S1 + S2 both flat, S1LIFT=50,  ISI=160, GFDDUR=100, GFDMODE=1, CAP=250
		&& D+P GrCs 100 Cap 250
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=8,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=100,GFDMODE=1,ISI=160,USDUR=20,P=0,D=.1,P0=.001,D0=0,CAP=250,B=20,N=10,CA=40,SLOW=30")
	CASE pcCMD=="65" && EBR Basic : CFa-D + neg-CFa-P con capped, D=.1%, P0 .001, S1 + S2 both flat, S1LIFT=50,  ISI=160, GFDDUR=100, GFDMODE=1, CAP=-125
		&& D+P GrCs 100 Cap -125 (SynCap=250, PuCCap=125)
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=8,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=100,GFDMODE=1,ISI=160,USDUR=20,P=0,D=.1,P0=.001,D0=0,CAP=-125,B=20,N=10,CA=40,SLOW=30")
	CASE pcCMD=="66" && EBR Basic : CFa-D + neg-CFa-P con capped, D=.1%, P0=.001, S1 + S2 both flat, S1LIFT=50, ISI=160, GFDMODE5 -> GFDUR=RAND()^2*(1-100), CAP=150
		&& D+P GFDUR=RAND()^2*(1-100) Cap 250
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=8,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=100,GFDMODE=5,ISI=160,USDUR=20,P=0,D=.1,P0=.001,D0=0,CAP=150,B=20,N=10,CA=40,SLOW=30")

&&	CASE pcCMD=="67" && EBR Basic : CFa-D + neg-CFa-P con capped, D=.1%, P0=.001, S1 + S2 both flat, S1LIFT=50, ISI=160, GFDMODE5 -> GFDUR=RAND()^2*(1-100), CAP=150
		&& D+P GFDUR=RAND()^2*(1-100) Cap 250
&&		thisform.MEM("MGCFUC=1,MODE=3,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
&&					 "GFDUR=100,GFDMODE=5,ISI=160,USDUR=20,P=2,D=2,P0=0,D0=0,B=20,N=10,CA=80,SLOW=30")


&&	CASE pcCMD=="66" && EBR Basic : CFa-D only, NO P, D=.1%, S1 + S2 both flat, S1LIFT=50, ISI=160, GFDMODE5 -> GFDUR=RAND()^2*(1-100)
		&& Only D, GFDUR=RAND()^2*(1-100)
&&		thisform.MEM("MGCFUC=1,MODE=3,F3_4=0,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
&&					 "GFDUR=100,GFDMODE=5,ISI=160,USDUR=20,P=0,D=.1,P0=0,D0=0,B=20,N=10,CA=40,SLOW=30")
&&	CASE pcCMD=="67" && EBR Basic : CFa-D + neg-CFa-P con, D=.1%, P0=.01, S1 + S2 both flat, S1LIFT=50, ISI=160, GFDMODE5 -> GFDUR=RAND()^2*(1-100)
		&& D+P GFDUR=RAND()^2*(1-100)
&&		thisform.MEM("MGCFUC=1,MODE=3,F3_4=7,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
&&					 "GFDUR=100,GFDMODE=5,ISI=160,USDUR=20,P=0,D=.1,P0=.01,D0=0,B=20,N=10,CA=40,SLOW=30")

&&	CASE pcCMD=="67" && EBR Basic : CFa-D + neg-CFa-P con, D=.1%, P0=.01, S1 + S2 both flat, S1LIFT=50,  ISI=160, GFDMODE5-> GFDUR=RAND()^2*(1-100), GFTRIG=10
		&& D+P GFDUR=RAND()^2*(1-100) Cap 150 GFTRIG 10
&&		thisform.MEM("MGCFUC=1,MODE=3,F3_4=8,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=100,GFDMODE=5,GFTRIG=10,GFTMODE=3,ISI=160,USDUR=20,P=0,D=.1,P0=.01,D0=0,CAP=150,SLOW=30")

&&	CASE pcCMD=="68" && EBR Basic : CFa-D + neg-CFa-P con, D=.1%, P0=.01, S1 + S2 both flat, S1LIFT=50,  ISI=160, GFDMODE5-> GFDUR=RAND()^2*(1-250), GFTRIG=10
		&& D+P GFDUR=RAND()^2*(1-250) NoCap
&&		thisform.MEM("MGCFUC=1,MODE=3,F3_4=7,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
					 "GFDUR=250,GFDMODE=5,GFTRIG=1,GFTMODE=1,ISI=160,USDUR=20,P=0,D=.1,P0=.01,D0=0,B=20,N=10,CA=40,SLOW=30")

&&	CASE pcCMD=="67" && EBR Basic : CFa-D only, NO P, D=.1%, S1 + S2 both flat, S1LIFT=50, ISI=160, GFDMODE5-> GFDUR=RAND()^2*(1-100), GFTRIG=10
&&		thisform.MEM("MGCFUC=1,MODE=3,F3_4=0,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,CWA=1,"+;
&&					 "GFDUR=100,GFDMODE=5,GFTRIG=10,GFTMODE=3,ISI=160,USDUR=20,P=0,D=.1,P0=0,D0=0,B=20,N=10,CA=40,SLOW=30")


&&	CASE pcCMD=="63" && EBR na-P% + na-D% : P 0%, D 0%, P0=D0=2, S1 flat, S2 US, S1LIFT=50,  GFDUR=20, ISI=120
	&& Formula of M&M with always D (na-D% instead of CFa-D)
&&		thisform.MEM("MGCFUC=1,MODE=3,F3_4=1,F3_5=2,F3_6=0,F3_7=0,S1=2,S2=5,S1LIFT=50,S4START=0,"+;
&&					 "ISI=120,USDUR=20,P=0,D=0,P0=2,D0=2,B=20,N=10,CA=40")
	&& Trough stabilized S4>S3
	CASE pcCMD=="64" && EBR neg-CFa-P + na-D% : P 2%, D 0%, P0=D0=2, S1 flat, S2 US, S1LIFT=50,  GFDUR=20, ISI=120 !!!!!!!!!!!!!!!!!!!
	&& Formula of M&M with always D (na-D% instead of CFa-D), with S4 starting at 150 to show that na-D and na-P (outside the US) tend to an equilibrium
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=0,F3_5=2,F3_6=1,F3_7=0,S1=2,S2=5,S1LIFT=50,S4START=150,"+;
					 "GFDUR=20,GFDMODE=1,ISI=120,USDUR=20,P=2,D=2,P0=2,D0=2,B=20,N=10,CA=40")

	CASE pcCMD=="65" && EBR neg-CFa-P + na-D% : P 0%, D 0%, P0=D0=2, S1 flat, S2 US, S1LIFT=50,  GFDMODE=3 (RAND(1-ISI), ISI=120
	&& Formula of M&M with always D (na-D% instead of CFa-D), with S4 starting at 150 to show that na-D and na-P (outside the US) tend to an equilibrium
		thisform.MEM("MGCFUC=1,MODE=3,F3_4=5,F3_5=2,F3_6=0,F3_7=0,S1=5,S2=2,S1LIFT=20,S4START=0,"+;
					 "GFDUR=20,GFDMODE=3,ISI=120,USDUR=20,P=0,D=0,P0=2,D0=2,B=20,N=10,CA=40")

	&& ?? Mode 4
&&	CASE pcCMD=="65" && EBR neg-CFa-P + na-D% : P 2%, D 0%, P0=D0=2, S1 flat, S2 US,   GFDUR=20, ISI=120
&&	&& Formula of M&M with always D (na-D% instead of CFa-D), with S4 starting at 150 to show that na-D and na-P (outside the US) tend to an equilibrium
&&		thisform.MEM("MGCFUC=1,MODE=4,F3_4=0,F3_5=2,F3_6=1,F3_7=0,S1=2,S2=5,S4START=0,"+;
&&					 "GFDUR=20,GFDMODE=1,ISI=120,USDUR=20,P=2,D=2,P0=2,D0=2,B=20,N=10,CA=40")

	&& Mode 5 Var 1 Two S5s (T and L)
&&	CASE pcCMD=="67" && EBR Basic : CFa-D + neg-CFa-P con capped, D=.1%, P0 .001, S1 + S2 both flat, S1LIFT=50,  ISI=160, GFDDUR=100, GFDMODE=1, CAP=250
		&& D+P GrCs 100 Cap 250
&&		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=1,F3_4=8,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=5,S1LIFT=0,S4START=0,CWA=1,"+;
&&					 "GFDUR=20,GFDMODE=1,ISI=240,USDUR=20,P=0,D=.1,P0=.001,D0=0,CAP=250,B=20,N=10,CA=40,SLOW=30")
	CASE pcCMD=="67" && EBR ISI=220 variant 1 (T-alone, L-alone) full height
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=1,ISI=220")
	CASE pcCMD=="68" && EBR ISI=220 variant 2 (T-alone, L-alone) half height
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=2,ISI=220")
	CASE pcCMD=="69" && EBR ISI=220 variant 3 (T-alone, T+L, L-alone) SLOW MOTION FOR FIRST LOOP
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=3,ISI=220")
&&	CASE pcCMD=="70" && EBR ISI=220 variant 4 (T-alone, T+L, L-alone)
&&		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=4,F3_4=8,F3_5=0,F3_6=0,F3_7=1,S1=2,S2=5,S4START=0,"+;
&&					 "GFDUR=20,GFDMODE=5,ISI=240,USDUR=20,P=0,D=.1,P0=.001,D0=0,B=20,N=10,CA=40")
	CASE pcCMD=="71" && EBR ISI=220 variant 5 (T-alone, T+L, L-alone) to be adapted for smaller peaks and added vertical (TL)
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=5,ISI=220")
	CASE pcCMD=="72" && EBR ISI=220 variant 6 (T-alone, T+L, L-alone) to be adapted for smaller peaks and added vertical (L)
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=6,ISI=220")
	CASE pcCMD=="73" && EBR ISI=220 variant 7 (T-alone, T+L, L-alone) to be adapted for smaller peaks and added vertical (T)
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=7,ISI=220")
	&& Idem WITH Kehoe's diagram overlaid
	CASE pcCMD=="77" && EBR ISI=220 variant 5 (T-alone, T+L, L-alone) to be adapted for smaller peaks and added vertical (TL)
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=5,ISI=220,DISPLAY='D'")
	CASE pcCMD=="78" && EBR ISI=220 variant 6 (T-alone, T+L, L-alone) to be adapted for smaller peaks and added vertical (L)
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=6,ISI=220,DISPLAY='D'")
	CASE pcCMD=="79" && EBR ISI=220 variant 7 (T-alone, T+L, L-alone) to be adapted for smaller peaks and added vertical (T)
		thisform.MEM("MGCFUC=1,MODE=5,VARIANT=7,ISI=220,DISPLAY='D'")

	CASE pcCMD=="27" && na-P capped, S1 inverted, S2 flat
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=2,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=2,S4START=5,P=0,D=0,P0=.1,D0=.1")
	CASE pcCMD=="28" && neg-BSa-P, S1 flat, S2 flat
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=2,F3_6=0,F3_7=1,S1=2,S2=2,S4START=5,P=2,D=0")
	CASE pcCMD=="29" && neg-BSa-P, S1 inverted, S2 flat
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=2,F3_6=0,F3_7=1,S1=3,S2=2,S4START=5,P=2,D=0")
	CASE pcCMD=="30" && neg-BSa-P, S1 inverted, S2 inverted
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=2,F3_6=0,F3_7=1,S1=3,S2=3,S4START=5,P=2,D=0")
	CASE pcCMD=="71" && neg-BSa-P, BSa-D, S1 inverted, S2 inverted
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=4,F3_6=1,F3_7=1,S1=3,S2=3,S4START=5,P=2,D=2")
	CASE pcCMD=="72" && neg-BSa-P, S1 inverted, S2 inverted, ILFMAX=10
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=4,F3_6=0,F3_7=1,S1=3,S2=3,S4START=5,ILFMAX=10,P=2,D=0")
	CASE pcCMD=="73" && neg-BSa-P, BSa-D, S1 inverted, S2 inverted, ILFMAX=10
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=2,F3_6=1,F3_7=1,S1=3,S2=3,S4START=5,ILFMAX=10,P=2,D=2")

	CASE pcCMD=="34" && na-P constant (.01) non-capped, BSa-P 2%, BSa-D 2%, ILFMAX=2, P0=.01,D0=.01, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=1,F3_7=1,S1=3,S2=3,S4START=0,ILFMAX=2,"+;
					 "P=2,D=2,P0=.01,D0=.01,B=20,N=10,CA=40,TIMES=25")

	CASE pcCMD=="74" && na-P = 0.01 non capped, NO BSa-P, BSa-D 2%, S2 flat,   ILFMAX=10, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=2,S4START=0,ILFMAX=10,"+;
					 "P=2,D=2,P0=.01,D0=.01,B=20,N=10,CA=40,TIMES=4")

	CASE pcCMD=="75" && NO na-P, BSa-P 2%, BSa-D 2%, S1 and S2 flat,   ILFMAX=10, CA=40
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=20,S4START=0,ILFMAX=10,"+;
					 "P=2,D=2,P0=0,D0=0,B=20,N=10,CA=40")

	CASE pcCMD=="76" && na-P = 0.1 non capped, NO BSa-P, BSa-D 2%, S2 flat,   ILFMAX=0, CA=40
		&& ILFMAX will be halved at mid-run
		thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=1,S2=2,S4START=0,ILFMAX=0,"+;
					 "P=0,D=2,P0=.1,D0=.1,B=20,N=10,CA=0")

	CASE pcCMD=="29" && S2 flat, 2 wrong adressings - correlated
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=2,S4START=-1,WA=2,CWA=0,P=2,D=2")
	CASE pcCMD=="29" && S2 flat, 2 wrong adressings - correlated P=6 D=2
		thisform.MEM("MGCFUC=1,MODE=1,F3_13=3,S1=1,S2=2,S4START=-1,WA=2,CWA=0,P=6,D=2")
	CASE pcCMD=="30" && S1 and S2 flat, ELL, Syndem, B=20, N=10, P=D=2, S4Start=2
		thisform.MEM("MGCFUC=1,MODE=2,F3_13=4,S1=2,S2=2,S4START=5,ILFMAX=10,B=20,N=10,P=2,D=2")
	CASE pcCMD=="31" && S2 flat, ELL, Syndem, B=20, N=10, P=D=2, S4Start=2
		thisform.MEM("MGCFUC=1,MODE=2,F3_13=4,S1=1,S2=2,S4START=5,ILFMAX=10,B=20,N=10,P=2,D=2")
	CASE pcCMD=="32" && ELL, Syndem, B=20, N=10, P=D=2, S4Start=2
		thisform.MEM("MGCFUC=1,MODE=2,F3_13=4,S1=1,S2=1,S4START=5,ILFMAX=10,B=20,N=10,P=2,D=2")
	CASE pcCMD=="33" && ELL, Syndem, S1 and S2 inverted, B=20, N=10, P=D=2, S4Start=2
		thisform.MEM("MGCFUC=1,MODE=2,F3_13=4,S1=3,S2=3,S4START=5,ILFMAX=10,B=20,N=10,P=2,D=2")
	
	&& PuC simulation !
	CASE pcCMD=="80" && NO na-P, BSa-P 2%, BSa-D 2%,   ILFMAX=1, CA=42
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=1,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=42")
	CASE pcCMD=="81" && NO na-P, BSa-P 2%, BSa-D 2%, S2 flat,   ILFMAX=1, CA=21
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=2,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=21")
	CASE pcCMD=="82" && NO na-P, BSa-P 2%, BSa-D 2%, S2 flat,   ILFMAX=1, CA=11
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=2,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=11")
	CASE pcCMD=="83" && NO na-P, BSa-P 2%, BSa-D 2%, S2 flat,   ILFMAX=1, CA=31
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=1,S2=2,S4START=0,"+;
					 "P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=31")

	CASE pcCMD=="84" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=0,S4START=0,"+;
					 "ISI=110,USDUR=20,USFORCE=75,GFDUR=1,P=2,D=2,P0=0,D0=0,IBCM=1,CWA=1,B=0,N=0,CA=75,SLOW=30,DISPLAY='f'")

	CASE pcCMD=="85" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=0,S4START=0,"+;
					 "ISI=110,USDUR=20,USFORCE=75,GFDUR=1,P=2,D=2,P0=0,D0=0,IBCM=1,CWA=1,B=0,N=0,CA=45,SLOW=30,DISPLAY='f'")
	CASE pcCMD=="86" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=0,S4START=0,"+;
					 "ISI=110,USDUR=20,USFORCE=45,GFDUR=1,P=2,D=2,P0=0,D0=0,IBCM=1,CWA=1,B=0,N=0,CA=75,SLOW=30,DISPLAY='f'")
	CASE pcCMD=="87" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=0,"+;
					 "ISI=110,USDUR=20,USFORCE=75,GFDUR=1,P=2,D=2,P0=0,D0=0,IBCM=1,CWA=1,B=0,N=0,CA=75,SLOW=30,DISPLAY='f'")

	CASE pcCMD=="88" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=0,S4START=0,"+;
					 "ISI=110,USDUR=20,USFORCE=150,GFDUR=20,GFTMODE=1,P=2,D=2,P0=0,D0=0,IBCM=1,CWA=1,B=0,N=0,CA=75,SLOW=30,DISPLAY='f'")
	CASE pcCMD=="89" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=0,S4START=0,"+;
					 "ISI=110,USDUR=20,USFORCE=150,GFDUR=60,GFTMODE=1,P=2,D=2,P0=0,D0=0,IBCM=1,CWA=1,B=0,N=0,CA=75,SLOW=30,DISPLAY='f'")
	CASE pcCMD=="90" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=0,S4START=0,"+;
					 "ISI=110,USDUR=20,USFORCE=150,GFDUR=60,GFDMODE=5,GFTMODE=1,P=2,D=2,P0=0,D0=0,IBCM=1,CWA=1,B=0,N=0,CA=75,SLOW=30,DISPLAY='f'")

&&	CASE pcCMD=="84" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110
&&		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=2,S2=2,S1LIFT=50,S4START=-1,"+;
&&					 "ISI=110,USDUR=20,GFDUR=20,P=2,D=2,P0=0,D0=0,CWA=1,B=0,N=0,CA=45,SLOW=30")

	CASE pcCMD=="85" && NO na-P, BSa-P 2%, BSa-D 2%, S1 predefined for US, S2 flat,   ILFMAX=1, CA=45, ISI=110, GFDUR=20
		thisform.MEM("MGCFUC=1,MODE=6,F3_4=0,F3_5=0,F3_6=1,F3_7=1,S1=5,S2=2,S4START=0,"+;
					 "GFDUR=20,GFDMODE=6,ISI=110,USDUR=20,P=2,D=2,P0=0,D0=0,IBCM=1,B=0,N=0,CA=45")

	ENDCASE
	oDashBoard.SP5_3.Value=VAL(pcCMD)
	oDashBoard.DASHBOARDCOHERENCE
	IF NOT lDemo
		thisform.EXECUTE
	ENDIF
	RETURN
	
	PROCEDURE EXECUTE(nTimes,	nX)
	nTimes=MAX(1,MEM.TIMES)
	IF plCMD
		DO CASE
		CASE VAL(pcCMD)=75
			FOR nX=1 TO 5
				IF nX=2 && na-P = 0.01 non capped, NO BSa-P, BSa-D 2%, S1LIFT=40, S2LIFT=40, ILFMAX=10, CA=40
					thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=2,S1LIFT=0,S4START=0,"+;
					 "P=2,D=2,P0=.01,D0=.01,CAP=0,B=20,N=10,CA=40")
					thisform.MAKE_S1("SIMCOR1")
				ENDIF
				IF NOT thisform.SCREENSHOW(nX) && When not yet present in SCREENMEM the command is executed fast
						thisform.CB6_5
						thisform.SCREENMEM(nX)
				ENDIF
				IF plReport
					thisform.SCREENGET(nX)
				ENDIF
			ENDFOR
		OTHERWISE
			FOR nX=1 TO nTimes
				IF NOT thisform.SCREENSHOW(nX) && When not yet present in SCREENMEM the command is executed fast
						thisform.CB6_5
						thisform.SCREENMEM(nX)
				ENDIF
				IF plReport
					thisform.SCREENGET(nX)
				ENDIF
			ENDFOR
		ENDCASE
	ELSE
		DO CASE
		CASE VAL(pcCMD)=4
&&			FOR nX=1 TO nTimes
				thisform.CB6_3
&&			ENDFOR
&&		CASE VAL(pcCMD)=67 && formerly also for 4
&&			FOR nX=1 TO nTimes
&&				thisform.CB6_3
&&			ENDFOR
			thisform.SCREENMEM(1)
		CASE VAL(pcCMD)=75
			FOR nX=1 TO 5
				IF nX=2 && na-P = 0.01 non capped, NO BSa-P, BSa-D 2%, S1LIFT=40, S2LIFT=40, ILFMAX=10, CA=40
					thisform.MEM("MGCFUC=1,MODE=2,F3_4=3,F3_5=0,F3_6=0,F3_7=1,S1=3,S2=2,S1LIFT=0,S4START=0,"+;
					 "P=2,D=2,P0=.01,D0=.01,CAP=0,B=20,N=10,CA=40")
					thisform.MAKE_S1("SIMCOR1")
				ENDIF
				IF nX=1
					thisform.CB6_4
				ELSE
					thisform.CB6_5
				ENDIF
				thisform.SCREENMEM(nX)
			ENDFOR
		CASE VAL(pcCMD)>4
			FOR nX=1 TO nTimes
				IF nTimes<3
					thisform.CB6_4
				ELSE
					thisform.CB6_5
				ENDIF
				thisform.SCREENMEM(nX)
			ENDFOR
		ENDCASE
	ENDIF
	thisform.SCREENCAPT
	RETURN

	PROCEDURE SCREENGET(nX,	cX,cF,cGdiPlus,nDim)
	cX=LTRIM(STR(nX))
	cF="C:\"+CURDIR()+"PICTURES\DEMO SNAPS\Demo"+pcCMD+cX+".JPG"
	cGdiPlus=thisform.GETSPECIAL(38)+'\microsoft visual foxpro 9\ffc\_gdiplus.vcx'
	LOCAL loImage AS GpImage of ffc/_gdiplus.vcx
	DO C:\VFP9\_GDIPLUS\system.app
	loImage = _SCREEN.System.Drawing.Bitmap.FromScreen(thisform.HWnd)
	IF .T.
		loImage.Save(cF, _SCREEN.System.Drawing.Imaging.ImageFormat.JPEG)
	ELSE && adjust the size
		nDim=400
		LOCAL loBitmap AS GpBitmap of ffc/_gdiplus.vcx
		loBitmap = NEWOBJECT('GpBitmap', cGdiPlus)
		LOCAL loGraphics as GpGraphics of ffc/_gdiplus.vcx
		loGraphics = NEWOBJECT('GpGraphics',cGdiPlus)
	
		loBitmap.Create(nDim,nDim) && new width & height
		loGraphics.CreateFromImage(loBitmap)
		loGraphics.DrawImageScaled(loImage, 0, 0, nDim, nDim)
		loBitmap.SaveToFile(cF, 'image/jpeg')
	ENDIF
	RETURN

	PROCEDURE EB_AUTOSIZE(cTxt,cEBname,  nH,nHLine,nSumH,nAT,nATBL,nATCR,cWord,cLine,nRec)
	cMemTxt=cTxt
	&& This routine makes use of the AutoSize function of a label-object
	&& to implement an 'AutoSize' of an editbox-object
	&& while getting around the 255-char-limit of the label-object.

	&& The label is for use 'in the background',
	&& and therefore we don't want it to be visible.
	&& However, it MUST be made visible for it's AutoSize method to work !
	&& (and putting it 'outside the screen' disables AutoSize too !)
	&& This 'fraction-of-a-second visibility' should normally go unnoticed,
	&& but to avoid an eventual flicker we will use lockscreen.
	thisform.LockScreen=.T.
	thisform.HLTXT.Visible=.T.

	&& Setting the stage
	thisform.HLTXT.FontName=thisform.&cEBname..FontName && Must be the same
	thisform.HLTXT.FontSize=thisform.&cEBname..FontSize && Must be the same
	thisform.HLTXT.WordWrap=.T. && WordWrap MUST of course be enabled
	thisform.&cEBName..ScrollBars=0 && We will have no need for them in the editbox
	
	&& We establish the height of one line of text in the actual font and fontsize
	thisform.HLTXT.Caption='O'
	nH=thisform.HLTXT.Height
	&& nH = the height of the label containing one line of text.
	&& To get the height necessary for a line of text INSIDE the label
	&& we subtract the borderwidths.
	nHLine=nH-2

	&& Now we will establish the height necessary for a multiline text
	&& that wordwraps and might contain carriage returns/linefeeds (CR/LF).
	&& Let's however get rid of the LF's-CHR(10), but keep the CR's-CHR(13)
	&& (for practical reasons : trailing blank/CR can both be processed as one char)
	cTxt=CHRTRAN(cTxt,CHR(10),'')

	nSumH=2 && Startvalue = borderwidths 
	cLine='' && Initialize empty line
	
&&	cY=''
	DO WHILE NOT EMPTY(cTxt) && cTxt will be processed word by word
		&& Get the leading word in the text
		nATBL=AT(' ',cTxt) && First occurrence of a blank
		nATCR=AT(CHR(13),cTxt) && First occurrence of a CR
		&& We take the smallest value (avoiding zero when blank or CR not present)
		nAT=MIN(IIF(nATBL>0,nATBL,9999),IIF(nATCR>0,nATCR,9999))
		&& Extract the leading word + the eventual blank or CR at it's end
		cWord=LEFT(cTxt,nAT) &&+IIF(nATBL+nATCR=0,' ','')
		
		&& If a CR happens to be appended to the word,
		&& then get rid of it to process only the word
		&& (which might provoke a wordwrap by itself).
		&& In the next loop the CR will be processed for itself
		&& to provoke an additional CR (and therefore line) in the label.
		&& If you don't want these CR's then feed a string to the routine
		&& in which they are replaced by blanks.
		IF cWord#CHR(13) && Not when the CR itself is being processed
			cWord=CHRTRAN(cWord,CHR(13),'')
		ENDIF
		cLine=cLine+cWord && builds a line of words
&&		cY=cY+STR(nSumH)+cLine+CHR(13)
		&& Let AutoSize decide whether the LABELheight is to be adjusted for this line
		&& (does it wordwrap or contain a CR ?) or not.
		&& Toggling AutoSize and resetting LABELwidth=EDITBOXwidth each time is crucial !
		&& (boggles me but that's the way it is ...)
		thisform.HLTXT.AutoSize=.F.
		thisform.HLTXT.Width=thisform.&cEBname..Width-17
		&& -10 because WordWrap apparently is triggered a wee bit easier in an editbox
		&& than in a label, which in the end might lead to an extra line outside view.
		&& -10 is a safety margin against that happening. Adjust if necessary.
		thisform.HLTXT.Caption=cLine
		thisform.HLTXT.AutoSize=.T.
		&& The LABELheight will now be adjusted to allow for two lines
		&& if a wordwrap or CR occurred, otherwise it will remain unchanged.
			
		&& If the LABELheight was adjusted then add 'one lineheight' to the sum
		IF thisform.HLTXT.Height>nH
		
			nSumH=nSumH+nHLine
			&& reinitialize the line and loop to process the rest of the text.
			&& In doing so we will avoid hitting the 255-char-barrier.
			cLine=''
&&			LOOP
		ENDIF
		&& Amputate the leading word (+ eventual blank) or the CR.
		cTxt=SUBSTR(cTxt,LEN(cWord)+1) && the remaining text
	ENDDO
	&& One 'lineheight' remains to be added
	&& (assuming you fed a text that didn't end with a CR).
	nSumH=nSumH+nHLine*2 && and for safety a margin with a second line

	&& Apply the height to the editbox, mask the label, unlock the screen.
	cMemTxt=LTRIM(cMemTxt)
	thisform.&cEBname..Value=UPPER(LEFT(cMemTxt,1))+SUBSTR(cMemTxt,2)
	thisform.&cEBname..Height=MIN(pnH-thisform.&cEBname..Top,nSumH)
	thisform.&cEBname..Height=MIN(thisform.nH-thisform.&cEBname..Top,nSumH)
	IF '3'$cEBname
		thisform.&cEBname..ScrollBars=2
	ENDIF
	thisform.HLTXT.Visible=.F.
	thisform.LockScreen=.F.
	RETURN
	
	PROCEDURE MEM(cList,	cAlias,nC,nX,cName,cValue,nValue,cX,nO,cField,cObj,nValue1,nValue2)
	&& cList can contain object names or field names : obj=val or field=val
	&& val is then put in the table MEM
	&& and LBPCAPTION is adjusted
	cAlias=ALIAS()
	&& First check whether the chosen options entail dashboard adjustments
	pcSpecs=cList
	cList=cList+','+oDashBoard.DASHBOARDCOHERENCE()
	IF NOT cList=','
		cList=','+cList
	ENDIF
	nC=OCCURS(',',cList)-1
	cList=STRTRAN(cList,',,',',')
	cObj=''
	FOR nX=1 TO nC
		cName=STREXTRACT(cList,',','=',nX)
		IF EMPTY(cName)
			EXIT
		ENDIF
		cValue=STREXTRACT(cList,'=',',',nX)
		nValue1=VAL(cValue)
		cValue=CHRTRAN(cValue,'.',',')
		nValue2=VAL(cValue)
		nValue=MAX(nValue1,nValue2)
		&& little trick to catch an inconsistent and incomprehensible result of VAL :
		&& gives 0,1 one time - correct - (when using the dashboard) but then 0 when called from a demo for VAL("0,1")
&&		IF cName='P0' OR cName="SP4_3"
&&			WAIT WINDOW cValue+STR(ASC(SUBSTR(cValue,1,1)))+STR(ASC(SUBSTR(cValue,2,1)))+STR(ASC(SUBSTR(cValue,3,1)))+STR(nValue,5,1)+STR(SET("Decimals"))+SET("Point")
&&		ENDIF	
		&& Is cName an object name ?
		IF UPPER(cName)="DISP"
		ENDIF
		cX=LEFT(pcObjects,AT(','+cName+',',pcObjects))
		nO=OCCURS(',',cX)
		IF nO>0 && Yes !
			thisform.INFO((cName),nValue)
			cField=STREXTRACT(pcFields,',',',',nO)
		ELSE && No !
			cField=cName
			&& We still look for the object name
			&& because with demos the entered field values must be shown in the dashboard, since they also end up in LBP.Caption
			cX=LEFT(pcFields,AT(','+cName+',',pcFields)+1)
			nO=OCCURS(',',cX)
			cObj=STREXTRACT(pcObjects,',',',',nO)
			DO CASE
			CASE cObj="SP" OR cObj="OP"
				oDashBoard.&cObj..Value=nValue
				IF cObj="SP"
					oDashBoard.&cObj..DISPLAYONCB
				ENDIF
			CASE cObj="TX"
				oDashBoard.&cObj..Value=CHRTRAN(cValue,"'",'')
			ENDCASE
		ENDIF
		&& Save in the table
		SELECT MEM
		GO pnValueSet
&&		IF cObj="SP"
&&			cObj=STRTRAN(cObj,"SP","CB")
&&			IF NOT oDashBoard.&cObj..Enabled
&&				LOOP
&&			ENDIF
&&		ENDIF
		IF VARTYPE(&cField)="N"
			REPLACE &cField WITH nValue
		ELSE
			REPLACE &cField WITH CHRTRAN(cValue,"'",'')
		ENDIF
	ENDFOR
	oDashBoard.MEMGET
	oDashBoard.DASHBOARDCOHERENCE && because new values in MEM require adjustments in the dashboard
	thisform.LBPCAPTION
	IF NOT EMPTY(cAlias)
		SELECT (cAlias)
	ENDIF
	RETURN
	
	PROCEDURE LBPCAPTION(cAlias,nF,cLBP,nX,cX,nO,cO,cC,cCMem,nCMem,cShowIf,cSI)
	cAlias=ALIAS()
	SELECT MEM
	GO pnValueSet
	cFields=",MODE,VARIANT,F3_13,F3_4,F3_5,F3_6,F3_7,IBCM,S1,S2,S1JIT,S2JIT,S1LIFT,S2LIFT,ISI,USDUR,USFORCE,S4START,AUTOLIFT,ILFMAX,"+;
			"P,D,CAP,CWA,WA,GFDUR,GFDMODE,GFTRIG,GFTMODE,PEN,CA,B,N,DEMO,"
	cShowIf=",0   ,0      ,0    ,+   ,+   ,+   ,+   ,1   ,1 ,1 ,0    ,0    ,+     ,+     ,0  ,0    ,0      ,+      ,-       ,1     ,"+;
			"0,0,0  ,0  ,0 ,1    ,0      ,1     ,1      ,0  ,0 ,+,+,-   ,"
	&& 0 = not shown when 0 ; 1 = not shown when 1 ; + = always shown ; - = never shown
	cLBP='DECORRELATING ALGORITHM'+IIF(TYPE("pcCMD")='C',' DEMO '+pcCMD,'')
	IF MEM.MODE=5
		cLBP='KEHOE DEPICTION GAUSSIANS'+IIF(TYPE("pcCMD")='C',' DEMO '+pcCMD,'')
		DO CASE
		CASE MEM.VARIANT=1
			cLBP=cLBP+CHR(13)+'T and L CRs after non-simultaneous training'
		CASE MEM.VARIANT=2
			cLBP=cLBP+CHR(13)+'T and L CRs after simultaneous compound training'
		CASE MEM.VARIANT=3
			cLBP=cLBP+CHR(13)+'T and L CRs after serial compound training'
		CASE MEM.VARIANT=5
			cLBP=cLBP+CHR(13)+'Testing of T->L after serial compound training'
		CASE MEM.VARIANT=6
			cLBP=cLBP+CHR(13)+'Testing of L only after serial compound training'
		CASE MEM.VARIANT=7
			cLBP=cLBP+CHR(13)+'Testing of T only after serial compound training'
		ENDCASE
	ENDIF
	cCMem=''
	FOR nX=1 TO OCCURS(',',cFields)-1
		cX=STREXTRACT(cFields,',',',',nX)
		nO=OCCURS(',',LEFT(pcFields,AT(','+cX+',',pcFields)))
		cO=STREXTRACT(pcObjects,',',',',nO)
		cO=STRTRAN(cO,"SP","CB")
		IF NOT oDashBoard.&cO..Enabled
			LOOP
		ENDIF
		cC=oDashBoard.&cO..Caption
		IF cC="N-t"
			cC="N-threshold = 10"
		ENDIF
		IF "stimulus"$cC
			cLBP=STRTRAN(cLBP,"signal","signal at"+SUBSTR(cC,AT("=",cC)+1))
&&			LOOP
		ENDIF
		IF MEM.MODE=1 AND MEM.F3_13<3 AND "%"$cC && in case of SUM+AVG or AVG derived
			cC=LEFT(cC,5)+LTRIM(STR(IIF(cC="P",pnPv,pnDv),5,1))
			IF MEM.F3_13=1 OR plCMD
				LOOP
			ENDIF
		ENDIF
		IF INLIST(MEM.MODE,1,3,4,5) AND "-t"$cC && no thresholds when not ELL && 7?
			LOOP
		ENDIF
		IF INLIST(MEM.MODE,2,3,4,5,6,7) AND ("% ="$cC OR "capping"$cC) && do not show separate P,D,Cap values when ELL or EBR && 7?
			LOOP
		ENDIF
		IF INLIST(MEM.MODE,5) AND ("S4"$cC OR "GrC"$cC) && Alles is 'depicted' in EBR Kehoe
			LOOP
		ENDIF
		IF cC="Lift S1"
			cCMem=cC
			LOOP
		ENDIF
		IF cC="NO"
			LOOP
		ENDIF
		IF "iBCM"$cC AND "iBCM"$cCMem
			LOOP
		ENDIF
		IF cC="Lift S2" AND cCMem="Lift S1"
			nCMem=VAL(SUBSTR(cC,AT("=",cC)+2))+VAL(SUBSTR(cCMem,AT("=",cCMem)+2))
			IF nCMem+pnLiftS1+pnLiftS2>0
				cC="Excitatory lift added to S3 = "+LTRIM(STR(nCMem+ROUND(pnLiftS1,0)+ROUND(pnLiftS2,0)))+IIF(MEM.AUTOLIFT=1," (autolifted)",'')
				cLBP=cLBP+CHR(13)+cC
			ELSE
				IF pnLift>0
					cC="Excitatory lift added to S3 = "+LTRIM(STR(nCMem+ROUND(pnLift,0)))+IIF(MEM.AUTOLIFT=1," (autolifted)",'')
					cLBP=cLBP+CHR(13)+cC
				ENDIF
			ENDIF
			LOOP
		ENDIF
		IF "GFD ="$cC OR "GFT ="$cC
			LOOP
		ENDIF
		IF (cC="B-t" OR cC="Ca-t") AND pnBShift>0
			cC=cC+'+'+LTRIM(STR(pnBShift,6,2))
		ENDIF
		cSI=STREXTRACT(cShowIf,',',',',nX)
		IF cSI='-'
			cCMem=''
			LOOP
		ENDIF
		IF NOT 48+&cX=ASC(cSI)
			cC=CHRTRAN(cC,CHR(13),' ')
			cLBP=cLBP+ IIF(("na-"$cC AND "na-"$cCMem);
						OR ("Variant"$cC AND "simul"$cCMem);
						OR ("US"$cC AND "US"$cCMem);
						OR ("Sa-"$cC AND "Sa-"$cCMem);
						OR ("Fa-"$cC AND "Fa-"$cCMem);
						OR ("S2"$cC AND "S1"$cCMem);
						OR ("D%"$cC AND "P%"$cCMem);
						OR ("N-t"$cC AND "B-t"$cCMem),;
													IIF(LEN(cCMem+cC)>40,CHR(13),'   '),CHR(13))+cC
			cLBP=STRTRAN(cLBP,"wrong addressings","wrong addressing(s) for each right one")
			cLBP=STRTRAN(cLBP,"US-",'')
			cLBP=STRTRAN(cLBP,"US dur","dur")
&&			cLBP=STRTRAN(cLBP,"GFD","GrC firing duration")
&&			cLBP=STRTRAN(cLBP,"GFT","GrC firing episodes")
			cCMem=cC
		ELSE
			cCMem=''
		ENDIF
	ENDFOR

	cLBP=cLBP+IIF(INLIST(MEM.MODE,3,4,5),'',CHR(13)+IIF(pnDivMax>1,"FIT-height reduced by factor "+LTRIM(STR(pnDivMax))+" .",''))
	nO=OCCURS(CHR(13),cLBP)
&&	cLBP=cLBP+REPLICATE(CHR(13),MAX(0,11-nO))+"Click to interrupt / RightClick to stop"
	cLBP=cLBP+REPLICATE(CHR(13),MAX(1,10-nO))+"Click to interrupt / RightClick to stop"
	thisform.LBP.Value=cLBP
	IF MEM.AUTOLIFT=1
		oDashBoard.LBSIGNALTEXT
	ENDIF
	SELECT (cAlias)
	RETURN
	
	PROCEDURE INFO(cName,nValue,	nButton,cAlias)
	nButton=nValue
	cName=UPPER(cName)
	cSPName=STRTRAN(cName,"CB","SP")
	IF cSPName="SP" AND ','+cSPName+','$pcObjects
		cName=cSPName
		nButton=0
	ENDIF
	cAlias=ALIAS()
	SELECT SCENARIOS
	LOCATE FOR NAME=cName AND BUTTON=nButton
	IF NOT FOUND()
		APPEND BLANK
		REPLACE NAME WITH cName, BUTTON WITH nButton
	ENDIF
	thisform.EB.Refresh
	thisform.EB_AUTOSIZE(thisform.EB.Value,thisform.EB.Name)
	IF NOT EMPTY(cAlias)
		SELECT (cAlias)
	ENDIF
	RETURN
	
	PROCEDURE SCREENMEM(nTimes,	cTimes,cAlias,nX,nY,cY)
	cTimes=STR(nTimes,2)
	cAlias=ALIAS()
	USE SCREENMEM IN SELECT(1)
	SELECT SCREENMEM
	LOCATE FOR SPECS=pcSpecs+cTimes
	IF NOT FOUND()
		FOR nY=1 TO 4
			cY=LTRIM(STR(nY))
			SELECT SIMCOR&cY
			LOCATE FOR S3VAL#0
			IF FOUND() OR (MEM.S1=2 AND MEM.S2=2 AND MEM.S1LIFT+MEM.S2LIFT=0)
				SELECT SCREENMEM
				FOR nX=1 TO pnSteps
					APPEND BLANK
					REPLACE SPECS WITH pcSpecs+cTimes,SIMCOR WITH nY
				ENDFOR
			ENDIF
		ENDFOR
	ENDIF
	SELECT SCREENMEM
	LOCATE FOR SPECS=pcSpecs+cTimes
	FOR nY=1 TO 4
		cY=LTRIM(STR(nY))
		SELECT SIMCOR&cY
		LOCATE FOR S3VAL#0
		IF FOUND() OR (MEM.S1=2 AND MEM.S2=2 AND MEM.S1LIFT+MEM.S2LIFT=0)
			SCAN
				SCATTER MEMVAR
				SELECT SCREENMEM
				GATHER MEMVAR
				SKIP
				SELECT SIMCOR&cY
			ENDSCAN
		ENDIF
	ENDFOR
	SELECT SCREENMEM
	LOCATE FOR SPECS=pcSpecs+cTimes
	REPLACE LFITH25 WITH pnDivMax,BSHIFT WITH pnBShift,LIFT WITH ROUND(pnLiftS1,0)+ROUND(pnLiftS2,0)
&&	SKIP
&&	REPLACE LFITH25 WITH pnDivMax
	USE IN SCREENMEM
	SELECT (cAlias)
	RETURN
	
	PROCEDURE SCREENSHOW(nTimes,	cTimes,cAlias,nLFITH25,nY,cY)
	plScreenShow=.T.
	cTimes=STR(nTimes,2)
	cAlias=ALIAS()
	SELECT SIMCOR1
	GO TOP
	USE SCREENMEM IN SELECT(1)
	SELECT SCREENMEM
	LOCATE FOR SPECS=pcSpecs+cTimes
	pnBShift=BSHIFT
	pnLift=LIFT
	IF NOT FOUND()
		USE IN SCREENMEM
		SELECT (cAlias)
		RETURN(.F.)
	ENDIF
	FOR nY=1 TO 4
		cY=LTRIM(STR(nY))
		SCAN FOR SPECS=pcSpecs+cTimes AND SIMCOR=nY
			SCATTER MEMVAR
			SELECT SIMCOR&cY
			GATHER MEMVAR
			SKIP
			SELECT SCREENMEM
		ENDSCAN
	ENDFOR
	USE IN SCREENMEM
	SELECT SIMCOR1
	CALCULATE MIN(S1VAL),MIN(S2VAL),MIN(S3VAL),MIN(S4VAL),MIN(S5VAL),MAX(LFITH25) TO pnAVMinS1,pnAVMinS2,pnAVMinS3,pnAVMinS4,pnAVMinS5,pnMaxLFITH
	pnLiftM1=pnAVMinS4-pnAVMinS1
	pnLiftM2=pnAVMinS5-pnAVMinS2
	pnLiftM3=pnAVMinS4-pnAVMinS3
	CALCULATE AVG(S1VAL),AVG(S2VAL),AVG(S3VAL),AVG(S4VAL),AVG(S5VAL) TO pnAVG1,pnAVG2,pnAVG3,pnAVG4,pnAVG5
	pnLift1=pnAVG4-pnAVG1
	pnLift2=pnAVG5-pnAVG2
	pnLift3=pnAVG4-pnAVG3
	GO TOP
	pnDivMax=LFITH25
	SKIP
	nLFITH25=LFITH25
	SKIP -1
	REPLACE LFITH25 WITH nLFITH25
	IF pcCMD="4"
		pnIC=1
	ELSE
		pnIC=250*nTimes
	ENDIF
	thisform.DRAWALLLINES
	plScreenShow=.F.
&&&	IF INLIST(MEM.MODE,1,3,4,5)
&&&		thisform.LBS4.Caption=LEFT(thisform.LBS4.Caption,RAT(CHR(13),thisform.LBS4.Caption))+"Iterations : "+STR(pnIC,4)
&&&	ENDIF
	thisform.LBMGC.Caption=LEFT(thisform.LBMGC.Caption,RAT(CHR(13),thisform.LBMGC.Caption))+"Iterations : "+STR(pnIC,4)+STR(pnBShift,6,2)
	IF INLIST(MEM.MODE,3,4,5,7)
		thisform.FIT1.Caption="Iterations : "+STR(pnIC,4)
	ELSE
		thisform.FIT1.Caption="Iterations : "+STR(pnIC,4)+IIF(NOT 'f'$MEM.DISPLAY,"     "+"Fit S2-S5 : "+LTRIM(STR(LFITH25,6,2)),'')
	ENDIF
	thisform.LBPCAPTION
	SELECT (cAlias)
	WAIT '' TIMEOUT 1
	DELETE FILE MYLOG.LOG
&&	thisform.SCREENCAPT
	RETURN(.T.)
	
ENDDEFINE

DEFINE CLASS L AS LINE
	Height		= 1
	Width		= 0
	Visible		= .T.
	Top			= -10
	
	PROCEDURE Init(nL)
	this.Left=nL
	DO CASE
	CASE .T.
	CASE INLIST(this.Name,"LR14","LR41")
		this.BorderColor=pnCyaan
	CASE INLIST(this.Name,"L1","L4","L6")
		this.BorderColor=pnLichtRood
	CASE INLIST(this.Name,"LR25","LR52")
		this.BorderColor=pnRood
	CASE INLIST(this.Name,"L2","L5","L3")
		this.BorderColor=pnCyaan
	CASE INLIST(this.Name,"LFIT25","L8")
		this.BorderColor=pnGeel
	ENDCASE
	RETURN
	
	PROCEDURE Click
	thisform.INFO(this.Class,0)
	RETURN
	
ENDDEFINE

DEFINE CLASS L1 AS L
ENDDEFINE

DEFINE CLASS L2 AS L
ENDDEFINE

DEFINE CLASS L3 AS L
ENDDEFINE

DEFINE CLASS L4 AS L
ENDDEFINE

DEFINE CLASS L5 AS L
ENDDEFINE

DEFINE CLASS L6 AS L
ENDDEFINE

DEFINE CLASS L7 AS L
ENDDEFINE

DEFINE CLASS L8 AS L
ENDDEFINE

DEFINE CLASS LR14 AS L
ENDDEFINE

DEFINE CLASS LR41 AS L
ENDDEFINE

DEFINE CLASS LR25 AS L
ENDDEFINE

DEFINE CLASS LR52 AS L
ENDDEFINE

DEFINE CLASS LR36 AS L
ENDDEFINE

DEFINE CLASS LR63 AS L
ENDDEFINE

DEFINE CLASS LFIT AS L1
ENDDEFINE

DEFINE CLASS LTA AS LT
ENDDEFINE

DEFINE CLASS LTL AS LABEL
	Height		= 10
	Width		= 12
	FontBold	= .T.
	FontSize	= 6
	Left		= 5
	Visible		= .T.
	Alignment	= 2
	
ENDDEFINE

DEFINE CLASS LT AS LINE
	Width		= 270
	Left		= pnLeft1-10
	Height		= 0
	Visible		= .T.
	
	PROCEDURE Init
	DO CASE
	CASE this.Name="LTC"
		this.BorderColor=pnWit
	CASE this.Name="LTB"
		this.BorderColor=pnDonkerRood
	CASE this.Name="LTN"
		this.BorderColor=pnBlauw
	CASE this.Name="LTA"
		this.BorderColor=pnZwart
	ENDCASE
	DO CASE
	CASE VAL(SUBSTR(this.Name,4))>3
		this.Left=pnLeft2-10
	ENDCASE
	RETURN

ENDDEFINE

DEFINE CLASS CB AS COMMANDBUTTON
ENDDEFINE

DEFINE CLASS LB AS LABEL
	Width		= pnSteps
	Height		= 12
	Alignment	= 2
	WordWrap	= .T.
	FontSize	= 7
	FontBold	= .T.
	BackColor	= pnLichtGrijs
	
ENDDEFINE

DEFINE CLASS LBE AS LABEL
	Width		= 80
	Height		= 40 &&24
	Alignment	= 2
	WordWrap	= .T.
	FontSize	= 7
	FontBold	= .T.
	BackColor	= pnLichtGrijs
	
	PROCEDURE Init
	DO CASE
	CASE this.Caption="MG1C"
		this.Left=pnLeft1+pnSteps+25-this.Width/2
	CASE this.Caption="FuC"
		this.Left=pnLeft3+pnSteps+25-this.Width/2
		this.Left=thisform.nW/2+30+pnSteps+25-this.Width/2
	OTHERWISE
		this.Left=pnLeft1-30
	ENDCASE
	RETURN
	
ENDDEFINE

DEFINE CLASS DASHBOARD AS BASEFORM
	ControlBox		= .F.
	ShowTips		= .T.	
	lDashBoard		= .F.
	

	ADD OBJECT LB12 AS LBDB WITH Caption="Signals"
	ADD OBJECT LB3 AS LBDB WITH Caption="Formula"
	ADD OBJECT LB4 AS LBDB WITH Caption="Settings"
	ADD OBJECT LB5 AS LBDB WITH Caption="Mode"
	ADD OBJECT LB6 AS LBDB WITH Caption="Execution"
	ADD OBJECT LB9 AS LBDB WITH Caption="Dummy"

	ADD OBJECT CB1_1 AS CBDB && S1
	ADD OBJECT SP1_1 AS SPDB
	ADD OBJECT OP1_2 AS OBDB WITH Caption="S1 with jitter"
	ADD OBJECT CB1_3 AS CBDB && Lift S1
	ADD OBJECT SP1_3 AS SPDB
	ADD OBJECT CB1_8 AS CBDB && Start S4
	ADD OBJECT SP1_8 AS SPDB

	ADD OBJECT CB2_1 AS CBDB && S2
	ADD OBJECT SP2_1 AS SPDB
	ADD OBJECT OP2_2 AS OBDB WITH Caption="S2 with jitter"
	ADD OBJECT CB2_3 AS CBDB && Lift S2
	ADD OBJECT SP2_3 AS SPDB
	ADD OBJECT CB2_4 AS CBDB && ISI (US beginning at ...)
	ADD OBJECT SP2_4 AS SPDB
	ADD OBJECT CB2_5 AS CBDB && USDUR
	ADD OBJECT SP2_5 AS SPDB
	ADD OBJECT CB2_6 AS CBDB && USFORCE (EXCESS)
	ADD OBJECT SP2_6 AS SPDB
	ADD OBJECT OP2_7 AS OBDB WITH Caption="Set autolift on"
	ADD OBJECT CB2_8 AS CBDB && ILFMAX
	ADD OBJECT SP2_8 AS SPDB

	ADD OBJECT CB3_1 AS CBDB && Basic Formulae
	ADD OBJECT SP3_1 AS SPDB
 	&& ELL Formulae
	ADD OBJECT CB3_4 AS CBDB && na-P
	ADD OBJECT SP3_4 AS SPDB 
	ADD OBJECT CB3_5 AS CBDB && na-D
	ADD OBJECT SP3_5 AS SPDB
	ADD OBJECT CB3_6 AS CBDB && BSa-P
	ADD OBJECT SP3_6 AS SPDB
	ADD OBJECT CB3_7 AS CBDB && BSa-D
	ADD OBJECT SP3_7 AS SPDB
	ADD OBJECT CB3_8 AS CBDB
	ADD OBJECT SP3_8 AS SPDB && IBCM
	ADD OBJECT CB3_9 AS CBDB
	ADD OBJECT SP3_9 AS SPDB && CAP

	ADD OBJECT CB4_1 AS CBDB && P
	ADD OBJECT SP4_1 AS SPDB
	ADD OBJECT CB4_2 AS CBDB && D
	ADD OBJECT SP4_2 AS SPDB
	ADD OBJECT CB4_3 AS CBDB && na-P
	ADD OBJECT SP4_3 AS SPDB
	ADD OBJECT CB4_4 AS CBDB && na-D
	ADD OBJECT SP4_4 AS SPDB
	ADD OBJECT OP4_5 AS OBDB WITH Caption="Correlated"+CHR(13)+"addressings"
	ADD OBJECT CB4_6 AS CBDB
	ADD OBJECT SP4_6 AS SPDB && WA
	ADD OBJECT CB4_7 AS CBDB
	ADD OBJECT SP4_7 AS SPDB && GFDUR
	ADD OBJECT CB4_8 AS CBDB
	ADD OBJECT SP4_8 AS SPDB && GFDMODE
	ADD OBJECT CB4_9 AS CBDB
	ADD OBJECT SP4_9 AS SPDB && GFTRIGGER

	ADD OBJECT CB5_1 AS CBDB && MODE
	ADD OBJECT SP5_1 AS SPDB
	ADD OBJECT CB5_2 AS CBDB && VARIANT
	ADD OBJECT SP5_2 AS SPDB
	ADD OBJECT CB5_3 AS CBDB && DEMO
	ADD OBJECT SP5_3 AS SPDB
	ADD OBJECT OP5_4 AS OBDB WITH Caption="Let PEN adjust B and Ca"
	ADD OBJECT CB5_5 AS CBDB && Ca
	ADD OBJECT SP5_5 AS SPDB
	ADD OBJECT CB5_6 AS CBDB && B
	ADD OBJECT SP5_6 AS SPDB
	ADD OBJECT CB5_7 AS CBDB && N
	ADD OBJECT SP5_7 AS SPDB
	ADD OBJECT CB5_8 AS CBDB && Value Set
	ADD OBJECT SP5_8 AS SPDB
	ADD OBJECT CB5_9 AS CBDB
	ADD OBJECT SP5_9 AS SPDB && GFTMODE

	ADD OBJECT CB6_1 AS CBDB WITH Caption="Execute one step"
	ADD OBJECT CB6_2 AS CBDB WITH Caption="Execute one loop"
	ADD OBJECT CB6_3 AS CBDB WITH Caption="Execute one loop +"
	ADD OBJECT CB6_4 AS CBDB WITH Caption="Execute "+LTRIM(STR(pnSteps))+" loops"
	ADD OBJECT CB6_5 AS CBDB WITH Caption=thisform.CB6_4.Caption+" +"
	ADD OBJECT CB6_6 AS CBDB WITH Caption="Reset"
	ADD OBJECT CB6_7 AS CBDB WITH Caption="Hide dashboard"
	ADD OBJECT CB6_8 AS CBDB WITH Caption="Close Program"
	ADD OBJECT TX6_9 AS TEXTBOX
	
	PROCEDURE Init
	NODEFAULT
	RETURN

	PROCEDURE Activate(nX,cX)
	IF thisform.lDashBoard=.T.
		IF NOT INLIST(thisform.BackColor,pnLichtBlauw,pnLichtGeel)
			thisform.SetAll("BackColor",pnLichtBlauw)
			thisform.BackColor=pnLichtBlauw
			thisform.SP5_8.Value=1
		ENDIF
		RETURN
	ENDIF
	thisform.lDashBoard=.T.

	thisform.LB12.Width=2*thisform.LB9.Width

	thisform.Left=oDecorrelator.Width/2
	thisform.Width=oDecorrelator.Width/2-7
	thisform.Top=oDecorrelator.Height*1/3
	thisform.Height=oDecorrelator.Height*2/3

	pnWDB=thisform.Width
	thisform.LB12.Width=pnWDB/3
	FOR nX=3 TO 9
		cX=LTRIM(STR(nX))
		IF VARTYPE(thisform.LB&cX)='O'
			thisform.LB&cX..Width=pnWDB/6
			thisform.LB&cX..Left=(nX-1)*pnWDB/6
		ENDIF
	ENDFOR
	
	thisform.LAYOUTGR("OP1_2")
	thisform.LAYOUT("CB1")
	thisform.LAYOUT("SP1")

	thisform.LAYOUTGR("OP2_2")
	thisform.LAYOUT("CB2")
	thisform.LAYOUT("SP2")
	thisform.LAYOUTGR("OP2_7")

	thisform.LAYOUT("CB3")
	thisform.LAYOUT("SP3")
	
	thisform.LAYOUT("CB4")
	thisform.LAYOUT("SP4")
	thisform.LAYOUTGR("OP4_5")

	thisform.LAYOUTGR("OP5_4")
	thisform.LAYOUT("CB5")
	thisform.LAYOUT("SP5")

	thisform.LAYOUT("CB6")
	thisform.LAYOUT("TX6")

	thisform.MEMGET
	oDecorrelator.MEM('')
&&	   thisform.DIMS('form')
&&	   thisform.REDIMS(.T.)
	RETURN
	
	PROCEDURE MEMGET(cAlias,nO,nX,cObj,cField,nV)
	cAlias=ALIAS()
	SELECT MEM
	GO pnValueSet
	nO=OCCURS(',',pcObjects)
	FOR nX=1 TO nO-1
		cObj=STREXTRACT(pcObjects,',',',',nX)
		cField=STREXTRACT(pcFields,',',',',nX)
		nV=&cField
		IF NOT thisform.&cObj..Enabled
			thisform.&cObj..Value=0
		ENDIF
		IF cObj="SP"
			IF BETWEEN(nV,thisform.&cObj..SpinnerLowValue,thisform.&cObj..SpinnerHighValue)
				thisform.&cObj..Value=nV
			ELSE
				thisform.&cObj..Value=ABS(thisform.&cObj..SpinnerLowValue)
				REPLACE &cField WITH thisform.&cObj..Value
			ENDIF
			thisform.&cObj..DISPLAYONCB
		ELSE
			thisform.&cObj..Value=nV
		ENDIF
	ENDFOR
	SELECT (cAlias)
	RETURN
	
	PROCEDURE MGCFUC
	oDecorrelator.LBFUC.Visible=(pnValueSet=2)
	oDecorrelator.EB.Visible=(pnValueSet=1)
	RETURN
	
	PROCEDURE LAYOUT(cO,	nH,nW,nX,cX,nL,nF)
&&	nH=thisform.LB9.Height
	nH=(thisform.Height-thisform.LB9.Height)/9
	nW=pnWDB/6
	FOR nX=1 TO 9
		cX=LTRIM(STR(nX))
		IF VARTYPE(thisform.&cO._&cX)='O'
			nL=VAL(SUBSTR(cO,3,1))
			nF=IIF(nL=3 AND nX=1,3,1)
			thisform.&cO._&cX..Width=nW
			thisform.&cO._&cX..Left=(nL-1)*nW
			thisform.&cO._&cX..Top=thisform.LB9.Height+(nX-1)*nH
			thisform.&cO._&cX..Height=nH*nF
			IF cO="SP"
				thisform.&cO._&cX..DISPLAYONCB && GitHub version: instead of .MouseUp (= DISPLAYONCB + DASHBOARDCOHERENCE), faster start
			ENDIF
		ENDIF
	ENDFOR
	RETURN
	
	PROCEDURE LAYOUTGR(cO,	nH,nL,nT,nF,nW,nX)
&&	nH=thisform.LB9.Height
	nH=(thisform.Height-thisform.LB9.Height)/9
	nL=VAL(SUBSTR(cO,3,1))
	nT=VAL(SUBSTR(cO,5,1))
	nF=VAL(SUBSTR(cO,6,1))
	nW=pnWDB/6
	thisform.&cO..Width=nW
	thisform.&cO..Left=(nL-1)*nW
	thisform.&cO..Top=thisform.LB9.Height+(nT-1)*nH
	thisform.&cO..Height=MAX(1,nF)*nH
	FOR nX=1 TO nF
		thisform.&cO..Buttons(nX).Width=nW
		thisform.&cO..Buttons(nX).Top=thisform.LB9.Height+(nX-1)*nH
		thisform.&cO..Buttons(nX).Height=nH
		thisform.&cO..Buttons(nX).FontSize=7
		thisform.&cO..Buttons(nX).FontBold=.T.
		thisform.&cO..Buttons(nX).WordWrap=.T.
	ENDFOR
	RETURN

	PROCEDURE DASHBOARDCOHERENCE(lMode,	lC1,lC2,lC3,cAddtoList,nX,cX,nY)
	cAddToList=''
	
	lC1=(thisform.SP5_1.Value=1)
	lC2=(thisform.SP5_1.Value=2)
	lC3=(INLIST(thisform.SP5_1.Value,3,4,5,6,7))
&&	lC4=lC3 OR (thisform.SP5_1.Value=4)

	thisform.SP2_4.Enabled=lC3 && ISI
	thisform.CB2_4.Enabled=lC3
	thisform.SP2_5.Enabled=lC3 && USDUR
	thisform.CB2_5.Enabled=lC3
	thisform.SP2_6.Enabled=lC3 && USFORCE
	thisform.CB2_6.Enabled=lC3
	thisform.OP2_7.Enabled=lC2
	thisform.SP3_1.Enabled=lC1 && Formula
	thisform.CB3_1.Enabled=lC1
	thisform.SP3_4.Enabled=NOT lC1 && na-P modes
	thisform.CB3_4.Enabled=NOT lC1
	thisform.SP3_5.Enabled=lC3 && na-D modes
	thisform.CB3_5.Enabled=lC3
	thisform.SP3_6.Enabled=NOT lC1 && BSaP/CFaP modes
	thisform.CB3_6.Enabled=NOT lC1
	thisform.SP3_7.Enabled=NOT lC1 && BSaD/CFaD modes
	thisform.CB3_7.Enabled=NOT lC1
	thisform.SP3_8.Enabled=NOT lC1 && IBCM setting
	thisform.CB3_8.Enabled=NOT lC1 
	thisform.SP3_9.Enabled=NOT lC1 && Cap setting
	thisform.CB3_9.Enabled=NOT lC1 

	thisform.SP4_3.Enabled=NOT lC1 && na-P value
	thisform.CB4_3.Enabled=NOT lC1
	thisform.SP4_4.Enabled=NOT lC1 && na-D value
	thisform.CB4_4.Enabled=NOT lC1
	thisform.SP4_7.Enabled=lC3 && GFDUR
	thisform.CB4_7.Enabled=lC3
	thisform.SP4_8.Enabled=lC3 && GFDMODE
	thisform.CB4_8.Enabled=lC3 AND thisform.SP2_5.Value>0
	thisform.SP4_9.Enabled=lC3 && GFTRIGGER
	thisform.CB4_9.Enabled=lC3
	thisform.SP5_9.Enabled=lC3 && GFTMODE
	thisform.CB5_9.Enabled=lC3 AND thisform.SP2_5.Value>0

	thisform.OP5_4.Enabled=lC2 && PEN adjust
&&	thisform.SP5_5.Enabled=lC2 && Ca value
&&	thisform.CB5_5.Enabled=lC2
	thisform.SP5_6.Enabled=lC2 && B value
	thisform.CB5_6.Enabled=lC2
	thisform.SP5_7.Enabled=lC2 && N value
	thisform.CB5_7.Enabled=lC2
	
	thisform.CB6_1.Enabled=lC1 && one step
&&	thisform.CB6_2.Enabled=lC1

	IF NOT lMode AND MEM.MODE>0 AND thisform.SP5_1.Value#MEM.MODE
&&		thisform.LBSIGNALTEXT
		oDecorrelator.RESET
	ENDIF

	thisform.PNTOP
	thisform.LBSIGNALTEXT
	RETURN(cAddToList)

	PROCEDURE PNTOP
	&& pnTop1 stands for S1 etc
	pnTop1=1*pnHI
	pnTop2=2*pnHI
	pnTop3=3*pnHI
	IF thisform.SP5_3.Value=51
		pnTop3=3*pnHI+30
	ENDIF
	pnTop4=1*pnHI
	pnTop5=2*pnHI
	pnTop6=3*pnHI
	pnTop7=4*pnHI
	pnTop8=5*pnHI
	IF .F.&&MEM.MODE=3
		pnTop3=3*pnHI
		pnTop4=3*pnHI
	ENDIF
	IF  .F. &&MEM.MODE=4
		pnTop2=1*pnHI
		pnTop3=4*pnHI
		pnTop4=1*pnHI
		pnTop5=2*pnHI
	ENDIF
	oDecorrelator.LB01.Top=pnTop4-5
	oDecorrelator.LB011.Top=pnTop4-10
	oDecorrelator.LB02.Top=pnTop5-5
	oDecorrelator.LB022.Top=pnTop5-10
	oDecorrelator.TRIAL.Top=pnTop3
&&	oDashBoard.LBSIGNALTEXT
	RETURN	

	PROCEDURE LBSIGNALTEXT(lC,lC2,cC1a,cC1b,cC2a,cC2b,cC3,cC1ib,nLift1,nLift2)
	&& CAPTION
	LBS(1,1)="S1 : Same signal repeated for every iteration"+CHR(13)+"Modulation of S4 projected over S1"
	LBS(1,2)="S2 : Random signal different for every iteration"+CHR(13)+"Modulation of S5 projected over S2"
	LBS(1,3)="S3 : The sum of S1 and S2, will serve as input"+CHR(13)+"250 timeslices"
	LBS(1,4)="S4 : Time-correlated component filtered out of S3"+CHR(13)+"Modulation of S1 projected over S4" &&+CHR(13)+"Iterations :   0"
	LBS(1,5)="S5 : Time-uncorrelated component (S3-S4+constant)"+CHR(13)+"Modulation of S2 projected over S5"
	
	cC1a=ICASE(MEM.S1=2,"flat",MEM.S1=3,"inverted CC of the DS (iCC)",MEM.S1=4,"antiphased CC of the DS (iCC)","CC of the DS")
	cC1b=ICASE(MEM.S1=2,"flat",MEM.S1>2,"iCC","CC")
	cC2a=ICASE(MEM.S2=2,"flat",MEM.S2=3,"inverted UC of the DS (iUC)",MEM.S2=4,"antiphased UC of the DS (iUC)","UC of the DS")
	cC2b=ICASE(MEM.S2=2,"flat",MEM.S2>2,"iUC","UC")

	nLift1=IIF(MEM.VARIANT=>10,ROUND(pnLiftS1,0)+MEM.S1LIFT,MEM.S1LIFT)
	nLift2=IIF(MEM.VARIANT=>10,ROUND(pnLiftS2,0)+MEM.S2LIFT,MEM.S2LIFT)
&&	LBS(2,1)="S1 : "+cC1a+IIF(MEM.''," + excitatory lift of "+LTRIM(STR(MEM.S1LIFT)))
&&	LBS(2,2)="S2 : "+cC2a+IIF(MEM.''," + excitatory lift of "+LTRIM(STR(MEM.S2LIFT)))
	LBS(2,1)="S1 : "+cC1a+IIF(nLift1=0,''," + excitatory lift of "+LTRIM(STR(nLift1)))
	LBS(2,2)="S2 : "+cC2a+IIF(nLift2=0,''," + excitatory lift of "+LTRIM(STR(nLift2)))

	cC3=ICASE(cC1b="flat",cC2b,cC2b="flat",cC1b,'i'$cC1b+cC2b,"iDS","DS")
	cC1ib=STRTRAN("i"+cC1b,"ii",'')
	cC1ib=STRTRAN(cC1ib,"iflat","flat")
&&	LBS(2,3)="S3 : "+cC1b+" + "+cC2b+" = "+cC3+CHR(13)+"Summed basilar output"+;
&&		IIF(MEM.S1LIFT+MEM.''," + excitatory lift of "+LTRIM(STR(MEM.S1LIFT+MEM.S2LIFT)))
	LBS(2,3)="S3 : "+cC1b+" + "+cC2b+" = "+cC3+CHR(13)+"Summed basilar output"+;
		IIF(nLift1+nLift2=0,''," + excitatory lift of "+LTRIM(STR(nLift1+nLift2)))
	LBS(2,3)=STRTRAN(LBS(2,3),"flat + flat = ",'')

	LBS(2,4)="S4 : SUM(ApO) evolving to "+cC1ib &&+" (+ a constant)"
	LBS(2,5)="S5 : SUM(ApO) + "+cC3+" evolving to "+cC2b+CHR(13)+"("+cC1ib+" + "+cC3+" = "+cC2b+" when successful)"+;
			  IIF(NOT cC2b="flat",CHR(13)+"SUM(ApO) annulling the "+cC1b+" in the "+cC3,'')
	LBS(2,5)=STRTRAN(LBS(2,5),CHR(13)+"(flat + flat = flat)",'')

	LBS(6,1)="S1 : "+cC1a+IIF(nLift1=0,''," + excitatory lift of "+LTRIM(STR(nLift1)))
	LBS(6,2)="S2 : "+cC2a+IIF(nLift2=0,''," + excitatory lift of "+LTRIM(STR(nLift2)))
	LBS(6,3)="S3 : "+cC1b+" + "+cC2b+" = "+cC3+CHR(13)+"CC + UC = DS (AF input)"+;
		IIF(nLift1+nLift2=0,''," + excitatory lift of "+LTRIM(STR(nLift1+nLift2)))
	LBS(6,3)=STRTRAN(LBS(6,3),"flat + flat = ",'')

	LBS(6,4)="S4 : ILF*aSS evolving to "+cC1ib &&+" (+ a constant)"
	LBS(6,5)="S5 : ILF*aSS + "+cC3+" evolving to "+cC2b+CHR(13)+"("+cC1ib+" + "+cC3+" = "+cC2b+" when successful)"+;
			  IIF(NOT cC2b="flat",CHR(13)+"ILF*aSS annulling the "+cC1b+" in the "+cC3,'')
	LBS(6,5)=STRTRAN(LBS(6,5),CHR(13)+"(flat + flat = flat)",'')

	IF MEM.S1=5
	LBS(6,1)="S1 : DS = CS signal with added US surge"
	LBS(6,2)="S2 : "+cC2a+IIF(nLift2=0,''," + excitatory lift of "+LTRIM(STR(nLift2)))
	LBS(6,3)="S3 = S1"
	LBS(6,4)="S4 : negative image of the DS when successful"
	LBS(6,5)="S5 : PuC activity profile when successful"
	ENDIF
	
	LBS(3,3)="(S3) CS-Tone signal + US signal"
	LBS(3,6)="(S4) SUM(ApO) / PuC activity"

	LBS(4,1)="(S3) CS-tone signal"
	LBS(4,2)="(S3) CS-light signal"
	LBS(4,4)="(S4) PuC reaction on CS-tone"
	LBS(4,8)="(S4) PuC reaction on CS-light"
	
	LBS(5,4)="NI output based on"+CHR(13)+"PuC population sensitive to tone only"+IIF(MEM.VARIANT=>3,CHR(13)+"PEAK 1",'')
	LBS(5,6)="NI output based on"+CHR(13)+"PuC population sensitive to both tone and light"+IIF(MEM.VARIANT=>3,CHR(13)+"PEAK 2 and PEAK 3",'')
	LBS(5,8)="NI output based on"+CHR(13)+"PuC population sensitive to light only"+IIF(MEM.VARIANT=>3,CHR(13)+"PEAK 4",'')
	
	LBS(7,1)="S1"
	LBS(7,2)="S2"
	LBS(7,3)="S1 + S2"
	LBS(7,4)="-S1 = S2 - (S1 + S2) , delivered by the PuC as S1"
	LBS(7,5)="-S2 = S1 - (S1 + S2) , delivered by the PuC as S2"
	LBS(7,6)="- (S1 + S2)"

	lC=(thisform.SP5_1.Value=2)
	FOR nX=1 TO 8
		cX=LTRIM(STR(nX))
		oDecorrelator.LBS&cX..Caption=LBS(thisform.SP5_1.Value,nX)
		oDecorrelator.LBS&cX..Height=12*(OCCURS(CHR(13),oDecorrelator.LBS&cX..Caption)+1)
	ENDFOR
	IF MEM.S2=6
		FOR nX=1 TO 6
			cX=LTRIM(STR(nX))
			oDecorrelator.LBS&cX..Caption=LBS(7,nX)
			oDecorrelator.LBS&cX..Height=12*(OCCURS(CHR(13),oDecorrelator.LBS&cX..Caption)+1)
		ENDFOR
	ENDIF
	&& POSITION
	LBS(8,1)=pnTop1+2
	LBS(8,2)=pnTop2+2
	LBS(8,3)=pnTop3+2
	LBS(8,4)=pnTop4+2
	LBS(8,5)=pnTop5+2
	LBS(8,6)=pnTop6+2
	LBS(8,7)=pnTop7+2
	LBS(8,8)=pnTop8+2

	FOR nX=1 TO 8
		cX=LTRIM(STR(nX))
		oDecorrelator.LBS&cX..Top=LBS(8,nX)
		LBS(9,nX)=0
	ENDFOR

	lC2=(INLIST(thisform.SP5_1.Value,2,6)) && ELL simulation OR PuC simulation
	oDecorrelator.SetAll("Top",-10,"LT")
	oDecorrelator.SetAll("Top",-10,"LTL")
&&	WAIT STR(thisform.LTB3.Top) WINDOW
	FOR nX=1 TO 8
		cX=LTRIM(STR(nX))
		nY=pnTop&cX
		IF nX=3 OR nX=5
			oDecorrelator.LTC&cX..Top=IIF(lC2,nY-thisform.SP5_5.Value-1,-10)
			oDecorrelator.LTCL&cX..Top=IIF(lC2,nY-thisform.SP5_5.Value-5,-10)
			oDecorrelator.LTCL&cX..Caption='Ca'
			oDecorrelator.LTCL&cX..Visible= ( thisform.SP5_5.Value>0 )
			IF nX=5
				oDecorrelator.LTCL&cX..Left=pnLeft2-27
			ENDIF
		ENDIF
		IF nX=3
			IF thisform.SP5_1.Value=2
				oDecorrelator.LTB&cX..Top=IIF(lC2,nY-thisform.SP5_6.Value-1,-10)
				oDecorrelator.LTBL&cX..Top=IIF(lC2,nY-thisform.SP5_6.Value-5,-10)
				oDecorrelator.LTBL&cX..Caption='B'
				oDecorrelator.LTN&cX..Top=IIF(lC2,nY-thisform.SP5_7.Value-1,-10)
				oDecorrelator.LTNL&cX..Top=IIF(lC2,nY-thisform.SP5_7.Value-5,-10)
				oDecorrelator.LTNL&cX..Caption='N'
			ENDIF
		ENDIF
		oDecorrelator.LTA&cX..Top=nY-1
	ENDFOR
&&	oDecorrelator.LTC4.Top=pnTop4-thisform.SP5_5.Value-1
&&	oDecorrelator.LTC5.Top=pnTop5-thisform.SP5_5.Value-1
	pnMaxFit=oDecorrelator.FIT1.Top-oDecorrelator.LBS5.Top-oDecorrelator.LBS5.Height-5
	FOR nX=1 TO pnSteps
		cX=LTRIM(STR(nX))
		oDecorrelator.L6&cX..Left=IIF(INLIST(MEM.MODE,1,2,6),nX+pnLeft1,nX+pnLeft2)
	ENDFOR

	&& VISIBILITY
	oDecorrelator.SetAll("Visible",.F.,"LB")
	oDecorrelator.SetAll("Visible",.F.,"LTA")
	oDecorrelator.S5HALT.Visible=.F.
	IF MEM.S2=6
		FOR nX=1 TO 6
			cX=LTRIM(STR(nX))
			oDecorrelator.LBS&cX..Visible=.T.
			oDecorrelator.LTA&cX..Visible=.T.
		ENDFOR
	ELSE
		FOR nX=1 TO 8
			cX=LTRIM(STR(nX))
			DO CASE
			CASE MEM.S2=6 AND INLIST(nX,7,8)
				LOOP
			CASE INLIST(MEM.MODE,1,2,6,7) AND INLIST(nX,6,7,8)
				LOOP
			CASE INLIST(MEM.MODE,3) AND INLIST(nX,1,2,3,4,5,7,8)
				LOOP
			CASE MEM.MODE=4 AND INLIST(nX,3,6,7,8)
				LOOP
			CASE MEM.MODE=5
				DO CASE
				CASE INLIST(MEM.VARIANT,1,2) AND INLIST(nX,1,2,3,5,6,7)
					LOOP
				CASE INLIST(MEM.VARIANT,3,4,5) AND INLIST(nX,1,2,3,5,7)
					LOOP
				CASE INLIST(MEM.VARIANT,6) AND INLIST(nX,1,2,3,4,5,7)
					LOOP
				CASE INLIST(MEM.VARIANT,7) AND INLIST(nX,1,2,3,5,7,8)
					LOOP
&&				CASE MEM.VARIANT=1 AND INLIST(nX,1,2,3)
&&					LOOP
&&				CASE MEM.VARIANT=1 AND INLIST(nX,1,2,3)
&&					LOOP
				ENDCASE
			ENDCASE
			oDecorrelator.LBS&cX..Visible=.T.
			oDecorrelator.LTA&cX..Visible=.T.
		ENDFOR
	ENDIF
&&	oDecorrelator.LBMGC.Visible=lC

	thisform.US(0,.F.)
	thisform.US(1,.F.)
	thisform.US(2,.F.)
	oDecorrelator.PEAKTL1.Visible=.F.
	oDecorrelator.PEAKTL1.ZOrder(1)
	oDecorrelator.PEAKTL2.Visible=.F.
	oDecorrelator.PEAKTL2.ZOrder(1)
	oDecorrelator.PEAKT.Visible=.F.
	oDecorrelator.PEAKT.ZOrder(1)
	oDecorrelator.PEAKL.Visible=.F.
	oDecorrelator.PEAKL.ZOrder(1)
	oDecorrelator.DIAGRAM.Visible=.F.
	oDecorrelator.OVERLAY.Visible=.F.
&&	IF INLIST(MEM.MODE,3,4,5,6,7)
	oDecorrelator.US2.BorderColor=pnRood
		DO CASE
		CASE .F. &&INLIST(MEM.MODE,4,5) AND MEM.ISI>0 AND MEM.USDUR>0
			oDecorrelator.US1.Visible=.T.
			oDecorrelator.US1.Left=pnLeft2+MEM.ISI+2
			oDecorrelator.US2.Left=pnLeft2+MEM.ISI/2+2
		CASE INLIST(MEM.MODE,3) AND MEM.ISI>0 AND MEM.USDUR>0
			thisform.US(0,.T.,6,30)
			thisform.US(1,.T.,6,45)
			thisform.US(2,.T.,6,45)
		CASE INLIST(MEM.MODE,6,7) AND MEM.ISI>0 AND MEM.USDUR>0
			thisform.US(0,.T.,5,30)
			thisform.US(1,.T.,5,45)
			thisform.US(2,.T.,5,45)
		CASE MEM.MODE=4
			oDecorrelator.US1.Visible=.T.
			oDecorrelator.US1.Left=pnLeft2+MEM.ISI+2
			oDecorrelator.US2.Left=pnLeft2+MEM.ISI/2+2

			oDecorrelator.US1.Height=pnTop6-pnTop4
			oDecorrelator.US1.Top=0
		CASE MEM.MODE=5
			oDecorrelator.US1.Visible=.T.
			IF INLIST(MEM.VARIANT,3)
				oDecorrelator.US1.Visible=.F.
				oDecorrelator.US1.Top=53
				oDecorrelator.US1.Left=pnLeft2+MEM.ISI+2 && +2 because of the thickness of the line
				oDecorrelator.US1.Height=pnTop8-53

				oDecorrelator.US2.Visible=.F.
				oDecorrelator.US2.BorderColor=pnCyaan
				oDecorrelator.US2.Top=53
				oDecorrelator.US2.Left=pnLeft2+MEM.ISI/2+2 && +2 because of the thickness of the line
				oDecorrelator.US2.Height=pnTop8-53
			ENDIF
			IF INLIST(MEM.VARIANT,1,2,5)
				oDecorrelator.US1.Top=53
				oDecorrelator.US1.Left=pnLeft2+MEM.ISI+2 && +2 because of the thickness of the line
				oDecorrelator.US1.Height=pnTop8-53

				oDecorrelator.US2.Visible=.F.
				oDecorrelator.US2.BorderColor=pnCyaan
				oDecorrelator.US2.Top=pnTop4+oDecorrelator.LBS4.Height
				oDecorrelator.US2.Left=pnLeft2+MEM.ISI/2+2 && +2 because of the thickness of the line
				oDecorrelator.US2.Height=pnTop6-pnTop4-oDecorrelator.LBS4.Height

				IF INLIST(MEM.VARIANT,1,2)
					thisform.USEBR(pnTop8-10,pnLeft2+MEM.ISI-oDecorrelator.US1LB.Width/2,-100,-100) &&;
&&								   pnTop8-10,pnLeft2+MEM.ISI/2-oDecorrelator.US0LB.Width/2)
				ENDIF
				IF INLIST(MEM.VARIANT,5)
					oDecorrelator.PEAKTL1.Visible=.T.
					oDecorrelator.PEAKTL1.Top=110
					oDecorrelator.PEAKTL1.Left=pnLeft2+7*MEM.ISI/8-1
					oDecorrelator.PEAKTL1.Height=pnTop8-110

					oDecorrelator.PEAKTL2.Visible=.T.
					oDecorrelator.PEAKTL2.Top=110
					oDecorrelator.PEAKTL2.Left=pnLeft2+7*MEM.ISI/8+1
					oDecorrelator.PEAKTL2.Height=pnTop8-110

					oDecorrelator.DIAGRAM.Left=pnLeft2-60
					oDecorrelator.DIAGRAM.Width=558
					thisform.USEBR(pnTop6-10,pnLeft2+MEM.ISI-oDecorrelator.US1LB.Width/2,;
								   pnTop6-10,pnLeft2+MEM.ISI/2-oDecorrelator.US0LB.Width/2)
				ENDIF

			ENDIF
			IF INLIST(MEM.VARIANT,6)
				oDecorrelator.US1.Top=53
				oDecorrelator.US1.Left=pnLeft2+MEM.ISI/2+2 && +2 because of the thickness of the line
				oDecorrelator.US1.Height=pnTop8-53

&&				oDecorrelator.US2.Height=pnTop8-pnTop4-oDecorrelator.LBS4.Height
&&				oDecorrelator.US2.Top=pnTop4+oDecorrelator.LBS4.Height
				oDecorrelator.PEAKL.Visible=.T.
				oDecorrelator.PEAKL.Top=225
				oDecorrelator.PEAKL.Left=pnLeft2+4*MEM.ISI/6
				oDecorrelator.PEAKL.Height=pnTop8-175

				oDecorrelator.DIAGRAM.Left=pnLeft2-60-MEM.ISI/2
				oDecorrelator.DIAGRAM.Width=558
				thisform.USEBR(pnTop6-10,pnLeft2+MEM.ISI/2-oDecorrelator.US1LB.Width/2,;
							   pnTop6-10,pnLeft2+0-oDecorrelator.US0LB.Width/2)
			ENDIF
&&		ENDCASE
			IF INLIST(MEM.VARIANT,7)
				oDecorrelator.US1.Top=53
				oDecorrelator.US1.Left=pnLeft2+MEM.ISI+2 && +2 because of the thickness of the line
				oDecorrelator.US1.Height=pnTop6-53

				oDecorrelator.PEAKT.Visible=.T.
				oDecorrelator.PEAKT.Top=175
				oDecorrelator.PEAKT.Left=pnLeft2+5*MEM.ISI/6
				oDecorrelator.PEAKT.Height=pnTop6-175
				oDecorrelator.DIAGRAM.Left=pnLeft2-60
				oDecorrelator.DIAGRAM.Width=558
				thisform.USEBR(pnTop6-10,pnLeft2+MEM.ISI-oDecorrelator.US1LB.Width/2,;
							   pnTop6-10,pnLeft2+MEM.ISI/2-oDecorrelator.US0LB.Width/2)
			ENDIF
			IF INLIST(MEM.VARIANT,5,6,7) &&,6,7)
				oDecorrelator.OVERLAY.Visible=.T.
				IF 'D'$MEM.DISPLAY
					oDecorrelator.OVERLAY.Click
&&					plNOCancel=.T.
				ENDIF
				oDecorrelator.DIAGRAM.Top=25
				IF VERSION(2)=0 OR plTESTVERSION0
&&					cDirFile=pcCR_DBaseDir+'I'+PPI+".JPG"
					cDirFile=pcCR_DBaseDir+'I'+"0120403"+".TXT" &&".JPG"
				ELSE
					cDirFile=pcRoot+"\IMAGES\"+'I'+"0120403"+".JPG"
				ENDIF
				IF VARTYPE(oCerebReader)='U'
					oDecorrelator.DIAGRAM.Picture=thisform.GETDIAGRAM("P012-4-3*")
				ELSE
					oDecorrelator.DIAGRAM.Picture=cDirFile &&thisform.GETDIAGRAM("P012-4-3*")
				ENDIF
				oDecorrelator.DIAGRAM.Stretch=2
				oDecorrelator.DIAGRAM.BackStyle=0
				oDecorrelator.DIAGRAM.ZOrder(1)
			ENDIF
			IF INLIST(MEM.VARIANT,4)
				oDecorrelator.US2.Visible=.T.
				oDecorrelator.US2.Height=pnTop6-pnTop4
				oDecorrelator.US2.Top=pnTop4
			ENDIF
			oDecorrelator.LBS4.ZOrder(0)
			oDecorrelator.LBS6.ZOrder(0)
			oDecorrelator.LBS8.ZOrder(0)
		ENDCASE
&&	ENDIF
	IF MEM.AUTOLIFT=1
		oDecorrelator.S5HALT.Visible=.T.
		oDecorrelator.S5HALT.Top=pnTop2-MEM.VARIANT
		oDecorrelator.S5HALT.ZOrder(0)
	ENDIF

	oDecorrelator.CR1.Visible= ( MEM.MODE=4 )
	oDecorrelator.CR2.Visible= ( MEM.MODE=4 )
	oDecorrelator.CR1.ZOrder(1)
	oDecorrelator.CR2.ZOrder(1)
	oDecorrelator.TRIAL.Visible=( MEM.MODE=6 AND MEM.S1=5 )
&&	oDecorrelator.FIT1.Visible=NOT 'f'$MEM.DISPLAY

	&& COLOR
	DO CASE
	CASE MEM.MODE=4
		oDecorrelator.SetAll("BorderColor",pnCyaan,"L5")
	CASE MEM.MODE=5
		oDecorrelator.SetAll("BorderColor",pnLichtRood,"L4")
		oDecorrelator.SetAll("BorderColor",pnLichtRood,"L5")
		oDecorrelator.SetAll("BorderColor",pnCyaan,"L6")
		oDecorrelator.SetAll("BorderColor",pnCyaan,"L7")
	ENDCASE
	RETURN

	PROCEDURE US(nNr,lVis,nL,nTop,cNr,cL)
	cNr=LTRIM(STR(nNr))
	oDecorrelator.US&cNr..Visible=lVis
	IF nNr<2
		oDecorrelator.US&cNr.LB.Visible=lVis
	ENDIF
	IF lVis
		oDecorrelator.US&cNr..Top=nTop
		oDecorrelator.US&cNr..Left=IIF(nL<4,pnLeft1,pnLeft2)+MEM.ISI+IIF(nNr=2,MEM.USDUR,0)-IIF(nNr=0,MEM.GFDUR,0)
		cL=LTRIM(STR(nL))
		oDecorrelator.US&cNr..Height=pnTop&cL-nTop &&IIF(MEM.MODE=3,pnTop7,pnTop6)-pnTop1-45
		oDecorrelator.US&cNr..BorderWidth=1
		oDecorrelator.US&cNr..ZOrder(0)
		IF nNr<2
			oDecorrelator.US&cNr.LB.Top=oDecorrelator.US&cNr..Top-10
			oDecorrelator.US&cNr.LB.Left=oDecorrelator.US&cNr..Left+(IIF(nNr=1,MEM.USDUR,0)-oDecorrelator.US&cNr.LB.Width)/2
			oDecorrelator.US&cNr.LB.Caption="US"+IIF(nNr=0,"-"+LTRIM(STR(MEM.GFDUR)),'')
			oDecorrelator.US&cNr.LB.ZOrder(0)
		ENDIF
	ENDIF
	RETURN
	
	PROCEDURE USEBR(nT1,nL1,nT0,nL0,	lV)
	oDecorrelator.US1LB.Visible=.T.
	oDecorrelator.US1LB.Top=nT1 &&oDecorrelator.US1.Top
	oDecorrelator.US1LB.Left=nL1 &&+(IIF(nNr=1,MEM.USDUR,0)-oDecorrelator.US1.LB.Width)/2
	oDecorrelator.US1LB.Caption="800 ms"
	oDecorrelator.US1LB.ZOrder(0)

	lV=oDecorrelator.US2.Visible
	oDecorrelator.US0LB.Visible=.T.
	oDecorrelator.US0LB.Top=nT1
	oDecorrelator.US0LB.Left=nL0 &&+(IIF(nNr=1,MEM.USDUR,0)-oDecorrelator.US1.LB.Width)/2
	oDecorrelator.US0LB.Caption="400 ms"
	oDecorrelator.US0LB.ZOrder(0)
	RETURN
	
	PROCEDURE MV(cN,nV)
	RETURN(cN+"="+CHRTRAN(LTRIM(STR(nV,5,2)),',','.'))
	
	PROCEDURE GETDIAGRAM(cLI,	cAlias,nRec,cF,cPict)
	cLI='-'+SUBSTR(cLI,2)+'-'
	cAlias=ALIAS()
	IF NOT plCalled
		USE PDFHL1 IN SELECT(1)
	ENDIF
	SELECT PDFHL1
	nRec=RECNO()
	cF=FILTER()
	SET FILTER TO
	SEEK STR(VAL(STREXTRACT(cLI,'-','-',1)),3)+STR(VAL(STREXTRACT(cLI,'-','-',2)),3)+STR(VAL(STREXTRACT(cLI,'-','-',3)),2) ORDER PDFPAGE
	cPict=IIF(FOUND(),RTRIM(PICTURE),'')
	SET FILTER TO &cF
	GO nRec
	IF NOT plCalled
		USE IN PDFHL1
	ENDIF
	SELECT (cAlias)
	RETURN(cPict)
	
ENDDEFINE

DEFINE CLASS LBDB AS COMMANDBUTTON
	Height			= 30
&&	BackColor		= pnDonkerGeel
	TabStop			= .F.
	FontSize		= 9
	FontBold		= .T.
	Themes			= .F.

	PROCEDURE GotFocus
	thisform.LB9.SetFocus
	RETURN
	
ENDDEFINE

DEFINE CLASS OPDB AS OPTIONGROUP

	PROCEDURE Click
	DO CASE
	CASE this.Buttons(this.Value).Caption="Set 1 values"
		thisform.SetAll("BackColor",pnLichtBlauw)
		thisform.BackColor=pnLichtBlauw
		pnValueSet=1
		thisform.MEMGET
		thisform.MGCFUC
	CASE this.Buttons(this.Value).Caption="Set 2 values"
		thisform.SetAll("BackColor",pnLichtGeel)
		thisform.BackColor=pnLichtGeel
		pnValueSet=2
		thisform.MEMGET
		thisform.MGCFUC
	ENDCASE
	oDecorrelator.MEM(thisform.MV(this.Name,this.Value))
	RETURN

ENDDEFINE

DEFINE CLASS OBDB AS OPTIONBUTTON
	FontSize		= 7
	FontBold		= .T.
	WordWrap		= .T.
	
	PROCEDURE Click
	oDecorrelator.MEM(thisform.MV(this.Name,this.Value))
	RETURN

ENDDEFINE

DEFINE CLASS CBDB AS COMMANDBUTTON
	Visible			= .T.
	WordWrap		= .T.
	FontSize		= 7
	FontBold		= .T.
	Themes			= .F.
	
	PROCEDURE Click(cN)
	cN=this.Name
	IF RUNNING_NOW() AND (INLIST(cN,"CB6_1","CB6_2","CB6_3","CB6_4","CB6_5") OR cN="CB5_3") && GitHub version:
		RETURN && no new run (or other demo values) during a run
	ENDIF
	oDecorrelator.INFO((cN),0)
&&		oDecorrelator.PNTOP
&&		oDashBoard.DASHBOARDCOHERENCE && because new values in MEM require adjustments in the dashboard
	IF cN="CB5_1" OR cN="CB6"
&&		oDecorrelator.PNTOP
		oDashBoard.DASHBOARDCOHERENCE && because new values in MEM require adjustments in the dashboard
&&		thisform.LBSIGNALTEXT
	ENDIF
	DO CASE
	CASE cN="CB5_3"
		oDecorrelator.DEMO(.T.,thisform.SP5_3.Value)
	CASE cN="CB6"
		DO CASE
		CASE VAL(SUBSTR(cN,5,1))=7
			thisform.Hide
		CASE VAL(SUBSTR(cN,5,1))=8
			thisform.Release
			oDecorrelator.Release
		OTHERWISE
			IF cN>"CB6_3"
&&				thisform.Hide && GitHub version: the dashboard stays open
			ENDIF
			oDecorrelator.MEM((pcFields)) && Between brackets, otherwise the variable pcFields disappears !!
			oDecorrelator.&cN
		ENDCASE
	ENDCASE
	RETURN
		
ENDDEFINE

DEFINE CLASS SPDB AS SPINNER
	FontSize		= 8
	FontBold		= .T.
	Themes			= .F.
	
	PROCEDURE Init(nL,nT)
	nL=VAL(SUBSTR(this.Name,3))
	nT=VAL(SUBSTR(this.Name,5))
	DO CASE
	CASE nL=1 AND nT=1 && S1
		this.SpinnerLowValue=1
		this.SpinnerHighValue=5
		this.Increment=-1
		this.Value=1
	CASE nL=2 AND nT=1 && S2
		this.SpinnerLowValue=1
		this.SpinnerHighValue=6
		this.Increment=-1
		this.Value=1
	CASE INLIST(nL,1,2) AND nT=3 && S1LIFT, S2LIFT
		this.SpinnerLowValue=0
		this.SpinnerHighValue=200
		this.Increment=1
		this.Value=0
	CASE nL=1 AND nT=8 && S4START
		this.SpinnerLowValue=-1
		this.SpinnerHighValue=200
		this.Increment=1
		this.Value=-1
	CASE nL=2 AND nT=4 && ISI
		this.SpinnerLowValue=0
		this.SpinnerHighValue=250
		this.Increment=10
		this.Value=0
	CASE nL=2 AND nT=5 && USDUR
		this.SpinnerLowValue=0
		this.SpinnerHighValue=20
		this.Increment=1
		this.Value=0
	CASE nL=2 AND nT=6 && USFORCE
		this.SpinnerLowValue=0
		this.SpinnerHighValue=300
		this.Increment=10
		this.Value=0
	CASE nL=2 AND nT=8 && ILFMAX
		this.SpinnerLowValue=0
		this.SpinnerHighValue=10
		this.Increment=1
		this.Value=1
	CASE nL=3 AND nT=1 && Basic Formulae
		this.SpinnerLowValue=1
		this.SpinnerHighValue=3
		this.Increment=-1
		this.Value=1
	CASE nL=3 AND INLIST(nT,4,5,6,7,8) && PD Formulae
		this.SpinnerLowValue=0
		this.SpinnerHighValue=ICASE(nT=4,8,nT=5,8,nT=6,1,nT=7,1,nT=8,1)
		this.Increment=ICASE(nT=5,-2,-1)
		this.Value=0
	CASE nL=3 AND nT=9 && CAP
		this.SpinnerLowValue=-300
		this.SpinnerHighValue=300
		this.Increment=1
		this.Value=0
&&	CASE nL=3 AND INLIST(nT,5,6) && ELL Formulae 5,6 ??????? of 1,2
&&		this.SpinnerLowValue=1
&&		this.SpinnerHighValue=3
&&		this.Increment=-1
&&		this.Value=1
	CASE nL=4 AND INLIST(nT,1,2) && P, D
		this.SpinnerLowValue=-20
		this.SpinnerHighValue=20
		this.Increment=.1
		this.Value=2.0
	CASE nL=4 AND INLIST(nT,3,4) && P0, D0
		this.SpinnerLowValue=-10
		this.SpinnerHighValue=10
		this.Increment=.01
		this.Value=0.000
	CASE nL=4 AND INLIST(nT,6) && WA
		this.SpinnerLowValue=0
		this.SpinnerHighValue=5
		this.Increment=1
		this.Value=0
	CASE nL=4 AND INLIST(nT,7) && GFDUR
		this.SpinnerLowValue=1
		this.SpinnerHighValue=250
		this.Increment=1
		this.Value=0
	CASE nL=4 AND INLIST(nT,8) && GFDMODE
		this.SpinnerLowValue=1
		this.SpinnerHighValue=7
		this.Increment=-1
		this.Value=1
	CASE nL=4 AND INLIST(nT,9) && GFTRIGGER
		this.SpinnerLowValue=1
		this.SpinnerHighValue=250
		this.Increment=1
		this.Value=1
	CASE nL=5 AND nT=1 && MODE
		this.SpinnerLowValue=1
		this.SpinnerHighValue=7
		this.Increment=-1
		this.Value=1
	CASE nL=5 AND nT=2 && VARIANT
		this.SpinnerLowValue=0
		this.SpinnerHighValue=70
		this.Increment=-1
		this.Value=0
	CASE nL=5 AND nT=3 && DEMO
		this.SpinnerLowValue=1
		this.SpinnerHighValue=99
		this.Increment=-1
		this.Value=1
	CASE nL=5 AND INLIST(nT,8) && SETS
		this.SpinnerLowValue=1
		this.SpinnerHighValue=2
		this.Increment=-1
		this.Value=1
	CASE nL=5 AND INLIST(nT,9) && GFTMODE
		this.SpinnerLowValue=0
		this.SpinnerHighValue=3
		this.Increment=-1
		this.Value=1
	ENDCASE
	RETURN
	
	PROCEDURE MouseDown
	LPARAMETERS nButton, nShift, nXCoord, nYCoord, nL,nW
	nL=VAL(SUBSTR(this.Name,3))
	nW=thisform.LB9.Width
	this.Width=nW
	this.Left=(nL-1)*nW
	RETURN
	
	PROCEDURE MouseEnter
	LPARAMETERS nButton, nShift, nXCoord, nYCoord
	this.ToolTipText=STR(this.Value)
	RETURN
	
	PROCEDURE MouseUp
	LPARAMETERS nButton, nShift, nXCoord, nYCoord
	this.DISPLAYONCB
	oDashBoard.DASHBOARDCOHERENCE(.T.)
	RETURN

	PROCEDURE UpClick(cX)
	oDecorrelator.MEM(thisform.MV(this.Name,this.Value))
	cX=STRTRAN(this.Name,"SP","CB")
	thisform.&cX..Click
	thisform.&cX..Click
	this.DISPLAYONCB
	RETURN
		
	PROCEDURE DownClick(cX)
	oDecorrelator.MEM(thisform.MV(this.Name,this.Value))
	cX=STRTRAN(this.Name,"SP","CB")
	thisform.&cX..Click
	thisform.&cX..Click
	this.DISPLAYONCB
	RETURN
	
	PROCEDURE DISPLAYONCB(nL,cL,nT,cT,nW,nV,cnaP,cnaD,cP,cD,cCap)
	nL=VAL(SUBSTR(this.Name,3))
	cL=LTRIM(STR(nL))
	nT=VAL(SUBSTR(this.Name,5))
	cT=LTRIM(STR(nT))

	nW=thisform.LB9.Width
	this.Width=nW/5
	this.Left=nL*nW-this.Width
	thisform.CB&cL._&cT..Width=4*nW/5
	
	DO CASE
	CASE nL=1
		DO CASE
		CASE nT=1
			nV=thisform.SP1_1.Value
			thisform.CB1_1.Caption="S1 "+ICASE(nV=1,"modulated",nV=2,"flat",nV=3,"inverted",nV=4,"antiphased",nV=5,"with US surge at "+LTRIM(STR(thisform.SP2_4.Value)))
		CASE nT=3
			thisform.CB1_3.Caption="Lift S1 = "+LTRIM(STR(thisform.SP1_3.Value))
		CASE nT=8
			IF thisform.SP1_8.Value=-1
				thisform.CB1_8.Caption="Start with S4 = S3"
			ELSE
				thisform.CB1_8.Caption="Start with S4 = "+LTRIM(STR(thisform.SP1_8.Value))
			ENDIF
		ENDCASE
	CASE nL=2
		DO CASE
		CASE nT=1
			nV=thisform.SP2_1.Value
			thisform.CB2_1.Caption="S2 "+ICASE(nV=1,"modulated",nV=2,"flat",nV=3,"inverted",nV=4,"antiphased",;
												nV=5,"predefined for virtual US",nV=6,"modulated but unchanging")
		CASE nT=3
			thisform.CB2_3.Caption="Lift S2 = "+LTRIM(STR(thisform.SP2_3.Value))
		CASE nT=4
			thisform.CB2_4.Caption="US at timeslice "+LTRIM(STR(thisform.SP2_4.Value))
			thisform.CB2_5.Caption="US duration = "+LTRIM(STR(thisform.SP2_5.Value))
			thisform.CB2_6.Caption="US-CF force excess = "+LTRIM(STR(thisform.SP2_6.Value))
		CASE nT=8
			nV=thisform.SP2_8.Value
			IF nV=0
				thisform.CB2_8.Caption="ILF=2 when ic<=125, ILF=1 when ic>125"
			ELSE
				thisform.CB2_8.Caption="Input load factor maximum = "+LTRIM(STR(nV))
			ENDIF
		ENDCASE
	CASE nL=3
		nV=thisform.SP3_1.Value
		thisform.CB3_1.Caption=ICASE(nV=1,"SUM and AVG",nV=2,"AVG derived",nV=3,"P and D in parallel and as set")

		nV=thisform.SP3_4.Value
		cnaP=LTRIM(STR(thisform.SP4_3.Value,6,3))
		nCap=thisform.SP3_9.Value
		IF nCap=>0
			cCap="capped at "+LTRIM(STR(nCap))
		ELSE
			cCap="capped at "+LTRIM(STR(-nCap*2))+CHR(13)+"PuC-capped at "+LTRIM(STR(-nCap))
		ENDIF
		DO CASE
		CASE nV=0
			cV="NO na-P"
		CASE nV=1
			cV="na-P = "+cnaP+"%"+CHR(13)+"non capped"
		CASE nV=2
			cV="na-P = "+cnaP+"%"+CHR(13)+cCap
		CASE nV=3
			cV="na-P = "+cnaP+" constant"+CHR(13)+"non capped"
		CASE nV=4
			cV="na-P = "+cnaP+" constant"+CHR(13)+cCap
		CASE nV=5
			cV="neg-BSa-P = "+cnaP+"%"+CHR(13)+"non capped"
		CASE nV=6
			cV="neg-BSa-P = "+cnaP+"%"+CHR(13)+cCap
		CASE nV=7
			cV="neg-BSa-P = "+cnaP+" constant"+CHR(13)+"non capped"
		CASE nV=8
			cV="neg-BSa-P = "+cnaP+" constant"+CHR(13)+cCap
		ENDCASE
		thisform.CB3_4.Caption=IIF(thisform.SP5_1.Value=>3,STRTRAN(cV,"BS","CF"),cV)
		thisform.CB3_4.FontSize=6

		nV=thisform.SP3_5.Value
		cnaD=LTRIM(STR(thisform.SP4_4.Value,5,2))
&&		cCap=LTRIM(STR(thisform.SP3_9.Value))
		DO CASE
		CASE nV=0
			cV="NO na-D"
		CASE nV=2
			cV="na-D = "+cnaD+"%"
		CASE nV=4
			cV="na-D = "+cnaD+" constant"
		CASE nV=6
			cV="neg-BSa-D = "+cnaD+"%"
		CASE nV=8
			cV="neg-BSa-D = "+cnaD+" constant"
		ENDCASE
		thisform.CB3_5.Caption=IIF(thisform.SP5_1.Value=>3,STRTRAN(cV,"BS","CF"),cV)

		cP=LTRIM(STR(thisform.SP4_1.Value,5,1))
		cD=LTRIM(STR(thisform.SP4_2.Value,5,1))

		nV=thisform.SP3_8.Value
		cD=LTRIM(STR(thisform.SP4_2.Value,5,1))
		DO CASE
		CASE nV=0
			cV="NO iBCM rule"
		CASE nV=1
			cV="WITH iBCM rule" && with"+CHR(13)+"P = "+cP+"%"+" and "+"D = "+cD+"%"
		ENDCASE
		thisform.CB3_8.Caption=cV &&IIF(thisform.SP5_1.Value=>3,STRTRAN(cV,"BS","CF"),cV)
		IF nV=1
			thisform.SP3_6.Value=2
			thisform.SP3_7.Value=2
		ENDIF
	
		nV=thisform.SP3_6.Value
		DO CASE
		CASE nV=0
			cV="NO BSa-P"
		CASE nV=1
			cV="BSa-P = "+cP+"%"
		CASE nV=2
			cV="BSa-P = "+cP+"%"+CHR(13)+"iBCM rule"+CHR(13)+"BSa-D = "+cD+"%"
		ENDCASE
		thisform.CB3_6.Caption=IIF(thisform.SP5_1.Value=>3,STRTRAN(cV,"BS","CF"),cV)

		nV=thisform.SP3_7.Value
		DO CASE
		CASE nV=0
			cV="NO BSa-D"
		CASE nV=1
			cV="BSa-D = "+cD+"%"
		CASE nV=2
			cV="BSa-P = "+cP+"%"+CHR(13)+"iBCM rule"+CHR(13)+"BSa-D = "+cD+"%"
		ENDCASE
		thisform.CB3_7.Caption=IIF(thisform.SP5_1.Value=>3,STRTRAN(cV,"BS","CF"),cV)

	CASE nL=4
		thisform.CB4_1.Caption="P% = "+LTRIM(STR(thisform.SP4_1.Value,4,1))
		thisform.SP3_5.DISPLAYONCB

		thisform.CB4_2.Caption="D% = "+LTRIM(STR(thisform.SP4_2.Value,4,1))
		thisform.SP3_6.DISPLAYONCB

		thisform.CB4_3.Caption="na-P = "+LTRIM(STR(thisform.SP4_3.Value,6,3))
		thisform.SP3_4.DISPLAYONCB

		thisform.CB4_4.Caption="na-D = "+LTRIM(STR(thisform.SP4_4.Value,5,2))
		thisform.SP3_4.DISPLAYONCB

		nCap=thisform.SP3_9.Value
		
		IF nCap=>0
			cCap="Synaps capping at "+LTRIM(STR(nCap))
		ELSE
			cCap="PuC capping at "+LTRIM(STR(-nCap))
		ENDIF
		thisform.CB3_9.Caption=cCap &&,4,1))
		thisform.SP3_4.DISPLAYONCB
		thisform.CB4_6.Caption=LTRIM(STR(thisform.SP4_6.Value))+" wrong addressings"

		cV=LTRIM(STR(thisform.SP4_7.Value))
		thisform.CB4_7.Caption="GFD = "+cV

		nV=thisform.SP4_8.Value
		thisform.CB4_8.Caption="GrC burst duration ="+CHR(13)+ICASE(nV=1,cV,nV=2,"RAND(1-"+cV+")",nV=3,"RAND(1-ISI)",nV=4,"RAND(1-250)",+;
																		nV=5,"RAND^2(1-"+cV+")",nV=6,"RAND^2(1-ISI)",nV=7,"RAND^2(1-250)")+" timeslices"

		cV=LTRIM(STR(thisform.SP4_9.Value))
		thisform.CB4_9.Caption="GFT = "+cV

	CASE nL=5
		DO CASE
		CASE nT=1
			nV=thisform.SP5_1.Value
			thisform.CB5_1.Caption=ICASE(nV=1,"Basic simulation",nV=2,"ELL simulation"+CHR(13)+"(MGC)",;
										 nV=3,"EBR simulation",nV=4,"EBR simulation 2",nV=5,"EBR simulation 3",;
										 nV=6,"PuC simulation",nV=7,"EBR-PUC") &&"EBR simulation 4",nV=7,"EBR simulation 5",nV=8,"EBR simulation 6",nV=9,"PuC simulation")
&&			thisform.SP1_1.Value=ICASE(nV=1,1,nV=2,3,nV=3,2,nV=4,2,nV=>5,2)
&&			thisform.SP2_1.Value=ICASE(nV=1,1,nV=3,5,nV=4,5,nV=>5,5,thisform.SP2_1.Value)
&&			thisform.SP1_3.Value=ICASE(nV=1,0,nV=2,0,nV=3,0,nV=4,0,nV=>5,0)
&&			thisform.SP1_1.DISPLAYONCB
&&			thisform.SP2_1.DISPLAYONCB
&&			thisform.SP1_3.DISPLAYONCB
			thisform.SP3_5.DISPLAYONCB
			thisform.SP3_6.DISPLAYONCB
		CASE nT=2
			nV=thisform.SP5_2.Value
			IF nV=>10
				thisform.CB5_2.Caption="No lift increment when S5 > "+LTRIM(STR(nV))
			ELSE
				thisform.CB5_2.Caption="Variant "+LTRIM(STR(nV))
			ENDIF
		CASE nT=3
			thisform.CB5_3.Caption="Load values of demo "+LTRIM(STR(thisform.SP5_3.Value))
		CASE nT=5
			thisform.CB5_5.Caption="Ca-threshold"+CHR(13)+"= "+LTRIM(STR(thisform.SP5_5.Value))
		CASE nT=6
			thisform.CB5_6.Caption="B-threshold"+CHR(13)+"= "+LTRIM(STR(thisform.SP5_6.Value))
		CASE nT=7
			thisform.CB5_7.Caption="N-threshold"+CHR(13)+"= "+LTRIM(STR(thisform.SP5_7.Value))
		CASE nT=8
			thisform.CB5_8.Caption="Value Set "+LTRIM(STR(thisform.SP5_8.Value))
		CASE nT=9
			cV=LTRIM(STR(thisform.SP4_9.Value))
			nV=thisform.SP5_9.Value
			IF nV=0
				thisform.CB5_9.Caption="GrC bursts cover"+CHR(13)+"all timeslices"
			ELSE
				thisform.CB5_9.Caption="GrCs burst"+CHR(13)+ICASE(nV=1,cV,nV=2,"RAND(1-"+cV+")",nV=3,"RAND^2(1-"+cV+")")+" times/cycle"
			ENDIF
		ENDCASE
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
