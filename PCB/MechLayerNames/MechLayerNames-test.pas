{.................................................................................
 Summary   This script can be used to export mech layer info to a text *.ini file.
           Works on PcbDoc & PcbLib files.
           Mechanical layer Names, Colours and MechanicalPairs can be
           exported/imported to another PcbDoc/PcbLib file

  From script by:    Petar Perisin
  url: https://github.com/Altium-Designer-addons/scripts-libraries/tree/master/MechLayerNames

  Modified by: B Miller

 v 0.22 
 03/07/2017  :  mod to fix layer names output, why was import okay ??
 23/02/2018  :  added MechLayer Pairs & colours
 27/02/2018  :  MechPair detect logic; only remove existing if any MPs detected in file
 16/06/2019  :  Test for AD19 etc.
01/07/2019   :  messed with MechPair DNW; added MinMax MechLayer constants to report

         tbd :  Use Layer Classes test in AD17 & AD19
..................................................................................}

{.................................................................................}
var
    Board      : IPCB_Board;
    LayerStack : IPCB_LayerStack;
    LayerObj   : IPCB_LayerObject;
    LayerClass : TLayerClassID;
    MechLayer  : IPCB_MechanicalLayer;
    MechPairs  : IPCB_MechanicalLayerPairs;
    MechPair   : TMechanicalLayerPair;
    Layer      : TLayer;

function LayerClassName (LClass : TLayerClassID) : WideString;
begin
//Type: TLayerClassID
    case LClass of
    eLayerClass_All           : Result := 'All';
    eLayerClass_Mechanical    : Result := 'Mechanical';
    eLayerClass_Physical      : Result := 'Physical';
    eLayerClass_Electrical    : Result := 'Electrical';
    eLayerClass_Dielectric    : Result := 'Dielectric';
    eLayerClass_Signal        : Result := 'Signal';
    eLayerClass_InternalPlane : Result := 'Internal Plane';
    eLayerClass_SolderMask    : Result := 'Solder Mask';
    eLayerClass_Overlay       : Result := 'Overlay';
    eLayerClass_PasteMask     : Result := 'Paste mask';
    else                        Result := 'Unknown';
    end;
end;

Procedure ExportMechLayerInfoTest;
var
   WS          : IWorkspace;
   // LayStack_V7 : IPCB_LayerStack_V7;
   // LayObj_V7   : IPCB_LayerObject_V7;
   i, j        : Integer;
   SaveDialog  : TSaveDialog;
   Flag        : Integer;
   FileName    : String;
   INIFile     : TIniFile;
   TempS       : TStringList;
   temp        : integer;
   LayerName   : WideString;
   LayerPos    : WideString;

begin
   Board := PCBServer.GetCurrentPCBBoard;
   if Board = nil then exit;
   WS := GetWorkSpace;
   FileName := WS.DM_FocusedDocument.DM_FullPath;
   FileName := ExtractFilePath(FileName);

{   SaveDialog        := TSaveDialog.Create(Application);
   SaveDialog.FileName := FileName;
   SaveDialog.Title  := 'Save Mech Layer Names to *.ini file';
   SaveDialog.Filter := 'INI file (*.ini)|*.ini';

   Flag := SaveDialog.Execute;
   if (not Flag) then exit;

   FileName := SaveDialog.FileName;

   // Set file extension
   FileName := ChangeFileExt(FileName, '.ini');
   IniFile := TIniFile.Create(FileName);
}

    Client.GetProductVersion;

    TempS := TStringList.Create;

    TempS.Add(Client.GetProductVersion);
    TempS.Add('');
    TempS.Add(' ----- LayerStack(eLayerClass) ------');

    LayerStack := Board.LayerStack;

    for LayerClass := eLayerClass_All to eLayerClass_PasteMask do
    begin
        TempS.Add('');
        TempS.Add('eLayerClass ' + IntToStr(LayerClass) + '  ' + LayerClassName(LayerClass));

        i := 1;
        LayerObj := LayerStack.First(LayerClass);
        While (LayerObj <> Nil ) do
        begin
            LayerPos :=' ';
            if LayerClass = eLayerClass_Electrical then
               LayerPos := IntToStr(Board.LayerPositionInSet(AllLayers, LayerObj));       // think this only applies to eLayerClass_Electrical

           TempS.Add('lc.i : ' + IntToStr(LayerClass) + '.' + IntToStr(i) + ' | ' + LayerPos + '  name: ' + LayerObj.Name);
//       if LayerObj <> Nil then MechLayer := LayerObj;
           LayerObj := LayerStack.Next(Layerclass, LayerObj);
           Inc(i);
        end;
    end;

    TempS.Add('');
    TempS.Add('');
    TempS.Add('Layers constants: ');
    TempS.Add('MaxRouteLayer = ' +  IntToStr(MaxRouteLayer) +' |  MaxBoardLayer = ' + IntToStr(MaxBoardLayer) );
    TempS.Add(' MinLayer = ' + IntToStr(MinLayer) + '   | MaxLayer = ' + IntToStr(MaxLayer) );
    TempS.Add(' MinMechanicalLayer = ' + IntToStr(MinMechanicalLayer) + '  | MaxMechanicalLayer =' + IntToStr(MaxMechanicalLayer) );
    TempS.Add('');
    TempS.Add(' ----- .LayerObject(index) Mechanical ------');
    TempS.Add('');
    
 
    for i := 1 to 32 do
    begin
        Layer := i + MinMechanicalLayer - 1;
        LayerObj := LayerStack.LayerObject[Layer];
        LayerName := 'Broken method NO name';
        if LayerObj <> Nil then                  // 3 different indices for the same object info, Fg Madness!!!
            LayerName := LayerObj.Name;
        TempS.Add(IntToStr(i) + ' ' + IntToStr(Layer) + ' ' + Board.LayerName(ILayer.MechanicalLayer(i)) + ' ' + LayerName);
        // LayerObj.UsedByPrims;
    end;

{
Function  LayerPositionInSet(ALayerSet : TLayerSet; ALayerObj : IPCB_LayerObject)  : Integer;
 ex. where do layer consts come from??            VV             VV
      LowPos  := PCBBoard.LayerPositionInSet( SignalLayers + InternalPlanes, LowLayerObj);
      HighPos := PCBBoard.LayerPositionInSet( SignalLayers + InternalPlanes, HighLayerObj);
}
{ LayerPair[I : Integer] property defines indexed layer pairs and returns a TMechanicalLayerPair record of two PCB layers.
  TMechanicalLayerPair = Record
    Layer1 : TLayer;
    Layer2 : TLayer;
  End;
}
    TempS.Add('');
    TempS.Add('');
    TempS.Add(' ----- MechLayerPairs Legacy 1 to 32?? -----');
    TempS.Add('');

    MechPairs := Board.MechanicalPairs;

    TempS.Add('Mech Layer Pair Count : ' + IntToStr(MechPairs.Count));

    for j := 0 to (MechPairs.Count - 1) do
    begin
        MechPair := MechPairs.LayerPair[j];
        if MechPair <> Nil then
        begin
{
TMechanicalLayerPair = Record
Layer1 : TLayer;
Layer2 : TLayer;
End;
}
//            MechPair ;   //  .Layer1;             // does NOT work
//            Layer := MechPair.GetTypeInfoCount(0);         //__TMechanicalLayerPair__Wrapper
//            Layer := MechPair;

//     FFS !! why is MechPair Layer properties not the same/similar to DrillPairs.

//            MechPair.GetTypeInfoCount(temp);
//            IniFile.WriteString('MechLayer' + IntToStr(MechPair[0]), 'Pair',    Board.LayerName(MechPair[0]) );
//            IniFile.WriteString('MechLayer' + IntToStr(MechPair[1]), 'Pair',    Board.LayerName(MechPair[1]) );
        end;
    end;

  // mickey mouse soln

    for i := 1 to 32 do 
//  for Layer := MinMechanicalLayer to MaxMechanicalLayer do
    begin
        Layer := i + MinMechanicalLayer - 1;
        MechLayer := LayerStack.LayerObject[Layer];      // this method does not work above eMech24 !!

//        if (MechLayer <> Nil) or true then            // this test STOPS layers above some eMech showing up !!
//        begin

//        if MechPairs.LayerUsed(Layer) then         // always false ! ; pass it (MechLayer) & will crash!
//        begin
            for j := (i + 1) to 32 do
            begin
                if MechPairs.PairDefined(ILayer.MechanicalLayer(i), ILayer.MechanicalLayer(j)) then
                    TempS.Add('MechLayer ' + IntToStr(i) + '-' + IntToStr(j) + ' Pair ' + Board.LayerName(ILayer.MechanicalLayer(i)) + ' - ' + Board.LayerName(ILayer.MechanicalLayer(j)) );
            end;

//        IniFile.WriteBool  ('MechLayer' + IntToStr(i), 'Enabled', MechLayer.MechanicalLayerEnabled);
//        IniFile.WriteBool  ('MechLayer' + IntToStr(i), 'Show',    MechLayer.IsDisplayed[Board]);
//        IniFile.WriteBool  ('MechLayer' + IntToStr(i), 'Sheet',   MechLayer.LinkToSheet);
//        IniFile.WriteBool  ('MechLayer' + IntToStr(i), 'SLM',     MechLayer.DisplayInSingleLayerMode);
//        IniFile.WriteString('MechLayer' + IntToStr(i), 'Color',   ColorToString(Board.LayerColor[MechLayer.V6_LayerID]));

//        end;

    end;

    WS := GetWorkSpace;
    FileName := WS.DM_FocusedDocument.DM_FullPath;
    FileName := ExtractFilePath(FileName) + '\mechlayername.txt';

    TempS.SaveToFile(FileName);
    Exit;

end;


Procedure ImportMechLayerInfoDummy(dummy : integer);
var
    temp : boolean;
begin

    ShowInfo('The names & colours assigned to layers (& mech pairs) have been updated.');
end;

{
// Use of LayerObject method to display specific layers
    Var
       Board      : IPCB_Board;
       Stack      : IPCB_LayerStack;
       LyrObj     : IPCB_LayerObject;
       Layer        : TLayer;

    Begin
       Board := PCBServer.GetCurrentPCBBoard;
       Stack := Board.LayerStack;
       for Lyr := eMechanical1 to eMechanical16 do
       begin
          LyrObj := Stack.LayerObject[Lyr];
          If LyrObj.MechanicalLayerEnabled then ShowInfo(LyrObj.Name);
       end;
    End;
}
{ //copper layers     below is for drill pairs need to get top & bottom copper.
     LowLayerObj  : IPCB_LayerObject;
     HighLayerObj : IPCB_LayerObject;
     LowPos       : Integer;
     HighPos      : Integer;
     LowLayerObj  := PCBBoard.LayerStack.LayerObject[PCBLayerPair.LowLayer];
     HighLayerObj := PCBBoard.LayerStack.LayerObject[PCBLayerPair.HighLayer];
     LowPos       := PCBBoard.LayerPositionInSet(SignalLayers, LowLayerObj);
     HighPos      := PCBBoard.LayerPositionInSet(SignalLayers, HighLayerObj);
}
{   TheLayerStack := PCBBoard.LayerStack_V7;
    If TheLayerStack = Nil Then Exit;
    LS       := '';
    LayerObj := TheLayerStack.FirstLayer;
    Repeat
        LS       := LS + Layer2String(LayerObj.LayerID) + #13#10;
        LayerObj := TheLayerStack.NextLayer(LayerObj);
    Until LayerObj = Nil;
}

{  // better to use later method ??
   Stack      : IPCB_LayerStack;
   Lyr        : TLayer;
   for Lyr := eTopLayer to eBottomLayer do
   for Lyr := eMechanical1 to eMechanical16 do  // but eMechanical17 - eMechanical32 are NOT defined ffs.
       LyrObj := Stack.LayerObject[Lyr];
}
