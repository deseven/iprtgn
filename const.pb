#myname = "iPRTGn"
#myver = "0.6.5"
#mydefhost = "monitoring.home-nadym.ru:12345"
#mydefutime = 30
#seed = 10100100011
#trayupdate = 500
#tTimeout = 30
#NSSquareStatusBarItemLength = -2

Enumeration main
  #wnd
  #host
  #hostCap
  #login
  #loginCap
  #pass
  #passCap
  #utime
  #utimeCap
  #apply
  #cancel
  #shittyicons
  #notifytype
  #custom
  #fMain
  #fAdd
  #fCustom
EndEnumeration

Enumeration notifyType
  #device
  #sensor
  #both
EndEnumeration

Enumeration state
  #sErr
  #sOk
EndEnumeration

Enumeration regex
  #name
  #lastvalue
EndEnumeration

Enumeration menu 255
  #menu
  #info
  #about
  #settings
  #exit
  #enter
EndEnumeration

Enumeration img
  #ok
  #okconn
  #alert
EndEnumeration

Enumeration encdec
  #encode
  #decode
EndEnumeration

Enumeration settings
  #save
  #load
EndEnumeration

Structure sensor
  id.s
  name.s
  lastvalue.s
  sData.s
EndStructure

Structure alertSensor
  sensor.s
  device.s
EndStructure

Structure alerts
  ver.s
  treesize.l
  List sensors.alertSensor()
EndStructure

DataSection
  imgOk:
  IncludeBinary "img/ok.png"
  imgAlert:
  IncludeBinary "img/alert.png"
  imgOkConn:
  IncludeBinary "img/okconn.png"
  imgShittyOk:
  IncludeBinary "img/shittyok.png"
  imgShittyAlert:
  IncludeBinary "img/shittyalert.png"
  imgShittyOkConn:
  IncludeBinary "img/shittyokconn.png"
EndDataSection