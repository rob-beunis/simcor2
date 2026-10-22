&& Source code for Visual Foxpro : adapt it to the language of your choice

&& It is assumed that each timeslice of the A-path is affected by a set of GrCs large enough to contain all input permutations (cfr main text)
&& and that is determined by your choice of dimensionality, number of PPVs on the axes and the eventual added surnumerary dendrites.

&& The program :
&& - generates all possible permutations for a given GrC input situation and lists them
&& - lists the same permutations after an ordering procedure (see there)
&& - counts totals of 'right addressings' (RAs) and 'wrong addressings' (WAs) (always affecting only the A-path itself) and computes the RA ratio %
&& - counts RA and WA totals for specific input permutation 'categories'

&& Important : these calculations presume that an A-path 'uses up' a whole ISU in a systematic manner without intersections with itself.
&& (it will increase the absolute number counts)
&& In vivo and in multi-D ISUs an A-path 'wanders' through the ISU engaging but a portion of its 'nodes' (leaving 'room' for other A-paths)
&& and A-path course and length will determine the WA occurrence.
&& It is nonetheless assumed that the RA ratio will be about the same if the A-path is long enough.
&& GrCs 'belonging' to other A-paths are presumed to stay silent.
&& Remember that the RA-ration by itself may be a 'pessimistic' estimate of network performance
&& since WAs clustered nearby in time to the RA may be considered 'right enough' (the DS not changing much between consecutive A-path steps). 

CLEAR ALL
CLOSE ALL
_SCREEN.Cls

&& Change the presets if you want other values

&& Specify the dimensionality (keep it <= 5)
pnDims=4
IF pnDims>5
	? "Too many dimensions"
	CANCEL
ENDIF

&& Specify the number of PPVs on each axis (if applicable in the chosen dimensionality)
pnPPVa=4 && a-axis
pnPPVb=4 && b-axis
pnPPVc=4 && c-axis
pnPPVd=4 && d-axis
pnPPVe=4 && e-axis

&& Specify the number of surnumerary dendrites (max 2).
pnSurDen=0
IF pnSurDen>2
	? "Too many surnumerary dendrites"
	CANCEL
ENDIF

pnAO=96 && the 'ASCII offset' between 1 and ASC('a')
? "Your inputs : "
? "ISU dimensions : "+LTRIM(STR(pnDims))
FOR nX=1 TO pnDims
	cX=CHR(nX+pnAO)
	? "PPVs on "+cX+"-axis : "+LTRIM(STR(pnPPV&cX))
ENDFOR
? "Added surnumerary dendrites : "+LTRIM(STR(pnSurDen))
WAIT
?

&& All GrCs are supposed to have the same number of dendrites, meaning that 'lacking inputs' will be filled in with redundant inputs.

&& Initialisation
STORE '' TO cPERMS,cCOMBS

&& Let's make a list of all the possible permutations and also of their 'ordered' combinations.
FOR nA=1 TO pnDims
	FOR nB=1 TO pnDims
		FOR nC=1 TO pnDims
			FOR nD=1 TO pnDims
				FOR nE=1 TO pnDims
					FOR nP=1 TO IIF(pnSurDen=>1,pnDims,1)
						FOR nQ=1 TO IIF(pnSurDen=>2,pnDims,1)
							&& 'Build' a permutation 'string' in function of the dimensionality and the added surnumerary dendrites
							cPERM=CHR(nA+pnAO)+CHR(nB+pnAO)+IIF(pnDims>2,CHR(nC+pnAO),'')+IIF(pnDims>3,CHR(nD+pnAO),'')+IIF(pnDims>4,CHR(nE+pnAO),'')+;
								IIF(pnSurDen=>1,CHR(nP+pnAO),'')+IIF(pnSurDen=2,CHR(nQ+pnAO),'')
							cPERMS=cPERMS+cPERM+' ' && make a long string of all the generated permutations (with a blank as separator)

							&& 'ordering the permutation' is permitted since only combinations matter for the GrC
							&& See also the ORDERINPUTS subroutine
							cCOMB=LEFT(ORDERINPUTS((cPERM)),pnDims)
							cCOMBS=cCOMBS+cCOMB+' ' && make a long string of all the 'ordered' permutations (with a blank as separator)
						ENDFOR
					ENDFOR
					IF pnDims<5 && Skip the loop if there is no 5th dimension
						EXIT
					ENDIF
				ENDFOR
				IF pnDims<4 && Skip the loop if there is no 4th dimension
					EXIT
				ENDIF
			ENDFOR
			IF pnDims<3 && Skip the loop if there is no 3rd dimension
				EXIT
			ENDIF
		ENDFOR
		IF pnDims<2 && Skip the loop if there is no 2nd dimension
			EXIT
		ENDIF
	ENDFOR
ENDFOR

? "The original permutation list"
? cPERMS
?
WAIT
?
? "The 'ordered' permutation list"
? cCOMBS
?
WAIT
?

&& Initialisation
nRAcount=0 && Will contain the RAs count
nWAcount=0 && Will contain the WAs count
cWAcats='' && Will contain an oversight of how many WAs are caused in function of the number of lacking inputs and of the PPVs per axis
nCount=0 && (to count the printed lines)

FOR nP=1 TO LEN(cCOMBS) STEP pnDims+1
	nCount=nCount+1
	cCOMB=SUBSTR(cCOMBS,nP,pnDims) && get the particular input combination
	&& Initialise nWAsubcount at 1 : will be multiplied with the PPV number on each lacking dimension
	&& to calculate the number of WAs this particular input combination will generate
	nWAsubcount=1
	cWASubCount=' (1*' && will contain the expression leading to the subcount
	cLIs='' && Will list the 'lacking inputs'
	
	FOR nQ=1 TO LEN(cCOMB) && look which inputs are lacking
		cQ=SUBSTR(cCOMB,nQ,1)
		IF cQ=CHR(nQ+pnAO) && this dimensional input is not lacking in the ordered combination
			LOOP
		ENDIF
		cRefChar=CHR(nQ+ASC('a')-1) && get the reference character (a,b,c,d,e) of the dimension axis
		cLIs=cLIs+cRefChar && add to the lacking input list
		nWAsubcount=nWAsubcount*pnPPV&cRefChar && multiply nWA with the PPV number of this dimension axis
		cWAsubcount=cWAsubcount+LTRIM(STR(pnPPV&cRefChar))+'*' && complete the expression
	ENDFOR
	&& subtract 1 since EVERY combination input will on one occasion fire at the right time (affecting the 'right' address/synapse)
	nWAsubcount=nWAsubcount-1
	cWAsubcount=LEFT(LEFT(cWAsubcount,LEN(cWASubCount)-1)+'-1)'+'          ',15)
	
	&& Show - for this specific combination - the RAs (always=1 here) and the WAs
	cT="GrC at RA fires every time the A-path engages a node in the "+cLIs+' '
	? cCOMB+' '+STR(1,2)+" RA "+STR(nWAsubcount,5)+" WAs "+cWASubCount+"  Lacking inputs : "+;
		LEFT(cLIs+'   ',4)+IIF(LEN(cLIs)=0,''," ("+cT+;
		ICASE(LEN(cLIs)=1,"row",LEN(cLIs)=2,"plane",+LEN(cLIs)=3,"volume",LEN(cLIs)=4,"hypervolume",'')+;
		" in the "+LTRIM(STR(LEN(cCOMB)))+"D ISU)")
	IF MOD(nCount,20)=0 && show 20 lines
		?
		WAIT
		?
	ENDIF
	
	nRAcount=nRAcount+1 && Count the total RAs
	nWAcount=nWAcount+nWAsubcount && Count the total WAs
	cWAcats=cWAcats+STR(nWAsubcount,7) && make a 'stringlist' of the WA subcounts (for later)
ENDFOR

?
? "RA and WA count totals and the RA/(RA+WA) ratio"
? STR(nRAcount,6)+" RAs",STR(nWAcount,6)+" WAs",STR(nRAcount*100/(nRAcount+nWAcount))+"% RAs"
?

&& Let's have a look at how many input combinations produce a specific number of WAs  
? "How many permutations produce a specific amount of WAs ?"
?
DO WHILE LEN(cWAcats)>0 && Scan the WA subcount 'stringlist'
	cX=LEFT(cWAcats,7)
	nX=OCCURS(cX,cWAcats) && How many times do we find this specific WA subcount ?
	cWAcats=STRTRAN(cWAcats,cX,'') && Let's remove these specific subcounts from the stringlist
	? STR(nX,5)+" permutations causing "+RIGHT(cX,3)+" WAs / causing a GrC to fire "+RIGHT(cX,3)+" times at a wrong time"   
ENDDO
?
? "Finished !"

	PROCEDURE ORDERINPUTS(cLPERM,	cLPERM_Ordered,nI,cPI,nRI,cRI)
	&& cLPERM is a specific input permutation (order mattering, repetitions allowed)
	&& For the GrC order does not matter.
	&& In 4D, abcd is for the GrC the same as bcad, dcba ...
	&& In 4D, 24 (faculty 4) such permutations exist among the total of 256 (4^4) possible permutations with repetitions allowed.
	
	&& If order doesn't matter we may 'order' the permutation as we like, in casu putting 'a' first, 'b' second ...
	&& leaving a blank when an input is lacking, then filling in the blank location with a redundant input
	
	cLPERM_Ordered=SPACE(pnDims+pnSurDen) && initialize with blanks for each input (surnumerary included)
	FOR nI=1 TO pnDims+pnSurDen
	&& loop through all the inputs (a,b,c,...)
		cPI=CHR(nI+pnAO) && gives 'a', 'b', 'c',...
		&& is the input present in the actual permutation of inputs ?
		IF cPI$cLPERM
			cLPERM_Ordered=STUFF(cLPERM_Ordered,nI,1,cPI) && place it where it belongs (xth input at xth place) in cLPERM_Ordered
			cLPERM=STUFF(cLPERM,AT(cPI,cLPERM),1,'') && remove this input from cLPERM
		ENDIF
	ENDFOR

	&& what is left in cLPERM are redundant inputs : their number should equal the leftover open places in cLPERM_Ordered
	cLPERM=ALFABETIC(cLPERM)
	FOR nRI=1 TO LEN(cLPERM)
	&& loop through them
		cRI=SUBSTR(cLPERM,nRI,1) && a redundant input
		&& place the redundant input in a leftover open place in cLPERM_Ordered
		cLPERM_Ordered=STUFF(cLPERM_Ordered,AT(' ',cLPERM_Ordered),1,cRI)
	ENDFOR
	&& cLPERM_Ordered is 'ordered' in function of the nested loops of dimensions
	&& When a,b,c,d are not resp. located in positions 1,2,3,4 then the 'misplaced elements' are redundant (repetitions)
	&& and take the place of lacking inputs (and any redundant input must find its namesake in its ordered position) :
	&& e.g. adcd means d is a redundant input filling in for a lacking b - and any combination that cannot be 'read' in this way is not 'ordered'.
	RETURN(cLPERM_Ordered)
	
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
								
