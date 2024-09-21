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

  You should have received a copy of the GNU General Public License
  along with Transmission Remote GUI; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  In addition, as a special exception, the copyright holders give permission to 
  link the code of portions of this program with the
  OpenSSL library under certain conditions as described in each individual
  source file, and distribute linked combinations including the two.

  You must obey the GNU General Public License in all respects for all of the
  code used other than OpenSSL.  If you modify file(s) with this exception, you
  may extend this exception to your version of the file(s), but you are not
  obligated to do so.  If you do not wish to do so, delete this exception
  statement from your version.  If you delete this exception statement from all
  source files in the program, then also delete it here.
*************************************************************************************}
unit ConnOptions;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Spin, ComCtrls, Buttons, ButtonPanel, ExtCtrls, ResTranslator,
  ConnOptionsFrames;

resourcestring
  SDelConnection = 'Are you sure to delete connection ''%s''?';
  SNewConnection = 'New connection to Transmission';

type

  { TConnOptionsForm }

  TConnOptionsForm = class(TForm)
    btNew: TButton;
    btDel: TButton;
    btRename: TButton;
    Buttons: TButtonPanel;
    cbConnection: TComboBox;
    txConName: TLabel;
    panTop: TPanel;
    tabProxy: TTabSheet;
    tabMisc: TTabSheet;
    tabPaths: TTabSheet;
    Page: TPageControl;
    tabConnection: TTabSheet;
    procedure btDelClick(Sender: TObject);
    procedure btNewClick(Sender: TObject);
    procedure btOKClick(Sender: TObject);
    procedure btRenameClick(Sender: TObject);
    procedure cbConnectionSelect(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tabPathsShow(Sender: TObject);
  private
    FCurConn: string;
    FCurHost: string;
    edConnection: TEdit;

    optionsFrames: TConnOptionsFrames;

    procedure BeginEdit;
    procedure EndEdit;
    procedure SaveConnectionsList;
    procedure transmissionHostChange(Sender: TObject);
  public
    ActiveConnection: string;
    ActiveSettingChanged: boolean;

    destructor Destroy; override;
    procedure LoadConnSettings(const ConnName: string);
    procedure SaveConnSettings(const ConnName: string);
    function IsConnSettingsChanged(const ConnName: string): boolean;
  end;

implementation

uses Main, synacode, utils, rpc, LCLIntf;

{ TConnOptionsForm }

destructor TConnOptionsForm.Destroy;
begin
  FreeAndNil(optionsFrames);
  inherited;
end;

procedure TConnOptionsForm.btOKClick(Sender: TObject);
begin
  if not optionsFrames.Validate then
    exit;
  EndEdit;
  SaveConnSettings(FCurConn);
  SaveConnectionsList;
  ModalResult:=mrOk;
end;

procedure TConnOptionsForm.btRenameClick(Sender: TObject);
begin
  if edConnection.Visible then begin
    if Trim(edConnection.Text) = '' then exit;
    EndEdit;
    exit;
  end;
  if cbConnection.Text = '' then exit;
  BeginEdit;
  ActiveControl:=edConnection;
  edConnection.SelectAll;
end;

procedure TConnOptionsForm.cbConnectionSelect(Sender: TObject);
var
  i: integer;
  s: string;
begin
  if edConnection.Visible then
    exit;
  i:=cbConnection.ItemIndex;
  if i >= 0 then
    s:=cbConnection.Items[i]
  else
    s:='';

  if (FCurConn <> s) and (FCurConn <> '') then begin
    if not optionsFrames.Validate then begin
      cbConnection.ItemIndex:=cbConnection.Items.IndexOf(FCurConn);
      exit;
    end;
    SaveConnSettings(FCurConn);
  end;
  if s <> '' then
    LoadConnSettings(s);
end;

procedure TConnOptionsForm.btNewClick(Sender: TObject);
begin
  EndEdit;
  if (FCurConn <> '') and not optionsFrames.Validate then
    exit;
  SaveConnSettings(FCurConn);
  LoadConnSettings('');
  BeginEdit;
  edConnection.Text:='';
  Page.ActivePage:=tabConnection;
  ActiveControl:=optionsFrames.transmission.edHost;
end;

procedure TConnOptionsForm.btDelClick(Sender: TObject);
var
  i: integer;
begin
  if edConnection.Visible or (cbConnection.Text = '') then
    exit;
  if MessageDlg('', Format(SDelConnection, [cbConnection.Text]), mtConfirmation, mbYesNo, 0, mbNo) <> mrYes then exit;
  if FCurConn <> '' then begin
    Ini.EraseSection('Connection.' + FCurConn);
    Ini.EraseSection('Connection');
    Ini.EraseSection('AddTorrent.' + FCurConn);

    i:=cbConnection.ItemIndex;
    if i >= 0 then begin
      cbConnection.Items.Delete(i);
      if i >= cbConnection.Items.Count then begin
        i:=cbConnection.Items.Count - 1;
        if i < 0 then
          i:=0;
      end;
    end
    else
      i:=0;
    if i < cbConnection.Items.Count then
      cbConnection.ItemIndex:=i
    else
      cbConnection.ItemIndex:=-1;
  end
  else
    cbConnection.ItemIndex:=-1;
  if cbConnection.ItemIndex >= 0 then begin
    if FCurConn = ActiveConnection then
      ActiveConnection:='';
    LoadConnSettings(cbConnection.Items[cbConnection.ItemIndex]);
    if ActiveConnection = '' then
      ActiveConnection:=FCurConn;
  end
  else begin
    FCurConn:='';
    btNewClick(nil);
  end;
  SaveConnectionsList;
end;

procedure TConnOptionsForm.FormCreate(Sender: TObject);
var
  i, cnt: integer;
  s: string;
begin
  optionsFrames := TConnOptionsFrames.Create(Self, tabConnection,
                   tabProxy, tabPaths, tabMisc, Page);
  optionsFrames.transmission.edHost.OnChange:=@transmissionHostChange;

  bidiMode := GetBiDi();
  Page.ActivePageIndex:=0;
  ActiveControl:=optionsFrames.transmission.edHost;
  Buttons.OKButton.ModalResult:=mrNone;
  Buttons.OKButton.OnClick:=@btOKClick;

  edConnection:=TEdit.Create(cbConnection.Parent);
  edConnection.Visible:=False;
  edConnection.BoundsRect:=cbConnection.BoundsRect;
  edConnection.Parent:=cbConnection.Parent;

  cnt:=Ini.ReadInteger('Hosts', 'Count', 0);
  for i:=1 to cnt do begin
    s:=Ini.ReadString('Hosts', Format('Host%d', [i]), '');
    if s <> '' then
      cbConnection.Items.Add(s);
  end;
end;

procedure TConnOptionsForm.FormShow(Sender: TObject);
begin
  if edConnection.Visible then
    exit;
  if cbConnection.Items.Count = 0 then begin
    btNewClick(nil);
    exit;
  end;
  cbConnection.ItemIndex:=cbConnection.Items.IndexOf(ActiveConnection);
  if cbConnection.ItemIndex < 0 then
    cbConnection.ItemIndex:=0;
  LoadConnSettings(cbConnection.Text);
end;

procedure TConnOptionsForm.tabPathsShow(Sender: TObject);
var
  R: TRect;
begin
  R:=optionsFrames.paths.edPaths.BoundsRect;
  R.Top:=optionsFrames.paths.txPaths.BoundsRect.Bottom + 8;
  optionsFrames.paths.edPaths.BoundsRect:=R;
end;

procedure TConnOptionsForm.transmissionHostChange(Sender: TObject);
begin
  if edConnection.Visible and (edConnection.Text = FCurHost) then
    edConnection.Text:=optionsFrames.transmission.edHost.Text;
  FCurHost:=optionsFrames.transmission.edHost.Text;
end;

procedure TConnOptionsForm.EndEdit;

  procedure RenameSection(const OldName, NewName: string);
  var
    i: integer;
    sl: TStringList;
  begin
    sl:=TStringList.Create;
    with Ini do
    try
      ReadSectionValues(OldName, sl);
      for i:=0 to sl.Count - 1 do
        WriteString(NewName, sl.Names[i], sl.ValueFromIndex[i]);
      EraseSection(OldName);
    finally
      sl.Free;
    end;
  end;

var
  NewName, s: string;
  i, p: integer;
begin
  if not edConnection.Visible then exit;
  NewName:=Trim(edConnection.Text);
  if NewName = '' then
    NewName:=Trim(optionsFrames.transmission.edHost.Text);
  if NewName <> FCurConn then begin
    if FCurConn <> '' then begin
      p:=cbConnection.Items.IndexOf(FCurConn);
      if p >= 0 then
        cbConnection.Items.Delete(p);
    end
    else
      p:=-1;

    i:=1;
    s:=NewName;
    while cbConnection.Items.IndexOf(NewName) >= 0 do begin
      Inc(i);
      NewName:=Format('%s (%d)', [s, i]);
    end;

    if FCurConn <> '' then begin
      RenameSection('Connection.' + FCurConn, 'Connection.' + NewName);
      RenameSection('AddTorrent.' + FCurConn, 'AddTorrent.' + NewName);
    end;

    if p >= 0 then
      cbConnection.Items.Insert(p, NewName)
    else
      cbConnection.Items.Add(NewName);
    if (FCurConn = ActiveConnection) or (FCurConn = '') then
      ActiveConnection:=NewName;
    FCurConn:=NewName;
    SaveConnectionsList;
  end;
  cbConnection.ItemIndex:=cbConnection.Items.IndexOf(NewName);
  cbConnection.Visible:=True;
  edConnection.Visible:=False;
end;

procedure TConnOptionsForm.SaveConnectionsList;
var
  i: integer;
begin
  with Ini do begin
    WriteString('Hosts', 'CurHost', ActiveConnection);
    WriteInteger('Hosts', 'Count', cbConnection.Items.Count);
    for i:=0 to cbConnection.Items.Count - 1 do
      WriteString('Hosts', Format('Host%d', [i + 1]), cbConnection.Items[i]);
    UpdateFile;
  end;
end;

procedure TConnOptionsForm.BeginEdit;
var
  i: integer;
begin
  i:=cbConnection.ItemIndex;
  if i >= 0 then
    edConnection.Text:=cbConnection.Items[i]
  else
    edConnection.Text:='';
  edConnection.Visible:=True;
  cbConnection.Visible:=False;
end;

procedure TConnOptionsForm.LoadConnSettings(const ConnName: string);
begin
  optionsFrames.LoadConnSettings(ConnName, Ini);

  FCurConn:=ConnName;
  FCurHost:=optionsFrames.transmission.edHost.Text;
end;

procedure TConnOptionsForm.SaveConnSettings(const ConnName: string);
var
  i: integer;
begin
  if ConnName = '' then
    exit;
  if ConnName = ActiveConnection then
    if IsConnSettingsChanged(ConnName) then
      ActiveSettingChanged:=True;

  optionsFrames.SaveConnSettings(ConnName, Ini);

  i:=cbConnection.Items.IndexOf(ConnName);
  if i < 0 then
    cbConnection.Items.Insert(0, ConnName);

  Ini.UpdateFile;
end;

function TConnOptionsForm.IsConnSettingsChanged(const ConnName: string): boolean;
begin
  Result := optionsFrames.IsConnSettingsChanged(ConnName, Ini);
end;

initialization
  {$I connoptions.lrs}

end.

