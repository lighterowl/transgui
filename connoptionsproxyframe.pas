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

unit ConnOptionsProxyFrame;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, StdCtrls, Spin, Utils, synacode;

type

  { TConnOptionsProxyFrame }

  TConnOptionsProxyFrame = class(TFrame)
    cbProxyAuth: TCheckBox;
    cbUseProxy: TCheckBox;
    cbUseSocks5: TCheckBox;
    edProxy: TEdit;
    edProxyPassword: TEdit;
    edProxyPort: TSpinEdit;
    edProxyUserName: TEdit;
    txProxy: TLabel;
    txProxyPassword: TLabel;
    txProxyPort: TLabel;
    txProxyUserName: TLabel;
    procedure cbProxyAuthClick(Sender: TObject);
    procedure cbUseProxyClick(Sender: TObject);
  private

  public
    procedure LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
    procedure SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
    function IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
  end;

implementation

procedure TConnOptionsProxyFrame.cbProxyAuthClick(Sender: TObject);
begin
  Utils.EnableControls(cbProxyAuth.Checked and cbProxyAuth.Enabled, [txProxyUserName, edProxyUserName, txProxyPassword, edProxyPassword]);
end;

procedure TConnOptionsProxyFrame.cbUseProxyClick(Sender: TObject);
begin
  EnableControls(cbUseProxy.Checked, [txProxy, edProxy, txProxyPort, edProxyPort, cbUseSocks5, cbProxyAuth]);
  cbProxyAuthClick(nil);
end;

procedure TConnOptionsProxyFrame.LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
begin
  cbUseProxy.Checked:=Ini.ReadBool(Section, 'UseProxy', False);
  cbUseSocks5.Checked:=Ini.ReadBool(Section, 'UseSockProxy', False);
  edProxy.Text:=Ini.ReadString(Section, 'ProxyHost', '');
  edProxyPort.Value:=Ini.ReadInteger(Section, 'ProxyPort', 8080);
  edProxyUserName.Text:=Ini.ReadString(Section, 'ProxyUser', '');
  cbProxyAuth.Checked:=edProxyUserName.Text <> '';
  if cbProxyAuth.Checked then
    if Ini.ReadString(Section, 'ProxyPass', '') <> '' then
      edProxyPassword.Text:='******'
    else
      edProxyPassword.Text:='';
  cbUseProxyClick(nil);
end;

procedure TConnOptionsProxyFrame.SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
var
  s: string;
begin
  Ini.WriteBool(Section, 'UseProxy', cbUseProxy.Checked);
  Ini.WriteBool(Section, 'UseSockProxy', cbUseSocks5.Checked);
  Ini.WriteString(Section, 'ProxyHost', Trim(edProxy.Text));
  Ini.WriteInteger(Section, 'ProxyPort', edProxyPort.Value);
  if not cbProxyAuth.Checked then begin
    edProxyUserName.Text:='';
    edProxyPassword.Text:='';
  end;
  Ini.WriteString(Section, 'ProxyUser', edProxyUserName.Text);
  if edProxyPassword.Text <> '******' then begin
    if edProxyPassword.Text = '' then
      s:=''
    else
      s:=EncodeBase64(edProxyPassword.Text);
    Ini.WriteString(Section, 'ProxyPass', s);
  end;
end;

function TConnOptionsProxyFrame.IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
begin
  Result := (cbUseProxy.Checked <> Ini.ReadBool(Section, 'UseProxy', False)) or
            (edProxy.Text <> Ini.ReadString(Section, 'ProxyHost', '')) or
            (edProxyPort.Value <> Ini.ReadInteger(Section, 'ProxyPort', 8080)) or
            (edProxyUserName.Text <> Ini.ReadString(Section, 'ProxyUser', '')) or
            ((Ini.ReadString(Section, 'ProxyPass', '') = '') and (edProxyPassword.Text <> '')) or
            ((Ini.ReadString(Section, 'ProxyPass', '') <> '') and (edProxyPassword.Text <> '******'));
end;

initialization
  {$I connoptionsproxyframe.lrs}

end.

