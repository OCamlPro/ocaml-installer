; NSIS Installer script for OCaml
;
; Original Author:
;   Jonathan Protzenko <jonathan.protzenko@ens-lyon.org>

; -------------
!define MUI_PRODUCT "OCaml"
!define MUI_UI_HEADERIMAGE "ocaml-icon.png"
!define MUI_ICON "ocaml-icon.ico"
; this must match the activetcl version ocaml was compiled against
!define ACTIVETCL_VERSION "8.5.10.1"
!define ACTIVETCL_URL "http://downloads.activestate.com/ActiveTcl/releases/8.5.10.1/ActiveTcl8.5.10.1.295062-win32-ix86-threaded.exe"
;!define EMACS_URL "http://ftp.gnu.org/gnu/emacs/windows/emacs-23.3-bin-i386.zip"
!define EMACS_URL "http://yquem/~protzenk/emacs-23.3-bin-i386.zip"
!define EMACS_VER "23.3"
!define ROOT_DIR "c:\ocamlmgw" ; the directory where your binary dist of ocaml lives

!include "version.nsh"
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "EnvVarUpdate.nsh"

Name "OCaml"
OutFile "ocaml-${MUI_VERSION}-mingw32.exe"
InstallDir "$PROGRAMFILES32\${MUI_PRODUCT}"
RequestExecutionLevel admin

!define MUI_WELCOMEPAGE_TITLE "Welcome to the OCaml setup for windows."
!define MUI_WELCOMEPAGE_TEXT "This wizard will install OCaml ${MUI_VERSION}, as well as required tools and libraries for it to work properly."
!define MUI_LICENSEPAGE_TEXT_TOP "OCaml is distributed under a modified QPL license."
!define MUI_LICENSEPAGE_TEXT_BOTTOM "You must agree with the terms of the license below before installing OCaml."
!define MUI_COMPONENTSPAGE_TEXT_COMPLIST "Tcl/Tk is a requirement, and Emacs is recommended to have a nice toplevel. This installer can download and install both."

; -------------
; Some constants

!define SHCNE_ASSOCCHANGED 0x8000000
!define SHCNF_IDLIST 0

; -------------
; Generate zillions of pages to look professional

  !insertmacro MUI_PAGE_WELCOME
  ;!insertmacro MUI_PAGE_STARTMENU 
  !insertmacro MUI_PAGE_LICENSE ${ROOT_DIR}\License.txt
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

; -------------
; Main entry point

Section "OCaml" SecOCaml

  ReadRegStr $1 SHCTX "SOFTWARE\OCaml" ""
  
  ${If} $1 != ""
    MessageBox MB_YESNO "There seems to be a previous version of OCaml installed. It is strongly recommended you uninstall it before proceeding. Proceed anyway?" IDNO end
  ${EndIf}

  SetOutPath "$INSTDIR\bin"

  File "flexlink\flexlink.exe"
  File "flexlink\flexdll_mingw.o"
  File "flexlink\flexdll_initer_mingw.o"

  SetOutPath "$INSTDIR"

  File ocaml-icon.ico
  File ${ROOT_DIR}\Changes.txt
  File ${ROOT_DIR}\License.txt
  File ${ROOT_DIR}\OCamlWin.exe
  File /r ${ROOT_DIR}\bin
  File /r ${ROOT_DIR}\lib
  File /r ${ROOT_DIR}\man
  
  WriteRegStr SHCTX "Software\OCaml" "" $INSTDIR
  ; We want to overwrite that one anyway for the new setup to work properly.
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "OCAMLLIB" "$INSTDIR\lib"
  ${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$INSTDIR\bin"

  FileOpen $0 "$INSTDIR\ld.conf" w
  FileWrite $0 "$INSTDIR\lib"
  FileClose $0

  WriteRegExpandStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\OCaml" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegExpandStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\OCaml" "InstallLocation" "$INSTDIR"
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\OCaml" "DisplayName" "OCaml"
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\OCaml" "DisplayIcon" "$INSTDIR\ocaml-icon.ico"
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\OCaml" "DisplayVersion" "${MUI_VERSION}"
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\OCaml" "Publisher" "Inria"

  WriteUninstaller $INSTDIR\uninstall.exe

  end:

SectionEnd

Section "ActiveTcl ${ACTIVETCL_VERSION}" SecActiveTcl

  ReadRegStr $1 HKLM "SOFTWARE\ActiveState\ActiveTcl" "CurrentVersion"
  
  ${If} $1 == ${ACTIVETCL_VERSION}
    MessageBox MB_YESNO "You already seem to have ActiveTcl ${ACTIVETCL_VERSION} installed. Download and install ActiveTcl anyway?" IDNO end
  ${EndIf}
  

  NSISdl::download ${ACTIVETCL_URL} "$TEMP\activetcl.exe"
  ExecWait "$TEMP\activetcl.exe"
  
  end:

SectionEnd

Section "Emacs ${EMACS_VER}" SecEmacs

  ${If} ${FileExists} "$INSTDIR\emacs-${EMACS_VER}"
    MessageBox MB_YESNO "There seems to be an Emacs living in that directory already... overwrite?" IDNO end
  ${EndIf}

  NSISdl::download ${EMACS_URL} "$TEMP\emacs.zip"
  nsisunz::UnzipToStack "$TEMP\emacs.zip" "$INSTDIR"

  Pop $0
  StrCmp $0 "success" ok
    DetailPrint "$0"
    Goto skiplist
  ok:

  next:
    Pop $0
    DetailPrint $0
  StrCmp $0 "" 0 next

  skiplist:

  ; add the caml-mode in the emacs distribution

  SetOutPath "$INSTDIR\emacs-${EMACS_VER}\site-lisp\caml-mode"
  File ${ROOT_DIR}\emacsfiles\*
  SetOutPath "$INSTDIR\emacs-${EMACS_VER}\site-lisp"
  File site-start.el

  ; register file types, add emacs bin directory to the path

  ${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$INSTDIR\emacs-${EMACS_VER}\bin"

  WriteRegStr HKCR ".mli" "" "OCaml.mli"
  WriteRegStr HKCR "OCaml.mli" "" "OCaml Interface File"
  WriteRegStr HKCR "OCaml.mli\DefaultIcon" "" "$INSTDIR\ocaml-icon.ico"
  WriteRegStr HKCR "OCaml.mli\shell" "" "open"
  WriteRegStr HKCR "OCaml.mli\shell\open\command" "" '$INSTDIR\emacs-${EMACS_VER}\bin\runemacs.exe "%1"'

  WriteRegStr HKCR ".ml" "" "OCaml.ml"
  WriteRegStr HKCR "OCaml.ml" "" "OCaml Implementation File"
  WriteRegStr HKCR "OCaml.ml\DefaultIcon" "" "$INSTDIR\ocaml-icon.ico"
  WriteRegStr HKCR "OCaml.ml\shell" "" "open"
  WriteRegStr HKCR "OCaml.ml\shell\open\command" "" '$INSTDIR\emacs-${EMACS_VER}\bin\runemacs.exe "%1"'

  System::Call 'Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)'

  end:

SectionEnd

; -------------
; The semantics are: if the section is named "Uninstall", then this is used to
; generate the uninstaller

Section "Uninstall"

  ${If} ${FileExists} "$INSTDIR\emacs-${EMACS_VER}"
    MessageBox MB_YESNO "Also uninstall Emacs ${EMACS_VER}?" IDNO next

    ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\emacs-${EMACS_VER}\bin"
    RMDir /r "$INSTDIR\emacs-${EMACS_VER}"

    ReadRegStr $R0 HKCR ".mli" ""
    StrCmp $R0 "OCaml.mli" 0 +2
      DeleteRegKey HKCR ".mli"

    ReadRegStr $R0 HKCR ".ml" ""
    StrCmp $R0 "OCaml.ml" 0 +2
      DeleteRegKey HKCR ".ml"

    DeleteRegKey HKCR "OCaml.ml"
    DeleteRegKey HKCR "OCaml.mli"

    System::Call 'Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)'
  ${EndIf}

  next:

  ; The rationale is that idiots^W users might install this in their Program
  ; Files directory, so we can't blindy remove the INSTDIR...
  Delete "$INSTDIR\bin\flexlink.exe"
  Delete "$INSTDIR\bin\flexdll_initer_mingw.o"
  Delete "$INSTDIR\bin\flexdll_mingw.o"
  RMDir "$INSTDIR\bin"

  Delete "$INSTDIR\ocaml-icon.ico"
  Delete "$INSTDIR\Changes.txt"
  Delete "$INSTDIR\License.txt"
  Delete "$INSTDIR\OCamlWin.exe"
  Delete "$INSTDIR\ld.conf"
  Delete "$INSTDIR\uninstall.exe"
  !include uninstall_lines.nsi
  RMDir "$INSTDIR"

  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"
  ; Using EnvVarUpdate makes sure we do *not* alter OCAMLLIB in case it has
  ; changed in the meanwhile.
  ${un.EnvVarUpdate} $0 "OCAMLLIB" "R" "HKLM" "$INSTDIR\lib"
  ReadRegStr $1 SHCTX "SOFTWARE\OCaml" ""
  ${Unless} $1 != $INSTDIR
    DeleteRegKey /ifempty SHCTX "SOFTWARE\OCaml"
  ${EndUnless}

  DeleteRegKey SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\OCaml"

SectionEnd
