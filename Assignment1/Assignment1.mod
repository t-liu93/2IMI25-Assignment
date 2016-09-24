/*********************************************
 * OPL 12.6.3.0 Model
 * Author: liuti
 * Creation Date: Sep 24, 2016 at 4:12:35 PM
 *********************************************/

 using CP;
 
 tuple Character {
 	key string name;
 	string type;  
 }
 
 tuple Scene {
 	key string name;
 	{string} characterSet; 
 }
 
 