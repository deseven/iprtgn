; init
EnableExplicit
UsePNGImageDecoder()
;IncludeFile "curl/libcurl-res.pb"
;IncludeFile "curl/libcurl-inc.pb"
IncludeFile "curl/libcurl.pbi"
IncludeFile "const.pb"
Define mydir.s = GetPathPart(ProgramFilename())
Define myhost.s,mylogin.s,mypass.s,myutime.l,shittyicons.b,state.b,alertsCount.l,curIcon.b,curIconSet.b,customSensors.s,curMsg.s,wndHidden.b,notifyMode.b
Define ItemLength.CGFloat,StatusBar.i,StatusItem.i
Define statData.s,statThread.i,customThread.i,threadStarted.i
Define globalLock.i = CreateMutex()
Define lastCheck.i = 0
Define lastSuccessCheck.i = 0
Define lastTrayUpdate.i = 0
Define dummy.i
Define enableDebug.b = #False
NewList custom.sensor()
IncludeFile "proc.pb"
settings(#load)
If shittyicons : createShittyIcons() : Else : createIcons() : EndIf
curIcon = #okconn
curIconSet = #okconn
wndHidden = #True
toLog("init finished")

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
CheckBoxGadget(#shittyicons,20,182,180,20,"Enable big icons")
ComboBoxGadget(#notifytype,200,184,180,20)
AddGadgetItem(#notifytype,#device,"Print device")
AddGadgetItem(#notifytype,#sensor,"Print sensor")
AddGadgetItem(#notifytype,#both,"Print device and sensor")
SetGadgetState(#notifytype,notifyMode)
If shittyicons : SetGadgetState(#shittyicons,#PB_Checkbox_Checked) : EndIf
FrameGadget(#fCustom,10,223,380,55,"Custom sensors (ids, comma separated)")
StringGadget(#custom,20,245,360,20,customSensors)
ButtonGadget(#apply,290,280,100,25,"Apply",#PB_Button_Default)
ButtonGadget(#cancel,190,280,100,25,"Cancel")
toLog("window created")

check()
AddKeyboardShortcut(#wnd,#PB_Shortcut_Return,#enter)
StickyWindow(#wnd,#True)

Repeat
  Define ev = WaitWindowEvent(250)
  If ElapsedMilliseconds() - lastCheck >= myutime*1000 And state = #sOk And Not statThread
    statThread = CreateThread(@getStat(),dummy)
    threadStarted = ElapsedMilliseconds()
    toLog("started stat tid " + Str(statThread))
  ElseIf ElapsedMilliseconds() - lastCheck >= myutime*1000 And state = #sOk And statThread And Not IsThread(statThread)
    If Not customThread
      customThread = CreateThread(@getCustom(),dummy)
      toLog("started custom tid " + Str(customThread))
    ElseIf Not IsThread(customThread)
      toLog("threads finished, starting parsing operations")
      If TryLockMutex(globalLock)
        UnlockMutex(globalLock)
      Else
        FreeMutex(globalLock)
        globalLock = CreateMutex()
        UnlockMutex(globalLock)
        toLog("!!! recreated global lock mutex")
      EndIf
      checkPRTG(statData)
      parseCustom()
      updateMenu()
      ForEach custom()
        toLog("custom [" + custom()\id + "," + custom()\name + "," + custom()\lastvalue + "]")
      Next
      If lastSuccessCheck
        If lastSuccessCheck < ElapsedMilliseconds() - myutime
          SetMenuItemText(#menu,#info,"Alerts: " + Str(alertsCount) + " (" + buildTime(ElapsedMilliseconds()-lastSuccessCheck) + ")")
        EndIf
      Else
        toLog("haven't got new data for at least " + Str(myutime) + " seconds")
        SetMenuItemText(#menu,#info,"Alerts: " + Str(alertsCount) + " - updating...")
      EndIf
      lastCheck = ElapsedMilliseconds()
      statThread = 0
      customThread = 0
    EndIf
  EndIf
  If statThread Or customThread
    If ElapsedMilliseconds() - #tTimeout*3000 > threadStarted
      If IsThread(statThread)
        toLog("!!! it seems that the thread is hanged, trying to recover")
        KillThread(statThread)
        toLog("!!! killed thread " + Str(statThread))
      EndIf
      If IsThread(customThread)
        toLog("!!! it seems that the thread is hanged, trying to recover")
        KillThread(customThread)
        toLog("!!! killed thread " + Str(customThread))
      EndIf
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
  EndSelect
ForEver

Die()