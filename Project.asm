; ==================================================================
;  Simple ATM Banking System  -  x86 Assembly (MASM + Irvine32)
;  COAL Lab Project, Group BDS-3A-05          ** BOX / "ATM LOOK" EDITION **
;
;  Still a console program, but every screen is now drawn with real
;  coloured boxes (double-line borders, filled backgrounds):
;     body  : big blue ATM cabinet
;     title : black box with the screen name + account info
;     screen: green-on-black "monitor"
;     keys  : cyan button boxes ([1] Balance, [2] Deposit ...)
;     slots : card / receipt / cash slots at the bottom
;     paper : white receipt box,  green banknote boxes when cash comes out
;  Everything is drawn by 3 small Irvine32-based procedures:
;     DrawBox  (Gotoxy + SetTextColor + WriteChar)
;     PutText  (Gotoxy + SetTextColor + WriteString)
;     SetPos / NextLine  (Gotoxy, remembers the cursor row and column)
;
;  IRVINE32 is used for:
;    screen   : Clrscr, Gotoxy, SetTextColor, WriteString, WriteChar,
;               WriteDec     (all box drawing)
;    keyboard : ReadChar (keypad style, no Enter needed)
;    strings  : Str_copy, Str_length
;    random   : Randomize, RandomRange   (receipt reference number)
;    FILES    : CreateOutputFile, OpenInputFile, WriteToFile,
;               ReadFromFile, CloseFile   -> atm_data.dat (saved accounts)
;
;  WIN32 API (called directly with INVOKE) is used for:
;    GetLocalTime   : date and time for the log and the receipt
;    CreateFile, SetFilePointer, WriteFile, CloseHandle
;                   : APPEND a line to atm_log.txt (Irvine32 cannot append)
;    Sleep          : timing of the cash-dispensing animation
;    SetConsoleTitle: title of the console window
;
;  FILES:
;    atm_data.dat : balances, PINs, lock flags, totals, last-10 history.
;                   Saved after every change, loaded at start-up.
;    atm_log.txt  : one text line per action (login, wrong PIN, deposit,
;                   withdraw, transfer, PIN change, logout ...).
;
;  REGISTER RULES:
;    ESI = account index (0..4).  EAX = number in / out of a procedure.
;    LogEvent: ESI = account (or NO_ACCOUNT), EDX = action text,
;              EAX = amount, EBX = details text.
;
;  Demo accounts 1001..1005, PINs 1111 2222 3333 4444 5555
;  Console window needs at least 80 columns x 25 rows (the default).
; ==================================================================

INCLUDE Irvine32.inc

; ---------------- prototypes (INVOKE needs them before first use) ----
PutChars    PROTO :DWORD, :DWORD
PutText     PROTO :DWORD, :DWORD, :DWORD, :DWORD
SetPos      PROTO :DWORD, :DWORD
DrawBox     PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
DrawButtons PROTO :DWORD, :DWORD

; ---------------- constants ----------------
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

; ---------------- screen layout ----------------
SCR_X          EQU 11           ; first text column inside the green screen
SCR_TOP        EQU 6            ; first text row inside the green screen

; ---------------- colours = foreground + background * 16 ----------------
CLR_BODY       EQU white      + (blue      * 16)
CLR_TITLE      EQU yellow     + (black     * 16)
CLR_SCREEN     EQU lightGreen + (black     * 16)
CLR_BTN        EQU black      + (lightCyan * 16)
CLR_SLOT       EQU white      + (gray      * 16)
CLR_NOTE       EQU black      + (green     * 16)
CLR_PAPER      EQU black      + (white     * 16)
CLR_CARD       EQU black      + (yellow    * 16)
CLR_HINT       EQU yellow     + (blue      * 16)
CLR_ERR        EQU white      + (red       * 16)
CLR_INFO       EQU white      + (green     * 16)

; ==================================================================
.data

; ---------------- fixed data (never saved) ----------------
accNo           DWORD 1001, 1002, 1003, 1004, 1005
accName         BYTE "Ali Khan",0,    11 DUP(0)
                BYTE "Sara Ahmed",0,   9 DUP(0)
                BYTE "Bilal Raza",0,   9 DUP(0)
                BYTE "Hina Malik",0,   9 DUP(0)
                BYTE "Usman Ali",0,   10 DUP(0)

; ---------------- block saved to atm_data.dat ----------------
saveStart       LABEL BYTE
saveDay         DWORD 0                    ; date of last save (YYYYMMDD)
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

loadBuf         BYTE SAVE_SIZE + 16 DUP(0)
dataFile        BYTE "atm_data.dat",0
logFile         BYTE "atm_log.txt",0

; transaction type names, 16 bytes each (15 letters + 0)
typeNames       BYTE "Deposit        ",0
                BYTE "Withdrawal     ",0
                BYTE "Transfer Out   ",0
                BYTE "Transfer In    ",0

quickAmt        DWORD 500, 1000, 2000, 5000, 10000

; ---------------- session / working variables ----------------
curAcc          DWORD NO_ACCOUNT
inputOK         DWORD 0
inputLen        DWORD 0
maskInput       DWORD 0                  ; 1 = show * instead of digits
inputBuf        BYTE 16 DUP(0)
numBuf          BYTE 12 DUP(0)
msgBuf          BYTE 100 DUP(0)
outBuf          BYTE 512 DUP(0)

curRow          DWORD 0                  ; text cursor kept by SetPos / NextLine
curCol          DWORD 0
stmtRow         DWORD 0

rcTypeP         DWORD 0
rcAmt           DWORD 0
rcFee           DWORD 0
rcDest          DWORD 0
detNum          DWORD 0
detFee          DWORD 0

; ---------------- screen titles ----------------
appTitle        BYTE "Simple ATM Banking System - COAL Project",0
titleLogin      BYTE "SIMPLE ATM BANKING SYSTEM",0
titleDash       BYTE "DASHBOARD",0
titleDeposit    BYTE "CASH DEPOSIT",0
titleWithdraw   BYTE "CASH WITHDRAWAL",0
titleTransfer   BYTE "FUND TRANSFER",0
titleStatement  BYTE "MINI STATEMENT",0
titleSummary    BYTE "ACCOUNT SUMMARY",0
titlePin        BYTE "CHANGE PIN",0
titleReceipt    BYTE "TRANSACTION RECEIPT",0

; ---------------- text on screen ----------------
txtNoCard       BYTE "Please insert your card",0
txtBalShort     BYTE "Balance Rs. ",0
txtSlotCard     BYTE "CARD",0
txtSlotRcpt     BYTE "RECEIPT",0
txtSlotCash     BYTE "CASH",0

txtWelcome      BYTE "Welcome to the Simple ATM",0
txtZeroExit     BYTE "(enter 0 as account number to exit)",0
txtDemo         BYTE "Demo accounts: 1001 to 1005",0
txtCardT1       BYTE "DEBIT CARD",0
txtCardT2       BYTE "**** **** ****",0
txtCardT3       BYTE "SIMPLE BANK",0
txtHintLogin    BYTE "Use the keyboard: digits, Backspace and Enter",0
askAcc          BYTE "Account number : ",0
askPin          BYTE "4-digit PIN    : ",0

txtHolder       BYTE "Account holder : ",0
txtAccNo        BYTE "Account number : ",0
txtBalance      BYTE "Balance (Rs.)  : ",0
txtDeposits     BYTE "Total deposits : ",0
txtWithdrawn    BYTE "Total withdrawn: ",0
txtTxns         BYTE "Transactions   : ",0

; menu buttons
btn1            BYTE "[1] Balance Inquiry",0
btn2            BYTE "[2] Cash Deposit",0
btn3            BYTE "[3] Cash Withdrawal",0
btn4            BYTE "[4] Fund Transfer",0
btn5            BYTE "[5] Mini Statement",0
btn6            BYTE "[6] Account Summary",0
btn7            BYTE "[7] Change PIN",0
btn8            BYTE "[8] Logout",0
menuTable       DWORD OFFSET btn1, OFFSET btn2, OFFSET btn3, OFFSET btn4
                DWORD OFFSET btn5, OFFSET btn6, OFFSET btn7, OFFSET btn8

; withdraw buttons
qb1             BYTE "[1] Rs. 500",0
qb2             BYTE "[2] Rs. 1000",0
qb3             BYTE "[3] Rs. 2000",0
qb4             BYTE "[4] Rs. 5000",0
qb5             BYTE "[5] Rs. 10000",0
qb6             BYTE "[6] Other amount",0
qb0             BYTE "[0] Cancel",0
quickTable      DWORD OFFSET qb1, OFFSET qb2, OFFSET qb3, OFFSET qb4
                DWORD OFFSET qb5, OFFSET qb6, OFFSET qb0

txtHintMenu     BYTE "Press the number key of your choice (1-8)",0
txtHintQuick    BYTE "Press 1-5 for a quick amount, 6 for other, 0 to cancel",0
txtPress        BYTE "Press any key to continue...",0
txtAnyKey       BYTE "[ press any key ]",0
txtYesNo        BYTE "[Y] Yes     [N] No",0

askDeposit      BYTE "Amount to deposit (Rs. 1 - 100000): ",0
askWithdraw     BYTE "Amount to withdraw (multiple of 100): ",0
askOther        BYTE "Amount: ",0
askDest         BYTE "Destination account number: ",0
askTrfAmount    BYTE "Amount to transfer: ",0
txtFeeNote      BYTE "Transfer fee: 1 percent (minimum Rs. 10)",0
askOldPin       BYTE "Current PIN       : ",0
askNewPin       BYTE "New 4-digit PIN   : ",0
askConfirmPin   BYTE "Confirm new PIN   : ",0

txtStmtHead     BYTE "Type", 14 DUP(' '), "Amount", 7 DUP(' '), "Balance after",0
txtStmtLine     BYTE "---------------------------------------------",0
txtNoTxn        BYTE "No transactions yet.",0

txtCounting     BYTE "Counting your cash",0
txtNote         BYTE "***   Rs. NOTE   ***",0
txtTakeCash     BYTE "*** PLEASE TAKE YOUR CASH ***",0

txtRcHead       BYTE "       ** SIMPLE ATM **",0
txtRef          BYTE "Reference no   : ",0
txtDateTime     BYTE "Date / Time    : ",0
txtTxType       BYTE "Transaction    : ",0
txtAmount       BYTE "Amount (Rs.)   : ",0
txtFee          BYTE "Fee (Rs.)      : ",0
txtToAcc        BYTE "To account     : ",0
txtThanks       BYTE "Thank you for using Simple ATM",0

; ---------------- popup box texts ----------------
msgBalance      BYTE "Your balance is Rs. ",0
msgPinOk        BYTE "PIN changed successfully.",0
askLogout       BYTE "Do you want to log out?",0

errNotNumber    BYTE "Please type digits only (0-9).",0
errZero         BYTE "The amount must be greater than zero.",0
errNoAccount    BYTE "Account number not found.",0
errLocked       BYTE "This account is locked (3 wrong PINs).",0
errWrongPin     BYTE "Wrong PIN. Attempts left: ",0
errNowLocked    BYTE "3 wrong PINs. This account is now locked.",0
errMenu         BYTE "Unknown option. Please choose 1 to 8.",0
errKey          BYTE "Unknown option.",0
errTooBig       BYTE "Maximum deposit is Rs. 100000.",0
errOverflow     BYTE "Balance is too large to add this amount.",0
errNotHundred   BYTE "Amount must be a multiple of Rs. 100.",0
errNoFunds      BYTE "Insufficient balance.",0
errDayLimit     BYTE "Daily withdrawal limit (Rs. 20000) exceeded.",0
errNoDest       BYTE "Destination account not found.",0
errSelf         BYTE "You cannot transfer to your own account.",0
errNoFundsFee   BYTE "Insufficient balance (amount + fee).",0
errOldPin       BYTE "Current PIN is wrong.",0
errNewPin       BYTE "New PIN must be 4 digits (1000 to 9999).",0
errNoMatch      BYTE "New PIN and confirmation do not match.",0

; ---------------- log file pieces ----------------
sOpenB          BYTE "[",0
sCloseB         BYTE "] ",0
sOpenP          BYTE " (",0
sCloseP         BYTE ") | ",0
sBar            BYTE " | ",0
sMinus          BYTE "-",0
sSpace          BYTE " ",0
sColon          BYTE ":",0
sZero           BYTE "0",0
sCrlf           BYTE 0Dh,0Ah,0
lgAcc           BYTE "Acc ",0
lgAmt           BYTE " | Amt Rs.",0
lgBal           BYTE " | Bal Rs.",0
lgNoAcc         BYTE "No account | ",0
lgFee           BYTE ", fee Rs.",0

txtDash         BYTE "-",0
txtToAcc2       BYTE "to acc ",0
txtFromAcc      BYTE "from acc ",0
txtBadPin       BYTE "wrong PIN entered",0
txtLockedDet    BYTE "account is locked",0
txtUnknownAcc   BYTE "unknown account number typed",0
txtWrongOld     BYTE "wrong current PIN",0

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

; ==================================================================
.code

; ------------------------------------------------------------------
;  SECTION 1 : BOX DRAWING  (Irvine32: Gotoxy, SetTextColor, WriteChar)
; ------------------------------------------------------------------

; PutChars : writes the character theChar, cnt times, at the cursor.
PutChars PROC USES eax, theChar:DWORD, cnt:DWORD
    LOCAL n:DWORD
    mov  eax, cnt
    mov  n, eax
pcLoop:
    cmp  n, 0
    jle  pcDone
    mov  eax, theChar
    call WriteChar
    dec  n
    jmp  pcLoop
pcDone:
    ret
PutChars ENDP

; DrawBox : double-line box, filled with spaces, in colour boxC.
;   boxX, boxY = top-left corner,  boxW, boxH = size in characters.
;   Box characters (code page 437):  C9 = top-left   BB = top-right
;   C8 = bottom-left  BC = bottom-right  CD = horizontal  BA = vertical
DrawBox PROC USES eax ebx ecx edx, boxX:DWORD, boxY:DWORD, boxW:DWORD, boxH:DWORD, boxC:DWORD
    LOCAL r:DWORD
    mov  eax, boxC
    call SetTextColor

    ; ---- top edge ----
    mov  dl, BYTE PTR boxX
    mov  dh, BYTE PTR boxY
    call Gotoxy
    mov  al, 0C9h
    call WriteChar
    mov  ecx, boxW
    sub  ecx, 2
    INVOKE PutChars, 0CDh, ecx
    mov  al, 0BBh
    call WriteChar

    ; ---- middle rows : | spaces | ----
    mov  r, 1
dbRow:
    mov  eax, boxH
    dec  eax
    cmp  r, eax
    jae  dbBottom
    mov  eax, boxY
    add  eax, r
    mov  dh, al
    mov  dl, BYTE PTR boxX
    call Gotoxy
    mov  al, 0BAh
    call WriteChar
    mov  ecx, boxW
    sub  ecx, 2
    INVOKE PutChars, ' ', ecx
    mov  al, 0BAh
    call WriteChar
    inc  r
    jmp  dbRow

    ; ---- bottom edge ----
dbBottom:
    mov  eax, boxY
    add  eax, boxH
    dec  eax
    mov  dh, al
    mov  dl, BYTE PTR boxX
    call Gotoxy
    mov  al, 0C8h
    call WriteChar
    mov  ecx, boxW
    sub  ecx, 2
    INVOKE PutChars, 0CDh, ecx
    mov  al, 0BCh
    call WriteChar
    ret
DrawBox ENDP

; PutText : writes the text at (textX, textY) in colour textC.
PutText PROC USES eax edx, textX:DWORD, textY:DWORD, textP:DWORD, textC:DWORD
    mov  eax, textC
    call SetTextColor
    mov  dl, BYTE PTR textX
    mov  dh, BYTE PTR textY
    call Gotoxy
    mov  edx, textP
    call WriteString
    ret
PutText ENDP

; SetPos : moves the cursor to (pcol, prow) and remembers it.
SetPos PROC USES eax edx, pcol:DWORD, prow:DWORD
    mov  eax, pcol
    mov  curCol, eax
    mov  eax, prow
    mov  curRow, eax
    mov  dl, BYTE PTR curCol
    mov  dh, BYTE PTR curRow
    call Gotoxy
    ret
SetPos ENDP

; NextLine : like Crlf, but goes back to the remembered column (curCol),
;   so the text stays inside the box.
NextLine PROC USES eax edx
    inc  curRow
    mov  dl, BYTE PTR curCol
    mov  dh, BYTE PTR curRow
    call Gotoxy
    ret
NextLine ENDP

; ScrReset : green screen colour, cursor at the top-left of the screen.
ScrReset PROC USES eax
    mov  eax, CLR_SCREEN
    call SetTextColor
    INVOKE SetPos, SCR_X, SCR_TOP
    ret
ScrReset ENDP

; DrawButtons : draws button boxes in two columns of 4.
;   pTable = address of a table of text addresses, cnt = number of buttons.
DrawButtons PROC USES eax ebx ecx edx esi, pTable:DWORD, cnt:DWORD
    xor  esi, esi
dbtLoop:
    cmp  esi, cnt
    jae  dbtDone
    mov  eax, esi
    shr  eax, 2                      ; 0 = left column, 1 = right column
    imul eax, eax, 32
    add  eax, 10                     ; EAX = x
    mov  ebx, esi
    and  ebx, 3                      ; row inside the column
    imul ebx, ebx, 3
    add  ebx, 6                      ; EBX = y
    mov  ecx, pTable
    mov  ecx, [ecx + esi*4]          ; ECX = address of the button text
    INVOKE DrawBox, eax, ebx, 28, 3, CLR_BTN
    inc  ebx
    add  eax, 2
    INVOKE PutText, eax, ebx, ecx, CLR_BTN
    inc  esi
    jmp  dbtLoop
dbtDone:
    ret
DrawButtons ENDP

; ------------------------------------------------------------------
;  SECTION 2 : SMALL HELPERS
; ------------------------------------------------------------------

; NumToText : EAX = number.  Puts the digits as text in numBuf.
NumToText PROC USES eax ebx edx esi edi
    mov  edi, OFFSET numBuf
    add  edi, 11
    mov  BYTE PTR [edi], 0
    mov  ebx, 10
ntLoop:
    mov  edx, 0
    div  ebx
    add  dl, '0'
    dec  edi
    mov  [edi], dl
    cmp  eax, 0
    jne  ntLoop
    INVOKE Str_copy, edi, OFFSET numBuf
    ret
NumToText ENDP

; AppendStr : EDX = text.  Adds it to the end of outBuf.
AppendStr PROC USES eax edi
    INVOKE Str_length, OFFSET outBuf
    mov  edi, OFFSET outBuf
    add  edi, eax
    INVOKE Str_copy, edx, edi
    ret
AppendStr ENDP

; AppendNum : EAX = number.  Adds its digits to outBuf.
AppendNum PROC USES eax edx
    call NumToText
    mov  edx, OFFSET numBuf
    call AppendStr
    ret
AppendNum ENDP

; AppendNum2 : EAX = number (0..99).  Adds it with 2 digits (05, 12 ...).
AppendNum2 PROC USES eax edx
    cmp  eax, 10
    jae  an2Go
    push eax
    mov  edx, OFFSET sZero
    call AppendStr
    pop  eax
an2Go:
    call AppendNum
    ret
AppendNum2 ENDP

; BuildStamp : adds "YYYY-MM-DD HH:MM:SS" (local time) to outBuf.
;   Uses the Win32 API GetLocalTime.
BuildStamp PROC USES eax edx
    LOCAL stm:SYSTEMTIME
    INVOKE GetLocalTime, ADDR stm
    movzx eax, stm.wYear
    call AppendNum
    mov  edx, OFFSET sMinus
    call AppendStr
    movzx eax, stm.wMonth
    call AppendNum2
    mov  edx, OFFSET sMinus
    call AppendStr
    movzx eax, stm.wDay
    call AppendNum2
    mov  edx, OFFSET sSpace
    call AppendStr
    movzx eax, stm.wHour
    call AppendNum2
    mov  edx, OFFSET sColon
    call AppendStr
    movzx eax, stm.wMinute
    call AppendNum2
    mov  edx, OFFSET sColon
    call AppendStr
    movzx eax, stm.wSecond
    call AppendNum2
    ret
BuildStamp ENDP

; GetToday : returns EAX = YYYYMMDD
GetToday PROC USES ecx
    LOCAL stm:SYSTEMTIME
    INVOKE GetLocalTime, ADDR stm
    movzx eax, stm.wYear
    imul eax, eax, 10000
    movzx ecx, stm.wMonth
    imul ecx, ecx, 100
    add  eax, ecx
    movzx ecx, stm.wDay
    add  eax, ecx
    ret
GetToday ENDP

; ShowLine : EDX = label text, EAX = number.   Prints "label number".
ShowLine PROC USES eax edx
    call WriteString
    call WriteDec
    call NextLine
    ret
ShowLine ENDP

; PrintName : ESI = account index.  Prints that account holder's name.
PrintName PROC USES eax edx
    mov  eax, esi
    mov  edx, NAME_LEN
    mul  edx
    mov  edx, OFFSET accName
    add  edx, eax
    call WriteString
    ret
PrintName ENDP

; DrawFrame : EDX = screen title.  Draws the whole ATM:
;   blue body, title box (title + account info), green screen,
;   and the card / receipt / cash slots.  Leaves the cursor at the
;   top-left of the green screen, ready for text.
DrawFrame PROC USES eax ebx ecx edx esi edi
    mov  esi, edx                    ; ESI = title text
    mov  eax, white
    call SetTextColor
    call Clrscr
    INVOKE DrawBox, 6, 0, 68, 24, CLR_BODY
    INVOKE DrawBox, 8, 1, 64, 4, CLR_TITLE
    INVOKE DrawBox, 8, 5, 64, 14, CLR_SCREEN
    INVOKE DrawBox, 10, 20, 18, 3, CLR_SLOT
    INVOKE DrawBox, 31, 20, 18, 3, CLR_SLOT
    INVOKE DrawBox, 52, 20, 18, 3, CLR_SLOT
    INVOKE PutText, 17, 21, OFFSET txtSlotCard, CLR_SLOT
    INVOKE PutText, 36, 21, OFFSET txtSlotRcpt, CLR_SLOT
    INVOKE PutText, 59, 21, OFFSET txtSlotCash, CLR_SLOT

    ; ---- title, centred in the title box (inside width = 62) ----
    INVOKE Str_length, esi           ; EAX = length of the title
    mov  ecx, 62
    sub  ecx, eax
    shr  ecx, 1
    add  ecx, 9
    INVOKE PutText, ecx, 2, esi, CLR_TITLE

    ; ---- second title line: account info (or "insert card") ----
    cmp  curAcc, NO_ACCOUNT
    je   dfNoCard
    mov  edi, curAcc
    mov  BYTE PTR outBuf, 0
    mov  eax, edi
    mov  edx, NAME_LEN
    mul  edx
    add  eax, OFFSET accName
    mov  edx, eax
    call AppendStr                   ; name
    mov  edx, OFFSET sBar
    call AppendStr
    mov  edx, OFFSET lgAcc
    call AppendStr                   ; "Acc "
    mov  eax, [accNo + edi*4]
    call AppendNum
    mov  edx, OFFSET sBar
    call AppendStr
    mov  edx, OFFSET txtBalShort
    call AppendStr
    mov  eax, [accBal + edi*4]
    call AppendNum
    INVOKE PutText, 10, 3, OFFSET outBuf, CLR_TITLE
    jmp  dfDone
dfNoCard:
    INVOKE PutText, 10, 3, OFFSET txtNoCard, CLR_TITLE
dfDone:
    call ScrReset
    ret
DrawFrame ENDP

; PopBox : EDX = text, EAX = colour.  Centred message box with the text
;   and "[ press any key ]".  Waits for a key.
PopBox PROC USES eax ebx ecx edx esi
    mov  esi, edx
    mov  ebx, eax
    INVOKE DrawBox, 14, 9, 52, 5, ebx
    INVOKE Str_length, esi
    mov  ecx, 50
    sub  ecx, eax
    shr  ecx, 1
    add  ecx, 15
    INVOKE PutText, ecx, 11, esi, ebx
    INVOKE PutText, 31, 12, OFFSET txtAnyKey, ebx
    call ReadChar
    ret
PopBox ENDP

; ShowError : EDX = text.  Red popup box.
ShowError PROC USES eax
    mov  eax, CLR_ERR
    call PopBox
    ret
ShowError ENDP

; ShowInfo : EDX = text.  Green popup box.
ShowInfo PROC USES eax
    mov  eax, CLR_INFO
    call PopBox
    ret
ShowInfo ENDP

; MsgNumber : EDX = text, EAX = number.  Green popup "text number".
MsgNumber PROC USES eax ebx ecx edx esi edi
    push eax
    mov  BYTE PTR outBuf, 0
    call AppendStr                   ; EDX = text
    pop  eax
    call AppendNum
    mov  edx, OFFSET outBuf
    mov  eax, CLR_INFO
    call PopBox
    ret
MsgNumber ENDP

; ConfirmLogout : popup with Yes / No.  Returns EAX = 1 (yes) or 0 (no).
ConfirmLogout PROC USES ebx ecx edx
    INVOKE DrawBox, 14, 9, 52, 5, CLR_INFO
    INVOKE PutText, 28, 11, OFFSET askLogout, CLR_INFO
    INVOKE PutText, 31, 12, OFFSET txtYesNo, CLR_INFO
alKey:
    call ReadChar
    cmp  al, 'y'
    je   alYes
    cmp  al, 'Y'
    je   alYes
    cmp  al, 'n'
    je   alNo
    cmp  al, 'N'
    je   alNo
    jmp  alKey
alYes:
    mov  eax, 1
    ret
alNo:
    mov  eax, 0
    ret
ConfirmLogout ENDP

; PressKey : hint line below the screen, then waits for a key.
PressKey PROC USES eax edx
    INVOKE PutText, 10, 19, OFFSET txtPress, CLR_HINT
    call ReadChar
    ret
PressKey ENDP

; ReadNumber : keypad-style input with ReadChar (digits, Backspace, Enter).
;   If maskInput = 1 every digit is shown as '*'  (used for PINs).
;   Returns EAX = number, inputOK = 1 if something was typed.
ReadNumber PROC USES ebx ecx edx esi
    mov  inputOK, 0
    mov  inputLen, 0
rnKey:
    call ReadChar                    ; AL = key pressed (not shown)
    cmp  al, 13
    je   rnEnter
    cmp  al, 8
    je   rnBack
    cmp  al, '0'
    jb   rnKey
    cmp  al, '9'
    ja   rnKey
    mov  ecx, inputLen
    cmp  ecx, 9                      ; at most 9 digits (no overflow)
    jae  rnKey
    mov  [inputBuf + ecx], al
    inc  inputLen
    cmp  maskInput, 0
    je   rnEcho
    mov  al, '*'
rnEcho:
    call WriteChar
    jmp  rnKey
rnBack:
    cmp  inputLen, 0
    je   rnKey
    dec  inputLen
    mov  al, 8                       ; erase the last character on screen
    call WriteChar
    mov  al, ' '
    call WriteChar
    mov  al, 8
    call WriteChar
    jmp  rnKey
rnEnter:
    call NextLine
    cmp  inputLen, 0
    je   rnBad
    mov  ecx, inputLen
    mov  BYTE PTR [inputBuf + ecx], 0
    xor  eax, eax                    ; EAX = number being built
    mov  esi, OFFSET inputBuf
rnConv:
    movzx ebx, BYTE PTR [esi]
    sub  ebx, '0'
    mov  edx, 10
    mul  edx
    add  eax, ebx
    inc  esi
    loop rnConv
    mov  inputOK, 1
    ret
rnBad:
    xor  eax, eax
    ret
ReadNumber ENDP

; ReadAmount : EDX = prompt text.  Returns EAX = amount, or 0 if bad
;   (the error message has already been shown in that case).
ReadAmount PROC USES edx
    call WriteString
    call ReadNumber
    cmp  inputOK, 0
    je   raNotNumber
    cmp  eax, 0
    je   raZero
    ret
raNotNumber:
    mov  edx, OFFSET errNotNumber
    call ShowError
    mov  eax, 0
    ret
raZero:
    mov  edx, OFFSET errZero
    call ShowError
    mov  eax, 0
    ret
ReadAmount ENDP

; FindAccount : EAX = account number.  Returns EAX = index or NO_ACCOUNT.
FindAccount PROC USES ebx ecx esi
    mov  ebx, eax
    mov  esi, OFFSET accNo
    mov  ecx, 0
faLoop:
    cmp  ecx, NUM_ACC
    jae  faNotFound
    cmp  ebx, [esi + ecx*4]
    je   faFound
    inc  ecx
    jmp  faLoop
faFound:
    mov  eax, ecx
    ret
faNotFound:
    mov  eax, NO_ACCOUNT
    ret
FindAccount ENDP

; CalcFee : EAX = amount.  Returns EAX = fee (1 %, at least Rs. 10).
CalcFee PROC USES ebx edx
    mov  ebx, FEE_PERCENT
    mul  ebx
    mov  ebx, 100
    mov  edx, 0
    div  ebx
    cmp  eax, MIN_FEE
    jae  cfDone
    mov  eax, MIN_FEE
cfDone:
    ret
CalcFee ENDP

; AddHistory : ESI = account, EBX = type (1..4), EAX = amount.
AddHistory PROC USES eax ecx edx
    mov  ecx, histNext
    mov  [histAcc  + ecx*4], esi
    mov  [histType + ecx*4], ebx
    mov  [histAmt  + ecx*4], eax
    mov  edx, [accBal + esi*4]
    mov  [histBal  + ecx*4], edx
    inc  ecx
    cmp  ecx, HIST_MAX
    jb   ahStore
    mov  ecx, 0
ahStore:
    mov  histNext, ecx
    cmp  histCount, HIST_MAX
    jae  ahDone
    inc  histCount
ahDone:
    ret
AddHistory ENDP

; ------------------------------------------------------------------
;  SECTION 3 : FILING
; ------------------------------------------------------------------

; SaveData : writes the whole saveStart..saveEnd block to atm_data.dat
SaveData PROC USES eax ebx ecx edx
    call GetToday
    mov  saveDay, eax
    mov  edx, OFFSET dataFile
    call CreateOutputFile            ; EAX = file handle
    cmp  eax, INVALID_HANDLE_VALUE
    je   sdDone
    mov  ebx, eax
    mov  edx, OFFSET saveStart
    mov  ecx, SAVE_SIZE
    call WriteToFile
    mov  eax, ebx
    call CloseFile
sdDone:
    ret
SaveData ENDP

; LoadData : reads atm_data.dat if it exists and has the right size.
LoadData PROC USES eax ebx ecx edx esi edi
    mov  edx, OFFSET dataFile
    call OpenInputFile
    cmp  eax, INVALID_HANDLE_VALUE
    je   ldCheckDay
    mov  ebx, eax
    mov  edx, OFFSET loadBuf
    mov  ecx, SAVE_SIZE + 16
    call ReadFromFile                ; EAX = bytes read, CF = error
    jc   ldClose
    cmp  eax, SAVE_SIZE
    jne  ldClose
    cld
    mov  esi, OFFSET loadBuf
    mov  edi, OFFSET saveStart
    mov  ecx, SAVE_SIZE
    rep  movsb
    cmp  histNext, HIST_MAX
    jae  ldBadHist
    cmp  histCount, HIST_MAX
    jbe  ldClose
ldBadHist:
    mov  histNext, 0
    mov  histCount, 0
ldClose:
    mov  eax, ebx
    call CloseFile
ldCheckDay:
    call GetToday
    cmp  eax, saveDay
    je   ldDone
    mov  saveDay, eax
    mov  edi, OFFSET accDayWithdrawn
    mov  ecx, NUM_ACC
    xor  eax, eax
    rep  stosd
ldDone:
    ret
LoadData ENDP

; LogEvent : appends ONE line to atm_log.txt.
;   ESI = account index (or NO_ACCOUNT), EDX = action text,
;   EAX = amount (0 if none), EBX = details text.
LogEvent PROC USES eax ebx ecx edx esi edi
    LOCAL hFile:DWORD
    LOCAL written:DWORD
    LOCAL vAct:DWORD
    LOCAL vAmt:DWORD
    LOCAL vDet:DWORD
    LOCAL vAcc:DWORD

    mov  vAct, edx
    mov  vAmt, eax
    mov  vDet, ebx
    mov  vAcc, esi

    mov  BYTE PTR outBuf, 0
    mov  edx, OFFSET sOpenB
    call AppendStr
    call BuildStamp
    mov  edx, OFFSET sCloseB
    call AppendStr

    cmp  vAcc, NO_ACCOUNT
    je   leNoAcc
    mov  esi, vAcc
    mov  edx, OFFSET lgAcc
    call AppendStr
    mov  eax, [accNo + esi*4]
    call AppendNum
    mov  edx, OFFSET sOpenP
    call AppendStr
    mov  eax, esi
    mov  edx, NAME_LEN
    mul  edx
    add  eax, OFFSET accName
    mov  edx, eax
    call AppendStr
    mov  edx, OFFSET sCloseP
    call AppendStr
    mov  edx, vAct
    call AppendStr
    mov  edx, OFFSET lgAmt
    call AppendStr
    mov  eax, vAmt
    call AppendNum
    mov  edx, OFFSET lgBal
    call AppendStr
    mov  esi, vAcc
    mov  eax, [accBal + esi*4]
    call AppendNum
    jmp  leDetail
leNoAcc:
    mov  edx, OFFSET lgNoAcc
    call AppendStr
    mov  edx, vAct
    call AppendStr
leDetail:
    mov  edx, OFFSET sBar
    call AppendStr
    mov  edx, vDet
    call AppendStr
    cmp  detNum, 0
    je   leNoNum
    mov  eax, detNum
    call AppendNum
leNoNum:
    cmp  detFee, 0
    je   leNoFee
    mov  edx, OFFSET lgFee
    call AppendStr
    mov  eax, detFee
    call AppendNum
leNoFee:
    mov  detNum, 0
    mov  detFee, 0
    mov  edx, OFFSET sCrlf
    call AppendStr

    ; ---- Win32 API: open the file, jump to the end, write, close ----
    INVOKE CreateFile, OFFSET logFile, GENERIC_WRITE, FILE_SHARE_READ, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp  eax, INVALID_HANDLE_VALUE
    je   leDone
    mov  hFile, eax
    INVOKE SetFilePointer, hFile, 0, 0, FILE_END
    INVOKE Str_length, OFFSET outBuf
    mov  ebx, eax
    INVOKE WriteFile, hFile, OFFSET outBuf, ebx, ADDR written, 0
    INVOKE CloseHandle, hFile
leDone:
    ret
LogEvent ENDP

; ------------------------------------------------------------------
;  SECTION 4 : ATM EFFECTS  (cash animation and receipt)
; ------------------------------------------------------------------

; DispenseCash : animation.  Boxes + colours (Irvine32), Sleep (Win32).
DispenseCash PROC USES eax ebx ecx edx esi
    mov  edx, OFFSET titleWithdraw
    call DrawFrame
    INVOKE PutText, SCR_X, 6, OFFSET txtCounting, CLR_SCREEN
    mov  esi, 5
dcDots:
    mov  al, '.'
    call WriteChar
    INVOKE Sleep, 350                ; Win32 API
    dec  esi
    jnz  dcDots

    xor  esi, esi                    ; three banknote boxes, one by one
dcNote:
    mov  ebx, esi
    imul ebx, ebx, 3
    add  ebx, 8                      ; y = 8, 11, 14
    INVOKE DrawBox, 26, ebx, 22, 3, CLR_NOTE
    inc  ebx
    INVOKE PutText, 28, ebx, OFFSET txtNote, CLR_NOTE
    INVOKE Sleep, 400
    inc  esi
    cmp  esi, 3
    jb   dcNote

    INVOKE DrawBox, 52, 20, 18, 3, CLR_NOTE      ; cash slot turns green
    INVOKE PutText, 59, 21, OFFSET txtSlotCash, CLR_NOTE
    INVOKE PutText, 21, 17, OFFSET txtTakeCash, CLR_SCREEN
    call PressKey
    ret
DispenseCash ENDP

; ShowReceipt : paper-coloured box.  Uses rcTypeP, rcAmt, rcFee, rcDest.
ShowReceipt PROC USES eax edx esi
    mov  edx, OFFSET titleReceipt
    call DrawFrame
    INVOKE DrawBox, 18, 6, 44, 12, CLR_PAPER
    mov  eax, CLR_PAPER
    call SetTextColor

    INVOKE SetPos, 21, 7
    mov  edx, OFFSET txtRcHead
    call WriteString

    mov  eax, 900000                 ; random 6-digit reference number
    call RandomRange
    add  eax, 100000
    INVOKE SetPos, 21, 8
    mov  edx, OFFSET txtRef
    call ShowLine

    INVOKE SetPos, 21, 9
    mov  edx, OFFSET txtDateTime
    call WriteString
    mov  BYTE PTR outBuf, 0
    call BuildStamp
    mov  edx, OFFSET outBuf
    call WriteString

    mov  esi, curAcc
    INVOKE SetPos, 21, 10
    mov  edx, OFFSET txtAccNo
    mov  eax, [accNo + esi*4]
    call ShowLine

    INVOKE SetPos, 21, 11
    mov  edx, OFFSET txtTxType
    call WriteString
    mov  edx, rcTypeP
    call WriteString

    INVOKE SetPos, 21, 12
    mov  edx, OFFSET txtAmount
    mov  eax, rcAmt
    call ShowLine

    cmp  rcFee, 0
    je   rcNoFee
    INVOKE SetPos, 21, 13
    mov  edx, OFFSET txtFee
    mov  eax, rcFee
    call ShowLine
rcNoFee:
    cmp  rcDest, 0
    je   rcNoDest
    INVOKE SetPos, 21, 14
    mov  edx, OFFSET txtToAcc
    mov  eax, rcDest
    call ShowLine
rcNoDest:
    INVOKE SetPos, 21, 15
    mov  edx, OFFSET txtBalance
    mov  eax, [accBal + esi*4]
    call ShowLine

    INVOKE SetPos, 21, 16
    mov  edx, OFFSET txtThanks
    call WriteString
    call PressKey
    ret
ShowReceipt ENDP

; ------------------------------------------------------------------
;  SECTION 5 : LOGIN
; ------------------------------------------------------------------

; LoginScreen : returns EAX = 1 if somebody logged in, 0 to exit.
LoginScreen PROC USES ebx ecx edx esi
loginAgain:
    mov  edx, OFFSET titleLogin
    call DrawFrame
    INVOKE DrawBox, 50, 6, 19, 6, CLR_CARD       ; the "bank card"
    INVOKE PutText, 52, 7, OFFSET txtCardT1, CLR_CARD
    INVOKE PutText, 52, 9, OFFSET txtCardT2, CLR_CARD
    INVOKE PutText, 52, 10, OFFSET txtCardT3, CLR_CARD
    INVOKE PutText, 10, 19, OFFSET txtHintLogin, CLR_HINT
    call ScrReset
    mov  edx, OFFSET txtWelcome
    call WriteString
    INVOKE SetPos, SCR_X, 8
    mov  edx, OFFSET txtZeroExit
    call WriteString
    INVOKE SetPos, SCR_X, 15
    mov  edx, OFFSET txtDemo
    call WriteString

    INVOKE SetPos, SCR_X, 10
    mov  edx, OFFSET askAcc
    call WriteString
    mov  maskInput, 0
    call ReadNumber
    cmp  inputOK, 0
    je   loginNotNumber
    cmp  eax, 0
    je   loginExit
    call FindAccount
    cmp  eax, NO_ACCOUNT
    je   loginNoAccount
    mov  esi, eax

    mov  eax, [accLocked + esi*4]
    test eax, 1
    jnz  loginIsLocked

    INVOKE SetPos, SCR_X, 12
    mov  edx, OFFSET askPin
    call WriteString
    mov  maskInput, 1                ; PIN is shown as ****
    call ReadNumber
    mov  maskInput, 0
    cmp  inputOK, 0
    je   loginNotNumber
    cmp  eax, [accPin + esi*4]
    jne  loginWrongPin

    ; ---- success ----
    mov  DWORD PTR [accAttempts + esi*4], 0
    mov  curAcc, esi
    xor  eax, eax
    mov  edx, OFFSET actLoginOk
    mov  ebx, OFFSET txtDash
    call LogEvent
    call SaveData
    mov  eax, 1
    ret

loginWrongPin:
    inc  DWORD PTR [accAttempts + esi*4]
    mov  eax, [accAttempts + esi*4]
    cmp  eax, MAX_ATTEMPTS
    jae  loginLockNow
    mov  ebx, MAX_ATTEMPTS
    sub  ebx, eax                    ; EBX = attempts left
    push ebx
    xor  eax, eax
    mov  edx, OFFSET actPinFail
    mov  ebx, OFFSET txtBadPin
    call LogEvent
    call SaveData
    pop  eax
    mov  edx, OFFSET errWrongPin
    call MsgNumber
    jmp  loginAgain
loginLockNow:
    mov  DWORD PTR [accLocked + esi*4], 1
    xor  eax, eax
    mov  edx, OFFSET actLocked
    mov  ebx, OFFSET txtLockedDet
    call LogEvent
    call SaveData
    mov  edx, OFFSET errNowLocked
    call ShowError
    jmp  loginAgain
loginIsLocked:
    xor  eax, eax
    mov  edx, OFFSET actLoginBlock
    mov  ebx, OFFSET txtLockedDet
    call LogEvent
    mov  edx, OFFSET errLocked
    call ShowError
    jmp  loginAgain
loginNoAccount:
    mov  esi, NO_ACCOUNT
    xor  eax, eax
    mov  edx, OFFSET actLoginFail
    mov  ebx, OFFSET txtUnknownAcc
    call LogEvent
    mov  edx, OFFSET errNoAccount
    call ShowError
    jmp  loginAgain
loginNotNumber:
    mov  edx, OFFSET errNotNumber
    call ShowError
    jmp  loginAgain
loginExit:
    mov  eax, 0
    ret
LoginScreen ENDP

; ------------------------------------------------------------------
;  SECTION 6 : FEATURES
; ------------------------------------------------------------------

; ---- Balance Inquiry ----
DoBalance PROC USES eax ebx edx esi
    mov  esi, curAcc
    xor  eax, eax
    mov  edx, OFFSET actBalance
    mov  ebx, OFFSET txtDash
    call LogEvent
    mov  eax, [accBal + esi*4]
    mov  edx, OFFSET msgBalance
    call MsgNumber
    ret
DoBalance ENDP

; ---- Cash Deposit ----
DoDeposit PROC USES eax ebx edx esi
    mov  edx, OFFSET titleDeposit
    call DrawFrame
    mov  esi, curAcc
    INVOKE SetPos, SCR_X, 8
    mov  edx, OFFSET askDeposit
    call ReadAmount                  ; EAX = amount (0 = bad input)
    cmp  eax, 0
    je   depExit
    cmp  eax, MAX_DEPOSIT
    ja   depTooBig
    mov  ebx, [accBal + esi*4]
    add  ebx, eax
    jc   depOverflow
    mov  [accBal + esi*4], ebx
    add  [accDeposits + esi*4], eax
    inc  DWORD PTR [accTxnCount + esi*4]
    mov  ebx, TYPE_DEPOSIT
    call AddHistory
    mov  rcAmt, eax
    mov  rcFee, 0
    mov  rcDest, 0
    mov  rcTypeP, OFFSET actDeposit
    mov  edx, OFFSET actDeposit
    mov  ebx, OFFSET txtDash
    call LogEvent
    call SaveData
    call ShowReceipt
depExit:
    ret
depTooBig:
    mov  edx, OFFSET actDepDenied
    mov  ebx, OFFSET errTooBig
    call LogEvent
    mov  edx, OFFSET errTooBig
    call ShowError
    ret
depOverflow:
    mov  edx, OFFSET actDepDenied
    mov  ebx, OFFSET errOverflow
    call LogEvent
    mov  edx, OFFSET errOverflow
    call ShowError
    ret
DoDeposit ENDP

; ---- Cash Withdrawal (quick-amount buttons or "other") ----
DoWithdraw PROC USES eax ebx ecx edx esi
    mov  edx, OFFSET titleWithdraw
    call DrawFrame
    mov  esi, curAcc
    INVOKE DrawButtons, OFFSET quickTable, 7
    INVOKE PutText, 10, 19, OFFSET txtHintQuick, CLR_HINT
    call ReadChar                    ; one key, like an ATM button
    cmp  al, '0'
    je   wdExit
    cmp  al, '6'
    je   wdOther
    cmp  al, '1'
    jb   wdBadKey
    cmp  al, '5'
    ja   wdBadKey
    movzx eax, al
    sub  eax, '1'
    mov  eax, [quickAmt + eax*4]
    jmp  wdHaveAmt
wdOther:
    mov  eax, CLR_SCREEN
    call SetTextColor
    INVOKE SetPos, 42, 16
    mov  edx, OFFSET askOther
    call ReadAmount
    cmp  eax, 0
    je   wdExit
wdHaveAmt:
    ; check 1: multiple of 100
    mov  ebx, eax
    mov  edx, 0
    mov  ecx, 100
    div  ecx                         ; EDX = remainder
    mov  eax, ebx
    cmp  edx, 0
    jne  wdNotHundred

    ; check 2: enough balance?
    mov  ebx, [accBal + esi*4]
    sub  ebx, eax
    jb   wdNoFunds

    ; check 3: daily limit?
    mov  ecx, [accDayWithdrawn + esi*4]
    add  ecx, eax
    cmp  ecx, DAILY_LIMIT
    ja   wdDayLimit

    mov  [accBal + esi*4], ebx
    mov  [accDayWithdrawn + esi*4], ecx
    add  [accWithdrawals + esi*4], eax
    inc  DWORD PTR [accTxnCount + esi*4]
    mov  ebx, TYPE_WITHDRAW
    call AddHistory
    mov  rcAmt, eax
    mov  rcFee, 0
    mov  rcDest, 0
    mov  rcTypeP, OFFSET actWithdraw
    mov  edx, OFFSET actWithdraw
    mov  ebx, OFFSET txtDash
    call LogEvent
    call SaveData
    call DispenseCash
    call ShowReceipt
wdExit:
    ret
wdBadKey:
    mov  edx, OFFSET errKey
    call ShowError
    ret
wdNotHundred:
    mov  edx, OFFSET actWdDenied
    mov  ebx, OFFSET errNotHundred
    call LogEvent
    mov  edx, OFFSET errNotHundred
    call ShowError
    ret
wdNoFunds:
    mov  edx, OFFSET actWdDenied
    mov  ebx, OFFSET errNoFunds
    call LogEvent
    mov  edx, OFFSET errNoFunds
    call ShowError
    ret
wdDayLimit:
    mov  edx, OFFSET actWdDenied
    mov  ebx, OFFSET errDayLimit
    call LogEvent
    mov  edx, OFFSET errDayLimit
    call ShowError
    ret
DoWithdraw ENDP

; ---- Fund Transfer with fee ----
;   ESI = sender, EDI = receiver, ECX = amount, EBX = fee
DoTransfer PROC USES eax ebx ecx edx esi edi
    mov  edx, OFFSET titleTransfer
    call DrawFrame
    INVOKE SetPos, SCR_X, 13
    mov  edx, OFFSET txtFeeNote
    call WriteString

    INVOKE SetPos, SCR_X, 7
    mov  edx, OFFSET askDest
    call WriteString
    call ReadNumber
    cmp  inputOK, 0
    je   trfNotNumber
    call FindAccount
    cmp  eax, NO_ACCOUNT
    je   trfNoDest
    mov  edi, eax                    ; EDI = receiver
    cmp  edi, curAcc
    je   trfSelf

    INVOKE SetPos, SCR_X, 9
    mov  edx, OFFSET askTrfAmount
    call ReadAmount
    cmp  eax, 0
    je   trfExit
    mov  ecx, eax                    ; ECX = amount
    call CalcFee
    mov  ebx, eax                    ; EBX = fee
    mov  rcFee, ebx

    mov  esi, curAcc                 ; ESI = sender
    mov  edx, [accBal + esi*4]
    mov  eax, ecx
    add  eax, ebx
    sub  edx, eax
    jb   trfNoFunds

    mov  [accBal + esi*4], edx       ; sender pays amount + fee
    add  [accBal + edi*4], ecx       ; receiver gets the amount
    inc  DWORD PTR [accTxnCount + esi*4]
    inc  DWORD PTR [accTxnCount + edi*4]

    ; ---- history for both accounts ----
    mov  eax, ecx
    mov  ebx, TYPE_TRF_OUT
    call AddHistory
    push esi
    mov  esi, edi
    mov  ebx, TYPE_TRF_IN
    call AddHistory
    pop  esi

    ; ---- log: sender line ----
    mov  eax, [accNo + edi*4]
    mov  detNum, eax
    mov  eax, rcFee
    mov  detFee, eax
    mov  eax, ecx
    mov  edx, OFFSET actTrfOut
    mov  ebx, OFFSET txtToAcc2
    call LogEvent
    ; ---- log: receiver line ----
    mov  eax, [accNo + esi*4]
    mov  detNum, eax
    push esi
    mov  esi, edi
    mov  eax, ecx
    mov  edx, OFFSET actTrfIn
    mov  ebx, OFFSET txtFromAcc
    call LogEvent
    pop  esi
    call SaveData

    ; ---- receipt ----
    mov  rcAmt, ecx
    mov  eax, [accNo + edi*4]
    mov  rcDest, eax
    mov  rcTypeP, OFFSET actTrfOut
    call ShowReceipt
trfExit:
    ret
trfNotNumber:
    mov  edx, OFFSET errNotNumber
    call ShowError
    ret
trfNoDest:
    mov  esi, curAcc
    xor  eax, eax
    mov  edx, OFFSET actTrfDenied
    mov  ebx, OFFSET errNoDest
    call LogEvent
    mov  edx, OFFSET errNoDest
    call ShowError
    ret
trfSelf:
    mov  edx, OFFSET errSelf
    call ShowError
    ret
trfNoFunds:
    mov  eax, ecx
    mov  edx, OFFSET actTrfDenied
    mov  ebx, OFFSET errNoFundsFee
    call LogEvent
    mov  edx, OFFSET errNoFundsFee
    call ShowError
    ret
DoTransfer ENDP

; ---- Mini Statement ----
;   Walks the circular buffer from the OLDEST to the NEWEST slot and
;   prints only the lines of the logged-in account.
DoStatement PROC USES eax ebx ecx edx esi
    mov  esi, curAcc
    xor  eax, eax
    mov  edx, OFFSET actStatement
    mov  ebx, OFFSET txtDash
    call LogEvent

    mov  edx, OFFSET titleStatement
    call DrawFrame
    INVOKE SetPos, SCR_X, 6
    mov  edx, OFFSET txtStmtHead
    call WriteString
    INVOKE SetPos, SCR_X, 7
    mov  edx, OFFSET txtStmtLine
    call WriteString
    mov  stmtRow, 8

    mov  ebx, 0
    mov  ecx, histCount
    cmp  ecx, 0
    je   stmtNone

    mov  esi, histNext               ; oldest slot = histNext - histCount
    sub  esi, histCount
    jae  stmtLoop
    add  esi, HIST_MAX

stmtLoop:
    mov  eax, [histAcc + esi*4]
    cmp  eax, curAcc
    jne  stmtSkip

    INVOKE SetPos, SCR_X, stmtRow
    mov  eax, [histType + esi*4]
    dec  eax
    shl  eax, 4                      ; * 16
    mov  edx, OFFSET typeNames
    add  edx, eax
    call WriteString
    INVOKE SetPos, 29, stmtRow
    mov  eax, [histAmt + esi*4]
    call WriteDec
    INVOKE SetPos, 42, stmtRow
    mov  eax, [histBal + esi*4]
    call WriteDec
    inc  stmtRow
    inc  ebx

stmtSkip:
    inc  esi
    cmp  esi, HIST_MAX
    jb   stmtNext
    mov  esi, 0
stmtNext:
    dec  ecx
    jnz  stmtLoop

    cmp  ebx, 0
    jne  stmtEnd
stmtNone:
    INVOKE SetPos, SCR_X, 9
    mov  edx, OFFSET txtNoTxn
    call WriteString
stmtEnd:
    call PressKey
    ret
DoStatement ENDP

; ---- Account Summary ----
DoSummary PROC USES eax ebx edx esi
    mov  esi, curAcc
    xor  eax, eax
    mov  edx, OFFSET actSummary
    mov  ebx, OFFSET txtDash
    call LogEvent

    mov  edx, OFFSET titleSummary
    call DrawFrame
    INVOKE SetPos, SCR_X, 7
    mov  edx, OFFSET txtHolder
    call WriteString
    call PrintName
    call NextLine

    mov  edx, OFFSET txtAccNo
    mov  eax, [accNo + esi*4]
    call ShowLine
    mov  edx, OFFSET txtBalance
    mov  eax, [accBal + esi*4]
    call ShowLine
    mov  edx, OFFSET txtDeposits
    mov  eax, [accDeposits + esi*4]
    call ShowLine
    mov  edx, OFFSET txtWithdrawn
    mov  eax, [accWithdrawals + esi*4]
    call ShowLine
    mov  edx, OFFSET txtTxns
    mov  eax, [accTxnCount + esi*4]
    call ShowLine

    call PressKey
    ret
DoSummary ENDP

; ---- PIN Change ----
;   DoPinChange switches the * masking on, runs PinChangeBody,
;   then switches it off again (so every exit path is covered).
DoPinChange PROC
    mov  maskInput, 1
    call PinChangeBody
    mov  maskInput, 0
    ret
DoPinChange ENDP

PinChangeBody PROC USES eax ebx edx esi
    mov  edx, OFFSET titlePin
    call DrawFrame
    mov  esi, curAcc

    INVOKE SetPos, SCR_X, 7
    mov  edx, OFFSET askOldPin
    call WriteString
    call ReadNumber
    cmp  inputOK, 0
    je   pcNotNumber
    cmp  eax, [accPin + esi*4]
    jne  pcWrongOld

    INVOKE SetPos, SCR_X, 9
    mov  edx, OFFSET askNewPin
    call WriteString
    call ReadNumber
    cmp  inputOK, 0
    je   pcNotNumber
    cmp  eax, 1000
    jb   pcBadFormat
    cmp  eax, 9999
    ja   pcBadFormat
    mov  ebx, eax                    ; EBX = new PIN

    INVOKE SetPos, SCR_X, 11
    mov  edx, OFFSET askConfirmPin
    call WriteString
    call ReadNumber
    cmp  inputOK, 0
    je   pcNotNumber
    cmp  eax, ebx
    jne  pcNoMatch

    mov  [accPin + esi*4], ebx       ; save the new PIN (never written to the log)
    xor  eax, eax
    mov  edx, OFFSET actPinChg
    mov  ebx, OFFSET txtDash
    call LogEvent
    call SaveData
    mov  edx, OFFSET msgPinOk
    call ShowInfo
    ret
pcNotNumber:
    mov  edx, OFFSET errNotNumber
    call ShowError
    ret
pcWrongOld:
    xor  eax, eax
    mov  edx, OFFSET actPinChgFail
    mov  ebx, OFFSET txtWrongOld
    call LogEvent
    mov  edx, OFFSET errOldPin
    call ShowError
    ret
pcBadFormat:
    mov  edx, OFFSET errNewPin
    call ShowError
    ret
pcNoMatch:
    mov  edx, OFFSET errNoMatch
    call ShowError
    ret
PinChangeBody ENDP

; ---- Logout ----  Returns EAX = 1 if the user confirmed, 0 if not.
DoLogout PROC USES ebx ecx edx esi edi
    call ConfirmLogout                   ; EAX = 1 (Y) or 0 (N)
    cmp  eax, 1
    jne  lgNo
    mov  esi, curAcc
    xor  eax, eax
    mov  edx, OFFSET actLogout
    mov  ebx, OFFSET txtDash
    call LogEvent
    mov  curAcc, NO_ACCOUNT
    mov  eax, 1
    ret
lgNo:
    mov  eax, 0
    ret
DoLogout ENDP

; ------------------------------------------------------------------
;  SECTION 7 : DASHBOARD - the 8 menu buttons
; ------------------------------------------------------------------
Dashboard PROC USES eax edx esi
dashTop:
    mov  edx, OFFSET titleDash
    call DrawFrame
    INVOKE DrawButtons, OFFSET menuTable, 8
    INVOKE PutText, 10, 19, OFFSET txtHintMenu, CLR_HINT
    call ReadChar                    ; one key, no Enter needed

    cmp  al, '1'
    je   dashBalance
    cmp  al, '2'
    je   dashDeposit
    cmp  al, '3'
    je   dashWithdraw
    cmp  al, '4'
    je   dashTransfer
    cmp  al, '5'
    je   dashStatement
    cmp  al, '6'
    je   dashSummary
    cmp  al, '7'
    je   dashPin
    cmp  al, '8'
    je   dashLogout

dashBad:                             ; unknown command
    mov  edx, OFFSET errMenu
    call ShowError
    jmp  dashTop
dashBalance:
    call DoBalance
    jmp  dashTop
dashDeposit:
    call DoDeposit
    jmp  dashTop
dashWithdraw:
    call DoWithdraw
    jmp  dashTop
dashTransfer:
    call DoTransfer
    jmp  dashTop
dashStatement:
    call DoStatement
    jmp  dashTop
dashSummary:
    call DoSummary
    jmp  dashTop
dashPin:
    call DoPinChange
    jmp  dashTop
dashLogout:
    call DoLogout
    cmp  eax, 1
    jne  dashTop
    ret
Dashboard ENDP

; ------------------------------------------------------------------
;  MAIN
; ------------------------------------------------------------------
main PROC
    INVOKE SetConsoleTitle, OFFSET appTitle   ; Win32 API
    call Randomize                   ; Irvine32: start the random generator
    call LoadData                    ; read atm_data.dat (if it exists)
    call SaveData                    ; make sure the file exists
    mov  esi, NO_ACCOUNT
    xor  eax, eax
    mov  edx, OFFSET actStart
    mov  ebx, OFFSET txtDash
    call LogEvent
mainLoop:
    call LoginScreen                 ; EAX = 1 logged in, 0 = exit
    cmp  eax, 0
    je   mainQuit
    call Dashboard                   ; returns after logout
    jmp  mainLoop
mainQuit:
    mov  esi, NO_ACCOUNT
    xor  eax, eax
    mov  edx, OFFSET actClose
    mov  ebx, OFFSET txtDash
    call LogEvent
    call SaveData
    mov  eax, white                  ; leave the console in normal colours
    call SetTextColor
    call Clrscr
    exit
main ENDP

END main