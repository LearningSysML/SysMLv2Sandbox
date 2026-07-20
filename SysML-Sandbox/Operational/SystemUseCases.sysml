package SystemUseCases {

    // Import the Domain package for referencing actors
    private import NaturalEnvironment::*;
    private import Structures::*;
    private import OperationalDomain::*;
    private import ScalarValues::*;
    private import StdPortsAndInterfaces::ImperialTechnology::ImperialStandardItems::*;
    private import COTS::*;
    private import PilotPodsAndSpaceships::*;
    private import MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::*;

    //Use Cases of the Mining Frigate. 
    //Define the operational sequence of interactions between the system of interest and the actors
    //The Use Cases are defined for any configuration of mining frigate
    //Main use cases

    use case def MineAsteroids {
        subject highSecMiningFrigate :> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate {
            event activateMiningLaser.targetEvent;
            event asteroidDeintegration.targetEvent;
            event miningReport.sourceEvent;
            event oreHoldFull.sourceEvent;
            event asteroidDepletion.targetEvent;
        } 
        actor pilotPod : PilotPod {
            event activateMiningLaser.sourceEvent;
            event miningReport.targetEvent;
            event oreHoldFull.targetEvent;
        }

        actor asteroid : Asteroid [1..*] {
            event asteroidDeintegration.sourceEvent;
            then event asteroidDepletion.sourceEvent;
        }       
        objective {
            doc /* Main Flow:
                  * 1. Activate mining lasers to extract ore.
                  *
                  * Exception Flows:
                  * - If the cargo hold is full, suspend mining and notify the pilot to return to a station for offloading.
                  */
        }

        message activateMiningLaser of ShipCommand; //messages between the pilotPod and the mining frigate
        then message asteroidDeintegration of Ore;
        then message miningReport of ShipCommand;
        then message oreHoldFull of ShipCommand;
        message asteroidDepletion of Ore;
    }

    use case def MonitorAndDetectThreats {
        subject highSecMiningFrigate ::> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate {
            event signatureEmission.targetEvent;
            event directionalScan.targetEvent;
            event scanGrid.targetEvent;
            then event scanReport.sourceEvent;
        }
        actor pilotPod : PilotPod {
            event directionalScan.sourceEvent;
            event scanGrid.sourceEvent;
            event scanReport.targetEvent;
        }
        actor hostilePilotPod : HostilePilotPod [0..*] {
            event signatureEmission.sourceEvent; //all bodies emmit constantly gravimetric waves.
            then snapshot destroyed; //if all goes well...
        }

        objective {
            doc /* Main Flow:
                  * 1. Monitor threats within the grid range.
                  * 2. Detect threats beyond the grid range using the directional sensor array.
                  */
        }
        message signatureEmission of GravitationalField;
        message scanGrid of ShipCommand;
        message directionalScan of ShipCommand;
        then message scanReport of ShipReport;
    }

    use case def DeployDefenseDrones { //needs further detail
        subject highSecMiningFrigate ::> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate;
        actor pilotPod : PilotPod;
        actor hostilePilotPod : HostilePilotPod [1..*];
        actor drone : Drone [2];
        objective {
            doc /* Main Flow:
                  * 1. Deploy two controlled drones in space.
                  * 2. Set drones mode
                  * 3. Recall drones to drone bay.
                  *
                * Alternate Flows:
                  * 1. If drones are lost or destroyed, deploy further drones if available in the drone bay.
                  */
        }
        message dronesDeploy of ShipCommand;
        message dronesGuardMode of ShipCommand;
        message dronesRecall of ShipCommand;
        message dronesReconnect of ShipCommand;
        message dronesSatatus of ShipReport;
    }

    use case def DockToStation {
        subject highSecMiningFrigate ::> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate {
            event dockInStation.targetEvent;
            include use case approachSignature defined by ApproachSignature {
                subject :>> highSecMiningFrigate = approachSignature.highSecMiningFrigate;
                actor :>> pilotPod = approachSignature.pilotPod;
                actor :>> station = approachSignature.gridSigantureBody; //reusing gridSignature as station for signature emission
            }
            event dockingRequest.sourceEvent;
            event dockingApproval.targetEvent;
            event dockApproved.sourceEvent;
        }
        actor pilotPod : PilotPod {
            event dockInStation.sourceEvent;
            event dockApproved.targetEvent;
            
        }
        actor station : CelestialSignature {
            event dockingRequest.targetEvent;
            event dockingApproval.sourceEvent;
        }
        objective {
            doc /* Main Flow:
                  * 1. Select station signature
                  * 2. Automatically approach to signature and dock in station
                  */
        }
        message dockInStation of ShipCommand;
        then message dockingRequest of StationCommand;
        then message dockingApproval of StationReport;
        then message dockApproved of ShipReport;
    }

    use case def WarpToCelestial {
        subject highSecMiningFrigate ::> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate {        
            event celestialSignatureToWarp.targetEvent;
            event executeWarp.targetEvent; 
            event warpDriveActive.sourceEvent;
            event warpDestinationReached.sourceEvent;    
        }
        actor pilotPod : PilotPod {
            event executeWarp.sourceEvent;
            event warpDriveActive.targetEvent;
            event warpDestinationReached.targetEvent;
        }
        actor celestialSignature : CelestialSignature {
            event celestialSignatureToWarp.sourceEvent;
        }

        objective {
            doc /* Main Flow:
                  * 1. Accept a celestial destination from the pilot.
                  * 2. Fix the celestial signature
                  * 3. Engage the warp drive to travel along the plotted course.
                  * 4. Notify arrival after arriving to the destination.
                  */
        }
        message celestialSignatureToWarp of CelestialSignature;
        then message executeWarp of ShipCommand;
        then message warpDriveActive of ShipReport;
        then message warpDestinationReached of ShipReport;
    }

    use case def ApproachSignature {
        subject highSecMiningFrigate ::> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate {
            event gridSignature.targetEvent;
            perform action scanGridAction {
                doc /* Action: Scan the grid for the target signature using the ship's sensor array. */
                out gridReport;
            }
            event gridReport.sourceEvent;
            event approachSignatureCommand.targetEvent;
            // if destinationSignature.distance > 150 then
            include use case warpToCelestial defined by WarpToCelestial {
                subject :>> highSecMiningFrigate = warpToCelestial.highSecMiningFrigate;
                actor :>> pilotPod = warpToCelestial.pilotPod;
                actor :>> celestialSignature = warpToCelestial.celestialSignature; //reusing gridSignature as celestial signature for warp
            }
            // else
            perform action approachSignatureAction {
                doc /* Action: Plot optimal course to the target signature using the navigation system. */
            }          
        }
        actor pilotPod : PilotPod {
            event gridReport.targetEvent;
            event approachSignatureCommand.sourceEvent;
        }
        actor gridSigantureBody : CelestialSignature [1..*] {
            event gridSignature.sourceEvent;
        }
        objective {
            doc /* Main Flow:
                  * 1. Accept a signature destination from the pilot.
                  * 2. Plot the optimal course using the navigation system.
                  * 3. Notify approach to the signature destination.
                  * 4. Engage the engines to travel along the plotted course.
                  */
        }
        message gridSignature of GridSignature;
        then message gridReport of ShipReport;
        then message approachSignatureCommand of ApproachSignatureCommand;
    }

    use case def TransferOre { //needs further detail
        subject highSecMiningFrigate ::> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate {
            event cargoReport.sourceEvent;
        }
        actor pilotPod : PilotPod{
            event transferCargoCommand.sourceEvent;
            event transferConfirmation.targetEvent;
            event cargoReport.targetEvent;
        }
        actor station : Station;
            event transferCargoCommand.targetEvent;
            event transferConfirmation.sourceEvent;
        objective {
            doc /* Main Flow:
                  * 1. Transfer ore or other cargo to the appropriate storage location.
                  * 2. Verify the transfer has been completed successfully.
                  */
        }
        message transferCargoCommand of StationCommand;
        then message transferConfirmation of StationReport;
        then message cargoReport of ShipReport;
    }
    
    use case def UndockFromStation { //needs further detail
        subject configuredMiningFrigate ::> MiningFrigateBlackBoxSpecification::MinigFrigateConfigurations::highSecMiningFrigate;
        actor pilotPod : PilotPod;
        actor station : Station;
        objective {
            doc /* Main Flow:
                  * 1. Request undock from station.
                  * 2. The spaceship is beamed out of station at warp speed in a random
                  * whithin a cone of 10 degrees around the direction of the station docking port.
                  */
        }
    }
}