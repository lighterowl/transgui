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

unit ConnOptionsTransmissionFrame;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, StdCtrls, Spin, Utils, Main,
  synacode, Dialogs, Menus, rpc;

type

  { TConnOptionsTransmissionFrame }

  TConnOptionsTransmissionFrame = class(TFrame)
    cbAskPassword: TCheckBox;
    cbAuth: TCheckBox;
    cbAutoReconnect: TCheckBox;
    cbSSL: TCheckBox;
    edCertFile: TEdit;
    edCertPass: TEdit;
    edHost: TEdit;
    edPassword: TEdit;
    edPort: TSpinEdit;
    edRpcPath: TEdit;
    edUserName: TEdit;
    txCertFile: TLabel;
    txCertPass: TLabel;
    txConnHelp: TLabel;
    txHost: TLabel;
    txPassword: TLabel;
    txPort: TLabel;
    txRpcPath: TLabel;
    txUserName: TLabel;
    procedure cbAskPasswordClick(Sender: TObject);
    procedure cbAuthClick(Sender: TObject);
    procedure cbSSLClick(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); reintroduce;
    procedure LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
    procedure SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
    function IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
  end;

implementation

{ TConnOptionsTransmissionFrame }

constructor TConnOptionsTransmissionFrame.Create(TheOwner: TComponent);
begin
  inherited Create(Owner);
  txConnHelp.Caption:=Format(txConnHelp.Caption, [Main.AppName]);
end;

procedure TConnOptionsTransmissionFrame.cbSSLClick(Sender: TObject);
begin
{$ifndef windows}
  Utils.EnableControls(cbSSL.Checked, [txCertFile, edCertFile, txCertPass, edCertPass]);
{$else}
  Utils.EnableControls(False, [txCertFile, edCertFile, txCertPass, edCertPass]);
{$endif windows}
end;

procedure TConnOptionsTransmissionFrame.cbAuthClick(Sender: TObject);
begin
  Utils.EnableControls(cbAuth.Checked, [txUserName, edUserName, txPassword, cbAskPassword]);
  cbAskPasswordClick(nil);
end;

procedure TConnOptionsTransmissionFrame.cbAskPasswordClick(Sender: TObject);
begin
  Utils.EnableControls(not cbAskPassword.Checked and cbAskPassword.Enabled, [txPassword, edPassword]);
end;

procedure TConnOptionsTransmissionFrame.LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
var
  s: string;
begin
  edHost.Text:=Ini.ReadString(Section, 'Host', '');
  edPort.Value:=Ini.ReadInteger(Section, 'Port', 9091);
  cbSSL.Checked:=Ini.ReadBool(Section, 'UseSSL', False);
  edCertFile.Text:=Ini.ReadString(Section, 'CertFile', '');
  if cbSSL.Checked then
    if Ini.ReadString(Section, 'CertPass', '') <> '' then
      edCertPass.Text:='******'
    else
      edCertPass.Text:='';
  cbAutoReconnect.Checked:=Ini.ReadBool(Section, 'Autoreconnect', False);
  edUserName.Text:=Ini.ReadString(Section, 'UserName', '');
  s:=Ini.ReadString(Section, 'Password', '');
  cbAuth.Checked:=(edUserName.Text <> '') or (s <> '');
  if cbAuth.Checked then begin
    cbAskPassword.Checked:=s = '-';
    if not cbAskPassword.Checked then
      if s <> '' then
        edPassword.Text:='******'
      else
        edPassword.Text:='';
  end;
  cbAuthClick(nil);
  cbSSLClick(nil);
  edRpcPath.Text:=Ini.ReadString(Section, 'RpcPath', rpc.DefaultRpcPath);
end;

procedure TConnOptionsTransmissionFrame.SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
var
  s, ss: string;
begin
  Ini.WriteString(Section, 'Host', Trim(edHost.Text));
  Ini.WriteBool(Section, 'UseSSL', cbSSL.Checked);
  if not cbSSL.Checked then begin
    edCertFile.Text:='';
    edCertPass.Text:='';
  end;
  Ini.WriteString(Section, 'CertFile', edCertFile.Text);
  if edCertPass.Text <> '******' then begin
    if edCertPass.Text = '' then
      s:=''
    else
      s:=EncodeBase64(edCertPass.Text);
    Ini.WriteString(Section, 'CertPass', s);
  end;
  Ini.WriteBool(Section, 'Autoreconnect', cbAutoReconnect.Checked);
  Ini.WriteInteger(Section, 'Port', edPort.Value);
  if not cbAuth.Checked then begin
    edUserName.Text:='';
    edPassword.Text:='';
    cbAskPassword.Checked:=False;
  end;
  Ini.WriteString(Section, 'UserName', edUserName.Text);
  if cbAskPassword.Checked then
    Ini.WriteString(Section, 'Password', '-')
  else
    if edPassword.Text <> '******' then begin
      ss := edPassword.Text;
      if (Pos('{', ss) > 0) or (Pos('}', ss) > 0) then begin
        Dialogs.MessageDlg('The password can''t contain the characters: { }', mtError, [mbOK], 0);
      end;

      if edPassword.Text = '' then
        s:=''
      else
        s:=EncodeBase64(edPassword.Text);
      Ini.WriteString(Section, 'Password', s);
    end;

  if (edRpcPath.Text = rpc.DefaultRpcPath) or (edRpcPath.Text = '') then
    Ini.DeleteKey(Section, 'RpcPath')
  else
    Ini.WriteString(Section, 'RpcPath', edRpcPath.Text);
end;

function TConnOptionsTransmissionFrame.IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
begin
  with Ini do begin
    Result :=   (edPort.Value <> ReadInteger(Section, 'Port', 9091)) or
                (edHost.Text <> ReadString(Section, 'Host', '')) or
                (cbSSL.Checked <> ReadBool(Section, 'UseSSL', False)) or
                (edCertFile.Text <> ReadString(Section, 'CertFile', '')) or
                ((ReadString(Section, 'CertPass', '') = '') and (edCertPass.Text <> '')) or
                ((ReadString(Section, 'CertPass', '') <> '') and (edCertPass.Text <> '******')) or
                (cbAutoReconnect.Checked <> ReadBool(Section, 'Autoreconnect', False)) or
                (edUserName.Text <> ReadString(Section, 'UserName', '')) or
                ((ReadString(Section, 'Password', '') = '') and (edPassword.Text <> '')) or
                ((ReadString(Section, 'Password', '') <> '') and (edPassword.Text <> '******')) or
                (edRpcPath.Text <> ReadString(Section, 'RpcPath', rpc.DefaultRpcPath));
  end;
end;

initialization
  {$I connoptionstransmissionframe.lrs}

end.

