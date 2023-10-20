{adapted from https://forum.lazarus.freepascal.org/index.php/topic,43111.msg461112.html}

unit MacOSThemeDetect;

{$MODESWITCH OBJECTIVEC2}

interface

uses
  Classes, SysUtils, CocoaAll, MacOsAll, CocoaUtils;

type
  TThemeChangedCallback = procedure () of object;

var
  Callback : TThemeChangedCallback;

function IsDarkMode: Boolean;

implementation

type
  TThemeChangedNotification = objcclass(NSObject)
    procedure ThemeChangedNotification(notification: NSNotification);
      message 'ThemeChangedNotification:';
  end;

procedure TThemeChangedNotification.ThemeChangedNotification(
  notification: NSNotification);
begin
  Callback();
end;

function IsDarkMode: Boolean;
var
  sMode: string;
begin
  sMode  := CFStringToStr(CFStringRef(NSApp.effectiveAppearance.name));
  Result := Pos('Dark', sMode) > 0;
end;

var
  ThemeChangedNotification: TThemeChangedNotification;
  DistributedNotificationCenter: NSDistributedNotificationCenter;

initialization
  ThemeChangedNotification := TThemeChangedNotification.alloc.init;
  ThemeChangedNotification.retain;
  DistributedNotificationCenter := NSDistributedNotificationCenter.defaultCenter;
  if Assigned(DistributedNotificationCenter) then
    DistributedNotificationCenter.addObserver_selector_name_object(
      ThemeChangedNotification, ObjCSelector('ThemeChangedNotification:'),
      NSSTR('AppleInterfaceThemeChangedNotification'), nil);

finalization
  ThemeChangedNotification.release;

end.

