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

unit ConnOptionsMiscFrame;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, StdCtrls, Utils,
  restranslator, Dialogs, Main;

type

  { TConnOptionsMiscFrame }

  TConnOptionsMiscFrame = class(TFrame)
    edDownSpeeds: TEdit;
    edIniFileName: TEdit;
    edLanguage: TEdit;
    edTranslateForm: TCheckBox;
    edTranslateMsg: TCheckBox;
    edUpSpeeds: TEdit;
    gbSpeed: TGroupBox;
    Label111: TLabel;
    Label2: TLabel;
    txDownSpeeds: TLabel;
    txUpSpeeds: TLabel;
    procedure edIniFileNameDblClick(Sender: TObject);
    procedure edLanguageDblClick(Sender: TObject);
    procedure edTranslateFormChange(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); reintroduce;
    procedure LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
    procedure SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
    function IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
  end;

implementation

constructor TConnOptionsMiscFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  if edTranslateForm.Checked then
    edTranslateMsg.Enabled:=True
  else
    edTranslateMsg.Enabled:=False;
  Main.LoadTranslation;
  edLanguage.Text:=Main.FTranslationLanguage;
  edIniFileName.Text:=Main.FHomeDir+ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), '.ini');
end;

procedure TConnOptionsMiscFrame.edLanguageDblClick(Sender: TObject);
var
  Sl: TStringList;
begin
  Sl:= GetAvailableTranslations(DefaultLangDir);
  GetTranslationFileName(Main.FTranslationLanguage, Sl);
  ShowMessage(
              sLanguagePathFile + ': ' + IniFileName + sLineBreak + sLineBreak +
              sLanguagePath + ': ' + DefaultLangDir + sLineBreak + sLineBreak +
              sLanguageList + ':' + sLineBreak + Sl.Text
              );
  edLanguage.Text:=IniFileName;
    if IniFileName <> '' then begin
        AppBusy;
        OpenURL(DefaultLangDir);
        AppNormal;
        exit;
    end;
    ForceAppNormal;
    MessageDlg(sNoPathMapping, mtInformation, [mbOK], 0);
end;

procedure TConnOptionsMiscFrame.edTranslateFormChange(Sender: TObject);
begin
  if edTranslateForm.Checked then edTranslateMsg.Enabled:=True
  else begin
    edTranslateMsg.Enabled:=False;
    edLanguage.Text:='';
  end;
end;

procedure TConnOptionsMiscFrame.edIniFileNameDblClick(Sender: TObject);
begin
  if edIniFileName.Text <> '' then begin
    AppBusy;
    OpenURL(Main.FHomeDir+ChangeFileExt(ExtractFileName(ParamStrUTF8(0)), '.ini'));
    AppNormal;
    exit;
  end;

  ForceAppNormal;
  MessageDlg(sNoPathMapping, mtInformation, [mbOK], 0);
end;

procedure TConnOptionsMiscFrame.LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
begin
  edDownSpeeds.Text:=Ini.ReadString(Section, 'DownSpeeds', DefSpeeds);
  edUpSpeeds.Text:=Ini.ReadString(Section, 'UpSpeeds', DefSpeeds);
  edTranslateMsg.Checked:=Ini.ReadBool('Translation', 'TranslateMsg', True);
  edTranslateForm.Checked:=Ini.ReadBool('Translation', 'TranslateForm', True);
end;

procedure TConnOptionsMiscFrame.SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
begin
  Ini.WriteBool('Translation', 'TranslateMsg', edTranslateMsg.Checked);
  Ini.WriteBool('Translation', 'TranslateForm', edTranslateForm.Checked);
  Ini.WriteString(Section, 'DownSpeeds', Trim(edDownSpeeds.Text));
  Ini.WriteString(Section, 'UpSpeeds', Trim(edUpSpeeds.Text));
end;

function TConnOptionsMiscFrame.IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
begin
  Result := (edTranslateMsg.Checked <> Ini.ReadBool('Translation', 'TranslateMsg', True)) or
            (edTranslateForm.Checked <> Ini.ReadBool('Translation', 'TranslateForm', True)) or
            (edDownSpeeds.Text <> Ini.ReadString(Section, 'DownSpeeds', '')) or
            (edUpSpeeds.Text <> Ini.ReadString(Section, 'UpSpeeds', ''));
end;

initialization
  {$I connoptionsmiscframe.lrs}

end.

