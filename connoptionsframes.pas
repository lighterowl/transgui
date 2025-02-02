{*************************************************************************************
  This file is part of Transmission Remote GUI.
  Copyright (c) 2008-2019 by Yury Sidorov and Transmission Remote GUI working group.
  Copyright (c) 2023-2024 by Daniel Kamil Kozar

  Transmission Remote GUI is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Transmission Remote GUI is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  In addition, as a special exception, the copyright holders give permission to
  link the code of portions of this program with the
  OpenSSL library under certain conditions as described in each individual
  source file, and distribute linked combinations including the two.

  You should have received a copy of the GNU General Public License
  along with Transmission Remote GUI; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*************************************************************************************}

unit ConnOptionsFrames;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, ComCtrls, Dialogs, Utils, ConnOptionsTransmissionFrame,
  ConnOptionsProxyFrame, ConnOptionsPathsFrame, ConnOptionsMiscFrame;

resourcestring
  sNoHost = 'No host name specified.';
  sNoProxy = 'No proxy server specified.';

type

  TConnOptionsFrames = class

    transmission: TConnOptionsTransmissionFrame;
    proxy: TConnOptionsProxyFrame;
    paths: TConnOptionsPathsFrame;
    misc: TConnOptionsMiscFrame;

    constructor Create(TheOwner: TComponent; tabTr: TTabSheet;
      tabPr: TTabSheet; tabPa: TTabSheet; tabMi: TTabSheet; page: TPageControl);

    function Validate : Boolean;
    procedure LoadConnSettings(const ConnName: string; Ini: TIniFileUtf8);
    procedure SaveConnSettings(const ConnName: string; Ini: TIniFileUtf8);
    function IsConnSettingsChanged(const ConnName: string; Ini: TIniFileUtf8) : Boolean;

    private

    tabTransmission: TTabSheet;
    tabProxy: TTabSheet;
    tabPaths: TTabSheet;
    tabMisc: TTabSheet;
    pageControl: TPageControl;

    class function ConnNameToSectionName(const ConnName: string; Ini: TIniFileUtf8) : String; static;
  end;

implementation

constructor TConnOptionsFrames.Create(TheOwner: TComponent; tabTr: TTabSheet;
  tabPr: TTabSheet; tabPa: TTabSheet; tabMi: TTabSheet; page: TPageControl);
begin
  transmission := TConnOptionsTransmissionFrame.Create(TheOwner);
  proxy := TConnOptionsProxyFrame.Create(TheOwner);
  paths := TConnOptionsPathsFrame.Create(TheOwner);
  misc := TConnOptionsMiscFrame.Create(TheOwner);

  tabTransmission := tabTr;
  tabProxy := tabPr;
  tabPaths := tabPa;
  tabMisc := tabMi;

  transmission.Parent := tabTransmission;
  proxy.Parent := tabProxy;
  paths.Parent := tabPaths;
  misc.Parent := tabMisc;
end;

function TConnOptionsFrames.Validate : Boolean;
begin
  Result:=False;
  transmission.edHost.Text:=Trim(transmission.edHost.Text);
  if Trim(transmission.edHost.Text) = '' then begin
    pageControl.ActivePage:=tabTransmission;
    transmission.edHost.SetFocus;
    MessageDlg(sNoHost, mtError, [mbOK], 0);
    exit;
  end;
  proxy.edProxy.Text:=Trim(proxy.edProxy.Text);
  if tabProxy.TabVisible and proxy.cbUseProxy.Checked and (proxy.edProxy.Text = '') then begin
    pageControl.ActivePage:=tabProxy;
    proxy.edProxy.SetFocus;
    MessageDlg(sNoProxy, mtError, [mbOK], 0);
    exit;
  end;
  Result:=True;
end;

procedure TConnOptionsFrames.LoadConnSettings(const ConnName: string; Ini: TIniFileUtf8);
var
  Section: String;
begin
  Section := ConnNameToSectionName(ConnName, Ini);
  transmission.LoadConnSettings(Section, Ini);
  proxy.LoadConnSettings(Section, Ini);
  paths.LoadConnSettings(Section, Ini);
  misc.LoadConnSettings(Section, Ini);
end;

procedure TConnOptionsFrames.SaveConnSettings(const ConnName: string; Ini: TIniFileUtf8);
var
  Section: String;
begin
  Section := 'Connection.' + ConnName;
  transmission.SaveConnSettings(Section, Ini);
  proxy.SaveConnSettings(Section, Ini);
  paths.SaveConnSettings(Section, Ini);
  misc.SaveConnSettings(Section, Ini);
end;

function TConnOptionsFrames.IsConnSettingsChanged(const ConnName: string; Ini: TIniFileUtf8) : Boolean;
var
  Section: String;
begin
  Section := ConnNameToSectionName(ConnName, Ini);
  Result:=transmission.IsConnSettingsChanged(Section, Ini) or
          proxy.IsConnSettingsChanged(Section, Ini) or
          paths.IsConnSettingsChanged(Section,Ini) or
          misc.IsConnSettingsChanged(Section, Ini);
end;

class function TConnOptionsFrames.ConnNameToSectionName(const ConnName: string; Ini: TIniFileUtf8) : String;
var
  Section: String;
begin
  { to be used only when loading as it preserves compatibility with (I presume)
    really old INIs created by single-connection-only transgui versions that
    stored all settings in the "Connection" section.
    newly created settings should always be stored in "Connection.$conn_name"
    sections. }
  Section := 'Connection.' + ConnName;
  if (ConnName <> '') and not Ini.SectionExists(Section) then
    Section := 'Connection';
  Result := Section;
end;

end.

