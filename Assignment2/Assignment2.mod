/*********************************************
 * OPL 12.6.3.0 Data
 * Author 1: Tianyu Liu (0937147), e-mail: t.liu.1@student.tue.nl
 * Author 2: Li Wang (0977456), e-mail: l.wang.3@student.tue.nl
 * Creation Date: Oct 18, 2016 at 12:53:38 PM
 *********************************************/

 using CP;
 /* 
 * Required ata structures
 * Tuples are established according to the xls file structure
 */
 tuple Product {
     key int productId;
     string name; 
 }
 {Product} Products = ...;
 
 tuple Demand {
     key string demandId;
     int productId;
     int quantity;
     int deliveryMin;
     int deliveryMax;
     float nonDeliveryVariableCost;
     int dueTime;
     float tardinessVariableCost;
 }
 {Demand} Demands = ...;
 
 tuple Resource {
     key string resourceId;
     int resourceNr;
     string setupMatrixId;
     int initialProductId; 
 }
 {Resource} Resources = ...;
 
 tuple SetupResource {
     key string setupResourceId; 
 }
 {SetupResource} SetupResources = ...;
 
 tuple StorageTank {
     key string storageTankId;
     string name;
     int quantityMax;
     string setupMatrixId;
     int initialProductId; 
 }
 {StorageTank} StorageTanks = ...;
 
 tuple StepPrototype {
     key string stepId;
     int productId;
     string setupResourceId;
 }
 {StepPrototype} Steps = ...;
 
 tuple Precedence {
     key string predecessorId;
     string successorId;
     int delayMin;
     int delayMax; 
 }
 {Precedence} Precedences = ...;
 
 tuple Alternative {
     key string stepId;
     key int alternativeNumber;
     string resourceId;
     int fixedProcessingTime;
     float variableProcessingTime;
     float fixedProcessingCost;
     float variableProcessingCost;
 }
 {Alternative} Alternatives = ...;
 
 tuple StorageProduction {
     key string prodStepId;
     key string storageTankId;
     string consStepId;
 }
 {StorageProduction} StorageProductions = ...;
 
 tuple SetupMatrix {
      key string setupMatrixId;
      key int fromState;
      key int toState;
      int setupTime;
      int setupCost;  
 }
 {SetupMatrix} Setups = ...;
 
 tuple CriterionWeight {
     key string criterionId;
     float weight; 
 }
 {CriterionWeight} CriterionWeights = ...;
 //---------------------------------------------------------
 
 
 
 /*
 * Some execute setting about tests, given in the assignment description. 
 * Using sequential search. 
 * Time limited: 1 secound per demand.
 */
 execute {
    cp.param.Workers = 1;
    cp.param.TimeLimit = Opl.card(Demands); 
    cp.param.DefaultInferenceLevel = "Extended";
 }
 
 //---------------------------------------------------------
 
 //A tuple of demands and its corrisponding steps
 tuple DemandStep {
    key Demand demand;
    key StepPrototype st; 
 }
 //The corrisponding array for all possible steps
 {DemandStep} DemSteps = 
 {<d, st> | d in Demands, st in Steps : 
        d.productId == st.productId};

 //A tuple of demands and its corrisponding steps, as well as alternatives        
 tuple DemandAlternative {
    key Demand demand;
    key StepPrototype st;
    key Alternative alternativ;
 }
 //The corrisponding array for all possible alternatives
 {DemandAlternative} DemAlter = 
 {<d, st, alter> | d in Demands, st in Steps, alter in Alternatives : 
                    d.productId == st.productId &&
                    st.stepId == alter.stepId}; 
 
 //Tuple that describes the precedence of a demand's aternatives
 tuple DemandAlternativePrecedence {
    key Demand demand;
    key Precedence pre; 
 }
 //The corrisponding array to describe all demands' alternatives' precedences
 {DemandAlternativePrecedence} DemAltPre = 
 {<d, pre> | <d, st, alter> in DemAlter, <d1, st1, alter1> in DemAlter, pre in Precedences : 
                d == d1 && 
                pre.predecessorId == st.stepId && 
                pre.successorId == st1.stepId};
                
 //Tuple for storage about a specific step/alternative
 //Suppose the steps will use a tank (it may not depends on the solver)
 tuple StepStorage {
    key StorageProduction sp;
    key DemandAlternativePrecedence dap;
    StorageTank tank;
 }
 //The array for all steps thay may use a tank
 {StepStorage} StepStorages = 
 {<sp, dap, tank> | sp in StorageProductions, dap in DemAltPre, 
                    tank in StorageTanks : sp.prodStepId == dap.pre.predecessorId && 
                    sp.consStepId == dap.pre.successorId && 
                    sp.storageTankId == tank.storageTankId};

 //Decision variables go here
 //The interval to determine the processing time of a demand
 dvar interval demandInterval[demand in Demands]
                optional; //Window time

 //The interval to determine the processing time of a step
 dvar interval demSteps[<d, st> in DemSteps]
                optional;
  
 //The interval to determine the processing time of an alternative                                  
 dvar interval demAlter[<d, st, alter> in DemAlter]
                optional
                size ftoi(ceil(alter.fixedProcessingTime + 
                        d.quantity * alter.variableProcessingTime)); //Processing time
 
 //The interval that describes the use time of a tank
 dvar interval tankUse[ss in StepStorages]
                optional //depends on whether a tank is used or not
                size ss.dap.pre.delayMin..ss.dap.pre.delayMax;                                                      
             
 dvar sequence resources[r in Resources] in
                all(da in DemAlter : 
                r.resourceId == da.alternativ.resourceId)
                demAlter[da]
                types all(da in DemAlter : 
                r.resourceId == da.alternativ.resourceId) da.st.productId;

 dvar sequence tankSequence[tank in StorageTanks] in 
                all(ss in StepStorages : 
                ss.tank == tank) tankUse[ss]
                types all(ss in StepStorages : 
                ss.tank == tank)ss.dap.demand.productId;
                
 dvar interval resourSetup[da in DemAlter]
                optional;
 dvar interval tankSetup[ss in StepStorages]
                optional;
 //An interval just to connect resource with setup resource
 
 //Tuples and arrays for setup issues (both for resources and storage tanks)               
 tuple triplet {int loc1; int loc2; int value;};
 {triplet} transitionTimesResource[r in Resources] = 
    {<setup.fromState, setup.toState, setup.setupTime> | setup in Setups : 
                    setup.setupMatrixId == r.setupMatrixId};
 {triplet} transitionTimesStorage[tank in StorageTanks] = 
    {<setup.fromState, setup.toState, setup.setupTime> | setup in Setups : 
                    setup.setupMatrixId == tank.setupMatrixId};
 //The exact setup time calculations
 //For both resources and tanks
 //for resources it is setup time
 //for tanks it is so-called clean time

 //Calculate productId, since somehow dexpr cannot index Products
 {int} productIds = {p.productId | p in Products};
 int setupTimeResource[r in Resources][preProd in productIds union {-1}]
                                    [succProd in productIds] = 
     sum(<matrixId, fromState, toState, setupTime, setupCost> in
            Setups : matrixId == r.setupMatrixId && 
            fromState == preProd && toState == succProd)
            setupTime;
 int setupTimeStorage[tank in StorageTanks][preProd in productIds]
                                    [succProd in productIds] = 
     sum(<matrixId, fromState, toState, setupTime, setupCost> in
            Setups : matrixId == tank.setupMatrixId && 
            fromState == preProd && toState == succProd)
            setupTime;    
 
 //The exact setup cost/clean cost for resources/tanks
 int setupCostResource[r in Resources][preProd in productIds union {-1}] //-1 is those not need setup
                                    [succProd in productIds] = 
     sum(<matrixId, fromState, toState, setupTime, setupCost> in
            Setups : matrixId == r.setupMatrixId && 
            fromState == preProd && toState == succProd)
            setupCost;
 int setupCostTank[tank in StorageTanks][preProd in productIds union {-1}]
                                    [succProd in productIds] = 
     sum(<matrixId, fromState, toState, setupTime, setupCost> in
            Setups : matrixId == tank.setupMatrixId && 
            fromState == preProd && toState == succProd)
            setupCost;  
 
 //To solve tank issue, calculate the amount stored in a tank                
 cumulFunction storageTank[tank in StorageTanks] = 
    sum(ss in StepStorages : ss.tank == tank) pulse(tankUse[ss], 
        ss.dap.demand.quantity);
  
 //TardinessCost calculation
 pwlFunction tardinessCost[d in Demands] = 
    piecewise
            {0 -> d.dueTime; d.tardinessVariableCost}(d.dueTime, 0);
      
 //Decision Expressions
 //A previous product for a specific resource
 //used to determine setup time       
 dexpr int prevProduct[da in DemAlter] = typeOfPrev(
        resources[item(Resources, <da.alternativ.resourceId>)], 
        demAlter[da], 
        item(Resources, <da.alternativ.resourceId>).initialProductId);
 dexpr int prevProductTank[ss in StepStorages] = typeOfPrev(
        tankSequence[item(StorageTanks, <ss.tank.storageTankId>)],
        tankUse[ss],
        item(StorageTanks, <ss.tank.storageTankId>).initialProductId);
 
 //An alternative that requires a setup for its resource       
 dexpr int alterToBeSetup[da in DemAlter] = 
        presenceOf(demAlter[da]) && 
        prevProduct[da] >= 0;
 dexpr int tankToBeSetup[ss in StepStorages] = 
        presenceOf(tankUse[ss]) && 
        ss.dap.demand.productId != prevProductTank[ss];
 
 //Total non-delivery cost, only used when a demand is not present
 dexpr float TotalNonDeliveryCost = sum(demand in Demands) 
        demand.quantity * demand.nonDeliveryVariableCost * 
        !presenceOf(demandInterval[demand]);
 
 //Total processing cost, which depands on the chosen alternative 
 //and the quantity
 dexpr float processingCost[da in DemAlter] = 
    (da.alternativ.fixedProcessingCost + (da.alternativ.variableProcessingCost * da.demand.quantity)) * 
    presenceOf(demAlter[da]);
 dexpr float TotalProcessingCost = sum(da in DemAlter) processingCost[da];
        
 //Total setup cost, only when a tank/resource needs a setup
 //Also, that needed alternative should present
 //Introducce two temp dexpr represents the setup cost for a 
 //specific resource/tank
 dexpr float resourceSetupCost[da in DemAlter] = 
    presenceOf(resourSetup[da]) * setupCostResource[<da.alternativ.resourceId>]
                            [prevProduct[da]][da.st.productId];
 dexpr float tankSetupCost[ss in StepStorages] =
    presenceOf(tankSetup[ss]) * setupCostTank[<ss.tank.storageTankId>]
                            [prevProductTank[ss]][ss.dap.demand.productId];
 dexpr float resourceSetupCosts = sum(da in DemAlter)resourceSetupCost[da];
 dexpr float tankSetupCosts = sum(ss in StepStorages)tankSetupCost[ss];
 dexpr float TotalSetupCost = resourceSetupCosts + 
                        tankSetupCosts;

 //Total TardinessCost, depends on the tardiness time and unit
 dexpr float TotalTardinessCost = sum(d in Demands)
            endEval(demandInterval[d], tardinessCost[d]);
 
 dexpr float WeightedNonDeliveryCost = TotalNonDeliveryCost * 
                item(CriterionWeights, ord(CriterionWeights, 
                <"NonDeliveryCost">)).weight;
 dexpr float WeightedProcessingCost = TotalProcessingCost * 
                item(CriterionWeights, ord(CriterionWeights, 
                <"ProcessingCost">)).weight;
 dexpr float WeightedSetupCost = TotalSetupCost * 
                item(CriterionWeights, ord(CriterionWeights, 
                <"ProcessingCost">)).weight;
 dexpr float WeightedTardinessCost = TotalTardinessCost * 
                item(CriterionWeights, ord(CriterionWeights, 
                <"TardinessCost">)).weight;               
 dexpr float sumWeighted = WeightedNonDeliveryCost + 
                    WeightedProcessingCost + 
                    WeightedSetupCost +
                    WeightedTardinessCost;

 minimize sumWeighted;
                    
 subject to {
 //General constraint
 //If a demand has a quantity which is larget than any tanks, just not present it
 forall (d in Demands)
   d.quantity > max(tank in StorageTanks) tank.quantityMax 
    => !presenceOf(demandInterval[d]); 
 
 //For those not presented(not delivered) demands,
 //(these demands should have steps use a tank(appearantly))
 //no tank will be used
 forall (ss in StepStorages)
   !presenceOf(demandInterval[ss.dap.demand]) => !presenceOf(tankUse[ss]);
   
 //For those demand that will storage
 //use only one tank at the same time over all steps/alternatives
 forall (dap in DemAltPre : dap.pre.delayMin > 0)
   presenceOf(demandInterval[dap.demand]) => 
   (sum(ss in StepStorages : ss.dap == dap) presenceOf(tankUse[ss]) == 1);
 forall (dap in DemAltPre : dap.pre.delayMin == 0)
   presenceOf(demandInterval[dap.demand]) => 
   (sum(ss in StepStorages : ss.dap == dap) presenceOf(tankUse[ss]) <= 1);
 
 //For those steps(one alternative) that will use a tank
 //The storaged product should be in the tank quantity max
 forall (tank in StorageTanks)
   storageTank[tank] <= tank.quantityMax;
   
 //Tank can only be cleaned(setup) when its empty
 forall(ss in StepStorages)
   alwaysIn(storageTank[ss.tank], tankSetup[ss], 0, 0);
 
 forall(ss in StepStorages)
   presenceOf(tankUse[ss]) => sizeOf(tankUse[ss]) > 0;
 //Constraints about setup
 //All alternative steps need a setup when needed
 forall(da in DemAlter)
   (alterToBeSetup[da] == 1) => presenceOf(resourSetup[da]); 
 //Setup time (setup interval length) is equal to the value in matrix
 forall(da in DemAlter)
   presenceOf(resourSetup[da]) => lengthOf(resourSetup[da]) == 
        setupTimeResource[<da.alternativ.resourceId>][prevProduct[da]][da.st.productId]; 
 //The processing step should followed by setup without any delay
 forall(da in DemAlter)
   startAtEnd(demAlter[da], resourSetup[da]);
 //Tank needs setup when needed
 forall(ss in StepStorages)
   (tankToBeSetup[ss] == 1) => presenceOf(tankSetup[ss]);
 //Setup time (setup interval length) is equal to the value in matrix
 forall(ss in StepStorages)
   presenceOf(tankSetup[ss]) => lengthOf(tankSetup[ss]) == 
        setupTimeStorage[<ss.tank.storageTankId>][prevProductTank[ss]][ss.dap.demand.productId];
 //The storaging step should followed by setup without any delay
 forall(ss in StepStorages)
   startAtEnd(tankUse[ss], tankSetup[ss]);
   
 //Span all demandIntervals to its steps
 forall(d in Demands)
   span(demandInterval[d], all(st in Steps : st.productId == d.productId)
                    demSteps[<d, st>]);
 //Make sure that a present demand must present all its steps
 forall(<d, st> in DemSteps)
   presenceOf(demandInterval[d]) => presenceOf(demSteps[<d, st>]);                                    
 
 //For each present step, only one alternative can be chosen  
 forall(<d, st> in DemSteps)
   alternative(demSteps[<d, st>], 
   all(alter in Alternatives : st.stepId == alter.stepId)demAlter[<d, st, alter>]);  
   
 forall(pre in Precedences, ds1, ds2 in DemSteps : 
        ds1.demand == ds2.demand && 
        ds1.st.stepId == pre.predecessorId &&
        ds2.st.stepId == pre.successorId)
   endBeforeStart(demSteps[ds1], demSteps[ds2], 
                    pre.delayMin);
 forall(resource in Resources)
   noOverlap(resources[resource], transitionTimesResource[resource], 0);
 forall(ss1, ss2 in StepStorages : 
        ss1.dap.demand.productId != ss2.dap.demand.productId &&
        ss1.tank == ss2.tank)
   noOverlap(tankSequence[ss1.tank], transitionTimesStorage[ss1.tank], 0);

   
//   bound tankUse start and end time
forall(ss in StepStorages, ds in DemSteps : 
        ss.dap.demand == ds.demand && 
        ss.dap.pre.predecessorId == ds.st.stepId)
    startAtEnd(tankUse[ss], demSteps[ds]);
forall(ss in StepStorages, ds in DemSteps : 
        ss.dap.demand == ds.demand && 
        ss.dap.pre.successorId == ds.st.stepId)
    startAtEnd(demSteps[ds], tankUse[ss]);
    
 //Delivery window
 forall (d in Demands) {
    startOf(demandInterval[d]) >= d.deliveryMin;
    endOf(demandInterval[d]) <= d.deliveryMax; 
 }
 
 }
 
 //----- End of constraint programming -----
 
 /*
 * Solutions to be reported.
 * Given according to the assignment descriptions. 
 */
 tuple DemandAssignment {
    key string demandId;
    int startTime;
    int endTime;
    float nonDeliveryCost;
    float tardinessCost; 
 };
{DemandAssignment} demandAssignments = 
{<d.demandId, startOf(demandInterval[d]), endOf(demandInterval[d]), 
(d.quantity * d.nonDeliveryVariableCost * 
    !presenceOf(demandInterval[d])), 
endEval(demandInterval[d], tardinessCost[d])> | d in Demands};//TODO: = fill in decision variables
 
 tuple StepAssignment {
    key string demandId;
    key string stepId;
    int startTime;
    int endTime;
    string resourceId;
    float procCost;
    float setupCost;
    int startTimeSetup;
    int endTimeSetup;
    string setupResourceId; 
 };
{StepAssignment} stepAssignments;
// = 
//{<d.demandId, st.stepId, startOf(demSteps[<d, st>]), endOf(demSteps[<d, st>]), 
//alter.resourceId, processingCost[<d, st, alter>], > | <d, st, alter> in DemAlter;//TODO: = fill in decision variables
 
 tuple StorageAssignment {
    key string demandId;
    key string prodStepId;
    int startTime;
    int endTime;
    int quantity;
    string storageTankId; 
 };
{StorageAssignment} storageAssignments;//TODO: = fill in decision variables
 
 /*
 * There are also some code from desctiption that may help.
 */
// {DemandAssignment} demandAssignments = {
//    <d.demandId,
//    startOf(something), 
//    endOf(something),
//    someExpression,
//    someOtherExpression>
//    | d in Demands 
// };
//Just for some hints

/*
* Final part execute
* From assignment description
* Determines the way to generage the output
*/
execute {
    writeln("Total Non-Delivery Cost    : ", TotalNonDeliveryCost);
    writeln("Total Processing Cost      : ", TotalProcessingCost);
    writeln("Total Setup Cost           : ", TotalSetupCost);
    writeln("Total Tardiness Cost       : ", TotalTardinessCost);
    writeln();
    writeln("Weighted Non-Delivery Cost : ", WeightedNonDeliveryCost);
    writeln("Weighted Processing Cost   : ", WeightedProcessingCost);
    writeln("Weighted Setup Cost        : ", WeightedSetupCost);
    writeln("Weighted Tardiness Cost    : ", WeightedTardinessCost);
    writeln();
    
    for (var d in demandAssignments) {
        writeln(d.demandId, ": [", 
                d.startTime, ",", d.endTime, "] ");
        writeln("    non-delivery cost: ", d.nonDeliveryCost, 
                ", tardiness cost: ", d.tardinessCost);
    }
    writeln();
    
    for (var sa in stepAssignments) {
        writeln(sa.stepId, " of ", sa.demandId, 
                ": [", sa.startTime, ",", sa.endTime, "] ", 
                "on ", sa.resourceId);
        write("    processing cost: ", sa.procCost);
        if (sa.setupCost > 0)
            write(", setup cost: ", sa.setupCost);
        writeln();
        if (sa.startTimeSetup < sa.endTimeSetup)
            writeln("    setup step: [", 
                    sa.startTimeSetup, ",", sa.endTimeSetup, "] ", 
                    "on ", sa.setupResourceId);    
    }
    writeln();
    
    for (var sta in storageAssignments) {
        if (sta.startTime < sta.endTime) {
            writeln(sta.prodStepId, " of ", sta.demandId, 
                    " produces quantity ", sta.quantity, 
                    " in storage tank ", sta.storageTankId, 
                    " at time ", sta.startTime, 
                    " which is consumed at time ", sta.endTime);        
        }    
    }
}