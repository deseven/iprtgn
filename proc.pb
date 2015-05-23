Declare.s encDec(string.s,mode.b)
Declare Die()
Declare.s buildTime(time.i)
Declare settings(mode.b)
Declare createIcons()
Declare createShittyIcons()
Declare notify(alerts.l,msg.s,url.s)
Declare.s getData(url.s)
Declare getStat(dummy)
Declare getCustom(dummy)
Declare buildCustom()
Declare parseCustom()
Declare checkPRTG(resData.s)
Declare menuActions()
Declare buildMenu()
Declare updateMenu()
Declare trayUpdate()
Declare check()

Procedure.s encDec(string.s,mode.b)
  If Len(string)
    Protected res.s = Space(1024)
    If mode = #encode
      Base64Encoder(@string,StringByteLength(string),@res,1024)
    Else
      Base64Decoder(@string,StringByteLength(string),@res,1024)
    EndIf
    ProcedureReturn(res)
  EndIf
EndProcedure

Procedure Die()
  Shared statThread.i,customThread.i
  If IsThread(statThread) : KillThread(statThread) : EndIf
  If IsThread(customThread) : KillThread(customThread) : EndIf
  End 0
EndProcedure

Procedure.s buildTime(time.i)
  time/1000
  If time => 60
    time/60
    ProcedureReturn Str(time) + " min ago"
  EndIf
  ProcedureReturn Str(time) + " sec ago"
EndProcedure

Procedure settings(mode.b)
  Shared myhost.s,mylogin.s,mypass.s,myutime.l,shittyicons.b,customSensors.s,notifyMode.b
  Protected config.s = GetEnvironmentVariable("HOME") + "/.config"
  If FileSize(config) <> -2 : CreateDirectory(config) : EndIf
  config + "/iPRTGn"
  If FileSize(config) <> -2 : CreateDirectory(config) : EndIf
  OpenPreferences(config + "/config.ini")
  If mode = #load
    myhost = ReadPreferenceString("host",#mydefhost)
    mylogin = ReadPreferenceString("login","")
    mypass = encDec(ReadPreferenceString("pass",""),#decode)
    myutime = ReadPreferenceInteger("update_time",#mydefutime)
    customSensors = ReadPreferenceString("custom_sensors","")
    Select ReadPreferenceString("notify_mode","device")
      Case "sensor"
        notifyMode = #sensor
      Case "both"
        notifyMode = #both
      Default
        notifyMode = #device
    EndSelect
    If ReadPreferenceString("shitty_icons","no") = "no"
      shittyicons = #False
    Else
      shittyicons = #True
    EndIf
    Debug myhost + "," + mylogin + "," + mypass + "," + Str(myutime)
  Else
    myhost = GetGadgetText(#host)
    mylogin = GetGadgetText(#login)
    mypass = GetGadgetText(#pass)
    myutime = Val(GetGadgetText(#utime))
    customSensors = GetGadgetText(#custom)
    If GetGadgetState(#shittyicons) = #PB_Checkbox_Checked
      shittyicons = #True
    Else
      shittyicons = #False
    EndIf
    WritePreferenceString("host",myhost)
    WritePreferenceString("login",mylogin)
    WritePreferenceString("pass",encDec(mypass,#encode))
    WritePreferenceInteger("update_time",myutime)
    WritePreferenceString("custom_sensors",customSensors)
    Select GetGadgetState(#notifytype)
      Case #sensor
        notifyMode = #sensor
        WritePreferenceString("notify_mode","sensor")
      Case #both
        notifyMode = #both
        WritePreferenceString("notify_mode","both")
      Default
        notifyMode = #device
        WritePreferenceString("notify_mode","device")
    EndSelect
    If shittyicons
      WritePreferenceString("shitty_icons","yes")
    Else
      WritePreferenceString("shitty_icons","no")
    EndIf
  EndIf
  ClosePreferences()
EndProcedure

Procedure createIcons()
  If IsImage(#ok) : FreeImage(#ok) : EndIf
  If IsImage(#okconn) : FreeImage(#okconn) : EndIf
  If IsImage(#alert) : FreeImage(#alert) : EndIf
  CatchImage(#ok,?imgOk)
  CatchImage(#okconn,?imgOkConn)
  CatchImage(#alert,?imgAlert)
EndProcedure

Procedure createShittyIcons()
  If IsImage(#ok) : FreeImage(#ok) : EndIf
  If IsImage(#okconn) : FreeImage(#okconn) : EndIf
  If IsImage(#alert) : FreeImage(#alert) : EndIf
  CatchImage(#ok,?imgShittyOk)
  CatchImage(#okconn,?imgShittyOkConn)
  CatchImage(#alert,?imgShittyAlert)
EndProcedure

Procedure notify(alerts.l,msg.s,url.s)
  Shared mydir.s,myhost.s
  Protected args.s = "-group iPRTGn -title " + #DQUOTE$ + "Alerts: " + Str(alerts) + #DQUOTE$ + " -message " + #DQUOTE$ + msg + #DQUOTE$ + " -open " + #DQUOTE$ + url + #DQUOTE$
  ;Debug args
  RunProgram(mydir + "iPRTGn.app/Contents/MacOS/terminal-notifier",args,mydir + "iPRTGn.app/")
EndProcedure

Procedure.s getData(url.s)
  Protected res.b,resData.s,curl.i
  curl = curl_easy_init()
  curl_easy_setopt(curl,#CURLOPT_URL,@url)
  curl_easy_setopt(curl,#CURLOPT_IPRESOLVE,#CURL_IPRESOLVE_V4)
  curl_easy_setopt(curl,#CURLOPT_WRITEFUNCTION,@RW_LibCurl_WriteFunction())
  res.b = curl_easy_perform(curl)
  resData.s = RW_LibCurl_GetData()
  curl_easy_cleanup(curl.i)
  ProcedureReturn resData
EndProcedure

Procedure getStat(dummy)
  Shared statData.s,myhost.s,mylogin.s,mypass.s
  Protected url.s = "http://" + myhost + "/api/table.json?content=sensors&output=json&columns=sensor,device&filter_status=5&username=" + mylogin + "&password=" + mypass
  statData = getData(url)
EndProcedure

Procedure getCustom(dummy)
  Shared globalLock.i,myhost.s,mylogin.s,mypass.s,custom.sensor()
  LockMutex(globalLock)
  ForEach custom()
    Protected url.s = "http://" + myhost + "/api/getsensordetails.xml?id=" + custom()\id + "&username=" + mylogin + "&password=" + mypass
    custom()\sData = getData(url)
  Next
  UnlockMutex(globalLock)
EndProcedure

Procedure buildCustom()
  Shared globalLock.i,custom.sensor()
  LockMutex(globalLock)
  ClearList(custom())
  Protected i.i,sensor.s,sensors.s = GetGadgetText(#custom)
  If Len(sensors)
    Protected numOfSensors.b = CountString(GetGadgetText(#custom),",") + 1
    If numOfSensors
      For i = 1 To numOfSensors
        sensor.s = StringField(sensors,i,",")
        If Len(sensor)
          AddElement(custom())
          custom()\id = sensor
        EndIf
      Next
    EndIf
  EndIf
  UnlockMutex(globalLock)
EndProcedure

Procedure parseCustom()
  Shared globalLock.i,custom.sensor()
  CreateRegularExpression(#name,"<name>\s*<!\[CDATA\[(.*)\]\]>\s*<\/name>")
  CreateRegularExpression(#lastvalue,"<lastvalue>\s*<!\[CDATA\[(.*)\]\]>\s*<\/lastvalue>")
  ;Debug custom()\sData
  LockMutex(globalLock)
  ForEach custom()
    If ExamineRegularExpression(#name,custom()\sData)
      If NextRegularExpressionMatch(#name)
        custom()\name = RegularExpressionGroup(#name,1)
      EndIf
    EndIf
    If ExamineRegularExpression(#lastvalue,custom()\sData)
      If NextRegularExpressionMatch(#lastvalue)
        custom()\lastvalue = RegularExpressionGroup(#lastvalue,1)
      EndIf
    EndIf
  Next
  UnlockMutex(globalLock)
  FreeRegularExpression(#name)
  FreeRegularExpression(#lastvalue)
EndProcedure

Procedure checkPRTG(resData.s)
  Shared myhost.s,mylogin.s,mypass.s,wndHidden.b,state.b,alertsCount.l,curIcon.b,curMsg.s,lastSuccessCheck.i,notifyMode.b
  Protected msg.s
  If FindString(resData,"Unauthorized")
    MessageRequester(#myname,"Login/password is incorrect!")
    mylogin = ""
    mypass = ""
    state = #sErr
    HideWindow(#wnd,#False,#PB_Window_ScreenCentered) : wndHidden = #False
  ElseIf Len(resData)
    If ParseJSON(0,resData,#PB_JSON_NoCase)
      curIcon = #ok
      NewMap PRTGData()
      Protected alerts.alerts
      ExtractJSONStructure(JSONValue(0),@alerts.alerts,alerts)
      Protected curAlerts = alerts\treesize
      Select notifyMode
        Case #sensor
          ;Debug "sensor"
          ForEach alerts\sensors()
            msg + alerts\sensors()\sensor + ", "
          Next
        Case #both
          ;Debug "both"
          Protected NewMap both.s()
          ForEach alerts\sensors()
            If Len(both(alerts\sensors()\device))
              both(alerts\sensors()\device) + "," + alerts\sensors()\sensor
            Else
              both(alerts\sensors()\device) = alerts\sensors()\sensor
            EndIf
          Next
          ForEach both()
            msg + MapKey(both()) + "[" + both() + "], "
          Next
        Default
          ;Debug "device"
          Protected NewList devices.s()
          ForEach alerts\sensors()
            AddElement(devices())
            devices() = alerts\sensors()\device
          Next
          SortList(devices(),#PB_Sort_Ascending)
          Protected prev.s
          ForEach devices()
            If devices() <> prev
              prev = devices()
            Else
              DeleteElement(devices())
            EndIf
          Next
          ForEach devices()
            msg + devices() + ", "
          Next
      EndSelect
      If curAlerts : msg = Left(msg,Len(msg)-2) : EndIf
      ;Debug curAlerts
      ;Debug msg
      If curAlerts <> alertsCount And msg <> curMsg
        If curAlerts
          notify(curAlerts,msg,"http://" + myhost + "/alarms.htm?filter_status=5&filter_status=4&filter_status=10&filter_status=13&filter_status=14")
        EndIf
        alertsCount = curAlerts
        curMsg = msg
      EndIf
      FreeJSON(0)
      SetMenuItemText(#menu,#info,"Alerts: " + Str(curAlerts))
      lastSuccessCheck = ElapsedMilliseconds()
    Else
      curIcon = #okconn
      ProcedureReturn
    EndIf
  Else
    curIcon = #okconn
    ProcedureReturn
  EndIf
EndProcedure

Procedure menuActions()
  Shared globalLock.i,myhost.s,wndHidden.b,state.b,custom.sensor()
  Select EventMenu()
    Case #info
      RunProgram("open","http://" + myhost + "/alarms.htm?filter_status=5&filter_status=4&filter_status=10&filter_status=13&filter_status=14","")
    Case #about
      MessageRequester(#myname,"v." + #myver + #CRLF$ + "written by deseven, 2015")
    Case #settings
      state = #sErr
      HideWindow(#wnd,#False,#PB_Window_ScreenCentered) : wndHidden = #False
    Case #exit
      Die()
    Case #enter
      If Not wndHidden
        settings(#save)
        HideWindow(#wnd,#True) : wndHidden = #True
        check()
      EndIf
    Default
      LockMutex(globalLock)
      If EventMenu() <= ListSize(custom())+1
        SelectElement(custom(),EventMenu()-1)
        RunProgram("open","http://" + myhost + "/sensor.htm?id=" + custom()\id + "#tab3","")
      EndIf
      UnlockMutex(globalLock)
  EndSelect
EndProcedure

Procedure buildMenu()
  Shared globalLock.i,ItemLength.CGFloat,StatusBar.i,StatusItem.i,curIconSet.b,alertsCount.l,custom.sensor()
  If Not (StatusBar And StatusItem)
    ItemLength.CGFloat = 32
    StatusBar.i = CocoaMessage(0,0,"NSStatusBar systemStatusBar")
    StatusItem.i = CocoaMessage(0,CocoaMessage(0,StatusBar,"statusItemWithLength:",#NSSquareStatusBarItemLength), "retain")
  EndIf
  If IsMenu(#menu) : FreeMenu(#menu) : EndIf
  CreatePopupMenu(#menu)
  MenuItem(#info,"Alerts: " + Str(alertsCount))
  BindMenuEvent(#menu,#info,@menuActions())
  MenuBar()
  LockMutex(globalLock)
  ForEach custom()
    MenuItem(ListIndex(custom())+1,custom()\id + " - updating...")
    UnbindMenuEvent(#menu,ListIndex(custom())+1,@menuActions())
    BindMenuEvent(#menu,ListIndex(custom())+1,@menuActions())
  Next
  UnlockMutex(globalLock)
  MenuBar()
  MenuItem(#about,"About")
  UnbindMenuEvent(#menu,#about,@menuActions())
  BindMenuEvent(#menu,#about,@menuActions())
  MenuItem(#settings,"Settings")
  UnbindMenuEvent(#menu,#settings,@menuActions())
  BindMenuEvent(#menu,#settings,@menuActions())
  MenuItem(#exit,"Exit")
  UnbindMenuEvent(#menu,#exit,@menuActions())
  BindMenuEvent(#menu,#exit,@menuActions())
  UnbindMenuEvent(#menu,#enter,@menuActions())
  BindMenuEvent(#menu,#enter,@menuActions())
  CocoaMessage(0,StatusItem,"setHighlightMode:",@"YES")
  CocoaMessage(0,StatusItem,"setLength:@",@ItemLength)
  CocoaMessage(0,StatusItem,"setImage:",ImageID(curIconSet))
  CocoaMessage(0,StatusItem,"setMenu:",CocoaMessage(0,MenuID(#menu),"firstObject"))
EndProcedure

Procedure updateMenu()
  Shared globalLock.i,custom.sensor()
  Protected text.s
  LockMutex(globalLock)
  ForEach custom()
    If Len(custom()\lastvalue)
      text = "[" + custom()\lastvalue + "] "
    Else
      text = "[no data] "
    EndIf
    If Len(custom()\name)
      text + custom()\name
    Else
      text + custom()\id
    EndIf
    SetMenuItemText(#menu,ListIndex(custom())+1,text)
  Next
  UnlockMutex(globalLock)
EndProcedure

Procedure trayUpdate()
  Shared curIcon.b,curIconSet.b,alertsCount.l,StatusBar.i,StatusItem.i,shittyicons.b
  If alertsCount
    If curIcon <> curIconSet
      CocoaMessage(0,StatusItem,"setImage:",ImageID(curIcon))
      curIconSet = curIcon
    Else
      CocoaMessage(0,StatusItem,"setImage:",ImageID(#alert))
      curIconSet = #alert
    EndIf
  ElseIf curIcon <> curIconSet
    CocoaMessage(0,StatusItem,"setImage:",ImageID(curIcon))
    curIconSet = curIcon
  EndIf
EndProcedure

Procedure check()
  Shared myhost.s,mylogin.s,mypass.s,shittyicons.b,myutime.l,wndHidden.b,state.b,curIconSet.b,lastCheck.i
  If Not (Len(myhost) And Len(mylogin) And Len(mypass) And myutime)
    state = #sErr
    HideWindow(#wnd,#False,#PB_Window_ScreenCentered) : wndHidden = #False
  Else
    state = #sOk
    lastCheck = -myutime*1000
  EndIf
  buildCustom()
  buildMenu()
  If shittyicons : createShittyIcons() : Else : createIcons() : EndIf
  curIconSet = -1
EndProcedure
