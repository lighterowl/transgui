{*************************************************************************************
  This file is part of Transmission Remote GUI.
  Copyright (c) 2008-2019 by Yury Sidorov and Transmission Remote GUI working group.
  Copyright (c) 2023-2025 by Daniel Kamil Kozar

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
unit DaemonOptions;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, LazUTF8, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Spin, ComCtrls, CheckLst, EditBtn, MaskEdit,
  ButtonPanel, Rpc, Main;

resourcestring
 sPortTestSuccess = 'Incoming port tested successfully.';
 sPortTestFailed = 'Incoming port is closed. Check your firewall settings.';
 sEncryptionDisabled = 'Allow encryption';
 sEncryptionEnabled = 'Prefer encryption';
 sEncryptionRequired = 'Require encryption';
 SNoDownloadDir = 'The downloads directory was not specified.';
 SNoIncompleteDir = 'The directory for incomplete files was not specified.';
// SNoBlocklistURL = 'The blocklist URL was not specified.';
 SInvalidTime = 'The invalid time value was entered.';

type

  { TDaemonOptionsForm }

  TDaemonOptionsForm = class(TForm)
    btTestPort: TButton;
    Buttons: TButtonPanel;
    cbBlocklist: TCheckBox;
    cbDHT: TCheckBox;
    cbUpQueue: TCheckBox;
    cbEncryption: TComboBox;
    cbMaxDown: TCheckBox;
    cbMaxUp: TCheckBox;
    cbPEX: TCheckBox;
    cbPortForwarding: TCheckBox;
    cbRandomPort: TCheckBox;
    cbIncompleteDir: TCheckBox;
    cbPartExt: TCheckBox;
    cbSeedRatio: TCheckBox;
    cbLPD: TCheckBox;
    cbIdleSeedLimit: TCheckBox;
    cbAltEnabled: TCheckBox;
    cbAutoAlt: TCheckBox;
    cbStalled: TCheckBox;
    cbUTP: TCheckBox;
    cbDownQueue: TCheckBox;
    edAltTimeEnd: TMaskEdit;
    edDownQueue: TSpinEdit;
    edUpQueue: TSpinEdit;
    edStalledTime: TSpinEdit;
    edMaxPeersPerTorrent: TSpinEdit;
    txPerTorrentPeerLimit: TLabel;
    tabQueue: TTabSheet;
    txDays: TLabel;
    txFrom: TLabel;
    edDownloadDir: TEdit;
    edIncompleteDir: TEdit;
    edBlocklistURL: TEdit;
    edMaxDown: TSpinEdit;
    edAltDown: TSpinEdit;
    edMaxPeers: TSpinEdit;
    edMaxUp: TSpinEdit;
    edAltUp: TSpinEdit;
    edPort: TSpinEdit;
    edSeedRatio: TFloatSpinEdit;
    gbBandwidth: TGroupBox;
    edIdleSeedLimit: TSpinEdit;
    gbAltSpeed: TGroupBox;
    edAltTimeBegin: TMaskEdit;
    txAltUp: TLabel;
    txAltDown: TLabel;
    txMinutes1: TLabel;
    txTo: TLabel;
    txKbs3: TLabel;
    txKbs4: TLabel;
    txMinutes: TLabel;
    txMB: TLabel;
    txCacheSize: TLabel;
    Page: TPageControl;
    edCacheSize: TSpinEdit;
    tabNetwork: TTabSheet;
    tabBandwidth: TTabSheet;
    tabDownload: TTabSheet;
    txDownloadDir: TLabel;
    txEncryption: TLabel;
    txKbs1: TLabel;
    txKbs2: TLabel;
    txPeerLimit: TLabel;
    txPort: TLabel;
    procedure btOKClick(Sender: TObject);
    procedure btTestPortClick(Sender: TObject);
    procedure cbAutoAltClick(Sender: TObject);
    procedure cbBlocklistClick(Sender: TObject);
    procedure cbIdleSeedLimitClick(Sender: TObject);
    procedure cbIncompleteDirClick(Sender: TObject);
    procedure cbMaxDownClick(Sender: TObject);
    procedure cbMaxUpClick(Sender: TObject);
    procedure cbRandomPortClick(Sender: TObject);
    procedure cbSeedRatioClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Launch(MainForm: TMainForm; RpcObj: TRpc);
  private
    { private declarations }
  public
    { public declarations }
  end;

implementation

uses utils, fpjson;

{ TDaemonOptionsForm }

procedure TDaemonOptionsForm.Launch(MainForm: TMainForm; RpcObj: TRpc);
var
  req, args: TJSONObject;
  s: string;
  i, j: integer;
begin
  try
    AppBusy;
    req:=TJSONObject.Create;
    try
      req.Add('method', 'session-get');
      args:=RpcObj.SendRequest(req);
      if args <> nil then
        try
          edDownloadDir.Text:= CorrectPath(UTF8Encode(args.Strings['download-dir']));
          if RpcObj.RPCVersion >= 5 then begin
            // RPC version 5
            edPort.Value:=args.Integers['peer-port'];
            cbPEX.Checked:=args.Booleans['pex-enabled'];
            edMaxPeers.Value:=args.Integers['peer-limit-global'];
            edMaxPeersPerTorrent.Value:=args.Integers['peer-limit-per-torrent'];
            cbRandomPort.Checked:=args.Booleans['peer-port-random-on-start'];
            cbDHT.Checked:=args.Booleans['dht-enabled'];
            cbSeedRatio.Checked:=args.Booleans['seedRatioLimited'];
            edSeedRatio.Value:=args.Floats['seedRatioLimit'];
            cbBlocklist.Checked:=args.Booleans['blocklist-enabled'];

            cbAltEnabled.Checked:=args.Booleans['alt-speed-enabled'];
            edAltDown.Value:=args.Integers['alt-speed-down'];
            edAltUp.Value:=args.Integers['alt-speed-up'];
            cbAutoAlt.Checked:=args.Booleans['alt-speed-time-enabled'];
            edAltTimeBegin.Text:=FormatDateTime('hh:nn', args.Integers['alt-speed-time-begin']/MinsPerDay);
            edAltTimeEnd.Text:=FormatDateTime('hh:nn', args.Integers['alt-speed-time-end']/MinsPerDay);
            j:=args.Integers['alt-speed-time-day'];
            for i:=1 to 7 do begin
              TCheckBox(gbAltSpeed.FindChildControl(Format('cbDay%d', [i]))).Checked:=LongBool(j and 1);
              j:=j shr 1;
            end;
            cbAutoAltClick(nil);
          end
          else begin
            // RPC versions prior to v5
            cbPortForwarding.Top:=cbRandomPort.Top;
            edPort.Value:=args.Integers['port'];
            cbPEX.Checked:=args.Integers['pex-allowed'] <> 0;
            edMaxPeers.Value:=args.Integers['peer-limit'];
            edMaxPeersPerTorrent.Enabled:=False;
            cbRandomPort.Visible:=False;
            cbDHT.Visible:=False;
            cbSeedRatio.Visible:=False;
            edSeedRatio.Visible:=False;
            btTestPort.Visible:=False;
            cbBlocklist.Visible:=False;
            gbAltSpeed.Visible:=False;
          end;

          if RpcObj.RPCVersion >= 7 then begin
            cbIncompleteDir.Checked:=args.Booleans['incomplete-dir-enabled'];
            edIncompleteDir.Text:=UTF8Encode(args.Strings['incomplete-dir']);
            cbIncompleteDirClick(nil);
          end
          else begin
            cbIncompleteDir.Visible:=False;
            edIncompleteDir.Visible:=False;
          end;

          if RpcObj.RPCVersion >= 8 then
            cbPartExt.Checked:=args.Booleans['rename-partial-files']
          else
            cbPartExt.Visible:=False;

          if RpcObj.RPCVersion >= 9 then
            cbLPD.Checked:=args.Booleans['lpd-enabled']
          else
            cbLPD.Visible:=False;

          if RpcObj.RPCVersion >= 10 then begin
            edCacheSize.Value:=args.Integers['cache-size-mb'];
            cbIdleSeedLimit.Checked:=args.Booleans['idle-seeding-limit-enabled'];
            edIdleSeedLimit.Value:=args.Integers['idle-seeding-limit'];
            cbIdleSeedLimitClick(nil);
          end
          else begin
            edCacheSize.Visible:=False;
            txCacheSize.Visible:=False;
            txMB.Visible:=False;
            cbIdleSeedLimit.Visible:=False;
            edIdleSeedLimit.Visible:=False;
            txMinutes.Visible:=False;
          end;

          if args.IndexOfName('blocklist-url') >= 0 then
            edBlocklistURL.Text:=UTF8Encode(args.Strings['blocklist-url'])
          else begin
            edBlocklistURL.Visible:=False;
            cbBlocklist.Left:=cbPEX.Left;
            cbBlocklist.Caption:=StringReplace(cbBlocklist.Caption, ':', '', [rfReplaceAll]);
          end;
          cbBlocklistClick(nil);

          if RpcObj.RPCVersion >= 13 then
            cbUTP.Checked:=args.Booleans['utp-enabled']
          else
            cbUTP.Visible:=False;

          if RpcObj.RPCVersion >= 14 then begin
            tabQueue.TabVisible:=True;
            cbDownQueue.Checked:=args.Booleans['download-queue-enabled'];
            edDownQueue.Value:=args.Integers['download-queue-size'];
            cbUpQueue.Checked:=args.Booleans['seed-queue-enabled'];
            edUpQueue.Value:=args.Integers['seed-queue-size'];
            cbStalled.Checked:=args.Booleans['queue-stalled-enabled'];
            edStalledTime.Value:=args.Integers['queue-stalled-minutes'];
          end
          else
            tabQueue.TabVisible:=False;

          cbPortForwarding.Checked:=args.Booleans['port-forwarding-enabled'];
          s:=args.Strings['encryption'];
          if s = 'preferred' then
            cbEncryption.ItemIndex:=1
          else
          if s = 'required' then
            cbEncryption.ItemIndex:=2
          else
            cbEncryption.ItemIndex:=0;
          cbMaxDown.Checked:=args.Booleans['speed-limit-down-enabled'];
          edMaxDown.Value:=args.Integers['speed-limit-down'];
          cbMaxUp.Checked:=args.Booleans['speed-limit-up-enabled'];
          edMaxUp.Value:=args.Integers['speed-limit-up'];
        finally
          args.Free;
        end
      else begin
        MainForm.CheckStatus(False);
        exit;
      end;
    finally
      req.Free;
    end;
    cbMaxDownClick(nil);
    cbMaxUpClick(nil);
    cbRandomPortClick(nil);
    cbSeedRatioClick(nil);
    AppNormal;

    if ShowModal = mrOK then begin
      AppBusy;
      Self.Update;
      req:=TJSONObject.Create;
      try
        req.Add('method', 'session-set');
        args:=TJSONObject.Create;
        args.Add('download-dir', UTF8Decode(edDownloadDir.Text));
        args.Add('port-forwarding-enabled', cbPortForwarding.Checked);
        case cbEncryption.ItemIndex of
          1: s:='preferred';
          2: s:='required';
          else s:='tolerated';
        end;
        args.Add('encryption', s);
        args.Add('speed-limit-down-enabled', cbMaxDown.Checked);
        if cbMaxDown.Checked then
          args.Add('speed-limit-down', edMaxDown.Value);
        args.Add('speed-limit-up-enabled', cbMaxUp.Checked);
        if cbMaxUp.Checked then
          args.Add('speed-limit-up', edMaxUp.Value);
        if RpcObj.RPCVersion >= 5 then begin
          args.Add('peer-limit-global', edMaxPeers.Value);
          args.Add('peer-limit-per-torrent', edMaxPeersPerTorrent.Value);
          args.Add('peer-port', edPort.Value);
          args.Add('pex-enabled', cbPEX.Checked);
          args.Add('peer-port-random-on-start', cbRandomPort.Checked);
          args.Add('dht-enabled', cbDHT.Checked);
          args.Add('seedRatioLimited', cbSeedRatio.Checked);
          if cbSeedRatio.Checked then
            args.Add('seedRatioLimit', edSeedRatio.Value);
          args.Add('blocklist-enabled', cbBlocklist.Checked);

          args.Add('alt-speed-enabled', cbAltEnabled.Checked);
          args.Add('alt-speed-down', edAltDown.Value);
          args.Add('alt-speed-up', edAltUp.Value);
          args.Add('alt-speed-time-enabled', cbAutoAlt.Checked);
          if cbAutoAlt.Checked then begin
            args.Add('alt-speed-time-begin', Round(Frac(StrToTime(edAltTimeBegin.Text))*MinsPerDay));
            args.Add('alt-speed-time-end', Round(Frac(StrToTime(edAltTimeEnd.Text))*MinsPerDay));
            j:=0;
            for i:=7 downto 1 do begin
              j:=j shl 1;
              j:=j or (integer(TCheckBox(gbAltSpeed.FindChildControl(Format('cbDay%d', [i]))).Checked) and 1);
            end;
            args.Add('alt-speed-time-day', j);
          end;
        end
        else begin
          args.Add('peer-limit', edMaxPeers.Value);
          args.Add('port', edPort.Value);
          args.Add('pex-allowed', cbPEX.Checked);
        end;
        if RpcObj.RPCVersion >= 7 then begin
          args.Add('incomplete-dir-enabled', cbIncompleteDir.Checked);
          if cbIncompleteDir.Checked then
            args.Add('incomplete-dir', UTF8Decode(edIncompleteDir.Text));
        end;
        if RpcObj.RPCVersion >= 8 then
          args.Add('rename-partial-files', cbPartExt.Checked);
        if RpcObj.RPCVersion >= 9 then
          args.Add('lpd-enabled', cbLPD.Checked);
        if RpcObj.RPCVersion >= 10 then begin
          args.Add('cache-size-mb', edCacheSize.Value);
          args.Add('idle-seeding-limit-enabled', cbIdleSeedLimit.Checked);
          args.Add('idle-seeding-limit', edIdleSeedLimit.Value);
        end;
        if edBlocklistURL.Visible then
          if cbBlocklist.Checked then
            args.Add('blocklist-url', UTF8Decode(edBlocklistURL.Text));
        if RpcObj.RPCVersion >= 13 then
          args.Add('utp-enabled', cbUTP.Checked);
        if RpcObj.RPCVersion >= 14 then begin
          args.Add('download-queue-enabled', cbDownQueue.Checked);
          args.Add('download-queue-size', edDownQueue.Value);
          args.Add('seed-queue-enabled', cbUpQueue.Checked);
          args.Add('seed-queue-size', edUpQueue.Value);
          args.Add('queue-stalled-enabled', cbStalled.Checked);
          args.Add('queue-stalled-minutes', edStalledTime.Value);
        end;

        req.Add('arguments', args);
        args:=RpcObj.SendRequest(req, False);
        if args = nil then begin
          MainForm.CheckStatus(False);
          exit;
        end;
        args.Free;
      finally
        req.Free;
      end;
      RpcObj.RefreshNow:=RpcObj.RefreshNow + [rtSession];
      AppNormal;
    end;
  finally
    Free;
  end;
end;

procedure TDaemonOptionsForm.cbMaxDownClick(Sender: TObject);
begin
  edMaxDown.Enabled:=cbMaxDown.Checked;
end;

procedure TDaemonOptionsForm.btTestPortClick(Sender: TObject);
var
  req, res: TJSONObject;
begin
  AppBusy;
  req:=TJSONObject.Create;
  try
    req.Add('method', 'port-test');
    res:=RpcObj.SendRequest(req, False);
    AppNormal;
    if res = nil then
      MainForm.CheckStatus(False)
    else
      if res.Objects['arguments'].Booleans['port-is-open'] then
        MessageDlg(sPortTestSuccess, mtInformation, [mbOk], 0)
      else
        MessageDlg(sPortTestFailed, mtError, [mbOK], 0);
    res.Free;
  finally
    req.Free;
  end;
end;

procedure TDaemonOptionsForm.cbAutoAltClick(Sender: TObject);
var
  i: integer;
begin
  edAltTimeBegin.Enabled:=cbAutoAlt.Checked;
  edAltTimeEnd.Enabled:=cbAutoAlt.Checked;
  txFrom.Enabled:=cbAutoAlt.Checked;
  txTo.Enabled:=cbAutoAlt.Checked;
  txDays.Enabled:=cbAutoAlt.Checked;
  for i:=1 to 7 do
    gbAltSpeed.FindChildControl(Format('cbDay%d', [i])).Enabled:=cbAutoAlt.Checked;
end;

procedure TDaemonOptionsForm.cbBlocklistClick(Sender: TObject);
begin
  if not edBlocklistURL.Visible then
    exit;
  edBlocklistURL.Enabled:=cbBlocklist.Checked;
  if edBlocklistURL.Enabled then
    edBlocklistURL.Color:=clWindow
  else
    edBlocklistURL.ParentColor:=True;
end;

procedure TDaemonOptionsForm.cbIdleSeedLimitClick(Sender: TObject);
begin
  edIdleSeedLimit.Enabled:=cbIdleSeedLimit.Checked;
end;

procedure TDaemonOptionsForm.btOKClick(Sender: TObject);
begin
  edDownloadDir.Text:=Trim(edDownloadDir.Text);
  if edDownloadDir.Text = '' then begin
    Page.ActivePage:=tabDownload;
    edDownloadDir.SetFocus;
    MessageDlg(SNoDownloadDir, mtError, [mbOK], 0);
    exit;
  end;
  edIncompleteDir.Text:=Trim(edIncompleteDir.Text);
  if cbIncompleteDir.Checked and (edIncompleteDir.Text = '') then begin
    Page.ActivePage:=tabDownload;
    edIncompleteDir.SetFocus;
    MessageDlg(SNoIncompleteDir, mtError, [mbOK], 0);
    exit;
  end;
  edBlocklistURL.Text:=Trim(edBlocklistURL.Text);
  if cbAutoAlt.Checked then begin
    if StrToTimeDef(edAltTimeBegin.Text, -1) < 0 then begin
      Page.ActivePage:=tabBandwidth;
      edAltTimeBegin.SetFocus;
      MessageDlg(SInvalidTime, mtError, [mbOK], 0);
      exit;
    end;
    if StrToTimeDef(edAltTimeEnd.Text, -1) < 0 then begin
      Page.ActivePage:=tabBandwidth;
      edAltTimeEnd.SetFocus;
      MessageDlg(SInvalidTime, mtError, [mbOK], 0);
      exit;
    end;
  end;
  ModalResult:=mrOK;
end;

procedure TDaemonOptionsForm.cbIncompleteDirClick(Sender: TObject);
begin
  edIncompleteDir.Enabled:=cbIncompleteDir.Checked;
  if edIncompleteDir.Enabled then
    edIncompleteDir.Color:=clWindow
  else
    edIncompleteDir.ParentColor:=True;
end;

procedure TDaemonOptionsForm.cbMaxUpClick(Sender: TObject);
begin
  edMaxUp.Enabled:=cbMaxUp.Checked;
end;

procedure TDaemonOptionsForm.cbRandomPortClick(Sender: TObject);
begin
  edPort.Enabled:=not cbRandomPort.Checked;
end;

procedure TDaemonOptionsForm.cbSeedRatioClick(Sender: TObject);
begin
  edSeedRatio.Enabled:=cbSeedRatio.Checked;
end;

procedure TDaemonOptionsForm.FormCreate(Sender: TObject);
var
  i, j, x, wd: integer;
  cb: TCheckBox;
begin
  bidiMode := GetBiDi();
  Page.ActivePageIndex:=0;
  cbEncryption.Items.Add(sEncryptionDisabled);
  cbEncryption.Items.Add(sEncryptionEnabled);
  cbEncryption.Items.Add(sEncryptionRequired);
  Buttons.OKButton.ModalResult:=mrNone;
  Buttons.OKButton.OnClick:=@btOKClick;

  x:=edAltTimeBegin.Left;
  wd:=(gbAltSpeed.ClientWidth - x - BorderWidth) div 7;
  for i:=1 to 7 do begin
    cb:=TCheckBox.Create(gbAltSpeed);
    cb.Parent:=gbAltSpeed;
    j:=i + 1;
    if j > 7 then
      Dec(j, 7);
    cb.Caption:=SysToUTF8(FormatSettings.ShortDayNames[j]);
    cb.Name:=Format('cbDay%d', [j]);
    cb.Left:=x;
    cb.Top:=txDays.Top - (cb.Height - txDays.Height) div 2;
    Inc(x, wd);
  end;
end;

initialization
  {$I daemonoptions.lrs}

end.

