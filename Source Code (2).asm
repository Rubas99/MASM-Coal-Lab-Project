.386
.model flat, stdcall
option casemap:none
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
NUM_ACC        EQU 5
NAME_LEN       EQU 20
HIST_MAX       EQU 10
MAX_ATTEMPTS   EQU 3
DAILY_LIMIT    EQU 20000
MAX_DEPOSIT    EQU 100000
FEE_PERCENT    EQU 1
MIN_FEE        EQU 10
TYPE_DEPOSIT   EQU 1
TYPE_WITHDRAW  EQU 2
TYPE_TRF_OUT   EQU 3
TYPE_TRF_IN    EQU 4
NO_ACCOUNT     EQU 0FFFFFFFFh
S_LOGIN_ACC    EQU 0
S_LOGIN_PIN    EQU 1
S_MENU         EQU 2
S_DEPOSIT      EQU 3
S_WITHDRAW     EQU 4
S_TRF_DEST     EQU 5
S_TRF_AMT      EQU 6
S_PIN_OLD      EQU 7
S_PIN_NEW      EQU 8
S_PIN_CONF     EQU 9
S_BALANCE      EQU 10
S_STATEMENT    EQU 11
S_SUMMARY      EQU 12
S_MESSAGE      EQU 13
WIN_W          EQU 640
WIN_H          EQU 700
SCR_L          EQU 130
SCR_T          EQU 75
SCR_R          EQU 510
SCR_B          EQU 315
ROW_H          EQU 24
NLINES         EQU 10
LINE_LEN       EQU 48
TRAY_L         EQU 170
TRAY_T         EQU 620
TRAY_R         EQU 470
TRAY_B         EQU 684
WIN_STYLE      EQU WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_CLIPCHILDREN
COL_BODY       EQU 00CDC8C8h
COL_PANEL      EQU 0048403Ch
COL_BEZEL      EQU 0026201Eh
COL_SCREEN     EQU 00182408h
COL_TEXT       EQU 00A0FF78h
COL_TITLE      EQU 0050DCFFh
COL_ERR        EQU 006E6EFFh
COL_SOFT       EQU 00FFFFFFh
COL_SLOT       EQU 00141414h
COL_CASH       EQU 005AAA5Ah
WinMain        PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc        PROTO :DWORD,:DWORD,:DWORD,:DWORD
OnPaint        PROTO :DWORD
FillRc         PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
MkBtn          PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LogEvent       PROTO :DWORD,:DWORD,:DWORD,:DWORD
ShowMsg        PROTO :DWORD,:DWORD,:DWORD,:DWORD
SetLn          PROTO :DWORD,:DWORD
FmtLn          PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SetSoft        PROTO :DWORD,:DWORD
NamePtr        PROTO :DWORD
GoScreen       PROTO :DWORD
OnSoft         PROTO :DWORD
AppendDigit    PROTO :DWORD
FindAccount    PROTO :DWORD
CalcFee        PROTO :DWORD
AddHistory     PROTO :DWORD,:DWORD,:DWORD
DoDeposit      PROTO :DWORD
DoWithdraw     PROTO :DWORD
DoTransfer     PROTO :DWORD
SaveData       PROTO
LoadData       PROTO
GetToday       PROTO
ParseInput     PROTO
ClearInput     PROTO
MaskInput      PROTO
BuildScreen    PROTO
Refresh        PROTO
OnEnter        PROTO
OnCancel       PROTO
OnBackspace    PROTO
DoLogout       PROTO
.data
accNo           DWORD 1001, 1002, 1003, 1004, 1005
accName         BYTE "Ali Khan",0,    11 DUP(0)
                BYTE "Sara Ahmed",0,   9 DUP(0)
                BYTE "Bilal Raza",0,   9 DUP(0)
                BYTE "Hina Malik",0,   9 DUP(0)
                BYTE "Usman Ali",0,   10 DUP(0)
saveStart       LABEL BYTE
saveDay         DWORD 0
accPin          DWORD 1111, 2222, 3333, 4444, 5555
accBal          DWORD 25000, 12000, 50000, 5000, 32000
accDeposits     DWORD NUM_ACC DUP(0)
accWithdrawals  DWORD NUM_ACC DUP(0)
accTxnCount     DWORD NUM_ACC DUP(0)
accDayWithdrawn DWORD NUM_ACC DUP(0)
accAttempts     DWORD NUM_ACC DUP(0)
accLocked       DWORD NUM_ACC DUP(0)
histAcc         DWORD HIST_MAX DUP(0)
histType        DWORD HIST_MAX DUP(0)
histAmt         DWORD HIST_MAX DUP(0)
histBal         DWORD HIST_MAX DUP(0)
histNext        DWORD 0
histCount       DWORD 0
saveEnd         LABEL BYTE
SAVE_SIZE       EQU saveEnd - saveStart
dataFile        BYTE "atm_data.dat",0
logFile         BYTE "atm_log.txt",0
hInstance       DWORD 0
hMainWnd        DWORD 0
hBrBody         DWORD 0
hBrPanel        DWORD 0
hBrBezel        DWORD 0
hBrScreen       DWORD 0
hBrSlot         DWORD 0
hBrCash         DWORD 0
hFontScr        DWORD 0
hFontTitle      DWORD 0
hFontSmall      DWORD 0
hFontBtn        DWORD 0
curScreen       DWORD S_LOGIN_ACC
curAcc          DWORD NO_ACCOUNT
loginAcc        DWORD NO_ACCOUNT
tmpDest         DWORD 0
tmpPin          DWORD 0
msgNext         DWORD 0
msgIsErr        DWORD 0
pMsg1           DWORD 0
pMsg2           DWORD 0
cashAmt         DWORD 0
inputLen        DWORD 0
inputBuf        BYTE 16 DUP(0)
scrLines        BYTE NLINES*LINE_LEN DUP(0)
softLbl         BYTE 8*16 DUP(0)
msgBuf1         BYTE 80 DUP(0)
msgBuf2         BYTE 80 DUP(0)
detBuf          BYTE 100 DUP(0)
tmpBuf          BYTE 40 DUP(0)
trayBuf         BYTE 40 DUP(0)
logLine         BYTE 400 DUP(0)
logBuf          BYTE 512 DUP(0)
stmtIdx         DWORD HIST_MAX DUP(0)
quickAmt        DWORD 500, 1000, 2000, 5000, 10000, 15000, 20000
clsName         BYTE "AtmWinClass",0
clsBtn          BYTE "BUTTON",0
appTitle        BYTE "Simple ATM Banking System - COAL Project",0
capATM          BYTE "Simple ATM",0
txtTitle        BYTE "SIMPLE  ATM",0
fontMono        BYTE "Courier New",0
fontSans        BYTE "Arial",0
txtLt           BYTE "<",0
txtGt           BYTE ">",0
txtCard         BYTE "INSERT CARD",0
txtReceipt      BYTE "RECEIPT",0
txtCashLbl      BYTE "CASH DISPENSER",0
txtClear        BYTE "CLEAR",0
txtEnter        BYTE "ENTER",0
txtCancel       BYTE "CANCEL",0
txtAskLogout    BYTE "Do you want to log out?",0
digitStr        BYTE "0",0,"1",0,"2",0,"3",0,"4",0,"5",0,"6",0,"7",0,"8",0,"9",0
tLoginT         BYTE "  *** WELCOME TO SIMPLE ATM ***",0
tLogin1         BYTE "Please enter your account number",0
tLogin2         BYTE "using the keypad.",0
tDemoAcc        BYTE "Demo accounts: 1001 to 1005",0
tPinT           BYTE "      *** ENTER YOUR PIN ***",0
tPinHint        BYTE "ENTER = confirm, CANCEL = back",0
tMenuHint       BYTE "Choose a service with the side keys",0
tDepT           BYTE "        CASH DEPOSIT",0
tDep1           BYTE "Enter amount (Rs. 1 - 100000)",0
tWdT            BYTE "       CASH WITHDRAWAL",0
tWdHint         BYTE "(multiple of 100) then press ENTER",0
tTrfT           BYTE "        FUND TRANSFER",0
tTrf1           BYTE "Destination account number",0
tTrf2           BYTE "Fee: 1 percent, minimum Rs. 10",0
tPinChT         BYTE "         CHANGE PIN",0
tPinOld         BYTE "Enter your CURRENT PIN",0
tPinNew         BYTE "Enter NEW 4-digit PIN",0
tPinConf        BYTE "Confirm the NEW PIN",0
tBalT           BYTE "       BALANCE INQUIRY",0
tBalAvail       BYTE "Available balance:",0
tStmtT          BYTE "       MINI STATEMENT",0
tStmtHead       BYTE "Type", 11 DUP(' '), "Amount", 3 DUP(' '), "Balance", 0
tNoTxn          BYTE "No transactions yet.",0
tSumT           BYTE "       ACCOUNT SUMMARY",0
tMsgOk          BYTE "         *** DONE ***",0
tMsgErr         BYTE "        *** ERROR ***",0
tContinue       BYTE "Press ENTER to continue",0
tGoBack         BYTE "Press ENTER to go back",0
tBack           BYTE "Back >",0
tContact        BYTE "Please contact the bank.",0
lblBal          BYTE "< Balance",0
lblDep          BYTE "< Deposit",0
lblWd           BYTE "< Withdraw",0
lblTrf          BYTE "< Transfer",0
lblStmt         BYTE "Statement >",0
lblSum          BYTE "Summary >",0
lblPin          BYTE "Change PIN >",0
lblLogout       BYTE "Logout >",0
lblQ1           BYTE "< Rs. 500",0
lblQ2           BYTE "< Rs. 1000",0
lblQ3           BYTE "< Rs. 2000",0
lblQ4           BYTE "< Rs. 5000",0
lblQ5           BYTE "Rs. 10000 >",0
lblQ6           BYTE "Rs. 15000 >",0
lblQ7           BYTE "Rs. 20000 >",0
fmtAccIn        BYTE "Account no : %s_",0
fmtAmtIn        BYTE "Amount : Rs. %s_",0
fmtPinIn        BYTE "PIN : %s_",0
fmtOtherAmt     BYTE "Other amount: %s_",0
fmtAccShow      BYTE "Account : %d",0
fmtWelcome      BYTE "Welcome, %s",0
fmtBalLine      BYTE "Balance: Rs. %d",0
fmtRs           BYTE "Rs. %d",0
fmtLimit        BYTE "Withdraw limit left today: Rs. %d",0
fmtTo           BYTE "To: %d (%s)",0
fmtHolder       BYTE "Account holder : %s",0
fmtSumAcc       BYTE "Account number : %d",0
fmtSumBal       BYTE "Balance (Rs.)  : %d",0
fmtSumDep       BYTE "Total deposits : %d",0
fmtSumWd        BYTE "Total withdrawn: %d",0
fmtSumTx        BYTE "Transactions   : %d",0
fmtSumToday     BYTE "Withdrawn today: %d",0
fmtStmt         BYTE "%s%7d %9d",0
fmtTray         BYTE "Rs. %d - click to take",0
fmtLeft         BYTE "Wrong PIN. Attempts left: %d",0
fmtDepOk        BYTE "Deposit accepted: Rs. %d",0
fmtNewBal       BYTE "New balance: Rs. %d",0
fmtCash         BYTE "Please take your cash: Rs. %d",0
fmtTrfOk1       BYTE "Rs. %d sent to account %d",0
fmtTrfOk2       BYTE "Fee Rs. %d, new balance Rs. %d",0
msgPinOk        BYTE "PIN changed successfully.",0
errZero         BYTE "Amount must be more than zero.",0
errNoAccount    BYTE "Account number not found.",0
errLocked       BYTE "This account is locked.",0
errNowLocked    BYTE "3 wrong PINs. Account locked.",0
errTooBig       BYTE "Maximum deposit is Rs. 100000.",0
errOverflow     BYTE "Balance too large for this amount.",0
errNotHundred   BYTE "Amount must be a multiple of 100.",0
errNoFunds      BYTE "Insufficient balance.",0
errDayLimit     BYTE "Daily limit (Rs. 20000) exceeded.",0
errNoDest       BYTE "Destination account not found.",0
errSelf         BYTE "Cannot transfer to own account.",0
errNoFundsFee   BYTE "Insufficient balance (amount+fee).",0
errOldPin       BYTE "Current PIN is wrong.",0
errNewPin       BYTE "PIN must be 4 digits (1000-9999).",0
errNoMatch      BYTE "PINs do not match.",0
fmtStamp        BYTE "[%04d-%02d-%02d %02d:%02d:%02d] ",0
fmtLogAcc       BYTE "Acc %d (%s) | %-18s | Amt Rs.%d | Bal Rs.%d | %s",0Dh,0Ah,0
fmtLogNo        BYTE "No account | %-18s | %s",0Dh,0Ah,0
fmtDetTyped     BYTE "typed number %d",0
fmtDetAtt       BYTE "attempt %d of 3",0
fmtDetOut       BYTE "to acc %d, fee Rs.%d",0
fmtDetIn        BYTE "from acc %d",0
txtDash         BYTE "-",0
txtLockedDet    BYTE "account is locked",0
txtWrongOldPin  BYTE "wrong current PIN",0
actStart        BYTE "PROGRAM STARTED",0
actClose        BYTE "PROGRAM CLOSED",0
actLoginOk      BYTE "LOGIN OK",0
actLoginFail    BYTE "LOGIN FAILED",0
actLoginBlock   BYTE "LOGIN BLOCKED",0
actPinFail      BYTE "WRONG PIN",0
actLocked       BYTE "ACCOUNT LOCKED",0
actLogout       BYTE "LOGOUT",0
actBalance      BYTE "BALANCE INQUIRY",0
actDeposit      BYTE "DEPOSIT",0
actDepDenied    BYTE "DEPOSIT DENIED",0
actWithdraw     BYTE "WITHDRAWAL",0
actWdDenied     BYTE "WITHDRAW DENIED",0
actTrfOut       BYTE "TRANSFER OUT",0
actTrfIn        BYTE "TRANSFER IN",0
actTrfDenied    BYTE "TRANSFER DENIED",0
actPinChg       BYTE "PIN CHANGED",0
actPinChgFail   BYTE "PIN CHANGE FAILED",0
actStatement    BYTE "STATEMENT VIEWED",0
actSummary      BYTE "SUMMARY VIEWED",0
typeNames       BYTE "Deposit",      7 DUP(' '), 0, 0
                BYTE "Withdrawal",   4 DUP(' '), 0, 0
                BYTE "Transfer Out", 2 DUP(' '), 0, 0
                BYTE "Transfer In",  3 DUP(' '), 0, 0
.code
GetToday PROC
    LOCAL st:SYSTEMTIME
    invoke GetLocalTime, addr st
    movzx eax, st.wYear
    imul  eax, eax, 10000
    movzx ecx, st.wMonth
    imul  ecx, ecx, 100
    add   eax, ecx
    movzx ecx, st.wDay
    add   eax, ecx
    ret
GetToday ENDP
SaveData PROC
    LOCAL hFile:DWORD
    LOCAL written:DWORD
    call  GetToday
    mov   saveDay, eax
    invoke CreateFile, addr dataFile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    cmp   eax, INVALID_HANDLE_VALUE
    je    sdDone
    mov   hFile, eax
    invoke WriteFile, hFile, addr saveStart, SAVE_SIZE, addr written, NULL
    invoke CloseHandle, hFile
sdDone:
    ret
SaveData ENDP
LoadData PROC USES edi
    LOCAL hFile:DWORD
    LOCAL got:DWORD
    invoke CreateFile, addr dataFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp   eax, INVALID_HANDLE_VALUE
    je    ldCheckDay
    mov   hFile, eax
    invoke GetFileSize, hFile, NULL
    cmp   eax, SAVE_SIZE
    jne   ldClose
    invoke ReadFile, hFile, addr saveStart, SAVE_SIZE, addr got, NULL
ldClose:
    invoke CloseHandle, hFile
    cmp   histNext, HIST_MAX
    jae   ldBadHist
    cmp   histCount, HIST_MAX
    jbe   ldCheckDay
ldBadHist:
    mov   histNext, 0
    mov   histCount, 0
ldCheckDay:
    call  GetToday
    cmp   eax, saveDay
    je    ldDone
    mov   saveDay, eax
    mov   edi, OFFSET accDayWithdrawn
    mov   ecx, NUM_ACC
    xor   eax, eax
    rep   stosd
ldDone:
    ret
LoadData ENDP
LogEvent PROC USES ebx esi edi acc:DWORD, pAct:DWORD, amt:DWORD, pDet:DWORD
    LOCAL st:SYSTEMTIME
    LOCAL hFile:DWORD
    LOCAL written:DWORD
    LOCAL vY:DWORD, vMo:DWORD, vD:DWORD, vH:DWORD, vMi:DWORD, vS:DWORD
    LOCAL pName:DWORD, vNo:DWORD, vBal:DWORD
    invoke GetLocalTime, addr st
    movzx eax, st.wYear
    mov   vY, eax
    movzx eax, st.wMonth
    mov   vMo, eax
    movzx eax, st.wDay
    mov   vD, eax
    movzx eax, st.wHour
    mov   vH, eax
    movzx eax, st.wMinute
    mov   vMi, eax
    movzx eax, st.wSecond
    mov   vS, eax
    invoke wsprintf, addr logBuf, addr fmtStamp, vY, vMo, vD, vH, vMi, vS
    cmp   acc, NO_ACCOUNT
    je    leNoAcc
    mov   esi, acc
    mov   eax, esi
    imul  eax, eax, NAME_LEN
    add   eax, OFFSET accName
    mov   pName, eax
    mov   eax, [accNo + esi*4]
    mov   vNo, eax
    mov   eax, [accBal + esi*4]
    mov   vBal, eax
    invoke wsprintf, addr logLine, addr fmtLogAcc, vNo, pName, pAct, amt, vBal, pDet
    jmp   leWrite
leNoAcc:
    invoke wsprintf, addr logLine, addr fmtLogNo, pAct, pDet
leWrite:
    invoke lstrcat, addr logBuf, addr logLine
    invoke CreateFile, addr logFile, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    cmp   eax, INVALID_HANDLE_VALUE
    je    leDone
    mov   hFile, eax
    invoke SetFilePointer, hFile, 0, NULL, FILE_END
    invoke lstrlen, addr logBuf
    mov   ebx, eax
    invoke WriteFile, hFile, addr logBuf, ebx, addr written, NULL
    invoke CloseHandle, hFile
leDone:
    ret
LogEvent ENDP
NamePtr PROC idx:DWORD
    mov   eax, idx
    imul  eax, eax, NAME_LEN
    add   eax, OFFSET accName
    ret
NamePtr ENDP
FindAccount PROC USES ebx ecx num:DWORD
    mov   ebx, num
    xor   ecx, ecx
faLoop:
    cmp   ecx, NUM_ACC
    jae   faNone
    cmp   ebx, [accNo + ecx*4]
    je    faFound
    inc   ecx
    jmp   faLoop
faFound:
    mov   eax, ecx
    ret
faNone:
    mov   eax, NO_ACCOUNT
    ret
FindAccount ENDP
CalcFee PROC USES ebx edx amt:DWORD
    mov   eax, amt
    mov   ebx, FEE_PERCENT
    mul   ebx
    mov   ebx, 100
    xor   edx, edx
    div   ebx
    cmp   eax, MIN_FEE
    jae   cfDone
    mov   eax, MIN_FEE
cfDone:
    ret
CalcFee ENDP
AddHistory PROC USES ecx edx acc:DWORD, typ:DWORD, amt:DWORD
    mov   ecx, histNext
    mov   eax, acc
    mov   [histAcc  + ecx*4], eax
    mov   eax, typ
    mov   [histType + ecx*4], eax
    mov   eax, amt
    mov   [histAmt  + ecx*4], eax
    mov   edx, acc
    mov   eax, [accBal + edx*4]
    mov   [histBal  + ecx*4], eax
    inc   ecx
    cmp   ecx, HIST_MAX
    jb    ahStore
    xor   ecx, ecx
ahStore:
    mov   histNext, ecx
    cmp   histCount, HIST_MAX
    jae   ahDone
    inc   histCount
ahDone:
    ret
AddHistory ENDP
ClearInput PROC
    mov   inputLen, 0
    mov   BYTE PTR [inputBuf], 0
    ret
ClearInput ENDP
ParseInput PROC USES ebx ecx esi
    xor   eax, eax
    mov   ecx, inputLen
    mov   esi, OFFSET inputBuf
piLoop:
    test  ecx, ecx
    jz    piDone
    movzx ebx, BYTE PTR [esi]
    sub   ebx, '0'
    imul  eax, eax, 10
    add   eax, ebx
    inc   esi
    dec   ecx
    jmp   piLoop
piDone:
    ret
ParseInput ENDP
MaskInput PROC USES ecx edi
    mov   edi, OFFSET tmpBuf
    mov   ecx, inputLen
    mov   al, '*'
    rep   stosb
    mov   BYTE PTR [edi], 0
    ret
MaskInput ENDP
SetLn PROC row:DWORD, pText:DWORD
    mov   eax, row
    imul  eax, eax, LINE_LEN
    add   eax, OFFSET scrLines
    invoke lstrcpy, eax, pText
    ret
SetLn ENDP
FmtLn PROC row:DWORD, pFmt:DWORD, a1:DWORD, a2:DWORD, a3:DWORD
    mov   eax, row
    imul  eax, eax, LINE_LEN
    add   eax, OFFSET scrLines
    invoke wsprintf, eax, pFmt, a1, a2, a3
    ret
FmtLn ENDP
SetSoft PROC idx:DWORD, pText:DWORD
    mov   eax, idx
    shl   eax, 4
    add   eax, OFFSET softLbl
    invoke lstrcpy, eax, pText
    ret
SetSoft ENDP
BuildScreen PROC USES ebx esi edi
    LOCAL startI:DWORD
    LOCAL typP:DWORD
    LOCAL vRow:DWORD
    mov   edi, OFFSET scrLines
    mov   ecx, NLINES*LINE_LEN
    xor   eax, eax
    rep   stosb
    mov   edi, OFFSET softLbl
    mov   ecx, 128
    rep   stosb
    mov   eax, curScreen
    cmp   eax, S_LOGIN_ACC
    je    bsLoginAcc
    cmp   eax, S_LOGIN_PIN
    je    bsLoginPin
    cmp   eax, S_MENU
    je    bsMenu
    cmp   eax, S_DEPOSIT
    je    bsDeposit
    cmp   eax, S_WITHDRAW
    je    bsWithdraw
    cmp   eax, S_TRF_DEST
    je    bsTrfDest
    cmp   eax, S_TRF_AMT
    je    bsTrfAmt
    cmp   eax, S_PIN_OLD
    je    bsPinOld
    cmp   eax, S_PIN_NEW
    je    bsPinNew
    cmp   eax, S_PIN_CONF
    je    bsPinConf
    cmp   eax, S_BALANCE
    je    bsBalance
    cmp   eax, S_STATEMENT
    je    bsStatement
    cmp   eax, S_SUMMARY
    je    bsSummary
    cmp   eax, S_MESSAGE
    je    bsMessage
    jmp   bsEnd
bsLoginAcc:
    invoke SetLn, 0, addr tLoginT
    invoke SetLn, 2, addr tLogin1
    invoke SetLn, 3, addr tLogin2
    invoke FmtLn, 5, addr fmtAccIn, addr inputBuf, 0, 0
    invoke SetLn, 7, addr tPinHint
    invoke SetLn, 9, addr tDemoAcc
    jmp   bsEnd
bsLoginPin:
    call  MaskInput
    mov   esi, loginAcc
    invoke SetLn, 0, addr tPinT
    mov   eax, [accNo + esi*4]
    invoke FmtLn, 2, addr fmtAccShow, eax, 0, 0
    invoke FmtLn, 4, addr fmtPinIn, addr tmpBuf, 0, 0
    invoke SetLn, 7, addr tPinHint
    jmp   bsEnd
bsMenu:
    mov   esi, curAcc
    invoke NamePtr, esi
    invoke FmtLn, 0, addr fmtWelcome, eax, 0, 0
    mov   eax, [accBal + esi*4]
    invoke FmtLn, 8, addr fmtBalLine, eax, 0, 0
    invoke SetLn, 9, addr tMenuHint
    invoke SetSoft, 0, addr lblBal
    invoke SetSoft, 1, addr lblDep
    invoke SetSoft, 2, addr lblWd
    invoke SetSoft, 3, addr lblTrf
    invoke SetSoft, 4, addr lblStmt
    invoke SetSoft, 5, addr lblSum
    invoke SetSoft, 6, addr lblPin
    invoke SetSoft, 7, addr lblLogout
    jmp   bsEnd
bsDeposit:
    invoke SetLn, 0, addr tDepT
    invoke SetLn, 2, addr tDep1
    invoke FmtLn, 5, addr fmtAmtIn, addr inputBuf, 0, 0
    invoke SetLn, 8, addr tPinHint
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsWithdraw:
    invoke SetLn, 0, addr tWdT
    invoke FmtLn, 8, addr fmtOtherAmt, addr inputBuf, 0, 0
    invoke SetLn, 9, addr tWdHint
    invoke SetSoft, 0, addr lblQ1
    invoke SetSoft, 1, addr lblQ2
    invoke SetSoft, 2, addr lblQ3
    invoke SetSoft, 3, addr lblQ4
    invoke SetSoft, 4, addr lblQ5
    invoke SetSoft, 5, addr lblQ6
    invoke SetSoft, 6, addr lblQ7
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsTrfDest:
    invoke SetLn, 0, addr tTrfT
    invoke SetLn, 2, addr tTrf1
    invoke FmtLn, 4, addr fmtAccIn, addr inputBuf, 0, 0
    invoke SetLn, 6, addr tTrf2
    invoke SetLn, 8, addr tPinHint
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsTrfAmt:
    mov   esi, tmpDest
    invoke NamePtr, esi
    mov   ebx, eax
    mov   eax, [accNo + esi*4]
    invoke SetLn, 0, addr tTrfT
    invoke FmtLn, 2, addr fmtTo, eax, ebx, 0
    invoke SetLn, 4, addr tTrf2
    invoke FmtLn, 6, addr fmtAmtIn, addr inputBuf, 0, 0
    invoke SetLn, 8, addr tPinHint
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsPinOld:
    call  MaskInput
    invoke SetLn, 0, addr tPinChT
    invoke SetLn, 2, addr tPinOld
    invoke FmtLn, 5, addr fmtPinIn, addr tmpBuf, 0, 0
    invoke SetLn, 8, addr tPinHint
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsPinNew:
    call  MaskInput
    invoke SetLn, 0, addr tPinChT
    invoke SetLn, 2, addr tPinNew
    invoke FmtLn, 5, addr fmtPinIn, addr tmpBuf, 0, 0
    invoke SetLn, 8, addr tPinHint
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsPinConf:
    call  MaskInput
    invoke SetLn, 0, addr tPinChT
    invoke SetLn, 2, addr tPinConf
    invoke FmtLn, 5, addr fmtPinIn, addr tmpBuf, 0, 0
    invoke SetLn, 8, addr tPinHint
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsBalance:
    mov   esi, curAcc
    invoke SetLn, 0, addr tBalT
    mov   eax, [accNo + esi*4]
    invoke FmtLn, 2, addr fmtAccShow, eax, 0, 0
    invoke SetLn, 4, addr tBalAvail
    mov   eax, [accBal + esi*4]
    invoke FmtLn, 5, addr fmtRs, eax, 0, 0
    mov   eax, DAILY_LIMIT
    sub   eax, [accDayWithdrawn + esi*4]
    jae   bsBalLim
    xor   eax, eax
bsBalLim:
    invoke FmtLn, 7, addr fmtLimit, eax, 0, 0
    invoke SetLn, 9, addr tGoBack
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsStatement:
    invoke SetLn, 0, addr tStmtT
    invoke SetLn, 1, addr tStmtHead
    invoke SetSoft, 7, addr tBack
    xor   ebx, ebx
    mov   ecx, histCount
    test  ecx, ecx
    jz    bsStmtNone
    mov   edi, histNext
    sub   edi, histCount
    jae   bsStmtLoop
    add   edi, HIST_MAX
bsStmtLoop:
    mov   eax, [histAcc + edi*4]
    cmp   eax, curAcc
    jne   bsStmtSkip
    mov   [stmtIdx + ebx*4], edi
    inc   ebx
bsStmtSkip:
    inc   edi
    cmp   edi, HIST_MAX
    jb    bsStmtNext
    xor   edi, edi
bsStmtNext:
    dec   ecx
    jnz   bsStmtLoop
    test  ebx, ebx
    jz    bsStmtNone
    xor   esi, esi
    cmp   ebx, 8
    jbe   bsStmtGo
    mov   esi, ebx
    sub   esi, 8
bsStmtGo:
    mov   startI, esi
bsStmtPrint:
    cmp   esi, ebx
    jae   bsEnd
    mov   edi, [stmtIdx + esi*4]
    mov   eax, [histType + edi*4]
    dec   eax
    shl   eax, 4
    add   eax, OFFSET typeNames
    mov   typP, eax
    mov   eax, esi
    sub   eax, startI
    add   eax, 2
    mov   vRow, eax
    invoke FmtLn, vRow, addr fmtStmt, typP, [histAmt + edi*4], [histBal + edi*4]
    inc   esi
    jmp   bsStmtPrint
bsStmtNone:
    invoke SetLn, 3, addr tNoTxn
    jmp   bsEnd
bsSummary:
    mov   esi, curAcc
    invoke SetLn, 0, addr tSumT
    invoke NamePtr, esi
    invoke FmtLn, 2, addr fmtHolder, eax, 0, 0
    invoke FmtLn, 3, addr fmtSumAcc, [accNo + esi*4], 0, 0
    invoke FmtLn, 4, addr fmtSumBal, [accBal + esi*4], 0, 0
    invoke FmtLn, 5, addr fmtSumDep, [accDeposits + esi*4], 0, 0
    invoke FmtLn, 6, addr fmtSumWd, [accWithdrawals + esi*4], 0, 0
    invoke FmtLn, 7, addr fmtSumTx, [accTxnCount + esi*4], 0, 0
    invoke FmtLn, 8, addr fmtSumToday, [accDayWithdrawn + esi*4], 0, 0
    invoke SetSoft, 7, addr tBack
    jmp   bsEnd
bsMessage:
    cmp   msgIsErr, 0
    jne   bsMsgErr
    invoke SetLn, 0, addr tMsgOk
    jmp   bsMsgBody
bsMsgErr:
    invoke SetLn, 0, addr tMsgErr
bsMsgBody:
    invoke SetLn, 3, pMsg1
    cmp   pMsg2, 0
    je    bsMsgNo2
    invoke SetLn, 4, pMsg2
bsMsgNo2:
    invoke SetLn, 8, addr tContinue
bsEnd:
    ret
BuildScreen ENDP
Refresh PROC
    call  BuildScreen
    invoke InvalidateRect, hMainWnd, NULL, FALSE
    ret
Refresh ENDP
GoScreen PROC scr:DWORD
    mov   eax, scr
    mov   curScreen, eax
    call  ClearInput
    call  Refresh
    ret
GoScreen ENDP
ShowMsg PROC p1:DWORD, p2:DWORD, nxt:DWORD, isErr:DWORD
    mov   eax, p1
    mov   pMsg1, eax
    mov   eax, p2
    mov   pMsg2, eax
    mov   eax, nxt
    mov   msgNext, eax
    mov   eax, isErr
    mov   msgIsErr, eax
    invoke GoScreen, S_MESSAGE
    ret
ShowMsg ENDP
DoDeposit PROC USES ebx esi amt:DWORD
    mov   esi, curAcc
    mov   eax, amt
    test  eax, eax
    jz    dpZero
    cmp   eax, MAX_DEPOSIT
    ja    dpBig
    mov   ebx, [accBal + esi*4]
    add   ebx, eax
    jc    dpOver
    mov   [accBal + esi*4], ebx
    add   [accDeposits + esi*4], eax
    inc   DWORD PTR [accTxnCount + esi*4]
    invoke AddHistory, esi, TYPE_DEPOSIT, amt
    invoke LogEvent, esi, addr actDeposit, amt, addr txtDash
    call  SaveData
    invoke wsprintf, addr msgBuf1, addr fmtDepOk, amt
    invoke wsprintf, addr msgBuf2, addr fmtNewBal, [accBal + esi*4]
    invoke ShowMsg, addr msgBuf1, addr msgBuf2, S_MENU, 0
    ret
dpZero:
    invoke ShowMsg, addr errZero, 0, S_DEPOSIT, 1
    ret
dpBig:
    invoke LogEvent, esi, addr actDepDenied, amt, addr errTooBig
    invoke ShowMsg, addr errTooBig, 0, S_DEPOSIT, 1
    ret
dpOver:
    invoke LogEvent, esi, addr actDepDenied, amt, addr errOverflow
    invoke ShowMsg, addr errOverflow, 0, S_DEPOSIT, 1
    ret
DoDeposit ENDP
DoWithdraw PROC USES ebx ecx edx esi amt:DWORD
    mov   esi, curAcc
    mov   eax, amt
    test  eax, eax
    jz    wdZero
    xor   edx, edx
    mov   ecx, 100
    div   ecx
    test  edx, edx
    jnz   wdHundred
    mov   eax, amt
    mov   ebx, [accBal + esi*4]
    sub   ebx, eax
    jb    wdNoFunds
    mov   ecx, [accDayWithdrawn + esi*4]
    add   ecx, eax
    cmp   ecx, DAILY_LIMIT
    ja    wdLimit
    mov   [accBal + esi*4], ebx
    mov   [accDayWithdrawn + esi*4], ecx
    add   [accWithdrawals + esi*4], eax
    inc   DWORD PTR [accTxnCount + esi*4]
    mov   cashAmt, eax
    invoke AddHistory, esi, TYPE_WITHDRAW, amt
    invoke LogEvent, esi, addr actWithdraw, amt, addr txtDash
    call  SaveData
    invoke wsprintf, addr msgBuf1, addr fmtCash, amt
    invoke wsprintf, addr msgBuf2, addr fmtNewBal, [accBal + esi*4]
    invoke ShowMsg, addr msgBuf1, addr msgBuf2, S_MENU, 0
    ret
wdZero:
    invoke ShowMsg, addr errZero, 0, S_WITHDRAW, 1
    ret
wdHundred:
    invoke LogEvent, esi, addr actWdDenied, amt, addr errNotHundred
    invoke ShowMsg, addr errNotHundred, 0, S_WITHDRAW, 1
    ret
wdNoFunds:
    invoke LogEvent, esi, addr actWdDenied, amt, addr errNoFunds
    invoke ShowMsg, addr errNoFunds, 0, S_WITHDRAW, 1
    ret
wdLimit:
    invoke LogEvent, esi, addr actWdDenied, amt, addr errDayLimit
    invoke ShowMsg, addr errDayLimit, 0, S_WITHDRAW, 1
    ret
DoWithdraw ENDP
DoTransfer PROC USES ebx ecx edx esi edi amt:DWORD
    mov   esi, curAcc
    mov   edi, tmpDest
    mov   eax, amt
    test  eax, eax
    jz    trZero
    invoke CalcFee, amt
    mov   ebx, eax
    mov   ecx, amt
    add   ecx, ebx
    mov   edx, [accBal + esi*4]
    sub   edx, ecx
    jb    trNoFunds
    mov   eax, [accBal + edi*4]
    add   eax, amt
    jc    trOver
    mov   [accBal + edi*4], eax
    mov   [accBal + esi*4], edx
    inc   DWORD PTR [accTxnCount + esi*4]
    inc   DWORD PTR [accTxnCount + edi*4]
    invoke AddHistory, esi, TYPE_TRF_OUT, amt
    invoke AddHistory, edi, TYPE_TRF_IN, amt
    invoke wsprintf, addr detBuf, addr fmtDetOut, [accNo + edi*4], ebx
    invoke LogEvent, esi, addr actTrfOut, amt, addr detBuf
    invoke wsprintf, addr detBuf, addr fmtDetIn, [accNo + esi*4]
    invoke LogEvent, edi, addr actTrfIn, amt, addr detBuf
    call  SaveData
    invoke wsprintf, addr msgBuf1, addr fmtTrfOk1, amt, [accNo + edi*4]
    invoke wsprintf, addr msgBuf2, addr fmtTrfOk2, ebx, [accBal + esi*4]
    invoke ShowMsg, addr msgBuf1, addr msgBuf2, S_MENU, 0
    ret
trZero:
    invoke ShowMsg, addr errZero, 0, S_TRF_AMT, 1
    ret
trNoFunds:
    invoke LogEvent, esi, addr actTrfDenied, amt, addr errNoFundsFee
    invoke ShowMsg, addr errNoFundsFee, 0, S_TRF_AMT, 1
    ret
trOver:
    invoke LogEvent, esi, addr actTrfDenied, amt, addr errOverflow
    invoke ShowMsg, addr errOverflow, 0, S_TRF_AMT, 1
    ret
DoTransfer ENDP
DoLogout PROC USES esi
    invoke MessageBox, hMainWnd, addr txtAskLogout, addr capATM, MB_YESNO or MB_ICONQUESTION
    cmp   eax, IDYES
    jne   dlNo
    mov   esi, curAcc
    invoke LogEvent, esi, addr actLogout, 0, addr txtDash
    mov   curAcc, NO_ACCOUNT
    mov   loginAcc, NO_ACCOUNT
    invoke GoScreen, S_LOGIN_ACC
dlNo:
    ret
DoLogout ENDP
AppendDigit PROC dig:DWORD
    mov   eax, curScreen
    mov   ecx, 9
    cmp   eax, S_LOGIN_PIN
    je    adPin
    cmp   eax, S_PIN_OLD
    je    adPin
    cmp   eax, S_PIN_NEW
    je    adPin
    cmp   eax, S_PIN_CONF
    je    adPin
    cmp   eax, S_LOGIN_ACC
    je    adOk
    cmp   eax, S_DEPOSIT
    je    adOk
    cmp   eax, S_WITHDRAW
    je    adOk
    cmp   eax, S_TRF_DEST
    je    adOk
    cmp   eax, S_TRF_AMT
    je    adOk
    ret
adPin:
    mov   ecx, 4
adOk:
    mov   eax, inputLen
    cmp   eax, ecx
    jae   adDone
    mov   edx, dig
    add   edx, '0'
    mov   BYTE PTR [inputBuf + eax], dl
    inc   eax
    mov   BYTE PTR [inputBuf + eax], 0
    mov   inputLen, eax
    call  Refresh
adDone:
    ret
AppendDigit ENDP
OnBackspace PROC
    mov   eax, inputLen
    test  eax, eax
    jz    obDone
    dec   eax
    mov   inputLen, eax
    mov   BYTE PTR [inputBuf + eax], 0
    call  Refresh
obDone:
    ret
OnBackspace ENDP
OnEnter PROC USES ebx esi edi
    mov   eax, curScreen
    cmp   eax, S_LOGIN_ACC
    je    oeLoginAcc
    cmp   eax, S_LOGIN_PIN
    je    oeLoginPin
    cmp   eax, S_DEPOSIT
    je    oeDeposit
    cmp   eax, S_WITHDRAW
    je    oeWithdraw
    cmp   eax, S_TRF_DEST
    je    oeTrfDest
    cmp   eax, S_TRF_AMT
    je    oeTrfAmt
    cmp   eax, S_PIN_OLD
    je    oePinOld
    cmp   eax, S_PIN_NEW
    je    oePinNew
    cmp   eax, S_PIN_CONF
    je    oePinConf
    cmp   eax, S_MESSAGE
    je    oeMessage
    cmp   eax, S_BALANCE
    je    oeBack
    cmp   eax, S_STATEMENT
    je    oeBack
    cmp   eax, S_SUMMARY
    je    oeBack
    ret
oeLoginAcc:
    cmp   inputLen, 0
    je    oeRet
    call  ParseInput
    mov   ebx, eax
    invoke FindAccount, ebx
    cmp   eax, NO_ACCOUNT
    je    oeNoAcc
    mov   esi, eax
    cmp   DWORD PTR [accLocked + esi*4], 0
    jne   oeLocked
    mov   loginAcc, esi
    invoke GoScreen, S_LOGIN_PIN
    ret
oeNoAcc:
    invoke wsprintf, addr detBuf, addr fmtDetTyped, ebx
    invoke LogEvent, NO_ACCOUNT, addr actLoginFail, 0, addr detBuf
    invoke ShowMsg, addr errNoAccount, 0, S_LOGIN_ACC, 1
    ret
oeLocked:
    invoke LogEvent, esi, addr actLoginBlock, 0, addr txtLockedDet
    invoke ShowMsg, addr errLocked, addr tContact, S_LOGIN_ACC, 1
    ret
oeLoginPin:
    call  ParseInput
    mov   ebx, eax
    mov   esi, loginAcc
    cmp   ebx, [accPin + esi*4]
    jne   oeWrongPin
    mov   DWORD PTR [accAttempts + esi*4], 0
    mov   curAcc, esi
    invoke LogEvent, esi, addr actLoginOk, 0, addr txtDash
    call  SaveData
    invoke GoScreen, S_MENU
    ret
oeWrongPin:
    inc   DWORD PTR [accAttempts + esi*4]
    mov   edi, [accAttempts + esi*4]
    cmp   edi, MAX_ATTEMPTS
    jae   oeLockNow
    mov   ebx, MAX_ATTEMPTS
    sub   ebx, edi
    invoke wsprintf, addr msgBuf1, addr fmtLeft, ebx
    invoke wsprintf, addr detBuf, addr fmtDetAtt, edi
    invoke LogEvent, esi, addr actPinFail, 0, addr detBuf
    call  SaveData
    invoke ShowMsg, addr msgBuf1, 0, S_LOGIN_PIN, 1
    ret
oeLockNow:
    mov   DWORD PTR [accLocked + esi*4], 1
    invoke LogEvent, esi, addr actLocked, 0, addr txtLockedDet
    call  SaveData
    invoke ShowMsg, addr errNowLocked, addr tContact, S_LOGIN_ACC, 1
    ret
oeDeposit:
    call  ParseInput
    invoke DoDeposit, eax
    ret
oeWithdraw:
    call  ParseInput
    invoke DoWithdraw, eax
    ret
oeTrfDest:
    cmp   inputLen, 0
    je    oeRet
    call  ParseInput
    mov   ebx, eax
    invoke FindAccount, ebx
    cmp   eax, NO_ACCOUNT
    je    oeTrfNoDest
    cmp   eax, curAcc
    je    oeTrfSelf
    mov   tmpDest, eax
    invoke GoScreen, S_TRF_AMT
    ret
oeTrfNoDest:
    invoke wsprintf, addr detBuf, addr fmtDetTyped, ebx
    invoke LogEvent, curAcc, addr actTrfDenied, 0, addr detBuf
    invoke ShowMsg, addr errNoDest, 0, S_TRF_DEST, 1
    ret
oeTrfSelf:
    invoke ShowMsg, addr errSelf, 0, S_TRF_DEST, 1
    ret
oeTrfAmt:
    call  ParseInput
    invoke DoTransfer, eax
    ret
oePinOld:
    call  ParseInput
    mov   esi, curAcc
    cmp   eax, [accPin + esi*4]
    jne   oePinOldBad
    invoke GoScreen, S_PIN_NEW
    ret
oePinOldBad:
    invoke LogEvent, esi, addr actPinChgFail, 0, addr txtWrongOldPin
    invoke ShowMsg, addr errOldPin, 0, S_MENU, 1
    ret
oePinNew:
    call  ParseInput
    cmp   inputLen, 4
    jne   oePinNewBad
    cmp   eax, 1000
    jb    oePinNewBad
    mov   tmpPin, eax
    invoke GoScreen, S_PIN_CONF
    ret
oePinNewBad:
    invoke ShowMsg, addr errNewPin, 0, S_PIN_NEW, 1
    ret
oePinConf:
    call  ParseInput
    cmp   eax, tmpPin
    jne   oePinNoMatch
    mov   esi, curAcc
    mov   [accPin + esi*4], eax
    invoke LogEvent, esi, addr actPinChg, 0, addr txtDash
    call  SaveData
    invoke ShowMsg, addr msgPinOk, 0, S_MENU, 0
    ret
oePinNoMatch:
    invoke ShowMsg, addr errNoMatch, 0, S_PIN_NEW, 1
    ret
oeMessage:
    mov   eax, msgNext
    invoke GoScreen, eax
    ret
oeBack:
    invoke GoScreen, S_MENU
oeRet:
    ret
OnEnter ENDP
OnCancel PROC
    mov   eax, curScreen
    cmp   eax, S_LOGIN_ACC
    je    ocClear
    cmp   eax, S_LOGIN_PIN
    je    ocToLogin
    cmp   eax, S_MESSAGE
    je    ocMessage
    cmp   eax, S_MENU
    je    ocLogout
    invoke GoScreen, S_MENU
    ret
ocClear:
    call  ClearInput
    call  Refresh
    ret
ocToLogin:
    invoke GoScreen, S_LOGIN_ACC
    ret
ocMessage:
    call  OnEnter
    ret
ocLogout:
    call  DoLogout
    ret
OnCancel ENDP
OnSoft PROC USES esi idx:DWORD
    mov   eax, curScreen
    cmp   eax, S_MESSAGE
    je    osMsg
    cmp   eax, S_MENU
    je    osMenu
    cmp   eax, S_WITHDRAW
    je    osWd
    cmp   eax, S_MENU
    jb    osRet
    cmp   idx, 7
    jne   osRet
    invoke GoScreen, S_MENU
    ret
osMsg:
    call  OnEnter
    ret
osWd:
    mov   eax, idx
    cmp   eax, 7
    je    osBack
    mov   eax, [quickAmt + eax*4]
    invoke DoWithdraw, eax
    ret
osBack:
    invoke GoScreen, S_MENU
    ret
osMenu:
    mov   esi, curAcc
    mov   eax, idx
    cmp   eax, 0
    je    osBal
    cmp   eax, 1
    je    osDep
    cmp   eax, 2
    je    osWdraw
    cmp   eax, 3
    je    osTrf
    cmp   eax, 4
    je    osStmt
    cmp   eax, 5
    je    osSum
    cmp   eax, 6
    je    osPin
    cmp   eax, 7
    je    osOut
    ret
osBal:
    invoke LogEvent, esi, addr actBalance, 0, addr txtDash
    invoke GoScreen, S_BALANCE
    ret
osDep:
    invoke GoScreen, S_DEPOSIT
    ret
osWdraw:
    invoke GoScreen, S_WITHDRAW
    ret
osTrf:
    invoke GoScreen, S_TRF_DEST
    ret
osStmt:
    invoke LogEvent, esi, addr actStatement, 0, addr txtDash
    invoke GoScreen, S_STATEMENT
    ret
osSum:
    invoke LogEvent, esi, addr actSummary, 0, addr txtDash
    invoke GoScreen, S_SUMMARY
    ret
osPin:
    invoke GoScreen, S_PIN_OLD
    ret
osOut:
    call  DoLogout
osRet:
    ret
OnSoft ENDP
FillRc PROC hdc:DWORD, x1:DWORD, y1:DWORD, x2:DWORD, y2:DWORD, hbr:DWORD
    LOCAL rc:RECT
    mov   eax, x1
    mov   rc.left, eax
    mov   eax, y1
    mov   rc.top, eax
    mov   eax, x2
    mov   rc.right, eax
    mov   eax, y2
    mov   rc.bottom, eax
    invoke FillRect, hdc, addr rc, hbr
    ret
FillRc ENDP
OnPaint PROC hWnd:DWORD
    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:DWORD
    LOCAL rc:RECT
    LOCAL i:DWORD
    LOCAL flg:DWORD
    LOCAL pTxt:DWORD
    invoke BeginPaint, hWnd, addr ps
    mov   hdc, eax
    invoke SetBkMode, hdc, TRANSPARENT
    invoke FillRc, hdc, 0, 0, WIN_W, WIN_H, hBrBody
    invoke FillRc, hdc, 20, 10, 620, 56, hBrPanel
    invoke SelectObject, hdc, hFontTitle
    invoke SetTextColor, hdc, 00FFFFFFh
    mov   rc.left, 20
    mov   rc.top, 10
    mov   rc.right, 620
    mov   rc.bottom, 56
    invoke DrawText, hdc, addr txtTitle, -1, addr rc, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    invoke FillRc, hdc, 40, 64, 600, 330, hBrBezel
    invoke FillRc, hdc, SCR_L, SCR_T, SCR_R, SCR_B, hBrScreen
    invoke SelectObject, hdc, hFontScr
    mov   i, 0
opLine:
    cmp   i, NLINES
    jae   opLinesDone
    mov   eax, i
    imul  eax, eax, ROW_H
    add   eax, SCR_T
    mov   rc.top, eax
    add   eax, ROW_H
    mov   rc.bottom, eax
    mov   rc.left, SCR_L + 6
    mov   rc.right, SCR_R - 6
    mov   eax, COL_TEXT
    cmp   i, 0
    jne   opNotTitle
    mov   eax, COL_TITLE
    jmp   opSetClr
opNotTitle:
    cmp   curScreen, S_MESSAGE
    jne   opSetClr
    cmp   msgIsErr, 0
    je    opSetClr
    mov   eax, COL_ERR
opSetClr:
    invoke SetTextColor, hdc, eax
    mov   eax, i
    imul  eax, eax, LINE_LEN
    add   eax, OFFSET scrLines
    mov   pTxt, eax
    invoke DrawText, hdc, pTxt, -1, addr rc, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER
    inc   i
    jmp   opLine
opLinesDone:
    invoke SetTextColor, hdc, COL_SOFT
    mov   i, 0
opSoft:
    cmp   i, 8
    jae   opSoftDone
    mov   eax, i
    and   eax, 3
    shl   eax, 1
    inc   eax
    imul  eax, eax, ROW_H
    add   eax, SCR_T
    mov   rc.top, eax
    add   eax, ROW_H
    mov   rc.bottom, eax
    mov   rc.left, SCR_L + 6
    mov   rc.right, SCR_R - 6
    mov   flg, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER
    cmp   i, 4
    jb    opSoftDraw
    mov   flg, DT_RIGHT or DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER
opSoftDraw:
    mov   eax, i
    shl   eax, 4
    add   eax, OFFSET softLbl
    mov   pTxt, eax
    invoke DrawText, hdc, pTxt, -1, addr rc, flg
    inc   i
    jmp   opSoft
opSoftDone:
    invoke FillRc, hdc, 190, 358, 580, 590, hBrPanel
    invoke SelectObject, hdc, hFontSmall
    invoke SetTextColor, hdc, 00404040h
    mov   rc.left, 50
    mov   rc.top, 356
    mov   rc.right, 170
    mov   rc.bottom, 376
    invoke DrawText, hdc, addr txtCard, -1, addr rc, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX
    invoke FillRc, hdc, 50, 380, 170, 404, hBrSlot
    invoke FillRc, hdc, 56, 388, 68, 396, hBrCash
    mov   rc.top, 446
    mov   rc.bottom, 466
    invoke DrawText, hdc, addr txtReceipt, -1, addr rc, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX
    invoke FillRc, hdc, 50, 470, 170, 484, hBrSlot
    mov   rc.left, TRAY_L
    mov   rc.top, TRAY_T - 22
    mov   rc.right, TRAY_R
    mov   rc.bottom, TRAY_T - 2
    invoke DrawText, hdc, addr txtCashLbl, -1, addr rc, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX
    invoke FillRc, hdc, TRAY_L, TRAY_T, TRAY_R, TRAY_B, hBrSlot
    cmp   cashAmt, 0
    je    opNoCash
    invoke FillRc, hdc, TRAY_L + 20, TRAY_T + 8, TRAY_R - 20, TRAY_B - 8, hBrCash
    invoke wsprintf, addr trayBuf, addr fmtTray, cashAmt
    invoke SetTextColor, hdc, 0
    mov   rc.left, TRAY_L + 20
    mov   rc.top, TRAY_T + 8
    mov   rc.right, TRAY_R - 20
    mov   rc.bottom, TRAY_B - 8
    invoke DrawText, hdc, addr trayBuf, -1, addr rc, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
opNoCash:
    invoke EndPaint, hWnd, addr ps
    ret
OnPaint ENDP
MkBtn PROC parent:DWORD, pText:DWORD, id:DWORD, px:DWORD, py:DWORD, pw:DWORD, ph:DWORD
    invoke CreateWindowEx, 0, addr clsBtn, pText, WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON, px, py, pw, ph, parent, id, hInstance, NULL
    invoke SendMessage, eax, WM_SETFONT, hFontBtn, TRUE
    ret
MkBtn ENDP
WndProc PROC USES ebx esi edi hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL xPos:DWORD, yPos:DWORD, tPtr:DWORD
    mov   eax, uMsg
    cmp   eax, WM_CREATE
    je    wpCreate
    cmp   eax, WM_PAINT
    je    wpPaint
    cmp   eax, WM_ERASEBKGND
    je    wpErase
    cmp   eax, WM_COMMAND
    je    wpCommand
    cmp   eax, WM_CHAR
    je    wpChar
    cmp   eax, WM_LBUTTONDOWN
    je    wpClick
    cmp   eax, WM_DESTROY
    je    wpDestroy
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
wpCreate:
    mov   eax, hWnd
    mov   hMainWnd, eax
    invoke CreateSolidBrush, COL_BODY
    mov   hBrBody, eax
    invoke CreateSolidBrush, COL_PANEL
    mov   hBrPanel, eax
    invoke CreateSolidBrush, COL_BEZEL
    mov   hBrBezel, eax
    invoke CreateSolidBrush, COL_SCREEN
    mov   hBrScreen, eax
    invoke CreateSolidBrush, COL_SLOT
    mov   hBrSlot, eax
    invoke CreateSolidBrush, COL_CASH
    mov   hBrCash, eax
    invoke CreateFont, -16, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FIXED_PITCH or FF_MODERN, addr fontMono
    mov   hFontScr, eax
    invoke CreateFont, -30, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, VARIABLE_PITCH or FF_SWISS, addr fontSans
    mov   hFontTitle, eax
    invoke CreateFont, -14, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, VARIABLE_PITCH or FF_SWISS, addr fontSans
    mov   hFontSmall, eax
    invoke CreateFont, -20, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, VARIABLE_PITCH or FF_SWISS, addr fontSans
    mov   hFontBtn, eax
    xor   esi, esi
wcSoft:
    cmp   esi, 4
    jae   wcSoftDone
    mov   eax, esi
    imul  eax, eax, 48
    add   eax, 93
    mov   ebx, eax
    lea   ecx, [esi + 101]
    invoke MkBtn, hWnd, addr txtLt, ecx, 50, ebx, 70, 36
    lea   ecx, [esi + 105]
    invoke MkBtn, hWnd, addr txtGt, ecx, 520, ebx, 70, 36
    inc   esi
    jmp   wcSoft
wcSoftDone:
    mov   esi, 1
wcDig:
    cmp   esi, 9
    ja    wcDigDone
    mov   eax, esi
    dec   eax
    xor   edx, edx
    mov   ecx, 3
    div   ecx
    imul  eax, eax, 54
    add   eax, 370
    mov   yPos, eax
    imul  edx, edx, 80
    add   edx, 200
    mov   xPos, edx
    mov   eax, esi
    shl   eax, 1
    add   eax, OFFSET digitStr
    mov   tPtr, eax
    lea   ebx, [esi + 300]
    invoke MkBtn, hWnd, tPtr, ebx, xPos, yPos, 70, 44
    inc   esi
    jmp   wcDig
wcDigDone:
    invoke MkBtn, hWnd, addr digitStr, 300, 280, 532, 70, 44
    invoke MkBtn, hWnd, addr txtCancel, 312, 470, 370, 100, 44
    invoke MkBtn, hWnd, addr txtClear,  310, 470, 424, 100, 44
    invoke MkBtn, hWnd, addr txtEnter,  311, 470, 478, 100, 44
    call  BuildScreen
    xor   eax, eax
    ret
wpPaint:
    invoke OnPaint, hWnd
    xor   eax, eax
    ret
wpErase:
    mov   eax, 1
    ret
wpCommand:
    mov   eax, wParam
    and   eax, 0FFFFh
    cmp   eax, 101
    jb    wpCmdDone
    cmp   eax, 108
    jbe   wpCmdSoft
    cmp   eax, 300
    jb    wpCmdDone
    cmp   eax, 309
    jbe   wpCmdDigit
    cmp   eax, 310
    je    wpCmdClear
    cmp   eax, 311
    je    wpCmdEnter
    cmp   eax, 312
    je    wpCmdCancel
    jmp   wpCmdDone
wpCmdSoft:
    sub   eax, 101
    invoke OnSoft, eax
    jmp   wpCmdDone
wpCmdDigit:
    sub   eax, 300
    invoke AppendDigit, eax
    jmp   wpCmdDone
wpCmdClear:
    call  ClearInput
    call  Refresh
    jmp   wpCmdDone
wpCmdEnter:
    call  OnEnter
    jmp   wpCmdDone
wpCmdCancel:
    call  OnCancel
wpCmdDone:
    invoke SetFocus, hWnd
    xor   eax, eax
    ret
wpChar:
    mov   eax, wParam
    cmp   eax, '0'
    jb    wpCharOther
    cmp   eax, '9'
    ja    wpCharOther
    sub   eax, '0'
    invoke AppendDigit, eax
    jmp   wpZero
wpCharOther:
    cmp   eax, 8
    je    wpCharBs
    cmp   eax, 13
    je    wpCharEnter
    cmp   eax, 27
    je    wpCharEsc
    jmp   wpZero
wpCharBs:
    call  OnBackspace
    jmp   wpZero
wpCharEnter:
    call  OnEnter
    jmp   wpZero
wpCharEsc:
    call  OnCancel
    jmp   wpZero
wpClick:
    cmp   cashAmt, 0
    je    wpZero
    mov   eax, lParam
    movzx ecx, ax
    shr   eax, 16
    cmp   ecx, TRAY_L
    jb    wpZero
    cmp   ecx, TRAY_R
    ja    wpZero
    cmp   eax, TRAY_T
    jb    wpZero
    cmp   eax, TRAY_B
    ja    wpZero
    mov   cashAmt, 0
    invoke InvalidateRect, hWnd, NULL, FALSE
    jmp   wpZero
wpDestroy:
    invoke LogEvent, NO_ACCOUNT, addr actClose, 0, addr txtDash
    call  SaveData
    invoke DeleteObject, hBrBody
    invoke DeleteObject, hBrPanel
    invoke DeleteObject, hBrBezel
    invoke DeleteObject, hBrScreen
    invoke DeleteObject, hBrSlot
    invoke DeleteObject, hBrCash
    invoke DeleteObject, hFontScr
    invoke DeleteObject, hFontTitle
    invoke DeleteObject, hFontSmall
    invoke DeleteObject, hFontBtn
    invoke PostQuitMessage, 0
wpZero:
    xor   eax, eax
    ret
WndProc ENDP
WinMain PROC hInst:DWORD, hPrev:DWORD, cmdLine:DWORD, cmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL rc:RECT
    LOCAL winW:DWORD
    LOCAL winH:DWORD
    mov   wc.cbSize, SIZEOF WNDCLASSEX
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra, 0
    mov   wc.cbWndExtra, 0
    mov   eax, hInst
    mov   wc.hInstance, eax
    mov   wc.hbrBackground, NULL
    mov   wc.lpszMenuName, NULL
    mov   wc.lpszClassName, OFFSET clsName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov   wc.hIcon, eax
    mov   wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov   wc.hCursor, eax
    invoke RegisterClassEx, addr wc
    mov   rc.left, 0
    mov   rc.top, 0
    mov   rc.right, WIN_W
    mov   rc.bottom, WIN_H
    invoke AdjustWindowRect, addr rc, WIN_STYLE, FALSE
    mov   eax, rc.right
    sub   eax, rc.left
    mov   winW, eax
    mov   eax, rc.bottom
    sub   eax, rc.top
    mov   winH, eax
    invoke CreateWindowEx, 0, addr clsName, addr appTitle, WIN_STYLE, CW_USEDEFAULT, CW_USEDEFAULT, winW, winH, NULL, NULL, hInst, NULL
    invoke ShowWindow, eax, cmdShow
    invoke UpdateWindow, hMainWnd
msgLoop:
    invoke GetMessage, addr msg, NULL, 0, 0
    cmp   eax, 0
    je    msgDone
    invoke TranslateMessage, addr msg
    invoke DispatchMessage, addr msg
    jmp   msgLoop
msgDone:
    mov   eax, msg.wParam
    ret
WinMain ENDP
start:
    invoke GetModuleHandle, NULL
    mov   hInstance, eax
    call  LoadData
    call  SaveData
    invoke LogEvent, NO_ACCOUNT, addr actStart, 0, addr txtDash
    invoke WinMain, hInstance, NULL, NULL, SW_SHOWDEFAULT
    invoke ExitProcess, eax
END start
