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
    reliable if ( Role == ROLE_Authority || bNetInitial)
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
    local int BarWidth, BarHeight, i, BarX;
    local string RedPct, BluePct;
    local int CurrentPosY; 

    if (!bShowDOMHUD || Canvas == None) return;

    Canvas.Style = 1; 
    Canvas.bNoSmooth = True;

    if (MyFonts == None)
    {
        if (Canvas.Viewport.Actor.myHUD != None && ChallengeHUD(Canvas.Viewport.Actor.myHUD) != None)
            MyFonts = ChallengeHUD(Canvas.Viewport.Actor.myHUD).MyFonts;
        
        if (MyFonts == None) return;
    }

    if (WhiteTex == None) WhiteTex = Texture'Engine.WhiteTexture';

    BarWidth = 7; BarHeight = 33; BarX = 45;
    Canvas.Font = MyFonts.GetStaticSmallFont(Canvas.ClipX);

    for (i = 0; i < NumPoints; i++)
    {
        if (i == 0) CurrentPosY = Canvas.ClipY - 397; 
        else if (i == 1) CurrentPosY = Canvas.ClipY - 313; 
        else if (i == 2) CurrentPosY = Canvas.ClipY - 229; 
        else CurrentPosY = Canvas.ClipY - 50 - (i * 84); 

        TotalTime = PointStats[i].RedTime + PointStats[i].BlueTime;
        
        Canvas.SetPos(BarX - 1, CurrentPosY - 1);
        Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
        Canvas.DrawRect(WhiteTex, BarWidth + 2, BarHeight + 2);
        
        Canvas.SetPos(BarX, CurrentPosY);
        Canvas.DrawColor.R = 40; Canvas.DrawColor.G = 40; Canvas.DrawColor.B = 40;
        Canvas.DrawRect(WhiteTex, BarWidth, BarHeight);
        
        if (TotalTime > 0)
        {
            RedRatio = PointStats[i].RedTime / TotalTime;
            BluePct = int((1.0 - RedRatio) * 100) $ "%";
            RedPct = int(RedRatio * 100) $ "%";

            Canvas.SetPos(BarX, CurrentPosY);
            Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
            Canvas.DrawRect(WhiteTex, BarWidth, BarHeight * (1.0 - RedRatio));

            Canvas.SetPos(BarX, CurrentPosY + (BarHeight * (1.0 - RedRatio)));
            Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;
            Canvas.DrawRect(WhiteTex, BarWidth, BarHeight * RedRatio);

            Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
            Canvas.SetPos(BarX + BarWidth + 5, CurrentPosY + (BarHeight * (1.0 - RedRatio)) / 2 - 5); 
            Canvas.DrawText(BluePct, false);

            Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;
            Canvas.SetPos(BarX + BarWidth + 5, CurrentPosY + (BarHeight * (1.0 - RedRatio)) + (BarHeight * RedRatio) / 2 - 5);
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
