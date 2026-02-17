class DomHUDHelper extends Mutator;

var DomHUDOverlay ParentMutator;
var bool bHUDMutatorSet;
var PlayerPawn OwnerPlayer;

// Folosim o variabilă locală pentru înlănțuire, evitând variabila 'const' din clasa părinte
var Mutator LocalNextHUDMutator; 

replication
{
    // Replicăm referințele necesare de la server la client
    reliable if ( Role == ROLE_Authority )
        ParentMutator, OwnerPlayer;
}

simulated function Tick(float DeltaTime)
{
    // Executăm logica doar pe clientul care deține acest HUD
    if (Level.NetMode != NM_DedicatedServer && !bHUDMutatorSet)
    {
        if (OwnerPlayer != None && OwnerPlayer.myHUD != None)
        {
            // Injectăm Helper-ul în lanțul de randare al HUD-ului
            LocalNextHUDMutator = OwnerPlayer.myHUD.HUDMutator;
            OwnerPlayer.myHUD.HUDMutator = Self;
            
            bHUDMutatorSet = true;
            // Oprirea Tick-ului după ce injectarea a reușit pentru a economisi resurse
            Disable('Tick'); 
        }
    }
}

simulated function PostRender(Canvas Canvas)
{
    // 1. Apelăm logica de desenare a barelor din Mutatorul principal
    if (ParentMutator != None)
    {
        ParentMutator.PostRender(Canvas);
    }

    // 2. Continuăm lanțul de randare către următorul mutator de HUD (dacă există)
    if (LocalNextHUDMutator != None)
    {
        LocalNextHUDMutator.PostRender(Canvas);
    }
}

defaultproperties
{
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}


