
; init
UsePNGImageDecoder()
IncludeFile "curl/libcurl-res.pb"
IncludeFile "curl/libcurl-inc.pb"
IncludeFile "const.pb"
mydir.s = GetPathPart(ProgramFilename())
Define myhost.s,mylogin.s,mypass.s,myutime.l,shittyicons.b,state.b,alertsCount.l,curIcon.b,curIconSet.b,customSensors.s,curMsg.s
Define statData.s,statThread.i,customThread.i
lastCheck.i = 0
lastTrayUpdate.i = 0
NewList custom.sensor()
IncludeFile "proc.pb"
settings(#load)
If shittyicons : createShittyIcons() : Else : createIcons() : EndIf
curIcon = #okconn
curIconSet = #okconn

wndHidden = #True
OpenWindow(#wnd,#PB_Ignore,#PB_Ignore,400,310,#myname,#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_Invisible)
FrameGadget(#fMain,10,10,380,142,"Main settings")
TextGadget(#hostCap,20,32,145,20,"PRTG (hostname:port)")
TextGadget(#loginCap,20,62,145,20,"PRTG login")
TextGadget(#passCap,20,92,145,20,"PRTG password")
TextGadget(#utimeCap,20,122,145,20,"PRTG check time (sec)")
StringGadget(#host,165,30,210,20,myhost)
StringGadget(#login,165,60,140,20,mylogin)
StringGadget(#pass,165,90,140,20,mypass,#PB_String_Password)
StringGadget(#utime,165,120,90,20,Str(myutime),#PB_String_Numeric)
FrameGadget(#fAdd,10,160,380,55,"Additional settings")
CheckBoxGadget(#shittyicons,20,182,200,20,"Enable big icons")
If shittyicons : SetGadgetState(#shittyicons,#PB_Checkbox_Checked) : EndIf
FrameGadget(#fCustom,10,223,380,55,"Custom sensors (ids, comma separated)")
StringGadget(#custom,20,245,360,20,customSensors)
ButtonGadget(#apply,290,280,100,25,"Apply",#PB_Button_Default)
ButtonGadget(#cancel,190,280,100,25,"Cancel")

check()
AddKeyboardShortcut(#wnd,#PB_Shortcut_Return,#enter)
StickyWindow(#wnd,#True)

Repeat
  ev = WaitWindowEvent(100)
  If CocoaMessage(0,WindowID(#wnd),"isVisible") And wndHidden
    HideWindow(#wnd,#True)
    RunProgram("open","http://" + myhost,"")
  EndIf
  If ElapsedMilliseconds() - lastCheck >= myutime*1000 And state = #sOk And Not statThread
    statThread = CreateThread(@getStat(),dummy)
    Debug "started stat tid " + Str(statThread)
  ElseIf ElapsedMilliseconds() - lastCheck >= myutime*1000 And state = #sOk And statThread And Not IsThread(statThread)
    If Not customThread
      customThread = CreateThread(@getCustom(),dummy)
      Debug "started custom tid " + Str(customThread)
    ElseIf Not IsThread(customThread)
      checkPRTG(statData)
      parseCustom()
      updateMenu()
      ForEach custom()
        Debug "[" + custom()\id + "," + custom()\name + "," + custom()\lastvalue + "]"
      Next
      lastCheck = ElapsedMilliseconds()
      statThread = 0
      customThread = 0
    EndIf
  EndIf
  If ElapsedMilliseconds() - lastTrayUpdate >= #trayupdate
    trayUpdate()
    lastTrayUpdate = ElapsedMilliseconds()
  EndIf
  Select ev
    Case #PB_Event_CloseWindow
      If Not wndHidden
        HideWindow(#wnd,#True) : wndHidden = #True
      Else
        Break
      EndIf
    Case #PB_Event_Gadget
      If EventGadget() = #apply
        settings(#save)
        HideWindow(#wnd,#True) : wndHidden = #True
        check()
      ElseIf EventGadget() = #cancel
        HideWindow(#wnd,#True) : wndHidden = #True
        check()
      EndIf
    Case #PB_Event_Menu
      Select EventMenu()
        Case #info
          RunProgram("open","http://" + myhost + "/alarms.htm?filter_status=5&filter_status=4&filter_status=10&filter_status=13&filter_status=14","")
        Case #about
          MessageRequester(#myname,"v." + #myver + #CRLF$ + "written by deseven, 2015")
        Case #settings
          state = #sErr
          HideWindow(#wnd,#False,#PB_Window_ScreenCentered) : wndHidden = #False
        Case #exit
          Break
        Case #enter
          If Not wndHidden
            settings(#save)
            HideWindow(#wnd,#True) : wndHidden = #True
            check()
          EndIf
        Default
          If EventMenu() <= ListSize(custom())+1
            SelectElement(custom(),EventMenu()-1)
            RunProgram("open","http://" + myhost + "/sensor.htm?id=" + custom()\id,"")
          EndIf
      EndSelect
  EndSelect
ForEver

Die()