
Procedure.s encDec(string.s,mode.b)
  If Len(string)
    res.s = Space(1024)
    If mode = #encode
      Base64Encoder(@string,StringByteLength(string),@res,1024)
    Else
      Base64Decoder(@string,StringByteLength(string),@res,1024)
    EndIf
    ProcedureReturn(res)
  EndIf
EndProcedure

Procedure Die()
  End 0
EndProcedure

Procedure settings(mode.b)
  Shared myhost.s,mylogin.s,mypass.s,myutime.l,shittyicons.b,customSensors.s
  config.s = GetEnvironmentVariable("HOME") + "/.config"
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

Procedure notify(msg.s,url.s)
  Shared mydir.s,myhost.s
  Protected args.s = "-group iPRTGn -title iPRTGn -message " + #DQUOTE$ + msg + #DQUOTE$ + " -open " + #DQUOTE$ + url + #DQUOTE$
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
  url.s = "http://" + myhost + "/api/table.json?content=sensors&output=json&columns=sensor&filter_status=5&username=" + mylogin + "&password=" + mypass
  statData = getData(url)
EndProcedure

Procedure getCustom(dummy)
  Shared myhost.s,mylogin.s,mypass.s,custom.sensor()
  ForEach custom()
    url.s = "http://" + myhost + "/api/getsensordetails.xml?id=" + custom()\id + "&username=" + mylogin + "&password=" + mypass
    custom()\sData = getData(url)
  Next
EndProcedure

Procedure buildCustom()
  Shared custom.sensor()
  ClearList(custom())
  sensors.s = GetGadgetText(#custom)
  If Len(sensors)
    numOfSensors.b = CountString(GetGadgetText(#custom),",") + 1
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
EndProcedure

Procedure parseCustom()
  Shared custom.sensor()
  CreateRegularExpression(#name,"<name>\s*<!\[CDATA\[(.*)\]\]>\s*<\/name>")
  CreateRegularExpression(#lastvalue,"<lastvalue>\s*<!\[CDATA\[(.*)\]\]>\s*<\/lastvalue>")
  ;Debug custom()\sData
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
  FreeRegularExpression(#name)
  FreeRegularExpression(#lastvalue)
EndProcedure

Procedure checkPRTG(resData.s)
  Shared myhost.s,mylogin.s,mypass.s,wndHidden.b,state.b,alertsCount.l,curIcon.b,curMsg.s
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
      ExtractJSONStructure(JSONValue(0),@alerts.alerts,alerts)
      curAlerts = alerts\treesize
      msg = "Alerts: " + Str(curAlerts)
      If curAlerts : msg + Chr(13) + "[" : EndIf
      ForEach alerts\sensors()
        Debug alerts\sensors()\sensor
        msg + alerts\sensors()\sensor + ", "
      Next
      If curAlerts : msg = Left(msg,Len(msg)-2) + "]" : EndIf
      ;Debug curAlerts
      If curAlerts <> alertsCount And msg <> curMsg
        notify(msg,"http://" + myhost + "/alarms.htm?filter_status=5&filter_status=4&filter_status=10&filter_status=13&filter_status=14")
        SetMenuItemText(#menu,#info,"Alerts: " + Str(curAlerts))
        alertsCount = curAlerts
        curMsg = msg
      EndIf
      FreeJSON(0)
    Else
      curIcon = #okconn
      ProcedureReturn
    EndIf
  Else
    curIcon = #okconn
    ProcedureReturn
  EndIf
EndProcedure

Procedure buildMenu()
  Shared ItemLength.CGFloat,StatusBar.i,StatusItem.i,curIconSet.b,curAlerts.l,custom.sensor()
  If Not (StatusBar And StatusItem)
    ItemLength.CGFloat = 32
    StatusBar.i = CocoaMessage(0, 0, "NSStatusBar systemStatusBar")
    StatusItem.i = CocoaMessage(0, CocoaMessage(0, StatusBar, "statusItemWithLength:", #NSSquareStatusBarItemLength), "retain")
  EndIf
  If IsMenu(#menu) : FreeMenu(#menu) : EndIf
  CreatePopupMenu(#menu)
  MenuItem(#info,"Alerts: " + Str(curAlerts))
  MenuBar()
  ForEach custom()
    MenuItem(ListIndex(custom())+1,custom()\id + " - updating...")
  Next
  MenuBar()
  MenuItem(#about,"About")
  MenuItem(#settings,"Settings")
  MenuItem(#exit,"Exit")
  CocoaMessage(0,StatusItem,"setHighlightMode:",@"YES")
  CocoaMessage(0,StatusItem,"setLength:@",@ItemLength)
  CocoaMessage(0,StatusItem,"setImage:",ImageID(curIconSet))
  CocoaMessage(0,StatusItem,"setMenu:",CocoaMessage(0,MenuID(#menu),"firstObject"))
EndProcedure

Procedure updateMenu()
  Shared custom.sensor()
  Protected text.s
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
