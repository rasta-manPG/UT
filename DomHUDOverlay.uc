class DomHUDOverlay extends Mutator config(User);

var bool bHUDMutatorSet;
var bool bShowDOMHUD;
var Texture WhiteTex;
var FontInfo MyFonts;

var ControlPoint CPList[16]; 
var int NumPoints;

struct TeamPossession {
    var float RedTime;
    var float BlueTime;
};
var TeamPossession PointStats[16]; 

replication
{
    reliable if ( Role == ROLE_Authority )
        PointStats, CPList, NumPoints, bShowDOMHUD;
}

function ModifyPlayer(Pawn Other)
{
    local DomHUDHelper Helper;
    local bool bFound;

    if (NextMutator != None)
        NextMutator.ModifyPlayer(Other);

    if (PlayerPawn(Other) != None)
    {
        foreach AllActors(class'DomHUDHelper', Helper)
        {
            if (Helper.OwnerPlayer == Other)
            {
                bFound = true;
                break;
            }
        }

        if (!bFound)
        {
            Helper = Spawn(class'DomHUDHelper', Other);
            Helper.ParentMutator = Self;
            Helper.OwnerPlayer = PlayerPawn(Other);
        }
    }
}

function Mutate(string MutateString, PlayerPawn Sender)
{
    if (MutateString ~= "ToggleDOMHUD")
    {
        bShowDOMHUD = !bShowDOMHUD;
        SaveConfig();
        Sender.ClientMessage("DOM HUD Overlay: " $ bShowDOMHUD);
    }

    if (NextMutator != None)
        NextMutator.Mutate(MutateString, Sender);
}

function PostBeginPlay()
{
    local ControlPoint CP;
    Super.PostBeginPlay();
    
    NumPoints = 0;
    foreach AllActors(class'ControlPoint', CP)
    {
        if (NumPoints < 16)
        {
            CPList[NumPoints] = CP;
            NumPoints++;
        }
    }
}

function Tick(float DeltaTime)
{
    local int i;
    if (Level.Game != None && !Level.Game.bGameEnded)
    {
        for (i = 0; i < NumPoints; i++)
        {
            if (CPList[i] != None && CPList[i].ControllingTeam != None)
            {
                if (CPList[i].ControllingTeam.TeamIndex == 0) PointStats[i].RedTime += DeltaTime;
                else if (CPList[i].ControllingTeam.TeamIndex == 1) PointStats[i].BlueTime += DeltaTime;
            }
        }
    }
}

simulated function PostRender(Canvas Canvas)
{
    local float TotalTime, RedRatio;
    local float BarWidth, BarHeight, BarX, ScaleRatio, CurrentHUDScale;
    local int i;
    local float CurrentPosY; 
    local string RedPct, BluePct;
    local ChallengeHUD CHUD;

    if (!bShowDOMHUD || Canvas == None) return;

    // --- LOGICA DE SCALARE ---
    CHUD = ChallengeHUD(Canvas.Viewport.Actor.myHUD);
    if (CHUD != None)
        CurrentHUDScale = CHUD.HUDScale;
    else
        CurrentHUDScale = 1.0;

    ScaleRatio = CurrentHUDScale / 0.4; // 0.4 este baza ta originala
    // -------------------------

    Canvas.Style = 1; 
    Canvas.bNoSmooth = True;

    if (MyFonts == None)
    {
        if (CHUD != None)
            MyFonts = CHUD.MyFonts;
        
        if (MyFonts == None) return;
    }

    if (WhiteTex == None) WhiteTex = Texture'Engine.WhiteTexture';

    // Aplicam ScaleRatio pe dimensiunile de baza
    BarWidth = 7 * ScaleRatio; 
    BarHeight = 33 * ScaleRatio; 
    BarX = 45 * ScaleRatio;
    
    Canvas.Font = MyFonts.GetStaticSmallFont(Canvas.ClipX);

    for (i = 0; i < NumPoints; i++)
    {
        // Scalam si pozitiile verticale (Y)
        if (i == 0) CurrentPosY = Canvas.ClipY - (397 * ScaleRatio); 
        else if (i == 1) CurrentPosY = Canvas.ClipY - (313 * ScaleRatio); 
        else if (i == 2) CurrentPosY = Canvas.ClipY - (229 * ScaleRatio); 
        else CurrentPosY = Canvas.ClipY - (50 * ScaleRatio) - (i * 84 * ScaleRatio); 

        TotalTime = PointStats[i].RedTime + PointStats[i].BlueTime;
        
        // Bordura
        Canvas.SetPos(BarX - 1, CurrentPosY - 1);
        Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
        Canvas.DrawRect(WhiteTex, BarWidth + 2, BarHeight + 2);
        
        // Fundal Bar
        Canvas.SetPos(BarX, CurrentPosY);
        Canvas.DrawColor.R = 40; Canvas.DrawColor.G = 40; Canvas.DrawColor.B = 40;
        Canvas.DrawRect(WhiteTex, BarWidth, BarHeight);
        
        if (TotalTime > 0)
        {
            RedRatio = PointStats[i].RedTime / TotalTime;
            BluePct = int((1.0 - RedRatio) * 100) $ "%";
            RedPct = int(RedRatio * 100) $ "%";

            // Echipa Albastra (Cyan)
            Canvas.SetPos(BarX, CurrentPosY);
            Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
            Canvas.DrawRect(WhiteTex, BarWidth, BarHeight * (1.0 - RedRatio));

            // Echipa Rosie
            Canvas.SetPos(BarX, CurrentPosY + (BarHeight * (1.0 - RedRatio)));
            Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;
            Canvas.DrawRect(WhiteTex, BarWidth, BarHeight * RedRatio);

            // Text Procente (Pozitionat relativ la ScaleRatio)
            Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
            Canvas.SetPos(BarX + BarWidth + (5 * ScaleRatio), CurrentPosY + (BarHeight * (1.0 - RedRatio)) / 2 - (5 * ScaleRatio)); 
            Canvas.DrawText(BluePct, false);

            Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;
            Canvas.SetPos(BarX + BarWidth + (5 * ScaleRatio), CurrentPosY + (BarHeight * (1.0 - RedRatio)) + (BarHeight * RedRatio) / 2 - (5 * ScaleRatio));
            Canvas.DrawText(RedPct, false);
        }
    }
}

defaultproperties
{
    bShowDOMHUD=True
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}
