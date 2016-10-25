/*********************************************
 * OPL 12.6.3.0 Data
 * Author 1: Tianyu Liu (0937147), e-mail: t.liu.1@student.tue.nl
 * Author 2: Li Wang (0977456), e-mail: l.wang.3@student.tue.nl
 * Creation Date: Oct 18, 2016 at 12:53:38 PM
 * Last Modified Date: Oct 7, 2016
 *********************************************/

 using CP;
 
 /* Data structures */
 /* Tuples are established according to the xls file structure */
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
 	int alternativeNumber;
 	string resourceId;
 	int fixedProcessingTime;
 	float variableProcessingTime;
 	float fixedProcessingCost;
 	float variableProcessingCost;
 }
 {Alternative} Alternatives = ...;
 
 tuple StorageProduction {
 	key string prodStepId;
 	string storageTankId;
 	string consStepId;
 }
 {StorageProduction} StorageProductions = ...;
 
 tuple SetupMatrix {
  	key string setupMatrixId;
  	int fromState;
  	int toState;
  	int setupTime;
  	int setupCost;  
 }
 {SetupMatrix} Setups = ...;
 
 tuple CriterionWeight {
 	key string criterionId;
 	float weight; 
 }
 {CriterionWeight} CriterionWeights = ...;
  