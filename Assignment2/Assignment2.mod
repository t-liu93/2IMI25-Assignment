/*********************************************
 * OPL 12.6.3.0 Data
 * Author 1: Tianyu Liu (0937147), e-mail: t.liu.1@student.tue.nl
 * Author 2: Li Wang (0977456), e-mail: l.wang.3@student.tue.nl
 * Creation Date: Oct 18, 2016 at 12:53:38 PM
 * Last Modified Date: Oct 7, 2016
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
     key string demandID;
     int productID;
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
 
 //TODO: Add some more data structures that the calculation needs
 
 /*
 * Some execute setting about tests, given in the assignment description. 
 * Using sequential search. 
 * Time limited: 1 secound per demand.
 */
 execute {
    cp.param.Workers = 1;
    cp.param.TimeLimit = Opl.card(Demands); 
 }
 
 /*
 * Decision variables given by description
 */
 //Set an interval dvar to decide whether a demand will be processed or not. 
 dvar interval demandInterval[demand in Demands]
                optional;
 
 //Non delivery cost if a demand is not present
 dexpr float TotalNonDeliveryCost = sum(demand in Demands) 
        demand.quantity * demand.nonDeliveryVariableCost * 
        !presenceOf(demandInterval[demand]);
 dexpr float TotalProcessingCost = 0;//TODO
 dexpr float TotalSetupCost = 0;//TODO
 dexpr float TotalTardinessCost = 0;//TODO
 
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
//TODO: Add detail of the decision expressions
 /*
 * Here goes the minimize part and subjects.
 */
 //TODO: What we want to minimize and subject 
 minimize sumWeighted;
                    
 subject to {
 /*
 * Constraint 1
 * If a demand is not possible to be processed, 
 * then just count the non-delivery cost of that demand. 
 */ 
 //Here are different cases of this constraint
 /*
 * Case 1: If a demand needs at least one tank to store, 
 * but there is no tank can hold the amount of the demand
 * (i.e. at least one precedence has a delay time, means 
    it needs a tank), then set the demand not present.
 */
 forall(demand in Demands)
     forall(tank in StorageTanks : demand.quantity > tank.quantityMax)
       forall(precedence in Precedences : precedence.delayMin > 0)
         !presenceOf(demandInterval[demand]);
//TODO other cases.
 
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
{DemandAssignment} demandAssignments;//TODO: = fill in decision variables
 
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
{StepAssignment} stepAssignments;//TODO: = fill in decision variables
 
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